defmodule Query.Merging.SpreadChanges do
  def for_market_id(market_id, start_time, end_time) do
    bids =
      Query.BestBids.for_market_id(market_id, start_time, end_time)
      |> Enum.map(fn bid -> {:bid, bid} end)

    asks =
      Query.BestAsks.for_market_id(market_id, start_time, end_time)
      |> Enum.map(fn ask -> {:ask, ask} end)

    bids_and_asks =
      (bids ++ asks)
      |> Enum.sort_by(fn {_, price} -> price.timestamp end, DateTime)

    all_spreads =
      Stream.transform(
        bids_and_asks,
        {nil, nil},
        fn {side, price}, {previous_bid, previous_ask} ->
          case side do
            :bid ->
              spread_change = {:bid_change, price.timestamp, {price, previous_ask}}
              {[spread_change], {price, previous_ask}}

            :ask ->
              spread_change = {:ask_change, price.timestamp, {previous_bid, price}}
              {[spread_change], {previous_bid, price}}
          end
        end
      )

    spreads_without_nil_prices =
      all_spreads
      |> Stream.filter(fn {_, _, {best_bid, best_ask}} ->
        best_bid != nil && best_ask != nil
      end)

    spreads_without_nil_prices
  end

  def for_market_ids(market_ids, start_time, end_time) do
    tasks =
      for market_id <- market_ids do
        Task.async(fn ->
          for_market_id(market_id, start_time, end_time)
          |> Stream.map(fn change -> {market_id, change} end)
        end)
      end

    market_streams =
      Task.yield_many(tasks)
      |> Enum.map(fn {_, stream} -> {:ok, stream} end)
      |> Enum.into(%{})

    initial_cursor =
      for market_id <- market_ids,
          into: %{},
          do:
            {market_id,
             %{
               :stream => market_streams[market_id],
               :current => nil,
               :previous => nil
             }}

    all_market_spreads =
      Stream.unfold(
        initial_cursor,
        fn cursor ->
          new_cursor =
            for market_id <- market_ids do
              cond do
                cursor[market_id].stream == :halt ->
                  {market_id, cursor[market_id].previous}

                cursor[market_id].current != nil ->
                  {market_id, cursor[market_id]}

                cursor[market_id].current == nil ->
                  {current, new_stream} = consume_one(cursor[market_id].stream)

                  {
                    market_id,
                    %{cursor[market_id] | :stream => new_stream, :current => current}
                  }
              end
            end
            |> Enum.filter(fn {_, cursor} -> cursor.stream != :halt end)
            |> Enum.into(%{})

          next_value = snapshot(new_cursor)

          {next_value, new_cursor}
        end
      )

    all_market_spreads
  end
end

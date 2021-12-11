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
        fn spread_change, previous -> snapshot(spread_change, previous) end
      )

    spreads_without_nil_prices =
      all_spreads
      |> Stream.filter(fn {_, _, {best_bid, best_ask}} ->
        best_bid != nil && best_ask != nil
      end)

    spreads_without_nil_prices
  end

  defp snapshot({side, price}, {previous_bid, previous_ask}) do
    case side do
      :bid ->
        spread_change = {:bid_change, price.timestamp, {price, previous_ask}}
        {[spread_change], {price, previous_ask}}

      :ask ->
        spread_change = {:ask_change, price.timestamp, {previous_bid, price}}
        {[spread_change], {previous_bid, price}}
    end
  end
end

defmodule Query.Mergeing.AggregatedSpreadChanges do
  def to_csv(stream, file_path) do
    file = File.stream!(file_path)

    stream
    |> Stream.map(fn changes ->
      chunks =
        for {_, change} <- changes do
          {_, _, {bid, ask}} = change
          "#{bid.price},#{ask.price}"
        end

      line =
        chunks
        |> Enum.join(",")

      line <> "\n"
    end)
    |> Stream.into(file)
    |> Stream.run()
  end

  def for_market_ids(market_ids, start_time, end_time) do
    tasks =
      for market_id <- market_ids do
        Task.async(fn ->
          spread_changes =
            Query.Merging.SpreadChanges.for_market_id(
              market_id,
              start_time,
              end_time
            )
            |> Enum.to_list()

          {market_id, spread_changes}
        end)
      end

    market_spread_changes =
      Task.yield_many(tasks, :infinity)
      |> Enum.map(fn {_, {:ok, spread_changes}} -> spread_changes end)
      |> Enum.into(%{})

    initial_market_cursors =
      for market_id <- market_ids,
          into: %{},
          do:
            {market_id,
             %{
               :spread_changes => market_spread_changes[market_id],
               :current => nil,
               :previous => nil
             }}

    all_aggregated =
      Stream.unfold(
        initial_market_cursors,
        fn market_cursors -> snapshot(market_ids, market_cursors) end
      )

    aggregated_without_nil_spread_changes =
      all_aggregated
      |> Stream.filter(fn market_spreads ->
        for {_, spread} <- market_spreads do
          spread != nil
        end
        |> Enum.all?()
      end)

    aggregated_without_nil_spread_changes
  end

  defp snapshot(market_ids, market_cursors) do
    candidates =
      for market_id <- market_ids do
        cursor = market_cursors[market_id]

        cond do
          cursor.spread_changes == [] ->
            {market_id, cursor}

          cursor.current != nil ->
            {market_id, cursor}

          cursor.current == nil ->
            [head | tail] = cursor.spread_changes

            {
              market_id,
              %{cursor | :current => head, :spread_changes => tail}
            }
        end
      end

    oldest =
      candidates
      |> Enum.filter(fn {_, cursor} -> cursor.current != nil end)
      |> Enum.min_by(
        fn {_, cursor} ->
          {_, timestamp, _} = cursor.current
          timestamp
        end,
        DateTime,
        fn -> nil end
      )

    if oldest != nil do
      {oldest_market_id, oldest_cursor} = oldest

      snapshot =
        candidates
        |> Enum.map(fn {market_id, cursor} ->
          if market_id == oldest_market_id do
            {market_id, oldest_cursor.current}
          else
            {market_id, cursor.previous}
          end
        end)

      new_market_cursors =
        candidates
        |> Enum.into(%{})
        |> Map.put(oldest_market_id, %{
          oldest_cursor
          | :current => nil,
            :previous => oldest_cursor.current
        })

      {snapshot, new_market_cursors}
    else
      nil
    end
  end
end

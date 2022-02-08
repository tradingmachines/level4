defmodule Exchanges.Binance.Spot do
  @moduledoc """
  Contains translation scheme for the Binance spot market websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state(base_symbol, quote_symbol) do
    %{
      "base_symbol" => base_symbol,
      "quote_symbol" => quote_symbol,
      "requested_snapshot" => false,
      "buffer_deltas" => true,
      "bids_buffer" => [],
      "asks_buffer" => []
    }
  end

  @impl TranslationScheme
  def make_ping_messages(sync_state) do
    {:ok, json_str} = Jason.encode(%{"op" => "ping"})
    [json_str]
  end

  @impl TranslationScheme
  def make_subscribe_messages(base_symbol, quote_symbol) do
    base_symbol_lower = String.downcase(base_symbol)
    quote_symbol_lower = String.downcase(quote_symbol)

    {:ok, json_str} =
      Jason.encode(%{
        "id" => 1,
        "method" => "SUBSCRIBE",
        "params" => [
          "#{base_symbol_lower}#{quote_symbol_lower}@depth@100ms",
          "#{base_symbol_lower}#{quote_symbol_lower}@trade"
        ]
      })

    [json_str]
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    {instructions, new_sync_state} =
      case json do
        %{"id" => 1, "result" => nil} ->
          {[:noop], sync_state}

        %{"lastUpdateId" => last_update_id, "bids" => bid_deltas, "asks" => ask_deltas} ->
          snapshot_bids =
            for [price_str, size_str] <- bid_deltas do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)
              {price, size}
            end

          snapshot_asks =
            for [price_str, size_str] <- ask_deltas do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)
              {price, size}
            end

          buffered_bids =
            sync_state["bids_buffer"]
            |> Enum.filter(fn {_, _, timestamp} -> timestamp > last_update_id end)
            |> Enum.map(fn {price, size, _} -> {:bid, price, size} end)

          buffered_asks =
            sync_state["asks_buffer"]
            |> Enum.filter(fn {_, _, timestamp} -> timestamp > last_update_id end)
            |> Enum.map(fn {price, size, _} -> {:ask, price, size} end)

          {[
             {:snapshot, snapshot_bids, snapshot_asks},
             {:deltas, buffered_bids ++ buffered_asks}
           ],
           %{
             sync_state
             | "buffer_deltas" => false,
               "bids_buffer" => [],
               "asks_buffer" => []
           }}

        %{
          "e" => "depthUpdate",
          "b" => bid_deltas,
          "a" => ask_deltas,
          "u" => final_update_id
        } ->
          bids =
            for [price_str, size_str] <- bid_deltas do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)
              {price, size, final_update_id}
            end

          asks =
            for [price_str, size_str] <- ask_deltas do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)
              {price, size, final_update_id}
            end

          cond do
            sync_state["requested_snapshot"] == false ->
              {[
                 {:fetch,
                  fn ->
                    {:ok, conn_pid} =
                      :gun.open("api.binance.com" |> to_charlist, 443, %{
                        :connect_timeout => 3000,
                        :domain_lookup_timeout => 3000,
                        :retry => 0,
                        :protocols => [:http],
                        :supervise => false
                      })

                    {:ok, protocol} = :gun.await_up(conn_pid)

                    symbol = sync_state["base_symbol"] <> sync_state["quote_symbol"]

                    stream_ref =
                      :gun.get(conn_pid, "/api/v3/depth?symbol=#{symbol}&limit=1000", [
                        {"accept", "application/json"}
                      ])

                    {:ok, response} =
                      case :gun.await(conn_pid, stream_ref) do
                        {:response, :fin, status, _} ->
                          {:error, status}

                        {:response, :nofin, _, _} ->
                          {:ok, body} = :gun.await_body(conn_pid, stream_ref)
                          {:ok, body}
                      end

                    :gun.close(conn_pid)

                    response
                  end}
               ],
               %{
                 sync_state
                 | "requested_snapshot" => true,
                   "buffer_deltas" => true,
                   "bids_buffer" => bids,
                   "asks_buffer" => asks
               }}

            sync_state["requested_snapshot"] == true and
                sync_state["buffer_deltas"] == true ->
              {[:noop],
               %{
                 sync_state
                 | "bids_buffer" => sync_state["bids_buffer"] ++ bids,
                   "asks_buffer" => sync_state["asks_buffer"] ++ asks
               }}

            sync_state["requested_snapshot"] == true and
                sync_state["buffer_deltas"] == false ->
              bids =
                for [price_str, size_str] <- bid_deltas do
                  {price, _} = Float.parse(price_str)
                  {size, _} = Float.parse(size_str)
                  {:bid, price, size}
                end

              asks =
                for [price_str, size_str] <- ask_deltas do
                  {price, _} = Float.parse(price_str)
                  {size, _} = Float.parse(size_str)
                  {:ask, price, size}
                end

              {[{:deltas, bids ++ asks}], sync_state}
          end

        %{
          "e" => "trade",
          "T" => epoch_ms,
          "p" => price_str,
          "q" => size_str,
          "m" => buyer_is_market_maker
        } ->
          {price, _} = Float.parse(price_str)
          {size, _} = Float.parse(size_str)

          epoch_micro = epoch_ms * 1000
          {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

          if buyer_is_market_maker do
            {[{:sells, [{price, size, timestamp}]}], sync_state}
          else
            {[{:buys, [{price, size, timestamp}]}], sync_state}
          end
      end

    {instructions, new_sync_state}
  end

  @impl TranslationScheme
  def check_sync_state(sync_state) do
    {:synced, sync_state}
  end
end

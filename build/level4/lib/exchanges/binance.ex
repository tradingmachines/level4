defmodule Exchanges.Binance.Spot do
  @moduledoc """
  Translation scheme for the Binance spot market websocket API.

  Change log and websocket docs:
  - https://binance-docs.github.io/apidocs/#change-log
  - https://binance-docs.github.io/apidocs/#websocket-market-streams
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def initial_state(base_symbol, quote_symbol) do
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
  def ping_msg(current_state) do
    {:ok, json_str} = Jason.encode(%{"op" => "ping"})
    {:ok, [json_str]}
  end

  @impl TranslationScheme
  def subscribe_msg(base_symbol, quote_symbol) do
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

    {:ok, [json_str]}
  end

  @impl TranslationScheme
  def synchronised?(current_state) do
    # TODO
    true
  end

  @impl TranslationScheme
  def translate(json, current_state) do
    {instructions, next_state} =
      case json do
        %{
          "id" => 1,
          "result" => nil
        } ->
          {[:noop], current_state}

        %{
          "lastUpdateId" => last_update_id,
          "bids" => bid_deltas,
          "asks" => ask_deltas
        } ->
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
            current_state["bids_buffer"]
            |> Enum.filter(fn {_, _, timestamp} -> timestamp > last_update_id end)
            |> Enum.map(fn {price, size, _} -> {:bid, price, size} end)

          buffered_asks =
            current_state["asks_buffer"]
            |> Enum.filter(fn {_, _, timestamp} -> timestamp > last_update_id end)
            |> Enum.map(fn {price, size, _} -> {:ask, price, size} end)

          {[
             {:snapshot, snapshot_bids, snapshot_asks},
             {:deltas, buffered_bids ++ buffered_asks}
           ],
           %{
             current_state
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
            current_state["requested_snapshot"] == false ->
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

                    symbol = current_state["base_symbol"] <> current_state["quote_symbol"]

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
                 current_state
                 | "requested_snapshot" => true,
                   "buffer_deltas" => true,
                   "bids_buffer" => bids,
                   "asks_buffer" => asks
               }}

            current_state["requested_snapshot"] == true and
                current_state["buffer_deltas"] == true ->
              {[:noop],
               %{
                 current_state
                 | "bids_buffer" => current_state["bids_buffer"] ++ bids,
                   "asks_buffer" => current_state["asks_buffer"] ++ asks
               }}

            current_state["requested_snapshot"] == true and
                current_state["buffer_deltas"] == false ->
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

              {[{:deltas, bids ++ asks}], current_state}
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
            {[{:sells, [{price, size, timestamp}]}], current_state}
          else
            {[{:buys, [{price, size, timestamp}]}], current_state}
          end
      end

    {:ok, instructions, next_state}
  end
end

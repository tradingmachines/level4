defmodule Exchange.Bitstamp do
  @moduledoc """
  Translation scheme for the Bitstamp websocket API.
  """

  defmacro __using__(_opts) do
    quote location: :keep do
      @http_opts %{
        :connect_timeout => 3000,
        :domain_lookup_timeout => 3000,
        :retry => 0,
        :protocols => [:http],
        :supervise => false
      }

      @http_headers [
        {"Accept", "application/json"},
        {"User-Agent", "william >:)"}
      ]

      def fetch_book_snapshot(base_symbol, quote_symbol) do
        base_symbol_lower = String.downcase(base_symbol)
        quote_symbol_lower = String.downcase(quote_symbol)
        pair = "#{base_symbol_lower}#{quote_symbol_lower}"

        domain = "www.bitstamp.net"
        path = "/api/v2/order_book/#{pair}?group=1"

        {:ok, conn_pid} = :gun.open(domain |> to_charlist, 443, @http_opts)
        {:ok, protocol} = :gun.await_up(conn_pid)

        stream_ref = :gun.get(conn_pid, path, @http_headers)

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
      end

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
        {:ok, json_str} = Jason.encode(%{"event" => "bts:heartbeat"})
        {:ok, [json_str]}
      end

      @impl TranslationScheme
      def subscribe_msg(base_symbol, quote_symbol) do
        base_symbol_lower = String.downcase(base_symbol)
        quote_symbol_lower = String.downcase(quote_symbol)
        pair = "#{base_symbol_lower}#{quote_symbol_lower}"

        {:ok, json_str_book} =
          Jason.encode(%{
            "event" => "bts:subscribe",
            "data" => %{
              "channel" => "diff_order_book_#{pair}"
            }
          })

        {:ok, json_str_trade} =
          Jason.encode(%{
            "event" => "bts:subscribe",
            "data" => %{
              "channel" => "live_trades_#{pair}"
            }
          })

        {:ok, [json_str_book, json_str_trade]}
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
            %{"event" => "bts:subscription_succeeded"} ->
              {[:noop], current_state}

            %{"event" => "bts:heartbeat"} ->
              {[:noop], current_state}

            %{"event" => "bts:request_reconnect"} ->
              {[:reconnect], current_state}

            %{
              "microtimestamp" => microtimestamp_str,
              "bids" => bid_strs,
              "asks" => ask_strs
            } ->
              snapshot_timestamp = Integer.parse(microtimestamp_str)

              snapshot_bids =
                for [price_str, size_str] <- bid_strs do
                  {price, _} = Float.parse(price_str)
                  {size, _} = Float.parse(size_str)
                  {price, size}
                end

              snapshot_asks =
                for [price_str, size_str] <- ask_strs do
                  {price, _} = Float.parse(price_str)
                  {size, _} = Float.parse(size_str)
                  {price, size}
                end

              buffered_bids =
                current_state["bids_buffer"]
                |> Enum.filter(fn {_, _, delta_timestamp} ->
                  delta_timestamp > snapshot_timestamp
                end)
                |> Enum.map(fn {price, size, _} ->
                  {:bid, price, size}
                end)

              buffered_asks =
                current_state["asks_buffer"]
                |> Enum.filter(fn {_, _, delta_timestamp} ->
                  delta_timestamp > snapshot_timestamp
                end)
                |> Enum.map(fn {price, size, _} ->
                  {:ask, price, size}
                end)

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
              "event" => "data",
              "data" => %{
                "microtimestamp" => microtimestamp_str,
                "bids" => bid_strs,
                "asks" => ask_strs
              }
            } ->
              delta_timestamp = Integer.parse(microtimestamp_str)

              bids =
                for [price_str, size_str] <- bid_strs do
                  {price, _} = Float.parse(price_str)
                  {size, _} = Float.parse(size_str)
                  {price, size, delta_timestamp}
                end

              asks =
                for [price_str, size_str] <- ask_strs do
                  {price, _} = Float.parse(price_str)
                  {size, _} = Float.parse(size_str)
                  {price, size, delta_timestamp}
                end

              cond do
                # have not fetched book snapshot yet
                current_state["requested_snapshot"] == false ->
                  {[
                     {:fetch,
                      fn ->
                        fetch_book_snapshot(
                          current_state["base_symbol"],
                          current_state["quote_symbol"]
                        )
                      end}
                   ],
                   %{
                     current_state
                     | "requested_snapshot" => true,
                       "buffer_deltas" => true,
                       "bids_buffer" => bids,
                       "asks_buffer" => asks
                   }}

                # asked for the snapshot but it isn't ready yet
                current_state["requested_snapshot"] == true and
                    current_state["buffer_deltas"] == true ->
                  {[:noop],
                   %{
                     current_state
                     | "bids_buffer" => current_state["bids_buffer"] ++ bids,
                       "asks_buffer" => current_state["asks_buffer"] ++ asks
                   }}

                # the snapshot is ready for deltas
                current_state["requested_snapshot"] == true and
                    current_state["buffer_deltas"] == false ->
                  bid_deltas =
                    for {price, size, _} <- bids do
                      {:bid, price, size}
                    end

                  ask_deltas =
                    for {price, size, _} <- asks do
                      {:ask, price, size}
                    end

                  {[{:deltas, bid_deltas ++ ask_deltas}], current_state}
              end

            %{
              "event" => "trade",
              "data" => %{
                "price" => price_int,
                "amount" => size_int,
                "type" => side
              }
            } ->
              price = price_int / 1
              size = size_int / 1

              case side do
                0 ->
                  {
                    [{:buys, [{price, size}]}],
                    current_state
                  }

                1 ->
                  {
                    [{:sells, [{price, size}]}],
                    current_state
                  }
              end
          end

        {:ok, instructions, next_state}
      end
    end
  end
end

defmodule Exchange.Bitstamp.Spot do
  @moduledoc """
  Spot markets.

  Relevant documentation:
  - https://www.bitstamp.net/websocket/v2/
  """

  @behaviour TranslationScheme

  use Exchange.Bitstamp
end

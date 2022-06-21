defmodule Exchanges.Binance do
  @moduledoc """
  Translation scheme for the Binance websocket API.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
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

      @snapshot_endpoint opts[:snapshot_endpoint]

      def determine_snapshot_uri(endpoint, pair) do
        case endpoint do
          :spot ->
            {
              "api.binance.com",
              "/api/v3/depth?symbol=#{pair}&limit=1000"
            }

          :futures ->
            {
              "fapi.binance.com",
              "/fapi/v1/depth?symbol=#{pair}&limit=1000"
            }

          :inverse ->
            {
              "dapi.binance.com",
              "/dapi/v1/depth?symbol=#{pair}_PERP&limit=1000"
            }
        end
      end

      def fetch_book_snapshot(base_symbol, quote_symbol) do
        endpoint = unquote(@snapshot_endpoint)
        pair = base_symbol <> quote_symbol

        {domain, path} = determine_snapshot_uri(endpoint, pair)

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
        {:ok, json_str} = Jason.encode(%{"op" => "ping"})
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
              "lastUpdateId" => snapshot_timestamp,
              "bids" => bid_strs,
              "asks" => ask_strs
            } ->
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
              "e" => "depthUpdate",
              "b" => bid_strs,
              "a" => ask_strs,
              "u" => delta_timestamp
            } ->
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
              "e" => "trade",
              "p" => price_str,
              "q" => size_str,
              "m" => buyer_is_market_maker
            } ->
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)

              if buyer_is_market_maker do
                {[{:sells, [{price, size}]}], current_state}
              else
                {[{:buys, [{price, size}]}], current_state}
              end
          end

        {:ok, instructions, next_state}
      end
    end
  end
end

defmodule Exchanges.Binance.Spot do
  @moduledoc """
  Spot markets.

  Relevant documentation:
  - https://binance-docs.github.io/apidocs/spot/en/#general-info
  - https://binance-docs.github.io/apidocs/spot/en/#websocket-market-streams
  """

  @behaviour TranslationScheme

  use Exchanges.Binance, snapshot_endpoint: :spot

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
end

defmodule Exchanges.Binance.Futures do
  @moduledoc """
  Futures markets.

  Relevant documentation:
  - https://binance-docs.github.io/apidocs/futures/en/#general-info
  - https://binance-docs.github.io/apidocs/futures/en/#websocket-market-streams
  """

  @behaviour TranslationScheme

  use Exchanges.Binance, snapshot_endpoint: :futures

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
end

defmodule Exchanges.Binance.Inverse do
  @moduledoc """
  Inverse futures markets.

  Relevant documentation:
  - https://binance-docs.github.io/delivery/futures/en/#general-info
  - https://binance-docs.github.io/delivery/futures/en/#websocket-market-streams
  """

  @behaviour TranslationScheme

  use Exchanges.Binance, snapshot_endpoint: :inverse

  @impl TranslationScheme
  def subscribe_msg(base_symbol, quote_symbol) do
    base_symbol_lower = String.downcase(base_symbol)
    quote_symbol_lower = String.downcase(quote_symbol)

    {:ok, json_str} =
      Jason.encode(%{
        "id" => 1,
        "method" => "SUBSCRIBE",
        "params" => [
          "#{base_symbol_lower}#{quote_symbol_lower}_perp@depth@100ms",
          "#{base_symbol_lower}#{quote_symbol_lower}_perp@trade"
        ]
      })

    {:ok, [json_str]}
  end
end

defmodule Exchanges.Coinbase do
  @moduledoc """
  Translation scheme for the Coinbase Pro websocket API.
  """

  defmacro __using__(_opts) do
    quote do
      @impl TranslationScheme
      def initial_state(base_symbol, quote_symbol) do
        %{"previous_sequence_number" => 0}
      end

      @impl TranslationScheme
      def ping_msg(current_state) do
        {:ok, json_str} = Jason.encode(%{"op" => "ping"})
        {:ok, [json_str]}
      end

      @impl TranslationScheme
      def subscribe_msg(base_symbol, quote_symbol) do
        {:ok, json_str} =
          Jason.encode(%{
            "type" => "subscribe",
            "product_ids" => ["#{base_symbol}-#{quote_symbol}"],
            "channels" => ["heartbeat", "level2", "matches"]
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
        instruction =
          case json["type"] do
            "snapshot" ->
              bids =
                for [price_str, size_str] <- json["bids"] do
                  {price, _} = Float.parse(price_str)
                  {size, _} = Float.parse(size_str)
                  {price, size}
                end

              asks =
                for [price_str, size_str] <- json["asks"] do
                  {price, _} = Float.parse(price_str)
                  {size, _} = Float.parse(size_str)
                  {price, size}
                end

              {:snapshot, bids, asks}

            "l2update" ->
              deltas =
                for [side, price_str, size_str] <- json["changes"] do
                  {price, _} = Float.parse(price_str)
                  {size, _} = Float.parse(size_str)

                  case side do
                    "buy" -> {:bid, price, size}
                    "sell" -> {:ask, price, size}
                  end
                end

              {:deltas, deltas}

            "match" ->
              {price, _} = Float.parse(json["price"])
              {size, _} = Float.parse(json["size"])
              {:ok, timestamp, 0} = DateTime.from_iso8601(json["time"])

              case json["side"] do
                "buy" -> {:buys, [{price, size, timestamp}]}
                "sell" -> {:sells, [{price, size, timestamp}]}
              end

            "subscriptions" ->
              :noop

            "heartbeat" ->
              :noop

            "error" ->
              :noop

            "last_match" ->
              :noop

            _ ->
              :unknown
          end

        {:ok, [instruction], current_state}
      end
    end
  end
end

defmodule Exchanges.Coinbase.Spot do
  @moduledoc """
  Spot markets.

  Relevant documentation:
  - https://docs.cloud.coinbase.com/exchange/docs/websocket-overview
  """

  @behaviour TranslationScheme

  use Exchanges.Coinbase
end

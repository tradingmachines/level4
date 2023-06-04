defmodule Exchange.Gemini do
  @moduledoc """
  Translation scheme for the Gemini websocket API.
  """

  defmacro __using__(_opts) do
    quote do
      @impl TranslationScheme
      def initial_state(base_symbol, quote_symbol) do
        %{"something" => nil}
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
            "subscriptions" => [
              %{
                "name" => "l2",
                "symbols" => ["#{base_symbol}#{quote_symbol}"]
              }
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
        instructions =
          case json do
            %{"type" => "heartbeat", "timestamp" => _} ->
              [:noop]

            %{"type" => "heartbeat", "sequence" => _} ->
              [:noop]

            %{"type" => "auction_result"} ->
              [:noop]

            %{"type" => "auction_indicative"} ->
              [:noop]

            %{
              "type" => "l2_updates",
              "changes" => changes,
              "trades" => _,
              "auction_events" => _
            } ->
              all_levels =
                for [side, price_str, size_str] <- changes do
                  {price, _} = Float.parse(price_str)
                  {size, _} = Float.parse(size_str)

                  case side do
                    "buy" -> {:bid, price, size}
                    "sell" -> {:ask, price, size}
                  end
                end

              bids =
                all_levels
                |> Enum.filter(fn {side, _, _} -> side == :bid end)
                |> Enum.map(fn {_, price, size} -> {price, size} end)

              asks =
                all_levels
                |> Enum.filter(fn {side, _, _} -> side == :ask end)
                |> Enum.map(fn {_, price, size} -> {price, size} end)

              [{:snapshot, bids, asks}]

            %{
              "type" => "l2_updates",
              "changes" => changes
            } ->
              deltas =
                for [side, price_str, size_str] <- changes do
                  {price, _} = Float.parse(price_str)
                  {size, _} = Float.parse(size_str)

                  case side do
                    "buy" -> {:bid, price, size}
                    "sell" -> {:ask, price, size}
                  end
                end

              [{:deltas, deltas}]

            %{
              "type" => "trade",
              "price" => price_str,
              "quantity" => size_str,
              "side" => side
            } ->
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)

              case side do
                "buy" -> [{:buys, [{price, size}]}]
                "sell" -> [{:sells, [{price, size}]}]
              end
          end

        {:ok, instructions, current_state}
      end
    end
  end
end

defmodule Exchange.Gemini.Spot do
  @moduledoc """
  Spot markets.

  Relevant documentation:
  - https://docs.gemini.com/websocket-api/
  """

  @behaviour TranslationScheme

  use Exchange.Gemini
end

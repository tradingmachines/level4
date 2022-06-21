defmodule Exchanges.FTX do
  @moduledoc """
  Translation scheme for the FTX websocket API.
  """

  defmacro __using__(_opts) do
    quote do
      @impl TranslationScheme
      def initial_state(base_symbol, quote_symbol) do
        %{}
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
        instructions =
          case json do
            %{"type" => "subscribed"} ->
              [:noop]

            %{"type" => "unsubscribed"} ->
              [:noop]

            %{"type" => "info"} ->
              [:noop]

            %{"type" => "pong"} ->
              [:noop]

            %{
              "type" => "partial",
              "data" => %{
                "bids" => initial_bids,
                "asks" => initial_asks
              }
            } ->
              bids =
                Enum.map(
                  initial_bids,
                  fn [price, size] -> {price, size} end
                )

              asks =
                Enum.map(
                  initial_asks,
                  fn [price, size] -> {price, size} end
                )

              [{:snapshot, bids, asks}]

            %{
              "type" => "update",
              "channel" => "orderbook",
              "data" => %{
                "bids" => bid_updates,
                "asks" => ask_updates
              }
            } ->
              bids =
                Enum.map(
                  bid_updates,
                  fn [price, size] -> {:bid, price, size} end
                )

              asks =
                Enum.map(
                  ask_updates,
                  fn [price, size] -> {:ask, price, size} end
                )

              [{:deltas, bids ++ asks}]

            %{
              "type" => "update",
              "channel" => "trades",
              "data" => data
            } ->
              for %{
                    "price" => price,
                    "size" => size,
                    "side" => side
                  } <- data do
                case side do
                  "buy" -> {:buys, [{price, size}]}
                  "sell" -> {:sells, [{price, size}]}
                end
              end
          end

        {:ok, instructions, current_state}
      end
    end
  end
end

defmodule Exchanges.FTX.Spot do
  @moduledoc """
  Spot markets.

  Relevant documentation:
  - https://docs.ftx.com/#websocket-api
  """

  @behaviour TranslationScheme

  use Exchanges.FTX

  @impl TranslationScheme
  def subscribe_msg(base_symbol, quote_symbol) do
    {:ok, json_str_book} =
      Jason.encode(%{
        "op" => "subscribe",
        "market" => "#{base_symbol}/#{quote_symbol}",
        "channel" => "orderbook"
      })

    {:ok, json_str_trade} =
      Jason.encode(%{
        "op" => "subscribe",
        "market" => "#{base_symbol}/#{quote_symbol}",
        "channel" => "trades"
      })

    {:ok, [json_str_book, json_str_trade]}
  end
end

defmodule Exchanges.FTX.Futures do
  @moduledoc """
  Futures markets.

  Relevant documentation:
  - https://docs.ftx.com/#websocket-api
  """

  @behaviour TranslationScheme

  use Exchanges.FTX

  @impl TranslationScheme
  def subscribe_msg(base_symbol, _quote_symbol) do
    {:ok, json_str_book} =
      Jason.encode(%{
        "op" => "subscribe",
        "market" => "#{base_symbol}-PERP",
        "channel" => "orderbook"
      })

    {:ok, json_str_trade} =
      Jason.encode(%{
        "op" => "subscribe",
        "market" => "#{base_symbol}-PERP",
        "channel" => "trades"
      })

    {:ok, [json_str_book, json_str_trade]}
  end
end

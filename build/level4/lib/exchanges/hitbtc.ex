defmodule Exchanges.HitBTC do
  @moduledoc """
  Translation scheme for the HitBTC websocket API.
  """

  defmacro __using__(_opts) do
    quote do
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
        symbol = current_state["symbol"]

        instructions =
          case json do
            %{"result" => data} ->
              [:noop]

            %{"ch" => ch, "snapshot" => snapshot} ->
              case ch do
                "trades" ->
                  [:noop]

                "orderbook/full" ->
                  bids =
                    for [price_str, size_str] <- snapshot[symbol]["b"] do
                      {price, _} = Float.parse(price_str)
                      {size, _} = Float.parse(size_str)
                      {price, size}
                    end

                  asks =
                    for [price_str, size_str] <- snapshot[symbol]["a"] do
                      {price, _} = Float.parse(price_str)
                      {size, _} = Float.parse(size_str)
                      {price, size}
                    end

                  [{:snapshot, bids, asks}]
              end

            %{"ch" => ch, "update" => update} ->
              case ch do
                "trades" ->
                  for update <- update[symbol] do
                    %{
                      "t" => epoch_ms,
                      "p" => price_str,
                      "q" => size_str,
                      "s" => side
                    } = update

                    {price, _} = Float.parse(price_str)
                    {size, _} = Float.parse(size_str)

                    epoch_micro = epoch_ms * 1000
                    {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

                    case side do
                      "buy" -> {:buys, [{price, size, timestamp}]}
                      "sell" -> {:sells, [{price, size, timestamp}]}
                    end
                  end

                "orderbook/full" ->
                  bids =
                    for [price_str, size_str] <- update[symbol]["b"] do
                      {price, _} = Float.parse(price_str)
                      {size, _} = Float.parse(size_str)
                      {:bid, price, size}
                    end

                  asks =
                    for [price_str, size_str] <- update[symbol]["a"] do
                      {price, _} = Float.parse(price_str)
                      {size, _} = Float.parse(size_str)
                      {:ask, price, size}
                    end

                  [{:deltas, bids ++ asks}]
              end
          end

        {:ok, instructions, current_state}
      end
    end
  end
end

defmodule Exchanges.HitBTC.Spot do
  @moduledoc """
  Spot markets.

  Relevant documentation:
  - https://api.hitbtc.com/#change-log
  - https://api.hitbtc.com/#socket-api-reference
  """

  @behaviour TranslationScheme

  use Exchanges.HitBTC

  @impl TranslationScheme
  def initial_state(base_symbol, quote_symbol) do
    %{"symbol" => "#{base_symbol}#{quote_symbol}"}
  end

  @impl TranslationScheme
  def subscribe_msg(base_symbol, quote_symbol) do
    {:ok, json_str_book} =
      Jason.encode(%{
        "method" => "subscribe",
        "ch" => "orderbook/full",
        "params" => %{
          "symbols" => ["#{base_symbol}#{quote_symbol}"]
        }
      })

    {:ok, json_str_trade} =
      Jason.encode(%{
        "method" => "subscribe",
        "ch" => "trades",
        "params" => %{
          "symbols" => ["#{base_symbol}#{quote_symbol}"],
          "limit" => 1
        }
      })

    {:ok, [json_str_book, json_str_trade]}
  end
end

defmodule Exchanges.HitBTC.Futures do
  @moduledoc """
  Futures markets.

  Relevant documentation:
  - https://api.hitbtc.com/#change-log
  - https://api.hitbtc.com/#socket-api-reference
  """

  @behaviour TranslationScheme

  use Exchanges.HitBTC

  @impl TranslationScheme
  def initial_state(base_symbol, quote_symbol) do
    %{"symbol" => "#{base_symbol}#{quote_symbol}_PERP"}
  end

  @impl TranslationScheme
  def subscribe_msg(base_symbol, quote_symbol) do
    {:ok, json_str_book} =
      Jason.encode(%{
        "method" => "subscribe",
        "ch" => "orderbook/full",
        "params" => %{
          "symbols" => ["#{base_symbol}#{quote_symbol}_PERP"]
        }
      })

    {:ok, json_str_trade} =
      Jason.encode(%{
        "method" => "subscribe",
        "ch" => "trades",
        "params" => %{
          "symbols" => ["#{base_symbol}#{quote_symbol}_PERP"],
          "limit" => 1
        }
      })

    {:ok, [json_str_book, json_str_trade]}
  end
end

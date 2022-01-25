defmodule Exchanges.HitBTC do
  @moduledoc """
  Contains translation scheme for the HitBTC websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state(base_symbol, quote_symbol) do
    %{"symbol" => "#{base_symbol}#{quote_symbol}"}
  end

  @impl TranslationScheme
  def make_ping_message() do
    {:ok, json_str} = Jason.encode(%{"op" => "ping"})
    json_str
  end

  @impl TranslationScheme
  def make_subscribe_messages(base_symbol, quote_symbol) do
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

    [json_str_book, json_str_trade]
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    symbol = sync_state["symbol"]

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

    {instructions, sync_state}
  end

  @impl TranslationScheme
  def check_sync_state(sync_state) do
    {:synced, sync_state}
  end
end

defmodule Exchanges.FTX do
  @moduledoc """
  Contains translation scheme for the FTX websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state(base_symbol, quote_symbol) do
    %{"something" => nil}
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

    [json_str_book, json_str_trade]
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    instructions =
      case json do
        %{"type" => "subscribed"} ->
          [:noop]

        %{"type" => "unsubscribed"} ->
          [:noop]

        %{"type" => "info"} ->
          [:noop]

        %{"type" => "pong"} ->
          IO.puts("PONG")

          [:noop]

        %{"type" => "error"} ->
          [:noop]

        %{
          "type" => "partial",
          "data" => %{
            "bids" => initial_bids,
            "asks" => initial_asks
          }
        } ->
          bids = Enum.map(initial_bids, fn [price, size] -> {price, size} end)
          asks = Enum.map(initial_asks, fn [price, size] -> {price, size} end)

          [{:snapshot, bids, asks}]

        %{
          "type" => "update",
          "channel" => "orderbook",
          "data" => %{
            "bids" => bid_updates,
            "asks" => ask_updates
          }
        } ->
          bids = Enum.map(bid_updates, fn [price, size] -> {:bid, price, size} end)
          asks = Enum.map(bid_updates, fn [price, size] -> {:ask, price, size} end)

          [{:deltas, bids ++ asks}]

        %{
          "type" => "update",
          "channel" => "trades",
          "data" => data
        } ->
          for %{
                "price" => price,
                "size" => size,
                "side" => side,
                "time" => timestamp_str
              } <- data do
            {:ok, timestamp, 0} = DateTime.from_iso8601(timestamp_str)

            case side do
              "buy" -> {:buys, [{price, size, timestamp}]}
              "sell" -> {:sells, [{price, size, timestamp}]}
            end
          end
      end

    {instructions, sync_state}
  end

  @impl TranslationScheme
  def check_sync_state(sync_state) do
    {:synced, sync_state}
  end
end

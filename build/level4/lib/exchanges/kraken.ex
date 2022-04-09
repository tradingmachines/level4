defmodule Exchanges.Kraken do
  @moduledoc """
  Contains translation scheme for the Kraken websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state(base_symbol, quote_symbol) do
    %{"something" => nil}
  end

  @impl TranslationScheme
  def make_ping_messages(sync_state) do
    {:ok, json_str} = Jason.encode(%{"op" => "ping"})
    [json_str]
  end

  @impl TranslationScheme
  def make_subscribe_messages(base_symbol, quote_symbol) do
    {:ok, json_str_book} =
      Jason.encode(%{
        "event" => "subscribe",
        "pair" => ["#{base_symbol}/#{quote_symbol}"],
        "subscription" => %{
          "name" => "book",
          "depth" => 100
        }
      })

    {:ok, json_str_trade} =
      Jason.encode(%{
        "event" => "subscribe",
        "pair" => ["#{base_symbol}/#{quote_symbol}"],
        "subscription" => %{
          "name" => "trade"
        }
      })

    [json_str_book, json_str_trade]
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    instructions =
      case json do
        %{"event" => event} ->
          case event do
            "systemStatus" -> [:noop]
            "subscriptionStatus" -> [:noop]
            "heartbeat" -> [:noop]
          end

        [_, %{"as" => initial_asks, "bs" => initial_bids}, _, _] ->
          bids =
            for [price_str, size_str, _] <- initial_bids do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)
              {price, size}
            end

          asks =
            for [price_str, size_str, _] <- initial_asks do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)
              {price, size}
            end

          [{:snapshot, bids, asks}]

        [_, %{"b" => bid_updates}, _, _] ->
          deltas =
            for bid_update <- bid_updates do
              {price, _} = Float.parse(Enum.at(bid_update, 0))
              {size, _} = Float.parse(Enum.at(bid_update, 1))
              {:bid, price, size}
            end

          [{:deltas, deltas}]

        [_, %{"a" => ask_updates}, _, _] ->
          deltas =
            for ask_update <- ask_updates do
              {price, _} = Float.parse(Enum.at(ask_update, 0))
              {size, _} = Float.parse(Enum.at(ask_update, 1))
              {:ask, price, size}
            end

          [{:deltas, deltas}]

        [_, %{"a" => ask_updates}, %{"b" => bid_updates}, _, _] ->
          bid_deltas =
            for bid_update <- bid_updates do
              {price, _} = Float.parse(Enum.at(bid_update, 0))
              {size, _} = Float.parse(Enum.at(bid_update, 1))
              {:bid, price, size}
            end

          ask_deltas =
            for ask_update <- ask_updates do
              {price, _} = Float.parse(Enum.at(ask_update, 0))
              {size, _} = Float.parse(Enum.at(ask_update, 1))
              {:ask, price, size}
            end

          [{:deltas, bid_deltas ++ ask_deltas}]

        [_, trades, _, _] ->
          for [price_str, size_str, timestamp_str, side, _, _] <- trades do
            {price, _} = Float.parse(price_str)
            {size, _} = Float.parse(size_str)
            {epoch, _} = Float.parse(timestamp_str)

            epoch_micro = trunc(epoch * 1_000_000)
            {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

            case side do
              "b" -> {:buys, [{price, size, timestamp}]}
              "s" -> {:sells, [{price, size, timestamp}]}
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

defmodule Exchanges.Kraken do
  @moduledoc """
  Contains translation scheme for the Kraken websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state() do
    %{"something" => nil}
  end

  @impl TranslationScheme
  def make_subscribe_messages(major_symbol, quote_symbol) do
    {:ok, json_str_book} =
      Jason.encode(%{
        "event" => "subscribe",
        "pair" => ["#{major_symbol}/#{quote_symbol}"],
        "subscription" => %{
          "name" => "book",
          "depth" => 100
        }
      })

    {:ok, json_str_trade} =
      Jason.encode(%{
        "event" => "subscribe",
        "pair" => ["#{major_symbol}/#{quote_symbol}"],
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

        [_, %{"bs" => initial_bids, "as" => initial_asks}, _, _] ->
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
            for [price_str, size_str, _] <- bid_updates do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)
              {:bid, price, size}
            end ++
              for [price_str, size_str, _, _] <- bid_updates do
                {price, _} = Float.parse(price_str)
                {size, _} = Float.parse(size_str)
                {:bid, price, size}
              end

          [{:deltas, deltas}]

        [_, %{"a" => ask_updates}, _, _] ->
          deltas =
            for [price_str, size_str, _] <- ask_updates do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)
              {:ask, price, size}
            end ++
              for [price_str, size_str, _, _] <- ask_updates do
                {price, _} = Float.parse(price_str)
                {size, _} = Float.parse(size_str)
                {:ask, price, size}
              end

          [{:deltas, deltas}]

        [_, %{"a" => bid_updates}, %{"b" => ask_updates}, _, _] ->
          bid_deltas =
            for [price_str, size_str, _] <- bid_updates do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)
              {:bid, price, size}
            end ++
              for [price_str, size_str, _, _] <- bid_updates do
                {price, _} = Float.parse(price_str)
                {size, _} = Float.parse(size_str)
                {:bid, price, size}
              end

          ask_deltas =
            for [price_str, size_str, _] <- ask_updates do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)
              {:ask, price, size}
            end ++
              for [price_str, size_str, _, _] <- ask_updates do
                {price, _} = Float.parse(price_str)
                {size, _} = Float.parse(size_str)
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

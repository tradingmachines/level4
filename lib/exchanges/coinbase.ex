defmodule Exchanges.Coinbase do
  @moduledoc """
  Contains translation scheme for the Coinbase Pro websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state() do
    %{"previous_sequence_number" => 0}
  end

  @impl TranslationScheme
  def make_subscribe_message(major_symbol, quote_symbol) do
    Jason.encode(%{
      "type" => "subscribe",
      "product_ids" => ["#{major_symbol}-#{quote_symbol}"],
      "channels" => ["heartbeat", "level2", "matches"]
    })
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    # all coinbase messages have a "type" field.
    instruction =
      case json["type"] do
        # ...
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

        # ...
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

        # ...
        "subscriptions" ->
          :noop

        # ...
        "heartbeat" ->
          :noop

        # ...
        "error" ->
          :noop

        # ...
        "last_match" ->
          :noop

        # ...
        "match" ->
          :noop

        # ...
        _ ->
          :unknown
      end

    {[instruction], sync_state}
  end

  @impl TranslationScheme
  def check_sync_state(sync_state) do
    {:synced, sync_state}
  end
end

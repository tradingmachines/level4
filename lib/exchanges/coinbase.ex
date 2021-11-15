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
    case json["type"] do
      # ...
      "subscriptions" ->
        {:noop, sync_state}

      # ...
      "snapshot" ->
        bids =
          for [price, size] <- json["bids"] do
            {Float.parse(price), Float.parse(size)}
          end

        asks =
          for [price, size] <- json["asks"] do
            {Float.parse(price), Float.parse(size)}
          end

        {:snapshot, bids, asks, sync_state}

      # ...
      "heartbeat" ->
        {:noop, sync_state}

      # ...
      "error" ->
        {:noop, sync_state}

      # ...
      "last_match" ->
        {:noop, sync_state}

      # ...
      "match" ->
        {:noop, sync_state}

      # ...
      "l2update" ->
        deltas =
          for [side, price, size] <- json["changes"] do
            case side do
              "buy" ->
                {:bid, Float.parse(price), Float.parse(size)}

              "sell" ->
                {:ask, Float.parse(price), Float.parse(size)}
            end
          end

        {:deltas, deltas, sync_state}

      # ...
      _ ->
        :unknown
    end
  end
end

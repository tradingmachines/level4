defmodule Exchanges.Poloniex do
  @moduledoc """
  Contains translation scheme for the Poloniex websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state() do
    %{"previous_sequence_number" => 0}
  end

  @impl TranslationScheme
  def make_subscribe_message(major_symbol, quote_symbol) do
    Jason.encode(%{
      "command" => "subscribe",
      "channel" => "#{major_symbol}_#{quote_symbol}"
    })
  end

  @impl TranslationScheme
  def translate({channel_id, sequence_num, messages}, sync_state) do
    instructions =
      for message <- messages do
        case message do
          ["i", snapshot, epoch_ms] ->
            [asks, bids] = snapshot["orderBook"]

            bid_levels =
              for {price_str, size_str} <- bids do
                {price, _} = Float.parse(price_str)
                {size, _} = Float.parse(size_str)

                {price, size}
              end

            ask_levels =
              for {price_str, size_str} <- asks do
                {price, _} = Float.parse(price_str)
                {size, _} = Float.parse(size_str)

                {price, size}
              end

            {:snapshot, bid_levels, ask_levels}

          ["o", 1, price, size, epoch_ms] ->
            {:bid, Float.parse(price), Float.parse(size)}

          ["o", 0, price, size, epoch_ms] ->
            {:ask, Float.parse(price), Float.parse(size)}

          ["t", trade_id, 1, price, size, timestamp, epoch_ms] ->
            :noop

          ["t", trade_id, 0, price, size, timestamp, epoch_ms] ->
            :noop
        end
      end

    {instructions, sync_state}
  end
end

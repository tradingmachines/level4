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
      "channel" => "#{quote_symbol}_#{major_symbol}"
    })
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    instructions =
      case json do
        [1010] ->
          [:noop]

        [1002] ->
          [:noop]

        [1003] ->
          [:noop]

        [channel_id, sequence_num, messages] ->
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

              ["o", 1, price_str, size_str, epoch_ms] ->
                {price, _} = Float.parse(price_str)
                {size, _} = Float.parse(size_str)
                {:delta, {:bid, price, size}}

              ["o", 0, price_str, size_str, epoch_ms] ->
                {price, _} = Float.parse(price_str)
                {size, _} = Float.parse(size_str)
                {:delta, {:ask, price, size}}

              ["t", trade_id, 1, price_Str, size_str, timestamp, epoch_ms] ->
                :noop

              ["t", trade_id, 0, price_str, size_str, timestamp, epoch_ms] ->
                :noop
            end
          end
      end

    {instructions, sync_state}
  end
end

defmodule Exchange.Poloniex do
  @moduledoc """
  Translation scheme for the Poloniex websocket API.
  """

  defmacro __using__(_opts) do
    quote do
      @impl TranslationScheme
      def initial_state(base_symbol, quote_symbol) do
        %{"previous_sequence_number" => 0}
      end

      @impl TranslationScheme
      def ping_msg(current_state) do
        {:ok, json_str} = Jason.encode(%{"op" => "ping"})
        {:ok, [json_str]}
      end

      @impl TranslationScheme
      def subscribe_msg(base_symbol, quote_symbol) do
        {:ok, json_str} =
          Jason.encode(%{
            "command" => "subscribe",
            "channel" => "#{quote_symbol}_#{base_symbol}"
          })

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
                    {:deltas, [{:bid, price, size}]}

                  ["o", 0, price_str, size_str, epoch_ms] ->
                    {price, _} = Float.parse(price_str)
                    {size, _} = Float.parse(size_str)
                    {:deltas, [{:ask, price, size}]}

                  [
                    "t",
                    trade_id,
                    1,
                    price_str,
                    size_str,
                    _,
                    _
                  ] ->
                    {price, _} = Float.parse(price_str)
                    {size, _} = Float.parse(size_str)

                    {:buys, [{price, size}]}

                  [
                    "t",
                    trade_id,
                    0,
                    price_str,
                    size_str,
                    _,
                    _
                  ] ->
                    {price, _} = Float.parse(price_str)
                    {size, _} = Float.parse(size_str)

                    {:sells, [{price, size}]}
                end
              end
          end

        {:ok, instructions, current_state}
      end
    end
  end
end

defmodule Exchange.Poloniex.Spot do
  @moduledoc """
  Spot markets.

  Relevant documentation:
  - https://docs.poloniex.com/#changelog
  - https://docs.poloniex.com/#websocket-api
  """

  @behaviour TranslationScheme

  use Exchange.Poloniex
end

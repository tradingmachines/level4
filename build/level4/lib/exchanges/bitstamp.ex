defmodule Exchanges.Bitstamp do
  @moduledoc """
  Translation scheme for the Bitstamp websocket API.
  """

  defmacro __using__(_opts) do
    quote do
      @impl TranslationScheme
      def initial_state(base_symbol, quote_symbol) do
        %{"did_snapshot" => false}
      end

      @impl TranslationScheme
      def ping_msg(current_state) do
        {:ok, json_str} = Jason.encode(%{"event" => "bts:heartbeat"})
        {:ok, [json_str]}
      end

      @impl TranslationScheme
      def subscribe_msg(base_symbol, quote_symbol) do
        base_symbol_lower = String.downcase(base_symbol)
        quote_symbol_lower = String.downcase(quote_symbol)

        {:ok, json_str_book} =
          Jason.encode(%{
            "event" => "bts:subscribe",
            "data" => %{
              "channel" => "order_book_#{base_symbol_lower}#{quote_symbol_lower}"
            }
          })

        {:ok, json_str_trade} =
          Jason.encode(%{
            "event" => "bts:subscribe",
            "data" => %{
              "channel" => "live_trades_#{base_symbol_lower}#{quote_symbol_lower}"
            }
          })

        {:ok, [json_str_book, json_str_trade]}
      end

      @impl TranslationScheme
      def synchronised?(current_state) do
        # TODO
        true
      end

      @impl TranslationScheme
      def translate(json, current_state) do
        {instructions, next_state} =
          case json do
            %{"event" => "bts:subscription_succeeded"} ->
              {[:noop], current_state}

            %{"event" => "bts:heartbeat"} ->
              {[:noop], current_state}

            %{"event" => "bts:request_reconnect"} ->
              {[:reconnect], current_state}

            %{
              "event" => "data",
              "data" => %{
                "bids" => bid_strs,
                "asks" => ask_strs
              }
            } ->
              if current_state["did_snapshot"] do
                bids =
                  for [price_str, size_str] <- bid_strs do
                    {price, _} = Float.parse(price_str)
                    {size, _} = Float.parse(size_str)
                    {:bid, price, size}
                  end

                asks =
                  for [price_str, size_str] <- ask_strs do
                    {price, _} = Float.parse(price_str)
                    {size, _} = Float.parse(size_str)
                    {:ask, price, size}
                  end

                {[{:deltas, bids ++ asks}], current_state}
              else
                bids =
                  for [price_str, size_str] <- bid_strs do
                    {price, _} = Float.parse(price_str)
                    {size, _} = Float.parse(size_str)
                    {price, size}
                  end

                asks =
                  for [price_str, size_str] <- ask_strs do
                    {price, _} = Float.parse(price_str)
                    {size, _} = Float.parse(size_str)
                    {price, size}
                  end

                {
                  [{:snapshot, bids, asks}],
                  %{current_state | "did_snapshot" => true}
                }
              end

            %{
              "event" => "trade",
              "data" => %{
                "price" => price_int,
                "amount" => size_int,
                "timestamp" => epoch_sec_str,
                "type" => side
              }
            } ->
              price = price_int / 1
              size = size_int / 1

              {epoch_sec, _} = Integer.parse(epoch_sec_str)
              epoch_ms = epoch_sec * 1000
              epoch_micro = epoch_ms * 1000
              {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

              case side do
                0 ->
                  {
                    [{:buys, [{price, size, timestamp}]}],
                    current_state
                  }

                1 ->
                  {
                    [{:sells, [{price, size, timestamp}]}],
                    current_state
                  }
              end
          end

        {:ok, instructions, next_state}
      end
    end
  end
end

defmodule Exchanges.Bitstamp.Spot do
  @moduledoc """
  Spot markets.

  Relevant documentation:
  - https://www.bitstamp.net/websocket/v2/
  """

  @behaviour TranslationScheme

  use Exchanges.Bitstamp
end

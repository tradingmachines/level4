defmodule Exchanges.Kraken do
  @moduledoc """
  Translation scheme for the Kraken websocket API.
  """

  defmacro __using__(_opts) do
    quote do
      @impl TranslationScheme
      def initial_state(base_symbol, quote_symbol) do
        %{}
      end

      @impl TranslationScheme
      def ping_msg(current_state) do
        {:ok, json_str} = Jason.encode(%{"op" => "ping"})
        {:ok, [json_str]}
      end

      @impl TranslationScheme
      def subscribe_msg(base_symbol, quote_symbol) do
        {:ok, json_str_book} =
          Jason.encode(%{
            "event" => "subscribe",
            "feed" => "book",
            "product_ids" => [
              "PI_#{base_symbol}#{quote_symbol}"
            ]
          })

        {:ok, json_str_trade} =
          Jason.encode(%{
            "event" => "subscribe",
            "feed" => "trade",
            "product_ids" => [
              "PI_#{base_symbol}#{quote_symbol}"
            ]
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
        instructions =
          case json do
            %{"event" => "subscribed", "feed" => "book"} ->
              [:noop]

            %{"event" => "subscribed", "feed" => "trade"} ->
              [:noop]

            %{
              "feed" => "book_snapshot",
              "bids" => initial_bids,
              "asks" => initial_asks
            } ->
              bids =
                for %{
                      "price" => price,
                      "qty" => size
                    } <- initial_bids do
                  {price, size}
                end

              asks =
                for %{
                      "price" => price,
                      "qty" => size
                    } <- initial_asks do
                  {price, size}
                end

              [{:snapshot, bids, asks}]

            %{
              "feed" => "book",
              "side" => side,
              "price" => price,
              "qty" => size
            } ->
              deltas =
                case side do
                  "buy" -> [{:bid, price, size}]
                  "sell" -> [{:ask, price, size}]
                end

              [{:deltas, deltas}]

            %{
              "feed" => "trade",
              "side" => side,
              "price" => price,
              "qty" => size,
              "time" => epoch_ms
            } ->
              epoch_micro = epoch_ms * 1000
              {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

              case side do
                "buy" -> {:buys, [{price, size, timestamp}]}
                "sell" -> {:sells, [{price, size, timestamp}]}
              end
          end

        {:ok, instructions, current_state}
      end
    end
  end
end

defmodule Exchanges.Kraken.Spot do
  @moduledoc """
  Spot markets.

  Relevant documentation:
  - https://docs.kraken.com/websockets/#changelog
  - https://docs.kraken.com/websockets/
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def initial_state(_base_symbol, _quote_symbol) do
    %{}
  end

  @impl TranslationScheme
  def ping_msg(_current_state) do
    {:ok, json_str} = Jason.encode(%{"op" => "ping"})
    {:ok, [json_str]}
  end

  @impl TranslationScheme
  def subscribe_msg(base_symbol, quote_symbol) do
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

    {:ok, [json_str_book, json_str_trade]}
  end

  @impl TranslationScheme
  def synchronised?(_current_state) do
    # TODO
    true
  end

  @impl TranslationScheme
  def translate(json, current_state) do
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

    {:ok, instructions, current_state}
  end
end

defmodule Exchanges.Kraken.Futures do
  @moduledoc """
  Futures markets.

  Relevant documentation:
  - https://support.kraken.com/hc/en-us/sections/360012894412-Futures-API
  - https://support.kraken.com/hc/en-us/articles/360022635912-Book
  """

  @behaviour TranslationScheme

  use Exchanges.Kraken
end

defmodule Exchanges.Kraken.Inverse do
  @moduledoc """
  Inverse futures markets.

  Relevant documentation:
  - https://support.kraken.com/hc/en-us/sections/360012894412-Futures-API
  - https://support.kraken.com/hc/en-us/articles/360022635912-Book
  """

  @behaviour TranslationScheme

  use Exchanges.Kraken
end

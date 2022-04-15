defmodule Exchanges.Bybit.Spot do
  @moduledoc """
  Translation scheme for the Bybit spot websocket API.

  Change log and websocket docs:
  - https://bybit-exchange.github.io/docs/spot/#t-changelog
  - https://bybit-exchange.github.io/docs/spot/#t-websocket
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def initial_state(base_symbol, quote_symbol) do
    %{"did_snapshot" => false}
  end

  @impl TranslationScheme
  def ping_msg(current_state) do
    timestamp = DateTime.utc_now()
    epoch_ms = DateTime.to_unix(timestamp, :millisecond)

    {:ok, json_str} = Jason.encode(%{"ping" => epoch_ms})
    {:ok, [json_str]}
  end

  @impl TranslationScheme
  def subscribe_msg(base_symbol, quote_symbol) do
    {:ok, json_str_book} =
      Jason.encode(%{
        "topic" => "depth",
        "event" => "sub",
        "params" => %{
          "symbol" => "#{base_symbol}#{quote_symbol}",
          "binary" => false
        }
      })

    {:ok, json_str_trade} =
      Jason.encode(%{
        "topic" => "trade",
        "event" => "sub",
        "params" => %{
          "symbol" => "#{base_symbol}#{quote_symbol}",
          "binary" => false
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
        %{"event" => "sub"} ->
          {[:noop], current_state}

        %{"pong" => _} ->
          {[:noop], current_state}

        %{"topic" => "depth", "data" => data} ->
          if current_state["did_snapshot"] do
            bids =
              for [price_str, size_str] <- data["b"] do
                {price, _} = Float.parse(price_str)
                {size, _} = Float.parse(size_str)
                {:bid, price, size}
              end

            asks =
              for [price_str, size_str] <- data["a"] do
                {price, _} = Float.parse(price_str)
                {size, _} = Float.parse(size_str)
                {:ask, price, size}
              end

            {[{:deltas, bids ++ asks}], current_state}
          else
            bids =
              for [price_str, size_str] <- data["b"] do
                {price, _} = Float.parse(price_str)
                {size, _} = Float.parse(size_str)
                {price, size}
              end

            asks =
              for [price_str, size_str] <- data["a"] do
                {price, _} = Float.parse(price_str)
                {size, _} = Float.parse(size_str)
                {price, size}
              end

            {[{:snapshot, bids, asks}], %{current_state | "did_snapshot" => true}}
          end

        %{"topic" => "trade", "data" => data} ->
          {price, _} = Float.parse(data["p"])
          {size, _} = Float.parse(data["q"])

          epoch_ms = data["t"]
          epoch_micro = epoch_ms * 1000
          {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

          case data["m"] do
            true -> {[{:buys, [{price, size, timestamp}]}], current_state}
            false -> {[{:sells, [{price, size, timestamp}]}], current_state}
          end
      end

    {:ok, instructions, next_state}
  end
end

defmodule Exchanges.Bybit.Perp.USDT do
  @moduledoc """
  Translation scheme for the Bybit perpetual USDT futures
  websocket API.

  Change log and websocket docs:
  - https://bybit-exchange.github.io/docs/linear/#t-changelog
  - https://bybit-exchange.github.io/docs/linear/#t-websocket
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def initial_state(base_symbol, quote_symbol) do
    %{"something" => nil}
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
        "op" => "subscribe",
        "args" => [
          "orderBookL2_25.#{base_symbol}#{quote_symbol}",
          "trade.#{base_symbol}#{quote_symbol}"
        ]
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
        %{"res_message" => "pong"} ->
          [:noop]

        %{"success" => true} ->
          [:noop]

        %{"type" => "snapshot", "data" => %{"order_book" => levels}} ->
          bids =
            levels
            |> Enum.filter(fn %{"side" => side} -> side == "Buy" end)
            |> Enum.map(fn %{"price" => price_str, "size" => size_int} ->
              {price, _} = Float.parse(price_str)
              size = size_int / 1
              {price, size}
            end)

          asks =
            levels
            |> Enum.filter(fn %{"side" => side} -> side == "Sell" end)
            |> Enum.map(fn %{"price" => price_str, "size" => size_int} ->
              {price, _} = Float.parse(price_str)
              size = size_int / 1
              {price, size}
            end)

          [{:snapshot, bids, asks}]

        %{"type" => "delta", "data" => data} ->
          inserts =
            for %{
                  "price" => price_str,
                  "size" => size_int,
                  "side" => side
                } <- data["insert"] do
              {price, _} = Float.parse(price_str)
              size = size_int / 1

              case side do
                "Buy" -> {:bid, price, size}
                "Sell" -> {:ask, price, size}
              end
            end

          updates =
            for %{
                  "price" => price_str,
                  "size" => size_int,
                  "side" => side
                } <- data["update"] do
              {price, _} = Float.parse(price_str)
              size = size_int / 1

              case side do
                "Buy" -> {:bid, price, size}
                "Sell" -> {:ask, price, size}
              end
            end

          deletes =
            for %{
                  "price" => price_str,
                  "side" => side
                } <- data["delete"] do
              {price, _} = Float.parse(price_str)

              case side do
                "Buy" -> {:bid, price, 0}
                "Sell" -> {:ask, price, 0}
              end
            end

          [{:deltas, inserts ++ updates ++ deletes}]

        %{"data" => data} ->
          buys =
            data
            |> Enum.filter(fn %{"side" => side} -> side == "Buy" end)
            |> Enum.map(fn %{
                             "price" => price_str,
                             "size" => size_int,
                             "trade_time_ms" => trade_time_ms_str
                           } ->
              {price, _} = Float.parse(price_str)
              size = size_int / 1

              {epoch_ms, _} = Integer.parse(trade_time_ms_str)
              epoch_micro = epoch_ms * 1000
              {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

              {price, size, timestamp}
            end)

          sells =
            data
            |> Enum.filter(fn %{"side" => side} -> side == "Sell" end)
            |> Enum.map(fn %{
                             "price" => price_str,
                             "size" => size_int,
                             "trade_time_ms" => trade_time_ms_str
                           } ->
              {price, _} = Float.parse(price_str)
              size = size_int / 1

              {epoch_ms, _} = Integer.parse(trade_time_ms_str)
              epoch_micro = epoch_ms * 1000
              {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

              {price, size, timestamp}
            end)

          [{:buys, buys}, {:sells, sells}]
      end

    {:ok, instructions, current_state}
  end
end

defmodule Exchanges.Bybit.Perp.Inverse do
  @moduledoc """
  Translation scheme for the Bybit inverse perpetual futures
  websocket API.

  Change log and websocket docs:
  - https://bybit-exchange.github.io/docs/inverse_futures/#t-changelog
  - https://bybit-exchange.github.io/docs/inverse_futures/#t-websocket
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def initial_state(base_symbol, quote_symbol) do
    %{"something" => nil}
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
        "op" => "subscribe",
        "args" => [
          "orderBookL2_25.#{base_symbol}#{quote_symbol}",
          "trade.#{base_symbol}#{quote_symbol}"
        ]
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
        %{"res_message" => "pong"} ->
          [:noop]

        %{"success" => true} ->
          [:noop]

        %{"type" => "snapshot", "data" => levels} ->
          bids =
            levels
            |> Enum.filter(fn %{"side" => side} -> side == "Buy" end)
            |> Enum.map(fn %{"price" => price_str, "size" => size_int} ->
              {price, _} = Float.parse(price_str)
              size = size_int / 1
              {price, size}
            end)

          asks =
            levels
            |> Enum.filter(fn %{"side" => side} -> side == "Sell" end)
            |> Enum.map(fn %{"price" => price_str, "size" => size_int} ->
              {price, _} = Float.parse(price_str)
              size = size_int / 1
              {price, size}
            end)

          [{:snapshot, bids, asks}]

        %{"type" => "delta", "data" => data} ->
          inserts =
            for %{
                  "price" => price_str,
                  "size" => size_int,
                  "side" => side
                } <- data["insert"] do
              {price, _} = Float.parse(price_str)
              size = size_int / 1

              case side do
                "Buy" -> {:bid, price, size}
                "Sell" -> {:ask, price, size}
              end
            end

          updates =
            for %{
                  "price" => price_str,
                  "size" => size_int,
                  "side" => side
                } <- data["update"] do
              {price, _} = Float.parse(price_str)
              size = size_int / 1

              case side do
                "Buy" -> {:bid, price, size}
                "Sell" -> {:ask, price, size}
              end
            end

          deletes =
            for %{
                  "price" => price_str,
                  "side" => side
                } <- data["delete"] do
              {price, _} = Float.parse(price_str)

              case side do
                "Buy" -> {:bid, price, 0}
                "Sell" -> {:ask, price, 0}
              end
            end

          [{:deltas, inserts ++ updates ++ deletes}]

        %{"data" => data} ->
          buys =
            data
            |> Enum.filter(fn %{"side" => side} -> side == "Buy" end)
            |> Enum.map(fn %{
                             "price" => price_int,
                             "size" => size_int,
                             "trade_time_ms" => epoch_ms
                           } ->
              price = price_int / 1
              size = size_int / 1

              epoch_micro = epoch_ms * 1000
              {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

              {price, size, timestamp}
            end)

          sells =
            data
            |> Enum.filter(fn %{"side" => side} -> side == "Sell" end)
            |> Enum.map(fn %{
                             "price" => price_int,
                             "size" => size_int,
                             "trade_time_ms" => epoch_ms
                           } ->
              price = price_int / 1
              size = size_int / 1

              epoch_micro = epoch_ms * 1000
              {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

              {price, size, timestamp}
            end)

          [{:buys, buys}, {:sells, sells}]
      end

    {:ok, instructions, current_state}
  end
end

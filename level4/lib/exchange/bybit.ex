defmodule Exchange.Bybit do
  @moduledoc """
  Translation scheme for the Bybit websocket API.
  """

  defmacro __using__(_opts) do
    quote do
    end
  end
end

defmodule Exchange.Bybit.Spot do
  @moduledoc """
  Spot markets.

  Relevant documentation:
  - https://bybit-exchange.github.io/docs/spot/#t-changelog
  - https://bybit-exchange.github.io/docs/spot/#t-websocket
  """

  @behaviour TranslationScheme

  use Exchange.Bybit

  def infer_deltas(side, old, new) do
    insert =
      new
      |> Enum.filter(fn {price, _} ->
        not Map.has_key?(old, price)
      end)
      |> Enum.map(fn {price, size} ->
        {side, price, size}
      end)

    update =
      new
      |> Enum.filter(fn {price, size} ->
        Map.has_key?(old, price) and old[price] != size
      end)
      |> Enum.map(fn {price, size} ->
        {side, price, size}
      end)

    delete =
      old
      |> Enum.filter(fn {price, _} ->
        not Map.has_key?(new, price)
      end)
      |> Enum.map(fn {price, _} ->
        {side, price, 0}
      end)

    insert ++ update ++ delete
  end

  @impl TranslationScheme
  def initial_state(base_symbol, quote_symbol) do
    %{
      "did_snapshot" => false,
      "bids" => %{},
      "asks" => %{}
    }
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

        %{
          "topic" => "depth",
          "data" => %{
            "b" => bid_strs,
            "a" => ask_strs
          }
        } ->
          bids =
            for [price_str, size_str] <- bid_strs do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)
              {price, size}
            end
            |> Enum.into(%{})

          asks =
            for [price_str, size_str] <- ask_strs do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)
              {price, size}
            end
            |> Enum.into(%{})

          if current_state["did_snapshot"] do
            bid_deltas =
              infer_deltas(
                :bid,
                current_state["bids"],
                bids
              )

            ask_deltas =
              infer_deltas(
                :ask,
                current_state["asks"],
                asks
              )

            {
              [{:deltas, bid_deltas ++ ask_deltas}],
              %{
                current_state
                | "bids" => bids,
                  "asks" => asks
              }
            }
          else
            {
              [{:snapshot, bids, asks}],
              %{
                current_state
                | "did_snapshot" => true,
                  "bids" => bids,
                  "asks" => asks
              }
            }
          end

        %{
          "topic" => "trade",
          "data" => %{
            "p" => price_str,
            "q" => size_str,
            "m" => buy_side_is_taker
          }
        } ->
          {price, _} = Float.parse(price_str)
          {size, _} = Float.parse(size_str)

          case buy_side_is_taker do
            true ->
              {
                [{:buys, [{price, size}]}],
                current_state
              }

            false ->
              {
                [{:sells, [{price, size}]}],
                current_state
              }
          end
      end

    {:ok, instructions, next_state}
  end
end

defmodule Exchange.Bybit.Futures do
  @moduledoc """
  Futures markets.

  Relevant documentation:
  - https://bybit-exchange.github.io/docs/linear/#t-changelog
  - https://bybit-exchange.github.io/docs/linear/#t-websocket
  """

  @behaviour TranslationScheme

  use Exchange.Bybit

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

        %{
          "type" => "snapshot",
          "data" => %{"order_book" => levels}
        } ->
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

        %{
          "type" => "delta",
          "data" => data
        } ->
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

              {price, size}
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

              {price, size}
            end)

          [{:buys, buys}, {:sells, sells}]
      end

    {:ok, instructions, current_state}
  end
end

defmodule Exchange.Bybit.Inverse do
  @moduledoc """
  Inverse futures markets.

  Relevant documentation:
  - https://bybit-exchange.github.io/docs/inverse_futures/#t-changelog
  - https://bybit-exchange.github.io/docs/inverse_futures/#t-websocket
  """

  @behaviour TranslationScheme

  use Exchange.Bybit

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

        %{
          "type" => "snapshot",
          "data" => levels
        } ->
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

        %{
          "type" => "delta",
          "data" => data
        } ->
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
            |> Enum.map(fn %{"price" => price_int, "size" => size_int} ->
              price = price_int / 1
              size = size_int / 1

              {price, size}
            end)

          sells =
            data
            |> Enum.filter(fn %{"side" => side} -> side == "Sell" end)
            |> Enum.map(fn %{"price" => price_int, "size" => size_int} ->
              price = price_int / 1
              size = size_int / 1

              {price, size}
            end)

          [{:buys, buys}, {:sells, sells}]
      end

    {:ok, instructions, current_state}
  end
end

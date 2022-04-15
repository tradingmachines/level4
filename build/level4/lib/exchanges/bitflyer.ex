defmodule Exchanges.Bitflyer.Spot do
  @moduledoc """
  Translation scheme for the Bitflyer websocket API.

  Websocket docs:
  - https://lightning.bitflyer.com/docs#order-book
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def initial_state(base_symbol, quote_symbol) do
    %{"base_symbol" => base_symbol, "quote_symbol" => quote_symbol}
  end

  @impl TranslationScheme
  def ping_msg(current_state) do
    {:ok, json_str} = Jason.encode(%{"op" => "ping"})
    {:ok, [json_str]}
  end

  @impl TranslationScheme
  def subscribe_msg(base_symbol, quote_symbol) do
    {:ok, json_str_snapshot} =
      Jason.encode(%{
        "id" => "json_str_snapshot",
        "jsonrpc" => "2.0",
        "method" => "subscribe",
        "params" => %{
          "channel" => "lightning_board_snapshot_#{base_symbol}_#{quote_symbol}"
        }
      })

    {:ok, json_str_updates} =
      Jason.encode(%{
        "id" => "json_str_updates",
        "jsonrpc" => "2.0",
        "method" => "subscribe",
        "params" => %{
          "channel" => "lightning_board_#{base_symbol}_#{quote_symbol}"
        }
      })

    {:ok, json_str_trade} =
      Jason.encode(%{
        "id" => "json_str_trade",
        "jsonrpc" => "2.0",
        "method" => "subscribe",
        "params" => %{
          "channel" => "lightning_executions_#{base_symbol}_#{quote_symbol}"
        }
      })

    {:ok, [json_str_snapshot, json_str_updates, json_str_trade]}
  end

  @impl TranslationScheme
  def synchronised?(current_state) do
    # TODO
    true
  end

  @impl TranslationScheme
  def translate(json, current_state) do
    base_symbol = current_state["base_symbol"]
    quote_symbol = current_state["quote_symbol"]

    instructions =
      case json do
        %{"id" => "json_str_snapshot", "result" => true} ->
          [:noop]

        %{"id" => "json_str_updates", "result" => true} ->
          [:noop]

        %{"id" => "json_str_trade", "result" => true} ->
          [:noop]

        %{
          "params" => %{
            "channel" => channel,
            "message" => message
          }
        } ->
          cond do
            channel == "lightning_board_snapshot_#{base_symbol}_#{quote_symbol}" ->
              %{"bids" => bid_updates, "asks" => ask_updates} = message

              bids =
                for %{"price" => price_int, "size" => size_int} <- bid_updates do
                  price = price_int / 1
                  size = size_int / 1
                  {price, size}
                end

              asks =
                for %{"price" => price_int, "size" => size_int} <- ask_updates do
                  price = price_int / 1
                  size = size_int / 1
                  {price, size}
                end

              [{:snapshot, bids, asks}]

            channel == "lightning_board_#{base_symbol}_#{quote_symbol}" ->
              %{"bids" => bid_updates, "asks" => ask_updates} = message

              bids =
                for %{"price" => price_int, "size" => size_int} <- bid_updates do
                  price = price_int / 1
                  size = size_int / 1
                  {:bid, price, size}
                end

              asks =
                for %{"price" => price_int, "size" => size_int} <- ask_updates do
                  price = price_int / 1
                  size = size_int / 1
                  {:ask, price, size}
                end

              [{:deltas, bids ++ asks}]

            channel == "lightning_executions_#{base_symbol}_#{quote_symbol}" ->
              buys =
                message
                |> Enum.filter(fn %{"side" => side} -> side == "BUY" end)
                |> Enum.map(fn %{
                                 "price" => price_int,
                                 "size" => size_int,
                                 "exec_date" => timestamp_str
                               } ->
                  price = price_int / 1
                  size = size_int / 1

                  {:ok, timestamp_ms, 0} = DateTime.from_iso8601(timestamp_str)

                  {:ok, timestamp_micro} =
                    timestamp_ms
                    |> DateTime.to_unix(:microsecond)
                    |> DateTime.from_unix(:microsecond)

                  {price, size, timestamp_micro}
                end)

              sells =
                message
                |> Enum.filter(fn %{"side" => side} -> side == "SELL" end)
                |> Enum.map(fn %{
                                 "price" => price_int,
                                 "size" => size_int,
                                 "exec_date" => timestamp_str
                               } ->
                  price = price_int / 1
                  size = size_int / 1

                  {:ok, timestamp_ms, 0} = DateTime.from_iso8601(timestamp_str)

                  {:ok, timestamp_micro} =
                    timestamp_ms
                    |> DateTime.to_unix(:microsecond)
                    |> DateTime.from_unix(:microsecond)

                  {price, size, timestamp_micro}
                end)

              [{:buys, buys}, {:sells, sells}]
          end
      end

    {:ok, instructions, current_state}
  end
end

defmodule Exchanges.Bitmex do
  @moduledoc """
  Contains translation scheme for the Bitmex websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state(base_symbol, quote_symbol) do
    %{"id_to_price" => %{}}
  end

  @impl TranslationScheme
  def make_ping_message() do
    "ping"
  end

  @impl TranslationScheme
  def make_subscribe_messages(base_symbol, quote_symbol) do
    {:ok, json_str} =
      Jason.encode(%{
        "op" => "subscribe",
        "args" => [
          "orderBookL2_25:#{base_symbol}#{quote_symbol}",
          "trade:#{base_symbol}#{quote_symbol}"
        ]
      })

    [json_str]
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    {instructions, new_sync_state} =
      case json do
        %{"docs" => _, "info" => _, "version" => _} ->
          {[:noop], sync_state}

        %{"request" => %{"op" => "subscribe"}, "success" => true} ->
          {[:noop], sync_state}

        %{"table" => "trade", "action" => "partial"} ->
          {[:noop], sync_state}

        %{
          "table" => "orderBookL2_25",
          "action" => "partial",
          "data" => levels
        } ->
          {bids, asks, id_to_price} =
            levels
            |> Enum.reduce(
              {[], [], %{}},
              fn level, {bids, asks, id_to_price} ->
                %{
                  "id" => id,
                  "price" => price_int,
                  "size" => size_int,
                  "side" => side
                } = level

                price = price_int / 1
                size = size_int / 1

                new_id_to_price = Map.put(id_to_price, id, price)

                case side do
                  "Buy" ->
                    bid = {price, size}
                    {bids ++ [bid], asks, new_id_to_price}

                  "Sell" ->
                    ask = {price, size}
                    {bids, asks ++ [ask], new_id_to_price}
                end
              end
            )

          {[{:snapshot, bids, asks}], %{sync_state | "id_to_price" => id_to_price}}

        %{
          "table" => "orderBookL2_25",
          "action" => action,
          "data" => data
        } ->
          {deltas, new_id_to_price} =
            data
            |> Enum.reduce(
              {[], sync_state["id_to_price"]},
              fn level, {deltas, id_to_price} ->
                case action do
                  "insert" ->
                    id = level["id"]
                    price = level["price"] / 1
                    size = level["size"] / 1

                    delta =
                      case level["side"] do
                        "Buy" -> {:bid, price, size}
                        "Sell" -> {:ask, price, size}
                      end

                    {deltas ++ [delta], Map.put(id_to_price, id, price)}

                  "update" ->
                    id = level["id"]
                    price = sync_state["id_to_price"][id]
                    size = level["size"] / 1

                    delta =
                      case level["side"] do
                        "Buy" -> {:bid, price, size}
                        "Sell" -> {:ask, price, size}
                      end

                    {deltas ++ [delta], id_to_price}

                  "delete" ->
                    id = level["id"]
                    price = sync_state["id_to_price"][id]

                    delta =
                      case level["side"] do
                        "Buy" -> {:bid, price, 0}
                        "Sell" -> {:ask, price, 0}
                      end

                    {deltas ++ [delta], Map.delete(id_to_price, id)}
                end
              end
            )

          {[{:deltas, deltas}], %{sync_state | "id_to_price" => new_id_to_price}}

        %{
          "table" => "trade",
          "action" => "insert",
          "data" => data
        } ->
          buys =
            data
            |> Enum.filter(fn %{"side" => side} -> side == "Buy" end)
            |> Enum.map(fn %{
                             "price" => price_int,
                             "size" => size_int,
                             "side" => side,
                             "timestamp" => timestamp_str
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
            data
            |> Enum.filter(fn %{"side" => side} -> side == "Sell" end)
            |> Enum.map(fn %{
                             "price" => price_int,
                             "size" => size_int,
                             "side" => side,
                             "timestamp" => timestamp_str
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

          {[{:buys, buys}, {:sells, sells}], sync_state}
      end

    {instructions, new_sync_state}
  end

  @impl TranslationScheme
  def check_sync_state(sync_state) do
    {:synced, sync_state}
  end
end

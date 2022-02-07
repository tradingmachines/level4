defmodule Exchanges.Bitfinex.Trading do
  @moduledoc """
  Contains translation scheme for the Bitfinex websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state(base_symbol, quote_symbol) do
    %{"book_cid" => nil, "trades_cid" => nil}
  end

  @impl TranslationScheme
  def make_ping_messages(sync_state) do
    book =
      if sync_state["book_cid"] != nil do
        {:ok, json_str_book} =
          Jason.encode(%{
            "event" => "ping",
            "cid" => sync_state["book_cid"]
          })

        [json_str_book]
      else
        []
      end

    trade =
      if sync_state["trades_cid"] != nil do
        {:ok, json_str_trade} =
          Jason.encode(%{
            "event" => "ping",
            "cid" => sync_state["trades_cid"]
          })

        [json_str_trade]
      else
        []
      end

    book ++ trade
  end

  @impl TranslationScheme
  def make_subscribe_messages(base_symbol, quote_symbol) do
    {:ok, json_str_book} =
      Jason.encode(%{
        "event" => "subscribe",
        "channel" => "book",
        "symbol" => "t#{base_symbol}#{quote_symbol}"
      })

    {:ok, json_str_trade} =
      Jason.encode(%{
        "event" => "subscribe",
        "channel" => "trades",
        "symbol" => "t#{base_symbol}#{quote_symbol}"
      })

    [json_str_book, json_str_trade]
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    {instructions, new_sync_state} =
      case json do
        [_, "hb"] ->
          {[:noop], sync_state}

        %{"event" => "info"} ->
          {[:noop], sync_state}

        %{"event" => "conf"} ->
          {[:noop], sync_state}

        %{"event" => "pong"} ->
          {[:noop], sync_state}

        %{"event" => "subscribed", "channel" => "book", "chanId" => chan_id} ->
          {[:noop], %{sync_state | "book_cid" => chan_id}}

        %{"event" => "subscribed", "channel" => "trades", "chanId" => chan_id} ->
          {[:noop], %{sync_state | "trades_cid" => chan_id}}

        [chan_id, data] ->
          cond do
            chan_id == sync_state["book_cid"] ->
              case data do
                [price_int, count, amount_int] ->
                  price = price_int / 1
                  amount = amount_int / 1

                  delta =
                    cond do
                      amount > 0 ->
                        if count == 0 do
                          {:bid, price, 0}
                        else
                          {:bid, price, amount}
                        end

                      amount <= 0 ->
                        if count == 0 do
                          {:ask, price, 0}
                        else
                          {:ask, price, -amount}
                        end
                    end

                  {[{:deltas, [delta]}], sync_state}

                levels ->
                  bids =
                    levels
                    |> Enum.filter(fn [_, _, amount] -> amount > 0 end)
                    |> Enum.map(fn [price_int, _, amount_int] ->
                      price = price_int / 1
                      amount = amount_int / 1
                      {price, amount}
                    end)

                  asks =
                    levels
                    |> Enum.filter(fn [_, _, amount] -> amount <= 0 end)
                    |> Enum.map(fn [price_int, _, amount_int] ->
                      price = price_int / 1
                      amount = amount_int / 1
                      {price, -amount}
                    end)

                  {[{:snapshot, bids, asks}], sync_state}
              end

            chan_id == sync_state["trades_cid"] ->
              {[:noop], sync_state}
          end

        [chan_id, _, data] ->
          cond do
            chan_id == sync_state["trades_cid"] ->
              [_, epoch_ms, amount_int, price_int] = data

              price = price_int / 1
              amount = amount_int / 1

              epoch_micro = epoch_ms * 1000
              {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

              if amount > 0 do
                {[{:buys, [{price, amount, timestamp}]}], sync_state}
              else
                {[{:sells, [{price, -amount, timestamp}]}], sync_state}
              end
          end
      end

    {instructions, new_sync_state}
  end

  @impl TranslationScheme
  def check_sync_state(sync_state) do
    {:synced, sync_state}
  end
end

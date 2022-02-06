defmodule Exchanges.Bitstamp do
  @moduledoc """
  Contains translation scheme for the Bitstamp websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state(base_symbol, quote_symbol) do
    %{"did_snapshot" => false}
  end

  @impl TranslationScheme
  def make_ping_message() do
    {:ok, json_str} = Jason.encode(%{"event" => "bts:heartbeat"})
    json_str
  end

  @impl TranslationScheme
  def make_subscribe_messages(base_symbol, quote_symbol) do
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

    [json_str_book, json_str_trade]
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    {instructions, new_sync_state} =
      case json do
        %{"event" => "bts:subscription_succeeded"} ->
          {[:noop], sync_state}

        %{"event" => "bts:heartbeat"} ->
          {[:noop], sync_state}

        %{"event" => "bts:request_reconnect"} ->
          {[:reconnect], sync_state}

        %{
          "event" => "data",
          "data" => %{
            "bids" => bid_strs,
            "asks" => ask_strs
          }
        } ->
          if sync_state["did_snapshot"] do
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

            {[{:deltas, bids ++ asks}], sync_state}
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

            {[{:snapshot, bids, asks}], %{sync_state | "did_snapshot" => true}}
          end

        %{
          "event" => "trade",
          "data" => %{
            "price" => price,
            "amount" => size,
            "timestamp" => epoch_sec_str,
            "type" => side
          }
        } ->
          {epoch_sec, _} = Integer.parse(epoch_sec_str)
          epoch_ms = epoch_sec * 1000
          epoch_micro = epoch_ms * 1000
          {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

          case side do
            0 -> {[{:buys, [{price, size, timestamp}]}], sync_state}
            1 -> {[{:sells, [{price, size, timestamp}]}], sync_state}
          end
      end

    {instructions, new_sync_state}
  end

  @impl TranslationScheme
  def check_sync_state(sync_state) do
    {:synced, sync_state}
  end
end

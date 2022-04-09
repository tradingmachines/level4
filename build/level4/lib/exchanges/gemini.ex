defmodule Exchanges.Gemini do
  @moduledoc """
  Contains translation scheme for the Gemini websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state(base_symbol, quote_symbol) do
    %{"something" => nil}
  end

  @impl TranslationScheme
  def make_ping_messages(sync_state) do
    {:ok, json_str} = Jason.encode(%{"op" => "ping"})
    [json_str]
  end

  @impl TranslationScheme
  def make_subscribe_messages(base_symbol, quote_symbol) do
    {:ok, json_str} =
      Jason.encode(%{
        "type" => "subscribe",
        "subscriptions" => [
          %{
            "name" => "l2",
            "symbols" => ["#{base_symbol}#{quote_symbol}"]
          }
        ]
      })

    [json_str]
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    instructions =
      case json do
        %{"type" => "heartbeat", "timestamp" => _} ->
          [:noop]

        %{"type" => "heartbeat", "sequence" => _} ->
          [:noop]

        %{"type" => "auction_result"} ->
          [:noop]

        %{"type" => "auction_indicative"} ->
          [:noop]

        %{
          "type" => "l2_updates",
          "changes" => changes,
          "trades" => _,
          "auction_events" => _
        } ->
          all_levels =
            for [side, price_str, size_str] <- changes do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)

              case side do
                "buy" -> {:bid, price, size}
                "sell" -> {:ask, price, size}
              end
            end

          bids =
            all_levels
            |> Enum.filter(fn {side, _, _} -> side == :bid end)
            |> Enum.map(fn {_, price, size} -> {price, size} end)

          asks =
            all_levels
            |> Enum.filter(fn {side, _, _} -> side == :ask end)
            |> Enum.map(fn {_, price, size} -> {price, size} end)

          [{:snapshot, bids, asks}]

        %{
          "type" => "l2_updates",
          "changes" => changes
        } ->
          deltas =
            for [side, price_str, size_str] <- changes do
              {price, _} = Float.parse(price_str)
              {size, _} = Float.parse(size_str)

              case side do
                "buy" -> {:bid, price, size}
                "sell" -> {:ask, price, size}
              end
            end

          [{:deltas, deltas}]

        %{
          "type" => "trade",
          "timestamp" => epoch_ms,
          "price" => price_str,
          "quantity" => size_str,
          "side" => side
        } ->
          {price, _} = Float.parse(price_str)
          {size, _} = Float.parse(size_str)

          epoch_micro = epoch_ms * 1000
          {:ok, timestamp} = DateTime.from_unix(epoch_micro, :microsecond)

          case side do
            "buy" -> [{:buys, [{price, size, timestamp}]}]
            "sell" -> [{:sells, [{price, size, timestamp}]}]
          end
      end

    {instructions, sync_state}
  end

  @impl TranslationScheme
  def check_sync_state(sync_state) do
    {:synced, sync_state}
  end
end

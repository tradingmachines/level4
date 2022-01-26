defmodule Exchanges.BybitSpot do
  @moduledoc """
  Contains translation scheme for the Bybit spot websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state(base_symbol, quote_symbol) do
    %{"something" => nil}
  end

  @impl TranslationScheme
  def make_ping_message() do
    timestamp = DateTime.utc_now()
    epoch_ms = DateTime.to_unix(timestamp, :millisecond)

    {:ok, json_str} = Jason.encode(%{"ping" => epoch_ms})

    json_str
  end

  @impl TranslationScheme
  def make_subscribe_messages(base_symbol, quote_symbol) do
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

    [json_str_book, json_str_trade]
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    instructions = []

    IO.puts(inspect(json))

    {instructions, sync_state}
  end

  @impl TranslationScheme
  def check_sync_state(sync_state) do
    {:synced, sync_state}
  end
end

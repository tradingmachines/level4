defmodule Exchanges.Bybit do
  @moduledoc """
  Contains translation scheme for the Bybit websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state(base_symbol, quote_symbol) do
    %{"something" => nil}
  end

  @impl TranslationScheme
  def make_ping_message() do
    {:ok, json_str} = Jason.encode(%{"op" => "ping"})
    json_str
  end

  @impl TranslationScheme
  def make_subscribe_messages(base_symbol, quote_symbol) do
    []
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    instructions = []

    {instructions, sync_state}
  end

  @impl TranslationScheme
  def check_sync_state(sync_state) do
    {:synced, sync_state}
  end
end

defmodule Exchanges.Bybit do
  @moduledoc """
  Contains translation scheme for the Bybit websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state() do
    nil
  end

  @impl TranslationScheme
  def make_subscribe_message(major_symbol, quote_symbol) do
    nil
  end

  @impl TranslationScheme
  def translate(json, sync_state) do
    nil
  end

  @impl TranslationScheme
  def check_sync_state(sync_state) do
    {:synced, sync_state}
  end
end

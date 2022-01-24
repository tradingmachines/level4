defmodule Exchanges.Gemini do
  @moduledoc """
  Contains translation scheme for the Gemini websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state(base_symbol, quote_symbol) do
    nil
  end

  @impl TranslationScheme
  def make_subscribe_messages(base_symbol, quote_symbol) do
    []
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

defmodule Exchanges.CexIO do
  @moduledoc """
  Contains translation scheme for the CexIO websocket API.
  """

  @behaviour TranslationScheme

  @impl TranslationScheme
  def init_sync_state() do
    nil
  end

  @impl TranslationScheme
  def make_subscribe_messages(major_symbol, quote_symbol) do
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

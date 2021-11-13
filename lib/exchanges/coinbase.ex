defmodule Exchanges.Coinbase do
  @moduledoc """
  Contains translation scheme for the Coinbase Pro websocket API.
  """

  @behaviour Level4.TranslationScheme

  @impl Level4.TranslationScheme
  @spec message_type(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def message_type(json) do
    nil
  end

  @impl Level4.TranslationScheme
  @spec snapshot(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def snapshot(json) do
    nil
  end

  @impl Level4.TranslationScheme
  @spec delta(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def delta(json) do
    nil
  end

  @impl Level4.TranslationScheme
  @spec make_subscribe_message(String.t(), String.t()) ::
          {:ok, String.t()}
          | {:error, String.t()}
  def make_subscribe_message(major_symbol, quote_symbol) do
    Jason.encode(%{
      "type" => "subscribe",
      "product_ids" => ["#{major_symbol}-#{quote_symbol}"],
      "channels" => ["heartbeat", "level2", "matches"]
    })
  end
end

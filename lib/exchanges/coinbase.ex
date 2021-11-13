defmodule Exchanges.Coinbase do
  @moduledoc """
  Contains translation scheme for the Coinbase Pro websocket API.
  """

  @behaviour Level4.TranslationScheme

  @impl Level4.TranslationScheme
  @spec decode_message_type(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def decode_message_type(json) do
    nil
  end

  @impl Level4.TranslationScheme
  @spec decode_snapshot(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def decode_snapshot(json) do
    nil
  end

  @impl Level4.TranslationScheme
  @spec decode_delta(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def decode_delta(json) do
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

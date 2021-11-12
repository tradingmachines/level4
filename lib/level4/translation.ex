defmodule Level4.TranslationScheme do
  @protocoldoc """
  Defines the functions a translation scheme should expose in order to
  be a valid scheme.
  """

  @doc """
  Returns the type of JSON message - either a snapshot or a delta.
  """
  @callback decode_message_type(String.t()) ::
              {:ok, String.t()}
              | {:error, String.t()}

  @doc """
  Decodes and returns the JSON snapshot payload.
  """
  @callback decode_snapshot(String.t()) ::
              {:ok, String.t()}
              | {:error, String.t()}

  @doc """
  Decodes and returns the JSON delta payload.
  """
  @callback decode_delta(String.t()) ::
              {:ok, String.t()}
              | {:error, String.t()}
end

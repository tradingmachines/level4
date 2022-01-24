defmodule TranslationScheme do
  @protocoldoc """
  Defines the functions a translation scheme should expose in order to
  be a valid scheme.
  """

  @doc """
  Initialises the "synchronisation state" value that is used to check
  the message stream is in-sync i.e. no messages have been dropped.
  """
  @callback init_sync_state(String.t(), String.t()) :: any()

  @doc """
  Makes and returns the subscribe message sent to the websocket API
  after successfully connecting.
  """
  @callback make_subscribe_messages(String.t(), String.t()) ::
              {:ok, [String.t()]}
              | {:error, String.t()}

  @doc """
  ...
  """
  @callback translate(String.t(), any()) :: {any(), any()}

  @doc """
  ...
  """
  @callback check_sync_state(any()) ::
              {:synced, any()}
              | {:not_synced, any()}
end

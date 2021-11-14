defmodule TranslationScheme do
  @protocoldoc """
  Defines the functions a translation scheme should expose in order to
  be a valid scheme.
  """

  @doc """
  Initialises the "synchronisation state" value that is used to check
  the message stream is in-sync i.e. no messages have been dropped.
  """
  @callback init_sync_state() :: any()

  @doc """
  Makes and returns the subscribe message sent to the websocket API
  after successfully connecting.
  """
  @callback make_subscribe_message(String.t(), String.t()) ::
              {:ok, String.t()}
              | {:error, String.t()}

  @doc """
  ...
  """
  @callback translate(String.t(), any()) ::
              {:snapshot, [{float(), float()}], [{float(), float()}], any()}
              | {:deltas, [{atom(), {float(), float()}}], any()}
              | {:noop, any()}
              | :out_of_sync
              | :unknown
end

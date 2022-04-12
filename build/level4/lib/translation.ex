defmodule TranslationScheme do
  @protocoldoc """
  Defines the functions a translation scheme should expose in order to
  be a valid scheme.

  A translation scheme has the following six behaviours:
  1. initial sync state: returns a value the client should use as initial
     state. The client is free to update this value over time using
     next_state function.
  2. next sync state: given the current sync state and latest message
     received from the socket, return the next value to use as the sync
     state.
  3. make ping messages: make and return the messages to send as a ping
     event.
  4. make subscription message: make and return subscription message to
     send after successfully connecting.
  5. translate message: convert and translate JSON string into internal
     representation.
  6. check sync state: given current sync state, return true if client
     is in-sync with the server, else return false.
  """

  @doc """
  Return the initial synchronisation state value. This is used to check
  if the message stream is in-sync:
  - is in sync = no messages have been dropped;
  - is not in sync = one or more messages have been dropped, the client
    should reconnect.
  """
  # need to find out why i used String.t(), String.t() here
  @callback initial_state(String.t(), String.t()) :: any()

  @doc """
  Return the next value to use as sync state, given the current sync
  state and latest message received.
  """
  @callback next_state(any(), any()) :: any()

  @doc """
  Make and return the list of ping messages. If a market's ping? field
  is true then one or more "ping messages" are sent at a specific
  internal. Some exchanges require clients to send such messages in
  order to keep the connection open.
  """
  @callback ping_msg(any()) :: {:ok, [String.t()]} | :error

  @doc """
  Make and return the subscribe message sent to the websocket API
  after successfully connecting. The subscription message tells the
  server which market feed to subscribe to.
  """
  # need to find out why i used String.t(), String.t() here
  @callback subscribe_msg(String.t(), String.t()) :: {:ok, [String.t()]} | :error

  @doc """
  Check the current state and decide whether the client is / is not
  synchronised with the server. Returning false means the client
  should reconnect.
  """
  @callback synchronised?(any()) :: true | false

  @doc """
  Translate a given message, which will be a JSON string, into an
  internal representation for the client. This is where the bulk of
  the translation scheme code will be.
  """
  @callback translate(String.t(), any()) :: {:ok, any()} | :error
end

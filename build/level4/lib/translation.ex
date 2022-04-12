defmodule TranslationScheme do
  @protocoldoc """
  Defines the functions a translation scheme should expose in order to
  be a valid scheme.

  A translation scheme has the following five behaviours:
  1. initial sync state: returns a value the client should use as initial
     state. The client is free to update this value over time using
     next_state function.
  2. make ping messages: make and return the messages to send as a ping
     event.
  3. make subscription message: make and return subscription message to
     send after successfully connecting.
  4. translate message: convert and translate JSON string into internal
     representation. Returns the translation and the next state.
  5. check sync state: given current sync state, return true if client
     is in-sync with the server, else return false.
  """

  @doc """
  Return the initial synchronisation state value. This is used to check
  if the message stream is in-sync:
  - is in sync = no messages have been dropped;
  - is not in sync = one or more messages have been dropped, the client
    should reconnect.

  The two parameters are the string representations of the base and quote
  symbols.

  initial_state(base, quote) :: initial state
  """
  @callback initial_state(String.t(), String.t()) :: any()

  @doc """
  Make and return the list of ping messages. If a market's ping? field
  is true then one or more "ping messages" are sent at a specific
  internal. Some exchanges require clients to send such messages in
  order to keep the connection open.

  ping_msg(current state) :: {:ok, [list of messages]}
                          OR :error
  """
  @callback ping_msg(any()) :: {:ok, [String.t()]} | :error

  @doc """
  Make and return the subscribe message sent to the websocket API
  after successfully connecting. The subscription message tells the
  server which market feed to subscribe to.

  The two parameters are the string representations of the base and quote
  symbols.

  subscribe_msg(base, quote) :: {:ok, [list of messages]}
                             OR :error
  """
  @callback subscribe_msg(String.t(), String.t()) :: {:ok, [String.t()]} | :error

  @doc """
  Check the current state and decide whether the client is / is not
  synchronised with the server. Returning false means the client
  should reconnect.

  synchronised(current state) :: true OR false
  """
  @callback synchronised?(any()) :: true | false

  @doc """
  Translate a given message, which will be a JSON string, into an
  internal representation for the client. This is where the bulk of
  the translation scheme code will be.

  translate(json str, current state) :: {:ok, translation, next state}
                                     OR :error
  """
  @callback translate(String.t(), any()) :: {:ok, any(), any} | :error
end

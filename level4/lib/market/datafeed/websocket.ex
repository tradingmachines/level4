defmodule Market.DataFeed.Level2.WebSocket do
  @moduledoc """
  Websocket module contains all logic for reading from a level2
  data feed websocket. An exchange translation scheme is used to
  setup the initial connection state and to translate messages
  into instructions. Messages are written to the data sump via
  TCP socket connection. If the sump connection dies then the
  websocket genserver will crash, which will trigger a reconnect.

  Open a new connection with the following config:
  - connecton timeout after 3 seconds;
  - domain lookup timeout after 3 seconds;
  - disconnect timeout after 1 second;
  - never try to reconnect after disconnect;
  - always use HTTP/1.1;
  - ask gun to not supervise this process.
  """

  use GenServer

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @impl true
  def init(init_arg) do
    # trap exits
    Process.flag(:trap_exit, true)

    # market internal representation
    market = init_arg[:market]
    config = init_arg[:config]

    # websocket host:port
    host = to_charlist(config.host)
    port = config.port

    # ask translation scheme for initial state
    initial_state =
      config.translation_scheme.initial_state(
        market.base_symbol,
        market.quote_symbol
      )

    # gun socket options
    options = %{
      :connect_timeout => 3000,
      :domain_lookup_timeout => 3000,
      :retry => 0,
      :protocols => [:http],
      :supervise => false,
      :http_opts => %{
        closing_timeout: 1000
      }
    }

    # attempt connection
    case :gun.open(host, port, options) do
      {:ok, conn_pid} ->
        # started successfully
        state = %{
          :conn_pid => conn_pid,
          :market => market,
          :config => config,
          :state => initial_state,
          :stream_ref => nil
        }

        {:ok, state}

      {:error, reason} ->
        # failed to start
        {:error, reason}
    end
  end

  @doc """
  shutdown the connection gracefully, timeout after:
  :http_opts => %{ closing_timeout: ... } and force close
  """
  @impl true
  def terminate(_, state) do
    # ...
    :ok = :gun.shutdown(state[:conn_pid])
  end

  # helper function. schedules do_ping commands five
  # seconds into the future
  def schedule_ping() do
    Process.send_after(self(), :do_ping, 5000)
  end

  # decode a text message using the current connection state
  def decode(text, state) do
    # market info, translation scheme, connection state
    %{:config => config, :state => current_state} = state

    cond do
      text == "pong" ->
        # ignore "pong" strings
        :nothing

      # add other filters here if/when necessary
      # ...

      true ->
        # assume the text is JSON
        case Jason.decode(text) do
          # successfully decoded the JSON
          {:ok, json} ->
            # translate into instructions
            # this is where it all comes together!
            {:ok, instructions, next_state} =
              config.translation_scheme.translate(
                json,
                current_state
              )

            # update connection state, execute instructions
            new_state = %{state | :state => next_state}
            {:execute, instructions, new_state}

          # JSON decode error
          {:error, error_msg} ->
            {:error, error_msg}
        end
    end
  end

  # snapshot instruction: apply bids and asks to orderbook
  def execute({:snapshot, bids, asks}, state) do
    # ...
    level2 =
      {:via, Registry,
       {
         Market.Level2.Registry,
         state[:market].id
       }}

    # ...
    :ok =
      Market.DataFeed.Level2.Mediator.snapshot(
        level2,
        bids,
        asks
      )

    :ok
  end

  # deltas instruction: apply one or more deltas to the book
  def execute({:deltas, deltas}, state) do
    # ...
    level2 =
      {:via, Registry,
       {
         Market.Level2.Registry,
         state[:market].id
       }}

    for {side, price, liquidity} <- deltas do
      case side do
        :bid ->
          # ...
          :ok =
            Market.DataFeed.Level2.Mediator.bids_delta(
              level2,
              price,
              liquidity
            )

        :ask ->
          # ...
          :ok =
            Market.DataFeed.Level2.Mediator.asks_delta(
              level2,
              price,
              liquidity
            )
      end
    end

    :ok
  end

  # buys instruction: there was one or more market buys
  def execute({:buys, buys}, state) do
    # ...
    level2 =
      {:via, Registry,
       {
         Market.Level2.Registry,
         state[:market].id
       }}

    for {price, size} <- buys do
      # ...
      :ok =
        Market.DataFeed.Level2.Mediator.buy(
          level2,
          price,
          size
        )
    end

    :ok
  end

  # sells instruction: there was one or more market sells
  def execute({:sells, sells}, state) do
    # ...
    level2 =
      {:via, Registry,
       {
         Market.Level2.Registry,
         state[:market].id
       }}

    for {price, size} <- sells do
      # ...
      :ok =
        Market.DataFeed.Level2.Mediator.sell(
          level2,
          price,
          size
        )
    end

    :ok
  end

  # fetch instruction: asynchronously fetch some data and send
  # the fetch_result to self. expects a do_work lambda function
  def execute({:fetch, do_work}, _) do
    # ...
    respond_to = self()

    # ...
    Task.start(fn -> send(respond_to, {:fetch_result, do_work.()}) end)

    :ok
  end

  # bad sync instruction: ...
  def execute(:bad_sync, _) do
    {:error, "level2 data feed has indicated a bad sync"}
  end

  # unknown message instruction: ...
  def execute(:unknown, _) do
    {:error, "received unknown instruction"}
  end

  # reconnect instruction: ...
  def execute(:reconnect, _) do
    {:error, "reconnect requested"}
  end

  # no op instruction: ...
  def execute(:noop, _) do
    :ok
  end

  # execute empty list of instructions (this is a base case)
  def execute([], _) do
    :ok
  end

  # execute a list of instructions, one by one, stop and return
  # error if an instruction does not return :ok
  def execute([instruction | remaining], state) do
    case execute(instruction, state) do
      :ok ->
        # keep going
        execute(remaining, state)

      {:error, error_msg} ->
        # stop, return error
        {:error, error_msg}
    end
  end

  @doc """
  ...
  """
  @impl true
  # handle do_ping command
  def handle_info(:do_ping, state) do
    %{
      :config => config,
      :state => current_state,
      :conn_pid => conn_pid,
      :stream_ref => stream_ref
    } = state

    # ask translation scheme for the messages
    {:ok, json_strs} = config.translation_scheme.ping_msg(current_state)

    # send the messages
    for json_str <- json_strs do
      :ok = :gun.ws_send(conn_pid, stream_ref, {:text, json_str})
    end

    # reschedule the ping
    schedule_ping()

    {:noreply, state}
  end

  # the HTTP connection upgrade was successful
  def handle_info({:gun_upgrade, _, _, _, _}, state) do
    %{
      :config => config,
      :market => market,
      :conn_pid => conn_pid,
      :stream_ref => stream_ref
    } = state

    # make the subscribe messages
    {:ok, json_strs} =
      config.translation_scheme.subscribe_msg(
        market.base_symbol,
        market.quote_symbol
      )

    # send the subscribe messages
    for json_str <- json_strs do
      :gun.ws_send(conn_pid, stream_ref, {:text, json_str})
    end

    {:noreply, state}
  end

  # received data from the underlying connection
  def handle_info({:gun_data, _, _, _, _}, state) do
    # do nothing
    {:noreply, state}
  end

  # the server closed the websocket
  def handle_info({:gun_ws, _, _, {:close, _}}, state) do
    # stop the GenServer and reconnect later
    {:stop, "server closed the websocket", state}
  end

  # the connection is up
  def handle_info({:gun_up, _, _}, state) do
    %{
      :config => config,
      :conn_pid => conn_pid
    } = state

    # request a connection upgrade to websocket
    stream_ref = :gun.ws_upgrade(conn_pid, config.path)

    # schedule pings?
    if config.ping?, do: schedule_ping()

    {:noreply, %{state | :stream_ref => stream_ref}}
  end

  # the connection has gone down
  def handle_info({:gun_down, _, _, reason, _}, state) do
    # the connection is dead so stop the websocket GenServer
    # it will be restarted with a fresh connection
    {:stop, "connection closed: #{reason}", state}
  end

  # the HTTP upgrade request failed
  def handle_info({:gun_response, _, _, _, status, _}, state) do
    # the upgrade failed so stop the websocket GenServer
    # it will be restarted and hopefully the upgrade won't fail again
    {:stop, "connection upgrade fail, HTTP: #{status}", state}
  end

  # there was a connection error
  def handle_info({:gun_error, _, _, reason}, state) do
    # there was an error so stop the websocket GenServer
    # it will be restarted with a fresh connection
    {:stop, "connection error: #{reason}", state}
  end

  # websocket and fetch_result messages are handled the same way:
  # decode, execute, or do nothing
  def handle_info(msg, state) do
    # extract text
    text =
      case msg do
        {:gun_ws, _, _, {:text, text}} ->
          # received text data from the websocket
          text

        {:fetch_result, text} ->
          # fetch_result event - result of async fetch instruction
          text
      end

    case decode(text, state) do
      :nothing ->
        # no action needed
        {:noreply, state}

      {:new_state, new_state} ->
        # just update the connection state
        {:noreply, new_state}

      {:error, error_msg} ->
        # there was an error
        {:stop, error_msg, state}

      {:execute, instructions, new_state} ->
        # need to execute some instructions
        case execute(instructions, new_state) do
          :ok ->
            # executed all successfully
            {:noreply, new_state}

          {:error, error_msg} ->
            # there was an error
            {:stop, error_msg, new_state}
        end
    end
  end
end

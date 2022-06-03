defmodule Market.Level2.WebSocket do
  @moduledoc """
  Websocket module contains all logic for reading from a level2
  data feed websocket. An exchange translation scheme is used to
  setup the initial connection state and to translate messages
  into instructions. Messages are written to the data sump via
  TCP socket connection. If the sump connection dies then the
  websocket genserver will crash, which will trigger a reconnect.
  """

  use GenServer

  # helper function. schedules do_ping commands five
  # seconds into the future
  defp schedule_ping() do
    Process.send_after(self(), :do_ping, 5000)
  end

  # decode a text message using the current connection context
  defp decode(text, context) do
    # market info, translation scheme, connection state
    %{:market => market, :state => current_state} = context
    schm = market.translation_scheme

    # decide how to handle the text
    cond do
      # ignore "pong" strings
      text == "pong" ->
        :nothing

      # add other filters here if/when necessary
      # ...

      # assume the text is JSON
      true ->
        case Jason.decode(text) do
          # successfully decoded the JSON
          {:ok, json} ->
            # translate into instructions
            # this is where it all comes together!
            {:ok, instructions, next_state} =
              schm.translate(
                json,
                current_state
              )

            # update connection context, execute instructions
            new_context = %{context | :state => next_state}
            {:execute, instructions, new_context}

          # JSON decode error
          {:error, error_msg} ->
            {:error, error_msg}
        end
    end
  end

  # snapshot instruction: apply bids and asks to orderbook
  defp execute({:snapshot, bids, asks}, context) do
    Market.Level2.Mediator.snapshot(
      {:via, Registry,
       {
         Market.Level2.Mediator.Registry,
         Market.tag(context[:market])
       }},
      bids,
      asks
    )

    :ok
  end

  # deltas instruction: apply one or more deltas to the book
  defp execute({:deltas, deltas}, context) do
    Market.Level2.Mediator.deltas(
      {:via, Registry,
       {
         Market.Level2.Mediator.Registry,
         Market.tag(context[:market])
       }},
      deltas
    )

    :ok
  end

  # buys instruction: there was one or more market buys
  defp execute({:buys, buys}, context) do
    Market.Level2.Mediator.buys(
      {:via, Registry,
       {
         Market.Level2.Mediator.Registry,
         Market.tag(context[:market])
       }},
      buys
    )

    :ok
  end

  # sells instruction: there was one or more market sells
  defp execute({:sells, sells}, context) do
    Market.Level2.Mediator.sells(
      {:via, Registry,
       {
         Market.Level2.Mediator.Registry,
         Market.tag(context[:market])
       }},
      sells
    )

    :ok
  end

  # fetch instruction: asynchronously fetch some data and send
  # the fetch_result to self. expects a do_work lambda function
  defp execute({:fetch, do_work}, _) do
    respond_to = self()
    Task.start(fn -> send(respond_to, {:fetch_result, do_work.()}) end)
    :ok
  end

  # bad sync instruction: ...
  defp execute(:bad_sync, _) do
    {:error, "level2 data feed has indicated a bad sync"}
  end

  # unknown message instruction: ...
  defp execute(:unknown, _) do
    {:error, "received unknown instruction"}
  end

  # reconnect instruction: ...
  defp execute(:reconnect, _) do
    {:error, "reconnect requested"}
  end

  # no op instruction: ...
  defp execute(:noop, _) do
    :ok
  end

  # execute empty list of instructions (this is a base case)
  defp execute([], _) do
    :ok
  end

  # execute a list of instructions, one by one, stop and return
  # error if an instruction does not return :ok
  defp execute([instruction | remaining], context) do
    case execute(instruction, context) do
      # keep going
      :ok -> execute(remaining, context)
      # stop, return error
      {:error, error_msg} -> {:error, error_msg}
    end
  end

  @doc """
  ...
  """
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @doc """
  Open a new connection with the following config:
  - connecton timeout after 3 seconds;
  - domain lookup timeout after 3 seconds;
  - disconnect timeout after 1 second;
  - never try to reconnect after disconnect;
  - always use HTTP/1.1;
  - ask gun to not supervise this process.
  """
  @impl true
  def init(init_arg) do
    # market internal representation
    market = init_arg[:market]

    # websocket host:port
    ws_host = to_charlist(market.ws_host)
    port = market.ws_port

    # ask translation scheme for initial state
    initial_state =
      market.translation_scheme.initial_state(
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
    case :gun.open(ws_host, port, options) do
      # started successfully
      {:ok, conn_pid} ->
        context = %{
          :conn_pid => conn_pid,
          :market => market,
          :state => initial_state,
          :stream_ref => nil
        }

        {:ok, context}

      # failed to start
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  shutdown the connection gracefully, timeout after:
  :http_opts => %{ closing_timeout: ... } and force close
  """
  @impl true
  def terminate(_, context) do
    :ok = :gun.shutdown(context[:conn_pid])
  end

  @doc """
  ...
  """
  @impl true
  # handle do_ping command
  def handle_info(:do_ping, context) do
    %{
      :market => market,
      :state => current_state,
      :conn_pid => conn_pid,
      :stream_ref => stream_ref
    } = context

    # ask translation scheme for the messages
    schm = market.translation_scheme
    {:ok, json_strs} = schm.ping_msg(current_state)

    # send the messages
    for json_str <- json_strs do
      :ok = :gun.ws_send(conn_pid, stream_ref, {:text, json_str})
    end

    # reschedule the ping
    schedule_ping()

    {:noreply, context}
  end

  # the connection is up
  def handle_info({:gun_up, _, _}, context) do
    %{
      :market => market,
      :conn_pid => conn_pid
    } = context

    # request a connection upgrade to websocket
    stream_ref = :gun.ws_upgrade(conn_pid, market.ws_path)

    # schedule pings?
    if market.ping?, do: schedule_ping()

    {:noreply, %{context | :stream_ref => stream_ref}}
  end

  # the HTTP connection upgrade was successful
  def handle_info({:gun_upgrade, _, _, _, _}, context) do
    %{
      :market => market,
      :conn_pid => conn_pid,
      :stream_ref => stream_ref
    } = context

    # make the JSON subscription messages
    schm = market.translation_scheme

    {:ok, json_strs} =
      schm.subscribe_msg(
        market.base_symbol,
        market.quote_symbol
      )

    # send the subscribe messages
    for json_str <- json_strs do
      :gun.ws_send(conn_pid, stream_ref, {:text, json_str})
    end

    {:noreply, context}
  end

  # received data from the underlying connection
  def handle_info({:gun_data, _, _, _, _}, context) do
    # do nothing
    {:noreply, context}
  end

  # the server closed the websocket
  def handle_info({:gun_ws, _, _, {:close, _}}, context) do
    # stop the GenServer and reconnect later
    {:stop, "server closed the websocket", context}
  end

  # the connection has gone down
  def handle_info({:gun_down, _, _, reason, _}, context) do
    # the connection is dead so stop the websocket GenServer
    # it will be restarted with a fresh connection
    {:stop, "connection closed: #{reason}", context}
  end

  # the HTTP upgrade request failed
  def handle_info({:gun_response, _, _, _, status, _}, context) do
    # the upgrade failed so stop the websocket GenServer
    # it will be restarted and hopefully the upgrade won't fail again
    {:stop, "connection upgrade fail, HTTP: #{status}", context}
  end

  # there was a connection error
  def handle_info({:gun_error, _, _, reason}, context) do
    # there was an error so stop the websocket GenServer
    # it will be restarted with a fresh connection
    {:stop, "connection error: #{reason}", context}
  end

  # websocket and fetch_result messages are handled the same way:
  # decode, execute, or do nothing
  def handle_info(msg, context) do
    # extract text
    text =
      case msg do
        # received text data from the websocket
        {:gun_ws, _, _, {:text, text}} -> text
        # fetch_result event - result of async fetch instruction
        {:fetch_result, text} -> text
      end

    # decode text
    case decode(text, context) do
      # no action needed
      :nothing ->
        {:noreply, context}

      # just update the connection context
      {:new_context, new_context} ->
        {:noreply, new_context}

      # need to execute some instructions
      {:execute, instructions, new_context} ->
        case execute(instructions, new_context) do
          # executed all successfully
          :ok -> {:noreply, new_context}
          # there was an error
          {:error, error_msg} -> {:stop, error_msg, new_context}
        end

      # there was an error
      {:error, error_msg} ->
        {:stop, error_msg, context}
    end
  end
end

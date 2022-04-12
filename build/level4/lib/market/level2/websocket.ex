defmodule Market.Level2.WebSocket do
  @moduledoc """
  ...
  """

  use GenServer

  @doc """
  ...
  """
  defp schedule_ping() do
    Process.send_after(self(), :do_ping, 5000)
  end

  @doc """
  ...
  """
  defp decode(text, state) do
    %{
      :market => market,
      :sync_state => sync_state
    } = state

    cond do
      text == "pong" ->
        :nothing

      true ->
        # decode the message and always assume it is JSON.
        case Jason.decode(text) do
          {:ok, json} ->
            {:ok, translated} = market.translation_scheme.translate(json, sync_state)
            {instructions, new_sync_state} = translated

            case execute(instructions, market) do
              :ok ->
                {:new_state, %{state | :sync_state => new_sync_state}}

              {:error, error_msg} ->
                {:error, error_msg}
            end

          {:error, error_msg} ->
            {:error, error_msg}
        end
    end
  end

  @doc """
  ...
  """
  # ...
  defp execute({:snapshot, bids, asks}, market) do
    Market.Level2.Mediator.snapshot(
      {:via, Registry,
       {
         Market.Level2.Mediator.Registry,
         Market.id(market)
       }},
      bids,
      asks
    )

    :ok
  end

  # ...
  defp execute({:deltas, deltas}, market) do
    Market.Level2.Mediator.deltas(
      {:via, Registry,
       {
         Market.Level2.Mediator.Registry,
         Market.id(market)
       }},
      deltas
    )

    :ok
  end

  # ...
  defp execute({:buys, buys}, market) do
    Market.Level2.Mediator.buys(
      {:via, Registry,
       {
         Market.Level2.Mediator.Registry,
         Market.id(market)
       }},
      buys
    )

    :ok
  end

  # ...
  defp execute({:sells, sells}, market) do
    Market.Level2.Mediator.sells(
      {:via, Registry,
       {
         Market.Level2.Mediator.Registry,
         Market.id(market)
       }},
      sells
    )

    :ok
  end

  # ...
  defp execute({:fetch, lambda}, _) do
    respond_to = self()

    Task.start(fn ->
      json_str = lambda.()
      send(respond_to, {:fetch_result, json_str})
    end)

    :ok
  end

  # ...
  defp execute(:bad_sync, _) do
    error_msg = "level2 data feed has indicated a bad sync"
    {:error, error_msg}
  end

  # ...
  defp execute(:unknown, _) do
    error_msg = "received unknown instruction"
    {:error, error_msg}
  end

  # ...
  defp execute(:reconnect, _) do
    error_msg = "reconnect requested"
    {:error, error_msg}
  end

  # ...
  defp execute(:noop, _) do
    :ok
  end

  # ...
  defp execute([], _) do
    :ok
  end

  # ...
  defp execute([instruction | remaining], market) do
    case execute(instruction, market) do
      :ok -> execute(remaining, market)
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
  open a new connection with the following config:
  - connecton timeout after 3 seconds;
  - domain lookup timeout after 3 seconds;
  - disconnect timeout after 1 second;
  - never try to reconnect after disconnect;
  - always use HTTP/1.1;
  - ask gun to not supervise this process.
  """
  @impl true
  def init(init_arg) do
    market = init_arg[:market]

    sync_state =
      market.translation_scheme.initial_state(
        market.base_symbol,
        market.quote_symbol
      )

    url = to_charlist(market.ws_url)
    port = market.ws_port

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

    case :gun.open(url, port, options) do
      # the connection process started successfully
      {:ok, conn_pid} ->
        state = %{
          :conn_pid => conn_pid,
          :market => market,
          :sync_state => sync_state,
          :stream_ref => nil
        }

        {:ok, state}

      # failed to start connection process
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  ...
  """
  @impl true
  def terminate(reason, state) do
    # shutdown the connection gracefully, timeout after
    # :http_opts => %{ closing_timeout: 1000 } and force close.
    :ok = :gun.shutdown(state[:conn_pid])
  end

  @doc """
  ...
  """
  @impl true
  # ...
  def handle_info({:fetch_result, json_str}, state) do
    case decode(json_str, state) do
      :nothing ->
        {:noreply, state}

      {:new_state, new_state} ->
        {:noreply, new_state}

      {:error, error_msg} ->
        {:stop, error_msg, state}
    end
  end

  # handle ping
  def handle_info(:do_ping, state) do
    %{
      :market => market,
      :sync_state => sync_state,
      :conn_pid => conn_pid,
      :stream_ref => stream_ref
    } = state

    {:ok, json_strs} = market.translation_scheme.ping_msg(sync_state)

    for json_str <- json_strs do
      :ok = :gun.ws_send(conn_pid, stream_ref, {:text, json_str})
    end

    schedule_ping()

    {:noreply, state}
  end

  # the connection is up.
  def handle_info({:gun_up, _, _}, state) do
    %{
      :market => market,
      :conn_pid => conn_pid
    } = state

    # request a connection upgrade to websocket
    stream_ref = :gun.ws_upgrade(conn_pid, market.ws_path)

    if market.ping? do
      schedule_ping()
    end

    {:noreply, %{state | :stream_ref => stream_ref}}
  end

  # the HTTP connection upgrade was successful.
  def handle_info({:gun_upgrade, _, _, _, _}, state) do
    %{
      :market => market,
      :conn_pid => conn_pid,
      :stream_ref => stream_ref
    } = state

    # make the JSON subscription messages for this exchange
    {:ok, json_strs} =
      market.translation_scheme.subscribe_msg(
        market.base_symbol,
        market.quote_symbol
      )

    # send the subscribe messages to the server
    for json_str <- json_strs do
      :gun.ws_send(conn_pid, stream_ref, {:text, json_str})
    end

    {:noreply, state}
  end

  # received data from the underlying connection.
  def handle_info({:gun_data, _, _, _, _}, state) do
    # do nothing
    {:noreply, state}
  end

  # we received text data from the websocket.
  def handle_info({:gun_ws, _, _, {:text, text}}, state) do
    case decode(text, state) do
      :nothing ->
        {:noreply, state}

      {:new_state, new_state} ->
        {:noreply, new_state}

      {:error, error_msg} ->
        {:stop, error_msg, state}
    end
  end

  # the server closed the websocket.
  def handle_info({:gun_ws, _, _, {:close, _}}, state) do
    # stop the GenServer and reconnect later.
    error_msg = "server closed the websocket"
    {:stop, error_msg, state}
  end

  # the connection has gone down.
  def handle_info({:gun_down, _, _, reason, _}, state) do
    # the connection is dead so stop the websocket GenServer.
    # it will be restarted with a fresh connection.
    error_msg = "connection closed: #{reason}"
    {:stop, error_msg, state}
  end

  # the HTTP upgrade request failed.
  def handle_info({:gun_response, _, _, _, status, _}, state) do
    # the upgrade failed so stop the websocket GenServer.
    # it will be restarted and hopefully the upgrade won't fail again.
    error_msg = "connection upgrade fail, HTTP: #{status}"
    {:stop, error_msg, state}
  end

  # there was a connection error.
  def handle_info({:gun_error, _, _, reason}, state) do
    # there was an error so stop the websocket GenServer.
    # it will be restarted with a fresh connection.
    error_msg = "connection error: #{reason}"
    {:stop, error_msg, state}
  end
end

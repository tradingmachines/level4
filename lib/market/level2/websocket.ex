require Logger

defmodule Market.Level2.WebSocket do
  @moduledoc """
  ...
  """

  use GenServer

  @doc """
  ...
  """
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @doc """
  ...
  """
  @impl true
  def init(init_arg) do
    # open a new connection with the following config:
    # - connecton timeout after 3 seconds;
    # - domain lookup timeout after 3 seconds;
    # - disconnect timeout after 1 second;
    # - never try to reconnect after disconnect;
    # - always use HTTP/1.1;
    # - ask gun to not supervise this process.
    case init_arg[:market].ws_url
         |> to_charlist()
         |> :gun.open(
           init_arg[:market].ws_port,
           %{
             :connect_timeout => 3000,
             :domain_lookup_timeout => 3000,
             :retry => 0,
             :protocols => [:http],
             :supervise => false,
             :http_opts => %{
               closing_timeout: 1000
             }
           }
         ) do
      # the connection process started successfully
      {:ok, conn_pid} ->
        Logger.info(
          "#{Market.id(init_arg[:market])} " <>
            "opened connection"
        )

        {:ok,
         {
           conn_pid,
           init_arg[:market],
           init_arg[:market].translation_scheme.init_sync_state()
         }}

      # failed to start connection process
      {:error, reason} ->
        Logger.error(
          "#{Market.id(init_arg[:market])} " <>
            "unable to open connection: #{reason}"
        )

        {:error, reason}
    end
  end

  @doc """
  ...
  """
  @impl true
  def terminate(reason, {conn_pid, market, _}) do
    # try to shutdown the connection gracefully, timeout after
    # :http_opts => %{ closing_timeout: 1000 } and force close.
    :gun.shutdown(conn_pid)

    Logger.info(
      "#{Market.id(market)} shutdown " <>
        "connection: #{reason}"
    )
  end

  @doc """
  ...
  """
  # the connection is up.
  @impl true
  def handle_info(
        {:gun_up, conn_pid, protocol},
        {_, market, sync_state}
      ) do
    # request a connection upgrade to websocket
    :gun.ws_upgrade(conn_pid, "/")
    {:noreply, {conn_pid, market, sync_state}}
  end

  # the HTTP connection upgrade was successful.
  def handle_info(
        {:gun_upgrade, conn_pid, stream_ref, protocols, headers},
        {_, market, sync_state}
      ) do
    Logger.info(
      "#{Market.id(market)} websocket " <>
        "opened successfully"
    )

    # make the JSON subscription message for this exchange
    {:ok, json_str} =
      market.translation_scheme.make_subscribe_message(
        market.major_symbol,
        market.quote_symbol
      )

    # send the subscribe message to the server
    :gun.ws_send(conn_pid, stream_ref, {:text, json_str})
    Logger.info("#{Market.id(market)} sent subscribe message")
    {:noreply, {conn_pid, market, sync_state}}
  end

  # we received data from the underlying connection.
  def handle_info(
        {:gun_data, conn_pid, stream_ref, is_fin, data},
        {_, market, sync_state}
      ) do
    # do nothing
    {:noreply, {conn_pid, market, sync_state}}
  end

  # we received text data from the websocket.
  def handle_info(
        {:gun_ws, conn_pid, stream_ref, {:text, binary}},
        {_, market, sync_state}
      ) do
    # decode the message and always assume it is JSON.
    case Jason.decode(binary) do
      {:ok, json} ->
        case market.translation_scheme.translate(
               json,
               sync_state
             ) do
          # the message is a snapshot
          {:snapshot, bids, asks, new_sync_state} ->
            Market.Level2.Mediator.snapshot(
              {:via, Registry,
               {
                 Market.Level2.Mediator.Registry,
                 Market.id(market)
               }},
              bids,
              asks
            )

            {:noreply, {conn_pid, market, new_sync_state}}

          # the message is a delta
          {:deltas, deltas, new_sync_state} ->
            Market.Level2.Mediator.deltas(
              {:via, Registry,
               {
                 Market.Level2.Mediator.Registry,
                 Market.id(market)
               }},
              deltas
            )

            {:noreply, {conn_pid, market, new_sync_state}}

          # do nothing
          {:noop, new_sync_state} ->
            {:noreply, {conn_pid, market, new_sync_state}}

          # messages are out of sync
          :out_of_sync ->
            Logger.error("#{Market.id(market)} out of sync")

            # stop the GenServer and reconnect later.
            {
              :stop,
              "out of sync",
              {conn_pid, market, sync_state}
            }

          # unknown message type
          :unknown ->
            Logger.warn(
              "#{Market.id(market)} don't know what to " <>
                "do with message: #{inspect(json)}"
            )

            {:noreply, {conn_pid, market, sync_state}}
        end

      {:error, decode_error} ->
        Logger.error(
          "#{Market.id(market)} unable to " <>
            "decode JSON: #{decode_error}"
        )

        # stop the GenServer and reconnect later.
        {
          :stop,
          "unable to decode JSON: #{decode_error}",
          {conn_pid, market, sync_state}
        }
    end
  end

  # the server closed the websocket.
  def handle_info(
        {:gun_ws, conn_pid, stream_ref, {:close, _}},
        {_, market, sync_state}
      ) do
    Logger.error(
      "#{Market.id(market)} server closed " <>
        "the websocket"
    )

    # stop the GenServer and reconnect later.
    {
      :stop,
      "server closed the websocket",
      {conn_pid, market, sync_state}
    }
  end

  # the connection has gone down.
  def handle_info(
        {:gun_down, conn_pid, protocol, reason, killed_streams},
        {_, market, sync_state}
      ) do
    Logger.info(
      "#{Market.id(market)} connection " <>
        "closed: #{reason}"
    )

    # the connection is dead so stop the websocket GenServer.
    # it will be restarted with a fresh connection.
    {
      :stop,
      "connection closed: #{reason}",
      {conn_pid, market, sync_state}
    }
  end

  # the HTTP upgrade request failed.
  def handle_info(
        {:gun_response, conn_pid, stream_ref, is_fin, status, headers},
        {_, market, sync_state}
      ) do
    Logger.error(
      "#{Market.id(market)} connection " <>
        "upgrade fail, HTTP: #{status}"
    )

    # the upgrade failed so stop the websocket GenServer.
    # it will be restarted and hopefully the upgrade won't fail again.
    {
      :stop,
      "connection upgrade fail, HTTP: #{status}",
      {conn_pid, market, sync_state}
    }
  end

  # there was a connection error.
  def handle_info(
        {:gun_error, conn_pid, stream_ref, reason},
        {_, market, sync_state}
      ) do
    Logger.error(
      "#{Market.id(market)} connection " <>
        "error: #{reason}"
    )

    # there was an error so stop the websocket GenServer.
    # it will be restarted with a fresh connection.
    {
      :stop,
      "connection error: #{reason}",
      {conn_pid, market, sync_state}
    }
  end
end

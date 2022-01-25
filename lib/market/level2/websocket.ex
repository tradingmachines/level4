require Logger

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

        if init_arg[:market].ping? do
          schedule_ping()
        end

        {:ok,
         {
           conn_pid,
           init_arg[:market],
           init_arg[:market].translation_scheme.init_sync_state(
             init_arg[:market].base_symbol,
             init_arg[:market].quote_symbol
           )
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
        "connection: #{inspect(reason)}"
    )
  end

  @doc """
  ...
  """
  @impl true
  # handle ping
  def handle_info(:do_ping, {conn_pid, market, sync_state}) do
    json_str = market.translation_scheme.make_ping_message()
    :gun.ws_send(conn_pid, stream_ref, {:text, json_str})

    if market.ping? do
      schedule_ping()
    end

    {:noreply, {conn_pid, market, sync_state}}
  end

  # the connection is up.
  def handle_info(
        {:gun_up, conn_pid, protocol},
        {_, market, sync_state}
      ) do
    # request a connection upgrade to websocket
    :gun.ws_upgrade(conn_pid, market.ws_path)
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

    # make the JSON subscription messages for this exchange
    json_strs =
      market.translation_scheme.make_subscribe_messages(
        market.base_symbol,
        market.quote_symbol
      )

    # send the subscribe messages to the server
    for json_str <- json_strs do
      :gun.ws_send(conn_pid, stream_ref, {:text, json_str})
    end

    Logger.info("#{Market.id(market)} sent subscribe messages")

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
        {instructions, new_sync_state} =
          market.translation_scheme.translate(
            json,
            sync_state
          )

        for instruction <- instructions do
          case instruction do
            # the message is a snapshot
            {:snapshot, bids, asks} ->
              Market.Level2.Mediator.snapshot(
                {:via, Registry,
                 {
                   Market.Level2.Mediator.Registry,
                   Market.id(market)
                 }},
                bids,
                asks
              )

            # the message contains deltas
            {:deltas, deltas} ->
              Market.Level2.Mediator.deltas(
                {:via, Registry,
                 {
                   Market.Level2.Mediator.Registry,
                   Market.id(market)
                 }},
                deltas
              )

            # the message contains multiple buys
            {:buys, buys} ->
              Market.Level2.Mediator.buys(
                {:via, Registry,
                 {
                   Market.Level2.Mediator.Registry,
                   Market.id(market)
                 }},
                buys
              )

            # the message contains multiple sells
            {:sells, sells} ->
              Market.Level2.Mediator.sells(
                {:via, Registry,
                 {
                   Market.Level2.Mediator.Registry,
                   Market.id(market)
                 }},
                sells
              )

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

            # do nothing
            :noop ->
              :noop
          end
        end

        {:noreply, {conn_pid, market, new_sync_state}}

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

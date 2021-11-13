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
    case init_arg[:market].exchange_ws_url
         |> to_charlist()
         |> :gun.open(
           443,
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
      {:ok, pid} ->
        id = Level4.Market.id(init_arg[:market])
        Logger.info("#{id} opened connection")
        {:ok, {pid, init_arg[:market]}}

      # failed to start connection process
      {:error, reason} ->
        id = Level4.Market.id(init_arg[:market])
        Logger.error("#{id} unable to open connection: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  ...
  """
  @impl true
  def terminate(reason, {conn_pid, market}) do
    # try to shutdown the connection gracefully, timeout after
    # :http_opts => %{ closing_timeout: 1000 } and force close.
    :gun.shutdown(conn_pid)

    # log shutdown
    id = Level4.Market.id(market)
    Logger.info("#{id} shutdown down connection")
  end

  @doc """
  ...
  """
  # the connection is up.
  @impl true
  def handle_info(
        {:gun_up, conn_pid, protocol},
        {_, market}
      ) do
    # request a connection upgrade to websocket
    :gun.ws_upgrade(conn_pid, "/")
    {:noreply, {conn_pid, market}}
  end

  # the HTTP connection upgrade was successful.
  def handle_info(
        {:gun_upgrade, conn_pid, stream_ref, protocols, headers},
        {_, market}
      ) do
    # log connection upgraded
    id = Level4.Market.id(market)
    Logger.info("#{id} upgraded connection to websocket")

    # make the JSON subscription message
    {:ok, json_str} =
      market.translation_scheme.make_subscribe_message(
        market.major_symbol,
        market.quote_symbol
      )

    # send the subscribe message to the server
    :gun.ws_send(conn_pid, stream_ref, {:text, json_str})
    Logger.info("#{id} sent subscribe message")

    {:noreply, {conn_pid, market}}
  end

  # we received data from the underlying connection.
  def handle_info(
        {:gun_data, conn_pid, stream_ref, is_fin, data},
        {_, market}
      ) do
    # do nothing
    {:noreply, {conn_pid, market}}
  end

  # we received text data from the websocket.
  def handle_info(
        {:gun_ws, conn_pid, stream_ref, {:text, binary}},
        {_, market}
      ) do
    # decode the message and always assume it is JSON.
    case Jason.decode(binary) do
      # decoded JSON successfully
      {:ok, map} ->
        case market.translation_scheme.message_type(map) do
          # the message is a snapshot
          :snapshot ->
            Market.Level2.Mediator.snapshot(
              {:via, Registry,
               {
                 Market.Level2.Mediator.Registry,
                 Level4.Market.id(market)
               }},
              [],
              []
            )

            {:noreply, {conn_pid, market}}

          # the message is a bid delta
          :bid_delta ->
            Market.Level2.Mediator.delta(
              {:via, Registry,
               {
                 Market.Level2.Mediator.Registry,
                 Level4.Market.id(market)
               }},
              :bid,
              {price, size}
            )

            {:noreply, {conn_pid, market}}

          # the message is an ask delta
          :bid_delta ->
            Market.Level2.Mediator.delta(
              {:via, Registry,
               {
                 Market.Level2.Mediator.Registry,
                 Level4.Market.id(market)
               }},
              :ask,
              {price, size}
            )

            {:noreply, {conn_pid, market}}

          # unknown message type
          true ->
            # log error
            id = Level4.Market.id(market)
            Logger.error("#{id} don't know what to do with: #{inspect(map)}")

            # stop the GenServer and reconnect later.
            {
              :stop,
              "don't know what to do with: #{inspect(map)}",
              {conn_pid, market}
            }
        end

      # failed to decode data
      {:error, decode_error} ->
        # log error
        id = Level4.Market.id(market)
        Logger.error("#{id} unable to decode JSON: #{decode_error}")

        # stop the GenServer and reconnect later.
        {
          :stop,
          "unable to decode JSON: #{decode_error}",
          {conn_pid, market}
        }
    end
  end

  # the server closed the websocket.
  def handle_info(
        {:gun_ws, conn_pid, stream_ref, {:close, _}},
        {_, market}
      ) do
    # log error
    id = Level4.Market.id(market)
    Logger.error("#{id} server closed the websocket")

    # stop the GenServer and reconnect later.
    {
      :stop,
      "server closed the websocket",
      {conn_pid, market}
    }
  end

  # the connection has gone down.
  def handle_info(
        {:gun_down, conn_pid, protocol, reason, killed_streams},
        {_, market}
      ) do
    # log connection closed
    id = Level4.Market.id(market)
    Logger.info("#{id} connection closed: #{reason}")

    # the connection is dead so stop the websocket GenServer.
    # it will be restarted with a fresh connection.
    {
      :stop,
      "connection closed: #{reason}",
      {conn_pid, market}
    }
  end

  # the HTTP upgrade request failed.
  def handle_info(
        {:gun_response, conn_pid, stream_ref, is_fin, status, headers},
        {_, market}
      ) do
    # log the error
    id = Level4.Market.id(market)
    Logger.error("#{id} connection upgrade fail, HTTP: #{status}")

    # the upgrade failed so stop the websocket GenServer.
    # it will be restarted and hopefully the upgrade won't fail again.
    {
      :stop,
      "connection upgrade fail, HTTP: #{status}",
      {conn_pid, market}
    }
  end

  # there was a connection error.
  def handle_info(
        {:gun_error, conn_pid, stream_ref, reason},
        {_, market}
      ) do
    # log the error
    id = Level4.Market.id(market)
    Logger.error("#{id} connection error: #{reason}")

    # there was an error so stop the websocket GenServer.
    # it will be restarted with a fresh connection.
    {
      :stop,
      "connection error: #{reason}",
      {conn_pid, market}
    }
  end
end

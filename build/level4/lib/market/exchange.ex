require Logger

defmodule Market.Exchange do
  @moduledoc """
  A Market.Exchange receives and handles messages from a
  Market.Level2.Mediator process. The exchange process is
  responsible for writing data to the data sump.
  """

  use GenServer

  @doc """
  Starts and links a new GenServer with the name returned from the
  process_name function above.
  """
  def start_link(init_arg) do
    GenServer.start_link(
      __MODULE__,
      init_arg,
      name:
        {:via, Registry,
         {
           Market.Exchange.Registry,
           Market.tag(init_arg[:market])
         }}
    )
  end

  @doc """
  Init function for the GenServer. Return the :market from init_arg
  as well as the PID of a TCP socket client -> to use as GenServer
  initial state.
  """
  @impl true
  def init(init_arg) do
    {:ok, data_sump} = Application.fetch_env(:level4, :data_sump)

    Logger.info("#{init_arg[:market]}: starting exchange genserver")

    # tcp socket: connect to flume data sump
    {:ok, socket} =
      :gen_tcp.connect(
        data_sump[:host],
        data_sump[:port],
        [:binary, active: false]
      )

    Logger.info("#{init_arg[:market]}: connected to data sump")

    {:ok, {init_arg[:market], socket}}
  end

  @doc """
  close tcp socket on terminate.
  """
  @impl true
  def terminate(_, {_, socket}) do
    :ok = :gen_tcp.close(socket)
  end

  @doc """
  GenServer cast functions for async API calls.
  """
  # :best_bid_change -> the best bid price changed -> log it
  # {price, initial liquidity, utc timestamp}
  @impl true
  def handle_cast(
        {:best_bid_change, {price, liquidity, timestamp}},
        {market, socket}
      ) do
    # make payload string
    market_id = market.market_id
    unix_ns = DateTime.to_unix(timestamp, :nanosecond)
    payload = "bids,#{market_id},#{price},#{liquidity},#{unix_ns}\n"

    # send string to data sump
    :ok = :gen_tcp.send(socket, payload)
    {:noreply, {market, socket}}
  end

  # :best_ask_change -> the best ask price changed -> log it
  # {price, initial liquidity, utc timestamp}
  def handle_cast(
        {:best_ask_change, {price, liquidity, timestamp}},
        {market, socket}
      ) do
    # make payload string
    market_id = market.market_id
    unix_ns = DateTime.to_unix(timestamp, :nanosecond)
    payload = "asks,#{market_id},#{price},#{liquidity},#{unix_ns}\n"

    # send string to data sump
    :ok = :gen_tcp.send(socket, payload)
    {:noreply, {market, socket}}
  end

  # :new_buy -> there was a new market buy -> log it
  # {price, size, utc timestamp}
  def handle_cast(
        {:new_buy, {price, size, timestamp}},
        {market, socket}
      ) do
    # make payload string
    market_id = market.market_id
    unix_ns = DateTime.to_unix(timestamp, :nanosecond)
    payload = "buy,#{market_id},#{price},#{size},#{unix_ns}\n"

    # send string to data sump
    :ok = :gen_tcp.send(socket, payload)
    {:noreply, {market, socket}}
  end

  # :new_sell -> there was a new market buy -> log it
  # {price, size, utc timestamp}
  def handle_cast(
        {:new_sell, {price, size, timestamp}},
        {market, socket}
      ) do
    # make payload string
    market_id = market.market_id
    unix_ns = DateTime.to_unix(timestamp, :nanosecond)
    payload = "sell,#{market_id},#{price},#{size},#{unix_ns}\n"

    # send string to data sump
    :ok = :gen_tcp.send(socket, payload)
    {:noreply, {market, socket}}
  end

  @doc """
  Async Market.Exchange API: a helper function that sends a
  :best_bid_change to the GenServer. Note: casts are asynchronous
  requests.
  """
  def best_bid_change(exchange, {new_price, new_size, timestamp}) do
    GenServer.cast(
      exchange,
      {:best_bid_change, {new_price, new_size, timestamp}}
    )
  end

  @doc """
  Async Market.Exchange API: a helper function that sends a
  :best_ask_change to the GenServer. Note: casts are asynchronous
  requests.
  """
  def best_ask_change(exchange, {new_price, new_size, timestamp}) do
    GenServer.cast(
      exchange,
      {:best_ask_change, {new_price, new_size, timestamp}}
    )
  end

  @doc """
  Async Market.Exchange API: a helper function that sends a
  :new_buy to the GenServer. Note: casts are asynchronous
  requests.
  """
  def new_buy(exchange, {price, size, timestamp}) do
    GenServer.cast(
      exchange,
      {:new_buy, {price, size, timestamp}}
    )
  end

  @doc """
  Async Market.Exchange API: a helper function that sends a
  :new_sell to the GenServer. Note: casts are asynchronous
  requests.
  """
  def new_sell(exchange, {price, size, timestamp}) do
    GenServer.cast(
      exchange,
      {:new_sell, {price, size, timestamp}}
    )
  end
end

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
           Market.id(init_arg[:market])
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

    Logger.info(
      "#{Market.id(init_arg[:market])} " <>
        "starting exchange genserver"
    )

    {:ok, socket} =
      :gen_tcp.connect(
        data_sump[:host],
        data_sump[:port],
        [:binary, active: false]
      )

    Logger.info(
      "#{Market.id(init_arg[:market])} " <>
        "connected to data sump"
    )

    {:ok, {init_arg[:market], socket}}
  end

  @doc """
  GenServer cast functions for async API calls.
  """
  # :best_bid_change -> the best bid price changed -> log it
  @impl true
  def handle_cast(
        {:best_bid_change, {new_price, initial_liquidity, timestamp}},
        {market, socket}
      ) do
    # ...
    payload = "bids,#{market.id},#{new_price},#{initial_liquidity},#{timestamp}\n"
    :ok = :gen_tcp.send(socket, payload)
    {:noreply, {market, socket}}
  end

  # :best_ask_change -> the best ask price changed -> log it
  def handle_cast(
        {:best_ask_change, {new_price, initial_liquidity, timestamp}},
        {market, socket}
      ) do
    # ...
    payload = "asks,#{market.id},#{new_price},#{initial_liquidity},#{timestamp}\n"
    :ok = :gen_tcp.send(socket, payload)
    {:noreply, {market, socket}}
  end

  # :new_buy -> there was a new market buy -> log it
  def handle_cast(
        {:new_buy, {price, size, timestamp}},
        {market, socket}
      ) do
    # ...
    payload = "buy,#{market.id},#{price},#{size},#{timestamp}\n"
    :ok = :gen_tcp.send(socket, payload)
    {:noreply, {market, socket}}
  end

  # :new_sell -> there was a new market buy -> log it
  def handle_cast(
        {:new_sell, {price, size, timestamp}},
        {market, socket}
      ) do
    # ...
    payload = "sell,#{market.id},#{price},#{size},#{timestamp}\n"
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

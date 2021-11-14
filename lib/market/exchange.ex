require Logger

defmodule Market.Exchange do
  @moduledoc """
  A Market.Exchange receives and handles messages from a
  Market.Level2.Mediator process.

  The exchange process is responsible for writing data to some persistent
  storage medium.
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
  Init function for the GenServer. Initialises a new storage medium and returns
  it to the GenServer so it is kept in the server's state for future use.
  """
  @impl true
  def init(init_arg) do
    Logger.info(
      "#{Market.id(init_arg[:market])} " <>
        "starting exchange"
    )

    # TODO setup storage medium
    # ...
    store = nil

    {:ok, {init_arg[:market], store}}
  end

  @doc """
  Terminate function for the GenServer. Handles tear-down of the storage medium.
  """
  @impl true
  def terminate(reason, {market, _}) do
    # handle termination
    # ...
  end

  @doc """
  GenServer cast function for :best_bid_change and :best_bid_change events
  received from the mediator process.
  """
  @impl true
  def handle_cast(
        {:best_bid_change, {new_price, new_size}},
        {market, store}
      ) do
    Logger.debug(
      "#{Market.id(market)} " <>
        "best bid change: #{new_price}"
    )

    # TODO

    {:noreply, {market, store}}
  end

  def handle_cast(
        {:best_ask_change, {new_price, new_size}},
        {market, store}
      ) do
    Logger.debug(
      "#{Market.id(market)} " <>
        "best ask change: #{new_price}"
    )

    # TODO

    {:noreply, {market, store}}
  end

  @doc """
  Market.Exchange API: a helper function that sends a :best_bid_change to
  the GenServer. Note: casts are asynchronous requests.
  """
  def best_bid_change(exchange, {new_price, new_size}) do
    GenServer.cast(exchange, {:best_bid_change, {new_price, new_size}})
  end

  @doc """
  Market.Exchange API: a helper function that sends a :best_ask_change to
  the GenServer. Note: casts are asynchronous requests.
  """
  def best_ask_change(exchange, {new_price, new_size}) do
    GenServer.cast(exchange, {:best_ask_change, {new_price, new_size}})
  end
end

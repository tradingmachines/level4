require Logger

defmodule Market.Level2.Mediator do
  @moduledoc """
  A level2 Mediator receives snapshot and delta commands from
  a websocket connection. The Mediator is responsible for updating
  the local orderbook structure.
  """

  use GenServer

  @doc """
  GenServer start_link callback. Register PID under marker Id.
  """
  def start_link(init_arg) do
    GenServer.start_link(
      __MODULE__,
      init_arg,
      name:
        {:via, Registry,
         {
           Market.Level2.Mediator.Registry,
           Market.id(init_arg[:market])
         }}
    )
  end

  @doc """
  GenServer init callback. Initial state is all zero: no best bid or ask
  price seen yet. When either bid/ask prices change, this state will be
  updated accordingly.
  """
  @impl true
  def init(init_arg) do
    Logger.info("#{Market.id(init_arg[:market])} " <> "starting mediator")

    {:ok,
     %{
       :market => init_arg[:market],
       :best_bid => %{:price => 0, :size => 0},
       :best_ask => %{:price => 0, :size => 0}
     }}
  end

  @doc """
  Synchronous API. Apply snapshot to orderbook.
  """
  @impl true
  def handle_call({:snapshot, {bids, asks}}, _, state) do
    Market.Level2.OrderBook.apply_snapshot(
      {:via, Registry,
       {
         Market.Level2.OrderBook.Registry,
         Market.id(state[:market])
       }},
      {bids, asks}
    )

    {:reply, :ok, state}
  end

  # ...
  def handle_call({:delta, {side, price, liquidity}}, _, state) do
    # ...
    timestamp = DateTime.utc_now()

    # ...
    orderbook =
      {:via, Registry,
       {
         Market.Level2.OrderBook.Registry,
         Market.id(state[:market])
       }}

    # ...
    exchange =
      {:via, Registry,
       {
         Market.Exchange.Registry,
         Market.id(state[:market])
       }}

    # apply the delta
    Market.Level2.OrderBook.apply_delta(orderbook, side, {price, liquidity})

    # check if best price changed
    case side do
      :bid ->
        case Market.Level2.OrderBook.best_bid(orderbook) do
          {new_best_bid_price, new_best_bid_size} ->
            if state[:best_bid][:price] != new_best_bid_price do
              # ...
              Market.Exchange.best_bid_change(
                exchange,
                {new_best_bid_price, new_best_bid_size, timestamp}
              )

              # ...
              new_state = %{
                state
                | :best_bid => %{
                    :price => new_best_bid_price,
                    :size => new_best_bid_size
                  }
              }

              {:reply, :ok, new_state}
            else
              {:reply, :ok, state}
            end

          :side_empty ->
            {:reply, :ok, state}
        end

      :ask ->
        case Market.Level2.OrderBook.best_ask(orderbook) do
          {new_best_ask_price, new_best_ask_size} ->
            if state[:best_ask][:price] != new_best_ask_price do
              # ...
              Market.Exchange.best_ask_change(
                exchange,
                {new_best_ask_price, new_best_ask_size, timestamp}
              )

              # ...
              new_state = %{
                state
                | :best_ask => %{
                    :price => new_best_ask_price,
                    :size => new_best_ask_size
                  }
              }

              {:reply, :ok, new_state}
            else
              {:reply, :ok, state}
            end

          :side_empty ->
            {:reply, :ok, state}
        end
    end
  end

  # ...
  def handle_call({side, {price, size, timestamp}}, _, state) do
    exchange =
      {:via, Registry,
       {
         Market.Exchange.Registry,
         Market.id(state[:market])
       }}

    case side do
      :buy -> Market.Exchange.new_buy(exchange, {price, size, timestamp})
      :sell -> Market.Exchange.new_sell(exchange, {price, size, timestamp})
    end

    {:reply, :ok, state}
  end

  @doc """
  Reset both sides of the orderbook. Synchronous API call.
  """
  def snapshot(mediator, bids, asks) do
    GenServer.call(mediator, {:snapshot, {bids, asks}})
  end

  @doc """
  Apply multiple deltas to the order book. Synchronous API call.
  """
  def deltas(mediator, deltas) do
    for delta <- deltas do
      GenServer.call(mediator, {:delta, delta})
    end
  end

  @doc """
  ...
  """
  def buys(mediator, buys) do
    for buy <- buys do
      GenServer.call(mediator, {:buy, buy})
    end
  end

  @doc """
  ...
  """
  def sells(mediator, sells) do
    for sell <- sells do
      GenServer.call(mediator, {:sell, sell})
    end
  end
end

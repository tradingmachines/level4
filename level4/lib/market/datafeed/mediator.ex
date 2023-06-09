defmodule Market.DataFeed.Level2.Mediator do
  @moduledoc """
  A level2 Mediator receives snapshot and delta commands from
  a websocket connection. The Mediator is responsible for updating
  the local orderbook structure. It also keeps track of the best
  bid and ask prices, and notifies the main data feed process when
  either of the best prices change,
  """

  use GenServer

  def start_link(init_arg),
    do:
      GenServer.start_link(
        __MODULE__,
        init_arg,
        name:
          {:via, Registry,
           {
             Market.Level2.Registry,
             init_arg[:market].id
           }}
      )

  @impl true
  def init(init_arg),
    do:
      {:ok,
       %{
         :market => init_arg[:market],
         :node => init_arg[:node],
         :best_bid => price_level(:default),
         :best_ask => price_level(:default)
       }}

  @doc """
  Return map containg price and liquidity.
  """
  def price_level(price, liquidity),
    do: %{:price => price, :liquidity => liquidity}

  def price_level(:default),
    do: %{:price => 0, :liquidity => 0}

  @doc """
  Do comparison between two prices.
  """
  def best_price_changed?(best, current),
    do: best != current

  @doc """
  Handle snapshot / deltas / and buys/sells.
  """
  @impl true
  def handle_call({:snapshot, bid_levels, ask_levels}, _, state) do
    # get the orderbook pid
    book = {:via, Registry, {Market.OrderBook.Registry, state[:market].id}}

    # apply the snapshot
    :ok =
      Market.DataFeed.Level2.OrderBook.apply_snapshot(
        book,
        {bid_levels, ask_levels}
      )

    # get the new best bid
    {
      best_bid_price,
      best_bid_liquidity
    } = Market.DataFeed.Level2.OrderBook.best_bid(book)

    # get the new best ask
    {
      best_ask_price,
      best_ask_liquidity
    } = Market.DataFeed.Level2.OrderBook.best_ask(book)

    # update state's best bid/ask levels
    {:reply, :ok,
     %{
       state
       | :best_bid => price_level(best_bid_price, best_bid_liquidity),
         :best_ask => price_level(best_ask_price, best_ask_liquidity)
     }}
  end

  @impl true
  def handle_call({:delta, side, price, liquidity}, _, state) do
    # get the orderbook and datafeed pids
    book = {:via, Registry, {Market.OrderBook.Registry, state[:market].id}}
    data_feed = {:via, Registry, {Market.DataFeed.Registry, state[:market].id}}

    # apply the delta
    :ok =
      Market.DataFeed.Level2.OrderBook.apply_delta(
        book,
        side,
        {price, liquidity}
      )

    # get the new best bid
    {
      best_bid_price,
      best_bid_liquidity
    } = Market.DataFeed.Level2.OrderBook.best_bid(book)

    # get the new best ask
    {
      best_ask_price,
      best_ask_liquidity
    } = Market.DataFeed.Level2.OrderBook.best_ask(book)

    case side do
      :bid ->
        if best_price_changed?(state[:best_bid][:price], best_bid_price) do
          # send a new event to the data feed
          :ok =
            Market.DataFeed.best_bid_change(
              data_feed,
              best_bid_price,
              best_bid_liquidity
            )

          # update the state's best bid
          {:reply, :ok,
           %{
             state
             | :best_bid => price_level(best_bid_price, best_bid_liquidity)
           }}
        else
          # no need to update best bid
          {:reply, :ok, state}
        end

      :ask ->
        if best_price_changed?(state[:best_ask][:price], best_ask_price) do
          # send a new event to the data feed
          :ok =
            Market.DataFeed.best_ask_change(
              data_feed,
              best_ask_price,
              best_ask_liquidity
            )

          # update the state's best ask
          {:reply, :ok,
           %{
             state
             | :best_ask => price_level(best_ask_price, best_ask_liquidity)
           }}
        else
          # no need to update best ask
          {:reply, :ok, state}
        end
    end
  end

  @impl true
  def handle_call({:fill, side, price, size}, _, state) do
    # get the data feed pid
    data_feed = {:via, Registry, {Market.DataFeed.Registry, state[:market].id}}

    # notify the data feed
    case side do
      :buy ->
        :ok = Market.DataFeed.buy(data_feed, price, size)

      :sell ->
        :ok = Market.DataFeed.sell(data_feed, price, size)
    end

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:status_update, event}, _, state) do
    # get the data feed pid
    data_feed = {:via, Registry, {Market.DataFeed.Registry, state[:market].id}}

    # notify the data feed
    :ok =
      Market.DataFeed.status_update(
        data_feed,
        event,
        state[:node]
      )

    {:reply, :ok, state}
  end

  @doc """
  Snapshot: set price levels for both sides of the orderbook.
  """
  def snapshot(level2, bid_levels, ask_levels) do
    :ok = GenServer.call(level2, {:snapshot, bid_levels, ask_levels})
    :ok = GenServer.call(level2, {:status_update, "snapshot"})
    :ok
  end

  @doc """
  Bid delta: update a price level on the bids side.
  """
  def bids_delta(level2, price, liquidity) do
    :ok = GenServer.call(level2, {:delta, :bid, price, liquidity})
    :ok
  end

  @doc """
  Ask delta: update a price level on the asks side.
  """
  def asks_delta(level2, price, liquidity) do
    :ok = GenServer.call(level2, {:delta, :ask, price, liquidity})
    :ok
  end

  @doc """
  Buy fill: somebody took from the asks side.
  """
  def buy(level2, price, size) do
    :ok = GenServer.call(level2, {:fill, :buy, price, size})
    :ok
  end

  @doc """
  Sell fill: somebody took from the bids side.
  """
  def sell(level2, price, size) do
    :ok = GenServer.call(level2, {:fill, :sell, price, size})
    :ok
  end
end

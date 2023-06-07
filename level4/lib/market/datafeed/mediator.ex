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
         :best_bid => best_price(0, 0),
         :best_ask => best_price(0, 0)
       }}

  @doc """
  Do comparison between two prices.
  """
  def best_price_changed?(best, current),
    do: best != current

  @doc """
  Return map containg price and liquidity.
  """
  def best_price(price, liquidity),
    do: %{:price => price, :liquidity => liquidity}

  @doc """
  Handle snapshot / deltas / and buys/sells.
  """
  @impl true
  def handle_call({:snapshot, bid_levels, ask_levels}, _, state) do
    # get the orderbook pid
    book =
      {:via, Registry,
       {
         Market.OrderBook.Registry,
         state[:market].id
       }}

    # apply the snapshot
    :ok =
      Market.DataFeed.Level2.OrderBook.apply_snapshot(
        book,
        {bid_levels, ask_levels}
      )

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:delta, side, price, liquidity}, _, state) do
    # get the orderbook pid
    book =
      {:via, Registry,
       {
         Market.OrderBook.Registry,
         state[:market].id
       }}

    # get the data feed pid
    data_feed =
      {:via, Registry,
       {
         Market.DataFeed.Registry,
         state[:market].id
       }}

    # apply the delta
    :ok =
      Market.DataFeed.Level2.OrderBook.apply_delta(
        book,
        side,
        {price, liquidity}
      )

    case side do
      :bid ->
        if best_price_changed?(state[:best_bid][:price], price) do
          # update best bid price
          :ok = Market.DataFeed.best_bid_change(data_feed, price, liquidity)
          {:reply, :ok, %{state | :best_bid => best_price(price, liquidity)}}
        else
          # no need to update best bid price
          {:reply, :ok, state}
        end

      :ask ->
        if best_price_changed?(state[:best_ask][:price], price) do
          # update best ask price
          :ok = Market.DataFeed.best_ask_change(data_feed, price, liquidity)
          {:reply, :ok, %{state | :best_ask => best_price(price, liquidity)}}
        else
          # no need to update best ask price
          {:reply, :ok, state}
        end
    end
  end

  @impl true
  def handle_call({:fill, side, price, size}, _, state) do
    # get the data feed pid
    data_feed =
      {:via, Registry,
       {
         Market.DataFeed.Registry,
         state[:market].id
       }}

    case side do
      :buy ->
        # notify the data feed of the buy event
        :ok = Market.DataFeed.buy(data_feed, price, size)

      :sell ->
        # notify the data feed of the sell event
        :ok = Market.DataFeed.sell(data_feed, price, size)
    end

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:status, event}, _, state) do
    # get the data feed pid
    data_feed =
      {:via, Registry,
       {
         Market.DataFeed.Registry,
         state[:market].id
       }}

    # notify the data feed of status change
    :ok =
      Market.DataFeed.status(
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
    :ok = GenServer.call(level2, {:status, "snapshot"})
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

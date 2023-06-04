defmodule Market.DataFeed do
  @moduledoc """
  A Market.DataFeed receives and handles messages from a
  Market.DataFeed.Level2 process. The DataFeed process is
  responsible for sending events to the relevant kafka topics.
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
             Market.DataFeed.Registry,
             init_arg[:market].id
           }}
      )

  @impl true
  def init(init_arg),
    do:
      {:ok,
       %{
         :market => init_arg[:market]
       }}

  @doc """
  Insert unix timestamp (nanoseconds) into event payload and send json payload
  to kafka topic.
  """
  def produce_event(topic, key, payload) do
    # tag events with nanosecond timestamp
    ts = :erlang.system_time(:nanosecond)

    # insert timestamp into payload and encode as json
    {:ok, json_str} = Jason.encode(payload |> Map.put("unix_ts_ns", ts))

    # publish event to kafka topic
    :ok = Kaffe.Producer.produce_sync(topic, key, json_str)

    :ok
  end

  @doc """
  ...
  """
  @impl true
  def handle_call(:metadata, _, state),
    do: {:reply, state[:market], state}

  @doc """
  Best bid/ask price update event and buy/sell events.
  """
  @impl true
  def handle_cast({:best_price, side, price, liquidity}, state) do
    # event key is the string version of the market id
    key = Integer.to_string(state[:market].id)

    # construct the event payload
    payload = %{
      "side" =>
        case side do
          :bids -> "bids"
          :asks -> "asks"
        end,
      "price" => price,
      "liquidity" => liquidity
    }

    # send event to kafka
    :ok = produce_event("level4.spread", key, payload)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:fill, side, price, size}, state) do
    # event key is the string version of the market id
    key = Integer.to_string(state[:market].id)

    # construct the event payload
    payload = %{
      "side" =>
        case side do
          :buy -> "buy"
          :sell -> "sell"
        end,
      "price" => price,
      "size" => size
    }

    # send event to kafka
    :ok = produce_event("level4.timesale", key, payload)

    {:noreply, state}
  end

  @doc """
  ...
  """
  def metadata(data_feed),
    do: GenServer.call(data_feed, :metadata)

  @doc """
  Record a new best bid price change event.
  """
  def best_bid_change(data_feed, price, liquidity),
    do:
      GenServer.cast(
        data_feed,
        {:best_price, :bids, price, liquidity}
      )

  @doc """
  Record a new best ask price change event.
  """
  def best_ask_change(data_feed, price, liquidity),
    do:
      GenServer.cast(
        data_feed,
        {:best_price, :asks, price, liquidity}
      )

  @doc """
  Record a new buy event.
  """
  def buy(data_feed, price, size),
    do:
      GenServer.cast(
        data_feed,
        {:fill, :buy, price, size}
      )

  @doc """
  Record a new sell event.
  """
  def sell(data_feed, price, size),
    do:
      GenServer.cast(
        data_feed,
        {:fill, :sell, price, size}
      )
end

defmodule Market.DataFeed.Supervisor do
  @moduledoc """
  A Market.DataFeed.Supervisor supervises a static tree consisting of a
  Market.DataFeed process and a Market.DataFeed.Level2.Supervisor. The
  level2 supervisor sets-up and monitors the orderbook and websocket.
  """

  use Supervisor

  def start_link(init_arg),
    do:
      Supervisor.start_link(
        __MODULE__,
        init_arg,
        name:
          {:via, Registry,
           {
             Market.Registry,
             init_arg[:market].id
           }}
      )

  @impl true
  def init(init_arg),
    do:
      Supervisor.init(
        [
          # the datafeed
          %{
            id: Market.DataFeed,
            start: {Market.DataFeed, :start_link, [init_arg]},
            type: :worker
          },

          # level2 supervisor (orderbook and websocket)
          %{
            id: Market.DataFeed.Level2.Supervisor,
            start: {Market.DataFeed.Level2.Supervisor, :start_link, [init_arg]},
            type: :supervisor
          }
        ],
        strategy: :one_for_all,
        max_restarts: 1
      )
end

defmodule Market.DataFeed.Level2 do
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

  @doc """
  Snapshot: set price levels for both sides of the orderbook.
  """
  def snapshot(level2, bid_levels, ask_levels),
    do: GenServer.call(level2, {:snapshot, bid_levels, ask_levels})

  @doc """
  Bid delta: update a price level on the bids side.
  """
  def bids_delta(level2, price, liquidity),
    do: GenServer.call(level2, {:delta, :bid, price, liquidity})

  @doc """
  Ask delta: update a price level on the asks side.
  """
  def asks_delta(level2, price, liquidity),
    do: GenServer.call(level2, {:delta, :ask, price, liquidity})

  @doc """
  Buy fill: somebody took from the asks side.
  """
  def buy(level2, price, size),
    do: GenServer.call(level2, {:fill, :buy, price, size})

  @doc """
  Sell fill: somebody took from the bids side.
  """
  def sell(level2, price, size),
    do: GenServer.call(level2, {:fill, :sell, price, size})
end

defmodule Market.DataFeed.Level2.Supervisor do
  @moduledoc """
  Supervises level2 data stream - which consists of three components:
  1. mediator
  2. orderbook
  3. websocket

  They are started in that order and the rest_for_one strategy is used.
  I.e. if websocket crashes then just restart websocket. If orderbook
  crashes then restart orderbook and websocket. If mediator crashes then
  restart mediator, orderbook, and websocket.
  """

  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg)
  end

  @impl true
  def init(init_arg) do
    Supervisor.init(
      [
        # level2 mediator
        %{
          id: Market.DataFeed.Level2,
          start: {Market.DataFeed.Level2, :start_link, [init_arg]},
          type: :worker
        },

        # orderbook
        %{
          id: Market.DataFeed.Level2.OrderBook,
          start: {Market.DataFeed.Level2.OrderBook, :start_link, [init_arg]},
          type: :worker
        },

        # websocket
        %{
          id: Market.DataFeed.Level2.WebSocket,
          start: {Market.DataFeed.Level2.WebSocket, :start_link, [init_arg]},
          type: :worker
        }
      ],
      strategy: :rest_for_one,
      max_restarts: 3,
      max_seconds: 5
    )
  end
end

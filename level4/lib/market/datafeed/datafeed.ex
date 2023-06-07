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

defmodule Market.DataFeed do
  @moduledoc """
  A Market.DataFeed receives and handles messages from a
  Market.DataFeed.Level2.Mediator process. The DataFeed process
  is responsible for sending events to the relevant kafka topics.
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

  @impl true
  def handle_cast({:status, event, node}, state) do
    # event key is the string version of the market id
    key = Integer.to_string(state[:market].id)

    # construct the event payload
    payload = %{
      "event" => event,
      "node" => node,
      "market_id" => state[:market].id
    }

    # send event to kafka
    :ok = produce_event("level4.status", key, payload)

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

  @doc """
  Data feed status change.
  """
  def status(data_feed, event, node),
    do:
      GenServer.cast(
        data_feed,
        {:status, event, node}
      )
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
        # mediator (orderbook <-> mediator <-> websocket)
        %{
          id: Market.DataFeed.Level2.Mediator,
          start: {Market.DataFeed.Level2.Mediator, :start_link, [init_arg]},
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

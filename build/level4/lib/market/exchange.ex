require Logger

defmodule Market.Exchange do
  @moduledoc """
  A Market.Exchange receives and handles messages from a
  Market.Level2.Mediator process. The exchange process is
  responsible for writing data to kafka topics.
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
  as initial state.
  """
  @impl true
  def init(init_arg) do
    Logger.info("#{init_arg[:market]}: starting exchange genserver")
    {:ok, init_arg[:market]}
  end

  @doc """
  GenServer cast functions for async API calls.
  """
  # :best_bid_change -> the best bid price changed -> log it
  # {price, initial liquidity, utc timestamp nano seconds}
  @impl true
  def handle_cast(
        {:best_bid_change, {price, liquidity, timestamp}},
        market
      ) do
    # nano second time
    # use market id as kafka message key
    unix_ts_ns = DateTime.to_unix(timestamp, :nanosecond)
    market_id_str = Integer.to_string(market.market_id)

    # make json string message content
    {:ok, json_str} =
      Jason.encode(%{
        "side" => "bids",
        "price" => price,
        "liquidity" => liquidity,
        "unix_ts_ns" => unix_ts_ns
      })

    # send to message queue topic
    :ok =
      Kaffe.Producer.produce_sync(
        "level4.spread",
        market_id_str,
        json_str
      )

    {:noreply, market}
  end

  # :best_ask_change -> the best ask price changed -> log it
  # {price, initial liquidity, utc timestamp nano seconds}
  def handle_cast(
        {:best_ask_change, {price, liquidity, timestamp}},
        market
      ) do
    # nano second time
    # use market id as kafka message key
    unix_ts_ns = DateTime.to_unix(timestamp, :nanosecond)
    market_id_str = Integer.to_string(market.market_id)

    # make json string message content
    {:ok, json_str} =
      Jason.encode(%{
        "side" => "asks",
        "price" => price,
        "liquidity" => liquidity,
        "unix_ts_ns" => unix_ts_ns
      })

    # send to message queue topic
    :ok =
      Kaffe.Producer.produce_sync(
        "level4.spread",
        market_id_str,
        json_str
      )

    {:noreply, market}
  end

  # :new_buy -> there was a new market buy -> log it
  # {price, size, utc timestamp nano seconds}
  def handle_cast(
        {:new_buy, {price, size, timestamp}},
        market
      ) do
    # nano second time
    # use market id as kafka message key
    unix_ts_ns = DateTime.to_unix(timestamp, :nanosecond)
    market_id_str = Integer.to_string(market.market_id)

    # make json string message content
    {:ok, json_str} =
      Jason.encode(%{
        "side" => "buy",
        "price" => price,
        "size" => size,
        "unix_ts_ns" => unix_ts_ns
      })

    # send to message queue topic
    :ok =
      Kaffe.Producer.produce_sync(
        "level4.timesale",
        market_id_str,
        json_str
      )

    {:noreply, market}
  end

  # :new_sell -> there was a new market buy -> log it
  # {price, size, utc timestamp nano seconds}
  def handle_cast(
        {:new_sell, {price, size, timestamp}},
        market
      ) do
    # nano second time
    # use market id as kafka message key
    unix_ts_ns = DateTime.to_unix(timestamp, :nanosecond)
    market_id_str = Integer.to_string(market.market_id)

    # make json string message content
    {:ok, json_str} =
      Jason.encode(%{
        "side" => "sell",
        "price" => price,
        "size" => size,
        "unix_ts_ns" => unix_ts_ns
      })

    # send to message queue topic
    :ok =
      Kaffe.Producer.produce_sync(
        "level4.timesale",
        market_id_str,
        json_str
      )

    {:noreply, market}
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

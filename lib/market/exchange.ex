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

    # make and/or get the exchange record
    exchange =
      case Storage.Model.Exchange
           |> Storage.Repo.get_by(name: init_arg[:market].exchange_name) do
        nil ->
          {:ok, struct} =
            Storage.Repo.insert(%Storage.Model.Exchange{
              name: init_arg[:market].exchange_name
            })

          struct

        struct ->
          struct
      end

    # make and/or get the major symbol record
    major_symbol =
      case Storage.Model.Symbol
           |> Storage.Repo.get_by(symbol: init_arg[:market].major_symbol) do
        nil ->
          {:ok, struct} =
            Storage.Repo.insert(%Storage.Model.Symbol{
              symbol: init_arg[:market].major_symbol
            })

          struct

        struct ->
          struct
      end

    # make and/or get the quote symbol record
    quote_symbol =
      case Storage.Model.Symbol
           |> Storage.Repo.get_by(symbol: init_arg[:market].quote_symbol) do
        nil ->
          {:ok, struct} =
            Storage.Repo.insert(%Storage.Model.Symbol{
              symbol: init_arg[:market].quote_symbol
            })

          struct

        struct ->
          struct
      end

    # make and/or get the market record
    market =
      case Storage.Model.Market
           |> Storage.Repo.get_by(
             major_symbol_id: major_symbol.id,
             quote_symbol_id: quote_symbol.id,
             exchange_id: exchange.id,
             market_type: init_arg[:market].market_type
           ) do
        nil ->
          {:ok, struct} =
            Storage.Repo.insert(%Storage.Model.Market{
              major_symbol_id: major_symbol.id,
              quote_symbol_id: quote_symbol.id,
              exchange_id: exchange.id,
              market_type: init_arg[:market].market_type,
              level4_feed_enabled: true
            })

          struct

        struct ->
          struct
      end

    {:ok, market}
  end

  @doc """
  Terminate function for the GenServer. Handles tear-down of the storage medium.
  """
  @impl true
  def terminate(reason, market) do
    # handle termination
    # ...
  end

  @doc """
  GenServer cast functions for async API calls.
  """
  # :best_bid_change -> the best bid price changed -> log it
  @impl true
  def handle_cast({:best_bid_change, {new_price, _, timestamp}}, market) do
    Storage.Repo.insert(%Storage.Model.BestBidPrice{
      market_id: market.id,
      price: new_price,
      timestamp: timestamp
    })

    {:noreply, market}
  end

  # :best_ask_change -> the best ask price changed -> log it
  def handle_cast({:best_ask_change, {new_price, _, timestamp}}, market) do
    Storage.Repo.insert(%Storage.Model.BestAskPrice{
      market_id: market.id,
      price: new_price,
      timestamp: timestamp
    })

    {:noreply, market}
  end

  # :do_pairwise_cointegration_tests -> do pairwise cointergration tests against all
  # markets currently running, including myself -> save the results.
  def handle_cast(
        {:do_pairwise_cointegration_tests, {timeframe_in_seconds, {start_time, end_time}}},
        market
      ) do
    Task.async(fn ->
      IO.puts("#{inspect(market)} :do_pairwise_cointegration_tests")

      # do work
      # ...

      nil
    end)
  end

  # :make_time_sale_candle -> make OHLCV candle -> save it
  def handle_cast(
        {:make_time_sale_candle, {timeframe_in_seconds, {start_time, end_time}}},
        market
      ) do
    Task.async(fn ->
      IO.puts("#{inspect(market)} :make_time_sale_candle")

      # do work
      # ...

      nil
    end)
  end

  # :make_spread_candle -> make OHLC candles for bids and asks -> save them
  def handle_cast(
        {:make_spread_candles, {timeframe_in_seconds, {start_time, end_time}}},
        market
      ) do
    Task.async(fn ->
      IO.puts("#{inspect(market)} :make_spread_candles")

      # do work
      # ...

      nil
    end)
  end

  @doc """
  Async Market.Exchange API: a helper function that sends a :best_bid_change to
  the GenServer. Note: casts are asynchronous requests.
  """
  def best_bid_change(exchange, {new_price, new_size, timestamp}) do
    GenServer.cast(exchange, {:best_bid_change, {new_price, new_size, timestamp}})
  end

  @doc """
  Async Market.Exchange API: a helper function that sends a :best_ask_change to
  the GenServer. Note: casts are asynchronous requests.
  """
  def best_ask_change(exchange, {new_price, new_size, timestamp}) do
    GenServer.cast(exchange, {:best_ask_change, {new_price, new_size, timestamp}})
  end

  @doc """
  Async Market.Exchange API: instruct exchange to do cointergration tests over
  some timeframe.
  """
  def do_pairwise_cointergration_tests(
        exchange,
        {timeframe_in_seconds, {start_time, end_time}}
      ) do
    GenServer.cast(exchange, {
      :do_pairwise_cointergration_tests,
      {timeframe_in_seconds, {start_time, end_time}}
    })
  end

  @doc """
  Async Market.Exchange API: instruct exchange to make a OHLCV candle for some
  timeframe.
  """
  def make_buy_sell_candle(
        exchange,
        {timeframe_in_seconds, {start_time, end_time}}
      ) do
    GenServer.cast(exchange, {
      :make_buy_sell_candle,
      {timeframe_in_seconds, {start_time, end_time}}
    })
  end

  @doc """
  Async Market.Exchange API: instruct exchange to make a OHLC candles for best
  bid/ask price changes over some timeframe.
  """
  def make_spread_candle(
        exchange,
        {timeframe_in_seconds, {start_time, end_time}}
      ) do
    GenServer.cast(exchange, {
      :make_spread_candle,
      {timeframe_in_seconds, {start_time, end_time}}
    })
  end
end

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
    Logger.info(
      "#{Market.id(init_arg[:market])} " <>
        "starting mediator"
    )

    {:ok, {init_arg[:market], {{0, 0}, {0, 0}}}}
  end

  @doc """
  Synchronous API. Apply snapshot to orderbook.
  """
  @impl true
  def handle_call({:snapshot, {bids, asks}}, _, {market, best_prices}) do
    Market.Level2.OrderBook.apply_snapshot(
      {:via, Registry,
       {
         Market.Level2.OrderBook.Registry,
         Market.id(market)
       }},
      {bids, asks}
    )

    {:reply, :ok, {market, best_prices}}
  end

  def handle_call(
        {:delta, {:bid, price, liquidity}},
        _,
        {market, {{best_bid_price, best_bid_size}, best_ask}}
      ) do
    # apply the delta to the order book
    Market.Level2.OrderBook.apply_delta(
      {:via, Registry,
       {
         Market.Level2.OrderBook.Registry,
         Market.id(market)
       }},
      :bid,
      {price, liquidity}
    )

    # get the current best bid price
    case Market.Level2.OrderBook.best_bid(
           {:via, Registry,
            {
              Market.Level2.OrderBook.Registry,
              Market.id(market)
            }}
         ) do
      # check if the best bid price changed
      {new_best_bid_price, new_best_bid_size} ->
        if best_bid_price != new_best_bid_price do
          timestamp = DateTime.utc_now()

          Market.Exchange.best_bid_change(
            {:via, Registry,
             {
               Market.Exchange.Registry,
               Market.id(market)
             }},
            {new_best_bid_price, new_best_bid_size, timestamp}
          )

          {
            :reply,
            :ok,
            {
              market,
              {{new_best_bid_price, new_best_bid_size}, best_ask}
            }
          }
        else
          {
            :reply,
            :ok,
            {
              market,
              {{best_bid_price, best_bid_size}, best_ask}
            }
          }
        end

      # the bids side is empty
      :side_empty ->
        {
          :reply,
          :ok,
          {
            market,
            {{best_bid_price, best_bid_size}, best_ask}
          }
        }
    end
  end

  def handle_call(
        {:delta, {:ask, price, liquidity}},
        _,
        {market, {best_bid, {best_ask_price, best_ask_size}}}
      ) do
    # apply the delta to the order book
    Market.Level2.OrderBook.apply_delta(
      {:via, Registry,
       {
         Market.Level2.OrderBook.Registry,
         Market.id(market)
       }},
      :ask,
      {price, liquidity}
    )

    # get the current best ask price
    case Market.Level2.OrderBook.best_ask(
           {:via, Registry,
            {
              Market.Level2.OrderBook.Registry,
              Market.id(market)
            }}
         ) do
      # check if the best ask price changed
      {new_best_ask_price, new_best_ask_size} ->
        if best_ask_price != new_best_ask_price do
          timestamp = DateTime.utc_now()

          Market.Exchange.best_ask_change(
            {:via, Registry,
             {
               Market.Exchange.Registry,
               Market.id(market)
             }},
            {new_best_ask_price, new_best_ask_size, timestamp}
          )

          {
            :reply,
            :ok,
            {
              market,
              {best_bid, {new_best_ask_price, new_best_ask_size}}
            }
          }
        else
          {
            :reply,
            :ok,
            {
              market,
              {best_bid, {best_ask_price, best_ask_size}}
            }
          }
        end

      # the asks side is empty
      :side_empty ->
        {
          :reply,
          :ok,
          {
            market,
            {best_bid, {best_ask_price, best_ask_size}}
          }
        }
    end
  end

  # ...
  def handle_call(
        {:buy, {price, size, timestamp}},
        _,
        {market, {best_bid, best_ask}}
      ) do
    Market.Exchange.new_buy(
      {:via, Registry,
       {
         Market.Exchange.Registry,
         Market.id(market)
       }},
      {price, size, timestamp}
    )

    {
      :reply,
      :ok,
      {
        {market, {best_bid, best_ask}}
      }
    }
  end

  # ...
  def handle_call(
        {:sell, {price, size, timestamp}},
        _,
        {market, {best_bid, best_ask}}
      ) do
    Market.Exchange.new_sell(
      {:via, Registry,
       {
         Market.Exchange.Registry,
         Market.id(market)
       }},
      {price, size, timestamp}
    )

    {
      :reply,
      :ok,
      {
        {market, {best_bid, best_ask}}
      }
    }
  end

  @doc """
  Handle GenServer termination.
  """
  @impl true
  def terminate(reason, state) do
    IO.puts(inspect(reason))
    IO.puts(inspect(state))

    #    Logger.info(
    #      "#{Market.id(market)} shutdown " <>
    #        "mediator: #{inspect(reason)}"
    #    )
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

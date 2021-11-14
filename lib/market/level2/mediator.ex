require Logger

defmodule Market.Level2.Mediator do
  @moduledoc """
  ...
  """

  use GenServer

  @doc """
  ...
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
  ...
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
  ...
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

    {:reply, %{}, {market, best_prices}}
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
          Market.Exchange.best_bid_change(
            {:via, Registry,
             {
               Market.Exchange.Registry,
               Market.id(market)
             }},
            {new_best_bid_price, new_best_bid_size}
          )

          {
            :reply,
            %{},
            {
              market,
              {{new_best_bid_price, new_best_bid_size}, best_ask}
            }
          }
        else
          {
            :reply,
            %{},
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
          %{},
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
          Market.Exchange.best_ask_change(
            {:via, Registry,
             {
               Market.Exchange.Registry,
               Market.id(market)
             }},
            {new_best_ask_price, new_best_ask_size}
          )

          {
            :reply,
            %{},
            {
              market,
              {best_bid, {new_best_ask_price, new_best_ask_size}}
            }
          }
        else
          {
            :reply,
            %{},
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
          %{},
          {
            market,
            {best_bid, {best_ask_price, best_ask_size}}
          }
        }
    end
  end

  @doc """
  ...
  """
  @impl true
  def terminate(reason, {market, _}) do
    Logger.info(
      "#{Market.id(market)} shutdown " <>
        "mediator: #{reason}"
    )
  end

  @doc """
  ...
  """
  def snapshot(mediator, bids, asks) do
    GenServer.call(mediator, {:snapshot, {bids, asks}})
  end

  @doc """
  ...
  """
  def deltas(mediator, deltas) do
    for delta <- deltas do
      GenServer.call(mediator, {:delta, delta})
    end
  end
end

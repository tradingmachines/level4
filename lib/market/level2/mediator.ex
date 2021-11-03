defmodule Market.Level2.Mediator do
  @moduledoc """
  ...
  """

  use GenServer

  @doc """
  ...
  """
  @impl true
  def init(args) do
    {:ok, orderbook} = Market.Level2.Orderbook.start_link()
    {:ok, orderbook}
  end

  @doc """
  ...
  """
  @impl true
  def handle_call({:snapshot, {bids, asks}}, from, orderbook) do
    Market.Level2.Orderbook.apply_snapshot(orderbook, {bids, asks})
  end

  @doc """
  ...
  """
  @impl true
  def handle_call({:delta, {:bid, price, liquidity}}, from, orderbook) do
    Market.Level2.Orderbook.apply_delta(orderbook, :bid, {price, liquidity})
  end

  @doc """
  ...
  """
  @impl true
  def handle_call({:delta, {:ask, price, liquidity}}, from, orderbook) do
    Market.Level2.Orderbook.apply_delta(orderbook, :ask, {price, liquidity})
  end

  @doc """
  ...
  """
  @impl true
  def terminate(reason, orderbook) do
    # handle termination
    # ...
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
  def delta(mediator, {:bid, price, liquidity}) do
    GenServer.call(mediator, {:delta, {:bid, price, liquidity}})
  end

  @doc """
  ...
  """
  def delta(mediator, {:ask, price, liquidity}) do
    GenServer.call(mediator, {:delta, {:ask, price, liquidity}})
  end
end

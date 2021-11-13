defmodule Market.Level2.Mediator do
  @moduledoc """
  ...
  """

  use GenServer

  @doc """
  ...
  """
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @doc """
  ...
  """
  @impl true
  def init(init_arg) do
    IO.puts("\t\tstarting mediator for #{Level4.Market.id(init_arg[:market])}")
    {:ok, %{}}
  end

  @doc """
  ...
  """
  @impl true
  def handle_call({:snapshot, {bids, asks}}, from, orderbook) do
    Market.Level2.Orderbook.apply_snapshot(orderbook, {bids, asks})
  end

  def handle_call({:bid_delta, {price, liquidity}}, from, orderbook) do
    Market.Level2.Orderbook.apply_delta(orderbook, :bid, {price, liquidity})
  end

  def handle_call({:ask_delta, {price, liquidity}}, from, orderbook) do
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
  def delta(mediator, :bid, {price, liquidity}) do
    GenServer.call(mediator, {:bid_delta, {price, liquidity}})
  end

  def delta(mediator, :ask, {price, liquidity}) do
    GenServer.call(mediator, {:ask_delta, {price, liquidity}})
  end
end

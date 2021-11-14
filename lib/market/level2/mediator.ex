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

    {:ok, init_arg[:market]}
  end

  @doc """
  ...
  """
  @impl true
  def handle_call({:snapshot, {bids, asks}}, _, market) do
    Market.Level2.OrderBook.apply_snapshot(
      {:via, Registry,
       {
         Market.Level2.OrderBook.Registry,
         Market.id(market)
       }},
      {bids, asks}
    )

    {:reply, %{}, market}
  end

  def handle_call({:delta, {side, price, liquidity}}, _, market) do
    Market.Level2.OrderBook.apply_delta(
      {:via, Registry,
       {
         Market.Level2.OrderBook.Registry,
         Market.id(market)
       }},
      side,
      {price, liquidity}
    )

    {:reply, %{}, market}
  end

  @doc """
  ...
  """
  @impl true
  def terminate(reason, market) do
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

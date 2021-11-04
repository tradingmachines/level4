defmodule Market.Exchange do
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
    IO.puts("\tstarting exchange for #{init_arg[:market_id]}")
    {:ok, %{}}
  end

  @doc """
  ...
  """
  @impl true
  def handle_cast({:best_bid_change, new_price}, state) do
    IO.puts("best bid change #{new_price}")
  end

  def handle_cast({:best_ask_change, new_price}, state) do
    IO.puts("best ask change #{new_price}")
  end

  @doc """
  ...
  """
  @impl true
  def terminate(reason, state) do
    # handle termination
    # ...
  end

  @doc """
  ...
  """
  def best_bid_change(exchange, new_price) do
    GenServer.cast(exchange, {:best_bid_change, new_price})
  end

  @doc """
  ...
  """
  def best_ask_change(exchange, new_price) do
    GenServer.cast(exchange, {:best_ask_change, new_price})
  end
end

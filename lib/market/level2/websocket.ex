defmodule Market.Level2.WebSocket do
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
    IO.puts("\t\tstarting websocket for #{init_arg[:market_id]}")
    {:ok, %{}}
  end

  @doc """
  ...
  """
  @impl true
  def handle_call(request, from, state) do
  end

  @doc """
  ...
  """
  @impl true
  def handle_cast(request, state) do
  end

  @doc """
  ...
  """
  @impl true
  def terminate(reason, state) do
  end
end

require Logger

defmodule Market.Level2.Supervisor do
  @moduledoc """
  Supervises level2 data feed - which consists of three components:
  1. mediator
  2. orderbook
  3. websocket

  They are started in that order and the rest_for_one strategy is used.
  I.e. if websocket crashes then just restart websocket. If orderbook
  crashes then restart orderbook and websocket. If mediator crashes then
  restart mediator, orderbook, and websocket.
  """

  use Supervisor

  @doc """
  Start and link to parent process.
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg)
  end

  @doc """
  Init function for the supervisor. Starts three children.
  """
  @impl true
  def init(init_arg) do
    Logger.info("#{init_arg[:market]}: starting level2 supervisor")

    Supervisor.init(
      [
        %{
          id: Market.Level2.Mediator,
          start: {Market.Level2.Mediator, :start_link, [init_arg]},
          type: :worker
        },
        %{
          id: Market.Level2.Orderbook,
          start: {Market.Level2.OrderBook, :start_link, [init_arg]},
          type: :worker
        },
        %{
          id: Market.Level2.WebSocket,
          start: {Market.Level2.WebSocket, :start_link, [init_arg]},
          type: :worker,
          max_restarts: 1,
          max_seconds: 2
        }
      ],
      strategy: :rest_for_one
    )
  end
end

require Logger

defmodule Market.Level2.Supervisor do
  @moduledoc """
  ...
  """

  use Supervisor

  @doc """
  ...
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg)
  end

  @doc """
  ...
  """
  @impl true
  def init(init_arg) do
    Logger.info(
      "#{Market.id(init_arg[:market])} " <>
        "starting level2 supervisor"
    )

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

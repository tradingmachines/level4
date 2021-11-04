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
    IO.puts("\tstarting level2 supervisor for #{init_arg[:market_id]}")

    Supervisor.init(
      [
        %{
          id: Market.Level2.Mediator,
          start: {Market.Level2.Mediator, :start_link, [init_arg]},
          type: :worker
        },
        %{
          id: Market.Level2.Orderbook,
          start: {Market.Level2.Orderbook, :start_link, [init_arg]},
          type: :worker
        },
        %{
          id: Market.Level2.Websocket,
          start: {Market.Level2.WebSocket, :start_link, [init_arg]},
          type: :worker
        }
      ],
      strategy: :rest_for_one
    )
  end
end

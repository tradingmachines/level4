defmodule Market.Level2.Supervisor do
  @moduledoc """
  ...
  """

  use Supervisor

  @doc """
  ...
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  ...
  """
  @impl true
  def init(:ok) do
    Supervisor.init(
      [
        Market.Level2.Mediator,
        Market.Level2.Orderbook,
        Market.Level2.Websocket
      ],
      strategy: :rest_for_one
    )
  end
end

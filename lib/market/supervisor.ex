defmodule Market.Supervisor do
  @moduledoc """
  ...
  """

  use Supervisor

  # ...
  defp process_name(init_arg) do
    {:via, Registry, {Market.Supervisor.Registry, init_arg[:market_id]}}
  end

  @doc """
  ...
  """
  def start_link(a, init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: process_name(init_arg))
  end

  @doc """
  ...
  """
  @impl true
  def init(init_arg) do
    IO.puts("starting market supervisor for #{init_arg[:market_id]}")

    Supervisor.init(
      [
        %{
          id: Market.Exchange,
          start: {Market.Exchange, :start_link, [init_arg]},
          type: :worker
        },
        %{
          id: Market.Level2.Supervisor,
          start: {Market.Level2.Supervisor, :start_link, [init_arg]},
          type: :supervisor
        }
      ],
      strategy: :one_for_all
    )
  end
end

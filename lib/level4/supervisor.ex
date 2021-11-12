defmodule Level4.DynamicSupervisor do
  @moduledoc """
  Spanws and destroys market sub-trees using Market.Supervisor, which
  is responsible for building and maintaining processes in its tree.
  """

  use DynamicSupervisor

  @doc """
  Starts and links a new DynamicSupervisor named Level4.DynamicSupervisor.
  Three is only ever one of these processes in the application's supervision
  tree, so it is possible to refer to it using this name. This is why you do
  not need to pass a PID to the `start_market` helper function.
  """
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Initialises the dynamic supervisor and passes `init_args` to down the
  process tree. The strategy is always `one_for_one` for dynamic
  supervisors.
  """
  @impl true
  def init(init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [init_arg]
    )
  end

  @doc """
  Spawns and adds a new market to the supervision tree. The
  Market.Supervisor is responsible for building this tree according to the
  market information provided.
  """
  @spec start_market(Level4.Market) :: pid()
  def start_market(market) do
    DynamicSupervisor.start_child(
      __MODULE__,
      %{
        id: Market.Supervisor,
        start: {Market.Supervisor, :start_link, [[market: market]]},
        type: :supervisor
      }
    )
  end
end

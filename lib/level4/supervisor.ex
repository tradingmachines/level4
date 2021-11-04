defmodule Level4.DynamicSupervisor do
  @moduledoc """
  ...
  """

  use DynamicSupervisor

  @doc """
  ...
  """
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  ...
  """
  @impl true
  def init(init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [init_arg]
    )
  end

  @doc """
  ...
  """
  def start_market(exchange_name, major_symbol, quote_symbol) do
    market_id = "#{exchange_name}:#{major_symbol}-#{quote_symbol}"

    # exchange-specific configuration stuff can go here
    # ...

    DynamicSupervisor.start_child(
      __MODULE__,
      %{
        id: Market.Supervisor,
        start: {Market.Supervisor, :start_link, [[market_id: market_id]]},
        type: :supervisor
      }
    )
  end
end

require Logger

defmodule Level4 do
  @moduledoc """
  Elixir application. Spawns a root supervisor that supervises
  multiple registries and one main dynamic supervisor.
  """

  use Application

  @doc """
  Starts the root supervisor, four registries, and the main
  dynamic supervisor.

  The registries maintain:
  1. market -> market supervisor process Ids;
  2. market -> exchange Ids;
  3. market -> level2 mediator process Ids;
  4. market -> level2 orderbook Ids.

  The dynamic supervisor dynamically creates and destroys market
  supervision trees as-and-when they are needed.
  """
  @impl true
  def start(_type, _args) do
    Logger.info("starting level4")

    Supervisor.start_link(
      [
        {
          Registry,
          keys: :unique, name: Market.Supervisor.Registry
        },
        {
          Registry,
          keys: :unique, name: Market.Exchange.Registry
        },
        {
          Registry,
          keys: :unique, name: Market.Level2.Mediator.Registry
        },
        {
          Registry,
          keys: :unique, name: Market.Level2.OrderBook.Registry
        },
        MarketSupervisor
      ],
      strategy: :one_for_one
    )
  end
end

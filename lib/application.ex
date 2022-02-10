require Logger

defmodule Level4 do
  @moduledoc """
  Elixir application. Spawns a root supervisor that monitors
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
        {
          Plug.Cowboy,
          scheme: :http, plug: Level4.Server, options: [port: 8080]
        },
        Storage.Repo,
        Markets
      ],
      strategy: :one_for_one
    )
  end
end

defmodule Markets do
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
  ...
  """
  def start(id) do
    {:ok, result} = Query.Markets.by_id(id)

    # get scheme builder from config
    # ...

    {translation_scheme, url, path, port, ping?} = scheme_builder.()

    market = %Market{
      translation_scheme: translation_scheme,
      exchange_name: result.exchange.name,
      base_symbol: result.base_symbol.symbol,
      quote_symbol: result.quote_symbol.symbol,
      market_type: result.market_type,
      ws_url: url,
      ws_path: path,
      ws_port: port,
      ping?: ping?
    }

    cond do
      result.level4_feed_enabled == true ->
        {:input_error, "market already started"}

      result.level4_feed_enabled == false ->
        {:ok, new_result} = Query.Markets.update(result, level4_feed_enabled: true)

        DynamicSupervisor.start_child(
          __MODULE__,
          %{
            id: Market.Supervisor,
            start: {Market.Supervisor, :start_link, [[market: market]]},
            type: :supervisor
          }
        )

        {:ok, new_result}
    end
  end

  @doc """
  ...
  """
  def stop(id) do
    {:ok, result} = Query.Markets.by_id(id)

    cond do
      result.level4_feed_enabled == false ->
        {:input_error, "market already stopped"}

      result.level4_feed_enabled == true ->
        {:ok, new_result} = Query.Markets.update(result, level4_feed_enabled: false)

        # ...

        #    DynamicSupervisor.start_child(
        #      __MODULE__,
        #      %{
        #        id: Market.Supervisor,
        #        start: {Market.Supervisor, :start_link, [[market: market]]},
        #        type: :supervisor
        #      }
        #    )

        {:ok, new_result}
    end
  end
end

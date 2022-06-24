require Logger

defmodule Level4 do
  @moduledoc """
  Mix application. Spawns a root supervisor that monitors
  1) multiple registries and 2) one main dynamic supervisor.

  Henceforth "market" refers to:
  1. a supervision tree for an exchange genserver and level2 data
     feed supervision tree;
  2. a pair of symbols, an exchange, and a market "type" (e.g. PERP).
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

  The supervisor dynamically creates and destroys market
  supervision trees as-and-when they are needed.
  """
  @impl true
  def start(_type, _args) do
    {:ok, http_server} = Application.fetch_env(:level4, :http_server)

    Logger.info("starting level4")

    Supervisor.start_link(
      [
        # map market id -> market supervisor pid
        {Registry, keys: :unique, name: Market.Supervisor.Registry},

        # map market id -> exchange genserver pid
        {Registry, keys: :unique, name: Market.Exchange.Registry},

        # map market id -> mediator genserver pid
        {Registry, keys: :unique, name: Market.Level2.Mediator.Registry},

        # map market id -> orderbook supervisor pid
        {Registry, keys: :unique, name: Market.Level2.OrderBook.Registry},

        # plug http server
        {Plug.Cowboy,
         scheme: :http,
         plug: Level4.Server,
         options: [ip: http_server[:iface], port: http_server[:port]]},

        # ecto repo
        Storage.Repo,

        # dynamic supervisor for market supervisors
        MarketController
      ],
      # if any the root supervisor's children crash
      # then restart everything because that shouldn't have happened
      strategy: :one_for_all
    )
  end
end

defmodule Level4.Release do
  @moduledoc """
  Contains helper functions for handling ecto schema migrations in
  production releases.
  See https://hexdocs.pm/ecto_sql/Ecto.Migrator.html

  note: bin/ can be omitted when added to path:
  - bin/level4 eval "Level4.Release.migrate"
  - bin/level4 start
  """

  @app :level4

  # return the list of ecto repos
  defp repos do
    :ok = Application.load(@app)
    {:ok, repos} = Application.fetch_env(@app, :ecto_repos)
    repos
  end

  @doc """
  Run all of the migrations for each repo.
  """
  def migrate do
    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(
          repo,
          &Ecto.Migrator.run(&1, :up, all: true)
        )
    end
  end
end

defmodule MarketController do
  @moduledoc """
  Spanws and destroys market sub-trees using Market.Supervisor, which
  is responsible for building and maintaining processes in its tree.
  """

  use DynamicSupervisor

  # turn market model into internal representation
  defp to_internal_representation(market) do
    # get exchange map from config/config.exs
    {:ok, exchanges} = Application.fetch_env(:level4, :exchanges)

    # walk the map exchange name -> market type -> market parameters
    %{
      translation_scheme: translation_scheme,
      ws_host: ws_host,
      path: path,
      port: port,
      ping?: ping?
    } = exchanges[market.exchange.name][market.market_type]

    # make market struct using above parameters
    # this is the "internal representation" used throughout level4
    %Market{
      translation_scheme: translation_scheme,
      exchange_name: market.exchange.name,
      base_symbol: market.base_symbol.symbol,
      quote_symbol: market.quote_symbol.symbol,
      market_type: market.market_type,
      market_id: market.id,
      ws_host: ws_host,
      ws_path: path,
      ws_port: port,
      ping?: ping?
    }
  end

  @doc """
  Starts and links a new DynamicSupervisor named Level4.DynamicSupervisor.
  Three is only ever one of these processes in the application's supervision
  tree, so it is possible to refer to it using this name. This is why you do
  not need to pass a PID to the `start_market` helper function.
  """
  def start_link(init_arg) do
    DynamicSupervisor.start_link(
      __MODULE__,
      init_arg,
      name: __MODULE__
    )
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
  Starts a new market data feed for a given market id. Does not create
  the market if it doesn't already exist, obviously, so you must have
  already created the symbol, exchange, and market records in the ecto
  repo beforehand. See the queries package for more info on how to do
  this. A websocket connection will be established for each data feed.
  """
  def start(id) do
    # get the market from database
    # and convert into internal representation
    {:ok, result} = Query.Markets.by_id(id)
    market = to_internal_representation(result)

    cond do
      # according to the repo the market is already running
      result.level4_feed_enabled == true ->
        {:error, "market already in started state"}

      # market is not running
      result.level4_feed_enabled == false ->
        # update market's state in the repo
        {:ok, new_result} = Query.Markets.set_enabled(result, true)

        # create a new child in the dynamic supervisor
        DynamicSupervisor.start_child(
          __MODULE__,
          %{
            id: Market.Supervisor,
            start: {Market.Supervisor, :start_link, [[market: market]]},
            type: :supervisor,
            restart: :temporary
          }
        )

        Logger.info("#{market}: started market")
        {:ok, new_result}
    end
  end

  @doc """
  Stops a market data feed by its repo market id. Also assumes the
  market exists. Refer to queries package. The market is not removed
  from the repo database. The data feed is simply switched off. This
  is a clean way of disconnecting from a specific websocket feed.
  """
  def stop(id) do
    # get the market from database
    # and convert into internal representation
    {:ok, result} = Query.Markets.by_id(id)
    market = to_internal_representation(result)

    cond do
      # according to the repo the market is already stopped
      result.level4_feed_enabled == false ->
        {:error, "market already stopped"}

      # market is running
      result.level4_feed_enabled == true ->
        # update market's state in the repo
        {:ok, new_result} = Query.Markets.set_enabled(result, false)

        # consult Market.Supervisor.Registry to find child's pid
        children =
          Registry.lookup(
            Market.Supervisor.Registry,
            Market.tag(market)
          )

        cond do
          # child does not exist
          # it must have crashed
          length(children) == 0 ->
            Logger.info("#{market}: data feed does not exist")

          # terminate the child
          # this will trigger shutdown process in the subtree
          length(children) == 1 ->
            [{pid, _}] = children
            :ok = DynamicSupervisor.terminate_child(__MODULE__, pid)
            Logger.info("#{market}: successfully stopped market")
        end

        {:ok, new_result}
    end
  end
end

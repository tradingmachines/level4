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
        Markets
      ],
      # if any the root supervisor's children crash
      # then restart everything because that shouldn't have happened
      strategy: :one_for_all
    )
  end
end

defmodule Markets do
  @moduledoc """
  Spanws and destroys market sub-trees using Market.Supervisor, which
  is responsible for building and maintaining processes in its tree.
  """

  use DynamicSupervisor

  # turn market model into internal representation
  defp to_internal_representation(result) do
    # get exchange map from config/config.exs
    {:ok, exchanges} = Application.fetch_env(:level4, :exchanges)

    # walk the map exchange name -> market type -> market lambda
    # get parameters from market lambda
    market_types = exchanges[result.exchange.name]
    market = market_types[result.market_type]
    {translation_scheme, url, path, port, ping?} = market.()

    # make market struct using above parameters
    # this is the "internal representation" used throughout level4
    %Market{
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
  end

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
  Starts a new market data feed for a given market id. Does not create
  the market if it doesn't already exist, obviously, so you must have
  already created the symbol, exchange, and market records in the ecto
  repo beforehand. See the queries package for more info on how to do
  this.

  start(:all) will start market data feeds for all inactive markets.
  A websocket connection will be established for each data feed. The
  order in which data feeds are started depends on the order of the
  results returned by the Query.Markets.are_disabled query. By
  default there is a five second delay between starts. A delay lambda
  function can be provided by calling start(:all, fn -> <ms to wait> end).
  """
  def start(:all) do
    start(:all, fn -> 5000 end)
  end

  def start(:all, delay) do
    {:ok, stopped} = Query.Markets.are_disabled()

    results =
      for %{id: id} <- stopped do
        {:ok, result} = start(id)
        Process.sleep(delay.())
        result
      end

    {:ok, results}
  end

  def start(id) do
    # get the market from database
    # and convert into internal representation
    {:ok, result} = Query.Markets.by_id(id)
    market = to_internal_representation(result)

    cond do
      # according to the repo the market is already running
      #      result.level4_feed_enabled == true ->
      #        {:error, "market already in started state"}

      # market is not running
      result.level4_feed_enabled == true ->
        # update market's state in the repo
        {:ok, new_result} =
          Query.Markets.update(result,
            level4_feed_enabled: true
          )

        # create a new child in the dynamic supervisor
        DynamicSupervisor.start_child(
          __MODULE__,
          %{
            id: Market.Supervisor,
            start: {Market.Supervisor, :start_link, [[market: market]]},
            type: :supervisor
          }
        )

        Logger.info("started market #{market}")
        {:ok, new_result}
    end
  end

  @doc """
  Stops a market data feed by its repo market id. Also assumes the
  market exists. Refer to queries package. The market is not removed
  from the repo database. The data feed is simply switched off. This
  is a clean way of disconnecting from a specific websocket feed.

  stop(:all) will disconnect from all active websoket connections
  and shut down live market data feeds. The order in which markets
  are stopped depends on the order of the results returned by the
  Query.Markets.are_enabled query. By default there is no delay
  between shutdowns. A delay lambda function can be provided by
  calling stop(:all, fn -> <ms to wait> end).
  """
  def stop(:all) do
    stop(:all, fn -> 0 end)
  end

  def stop(:all, delay) do
    {:ok, started} = Query.Markets.are_enabled()

    results =
      for %{id: id} <- started do
        {:ok, result} = stop(id)
        Process.sleep(delay.())
        result
      end

    {:ok, results}
  end

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
        {:ok, new_result} =
          Query.Markets.update(result,
            level4_feed_enabled: false
          )

        # consult Market.Supervisor.Registry to find child's pid
        [{pid, _}] =
          Registry.lookup(
            Market.Supervisor.Registry,
            Market.id(market)
          )

        # terminate the child
        # this will trigger shutdown process down the subtree
        :ok = DynamicSupervisor.terminate_child(__MODULE__, pid)

        Logger.info("stopped market #{market}")
        {:ok, new_result}
    end
  end
end

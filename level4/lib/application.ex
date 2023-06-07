defmodule TranslationScheme do
  @moduledoc """
  Translation scheme defines the behaviours that an exchange translation
  scheme must implement in order to be comparable with the level2 data feed.
  """

  # still need to define stuff here
  # ... :-)
end

defmodule Level4 do
  @moduledoc """
  Level4 node: runs a libcluster supervisor and participates in a cluster.
  The Market.DynamicSupervisor maintains market data feed processes.
  """

  use Application

  @impl true
  def start(_type, _args) do
    # max concurrent data feeds per node
    # libcluster topologies
    # node hostname
    # RPC server port
    title_text = Application.get_env(:level4, :title)
    max_data_feeds = Application.get_env(:level4, :max_data_feeds)
    topologies = Application.get_env(:level4, :topologies)
    hostname = Application.get_env(:level4, :hostname)
    rpc_port = Application.get_env(:level4, :rpc_port)

    # print system info
    IO.puts(title_text)
    IO.puts("> instance hostname: #{hostname}")
    IO.puts("> max concurrent data feeds: #{max_data_feeds}")
    IO.puts("> gRPC server listening on port: #{rpc_port}")

    # turn on distributed mode / assign a hostname
    Node.start(hostname, :shortnames, 15000)

    # start the root supervisor
    Supervisor.start_link(
      [
        # libcluster supervisor
        {Cluster.Supervisor, [topologies, [name: Level4.ClusterSupervisor]]},

        # RPC server
        {GRPC.Server.Supervisor, {Level4.RPC.Endpoint, rpc_port}},

        # registry mapping market id -> market data feed supervisor
        {Registry, keys: :unique, name: Market.Registry},

        # registry mapping market id -> data feed process
        {Registry, keys: :unique, name: Market.DataFeed.Registry},

        # registry mapping market id -> level2 mediator process
        {Registry, keys: :unique, name: Market.Level2.Registry},

        # registry mapping market id -> orderbook process
        {Registry, keys: :unique, name: Market.OrderBook.Registry},

        # dynamic supervisor for market data feeds
        {Market.DynamicSupervisor, max_data_feeds: max_data_feeds}
      ],
      strategy: :one_for_one,
      name: Level4.Supervisor
    )
  end

  @doc """
  Helper function for calling a module function with args on a given node.
  The calling node will wait for the result indefinitely - there is no timeout.
  """
  def on_node(node, module, fun, args) do
    # who to send the result to
    me = self()

    # spawn the function
    _pid =
      Node.spawn_link(
        node,
        fn -> send(me, apply(module, fun, args)) end
      )

    # wait for result
    receive do
      result -> result
    end
  end

  @doc """
  Returns true if all nodes / a given node in the cluster is at maximum capacity.
  """
  def at_max_capacity?(:cluster),
    do:
      list_nodes(:all)
      |> Enum.map(fn x -> at_max_capacity?(x) end)
      |> Enum.all?()

  def at_max_capacity?(node) do
    # get the maximum and actual running data feeds for node
    max = Application.get_env(:level4, :max_data_feeds)
    count = list_active_markets(node) |> Enum.count()

    # do check
    count >= max
  end

  @doc """
  Returns true if there is a data feed associated with the given market id
  running somewhere in the cluster. Else returns false.
  """
  def market_id_taken?(id),
    do:
      list_active_markets(:all)
      |> Enum.map(fn x -> x.id end)
      |> Enum.member?(id)

  @doc """
  Returns true if there is an entry in config for the given exchange name
  and market type. Else returns false.
  """
  def have_config?(exchange_name, market_type) do
    # get exchange exchanges from the configuration
    exchanges = Application.get_env(:level4, :exchanges)

    cond do
      # the exchange name is invalid
      not Map.has_key?(exchanges, exchange_name) ->
        {false, false}

      # exchange name is valid but market type is invalid
      not Map.has_key?(exchanges[exchange_name], market_type) ->
        {true, false}

      # both exchange name and market type are valid
      true ->
        {true, true}
    end
  end

  @doc """
  Returns a node's max capacity.
  """
  def get_max_capacity(node),
    do:
      on_node(
        node,
        Market.DynamicSupervisor,
        :get_max_capacity,
        []
      )

  @doc """
  List active market data feeds for node / on all nodes.
  """
  def list_active_markets(:all),
    do:
      list_nodes(:all)
      |> Enum.map(fn x -> list_active_markets(x) end)
      |> List.flatten()

  def list_active_markets(node),
    do:
      on_node(
        node,
        Market.DynamicSupervisor,
        :list_active_markets,
        [:all]
      )

  @doc """
  List all connected nodes in the cluster, plus the current node.
  """
  def list_nodes(:all), do: Node.list(:this) ++ Node.list(:connected)

  @doc """
  Randomly pick a node from the set of online nodes, ignoring those that are at
  maximum capacity already.
  """
  def pick_available_node(:randomly),
    do:
      list_nodes(:all)
      |> Enum.filter(fn x -> not at_max_capacity?(x) end)
      |> Enum.random()

  @doc """
  Find and return the node a market data feed is running on.
  """
  def which_node(market) do
    list_nodes(:all)
    |> Enum.find(fn node ->
      on_node(node, Market.DynamicSupervisor, :have_market?, [market])
    end)
  end

  @doc """
  Get and return the config / translation scheme for the given exchange
  and market type.
  """
  def get_config(exchange_name, market_type) do
    # get exchange exchanges from the configuration
    exchanges = Application.get_env(:level4, :exchanges)

    # exchange name -> market type
    exchanges[exchange_name][market_type]
  end

  @doc """
  Spawn a new data feed process on the given node.
  """
  def start_data_feed(node, market, config),
    do:
      on_node(
        node,
        Market.DynamicSupervisor,
        :start_data_feed,
        [market, config, node]
      )

  @doc """
  Stop a data feed process on the given node.
  """
  def stop_data_feed(node, market),
    do:
      on_node(
        node,
        Market.DynamicSupervisor,
        :stop_data_feed,
        [market]
      )

  @doc """
  Start a new market data feed.
  """
  def start_market(market) do
    # check if the cluster is at max capacity
    is_full = at_max_capacity?(:cluster)

    # make sure it is not already running
    already_running = market_id_taken?(market.id)

    # make sure exchange name and market type are valid
    {valid_exchange, valid_market_type} =
      have_config?(
        market.exchange_name,
        market.type
      )

    cond do
      # cannot start more data feed processes anywhere in the cluster
      is_full == true ->
        {:error, "cluster is at maximum capacity"}

      # the market id is already in use / feed is active
      already_running == true ->
        {:error, "market id already associated with data feed"}

      # bad exchange name
      valid_exchange == false ->
        {:error, "no translation scheme for exchange"}

      # base market type
      valid_market_type == false ->
        {:error, "no translation scheme for market type"}

      # start the feed
      true ->
        # pick a node to start the feed on
        # and get the relevant config / translation scheme
        node = pick_available_node(:randomly)
        config = get_config(market.exchange_name, market.type)

        # add a new child to the target node's dynamic supervisor
        :ok = start_data_feed(node, market, config)

        {:ok, node}
    end
  end

  @doc """
  Stop an active market data feed.
  """
  def stop_market(market) do
    # make sure it is currently running
    already_running = market_id_taken?(market.id)

    cond do
      # no data feed associated with the given market id
      already_running == false ->
        {:error, "no data feed associated with market id"}

      # stop the data feed process
      true ->
        # get the node the feed is running on
        node = which_node(market)

        # remove the child process from the node's dynamic supervisor
        :ok = stop_data_feed(node, market)

        {:ok, node}
    end
  end
end

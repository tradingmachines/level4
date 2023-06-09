import Config

defmodule Level4.Runtime do
  # helper functions: wrappers around System.get_env that load an
  # environment variable and do some pre-processing
  def get_env(:atom, name, default) do
    System.get_env(name, default) |> String.to_atom()
  end

  def get_env(:integer, name, default) do
    {x, ""} = System.get_env(name, default) |> Integer.parse()
    x
  end

  def get_env(:hosts, name, default) do
    System.get_env(name, default)
    |> String.split(",")
    |> Enum.flat_map(fn addr ->
      [ip, port] = String.split(addr, ":")
      Keyword.put([], String.to_atom(ip), String.to_integer(port))
    end)
  end
end

################################################################################
#
# level4 config
# > node hostname
# > RPC server port
# > maximum concurrent data feed processes per node
# > libcluster topology
#
config :level4,
  hostname:
    Level4.Runtime.get_env(
      :atom,
      "HOSTNAME",
      "node1"
    ),
  rpc_port:
    Level4.Runtime.get_env(
      :integer,
      "RPC_PORT",
      "50051"
    ),
  max_data_feeds:
    Level4.Runtime.get_env(
      :integer,
      "MAX_DATA_FEEDS",
      "25"
    ),
  topologies: [
    level4: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45892,
        multicast_ttl: 1
      ]
    ]
  ]

################################################################################
#
# kafka producer config
#
config :kaffe,
  producer: [
    endpoints:
      Level4.Runtime.get_env(
        :hosts,
        "KAFKA_ENDPOINTS",
        "127.0.0.1:9092"
      ),
    topics: [
      "level4.spread",
      "level4.timesale",
      "level4.status"
    ],
    partition_strategy: fn _topic, _partitions_count, key, _value ->
      {market_id, ""} = Integer.parse(key)
      market_id
    end
  ]

################################################################################
#
# schema registry config
#

config :avrora,
  registry_url: "http://127.0.0.1:8081",
  schemas_path: "./priv/schemas",
  registry_schemas_autoreg: false,
  convert_null_values: false,
  names_cache_ttl: :timer.minutes(5)

################################################################################

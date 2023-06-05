import Config

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
  |> Enum.map(fn addr ->
    [ip_address, port] = String.split(addr, ":")
    %{ip_address => String.to_integer(port)}
  end)
end

# define the node hostname
config :level4,
  hostname: get_env(:atom, "HOSTNAME", "node1")

# define the maximum concurrent data feed processes per node
config :level4,
  max_data_feeds: get_env(:integer, "MAX_DATA_FEEDS", "25")

# define the RPC server port
config :level4,
  rpc_port: get_env(:integer, "RPC_PORT", "50051")

# define the kafka producer
config :kaffe,
  producer: [
    endpoints: get_env(:hosts, "KAFKA_ENDPOINTS", ["127.0.0.1:9093"]),
    topics: [
      "level4.spread",
      "level4.timesale"
    ],
    partition_strategy: fn _topic, _partitions_count, key, _value ->
      # subtract 1 because topics start at zero
      {market_id, ""} = Integer.parse(key)
      market_id - 1
    end
  ]

# define the libcluster topologies
config :level4,
  topologies: [
    level4: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45892,
        multicast_ttl: 1
      ]
    ]
  ]

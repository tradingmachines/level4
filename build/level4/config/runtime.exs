import Config

# define the node hostname
config :level4,
  hostname: System.get_env("HOSTNAME", "node1") |> String.to_atom()

# define the maximum concurrent data feed processes per node
config :level4,
  max_data_feeds: 25

# define the RPC server port
config :level4,
  rpc_port: 50051

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

# define the kafka producer
config :kaffe,
  producer: [
    endpoints: [
      kafka: 9093
    ],
    topics: [
      "level4.spread",
      "level4.timesale"
    ],
    partition_strategy: fn _topic, _partitions_count, key, _value ->
      {market_id, ""} = Integer.parse(key)

      # subtract 1 because topics start at zero
      market_id - 1
    end
  ]

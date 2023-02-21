import Config

# define the node hostname
config :level4,
  hostname: System.get_env("HOSTNAME", "node1") |> String.to_atom()

# define the maximum concurrent data feed processes per node
config :level4,
  max_data_feeds: 25

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
      "127.0.0.1": 9092
    ],
    topics: [
      "level4.spread",
      "level4.timesale"
    ],
    partition_strategy: :random
  ]

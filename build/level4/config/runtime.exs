import Config

# ecto repo backend (postgres)
config :level4, Storage.Repo,
  database: "level4",
  username: "level4",
  password: "level4",
  hostname: "database",
  port: 5432,
  pool_size: 10

# kafka producer
config :kaffe,
  producer: [
    endpoints: [
      kafka1: 9092,
      kafka2: 9092,
      kafka3: 9092,
      kafka4: 9092
    ],
    topics: [
      "level4.spread",
      "level4.timesale"
    ],
    partition_strategy: :random
  ]

# http server host and port
config :level4,
  http_server: %{
    iface: {0, 0, 0, 0},
    port: 5000
  }

import Config

# ecto storage repo
config :level4, ecto_repos: [Storage.Repo]

# ecto repo backend: postgres + timescaledb
config :level4, Storage.Repo,
  database: "level4",
  username: "level4",
  password: "level4",
  hostname: "127.0.0.1",
  port: 5432,
  pool_size: 25

# exchange translation scheme map
config :level4,
  translation_scheme: %{
    "binance" => %{
      "spot" => fn something -> nil end,
      "futures" => fn something -> nil end
    },
    "bitfinex" => %{
      "spot" => fn something -> nil end,
      "futures" => fn something -> nil end
    },
    "bitmex" => %{
      "spot" => fn something -> nil end,
      "futures" => fn something -> nil end
    },
    "bitstamp" => %{
      "spot" => fn something -> nil end,
      "futures" => fn something -> nil end
    },
    "bittrex" => %{
      "spot" => fn something -> nil end,
      "futures" => fn something -> nil end
    },
    "bybit" => %{
      "spot" => fn something -> nil end,
      "futures" => fn something -> nil end
    },
    "coinbase" => %{
      "spot" => fn something -> nil end,
      "futures" => fn something -> nil end
    },
    "ftx" => %{
      "spot" => fn something -> nil end,
      "futures" => fn something -> nil end
    },
    "gemini" => %{
      "spot" => fn something -> nil end,
      "futures" => fn something -> nil end
    },
    "hitbtc" => %{
      "spot" => fn something -> nil end,
      "futures" => fn something -> nil end
    },
    "kraken" => %{
      "spot" => fn something -> nil end,
      "futures" => fn something -> nil end
    },
    "poloniex" => %{
      "spot" => fn something -> nil end,
      "futures" => fn something -> nil end
    }
  }

import Config

# ecto repo backend (postgres)
config :level4, Storage.Repo,
  database: "level4",
  username: "level4",
  password: "level4",
  hostname: "database",
  port: 5432,
  pool_size: 10

# http server host and port
config :level4,
  http_server: %{
    iface: {0, 0, 0, 0},
    port: 8080
    # add stream handlers?
    # ...
  }

# data sump host and port
config :level4,
  data_sumps: %{
    bidasksump: %{
      host: 'bidasksump',
      port: 5000
    },
    timesalesump: %{
      host: 'timesalesump',
      port: 5000
    }
  }

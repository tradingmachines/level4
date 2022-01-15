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

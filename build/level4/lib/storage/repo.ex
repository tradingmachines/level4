defmodule Storage.Repo do
  use Ecto.Repo,
    otp_app: :level4,
    adapter: Ecto.Adapters.Postgres
end

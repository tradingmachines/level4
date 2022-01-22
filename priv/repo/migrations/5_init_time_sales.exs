defmodule Storage.Repo.Migrations.CreateTimeSales do
  use Ecto.Migration

  def change do
    create table(:buys, primary_key: false) do
      add(:market_id, references(:markets), null: false)
      add(:price, :float, null: false)
      add(:size, :float, null: false)
      add(:timestamp, :utc_datetime_usec, null: false)
    end

    create table(:sells, primary_key: false) do
      add(:market_id, references(:markets), null: false)
      add(:price, :float, null: false)
      add(:size, :float, null: false)
      add(:timestamp, :utc_datetime_usec, null: false)
    end

    execute("SELECT create_hypertable('buys', 'timestamp')")
    execute("SELECT create_hypertable('sells', 'timestamp')")
  end
end

defmodule Storage.Repo.Migrations.CreateBestPrices do
  use Ecto.Migration

  def change do
    create table(:best_bid_prices, primary_key: false) do
      add(:market_id, references(:markets), null: false)
      add(:price, :float, null: false)
      add(:size, :float, null: false)
      add(:timestamp, :utc_datetime_usec, null: false)
    end

    create table(:best_ask_prices, primary_key: false) do
      add(:market_id, references(:markets), null: false)
      add(:price, :float, null: false)
      add(:size, :float, null: false)
      add(:timestamp, :utc_datetime_usec, null: false)
    end
  end
end

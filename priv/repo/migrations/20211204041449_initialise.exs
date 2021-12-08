defmodule Storage.Repo.Migrations.Initialise do
  use Ecto.Migration

  def change do
    create table(:symbols) do
      add(:symbol, :string, null: false)
    end

    create table(:exchanges) do
      add(:name, :string, null: false)
    end

    create table(:markets) do
      add(:major_symbol_id, references(:symbols), null: false)
      add(:quote_symbol_id, references(:symbols), null: false)
      add(:exchange_id, references(:exchanges), null: false)
      add(:market_type, :string, null: false)
    end

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

    create(unique_index(:symbols, [:symbol]))
    create(unique_index(:exchanges, [:name]))

    create(
      unique_index(
        :markets,
        [:major_symbol_id, :quote_symbol_id, :exchange_id, :market_type]
      )
    )
  end
end

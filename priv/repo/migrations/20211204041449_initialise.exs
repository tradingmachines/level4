defmodule Storage.Repo.Migrations.Initialise do
  use Ecto.Migration

  def change do
    create table(:symbols) do
      add(:symbol, :string)
    end

    create table(:exchanges) do
      add(:name, :string)
    end

    create table(:markets) do
      add(:major_symbol_id, references(:symbols))
      add(:quote_symbol_id, references(:symbols))
      add(:exchange_id, references(:exchanges))
      add(:market_type, :string)
    end

    create table(:spread_changes) do
      add(:market_id, references(:markets))
      add(:best_bid_price, :float)
      add(:best_ask_price, :float)
      add(:timestamp, :utc_datetime_usec)
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
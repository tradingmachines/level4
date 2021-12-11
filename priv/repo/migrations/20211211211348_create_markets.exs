defmodule Storage.Repo.Migrations.CreateMarkets do
  use Ecto.Migration

  def change do
    create table(:markets) do
      add(:major_symbol_id, references(:symbols), null: false)
      add(:quote_symbol_id, references(:symbols), null: false)
      add(:exchange_id, references(:exchanges), null: false)
      add(:market_type, :string, null: false)
    end

    create(
      unique_index(
        :markets,
        [:major_symbol_id, :quote_symbol_id, :exchange_id, :market_type]
      )
    )
  end
end

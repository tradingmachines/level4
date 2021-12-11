defmodule Storage.Repo.Migrations.CreateSymbols do
  use Ecto.Migration

  def change do
    create table(:symbols) do
      add(:symbol, :string, null: false)
    end

    create(unique_index(:symbols, [:symbol]))
  end
end

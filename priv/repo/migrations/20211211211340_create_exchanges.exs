defmodule Storage.Repo.Migrations.CreateExchanges do
  use Ecto.Migration

  def change do
    create table(:exchanges) do
      add(:name, :string, null: false)
    end

    create(unique_index(:exchanges, [:name]))
  end
end

defmodule Storage.Repo.Migrations.CreatePairwiseCointegrationTests do
  use Ecto.Migration

  def change do
    create table(:pairwise_cointegration_tests, primary_key: false) do
      add(:market_a_id, references(:markets), null: false)
      add(:market_b_id, references(:markets), null: false)
      add(:rss, :float, null: false)
      add(:coff_alpha, :float, null: false)
      add(:coff_beta, :float, null: false)
      add(:timeframe_in_seconds, :integer, null: false)
      add(:start_timestamp, :utc_datetime_usec, null: false)
    end
  end
end

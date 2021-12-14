defmodule Storage.Repo.Migrations.CreateCandles do
  use Ecto.Migration

  def change do
    create table(:time_sale_candles, primary_key: false) do
      add(:market_id, references(:markets), null: false)
      add(:open, :float, null: false)
      add(:high, :float, null: false)
      add(:low, :float, null: false)
      add(:close, :float, null: false)
      add(:volume, :float, null: false)
      add(:timeframe_in_seconds, :integer, null: false)
      add(:start_timestamp, :utc_datetime_usec, null: false)
    end

    create table(:bid_spread_candles, primary_key: false) do
      add(:market_id, references(:markets), null: false)
      add(:open, :float, null: false)
      add(:high, :float, null: false)
      add(:low, :float, null: false)
      add(:close, :float, null: false)
      add(:timeframe_in_seconds, :integer, null: false)
      add(:start_timestamp, :utc_datetime_usec, null: false)
    end

    create table(:ask_spread_candles, primary_key: false) do
      add(:market_id, references(:markets), null: false)
      add(:open, :float, null: false)
      add(:high, :float, null: false)
      add(:low, :float, null: false)
      add(:close, :float, null: false)
      add(:timeframe_in_seconds, :integer, null: false)
      add(:start_timestamp, :utc_datetime_usec, null: false)
    end

    execute("SELECT create_hypertable('time_sale_candles', 'start_timestamp')")
    execute("SELECT create_hypertable('bid_spread_candles', 'start_timestamp')")
    execute("SELECT create_hypertable('ask_spread_candles', 'start_timestamp')")
  end
end

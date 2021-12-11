defmodule Storage.Model.Candle do
  use Ecto.Schema

  @primary_key false
  schema "candles" do
    belongs_to(:market, Storage.Model.Market)
    field(:open, :float)
    field(:high, :float)
    field(:low, :float)
    field(:close, :float)
    field(:volume, :float)
    field(:timeframe_in_seconds, :integer)
    field(:start_timestamp, :utc_datetime_usec)
    field(:end_timestamp, :utc_datetime_usec, virtual: true)
  end
end

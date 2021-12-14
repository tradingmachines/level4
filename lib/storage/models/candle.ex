defmodule Storage.Model.TimeSaleCandle do
  use Ecto.Schema

  @primary_key false
  schema "time_sale_candles" do
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

defmodule Storage.Model.BidSpreadCandle do
  use Ecto.Schema

  @primary_key false
  schema "bid_spread_candles" do
    belongs_to(:market, Storage.Model.Market)
    field(:open, :float)
    field(:high, :float)
    field(:low, :float)
    field(:close, :float)
    field(:timeframe_in_seconds, :integer)
    field(:start_timestamp, :utc_datetime_usec)
    field(:end_timestamp, :utc_datetime_usec, virtual: true)
  end
end

defmodule Storage.Model.AskSpreadCandle do
  use Ecto.Schema

  @primary_key false
  schema "ask_spread_candles" do
    belongs_to(:market, Storage.Model.Market)
    field(:open, :float)
    field(:high, :float)
    field(:low, :float)
    field(:close, :float)
    field(:timeframe_in_seconds, :integer)
    field(:start_timestamp, :utc_datetime_usec)
    field(:end_timestamp, :utc_datetime_usec, virtual: true)
  end
end

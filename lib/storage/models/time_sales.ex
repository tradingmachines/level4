defmodule Storage.Model.Buy do
  use Ecto.Schema

  @primary_key false
  schema "buys" do
    belongs_to(:market, Storage.Model.Market)
    field(:price, :float)
    field(:size, :float)
    field(:timestamp, :utc_datetime_usec)
  end
end

defmodule Storage.Model.Sell do
  use Ecto.Schema

  @primary_key false
  schema "sells" do
    belongs_to(:market, Storage.Model.Market)
    field(:price, :float)
    field(:size, :float)
    field(:timestamp, :utc_datetime_usec)
  end
end

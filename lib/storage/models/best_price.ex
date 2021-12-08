defmodule Storage.Model.BestBidPrice do
  use Ecto.Schema

  @primary_key false
  schema "best_bid_prices" do
    belongs_to(:market, Storage.Model.Market)
    field(:price, :float)
    field(:size, :float)
    field(:mid_market_price, :float, virtual: true)
    field(:timestamp, :utc_datetime_usec)
  end
end

defmodule Storage.Model.BestAskPrice do
  use Ecto.Schema

  @primary_key false
  schema "best_ask_prices" do
    belongs_to(:market, Storage.Model.Market)
    field(:price, :float)
    field(:size, :float)
    field(:mid_market_price, :float, virtual: true)
    field(:timestamp, :utc_datetime_usec)
  end
end

defmodule Storage.Model.SpreadChange do
  use Ecto.Schema

  schema "spread_change" do
    belongs_to(:market, Storage.Model.Market)
    field(:best_bid_price, :float)
    field(:best_ask_price, :float)
    field(:mid_market_price, :float, virtual: true)
    field(:timestamp, :utc_datetime_usec)
  end
end

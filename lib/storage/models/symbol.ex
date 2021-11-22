defmodule Storage.Model.Symbol do
  use Ecto.Schema

  schema "currency_symbol" do
    has_many(:markets, Storage.Model.Market)
    field(:symbol, :string)
  end
end

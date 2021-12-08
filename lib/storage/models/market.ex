defmodule Storage.Model.Market do
  use Ecto.Schema

  schema "markets" do
    belongs_to(:major_symbol, Storage.Model.Symbol)
    belongs_to(:quote_symbol, Storage.Model.Symbol)
    belongs_to(:exchange, Storage.Model.Exchange)
    field(:market_type, :string)
    field(:name, :string, virtual: true)
  end
end

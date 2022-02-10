defmodule Storage.Model.Market do
  use Ecto.Schema

  @derive {Jason.Encoder,
           only: [
             :id,
             :exchange,
             :base_symbol,
             :quote_symbol,
             :market_type,
             :level4_feed_enabled
           ]}
  schema "markets" do
    belongs_to(:base_symbol, Storage.Model.Symbol)
    belongs_to(:quote_symbol, Storage.Model.Symbol)
    belongs_to(:exchange, Storage.Model.Exchange)
    field(:market_type, :string)
    field(:level4_feed_enabled, :boolean)
  end
end

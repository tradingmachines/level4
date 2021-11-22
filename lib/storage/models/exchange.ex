defmodule Storage.Model.Exchange do
  use Ecto.Schema

  schema "exchange" do
    has_many(:markets, Storage.Model.Market)
    field(:name, :string)
  end
end

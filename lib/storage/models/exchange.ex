defmodule Storage.Model.Exchange do
  use Ecto.Schema

  schema "exchanges" do
    has_many(:markets, Storage.Model.Market)
    field(:name, :string)
  end
end

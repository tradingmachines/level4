defmodule Storage.Model.Exchange do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :name]}
  schema "exchanges" do
    has_many(:markets, Storage.Model.Market)
    field(:name, :string)
  end
end

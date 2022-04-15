defmodule Storage.Model.Symbol do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :symbol]}
  schema "symbols" do
    field(:symbol, :string)
  end
end

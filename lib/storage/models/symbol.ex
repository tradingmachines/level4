defmodule Storage.Model.Symbol do
  use Ecto.Schema

  schema "symbols" do
    field(:symbol, :string)
  end
end

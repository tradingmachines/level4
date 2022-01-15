defmodule Query.Symbols do
  def all do
    Storage.Model.Symbol |> Storage.Repo.all()
  end

  def by_id(id) do
    Storage.Model.Symbol |> Storage.Repo.get(id)
  end

  def by_name(name) do
    Storage.Model.Symbol |> Storage.Repo.get_by(symbol: name)
  end
end

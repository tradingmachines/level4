defmodule Query.Symbols do
  def all do
    result = Storage.Model.Symbol |> Storage.Repo.all()
    {:ok, result}
  end

  def by_id(id) do
    result = Storage.Model.Symbol |> Storage.Repo.get(id)
    {:ok, result}
  end

  def by_name(name) do
    result = Storage.Model.Symbol |> Storage.Repo.get_by(symbol: name)
    {:ok, result}
  end
end

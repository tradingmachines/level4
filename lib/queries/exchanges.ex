defmodule Query.Exchanges do
  def all(preload \\ []) do
    Storage.Model.Exchange
    |> Storage.Repo.all()
    |> Storage.Repo.preload(preload)
  end

  def by_id(id, preload \\ []) do
    Storage.Model.Exchange
    |> Storage.Repo.get(id)
    |> Storage.Repo.preload(preload)
  end

  def by_name(name, preload \\ []) do
    Storage.Model.Exchange
    |> Storage.Repo.get_by(name: name)
    |> Storage.Repo.preload(preload)
  end
end

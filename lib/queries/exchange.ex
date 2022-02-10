defmodule Query.Exchanges do
  @moduledoc """
  ...
  """

  @preload []

  @doc """
  ...
  """
  def new(name) do
    {:ok, result} =
      Storage.Repo.insert(%Storage.Model.Exchange{
        name: name
      })

    {:ok, result}
  end

  @doc """
  ...
  """
  def all() do
    result =
      Storage.Model.Exchange
      |> Storage.Repo.all()
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end

  @doc """
  ...
  """
  def by_id(id) do
    result =
      Storage.Model.Exchange
      |> Storage.Repo.get(id)
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end

  @doc """
  ...
  """
  def by_name(name) do
    result =
      Storage.Model.Exchange
      |> Storage.Repo.get_by(name: name)
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end
end

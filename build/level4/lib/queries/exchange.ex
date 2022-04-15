defmodule Query.Exchanges do
  @moduledoc """
  ...
  """

  @doc """
  ...
  """
  def new(name) do
    # ...
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
    # ...
    result =
      Storage.Model.Exchange
      |> Storage.Repo.all()

    {:ok, result}
  end

  @doc """
  ...
  """
  def by_id(id) do
    # ...
    result =
      Storage.Model.Exchange
      |> Storage.Repo.get(id)

    {:ok, result}
  end

  @doc """
  ...
  """
  def by_name(name) do
    # ...
    result =
      Storage.Model.Exchange
      |> Storage.Repo.get_by(name: name)

    {:ok, result}
  end
end

defmodule Query.Symbols do
  @moduledoc """
   ...
  """

  @doc """
  ...
  """
  def new(symbol) do
    # ...
    {:ok, result} =
      Storage.Repo.insert(%Storage.Model.Symbol{
        symbol: symbol
      })

    {:ok, result}
  end

  @doc """
  ...
  """
  def all do
    # ...
    result =
      Storage.Model.Symbol
      |> Storage.Repo.all()

    {:ok, result}
  end

  @doc """
  ...
  """
  def by_id(id) do
    # ...
    result =
      Storage.Model.Symbol
      |> Storage.Repo.get(id)

    {:ok, result}
  end

  @doc """
  ...
  """
  def by_name(name) do
    # ...
    result =
      Storage.Model.Symbol
      |> Storage.Repo.get_by(symbol: name)

    {:ok, result}
  end
end

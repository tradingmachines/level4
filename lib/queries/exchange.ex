defmodule Query.Exchanges do
  @moduledoc """
  Query.Exchanges contains ecto queries for exchange records. There is no need
  for complex buffering and pagination here because the total number of exchanges
  is always relatively small.
  """

  @doc """
  Get all exchanges and optionally preload associated records.
  """
  def all(preload \\ []) do
    Storage.Model.Exchange
    |> Storage.Repo.all()
    |> Storage.Repo.preload(preload)
  end

  @doc """
  Get a single exchange by its id and optionally preload associated records.
  """
  def by_id(id, preload \\ []) do
    Storage.Model.Exchange
    |> Storage.Repo.get(id)
    |> Storage.Repo.preload(preload)
  end

  @doc """
  Get a single exchange by its name and optionally preload associated records.
  """
  def by_name(name, preload \\ []) do
    Storage.Model.Exchange
    |> Storage.Repo.get_by(name: name)
    |> Storage.Repo.preload(preload)
  end
end

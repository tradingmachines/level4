require Ecto.Query

defmodule Query.Markets do
  @moduledoc """
  Query.Markets contains ecto queries for market records. There is no need
  for complex buffering and pagination here because the total number of exchanges
  is always relatively small.
  """

  @doc """
  Get all markets and optionally preload associated records.
  """
  def all(preload \\ []) do
    Storage.Model.Market
    |> Storage.Repo.all()
    |> Storage.Repo.preload(preload)
  end

  @doc """
  Get a single market by its id and optionally preload associated records.
  """
  def by_id(id, preload \\ []) do
    Storage.Model.Market
    |> Storage.Repo.get(id)
    |> Storage.Repo.preload(preload)
  end

  @doc """
  Get all markets for a specific base symbol id. Optionally preload associated
  records.
  """
  def for_base_symbol_id(id, preload \\ []) do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.base_symbol_id == ^id
      )

    Storage.Repo.all(query)
    |> Storage.Repo.preload(preload)
  end

  @doc """
  Get all markets for a specific quote symbol id. Optionally preload associated
  records.
  """
  def for_quote_symbol_id(id, preload \\ []) do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.quote_symbol_id == ^id
      )

    Storage.Repo.all(query)
    |> Storage.Repo.preload(preload)
  end

  @doc """
  Get all markets for a specific exchange id. Optionally preload associated records.
  """
  def for_exchange_id(id, preload \\ []) do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.exchange_id == ^id
      )

    Storage.Repo.all(query)
    |> Storage.Repo.preload(preload)
  end

  @doc """
  Get all markets for a specific market type (e.g. spot, future). Optionally preload
  associated records.
  """
  def by_market_type(type, preload \\ []) do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.market_type == ^type
      )

    Storage.Repo.all(query)
    |> Storage.Repo.preload(preload)
  end
end

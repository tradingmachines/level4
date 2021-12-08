require Ecto.Query

defmodule Query.Markets do
  def all(preload \\ []) do
    Storage.Model.Market
    |> Storage.Repo.all()
    |> Storage.Repo.preload(preload)
  end

  def by_id(id, preload \\ []) do
    Storage.Model.Market
    |> Storage.Repo.get(id)
    |> Storage.Repo.preload(preload)
  end

  def for_major_symbol_id(id, preload \\ []) do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.major_symbol_id == ^id
      )

    Storage.Repo.all(query)
    |> Storage.Repo.preload(preload)
  end

  def for_quote_symbol_id(id, preload \\ []) do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.quote_symbol_id == ^id
      )

    Storage.Repo.all(query)
    |> Storage.Repo.preload(preload)
  end

  def for_exchange_id(id, preload \\ []) do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.exchange_id == ^id
      )

    Storage.Repo.all(query)
    |> Storage.Repo.preload(preload)
  end

  def by_market_type(type, preload \\ []) do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.market_type == ^type
      )

    Storage.Repo.all(query)
    |> Storage.Repo.preload(preload)
  end
end

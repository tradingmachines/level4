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
    Storage.Model.Market
    |> Storage.Repo.get_by(major_symbol_id: id)
    |> Storage.Repo.preload(preload)
  end

  def for_quote_symbol_id(id, preload \\ []) do
    Storage.Model.Market
    |> Storage.Repo.get_by(quote_symbol_id: id)
    |> Storage.Repo.preload(preload)
  end

  def for_exchange_id(id, preload \\ []) do
    Storage.Model.Market
    |> Storage.Repo.get_by(exchange_id: id)
    |> Storage.Repo.preload(preload)
  end

  def by_market_type(type, preload \\ []) do
    Storage.Model.Market
    |> Storage.Repo.get_by(market_type: type)
    |> Storage.Repo.preload(preload)
  end
end

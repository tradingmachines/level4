require Ecto.Query

defmodule Query.Markets do
  @moduledoc """
  ...
  """

  @preload [:base_symbol, :quote_symbol, :exchange]

  @doc """
  ...
  """
  def new(
        exchange_id,
        base_symbol_id,
        quote_symbol_id,
        market_type,
        level4_feed_enabled
      ) do
    {:ok, result} =
      Storage.Repo.insert(%Storage.Model.Market{
        exchange_id: exchange_id,
        base_symbol_id: base_symbol_id,
        quote_symbol_id: quote_symbol_id,
        market_type: market_type,
        level4_feed_enabled: level4_feed_enabled
      })

    {:ok, result}
  end

  @doc """
  ...
  """
  def update(market, fields) do
    new_market = Ecto.Changeset.change(market, fields)

    {:ok, result} = Storage.Repo.update(new_market)
    {:ok, result}
  end

  @doc """
  ...
  """
  def all() do
    result =
      Storage.Model.Market
      |> Storage.Repo.all()
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end

  @doc """
  ...
  """
  def by_id(id) do
    result =
      Storage.Model.Market
      |> Storage.Repo.get(id)
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end

  @doc """
  ...
  """
  def for_base_symbol_id(id) do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.base_symbol_id == ^id
      )

    result =
      Storage.Repo.all(query)
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end

  @doc """
  ...
  """
  def for_quote_symbol_id(id) do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.quote_symbol_id == ^id
      )

    result =
      Storage.Repo.all(query)
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end

  @doc """
  ...
  """
  def for_exchange_id(id) do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.exchange_id == ^id
      )

    result =
      Storage.Repo.all(query)
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end

  @doc """
  ...
  """
  def by_market_type(type) do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.market_type == ^type
      )

    result =
      Storage.Repo.all(query)
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end

  @doc """
  ...
  """
  def are_enabled() do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.level4_feed_enabled == true
      )

    result =
      Storage.Repo.all(query)
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end

  @doc """
  ...
  """
  def are_disabled() do
    query =
      Ecto.Query.from(market in Storage.Model.Market,
        where: market.level4_feed_enabled == false
      )

    result =
      Storage.Repo.all(query)
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end
end

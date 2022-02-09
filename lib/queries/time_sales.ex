require Ecto.Query

defmodule Query.TimeSale.Buys do
  @moduledoc """
  Query.TimeSale.Buys contains ecto queries for buy trades (take from ask side)
  that executed on a particular market.
  """

  @doc """
  ...
  """
  def for_market_id(market_id, start_time, end_time, preload \\ []) do
    query =
      Ecto.Query.from(buy in Storage.Model.Buy,
        where:
          buy.market_id == ^market_id and
            buy.timestamp >= ^start_time and
            buy.timestamp < ^end_time,
        order_by: [asc: buy.timestamp]
      )

    result =
      Storage.Repo.all(query)
      |> Storage.Repo.preload(preload)

    {:ok, result}
  end
end

defmodule Query.TimeSale.Sells do
  @moduledoc """
  Query.TimeSale.Buys contains ecto queries for sell trades (take from bid side)
  that executed on a particular market.
  """

  @doc """
  ...
  """
  def for_market_id(market_id, start_time, end_time, preload \\ []) do
    query =
      Ecto.Query.from(sell in Storage.Model.Sell,
        where:
          sell.market_id == ^market_id and
            sell.timestamp >= ^start_time and
            sell.timestamp < ^end_time,
        order_by: [asc: sell.timestamp]
      )

    result =
      Storage.Repo.all(query)
      |> Storage.Repo.preload(preload)

    {:ok, result}
  end
end

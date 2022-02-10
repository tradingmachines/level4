require Ecto.Query

defmodule Query.BestAsks do
  @moduledoc """
  ...
  """

  @preload []

  @doc """
  ...
  """
  def for_market_id(market_id, start_time, end_time) do
    query =
      Ecto.Query.from(ask in Storage.Model.BestAskPrice,
        where:
          ask.market_id == ^market_id and
            ask.timestamp >= ^start_time and
            ask.timestamp < ^end_time,
        order_by: [asc: ask.timestamp]
      )

    result =
      Storage.Repo.all(query)
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end
end

defmodule Query.BestBids do
  @moduledoc """
  ...
  """

  @preload []

  @doc """
  ...
  """
  def for_market_id(market_id, start_time, end_time) do
    query =
      Ecto.Query.from(bid in Storage.Model.BestBidPrice,
        where:
          bid.market_id == ^market_id and
            bid.timestamp >= ^start_time and
            bid.timestamp < ^end_time,
        order_by: [asc: bid.timestamp]
      )

    result =
      Storage.Repo.all(query)
      |> Storage.Repo.preload(@preload)

    {:ok, result}
  end
end

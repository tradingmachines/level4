require Ecto.Query

defmodule Query.BestBids do
  @moduledoc """
  Query.BestBids contains ecto queries for best bid price changes.
  """

  @doc """
  Return all best bid price changes between a specific timeframe for a
  single market id. Optionally preload associated records.
  """
  def for_market_id(market_id, start_time, end_time, preload \\ []) do
    query =
      Ecto.Query.from(bid in Storage.Model.BestBidPrice,
        where:
          bid.market_id == ^market_id and
            bid.timestamp >= ^start_time and
            bid.timestamp < ^end_time,
        order_by: [asc: bid.timestamp]
      )

    Storage.Repo.all(query)
    |> Storage.Repo.preload(preload)
  end
end

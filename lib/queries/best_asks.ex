require Ecto.Query

defmodule Query.BestAsks do
  @moduledoc """
  Query.BestAsks contains ecto queries for best ask price changes.
  """

  @doc """
  Return all best ask price changes between a specific timeframe for a
  single market id. Optionally preload associated records.
  """
  def for_market_id(market_id, start_time, end_time, preload \\ []) do
    query =
      Ecto.Query.from(ask in Storage.Model.BestAskPrice,
        where:
          ask.market_id == ^market_id and
            ask.timestamp >= ^start_time and
            ask.timestamp < ^end_time,
        order_by: [asc: ask.timestamp]
      )

    Storage.Repo.all(query)
    |> Storage.Repo.preload(preload)
  end
end

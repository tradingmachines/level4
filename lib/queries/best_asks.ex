require Ecto.Query

defmodule Query.BestAsks do
  def for_market_id(market_id, start_time, end_time) do
    query =
      Ecto.Query.from(ask in Storage.Model.BestAskPrice,
        where:
          ask.market_id == ^market_id and
            ask.timestamp >= ^start_time and
            ask.timestamp < ^end_time,
        order_by: [asc: ask.timestamp]
      )

    Storage.Repo.all(query)
  end
end

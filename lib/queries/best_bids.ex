require Ecto.Query

defmodule Query.BestBids do
  def for_market_id(market_id, start_time, end_time) do
    query =
      Ecto.Query.from(b in Storage.Model.BestBidPrice,
        where:
          b.market_id == ^market_id and
            b.timestamp >= ^start_time and
            b.timestamp < ^end_time,
        order_by: [asc: b.timestamp]
      )

    Storage.Repo.all(query)
  end
end

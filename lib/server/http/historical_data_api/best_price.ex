defmodule Level4.Server.HTTP.HistoricalMarketData.BestPrices.Bids do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/:market_id/:start_ts/:end_ts" do
    result = Query.BestBids.for_market_id(market_id, start_ts, end_ts)

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end
end

defmodule Level4.Server.HTTP.HistoricalMarketData.BestPrices.Asks do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/:market_id/:start_ts/:end_ts" do
    result = Query.BestAsks.for_market_id(market_id, start_ts, end_ts)

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end
end

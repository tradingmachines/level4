defmodule Level4.Server.HTTP.HistoricalMarketData.TimeSales.Buys do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/:market_id/:start_ts/:end_ts" do
    result = Query.TimeSale.Buys.for_market_id(market_id, start_ts, end_ts)

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end
end

defmodule Level4.Server.HTTP.HistoricalMarketData.TimeSales.Sells do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/:market_id/:start_ts/:end_ts" do
    result = Query.TimeSale.Sells.for_market_id(market_id, start_ts, end_ts)

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end
end

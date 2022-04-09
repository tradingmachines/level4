defmodule Level4.Server.HTTP.HistoricalMarketData do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  forward("/best-prices/bids", to: Level4.Server.HTTP.HistoricalMarketData.BestPrices.Bids)
  forward("/best-prices/asks", to: Level4.Server.HTTP.HistoricalMarketData.BestPrices.Asks)
  forward("/time-sales/buys", to: Level4.Server.HTTP.HistoricalMarketData.TimeSales.Buys)
  forward("/time-sales/sells", to: Level4.Server.HTTP.HistoricalMarketData.TimeSales.Sells)

  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "nothing here")
  end
end

defmodule Level4.Server.WebSocket.LiveMarketData do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "live market data")
  end
end

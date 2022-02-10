defmodule Level4.Server.HTTP.ControlPanel do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  forward("/symbols", to: Level4.Server.HTTP.ControlPanel.Symbols)
  forward("/exchanges", to: Level4.Server.HTTP.ControlPanel.Exchanges)
  forward("/markets", to: Level4.Server.HTTP.ControlPanel.Markets)

  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "nothing here")
  end
end

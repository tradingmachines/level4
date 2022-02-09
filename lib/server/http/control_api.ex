defmodule Level4.Server.HTTP.ControlPanel.Symbols do
  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  get "/" do
    %{:query_params => params} = Plug.Conn.fetch_query_params(conn)

    result =
      case params do
        %{"id" => id} -> Query.Symbols.by_id(id)
        %{"name" => name} -> Query.Symbols.by_name(name)
        _ -> Query.Symbols.all()
      end

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  post "/" do
  end

  patch "/" do
  end
end

defmodule Level4.Server.HTTP.ControlPanel.Exchanges do
  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  get "/" do
    %{:query_params => params} = Plug.Conn.fetch_query_params(conn)

    result =
      case params do
        %{"id" => id} -> Query.Exchanges.by_id(id)
        %{"name" => name} -> Query.Exchanges.by_name(name)
        _ -> Query.Exchanges.all()
      end

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  post "/" do
  end

  patch "/" do
  end
end

defmodule Level4.Server.HTTP.ControlPanel.Markets do
  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  get "/" do
    %{:query_params => params} = Plug.Conn.fetch_query_params(conn)

    result =
      case params do
        %{"id" => id} -> Query.Markets.by_id(id)
        %{"base_symbol_id" => id} -> Query.Markets.for_base_symbol_id(id)
        %{"quote_symbol_id" => id} -> Query.Markets.for_quote_symbol_id(id)
        %{"exchange_id" => id} -> Query.Markets.for_exchange_id(id)
        _ -> Query.Markets.all()
      end

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  post "/:market_id/start" do
    # ...

    status = 200
    json_str = ""

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  post "/:market_id/stop" do
    # ...

    status = 200
    json_str = ""

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  post "/" do
  end

  patch "/" do
  end
end

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

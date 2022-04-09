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
        %{"id" => id} ->
          Query.Symbols.by_id(id)

        %{"name" => name} ->
          Query.Symbols.by_name(name)

        _ ->
          Query.Symbols.all()
      end

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  post "/" do
    json = conn.body_params

    result =
      case json do
        %{"symbol" => symbol} -> Query.Symbols.new(symbol)
        _ -> {:input_error, "required fields => symbol::string"}
      end

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end
end

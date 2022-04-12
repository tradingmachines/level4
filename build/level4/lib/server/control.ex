defmodule Level4.Server.ControlPanel.Exchanges do
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
          Query.Exchanges.by_id(id)

        %{"name" => name} ->
          Query.Exchanges.by_name(name)

        _ ->
          Query.Exchanges.all()
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
        %{"name" => name} -> Query.Exchanges.new(name)
        _ -> {:input_error, "required fields => name::string"}
      end

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end
end

defmodule Level4.Server.ControlPanel.Markets do
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
          Query.Markets.by_id(id)

        %{"base_symbol_id" => id} ->
          Query.Markets.for_base_symbol_id(id)

        %{"quote_symbol_id" => id} ->
          Query.Markets.for_quote_symbol_id(id)

        %{"exchange_id" => id} ->
          Query.Markets.for_exchange_id(id)

        %{"market_type" => market_type} ->
          Query.Markets.by_market_type(market_type)

        %{"enabled" => "true"} ->
          Query.Markets.are_enabled()

        %{"enabled" => "false"} ->
          Query.Markets.are_disabled()

        _ ->
          Query.Markets.all()
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
        %{
          "exchange_id" => exchange_id,
          "base_symbol_id" => base_symbol_id,
          "quote_symbol_id" => quote_symbol_id,
          "market_type" => market_type,
          "level4_feed_enabled" => level4_feed_enabled
        } ->
          Query.Markets.new(
            exchange_id,
            base_symbol_id,
            quote_symbol_id,
            market_type,
            level4_feed_enabled
          )

        _ ->
          {:input_error,
           "required fields => exchange_id::int, base_symbol_id::int, " <>
             "quote_symbol_id::int, market_type::string, " <>
             "level4_feed_enabled:boolean"}
      end

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  post "/:market_id/start" do
    result = Markets.start(market_id)

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  post "/:market_id/stop" do
    result = Markets.stop(market_id)

    {status, json_str} = Level4.Server.response(result)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end
end

defmodule Level4.Server.ControlPanel.Symbols do
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

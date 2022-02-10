defmodule Level4.Server.HTTP.ControlPanel.Markets do
  use Plug.Router

  @preload [:base_symbol, :quote_symbol, :exchange]

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
          Query.Markets.by_id(id, @preload)

        %{"base_symbol_id" => id} ->
          Query.Markets.for_base_symbol_id(id, @preload)

        %{"quote_symbol_id" => id} ->
          Query.Markets.for_quote_symbol_id(id, @preload)

        %{"exchange_id" => id} ->
          Query.Markets.for_exchange_id(id, @preload)

        _ ->
          Query.Markets.all(@preload)
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
end

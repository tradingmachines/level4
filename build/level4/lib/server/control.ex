defmodule Level4.Server.ControlPanel.Exchanges do
  @moduledoc """
  Endpoints for exchanges resource.
  - get /control/exchanges
  - post /control/exchanges
  """

  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  # [GET /control/exchanges] :: get all / subset exchanges
  get "/" do
    # extract query params
    %{
      :query_params => params
    } = Plug.Conn.fetch_query_params(conn)

    # determine query using url query parameters
    result =
      case params do
        # get by id
        %{"id" => id} ->
          Query.Exchanges.by_id(id)

        # get by name
        %{"name" => name} ->
          Query.Exchanges.by_name(name)

        # no filter, get all
        _ ->
          Query.Exchanges.all()
      end

    # make the response message
    {status, json_str} = Level4.Server.response(result)

    # respond with json string
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  # [POST /control/exchanges] :: create new exchange
  post "/" do
    # determine query using body parameters
    result =
      case conn.body_params do
        # extract required values
        %{"name" => name} ->
          Query.Exchanges.new(name)

        # missing values
        _ ->
          {:input_error, "required fields => name::string"}
      end

    # make the respond message
    {status, json_str} = Level4.Server.response(result)

    # respond with json string
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end
end

defmodule Level4.Server.ControlPanel.Markets do
  @moduledoc """
  Endpoints for markets resource.
  - get /control/markets
  - post /control/markets
  - post /control/markets/<id>/start
  - post /control/markets/<id>/stop
  """

  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  # [GET /control/exchanges] :: get all / subset markets
  get "/" do
    # extract query params
    %{
      :query_params => params
    } = Plug.Conn.fetch_query_params(conn)

    # determine query using url query parameters
    result =
      case params do
        # get by id
        %{"id" => id} ->
          Query.Markets.by_id(id)

        # get all that have a specific base symbol id
        %{"base_symbol_id" => id} ->
          Query.Markets.for_base_symbol_id(id)

        # get all that have a specific quote symbol id
        %{"quote_symbol_id" => id} ->
          Query.Markets.for_quote_symbol_id(id)

        # get all that have a specific exchange id
        %{"exchange_id" => id} ->
          Query.Markets.for_exchange_id(id)

        # get all that have a specific market type
        %{"market_type" => market_type} ->
          Query.Markets.by_market_type(market_type)

        # get all enabled
        %{"enabled" => "true"} ->
          Query.Markets.are_enabled()

        # get all disabled
        %{"enabled" => "false"} ->
          Query.Markets.are_disabled()

        # no filter, get all
        _ ->
          Query.Markets.all()
      end

    # make the respond message
    {status, json_str} = Level4.Server.response(result)

    # respond with json string
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  # [POST /control/markets] :: create new market
  post "/" do
    # determine query using body parameters
    result =
      case conn.body_params do
        # extract required values
        %{
          "exchange_id" => exchange_id,
          "base_symbol_id" => base_symbol_id,
          "quote_symbol_id" => quote_symbol_id,
          "market_type" => market_type
        } ->
          Query.Markets.new(
            exchange_id,
            base_symbol_id,
            quote_symbol_id,
            market_type
          )

        # missing values
        _ ->
          {:input_error,
           "required fields => exchange_id::int, base_symbol_id::int, " <>
             "quote_symbol_id::int, market_type::string"}
      end

    # make the respond message
    {status, json_str} = Level4.Server.response(result)

    # respond with json string
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  # [POST /control/markets/<id>/start] :: start market data feed
  post "/:market_id/start" do
    # determine result using outcome of Markets.start
    result =
      case MarketController.start(market_id) do
        # started successfully
        {:ok, result} ->
          {:ok, result}

        # there was an error
        {:error, error_msg} ->
          {:internal_error, error_msg}
      end

    # make the respond message
    {status, json_str} = Level4.Server.response(result)

    # respond with json string
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  # [POST /control/markets/<id>/stop] :: stop market data feed
  post "/:market_id/stop" do
    # determine result using outcome of Markets.stop
    result =
      case MarketController.stop(market_id) do
        # started successfully
        {:ok, result} ->
          {:ok, result}

        # there was an error
        {:error, error_msg} ->
          {:internal_error, error_msg}
      end

    # make the respond message
    {status, json_str} = Level4.Server.response(result)

    # respond with json string
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end
end

defmodule Level4.Server.ControlPanel.Symbols do
  @moduledoc """
  Endpoints for symbols resource.
  - get /control/symbols
  - post /control/symbols
  """

  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  # [GET /control/exchanges] :: get all / subset symbols
  get "/" do
    # extract query params
    %{
      :query_params => params
    } = Plug.Conn.fetch_query_params(conn)

    # determine query using url query parameters
    result =
      case params do
        # get by id
        %{"id" => id} ->
          Query.Symbols.by_id(id)

        # get by name
        %{"name" => name} ->
          Query.Symbols.by_name(name)

        # no filter, get all
        _ ->
          Query.Symbols.all()
      end

    # make the respond message
    {status, json_str} = Level4.Server.response(result)

    # respond with json string
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end

  # [POST /control/symbols] :: create new symbol
  post "/" do
    # determine query using body parameters
    result =
      case conn.body_params do
        # extract required values
        %{"symbol" => symbol} ->
          Query.Symbols.new(symbol)

        # missing values
        _ ->
          {:input_error, "required fields => symbol::string"}
      end

    # make the respond message
    {status, json_str} = Level4.Server.response(result)

    # respond with json string
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json_str)
  end
end

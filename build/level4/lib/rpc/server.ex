defmodule Level4.RPC.Endpoint do
  @doc """
  ...
  """

  use GRPC.Endpoint

  intercept(GRPC.Logger.Server)
  run(Level4.RPC.Server)
end

defmodule Level4.RPC.Server do
  @doc """
  ...
  """

  use GRPC.Server, service: Level4.RPC.Server.Control.Service

  @spec start_market(
          Level4.StartMarketRequest.t(),
          GRPC.Server.Stream.t()
        ) :: Level4.StartMarketReply.t()
  def start_market(request, _stream) do
    # ...
    market = %Market{
      id: request.market.id,
      base_symbol: request.market.base_symbol,
      quote_symbol: request.market.quote_symbol,
      exchange_name: request.market.exchange_name,
      type: request.market.type
    }

    case Level4.start_market(market) do
      {:error, reason} ->
        # ...
        raise GRPC.RPCError, status: GRPC.Status.unknown(), message: reason

      {:ok, node} ->
        # ...
        Level4.RPC.Server.StartMarketReply.new(
          market:
            Level4.RPC.Server.Market.new(
              id: market.id,
              base_symbol: market.base_symbol,
              quote_symbol: market.quote_symbol,
              exchange_name: market.exchange_name,
              type: market.type
            ),
          node:
            Level4.RPC.Server.Node.new(
              name: "#{node}",
              active_market_count: 0
            )
        )
    end
  end

  @spec stop_market(
          Level4.StopMarketRequest.t(),
          GRPC.Server.Stream.t()
        ) :: Level4.StopMarketReply.t()
  def stop_market(request, _stream) do
    # ...
    market = %Market{
      id: request.market.id,
      base_symbol: request.market.base_symbol,
      quote_symbol: request.market.quote_symbol,
      exchange_name: request.market.exchange_name,
      type: request.market.type
    }

    case Level4.stop_market(market) do
      {:error, reason} ->
        # ...
        raise GRPC.RPCError, status: GRPC.Status.unknown(), message: reason

      {:ok, node} ->
        # ...
        Level4.RPC.Server.StopMarketReply.new(
          market:
            Level4.RPC.Server.Market.new(
              id: market.id,
              base_symbol: market.base_symbol,
              quote_symbol: market.quote_symbol,
              exchange_name: market.exchange_name,
              type: market.type
            ),
          node:
            Level4.RPC.Server.Node.new(
              name: "#{node}",
              active_market_count: 0
            )
        )
    end
  end

  @spec stop_market(
          Level4.ListNodesRequest.t(),
          GRPC.Server.Stream.t()
        ) :: Level4.ListNodesReply.t()
  def list_nodes(request, _stream) do
    Level4.RPC.Server.ListNodesReply.new(
      nodes:
        Level4.list_nodes(:all)
        |> Enum.map(fn x ->
          Level4.RPC.Server.Node.new(
            name: "#{x}",
            active_market_count: 0
          )
        end)
    )
  end

  @spec list_active_markets(
          ListMarketsRequest.t(),
          GRPC.Server.Stream.t()
        ) :: Level4.ListMarketsReply.t()
  def list_active_markets(request, _stream) do
    Level4.RPC.Server.ListMarketsReply.new(
      markets:
        Level4.list_active_markets(:all)
        |> Enum.map(fn x ->
          Level4.RPC.Server.Market.new(
            id: x.id,
            base_symbol: x.base_symbol,
            quote_symbol: x.quote_symbol,
            exchange_name: x.exchange_name,
            type: x.type
          )
        end)
    )
  end
end

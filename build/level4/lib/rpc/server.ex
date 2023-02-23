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
  def start_market(request, _stream),
    do: case(Level4.start_market(request.market)) do
    {:error, reason} ->
      # error starting market data feed
      raise GRPC.RPCError, status: GRPC.Status.unknown(), message: reason

    {:ok, node} ->
      # started market data feed successfully
      Level4.RPC.Server.StartMarketReply.new(
        market: request.market |> Map.to_list() |> Level4.RPC.Server.Market.new(),
        node: Level4.RPC.Server.Node.new(name: "#{node}", active_market_count: 0)
      )
  end

  @spec stop_market(
          Level4.StopMarketRequest.t(),
          GRPC.Server.Stream.t()
        ) :: Level4.StopMarketReply.t()
  def stop_market(request, _stream),
    do: case(Level4.stop_market(request.market)) do
    {:error, reason} ->
      # error stopping market data feed
      raise GRPC.RPCError, status: GRPC.Status.unknown(), message: reason

    {:ok, node} ->
      # stopped market data feed successfully
      Level4.RPC.Server.StopMarketReply.new(
        market: request.market |> Map.to_list() |> Level4.RPC.Server.Market.new(),
        node: Level4.RPC.Server.Node.new(name: "#{node}", active_market_count: 0)
      )
  end

  @spec stop_market(
          Level4.ListNodesRequest.t(),
          GRPC.Server.Stream.t()
        ) :: Level4.ListNodesReply.t()
  def list_nodes(request, _stream),
    do:
      Level4.RPC.Server.ListNodesReply.new(
        # list the nodes in the cluster
        nodes:
          Level4.list_nodes(:all)
          |> Enum.map(fn x ->
            Level4.RPC.Server.Node.new(name: "#{x}", active_market_count: 0)
          end)
      )

  @spec list_active_markets(
          ListMarketsRequest.t(),
          GRPC.Server.Stream.t()
        ) :: Level4.ListMarketsReply.t()
  def list_active_markets(request, _stream),
    do:
      Level4.RPC.Server.ListMarketsReply.new(
        # list active market data feeds 
        markets:
          Level4.list_active_markets(:all)
          |> Enum.map(fn x ->
            x |> Map.to_list() |> Level4.RPC.Server.Market.new()
          end)
      )
end

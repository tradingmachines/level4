defmodule Level4.RPC.Endpoint do
  @doc """
  The RPC server endpoint. Inserts the logger middleware and runs the
  main server module.
  """

  use GRPC.Endpoint

  intercept(GRPC.Logger.Server)
  run(Level4.RPC.Server)
end

defmodule Level4.RPC.Server do
  @doc """
  The Level4 RPC server implements GRPC.Server and uses types defined
  in level4.pb.ex. The pb file is generated using the protoc compiler.

  See the following pages for information regarding grpc / protobuf:
  - https://github.com/elixir-grpc/grpc
  - https://github.com/elixir-protobuf/protobuf
  - https://github.com/protocolbuffers/protobuf
  """

  use GRPC.Server, service: Level4.RPC.Server.Control.Service

  @doc """
  RPC call :: start a market data feed. The input is a market struct.

  market = {
    int32 id
    string base_symbol
    string quote_symbol
    string exchange_name
    string type
  }

  node = {
    string name
    int32 active_market_count
  }

  The output can be:
  1. success, node name
  2. error, reason
  """
  @spec start_market(
          Level4.StartMarketRequest.t(),
          GRPC.Server.Stream.t()
        ) :: Level4.StartMarketReply.t()
  def start_market(request, _stream) do
    case(Level4.start_market(request.market)) do
      {:error, reason} ->
        # error starting market data feed
        raise GRPC.RPCError, status: GRPC.Status.unknown(), message: reason

      {:ok, node} ->
        # started market data feed successfully
        Level4.RPC.Server.StartMarketReply.new(
          market:
            request.market
            |> Map.to_list()
            |> Level4.RPC.Server.Market.new(),
          node:
            Level4.RPC.Server.Node.new(
              name: "#{node}",
              active_market_count: Level4.list_active_markets(node) |> Enum.count()
            )
        )
    end
  end

  @doc """
  RPC call :: stop a market data feed. The input is a market struct.

  market = {
    int32 id
    string base_symbol
    string quote_symbol
    string exchange_name
    string type
  }

  node = {
    string name
    int32 active_market_count
  }

  The output can be:
  1. success, node name
  2. error, reason
  """
  @spec stop_market(
          Level4.StopMarketRequest.t(),
          GRPC.Server.Stream.t()
        ) :: Level4.StopMarketReply.t()
  def stop_market(request, _stream) do
    case(Level4.stop_market(request.market)) do
      {:error, reason} ->
        # error stopping market data feed
        raise GRPC.RPCError, status: GRPC.Status.unknown(), message: reason

      {:ok, node} ->
        # stopped market data feed successfully
        Level4.RPC.Server.StopMarketReply.new(
          market:
            request.market
            |> Map.to_list()
            |> Level4.RPC.Server.Market.new(),
          node:
            Level4.RPC.Server.Node.new(
              name: "#{node}",
              active_market_count: Level4.list_active_markets(node) |> Enum.count()
            )
        )
    end
  end

  @doc """
  RPC call :: list nodes in the cluster. There is no input. The output
  is always a list of one or more node host hostnames.

  node = {
    string name
    int32 active_market_count
  }
  """
  @spec list_nodes(
          Level4.ListNodesRequest.t(),
          GRPC.Server.Stream.t()
        ) :: Level4.ListNodesReply.t()
  def list_nodes(request, _stream),
    do:
      Level4.RPC.Server.ListNodesReply.new(
        nodes:
          Level4.list_nodes(:all)
          |> Enum.map(fn x ->
            Level4.RPC.Server.Node.new(
              name: "#{x}",
              active_market_count: Level4.list_active_markets(x) |> Enum.count()
            )
          end)
      )

  @doc """
  RPC call :: list all active nodes. There is no input. The output
  is always a list of zero or more market structs.

  market = {
    int32 id
    string base_symbol
    string quote_symbol
    string exchange_name
    string type
  }
  """
  @spec list_active_markets(
          ListMarketsRequest.t(),
          GRPC.Server.Stream.t()
        ) :: Level4.ListMarketsReply.t()
  def list_active_markets(request, _stream),
    do:
      Level4.RPC.Server.ListMarketsReply.new(
        markets:
          Level4.list_active_markets(:all)
          |> Enum.map(fn x ->
            x |> Map.to_list() |> Level4.RPC.Server.Market.new()
          end)
      )
end

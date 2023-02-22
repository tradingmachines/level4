defmodule Level4.RPC.Endpoint do
  @doc """
  ...
  """

  use GRPC.Endpoint

  intercept(GRPC.Server.Interceptors.Logger)
  run(Level4.RPC.Server)
end

defmodule Level4.RPC.Server do
  @doc """
  ...
  """

  use GRPC.Server, service: Level4.Service

  @spec start_market(Level4.MarketRequest.t(), GRPC.Server.Stream.t()) :: Level4.MarketReply.t()
  def start_market(request, _stream) do
    # do stuff here
    # ...

    Level4.MarketReply.new()
  end

  @spec stop_market(Level4.MarketRequest.t(), GRPC.Server.Stream.t()) :: Level4.MarketReply.t()
  def stop_market(request, _stream) do
    # do stuff here
    # ...

    Level4.MarketReply.new()
  end

  @spec stop_market(GRPC.Server.Stream.t()) :: Level4.NodesReply.t()
  def list_nodes(_stream) do
    # do stuff here
    # ...

    Level4.NodesReply.new()
  end

  @spec list_active_markets(GRPC.Server.Stream.t()) :: Level4.ActiveMarketsReply.t()
  def list_active_markets(_stream) do
    # do stuff here
    # ...

    Level4.ActiveMarketsReply.new()
  end
end

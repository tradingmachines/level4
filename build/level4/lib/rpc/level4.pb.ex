defmodule Level4.RPC.Server.Node do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :name, 1, type: :string
  field :active_market_count, 2, type: :int32, json_name: "activeMarketCount"
end

defmodule Level4.RPC.Server.Market do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :id, 1, type: :int32
  field :base_symbol, 2, type: :string, json_name: "baseSymbol"
  field :quote_symbol, 3, type: :string, json_name: "quoteSymbol"
  field :exchange_name, 4, type: :string, json_name: "exchangeName"
  field :type, 5, type: :string
end

defmodule Level4.RPC.Server.StartMarketRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :market, 1, type: Level4.RPC.Server.Market
end

defmodule Level4.RPC.Server.StopMarketRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :market, 1, type: Level4.RPC.Server.Market
end

defmodule Level4.RPC.Server.ListNodesRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3
end

defmodule Level4.RPC.Server.ListMarketsRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3
end

defmodule Level4.RPC.Server.StartMarketReply do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :market, 1, type: Level4.RPC.Server.Market
  field :node, 2, type: Level4.RPC.Server.Node
end

defmodule Level4.RPC.Server.StopMarketReply do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :market, 1, type: Level4.RPC.Server.Market
  field :node, 2, type: Level4.RPC.Server.Node
end

defmodule Level4.RPC.Server.ListNodesReply do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :nodes, 1, repeated: true, type: Level4.RPC.Server.Node
end

defmodule Level4.RPC.Server.ListMarketsReply do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

  field :markets, 1, repeated: true, type: Level4.RPC.Server.Market
end

defmodule Level4.RPC.Server.Control.Service do
  @moduledoc false
  use GRPC.Service, name: "level4.rpc.Control", protoc_gen_elixir_version: "0.11.0"

  rpc :StartMarket, Level4.RPC.Server.StartMarketRequest, Level4.RPC.Server.StopMarketReply

  rpc :StopMarket, Level4.RPC.Server.StartMarketRequest, Level4.RPC.Server.StopMarketReply

  rpc :ListNodes, Level4.RPC.Server.ListNodesRequest, Level4.RPC.Server.ListNodesReply

  rpc :ListActiveMarkets, Level4.RPC.Server.ListMarketsRequest, Level4.RPC.Server.ListMarketsReply
end

defmodule Level4.RPC.Server.Control.Stub do
  @moduledoc false
  use GRPC.Stub, service: Level4.RPC.Server.Control.Service
end
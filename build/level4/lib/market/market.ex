defmodule Market do
  @moduledoc """
  Defines a structure for all fields that make up a market:
  - numeric identifier
  - exchange name
  - base symbol
  - quote symbol
  - market type
  """

  @enforce_keys [:id, :exchange_name, :base_symbol, :quote_symbol, :type]
  defstruct [:id, :exchange_name, :base_symbol, :quote_symbol, :type]

  @doc """
  A market's tag is:

  <exchange name>.<market type>:<base>-<quote>

  Always fully capitalised. for example:
  - COINBASE-PRO.SPOT:BTC-USDT
  - POLONIEX.SPOT:BTC-USDT
  - POLONIEX.PERP:BTC-USDT
  """
  def tag(market) do
    # get and capitalise all of the fields
    exchange_name = String.upcase(market.exchange_name)
    market_type = String.upcase(market.market_type)
    base_symbol = String.upcase(market.base_symbol)
    quote_symbol = String.upcase(market.quote_symbol)

    # interpolate them
    "#{exchange_name}.#{market_type}:#{base_symbol}-#{quote_symbol}"
  end
end

defimpl String.Chars, for: Market do
  # make a market struct printable
  def to_string(market), do: Market.tag(market)
end

defmodule Market.DynamicSupervisor do
  @moduledoc """
  Implements a dynamic supervisor for market data feeds.
  """

  use DynamicSupervisor

  def start_link(init_arg),
    do:
      DynamicSupervisor.start_link(
        __MODULE__,
        init_arg,
        name: __MODULE__
      )

  @impl true
  def init(init_arg),
    do:
      DynamicSupervisor.init(
        strategy: :one_for_one,
        max_children: init_arg[:max_data_feeds]
      )

  @doc """
  List all market data feeds under the dynamic supervisor.
  """
  def list_active_markets(:all),
    do:
      DynamicSupervisor.which_children(__MODULE__)
      |> Enum.map(fn {_id, pid, _type, _modules} ->
        Market.DataFeed.Supervisor.get_market_metadata(pid)
      end)

  @doc """
  Start a new market data feed: adds a new data feed process to the dynamic
  supervisor.
  """
  def start_data_feed(market, config) do
    {:ok, _pid} =
      DynamicSupervisor.start_child(
        __MODULE__,
        %{
          id: Market.DataFeed.Supervisor,
          start: {
            Market.DataFeed.Supervisor,
            :start_link,
            [
              [market: market, config: config]
            ]
          },
          type: :supervisor,
          restart: :temporary
        }
      )

    :ok
  end

  @doc """
  Stop a market data feed: close the websocket connection and remove the
  process from the dynamic supervisor.
  """
  def stop_data_feed(market) do
    # get the pid for the data feed's supervisor
    [{pid, _}] =
      Registry.lookup(
        Market.DataFeed.Registry,
        market.id
      )

    # terminating the supervisor will trigger the
    # websoket shutdown process
    :ok = DynamicSupervisor.terminate_child(__MODULE__, pid)

    :ok
  end
end

require Logger

defmodule Market.Exchange do
  @moduledoc """
  A Market.Exchange receives and handles messages from a
  Market.Level2.Mediator process.

  The exchange process is responsible for writing data to some persistent
  storage medium.
  """

  use GenServer

  @doc """
  Starts and links a new GenServer with the name returned from the
  process_name function above.
  """
  def start_link(init_arg) do
    GenServer.start_link(
      __MODULE__,
      init_arg,
      name:
        {:via, Registry,
         {
           Market.Exchange.Registry,
           Market.id(init_arg[:market])
         }}
    )
  end

  @doc """
  Init function for the GenServer. Initialises a new storage medium and returns
  it to the GenServer so it is kept in the server's state for future use.
  """
  @impl true
  def init(init_arg) do
    Logger.info(
      "#{Market.id(init_arg[:market])} " <>
        "starting exchange"
    )

    # make and/or get the exchange record
    exchange =
      case Storage.Model.Exchange
           |> Storage.Repo.get_by(name: init_arg[:market].exchange_name) do
        nil ->
          {:ok, struct} =
            Storage.Repo.insert(%Storage.Model.Exchange{
              name: init_arg[:market].exchange_name
            })

          struct

        struct ->
          struct
      end

    # make and/or get the base symbol record
    base_symbol =
      case Storage.Model.Symbol
           |> Storage.Repo.get_by(symbol: init_arg[:market].base_symbol) do
        nil ->
          {:ok, struct} =
            Storage.Repo.insert(%Storage.Model.Symbol{
              symbol: init_arg[:market].base_symbol
            })

          struct

        struct ->
          struct
      end

    # make and/or get the quote symbol record
    quote_symbol =
      case Storage.Model.Symbol
           |> Storage.Repo.get_by(symbol: init_arg[:market].quote_symbol) do
        nil ->
          {:ok, struct} =
            Storage.Repo.insert(%Storage.Model.Symbol{
              symbol: init_arg[:market].quote_symbol
            })

          struct

        struct ->
          struct
      end

    # make and/or get the market record
    market =
      case Storage.Model.Market
           |> Storage.Repo.get_by(
             base_symbol_id: base_symbol.id,
             quote_symbol_id: quote_symbol.id,
             exchange_id: exchange.id,
             market_type: init_arg[:market].market_type
           ) do
        nil ->
          {:ok, struct} =
            Storage.Repo.insert(%Storage.Model.Market{
              base_symbol_id: base_symbol.id,
              quote_symbol_id: quote_symbol.id,
              exchange_id: exchange.id,
              market_type: init_arg[:market].market_type,
              level4_feed_enabled: true
            })

          struct

        struct ->
          struct
      end

    {:ok, market}
  end

  @doc """
  GenServer cast functions for async API calls.
  """
  # :best_bid_change -> the best bid price changed -> log it
  @impl true
  def handle_cast({:best_bid_change, {new_price, _, timestamp}}, market) do
    Storage.Repo.insert(%Storage.Model.BestBidPrice{
      market_id: market.id,
      price: new_price,
      timestamp: timestamp
    })

    {:noreply, market}
  end

  # :best_ask_change -> the best ask price changed -> log it
  def handle_cast({:best_ask_change, {new_price, _, timestamp}}, market) do
    Storage.Repo.insert(%Storage.Model.BestAskPrice{
      market_id: market.id,
      price: new_price,
      timestamp: timestamp
    })

    {:noreply, market}
  end

  @doc """
  Async Market.Exchange API: a helper function that sends a :best_bid_change to
  the GenServer. Note: casts are asynchronous requests.
  """
  def best_bid_change(exchange, {new_price, new_size, timestamp}) do
    GenServer.cast(exchange, {:best_bid_change, {new_price, new_size, timestamp}})
  end

  @doc """
  Async Market.Exchange API: a helper function that sends a :best_ask_change to
  the GenServer. Note: casts are asynchronous requests.
  """
  def best_ask_change(exchange, {new_price, new_size, timestamp}) do
    GenServer.cast(exchange, {:best_ask_change, {new_price, new_size, timestamp}})
  end
end

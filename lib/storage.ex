defmodule StorageMedium do
  @moduledoc """
  Defines behaviours that a backend storage medium must implement
  in order to be a valid storage medium.
  """

  @doc """
  Tries to write a symbol string to the storage backend. If successful
  or symbol already exists then returns the symbol's unique Id.
  """
  @callback save_symbol(Storage.Model.Symbol) ::
              {:created, any()}
              | {:already_exists, any()}
              | {:error, any()}

  @doc """
  Tries to write an exchange tuple to the storage backend. If successful
  or exchange already exists then returns the exchange's unique Id.
  """
  @callback save_exchange(Storage.Model.Exchange) ::
              {:created, any()}
              | {:already_exists, any()}
              | {:error, any()}

  @doc """
  Tries to write a market tuple to the storage backend. If successful
  or market already exists then returns the market's unique Id.
  """
  @callback save_market(Storage.Model.Market) ::
              {:created, any()}
              | {:already_exists, any()}
              | {:error, any()}

  @doc """
  Writes a spread change event to the storage backend.
  """
  @callback save_spread_change(SpreadChange) ::
              :ok
              | {:error, String.t()}
end

defmodule SpreadChange do
  @moduledoc """
  a spread change is an event that occurs when either the best
  bid or best ask price changes for a particular market.
  """

  # the event is tagged with the exchange name, major and quote
  # symbols, and timestamp for easy filtration later on.
  @enforce_keys [
    :exchange_name,
    :major_symbol,
    :quote_symbol,
    :timestamp,
    :side,
    :price
  ]
  defstruct [
    :exchange_name,
    :major_symbol,
    :quote_symbol,
    :timestamp,
    :side,
    :price
  ]
end

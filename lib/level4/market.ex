defmodule Level4.Market do
  @moduledoc """
  Level4.Market encapsulates configuration for a particular market.
  Recall: a "market" is a tradeable currency pair on a specific exchange
  e.g. `COINBASE-PRO:BTC-USD`. Level4.Market is essentially our internal,
  high-level representation of a single data feed.
  """

  # a market has an exchange name, major and quote currency symbols,
  # and an exchange-specific translation scheme for communication with
  # the exchange's websocket API.
  @enforce_keys [
    :exchange_name,
    :exchange_ws_url,
    :major_symbol,
    :quote_symbol,
    :translation_scheme
  ]
  defstruct [
    :exchange_name,
    :exchange_ws_url,
    :major_symbol,
    :quote_symbol,
    :translation_scheme
  ]

  @doc """
  A market's identifier is of the form <exchange name>:<major>-<quote>,
  inspired by Cryptowatch's URL scheme.
  """
  @spec id(Level4.Market) :: String.t()
  def id(market) do
    "#{market.exchange_name}:#{market.major_symbol}-#{market.quote_symbol}"
  end
end

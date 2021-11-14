defmodule Market do
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
    :ws_url,
    :ws_port,
    :major_symbol,
    :quote_symbol,
    :translation_scheme
  ]
  defstruct [
    :exchange_name,
    :ws_url,
    :ws_port,
    :major_symbol,
    :quote_symbol,
    :translation_scheme
  ]

  @doc """
  A market's identifier is of the form <exchange name>:<major>-<quote>,
  inspired by Cryptowatch's URL scheme - the whole string is uppercase.
  """
  @spec id(Market) :: String.t()
  def id(market) do
    exchange_name = String.upcase(market.exchange_name)
    major_symbol = String.upcase(market.major_symbol)
    quote_symbol = String.upcase(market.quote_symbol)

    "#{exchange_name}:#{major_symbol}-#{quote_symbol}"
  end
end

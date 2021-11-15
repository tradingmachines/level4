# Level4
Ingress. This is were the data comes from.
Level 4 is an elixir application which exposes some (convenient)
interface to:
- receive live data
- query historical data

## Mechanics
### Exchanges
- There is some collection of Exchange processes
- Each exchange monitors some set of markets (pairs of currency symbols)
- Each exchange maintains a database process, WIP TODO

### Market
- A market maintains a local order book
- A market updates its order book based on incoming snapshots (lists of
  deltas) and deltas from some websocket
- A market may need to send its orderbook to a websocket

### Orderbook
- The orderbook contains two gb\_trees, for both the bid and ask sides
- The orderbook exists as a sorted map of prices to liquidity at each price
  level
- A snapshot will always replace the current state
- A delta will update the current state

### Deltas and Fills
- A delta is a 3tuple of form (:side, :price, :size) representing a change
  in the order book
- A fill is a 4tuple (:side, :time, :price, :size) representing a market
  order fulfilment

### Translation Scheme
- A translation scheme is some function which transforms heterogeneous
  json data from a websocket into  homogeneous elixir data structure (deltas
  or fill)
- A translation scheme may need to request an orderbook from some market

### Phone Book
- A phone book is a relation mapping specific markets to the PIDs of market
processes which should receive updates on those markets

### Websockets
- A websocket is a reliable connection to some exchanges level2 feed
- It automatically handles reconnects with sensible backoffs
- A websocket is initialized with a translation scheme and a phone book
- When it receives information from the exchange it is subscribed to it will
  translate the data (with it's translation scheme) and then send this data to
  a specific market (based on its phone book)
- The websocket must handle synchronisation checks, but different exchanges
  indicate synchronisation in different ways so this will be exchange specific
- A websocket may need to request an orderbook from a market (for some exchange
  specific sync checks)

## Installation
If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `level4` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:level4, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/level4](https://hexdocs.pm/level4).

## Testing
```elixir
MarketSupervisor.start_market(%Market{exchange_name: "COINBASE-PRO", major_symbol: "LTC", quote_symbol: "GBP", ws_url: "ws-feed.exchange.coinbase.com", ws_port: 443, translation_scheme: Exchanges.Coinbase})


[{"BTC", "GBP"},
 {"BTC", "USD"},
 {"ETH", "GBP"},
 {"ETH", "USD"},
 {"LTC", "GBP"},
 {"LTC", "USD"},
 {"MATIC", "GBP"},
 {"MATIC", "USD"},
 {"ADA", "GBP"},
 {"ADA", "USD"},
 {"CHZ", "GBP"},
 {"CHZ", "USD"},
 {"OMG", "GBP"},
 {"OMG", "USD"},
 {"DOGE", "GBP"},
 {"DOGE", "USD"},
 {"SHIB", "GBP"},
 {"SHIB", "USD"},
 {"1INCH", "GBP"},
 {"1INCH", "USD"},
 {"AAVE", "GBP"},
 {"AAVE", "USD"},
 {"ALGO", "GBP"},
 {"ALGO", "USD"},
 {"ANKR", "GBP"},
 {"ANKR", "USD"},
 {"ATOM", "GBP"},
 {"ATOM", "USD"},
 {"BAND", "GBP"},
 {"BAND", "USD"},
 {"BCH", "GBP"},
 {"BCH", "USD"},
 {"BNT", "GBP"},
 {"BNT", "USD"},
 {"BTRST", "GBP"},
 {"BTRST", "USD"},
 {"CELO", "GBP"},
 {"CELO", "USD"},
 {"CLV", "GBP"},
 {"CLV", "USD"},
 {"CRV", "GBP"},
 {"CRV", "USD"},
 {"DOT", "GBP"},
 {"DOT", "USD"},
 {"ETC", "GBP"},
 {"ETC", "USD"},
 {"FIL", "GBP"},
 {"FIL", "USD"},
 {"FORTH", "GBP"},
 {"FORTH", "USD"},
 {"GRT", "GBP"},
 {"GRT", "USD"},
 {"LINK", "GBP"},
 {"LINK", "USD"},
 {"MASK", "GBP"},
 {"MASK", "USD"},
 {"SOL", "GBP"},
 {"SOL", "USD"},
 {"RLY", "GBP"},
 {"RLY", "USD"},
 {"SUSHI", "GBP"},
 {"SUSHI", "USD"},
 {"UNI", "GBP"},
 {"UNI", "USD"}
]
```

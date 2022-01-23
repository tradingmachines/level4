# level4

...

## Testing
```elixir
Markets.start_market(%Market{exchange_name: "COINBASE-PRO", base_symbol: "BTC", quote_symbol: "GBP", market_type: "SPOT", ws_url: "ws-feed.exchange.coinbase.com", ws_port: 443, translation_scheme: Exchanges.Coinbase})

Markets.start_market(%Market{exchange_name: "POLONIEX", base_symbol: "BTC", quote_symbol: "USDT", market_type: "SPOT", ws_url: "api2.poloniex.com", ws_port: 443, translation_scheme: Exchanges.Poloniex})

Markets.start_market(%Market{exchange_name: "KRAKEN", base_symbol: "BTC", quote_symbol: "USD", market_type: "SPOT", ws_url: "ws.kraken.com", ws_port: 443, translation_scheme: Exchanges.Kraken})


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

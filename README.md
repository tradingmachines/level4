# level4

...

### coinbase
```
Markets.start_market(%Market{exchange_name: "COINBASE-PRO", base_symbol: "BTC", quote_symbol: "GBP", market_type: "SPOT", ws_url: "ws-feed.exchange.coinbase.com", ws_path: "/", ws_port: 443, translation_scheme: Exchanges.Coinbase})
```

### poloniex
```
Markets.start_market(%Market{exchange_name: "POLONIEX", base_symbol: "BTC", quote_symbol: "USDT", market_type: "SPOT", ws_url: "api2.poloniex.com", ws_path: "/", ws_port: 443, translation_scheme: Exchanges.Poloniex})
```

### kraken
```
Markets.start_market(%Market{exchange_name: "KRAKEN", base_symbol: "BTC", quote_symbol: "USD", market_type: "SPOT", ws_url: "ws.kraken.com", ws_path: "/", ws_port: 443, translation_scheme: Exchanges.Kraken})
```

### hitbtc
```
Markets.start_market(%Market{exchange_name: "HITBTC", base_symbol: "BTC", quote_symbol: "USDT", market_type: "SPOT", ws_url: "api.hitbtc.com", ws_path: "/api/3/ws/public", ws_port: 443, translation_scheme: Exchanges.HitBTC})
```

### gemini
```
Markets.start_market(%Market{exchange_name: "GEMINI", base_symbol: "BTC", quote_symbol: "USD", market_type: "SPOT", ws_url: "api.gemini.com", ws_path: "/v2/marketdata", ws_port: 443, translation_scheme: Exchanges.Gemini})
```

### ftx
```
Markets.start_market(%Market{exchange_name: "FTX", base_symbol: "BTC", quote_symbol: "USDT", market_type: "SPOT", ws_url: "ftx.com", ws_path: "/ws", ws_port: 443, translation_scheme: Exchanges.FTX})
```

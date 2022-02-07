# level4

...

### coinbase
```
Markets.start_market(%Market{exchange_name: "COINBASE-PRO", base_symbol: "BTC", quote_symbol: "GBP", market_type: "SPOT", ws_url: "ws-feed.exchange.coinbase.com", ws_path: "/", ws_port: 443, translation_scheme: Exchanges.Coinbase, ping?: false})
```

### poloniex
```
Markets.start_market(%Market{exchange_name: "POLONIEX", base_symbol: "BTC", quote_symbol: "USDT", market_type: "SPOT", ws_url: "api2.poloniex.com", ws_path: "/", ws_port: 443, translation_scheme: Exchanges.Poloniex, ping?: false})
```

### kraken
```
Markets.start_market(%Market{exchange_name: "KRAKEN", base_symbol: "BTC", quote_symbol: "USD", market_type: "SPOT", ws_url: "ws.kraken.com", ws_path: "/", ws_port: 443, translation_scheme: Exchanges.Kraken, ping?: false})
```

### hitbtc
```
Markets.start_market(%Market{exchange_name: "HITBTC", base_symbol: "BTC", quote_symbol: "USDT", market_type: "SPOT", ws_url: "api.hitbtc.com", ws_path: "/api/3/ws/public", ws_port: 443, translation_scheme: Exchanges.HitBTC, ping?: false})
```

### gemini
```
Markets.start_market(%Market{exchange_name: "GEMINI", base_symbol: "BTC", quote_symbol: "USD", market_type: "SPOT", ws_url: "api.gemini.com", ws_path: "/v2/marketdata", ws_port: 443, translation_scheme: Exchanges.Gemini, ping?: false})
```

### ftx
```
Markets.start_market(%Market{exchange_name: "FTX", base_symbol: "BTC", quote_symbol: "USDT", market_type: "SPOT", ws_url: "ftx.com", ws_path: "/ws", ws_port: 443, translation_scheme: Exchanges.FTX, ping?: true})
```

### bybit
```
Markets.start_market(%Market{exchange_name: "BYBIT", base_symbol: "BTC", quote_symbol: "USDT", market_type: "SPOT", ws_url: "stream.bybit.com", ws_path: "/spot/quote/ws/v2", ws_port: 443, translation_scheme: Exchanges.Bybit.Spot, ping?: true})

Markets.start_market(%Market{exchange_name: "BYBIT", base_symbol: "BTC", quote_symbol: "USDT", market_type: "PERP[USDT]", ws_url: "stream.bybit.com", ws_path: "/realtime_public", ws_port: 443, translation_scheme: Exchanges.Bybit.Perp.USDT, ping?: true})

Markets.start_market(%Market{exchange_name: "BYBIT", base_symbol: "BTC", quote_symbol: "USD", market_type: "PERP[INVERSE]", ws_url: "stream.bybit.com", ws_path: "/realtime", ws_port: 443, translation_scheme: Exchanges.Bybit.Perp.Inverse, ping?: true})
```

### bitstamp
```
Markets.start_market(%Market{exchange_name: "BITSTAMP", base_symbol: "BTC", quote_symbol: "USD", market_type: "SPOT", ws_url: "ws.bitstamp.net", ws_path: "/", ws_port: 443, translation_scheme: Exchanges.Bitstamp, ping?: true})
```

### bitmex
```
Markets.start_market(%Market{exchange_name: "BITMEX", base_symbol: "XBT", quote_symbol: "USD", market_type: "SPOT", ws_url: "ws.bitmex.com", ws_path: "/realtime", ws_port: 443, translation_scheme: Exchanges.Bitmex, ping?: true})
```

### bitflyer
```
Markets.start_market(%Market{exchange_name: "BITFLYER", base_symbol: "BTC", quote_symbol: "JPY", market_type: "SPOT", ws_url: "ws.lightstream.bitflyer.com", ws_path: "/json-rpc", ws_port: 443, translation_scheme: Exchanges.Bitflyer.Spot, ping?: false})
```

### bitfinex
```
Markets.start_market(%Market{exchange_name: "BITFINEX", base_symbol: "BTC", quote_symbol: "USD", market_type: "SPOT", ws_url: "api-pub.bitfinex.com", ws_path: "/ws/2", ws_port: 443, translation_scheme: Exchanges.Bitfinex.Trading, ping?: true})
```

import Config

# ecto storage repo
config :level4, ecto_repos: [Storage.Repo]

# exchange translation scheme map
config :level4,
  exchanges: %{
    "BINANCE" => %{
      "SPOT" => %{
        translation_scheme: Exchanges.Binance.Spot,
        url: "stream.binance.com",
        path: "/ws",
        port: 443,
        ping?: false
      }
    },
    "BITFINEX" => %{
      "SPOT" => %{
        translation_scheme: Exchanges.Bitfinex.Trading,
        url: "api-pub.bitfinex.com",
        path: "/ws/2",
        port: 443,
        ping?: true
      }
    },
    "BITFLYER" => %{
      "SPOT" => %{
        translation_scheme: Exchanges.Bitflyer.Spot,
        url: "ws.lightstream.bitflyer.com",
        path: "/json-rpc",
        port: 443,
        ping?: true
      }
    },
    "BITMEX" => %{
      "SPOT" => %{
        translation_scheme: Exchanges.Bitmex,
        url: "ws.bitmex.com",
        path: "/realtime",
        port: 443,
        ping?: true
      }
    },
    "BITSTAMP" => %{
      "SPOT" => %{
        translation_scheme: Exchanges.Bitstamp,
        url: "ws.bitstamp.net",
        path: "/",
        port: 443,
        ping?: true
      }
    },
    "BYBIT" => %{
      "SPOT" => %{
        translation_scheme: Exchanges.Bybit.Spot,
        url: "stream.bybit.com",
        path: "/spot/quote/ws/v2",
        port: 443,
        ping?: true
      },
      "PERP[USDT]" => %{
        translation_scheme: Exchanges.Bybit.Perp.USDT,
        url: "stream.bybit.com",
        path: "/realtime_public",
        port: 443,
        ping?: true
      },
      "PERP[INVERSE]" => %{
        translation_scheme: Exchanges.Bybit.Perp.Inverse,
        url: "stream.bybit.com",
        path: "/realtime",
        port: 443,
        ping?: true
      }
    },
    "COINBASE-PRO" => %{
      "SPOT" => %{
        translation_scheme: Exchanges.Coinbase,
        url: "ws-feed.exchange.coinbase.com",
        path: "/",
        port: 443,
        ping?: false
      }
    },
    "FTX" => %{
      "SPOT" => %{
        translation_scheme: Exchanges.FTX,
        url: "ftx.com",
        path: "/ws",
        port: 443,
        ping?: true
      }
    },
    "GEMINI" => %{
      "SPOT" => %{
        translation_scheme: Exchanges.Gemini,
        url: "api.gemini.com",
        path: "/v2/marketdata",
        port: 443,
        ping?: false
      }
    },
    "HITBTC" => %{
      "SPOT" => %{
        translation_scheme: Exchanges.HitBTC,
        url: "api.hitbtc.com",
        path: "/api/3/ws/public",
        port: 443,
        ping?: false
      }
    },
    "KRAKEN" => %{
      "SPOT" => %{
        translation_scheme: Exchanges.Kraken,
        url: "ws.kraken.com",
        path: "/",
        port: 443,
        ping?: false
      }
    },
    "POLONIEX" => %{
      "SPOT" => %{
        translation_scheme: Exchanges.Poloniex,
        url: "api2.poloniex.com",
        path: "/",
        port: 443,
        ping?: false
      }
    }
  }

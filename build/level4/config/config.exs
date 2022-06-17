import Config

# set log level
config :logger, level: :info

# ecto storage repo
config :level4, ecto_repos: [Storage.Repo]

# exchange translation scheme map
config :level4,
  exchanges: %{
    #
    # binance.com
    #
    "BINANCE" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchanges.Binance.Spot,
        ws_host: "stream.binance.com",
        path: "/ws",
        port: 443,
        ping?: false
      },
      # status: working
      # correctness: correct
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.Binance.Futures,
        ws_host: "fstream.binance.com",
        path: "/ws",
        port: 443,
        ping?: false
      },
      # status: working
      # correctness: correct
      "PERP-FUTURE-INVERSE" => %{
        translation_scheme: Exchanges.Binance.Inverse,
        ws_host: "dstream.binance.com",
        path: "/ws",
        port: 443,
        ping?: false
      }
    },
    #
    # bitfinex.com
    #
    "BITFINEX" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchanges.Bitfinex.Spot,
        ws_host: "api-pub.bitfinex.com",
        path: "/ws/2",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.Bitfinex.Futures,
        ws_host: "api-pub.bitfinex.com",
        path: "/ws/2",
        port: 443,
        ping?: true
      }
    },
    #
    # bitflyer.com
    #
    "BITFLYER" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchanges.Bitflyer.Spot,
        ws_host: "ws.lightstream.bitflyer.com",
        path: "/json-rpc",
        port: 443,
        ping?: false
      }
    },
    #
    # bitmex.com
    #
    "BITMEX" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchanges.Bitmex.Spot,
        ws_host: "ws.bitmex.com",
        path: "/realtime",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.Bitmex.Futures,
        ws_host: "ws.bitmex.com",
        path: "/realtime",
        port: 443,
        ping?: true
      }
    },
    #
    # bitstamp.com
    #
    "BITSTAMP" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchanges.Bitstamp.Spot,
        ws_host: "ws.bitstamp.net",
        path: "/",
        port: 443,
        ping?: true
      }
    },
    #
    # bybit.com
    #
    "BYBIT" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchanges.Bybit.Spot,
        ws_host: "stream.bybit.com",
        path: "/spot/quote/ws/v2",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.Bybit.Futures,
        ws_host: "stream.bybit.com",
        path: "/realtime_public",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "PERP-FUTURE-INVERSE" => %{
        translation_scheme: Exchanges.Bybit.Inverse,
        ws_host: "stream.bybit.com",
        path: "/realtime",
        port: 443,
        ping?: true
      }
    },
    #
    # coinbase.com
    #
    "COINBASE-PRO" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchanges.Coinbase.Spot,
        ws_host: "ws-feed.exchange.coinbase.com",
        path: "/",
        port: 443,
        ping?: false
      }
    },
    #
    # ftx.com
    #
    "FTX" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchanges.FTX.Spot,
        ws_host: "ftx.com",
        path: "/ws",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.FTX.Futures,
        ws_host: "ftx.com",
        path: "/ws",
        port: 443,
        ping?: true
      }
    },
    #
    # gemini.com
    #
    "GEMINI" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchanges.Gemini.Spot,
        ws_host: "api.gemini.com",
        path: "/v2/marketdata",
        port: 443,
        ping?: false
      }
    },
    #
    # hitbtc.com
    #
    "HITBTC" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchanges.HitBTC.Spot,
        ws_host: "api.hitbtc.com",
        path: "/api/3/ws/public",
        port: 443,
        ping?: false
      },
      # status: working
      # correctness: correct
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.HitBTC.Futures,
        ws_host: "api.hitbtc.com",
        path: "/api/3/ws/public",
        port: 443,
        ping?: false
      }
    },
    #
    # kraken.com
    #
    "KRAKEN" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchanges.Kraken.Spot,
        ws_host: "ws.kraken.com",
        path: "/",
        port: 443,
        ping?: false
      },
      # status: working
      # correctness: correct
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.Kraken.Futures,
        ws_host: "futures.kraken.com",
        path: "/ws/v1",
        port: 443,
        ping?: false
      },
      # status: working
      # correctness: correct
      "PERP-FUTURE-INVERSE" => %{
        translation_scheme: Exchanges.Kraken.Inverse,
        ws_host: "futures.kraken.com",
        path: "/ws/v1",
        port: 443,
        ping?: false
      }
    },
    #
    # poloniex.com
    #
    "POLONIEX" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchanges.Poloniex.Spot,
        ws_host: "api2.poloniex.com",
        path: "/",
        port: 443,
        ping?: false
      }
    }
  }

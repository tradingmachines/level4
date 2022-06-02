import Config

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
        url: "stream.binance.com",
        path: "/ws",
        port: 443,
        ping?: false
      },
      # status: working
      # correctness: correct
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.Binance.Futures,
        url: "fstream.binance.com",
        path: "/ws",
        port: 443,
        ping?: false
      },
      # status: working
      # correctness: correct
      "PERP-FUTURE-INVERSE" => %{
        translation_scheme: Exchanges.Binance.Inverse,
        url: "dstream.binance.com",
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
        url: "api-pub.bitfinex.com",
        path: "/ws/2",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.Bitfinex.Futures,
        url: "api-pub.bitfinex.com",
        path: "/ws/2",
        port: 443,
        ping?: true
      }
    },
    #
    # bitflyer.com
    #
    "BITFLYER" => %{
      # status: not working
      # correctness: unchecked
      "SPOT" => %{
        translation_scheme: Exchanges.Bitflyer.Spot,
        url: "ws.lightstream.bitflyer.com",
        path: "/json-rpc",
        port: 443,
        ping?: true
      }
    },
    #
    # bitmex.com
    #
    "BITMEX" => %{
      # status: working
      # correctness: correct
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.Bitmex.Futures,
        url: "ws.bitmex.com",
        path: "/realtime",
        port: 443,
        ping?: true
      },
      # status: not working
      # correctness: unchecked
      "PERP-FUTURE-INVERSE" => %{
        translation_scheme: Exchanges.Bitmex.Inverse,
        url: "ws.bitmex.com",
        path: "/realtime",
        port: 443,
        ping?: true
      }
    },
    #
    # bitstamp.com
    #
    "BITSTAMP" => %{
      # status: not working
      # correctness: incorrect
      "SPOT" => %{
        translation_scheme: Exchanges.Bitstamp.Spot,
        url: "ws.bitstamp.net",
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
      # correctness: incorrect
      "SPOT" => %{
        translation_scheme: Exchanges.Bybit.Spot,
        url: "stream.bybit.com",
        path: "/spot/quote/ws/v2",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.Bybit.Futures,
        url: "stream.bybit.com",
        path: "/realtime_public",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "PERP-FUTURE-INVERSE" => %{
        translation_scheme: Exchanges.Bybit.Inverse,
        url: "stream.bybit.com",
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
        url: "ws-feed.exchange.coinbase.com",
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
      # correctness: incorrect
      "SPOT" => %{
        translation_scheme: Exchanges.FTX.Spot,
        url: "ftx.com",
        path: "/ws",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: incorrect
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.FTX.Futures,
        url: "ftx.com",
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
        url: "api.gemini.com",
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
        url: "api.hitbtc.com",
        path: "/api/3/ws/public",
        port: 443,
        ping?: false
      },
      # status: not working
      # correctness: unchecked
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.HitBTC.Futures,
        url: "api.hitbtc.com",
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
        url: "ws.kraken.com",
        path: "/",
        port: 443,
        ping?: false
      },
      # status: not working
      # correctness: unchecked
      "PERP-FUTURES" => %{
        translation_scheme: Exchanges.Kraken.Futures,
        url: "futures.kraken.com",
        path: "/ws/v1",
        port: 443,
        ping?: false
      },
      # status: not working
      # correctness: unchecked
      "PERP-FUTURE-INVERSE" => %{
        translation_scheme: Exchanges.Kraken.Inverse,
        url: "futures.kraken.com",
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
        url: "api2.poloniex.com",
        path: "/",
        port: 443,
        ping?: false
      }
    }
  }

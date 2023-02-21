import Config

# set the log level
config :logger,
  level: :info

# define the exchange -> market type translation schemes
config :level4,
  exchanges: %{
    ################################################################################
    #
    # binance.com
    #
    "BINANCE" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchange.Binance.Spot,
        host: "stream.binance.com",
        path: "/ws",
        port: 443,
        ping?: false
      },
      # status: working
      # correctness: correct
      "PERP" => %{
        translation_scheme: Exchange.Binance.Futures,
        host: "fstream.binance.com",
        path: "/ws",
        port: 443,
        ping?: false
      },
      # status: working
      # correctness: correct
      "INVERSE" => %{
        translation_scheme: Exchange.Binance.Inverse,
        host: "dstream.binance.com",
        path: "/ws",
        port: 443,
        ping?: false
      }
    },
    ################################################################################
    #
    # bitfinex.com
    #
    "BITFINEX" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchange.Bitfinex.Spot,
        host: "api-pub.bitfinex.com",
        path: "/ws/2",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "PERP" => %{
        translation_scheme: Exchange.Bitfinex.Futures,
        host: "api-pub.bitfinex.com",
        path: "/ws/2",
        port: 443,
        ping?: true
      }
    },
    ################################################################################
    #
    # bitflyer.com
    #
    "BITFLYER" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchange.Bitflyer.Spot,
        host: "ws.lightstream.bitflyer.com",
        path: "/json-rpc",
        port: 443,
        ping?: false
      }
    },
    ################################################################################
    #
    # bitmex.com
    #
    "BITMEX" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchange.Bitmex.Spot,
        host: "ws.bitmex.com",
        path: "/realtime",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "PERP" => %{
        translation_scheme: Exchange.Bitmex.Futures,
        host: "ws.bitmex.com",
        path: "/realtime",
        port: 443,
        ping?: true
      }
    },
    ################################################################################
    #
    # bitstamp.com
    #
    "BITSTAMP" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchange.Bitstamp.Spot,
        host: "ws.bitstamp.net",
        path: "/",
        port: 443,
        ping?: true
      }
    },
    ################################################################################
    #
    # bybit.com
    #
    "BYBIT" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchange.Bybit.Spot,
        host: "stream.bybit.com",
        path: "/spot/quote/ws/v2",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "PERP" => %{
        translation_scheme: Exchange.Bybit.Futures,
        host: "stream.bybit.com",
        path: "/realtime_public",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "INVERSE" => %{
        translation_scheme: Exchange.Bybit.Inverse,
        host: "stream.bybit.com",
        path: "/realtime",
        port: 443,
        ping?: true
      }
    },
    ################################################################################
    #
    # coinbase.com
    #
    "COINBASE-PRO" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchange.Coinbase.Spot,
        host: "ws-feed.exchange.coinbase.com",
        path: "/",
        port: 443,
        ping?: false
      }
    },
    ################################################################################
    #
    # ftx.com
    #
    "FTX" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchange.FTX.Spot,
        host: "ftx.com",
        path: "/ws",
        port: 443,
        ping?: true
      },
      # status: working
      # correctness: correct
      "PERP" => %{
        translation_scheme: Exchange.FTX.Futures,
        host: "ftx.com",
        path: "/ws",
        port: 443,
        ping?: true
      }
    },
    ################################################################################
    #
    # gemini.com
    #
    "GEMINI" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchange.Gemini.Spot,
        host: "api.gemini.com",
        path: "/v2/marketdata",
        port: 443,
        ping?: false
      }
    },
    ################################################################################
    #
    # hitbtc.com
    #
    "HITBTC" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchange.HitBTC.Spot,
        host: "api.hitbtc.com",
        path: "/api/3/ws/public",
        port: 443,
        ping?: false
      },
      # status: working
      # correctness: correct
      "PERP" => %{
        translation_scheme: Exchange.HitBTC.Futures,
        host: "api.hitbtc.com",
        path: "/api/3/ws/public",
        port: 443,
        ping?: false
      }
    },
    ################################################################################
    #
    # kraken.com
    #
    "KRAKEN" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchange.Kraken.Spot,
        host: "ws.kraken.com",
        path: "/",
        port: 443,
        ping?: false
      },
      # status: working
      # correctness: correct
      "PERP" => %{
        translation_scheme: Exchange.Kraken.Futures,
        host: "futures.kraken.com",
        path: "/ws/v1",
        port: 443,
        ping?: false
      },
      # status: working
      # correctness: correct
      "INVERSE" => %{
        translation_scheme: Exchange.Kraken.Inverse,
        host: "futures.kraken.com",
        path: "/ws/v1",
        port: 443,
        ping?: false
      }
    },
    ################################################################################
    #
    # poloniex.com
    #
    "POLONIEX" => %{
      # status: working
      # correctness: correct
      "SPOT" => %{
        translation_scheme: Exchange.Poloniex.Spot,
        host: "api2.poloniex.com",
        path: "/",
        port: 443,
        ping?: false
      }
    }
    ################################################################################
  }

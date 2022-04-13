import Config

# ecto storage repo
config :level4, ecto_repos: [Storage.Repo]

# ecto repo backend (postgres)
config :level4, Storage.Repo,
  database: "level4",
  username: "level4",
  password: "level4",
  hostname: "127.0.0.1",
  port: 5432,
  pool_size: 10

# http server host and port
config :level4,
  http_server: %{
    iface: {0, 0, 0, 0},
    port: 8080
    # add stream handlers?
    # ...
  }

# data sump host and port
config :level4,
  data_sump: %{
    host: '127.0.0.1',
    port: 5000
  }

# exchange translation scheme map
config :level4,
  exchanges: %{
    "BINANCE" => %{
      "SPOT" => fn ->
        translation_scheme = Exchanges.Binance.Spot
        url = "stream.binance.com"
        path = "/ws"
        port = 443
        ping? = false

        {translation_scheme, url, path, port, ping?}
      end
    },
    "BITFINEX" => %{
      "SPOT" => fn ->
        translation_scheme = Exchanges.Bitfinex.Trading
        url = "api-pub.bitfinex.com"
        path = "/ws/2"
        port = 443
        ping? = true

        {translation_scheme, url, path, port, ping?}
      end
    },
    "BITFLYER" => %{
      "SPOT" => fn ->
        translation_scheme = Exchanges.Bitflyer.Spot
        url = "ws.lightstream.bitflyer.com"
        path = "/json-rpc"
        port = 443
        ping? = true

        {translation_scheme, url, path, port, ping?}
      end
    },
    "BITMEX" => %{
      "SPOT" => fn ->
        translation_scheme = Exchanges.Bitmex
        url = "ws.bitmex.com"
        path = "/realtime"
        port = 443
        ping? = true

        {translation_scheme, url, path, port, ping?}
      end
    },
    "BITSTAMP" => %{
      "SPOT" => fn ->
        translation_scheme = Exchanges.Bitstamp
        url = "ws.bitstamp.net"
        path = "/"
        port = 443
        ping? = true

        {translation_scheme, url, path, port, ping?}
      end
    },
    "BYBIT" => %{
      "SPOT" => fn ->
        translation_scheme = Exchanges.Bybit.Spot
        url = "stream.bybit.com"
        path = "/spot/quote/ws/v2"
        port = 443
        ping? = true

        {translation_scheme, url, path, port, ping?}
      end,
      "PERP[USDT]" => fn ->
        translation_scheme = Exchanges.Bybit.Perp.USDT
        url = "stream.bybit.com"
        path = "/realtime_public"
        port = 443
        ping? = true

        {translation_scheme, url, path, port, ping?}
      end,
      "PERP[INVERSE]" => fn ->
        translation_scheme = Exchanges.Bybit.Perp.Inverse
        url = "stream.bybit.com"
        path = "/realtime"
        port = 443
        ping? = true

        {translation_scheme, url, path, port, ping?}
      end
    },
    "COINBASE-PRO" => %{
      "SPOT" => fn ->
        translation_scheme = Exchanges.Coinbase
        url = "ws-feed.exchange.coinbase.com"
        path = "/"
        port = 443
        ping? = false

        {translation_scheme, url, path, port, ping?}
      end
    },
    "FTX" => %{
      "SPOT" => fn ->
        translation_scheme = Exchanges.FTX
        url = "ftx.com"
        path = "/ws"
        port = 443
        ping? = true

        {translation_scheme, url, path, port, ping?}
      end
    },
    "GEMINI" => %{
      "SPOT" => fn ->
        translation_scheme = Exchanges.Gemini
        url = "api.gemini.com"
        path = "/v2/marketdata"
        port = 443
        ping? = false

        {translation_scheme, url, path, port, ping?}
      end
    },
    "HITBTC" => %{
      "SPOT" => fn ->
        translation_scheme = Exchanges.HitBTC
        url = "api.hitbtc.com"
        path = "/api/3/ws/public"
        port = 443
        ping? = false

        {translation_scheme, url, path, port, ping?}
      end
    },
    "KRAKEN" => %{
      "SPOT" => fn ->
        translation_scheme = Exchanges.Kraken
        url = "ws.kraken.com"
        path = "/"
        port = 443
        ping? = false

        {translation_scheme, url, path, port, ping?}
      end
    },
    "POLONIEX" => %{
      "SPOT" => fn ->
        translation_scheme = Exchanges.Poloniex
        url = "api2.poloniex.com"
        path = "/"
        port = 443
        ping? = false

        {translation_scheme, url, path, port, ping?}
      end
    }
  }

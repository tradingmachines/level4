import Config

config :level4, ecto_repos: [Storage.Repo]

config :level4, Storage.Repo,
  database: "level4",
  username: "level4",
  password: "level4",
  hostname: "127.0.0.1",
  port: 5432,
  pool_size: 25

config :level4, SchedulePairwiseCointegrationTests,
  overlap: true,
  timezone: :utc,
  jobs: [
    every_minute: [
      schedule: "* * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :do_pairwise_cointegration_tests,
           60
         ]}
    ],
    every_3_minutes: [
      schedule: "*/3 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :do_pairwise_cointegration_tests,
           180
         ]}
    ],
    every_5_minutes: [
      schedule: "*/5 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :do_pairwise_cointegration_tests,
           300
         ]}
    ],
    every_15_minutes: [
      schedule: "*/15 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :do_pairwise_cointegration_tests,
           900
         ]}
    ],
    every_30_minutes: [
      schedule: "*/30 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :do_pairwise_cointegration_tests,
           1800
         ]}
    ],
    every_hour: [
      schedule: "0 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :do_pairwise_cointegration_tests,
           3600
         ]}
    ],
    every_4_hours: [
      schedule: "0 */4 * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :do_pairwise_cointegration_tests,
           14400
         ]}
    ]
  ]

config :level4, ScheduleTimeSaleCandles,
  overlap: true,
  timezone: :utc,
  jobs: [
    every_minute: [
      schedule: "* * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           60
         ]}
    ],
    every_3_minutes: [
      schedule: "*/3 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           180
         ]}
    ],
    every_5_minutes: [
      schedule: "*/5 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           300
         ]}
    ],
    every_15_minutes: [
      schedule: "*/15 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           900
         ]}
    ],
    every_30_minutes: [
      schedule: "*/30 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           1800
         ]}
    ],
    every_hour: [
      schedule: "0 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           3600
         ]}
    ],
    every_2_hours: [
      schedule: "0 */2 * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           7200
         ]}
    ],
    every_4_hours: [
      schedule: "0 */4 * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           14400
         ]}
    ],
    every_6_hours: [
      schedule: "0 */6 * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           21600
         ]}
    ],
    every_12_hours: [
      schedule: "0 */12 * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           43200
         ]}
    ],
    every_day: [
      schedule: "0 0 * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           86400
         ]}
    ],
    every_3_days: [
      schedule: "0 0 */3 * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           259_200
         ]}
    ],
    every_week: [
      schedule: "0 0 * * 0",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_time_sale_candle,
           604_800
         ]}
    ]
  ]

config :level4, ScheduleSpreadCandles,
  overlap: true,
  timezone: :utc,
  jobs: [
    every_second: [
      schedule: {:extended, "* * * * *"},
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_spread_candles,
           1
         ]}
    ],
    every_3_seconds: [
      schedule: {:extended, "*/3 * * * *"},
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_spread_candles,
           3
         ]}
    ],
    every_5_seconds: [
      schedule: {:extended, "*/5 * * * *"},
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_spread_candles,
           5
         ]}
    ],
    every_15_seconds: [
      schedule: {:extended, "*/15 * * * *"},
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_spread_candles,
           15
         ]}
    ],
    every_30_seconds: [
      schedule: {:extended, "*/30 * * * *"},
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_spread_candles,
           30
         ]}
    ],
    every_minute: [
      schedule: "* * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_spread_candles,
           60
         ]}
    ],
    every_3_minutes: [
      schedule: "*/3 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_spread_candles,
           180
         ]}
    ],
    every_5_minutes: [
      schedule: "*/5 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_spread_candles,
           300
         ]}
    ],
    every_15_minutes: [
      schedule: "*/15 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_spread_candles,
           900
         ]}
    ],
    every_30_minutes: [
      schedule: "*/30 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_spread_candles,
           1800
         ]}
    ],
    every_hour: [
      schedule: "0 * * * *",
      task:
        {Markets, :tell_all_markets_to,
         [
           :make_spread_candles,
           3600
         ]}
    ]
  ]

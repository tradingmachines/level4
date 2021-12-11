defmodule Storage.Model.PairwiseCointegrationTest do
  use Ecto.Schema

  @primary_key false
  schema "pairwise_cointegration_tests" do
    belongs_to(:market_a, Storage.Model.Market)
    belongs_to(:market_b, Storage.Model.Market)
    field(:rss, :float)
    field(:coff_alpha, :float)
    field(:coff_beta, :float)
    field(:timeframe_in_seconds, :integer)
    field(:start_timestamp, :utc_datetime_usec)
    field(:end_timestamp, :utc_datetime_usec, virtual: true)
  end
end

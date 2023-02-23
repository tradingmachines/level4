defmodule Level4.MixProject do
  use Mix.Project

  def project do
    [
      app: :level4,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :kaffe],
      mod: {Level4, []}
    ]
  end

  defp deps do
    [
      {:libcluster, "~> 3.3"},
      {:kaffe, "~> 1.0"},
      {:grpc, "~> 0.5.0"},
      {:protobuf, "~> 0.11"},
      {:google_protos, "~> 0.1"},
      {:jason, "~> 1.4"}
    ]
  end
end

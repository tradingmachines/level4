defmodule Level4.MixProject do
  use Mix.Project

  def project do
    [
      app: :level4,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Level4, []},
      extra_applications: [
        :logger,
        :inets,
        :kaffe
      ]
    ]
  end

  defp deps do
    [
      {:gun, "~> 2.0.0-rc.2"},
      {:cowboy, "~> 2.9"},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:ecto_sql, "~> 3.0"},
      {:kaffe, "~> 1.0"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end

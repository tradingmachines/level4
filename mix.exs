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
      extra_applications: [:logger],
      mod: {Level4.Application, []}
    ]
  end

  defp deps do
    [
      {:gun, github: "ninenines/gun"},
      {:jason, "~> 1.2"}
    ]
  end
end

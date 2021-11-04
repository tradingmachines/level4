defmodule Level4.Application do
  @moduledoc """
  ...
  """

  use Application

  @doc """
  ...
  """
  @impl true
  def start(_type, _args) do
    IO.puts("starting level4 application")

    Supervisor.start_link(
      [
        {
          Registry,
          keys: :unique, name: Market.Supervisor.Registry
        },
        Level4.DynamicSupervisor
      ],
      strategy: :one_for_one
    )
  end
end

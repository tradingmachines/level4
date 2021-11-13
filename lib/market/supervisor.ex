defmodule Market.Supervisor do
  @moduledoc """
  A Market.Supervisor supervises a static tree consisting of a
  Market.Exchange process and a Market.Level2.Supervisor.

  The "exchange" process is responsible for receiving and writing
  changes to some persistent store. The "level2 supervisor" handles
  the mediator, orderbook, and websocket processes.
  """

  use Supervisor

  @doc """
  Starts and links a new Supervisor with the name returned from the
  process_name function above.
  """
  def start_link(a, init_arg) do
    Supervisor.start_link(
      __MODULE__,
      init_arg,
      name:
        {:via, Registry,
         {
           Market.Supervisor.Registry,
           Level4.Market.id(init_arg[:market])
         }}
    )
  end

  @doc """
  Init function for the Supervisor. Passes the child specs for the two children
  Market.Exchange and Market.Level2.Supervisor to Supervisor.init.
  """
  @impl true
  def init(init_arg) do
    IO.puts("starting market supervisor for #{Level4.Market.id(init_arg[:market])}")

    Supervisor.init(
      [
        %{
          id: Market.Exchange,
          start: {Market.Exchange, :start_link, [init_arg]},
          type: :worker
        },
        %{
          id: Market.Level2.Supervisor,
          start: {Market.Level2.Supervisor, :start_link, [init_arg]},
          type: :supervisor
        }
      ],
      strategy: :one_for_all
    )
  end
end

defmodule Market.Level2.WebSocket do
  @moduledoc """
  ...
  """

  use Task

  @doc """
  ...
  """
  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  @doc """
  ...
  """
  def run(arg) do
    nil
  end
end

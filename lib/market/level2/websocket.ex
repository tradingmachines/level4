defmodule Market.Level2.WebSocket do
  @moduledoc """
  ...
  """

  use GenServer

  @doc """
  ...
  """
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @doc """
  ...
  """
  @impl true
  def init(init_arg) do
    IO.puts("\t\tstarting websocket for #{Level4.Market.id(init_arg[:market])}")

    case init_arg[:market].exchange_ws_url
         |> to_charlist()
         |> :gun.open(
           443,
           %{
             :connect_timeout => 3000,
             :domain_lookup_timeout => 3000,
             :retry => 0,
             :protocols => [:http],
             :supervise => false,
             :http_opts => %{
               closing_timeout: 1000
             }
           }
         ) do
      {:ok, pid} ->
        IO.puts("ok")
        {:ok, {pid, init_arg[:market]}}

      {:error, reason} ->
        IO.puts("error")
        {:error, reason}
    end
  end

  @doc """
  ...
  """
  @impl true
  def terminate(reason, {conn_pid, _}) do
    IO.puts("terminating")
    :gun.shutdown(conn_pid)
  end

  @doc """
  ...
  """
  @impl true
  def handle_info(
        {:gun_up, conn_pid, protocol},
        {_, market}
      ) do
    IO.puts("connection open")
    :gun.ws_upgrade(conn_pid, "/")
    {:noreply, {conn_pid, market}}
  end

  # ...
  def handle_info(
        {:gun_upgrade, conn_pid, stream_ref, protocols, headers},
        {_, market}
      ) do
    IO.puts("connection upgrade success")

    {:ok, json_str} =
      market.translation_scheme.make_subscribe_message(
        market.major_symbol,
        market.quote_symbol
      )

    :gun.ws_send(conn_pid, stream_ref, {:text, json_str})
    IO.puts("sent subscribe message")

    {:noreply, {conn_pid, market}}
  end

  # ...
  def handle_info(
        {:gun_data, conn_pid, stream_ref, is_fin, data},
        {_, market}
      ) do
    IO.puts(inspect(data))
    {:noreply, {conn_pid, market}}
  end

  # ...
  def handle_info(
        {:gun_ws, conn_pid, stream_ref, frame},
        {_, market}
      ) do
    IO.puts(inspect(frame))
    {:noreply, {conn_pid, market}}
  end

  # ...
  def handle_info(
        {:gun_down, conn_pid, protocol, reason, killed_streams},
        {_, market}
      ) do
    IO.puts("connection closed")
    {:stop, "connection closed: #{reason}", {conn_pid, market}}
  end

  # ...
  def handle_info(
        {:gun_response, conn_pid, stream_ref, is_fin, status, headers},
        {_, market}
      ) do
    IO.puts("connection upgrade fail")
    {:stop, "connection upgrade fail: #{status}", {conn_pid, market}}
  end

  # ...
  def handle_info(
        {:gun_error, conn_pid, stream_ref, reason},
        {_, market}
      ) do
    IO.puts("connection error #{reason}")
    {:stop, "connection error: #{reason}", {conn_pid, market}}
  end
end

defmodule Level4.Server.ControlPanel do
  @moduledoc """
  ...
  """

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  # /control/symbols endpoint :: create and get symbols
  forward("/symbols", to: Level4.Server.ControlPanel.Symbols)

  # /control/exchanges endpoint :: create and get exchanges
  forward("/exchanges", to: Level4.Server.ControlPanel.Exchanges)

  # /control/markets endpoint :: create and get markets
  forward("/markets", to: Level4.Server.ControlPanel.Markets)

  # match root path "/control" and return error message
  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "nothing here")
  end
end

defmodule Level4.Server do
  @moduledoc """
  ...
  """

  use Plug.Router

  plug(:match)
  plug(:dispatch)

  # ...
  defp status(msg, :ok) do
    %{"meta" => meta} = msg
    %{msg | "meta" => %{meta | "status" => "ok"}}
  end

  # ...
  defp status(msg, :no_result) do
    %{"meta" => meta} = msg
    %{msg | "meta" => %{meta | "status" => "no result"}}
  end

  # ...
  defp status(msg, :input_error) do
    %{"meta" => meta} = msg
    %{msg | "meta" => %{meta | "status" => "bad input"}}
  end

  # ...
  defp status(msg, :internal_error) do
    %{"meta" => meta} = msg
    %{msg | "meta" => %{meta | "status" => "error"}}
  end

  # ...
  defp payload(msg, data) do
    %{msg | "payload" => data}
  end

  # ...
  defp initial_payload() do
    %{"meta" => %{"status" => nil}, "payload" => nil}
  end

  @doc """
  ...
  """
  # ok 204 no result
  def response({:ok, nil}) do
    # make the response json
    # the payload is nil
    # and the status is :no_result
    payload =
      initial_payload()
      |> payload(nil)
      |> status(:no_result)

    # encode as json string
    {:ok, json_str} = Jason.encode(payload)
    {204, json_str}
  end

  # ok 200
  def response({:ok, return_value}) do
    # make the response json
    # the payload is the return value
    # and the status is :ok
    payload =
      initial_payload()
      |> payload(return_value)
      |> status(:ok)

    # encode as json string
    {:ok, json_str} = Jason.encode(payload)
    {200, json_str}
  end

  # error 400 input error
  def response({:input_error, error_msg}) do
    # make the response json
    # the payload is an error message
    # and the status is :input_error
    payload =
      initial_payload()
      |> payload(error_msg)
      |> status(:input_error)

    # encode as json string
    {:ok, json_str} = Jason.encode(payload)
    {400, json_str}
  end

  # error 500 internal error
  def response({:internal_error, error_msg}) do
    # make the response json
    # the payload is an error message
    # and the status is :internal_error
    payload =
      initial_payload()
      |> payload(error_msg)
      |> status(:internal_error)

    # encode as json string
    {:ok, json_str} = Jason.encode(payload)
    {500, json_str}
  end

  # /control endpoints
  forward("/control", to: Level4.Server.ControlPanel)

  # match root path "/" and return error message
  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "wrong path. nothing here")
  end
end

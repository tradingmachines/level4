defmodule Level4.Server do
  use Plug.Router

  defp meta(msg) do
    Map.put(msg, "meta", %{})
  end

  defp status(msg, status) do
    %{"meta" => meta} = msg

    case status do
      :ok ->
        new_meta = Map.put(meta, "status", "ok")
        Map.put(msg, "meta", new_meta)

      :no_result ->
        new_meta = Map.put(meta, "status", "no result")
        Map.put(msg, "meta", new_meta)

      :input_error ->
        new_meta = Map.put(meta, "status", "bad input")
        Map.put(msg, "meta", new_meta)

      :internal_error ->
        new_meta = Map.put(meta, "status", "error")
        Map.put(msg, "meta", new_meta)
    end
  end

  defp payload(msg, data) do
    Map.put(msg, "payload", data)
  end

  plug(:match)
  plug(:dispatch)

  forward("/control", to: Level4.Server.ControlPanel)

  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "wrong path. nothing here")
  end

  def response(result) do
    {status, msg} =
      case result do
        {:ok, nil} ->
          {400,
           %{}
           |> payload(nil)
           |> (meta()
               |> status(:no_result))}

        {:ok, return_value} ->
          {200,
           %{}
           |> payload(return_value)
           |> (meta()
               |> status(:ok))}

        {:input_error, error_msg} ->
          {400,
           %{}
           |> payload(error_msg)
           |> (meta()
               |> status(:input_error))}

        {:internal_error, error_msg} ->
          {500,
           %{}
           |> payload(error_msg)
           |> (meta()
               |> status(:internal_error))}
      end

    {:ok, json_str} = Jason.encode(msg)
    {status, json_str}
  end
end

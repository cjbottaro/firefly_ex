defmodule Firefly.Plug do
  import Plug.Conn
  alias Firefly.{Job, Url}

  def init(app), do: app

  def call(conn, app) do
    try do
      job = Url.extract_job(app, conn.path_info)
        |> Job.decode
        |> Job.run

      conn
        |> add_resp_headers(app)
        |> send_resp(200, job.content)
        |> halt
    rescue
      e in [Firefly.Error.Encoding] ->
        send_resp(conn, 500, "failed to decode job: #{e.message}")
          |> halt
    end
  end

  defp add_resp_headers(conn, app) do
    headers = app.config.response_headers
    Enum.reduce(headers, conn, fn {name, value}, conn ->
      put_resp_header(conn, name, value)
    end)
  end

end

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
        |> send_resp(200, job.content)
        |> halt
    rescue
      e in [Firefly.Error.Encoding] ->
        send_resp(conn, 500, "failed to decode job: #{e.message}")
          |> halt
    end
  end

end

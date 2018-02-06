defmodule Firefly.Plug do
  import Plug.Conn
  alias Firefly.Job

  def init(app), do: app

  def call(conn, app) do
    job = conn.path_info
      |> Enum.at(1)
      |> Job.decode
      |> Job.run

    conn
      |> send_resp(200, job.content)
      |> halt
  end

end

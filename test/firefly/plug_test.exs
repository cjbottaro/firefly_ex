defmodule Firefly.PlugTest do
  use ExUnit.Case
  use Plug.Test
  alias Firefly.Job

  test "that it works" do
    options = Firefly.Plug.init(TextPlugin)
    path = TextApp.new_job
      |> TextApp.text("callie")
      |> TextApp.upcase
      |> TextApp.reverse
      |> Job.path

    conn = conn(:get, path, "")
      |> Firefly.Plug.call(options)

    assert conn.resp_body == "EILLAC"
    assert conn.halted
  end

end

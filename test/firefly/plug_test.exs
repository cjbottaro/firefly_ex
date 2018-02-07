defmodule Firefly.PlugTest do
  use ExUnit.Case
  use Plug.Test

  test "that it works" do
    options = Firefly.Plug.init(TextApp)

    url = TextApp.new_job
      |> TextApp.text("callie")
      |> TextApp.upcase
      |> TextApp.reverse
      |> TextApp.put_meta(%{name: "callie", ext: "txt"})
      |> TextApp.url

    conn = conn(:get, url, "")
      |> Firefly.Plug.call(options)

    assert conn.resp_body == "EILLAC"
    assert conn.halted
  end

  test "that it doesn't work" do
    options = Firefly.Plug.init(TextApp)

    url = "/badurl/callie.txt"

    conn = conn(:get, url, "")
      |> Firefly.Plug.call(options)

    assert conn.status == 500
    assert conn.resp_body =~ "failed to decode"
    assert conn.halted
  end

end

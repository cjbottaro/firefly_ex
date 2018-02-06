defmodule Firefly.Utils do

  def tsplit(string, options \\ []) do
    String.split(string, options) |> List.to_tuple
  end

  def tmpfile do
    basename = :crypto.strong_rand_bytes(5) |> Base.encode16(case: :lower)
    path = System.tmp_dir! |> Path.join(["firefly-", basename])
    if File.exists?(path) do
      tmpfile()
    else
      path
    end
  end

  def with_tmpfile(count \\ 1, func) do
    files = Enum.map(1..count, fn _ -> tmpfile() end)
    try do
      if count == 1 do
        files |> List.first |> func.()
      else
        files |> List.to_tuple |> func.()
      end
    after
      Enum.each(files, &File.rm/1)
    end
  end

end

defmodule Firefly.Utils do

  def tmpfile do
    basename = :crypto.strong_rand_bytes(5) |> Base.encode16(case: :lower)
    path = System.tmp_dir! |> Path.join(["firefly-", basename])
    if File.exists?(path) do
      tmpfile
    else
      path
    end
  end

end

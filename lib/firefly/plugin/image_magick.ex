defmodule Firefly.Plugin.ImageMagick do
  use Firefly.Plugin

  processor thumb(job, spec) do
    thumb = ExMagick.init!
      |> ExMagick.image_load!({:blob, job.content})
      |> ExMagick.thumb!(200, 200)
      |> ExMagick.image_dump!
    %{job | content: thumb}
  end

end

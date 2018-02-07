defmodule Firefly.Url do

  def make(app, job) do
    format = app.config.url_format
      |> String.replace(":job", Firefly.Job.encode(job))
    format = Enum.reduce(job.metadata, format, fn {k, v}, acc ->
      String.replace(acc, "%#{k}", to_string(v))
    end)

    [app.config.url_host, app.config.url_prefix, format]
      |> Enum.join("/")
      |> String.replace(~r/\/+/, "/")
  end

  def extract_job(app, path_info) do
    index = [app.config.url_prefix, app.config.url_format]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("/")
      |> String.split("/")
      |> Enum.find_index(& &1 == ":job")
    Enum.at(path_info, index)
  end

end

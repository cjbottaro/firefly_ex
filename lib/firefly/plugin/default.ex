defmodule Firefly.Plugin.Default do
  @moduledoc """
  Included in all apps by default.
  """

  use Firefly.Plugin

  @doc """
  Fetch content and metadata from storage backend.
  """
  def fetch(job, uid) do
    case job.app.config.storage.read(job.app, uid) do
      nil -> raise Firefly.Error.NotFound, {job.app.config.storage, uid}
      {content, metadata} -> %{ job | content: content, metadata: metadata }
    end
  end

  @doc """
  Fetch content from a url.

  Will populate `:"content-type"` in metdata if possible.
  """
  def fetch_url(job, url) do
    url = to_charlist(url)

    # Why is erlang shit so ugly?
    {:ok, resp} = :httpc.request(:get, {url, []}, [], [body_format: :binary])
    {{_, 200, 'OK'}, headers, body} = resp

    content_type = Enum.find_value(headers, fn {header, value} ->
      case header do
        'content-type' -> to_string(value)
        _ -> nil
      end
    end)

    if content_type do
      %{ job | content: body } |> put_meta(:"content-type", content_type)
    else
      %{ job | content: body }
    end
  end

  @doc """
  Read a file from the filesystem.
  """
  def read_file(job, path) do
    %{ job | content: path |> Path.expand |> File.read! }
  end

  @doc """
  Write a file to the filesystem.
  """
  def write_file(job, path) do
    path |> Path.expand |> File.write!(job.content)
    job
  end

  @doc """
  Puts byte size of content into metadata as `:size`.
  """
  def size(job) do
    put_meta(job, :size, byte_size(job.content))
  end

end

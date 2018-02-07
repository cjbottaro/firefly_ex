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

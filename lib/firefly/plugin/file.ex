defmodule Firefly.Plugin.File do

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

  def size(job) do
    metadata = Map.put(job.metadata, :size, byte_size(job.content))
    %{ job | metadata: metadata }
  end

end

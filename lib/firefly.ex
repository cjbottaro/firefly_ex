defmodule Firefly do
  @moduledoc """
  Documentation for Firefly.
  """

  use Firefly.Plugin

  @doc """
  (generator) Read a file from the filesystem.
  """
  generator fetch_file(job, path) do
    %{ job | content: path |> Path.expand |> File.read! }
  end

  @doc """
  (processor) Write a file to the filesystem.
  """
  processor write_file(job, path) do
    path |> Path.expand |> File.write!(job.content)
    job
  end

  analyzer size(job) do
    byte_size(job.content)
  end

end

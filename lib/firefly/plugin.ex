defmodule Firefly.Plugin do
  @moduledoc ~S"""
  Create your own plugins.

  Plugins are really simple. They are just modules with functions that take a
  `t:Firefly.Job.t/0` and return a `t:Firefly.Job.t/0`, optionally modifying
  the job's `contents` and/or `metadata`.

  Let's create a simple plugin to manipulate text.

  ```elixir
  defmodule MyTextPlugin do
    use Firefly.Plugin

    def generate(job, text) do
      %{ job | content: text }
    end

    def upcase(job) do
      new_content = String.upcase(job.content)
      %{ job | content: new_content }
    end

    def length(job) do
      length = String.length(job.content)
      metadata = Map.put(job.metadata, :length, length)
      %{ job | metadata: metadata }
    end
  end
  ```

  Now add it to your app's config.

  ```elixir
  use Mix.Config
  config :firefly, MyApp,
    plugins: [MyTextPlugin]
  ```

  And now we can use it.

  ```elixir
  job = MyApp.new_job
    |> MyApp.generate("hello")
    |> MyApp.upcase
    |> MyApp.length
    |> MyApp.run
  job.content # "HELLO"
  job.metadata.length # 5
  ```
  """

  defmacro __using__(_) do
    quote do
      import Firefly.Plugin
    end
  end

  @doc """
  Convenience function to update a job's metadata.

  ```elixir
  defmodule MyPlugin do
    use Firefly.Plugin
    def size(job) do
      put_meta(job, :size, byte_size(job.content))
    end
  end
  ```
  """
  @spec put_meta(
    job :: Firefly.Job.t, key :: atom | String.t, value :: term
  ) :: Firefly.Job.t
  def put_meta(job, key, value) do
    %{ job | metadata: Map.put(job.metadata, key, value) }
  end

  @doc """
  Convenience function to update a job's metadata.

  ```elixir
  defmodule MyPlugin do
    use Firefly.Plugin
    def size(job) do
      metadata = [size: byte_size(job.content)]
      merge_meta(job, metadata)
    end
  end
  ```
  """
  @spec merge_meta(
    job :: Firefly.Job.t, metadata :: Firefly.Storage.metadata | Keyword.t
  ) :: Firefly.Job.t
  def merge_meta(job, metadata) do
    %{ job | metadata: Map.merge(job.metadata, Map.new(metadata)) }
  end
end

defmodule Firefly.App do

  @typedoc """
  A Firefly app.

  ```elixir
  defmodule MyApp do
    use FireFly.App
  end
  ```
  `MyApp` would be this type.
  """
  @opaque t :: term

  defmacro __using__(_) do
    quote bind_quoted: [] do
      def init(config), do: config
      defoverridable [init: 1]

      def new_job(options \\ []) do
        %Firefly.Job{app: __MODULE__}
          |> Map.merge(options |> Map.new)
      end

      Firefly.App.delegates_for_app(__MODULE__)
        |> Enum.each(fn {sig, plugin} ->
          {name, _, args} = sig
          job = Enum.at(args, 0)
          args = Enum.slice(args, 1..-1)
          def unquote(sig) do
            Firefly.Job.add_step(
              unquote(job),
              unquote(plugin),
              unquote(name),
              unquote(args)
            )
          end
        end)

      Module.register_attribute(__MODULE__, :firefly_app, persist: true)
      Module.put_attribute(__MODULE__, :firefly_app, true)

      def config do
        Application.get_env(:firefly, __MODULE__)
      end

      def fetch(uid) do
        Firefly.App.fetch(__MODULE__, uid)
      end

      def store(content, metadata \\ %{}, options \\ []) do
        Firefly.App.store(__MODULE__, content, metadata, options)
      end

      def delete(uid) do
        Firefly.App.delete(__MODULE__, uid)
      end

      defdelegate run(job), to: Firefly.Job

    end
  end

  @doc ~S"""
  Convenience function to create a job with a fetch step.

  Equivalent to:
  ```elixir
  MyApp.new_job |> MyApp.fetch(uid)
  ```
  """
  @callback fetch(uid :: Firefly.Storage.uid) :: Firefly.Job.t

  @doc ~S"""
  Store content to app's storage backend.
  """
  @callback store(content :: Firefly.Storage.content) :: Firefly.Storage.uid

  @doc ~S"""
  Store content and metadata to app's storage backend.
  """
  @callback store(
    content :: Firefly.Storage.content,
    metadata :: Firefly.Storage.metadata
  ) :: Firefly.Storage.uid

  @doc ~S"""
  Store content and metadata to app's storage backend with options.
  """
  @callback store(
    content :: Firefly.Storage.content,
    metadata :: Firefly.Storage.metadata,
    options :: Firefly.Storage.options
  ) :: Firefly.Storage.uid

  @doc ~S"""
  Run a job for this app.

  Only unapplied steps in the job will be run.

  A new job is returned with all the steps marked as applied.
  """
  @callback run(job :: Firefly.Job.t) :: Firefly.Job.t

  @doc ~S"""
  Create a new job for this app.

  The job will be empty (zero steps).
  """
  @callback new_job :: Firefly.Job.t

  @doc false
  def fetch(app, uid) do
    app.new_job
      |> Firefly.Job.add_step(Firefly.Plugin.Storage, :fetch, [uid])
  end

  @doc false
  def store(app, content, metadata, options) do
    app.config.storage.write(app, content, metadata, options)
  end

  @doc false
  def delete(app, uid) do
    app.config.storage.delete(app, uid)
  end

  @doc false
  def delegates_for_app(app) do
    config = Application.get_env(:firefly, app, [])
    plugins = [Firefly.Plugin.Default | config[:plugins]]
    Enum.flat_map(plugins, &delegates_for_plugin/1)
  end

  defp delegates_for_plugin(plugin) do
    Enum.map(plugin.__info__(:functions), &{make_sig(&1), plugin})
  end

  defp make_sig({name, 0}) do
    "#{name}()"
      |> Code.string_to_quoted!
  end

  defp make_sig({name, arity}) do
    args = 1..arity
      |> Enum.map(&("a#{&1}"))
      |> Enum.join(",")
    "#{name}(#{args})"
      |> Code.string_to_quoted!
  end

end

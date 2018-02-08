defmodule Firefly.App do
  @moduledoc """
  Use to define a Firefly app.

  You interact with jobs and storage backends through an app.

  ```elixir
  defmodule MyFineApp do
    use Firefly.App
  end

  uid = MyFineApp.read_file("~/Downloads/puppy.png")
    |> MyFineApp.store

  job = MyFineApp.fetch(uid)
    |> MyFineApp.thumb("200x200#")
  ```

  Don't forget to configure your app with `Firefly.Configuration`.
  """

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

  @typedoc """
  Either a job or `{content, metadata}`.
  """
  @type storable :: Firefly.Job.t
    | {Firefly.Storage.content, Firefly.Storage.metadata}

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
        fetch(new_job(), uid) # fetch/2 is defined by default plugin.
      end

      def store(job, options \\ []) do
        Firefly.App.store(__MODULE__, job, options)
      end

      def delete(uid) do
        Firefly.App.delete(__MODULE__, uid)
      end

      def url(job) do
        Firefly.App.url(__MODULE__, job)
      end

      defdelegate run(job), to: Firefly.Job
      defdelegate put_meta(job, meta), to: Firefly.App

    end
  end

  @doc """
  Do dynamic configuration in this callback.
  """
  @callback init(config :: Keyword.t) :: Keyword.t

  @doc """
  App's configuration.
  """
  @callback config :: Firefly.Configuration.t

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

  @doc ~S"""
  Convenience function to create a job with a fetch step.

  Equivalent to:
  ```elixir
  MyApp.new_job |> MyApp.fetch(uid)
  ```
  """
  @callback fetch(uid :: Firefly.Storage.uid) :: Firefly.Job.t

  @doc ~S"""
  Save to app's storage backend.

  If `storable` is a `t:Firefly.Job.t/0` then it will be run first.
  """
  @callback store(storable) :: Firefly.Storage.uid

  @doc ~S"""
  Save to app's storage backend using options.

  If `storable` is a `t:Firefly.Job.t/0` then it will be run first.

  See the storage backend's documentation for valid options.
  """
  @callback store(
    storable,
    options :: Firefly.Storage.options
  ) :: Firefly.Storage.uid

  @doc false
  def store(app, {content, metadata}, options) do
    app.config.storage.write(app, content, metadata, options)
  end

  @doc false
  def store(app, %Firefly.Job{} = job, options) do
    %{content: content, metadata: metadata} = app.run(job)
    app.config.storage.write(app, content, metadata, options)
  end

  @doc ~S"""
  Delete an item from storage backend.
  """
  @callback delete(Firefly.Storage.uid) :: any

  @doc false
  def delete(app, uid) do
    app.config.storage.delete(app, uid)
  end

  @type metadata :: Keyword.t
    | Map.t
    | (Firefly.Job.metadata -> Firefly.Job.metadata)

  @doc """
  Update a job's metadata.

  This _does not_ create a job step; it updates the metadata immediately. It
  can be called before or after `c:Firefly.App.run/1`.

  If a keyword list or map is given, then the contents are merged with the
  existing metadata.

  Ex:
  ```elixir
    MyApp.new_job
      |> MyApp.read_file("~/Downloads/puppy.png")
      |> MyApp.put_meta(name: "puppy.png")
      |> MyApp.identify
      |> MyApp.run
      |> MyApp.put_meta(%{foo: "bar", bar: "baz"})
      |> MyApp.put_meta(fn meta ->
        Map.put(meta, :aspect_ratio, meta.width / meta.height)
      end)
  ```
  """
  @callback put_meta(job :: Firefly.Job.t, metadata) :: Firefly.Job.t

  @doc false
  def put_meta(job, func) when is_function(func) do
    %{ job | metadata: func.(job.metadata) }
  end

  @doc false
  def put_meta(job, metadata) do
    %{ job | metadata: Map.merge(job.metadata, Map.new(metadata))}
  end

  @doc ~S"""
  Generate a url that will run and serve a job.

  ```elixir
  url = MyApp.new_job
    |> MyApp.fetch(uid)
    |> MyApp.thumb("200x200#")
    |> MyApp.url
  ```

  Now assuming you have your `Firefly.Plug` setup, you can hit that url
  in a web browser and it should be served up.
  """
  @callback url(job :: Firefly.Job.t) :: String.t

  @doc false
  def url(app, job) do
    Firefly.Url.make(app, job)
  end

  @doc false
  def delegates_for_app(app) do
    config = Firefly.Configuration.get_compile_time(app)
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

defmodule Firefly.Storage do
  def __using__(_options) do
    quote do
      @behaviour Firefly.Storage
    end
  end

  @type app :: Firefly.App.t()
  @type config :: map
  @type uid :: String.t()
  @type content :: binary
  @type metadata :: map
  @type options :: Keyword.t()

  @callback init(app, config) :: any
  @callback write(app, content, metadata, options) :: uid
  @callback read(app, uid) :: {content, metadata} | nil
  @callback delete(app, uid) :: any

  @doc false
  def store(app, content, metadata, options) do
    app.config.storage.write(app, content, metadata, options)
  end

  @doc false
  def fetch(app, uid) do
    app.new_job
      |> Firefly.Job.add_step(Firefly.Plugin.Storage, :fetch, [uid])
  end

  @doc false
  def delete(app, uid) do
    app.config.storage.delete(app, uid)
  end

end

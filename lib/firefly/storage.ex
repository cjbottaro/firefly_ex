defmodule Firefly.Storage do
  @moduledoc """
  Behaviour for defining a storage backend.

  Firefly comes with a few storage backends out of the box, but feel free to
  contribute more (as seperate packages).
  """

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

end

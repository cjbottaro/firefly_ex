defmodule Firefly.Storage do
  def __using__(_options) do
    quote do
      @behaviour Firefly.Storage
    end
  end

  @type config :: map
  @type uid :: String.t()
  @type content :: binary
  @type metadata :: map
  @type options :: Keyword.t()

  @callback init(config) :: any
  @callback write(content, metadata, options) :: uid
  @callback read(uid) :: {content, metadata} | nil
  @callback delete(uid) :: any
end

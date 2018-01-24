defmodule Firefly.Storage.Ets do
  use Firefly.Storage

  def init(_options \\ []) do
    :ets.new(__MODULE__, [:public, :named_table])
  end

  def write(contents, metadata, _options) do
    uid = new_uid()
    :ets.insert(__MODULE__, {uid, contents, metadata})
    uid
  end

  def read(uid) do
    case :ets.lookup(__MODULE__, uid) do
      [] -> nil
      [{_, content, metadata} | []] -> {content, metadata}
    end
  end

  def delete(uid) do
    :ets.delete(__MODULE__, uid)
  end

  defp new_uid do
    :crypto.strong_rand_bytes(5) |> Base.encode16()
  end
end

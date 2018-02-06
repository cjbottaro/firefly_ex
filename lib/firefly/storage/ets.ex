defmodule Firefly.Storage.Ets do
  use Firefly.Storage

  def init(app) do
    :ets.new(app, [:public, :named_table])
  end

  def write(app, contents, metadata, _options) do
    uid = new_uid()
    :ets.insert(app, {uid, contents, metadata})
    uid
  end

  def read(app, uid) do
    case :ets.lookup(app, uid) do
      [] -> nil
      [{_, content, metadata} | []] -> {content, metadata}
    end
  end

  def delete(app, uid) do
    :ets.delete(app, uid)
  end

  defp new_uid do
    :crypto.strong_rand_bytes(5) |> Base.encode16()
  end
end

defmodule Firefly.Plugin.Storage do
  use Firefly.Plugin

  def fetch(job, uid) do
    {content, metadata} = job.app.config.storage.read(job.app, uid)
    %{ job | content: content, metadata: metadata }
  end

end

defmodule TextPlugin do
  use Firefly.Plugin

  def text(job, string) do
    %{job | content: string}
  end

  def upcase(job) do
    %{job | content: String.upcase(job.content)}
  end

  def reverse(job) do
    %{job | content: String.reverse(job.content)}
  end

end

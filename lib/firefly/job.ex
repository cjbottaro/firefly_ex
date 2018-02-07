defmodule Firefly.Job do
  @moduledoc """
  What apps work with.
  """

  defstruct [app: nil, steps: [], content: "", metadata: %{}]

  alias Firefly.Step

  @type t :: %__MODULE__{
    app: Firefly.App.t,
    content: Firefly.Storage.content,
    metadata: Firefly.Storage.metadata,
    steps: [Firefly.Step.t]
  }

  @doc false
  def new do
    %__MODULE__{}
  end

  @doc false
  def add_step(%{steps: steps} = job, plugin, func, args) do
    step = %Step{plugin: plugin, func: func, args: args}
    %{job | steps: [step | steps]}
  end

  @doc false
  def run(job) do
    steps = Enum.reverse(job.steps)
    run(job, steps)
  end

  @doc false
  def encode(job) do
    steps = job.steps
      |> Enum.map(fn step -> {step.plugin, step.func, step.args} end)
    {job.app, steps}
      |> :erlang.term_to_binary
      |> :zlib.zip
      |> Base.url_encode64
  end

  @doc false
  def decode(encoded) do
    try do
      encoded
        |> Base.url_decode64!
        |> :zlib.unzip
        |> :erlang.binary_to_term
    rescue
      _ -> raise Firefly.Error.Encoding, message: encoded
    else
      {app, steps} ->
        steps = Enum.map(steps, &Step.from_tuple/1)
        %__MODULE__{app: app, steps: steps}
    end
  end

  defp run(job, []), do: job
  defp run(job, [%{applied: true} | steps]), do: run(job, steps)
  defp run(job, [step | steps]) do
    apply(step.plugin, step.func, [job] ++ step.args)
      |> mark_step_applied
      |> run(steps)
  end

  defp mark_step_applied(job) do
    %{job | steps: mark_next_step(job.steps)}
  end

  defp mark_next_step([]), do: []
  defp mark_next_step([%{applied: false} = step | rest]) do
    [%{step | applied: true} | rest]
  end
  defp mark_next_step([step | rest]), do: [step | mark_next_step(rest)]

end

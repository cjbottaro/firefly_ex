defmodule Firefly.Job do
  defstruct [steps: [], content: "", metadata: %{}]

  alias Firefly.Step

  @type t :: %__MODULE__{}

  def new do
    %__MODULE__{}
  end

  def add_step(%{steps: steps} = job, module, func, args) do
    step = %Step{module: module, func: func, args: args}
    %{job | steps: [step | steps]}
  end

  def run(job) do
    steps = Enum.reverse(job.steps)
    run(job, steps)
  end

  def encode(job) do
    job.steps
      |> Enum.map(fn job -> {job.module, job.func, job.args} end)
      |> :erlang.term_to_binary
      |> :zlib.zip
      |> Base.url_encode64
  end

  def decode(encoded_steps) do
    steps = encoded_steps
      |> Base.url_decode64!
      |> :zlib.unzip
      |> :erlang.binary_to_term
      |> Enum.map(&Step.from_tuple/1)
    %__MODULE__{steps: steps}
  end

  defp run(job, []), do: job
  defp run(job, [%{applied: true} | steps]), do: run(job, steps)
  defp run(job, [step | steps]) do
    result = apply(step.module, :"apply_#{step.func}", [job] ++ step.args)

    if Step.type(step) == :analyzer do
      result
    else
      mark_step_applied(result) |> run(steps)
    end
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

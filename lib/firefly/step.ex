defmodule Firefly.Step do
  @moduledoc """
  A step in a job.
  """
  
  defstruct [plugin: nil, func: nil, args: [], applied: false]

  @type t :: %__MODULE__{
    plugin: module,
    func: atom,
    args: [term],
    applied: boolean
  }

  @doc false
  def from_tuple({plugin, func, args}) do
    %__MODULE__{plugin: plugin, func: func, args: args}
  end
end

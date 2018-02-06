defmodule Firefly.Step do
  defstruct [module: nil, func: nil, args: [], applied: false]

  def from_tuple({module, func, args}) do
    %__MODULE__{module: module, func: func, args: args}
  end
end

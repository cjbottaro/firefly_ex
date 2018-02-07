defmodule Firefly.Error do
  @moduledoc false

  defmodule NotFound do
    defexception [:storage, :uid]

    def exception({storage, uid}) do
      %__MODULE__{storage: storage, uid: uid}
    end

    def message(e) do
      module = e.storage |> Module.split |> Enum.join(".")
      "#{module}, #{e.uid}"
    end
  end

end

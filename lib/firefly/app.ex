defmodule Firefly.App do

  defmacro __using__(_) do
    plugins = [Firefly, Firefly.Plugin.ImageMagick]

    delegates = Enum.reduce(plugins, [], fn mod, acc ->
      fn_names = mod.generators ++ mod.processors ++ mod.analyzers
      Enum.reduce(mod.__info__(:functions), acc, fn {fn_name, arity}, acc ->
        if Enum.member?(fn_names, fn_name) do
          [{mod, make_sig(fn_name, arity)} | acc]
        else
          acc
        end
      end)
    end)

    # bind_quoted is necessary to make this work.
    quote bind_quoted: [delegates: delegates] do
      Enum.each(delegates, fn {mod, sig} ->
        defdelegate unquote(sig), to: mod
      end)
    end
  end

  defp make_sig(name, 0) do
    "#{name}()"
      |> Code.string_to_quoted!
      |> Macro.escape
  end

  defp make_sig(name, arity) do
    args = 1..arity
      |> Enum.map(&("a#{&1}"))
      |> Enum.join(",")
    "#{name}(#{args})"
      |> Code.string_to_quoted!
      |> Macro.escape
  end

end

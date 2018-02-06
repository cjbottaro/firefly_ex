defmodule Firefly.App do

  defmacro __using__(_) do
    quote bind_quoted: [] do
      def init(config), do: config
      defoverridable [init: 1]

      def new_job do
        %Firefly.Job{app: __MODULE__}
      end

      Firefly.App.delegates_for_app(__MODULE__)
        |> Enum.each(fn {sig, plugin} ->
          {name, _, args} = sig
          job = Enum.at(args, 0)
          args = Enum.slice(args, 1..-1)
          def unquote(sig) do
            Firefly.Job.add_step(
              unquote(job),
              unquote(plugin),
              unquote(name),
              unquote(args)
            )
          end
        end)
    end
  end

  def delegates_for_app(app) do
    Application.get_env(:firefly, app, [])
      |> Access.get(:plugins, [])
      |> Enum.flat_map(&delegates_for_plugin/1)
  end

  defp delegates_for_plugin(plugin) do
    Enum.map(plugin.__info__(:functions), &{make_sig(&1), plugin})
  end

  defp make_sig({name, 0}) do
    "#{name}()"
      |> Code.string_to_quoted!
  end

  defp make_sig({name, arity}) do
    args = 1..arity
      |> Enum.map(&("a#{&1}"))
      |> Enum.join(",")
    "#{name}(#{args})"
      |> Code.string_to_quoted!
  end

end

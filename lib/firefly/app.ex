defmodule Firefly.App do

  @opaque t :: term

  defmacro __using__(_) do
    quote bind_quoted: [] do
      def init(config), do: config
      defoverridable [init: 1]

      def new_job(options \\ []) do
        %Firefly.Job{app: __MODULE__}
          |> Map.merge(options |> Map.new)
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

      Module.register_attribute(__MODULE__, :firefly_app, persist: true)
      Module.put_attribute(__MODULE__, :firefly_app, true)

      def config, do: Application.get_env(:firefly, __MODULE__)

      def store(content, metadata, options \\ []) do
        Firefly.Storage.store(__MODULE__, content, metadata, options)
      end

      def fetch(uid) do
        Firefly.Storage.fetch(__MODULE__, uid)
      end

      def delete(uid) do
        Firefly.Storage.delete(__MODULE__, uid)
      end

    end
  end

  def delegates_for_app(app) do
    config = Application.get_env(:firefly, app, [])
    plugins = [Firefly.Plugin.Storage | config[:plugins]] |> IO.inspect
    Enum.flat_map(plugins, &delegates_for_plugin/1)
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

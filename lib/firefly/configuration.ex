defmodule Firefly.Configuration do

  def init do
    Application.get_all_env(:firefly) |> Enum.each(&configure/1)
  end

  defguardp is_app?(app, options) when is_atom(app) and is_list(options)

  defp configure({:included_applications, _}), do: nil
  defp configure({app, options}) when is_app?(app, options) do
    # maybe_create_app(app)
    # config = resolve_config(app, options)
    # Code.compiler_options(ignore_module_conflict: true)
    # defmodule app, do: use Firefly.App, config
    # Code.compiler_options(ignore_module_conflict: false)
  end
  defp configure(_), do: nil

  defp maybe_create_app(app) do
    if !Code.ensure_loaded?(app) do
      defmodule app, do: use Firefly.App
    end
  end

  defp resolve_config(app, config) do
    config = app.init(config)
    plugins = [Firefly.Plugin.File] ++ config[:plugins] |> Enum.uniq
    Keyword.put(config, :plugins, plugins)
  end

end

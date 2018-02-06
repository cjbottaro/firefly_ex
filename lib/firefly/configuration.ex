defmodule Firefly.Configuration do

  def init do
    Application.get_all_env(:firefly)
      |> Enum.filter(&is_app?/1)
      |> Enum.each(&configure/1)
  end

  defp configure({app, options}) do
    config = resolve_config(app, options)
    Application.put_env(:firefly, app, config)
    app.config.storage.init(app)
  end

  defp is_app?({module, _options}) do
    module == Module.concat(Elixir, module) and
    module.__info__(:attributes)
      |> Enum.any?(& &1 == {:firefly_app, [true]})
  end

  defp resolve_config(app, config) do
    config
      |> resolve_env_vars
      |> app.init
      |> Map.new
  end

  def resolve_env_vars(config) do
    Enum.map(config, fn {k, v} ->
      case v do
        {:system, name} -> {k, System.get_env(name)}
        {:system, name, default} -> {k, System.get_env(name) || default}
        _ -> {k, v}
      end
    end)
  end

end

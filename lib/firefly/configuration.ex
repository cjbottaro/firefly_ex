defmodule Firefly.Configuration do

  @type t :: %{optional(atom) => term}

  @defaults [
    storage: nil,
    plugins: [],
    url_host: nil,
    url_prefix: nil,
    url_format: ":job"
  ]

  @doc false
  # Only meant to be called at compile time, i.e. when compiling modules
  # that use Firefly.App.
  def get_compile_time(app) do
    config = Application.get_env(:firefly, app, [])
    Keyword.merge(@defaults, config)
  end

  @doc false
  # Call from application startup. Resolves dynamic config, writes final
  # config back to Application env. Also initializes storage backends, etc.
  def init do
    Application.get_all_env(:firefly)
      |> Enum.filter(&is_app?/1)
      |> Enum.each(&configure/1)
  end

  defp configure({app, options}) do
    config = Keyword.merge(@defaults, options)
    config = resolve_config(app, config)
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

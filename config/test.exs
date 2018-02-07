use Mix.Config

config :firefly, TextApp,
  storage: Firefly.Storage.Ets,
  plugins: [TextPlugin],
  url_format: ":job/%name.%ext"

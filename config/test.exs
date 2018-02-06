use Mix.Config

config :firefly, TextApp,
  storage: Firefly.Storage.Ets,
  plugins: [TextPlugin]

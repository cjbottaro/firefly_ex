use Mix.Config

config :firefly, FireflyApp,
  storage: Firefly.Storage.Ets,
  plugins: [Firefly.Plugin.ImageMagick]

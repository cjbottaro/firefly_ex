use Mix.Config

config :firefly, FireflyRepo,
  storage: Firefly.Storage.Ets,
  plugins: [Firefly.Plugin.ImageMagick]

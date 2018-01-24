defmodule Firefly.MixProject do
  use Mix.Project

  def project do
    [
      app: :firefly,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description: "Image/asset management for Elixir, heavily inspired by Ruby's Dragonfly",
      package: [
        maintainers: ["Christopher J. Bottaro"],
        licenses: ["GNU General Public License v3.0"],
        links: %{"GitHub" => "https://github.com/cjbottaro/firefly_ex"},
      ],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Firefly.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exmagick, "~> 0.0.5"},
      {:ex_doc, "~> 0.18.1", only: :dev},
    ]
  end
end

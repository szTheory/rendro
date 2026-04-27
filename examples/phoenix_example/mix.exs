defmodule PhoenixExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_example,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {PhoenixExample.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:plug, "~> 1.14"},
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:rendro, path: "../.."}
    ]
  end
end

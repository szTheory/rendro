defmodule Rendro.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/szTheory/rendro"

  def project do
    [
      app: :rendro,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      name: "Rendro",
      description: "Pure-Elixir, Phoenix-first PDF/document generation with deterministic layout and pagination",
      source_url: @source_url,
      docs: docs(),
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  def cli do
    [
      preferred_envs: [ci: :test]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:telemetry, "~> 1.4"},
      {:stream_data, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      ci: ["compile --warnings-as-errors", "test", "credo --strict", "dialyzer"]
    ]
  end

  defp docs do
    [
      main: "Rendro",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end
end

defmodule Rendro.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/szTheory/rendro"

  def project do
    [
      app: :rendro,
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      name: "Rendro",
      description:
        "Pure-Elixir, Phoenix-first PDF/document generation with deterministic layout and pagination",
      source_url: @source_url,
      docs: docs(),
      dialyzer: [plt_add_apps: [:mix, :stream_data]]
    ]
  end

  def cli do
    [
      preferred_envs: [ci: :test, verify: :test]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:telemetry, "~> 1.4"},
      {:phoenix, "~> 1.7", optional: true},
      {:plug, "~> 1.14", optional: true},
      {:oban, "~> 2.17", optional: true},
      {:stream_data, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:req, "~> 0.5", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      ci: [
        "format --check-formatted",
        "hex.build",
        "compile --warnings-as-errors",
        "test",
        "docs",
        "credo --strict",
        "dialyzer"
      ]
    ]
  end

  defp package do
    [
      licenses: ["UNLICENSED"],
      links: %{"GitHub" => @source_url},
      files: ~w(
        lib
        priv/branded
        guides
        .formatter.exs
        mix.exs
        README.md
        NOTICE
        CHANGELOG.md
      )
    ]
  end

  defp docs do
    [
      main: "Rendro",
      source_url: @source_url,
      extras: [
        "README.md",
        "guides/integrations.md",
        "guides/branding.md"
      ]
    ]
  end
end

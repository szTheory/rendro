defmodule Rendro.MixProject do
  use Mix.Project

  @version "0.3.0"
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
      homepage_url: @source_url,
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
      {:harfbuzz_ex, "~> 1.2"},
      {:unicode_data, "~> 0.8.0"},
      {:phoenix, "~> 1.7", optional: true},
      {:plug, "~> 1.14", optional: true},
      {:oban, "~> 2.17", optional: true},
      {:stream_data, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:req, "~> 0.5", only: [:dev, :test]},
      {:jsv, "~> 0.18", only: [:dev, :test], runtime: false},
      {:yaml_elixir, "~> 2.12", only: [:dev, :test], runtime: false}
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
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(
        lib
        priv/branded
        guides
        .formatter.exs
        mix.exs
        README.md
        LICENSE
        NOTICE
        CHANGELOG.md
      )
    ]
  end

  defp docs do
    [
      main: "readme",
      skip_undefined_reference_warnings_on: [
        "guides/branding.md",
        "guides/integrations.md",
        "lib/rendro/document.ex",
        "lib/rendro/font_registry.ex",
        "lib/rendro.ex"
      ],
      source_url: @source_url,
      extras: [
        "README.md",
        "guides/integrations.md",
        "guides/branding.md",
        "guides/api_stability.md"
      ],
      groups_for_extras: [
        Guides: [
          "guides/branding.md",
          "guides/integrations.md"
        ],
        Policies: [
          "guides/api_stability.md"
        ]
      ],
      groups_for_modules: [
        "Core Builder API": [
          Rendro,
          Rendro.Document,
          Rendro.PageTemplate,
          Rendro.Section,
          Rendro.Block,
          Rendro.Region,
          Rendro.Text,
          Rendro.Table,
          Rendro.Image,
          Rendro.Page
        ],
        "Canonical Recipes": [
          Rendro.Recipes,
          Rendro.Recipes.Invoice,
          Rendro.Recipes.BrandedInvoice
        ],
        "Ecosystem Adapters": [
          Rendro.Adapters.Phoenix,
          Rendro.Adapters.Oban.RenderWorker,
          Rendro.Adapters.Threadline,
          Rendro.Adapters.Mailglass,
          Rendro.Adapters.Accrue,
          Rendro.Adapters.Qpdf
        ],
        Protection: [
          Rendro.Protect,
          Rendro.Protect.Adapter
        ],
        Signing: [
          Rendro.Sign,
          Rendro.Sign.Adapter,
          Rendro.Adapters.PyHanko,
          Rendro.Adapters.Pdfsig
        ],
        "Inspection & Observability": [
          Rendro.Inspector,
          Rendro.Error,
          Rendro.Telemetry
        ],
        Registries: [
          Rendro.FontRegistry,
          Rendro.AssetRegistry
        ]
      ]
    ]
  end
end

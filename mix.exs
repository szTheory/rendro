defmodule Rendro.MixProject do
  use Mix.Project

  @version "1.0.0"
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
      dialyzer: [plt_add_apps: [:mix, :stream_data, :jsv, :yaml_elixir]]
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
      {:decimal, ">= 2.3.0 and < 4.0.0"},
      {:phoenix, "~> 1.7", optional: true},
      {:plug, "~> 1.14", optional: true},
      {:oban, "~> 2.17", optional: true},
      {:stream_data, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:req, "~> 0.5", only: [:dev, :test]},
      {:jsv, "~> 0.18", only: [:dev, :test], runtime: false},
      {:yaml_elixir, "~> 2.12", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}
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
      before_closing_head_tag: &before_closing_head_tag/1,
      skip_undefined_reference_warnings_on: [
        "guides/branding.md",
        "guides/integrations.md",
        "guides/page_primitive.md",
        "guides/recipes.md",
        "guides/user_flows_and_jtbd.md",
        "lib/rendro/document.ex",
        "lib/rendro/font_registry.ex",
        "lib/rendro.ex"
      ],
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "guides/integrations.md",
        "guides/branding.md",
        "guides/api_stability.md",
        "guides/upgrading_to_1.0.md",
        "guides/viewer_evidence.md",
        "guides/page_primitive.md",
        "guides/recipes.md",
        "guides/user_flows_and_jtbd.md"
      ],
      groups_for_extras: [
        Guides: [
          "guides/branding.md",
          "guides/integrations.md",
          "guides/user_flows_and_jtbd.md"
        ],
        Policies: [
          "guides/api_stability.md",
          "guides/upgrading_to_1.0.md",
          "guides/viewer_evidence.md"
        ],
        "Recipes & Primitives": [
          "guides/page_primitive.md",
          "guides/recipes.md"
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
          Rendro.Page,
          Rendro.Cell,
          Rendro.Row,
          Rendro.Component,
          Rendro.Metadata,
          Rendro.FontRegistry,
          Rendro.AssetRegistry,
          Rendro.EmbeddedFileRegistry,
          Rendro.RunningContent,
          Rendro.Error
        ],
        "Canonical Recipes": [
          Rendro.Recipes,
          Rendro.Recipes.Invoice,
          Rendro.Recipes.BrandedInvoice,
          Rendro.Recipes.Statement,
          Rendro.Recipes.Receipt,
          Rendro.Recipes.Certificate
        ],
        "Ecosystem Adapters": [
          Rendro.Adapters.Phoenix,
          Rendro.Adapters.Oban.RenderWorker,
          Rendro.Adapters.Threadline,
          Rendro.Adapters.Mailglass,
          Rendro.Adapters.Accrue,
          Rendro.Adapters.Qpdf,
          Rendro.Adapters.PyHanko,
          Rendro.Adapters.Pdfsig
        ],
        Protection: [
          Rendro.Protect,
          Rendro.Protect.Adapter
        ],
        Signing: [
          Rendro.Sign,
          Rendro.Sign.Adapter
        ],
        "Inspection & Observability": [
          Rendro.Inspector,
          Rendro.Telemetry
        ],
        Storage: [
          Rendro.Storage,
          Rendro.Storage.Local
        ]
      ]
    ]
  end

  defp before_closing_head_tag(:html) do
    """
    <style>
      .note.tier-stable { background-color: #d4edda; color: #155724; border-color: #c3e6cb; }
      .note.tier-adapter { background-color: #cce5ff; color: #004085; border-color: #b8daff; }
    </style>
    <script>
      document.querySelectorAll('.note').forEach(function(s) {
        if (s.textContent.includes('stable')) s.classList.add('tier-stable');
        if (s.textContent.includes('adapter')) s.classList.add('tier-adapter');
      });
    </script>
    """
  end

  defp before_closing_head_tag(_), do: ""
end

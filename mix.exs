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
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix, :stream_data, :jsv, :yaml_elixir, :livebook],
        plt_core_path: "priv/plts",
        plt_local_path: "priv/plts"
      ]
    ]
  end

  def cli do
    [
      preferred_envs: [
        ci: :test,
        "ci.fast": :test,
        "ci.proofs": :test,
        "ci.advisory": :test,
        "verify.flake": :test,
        "test.all": :test,
        verify: :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Catalog tooling is deliberately dev/test-only: static docs generation must
  # not widen the runtime package's public compilation surface.
  defp elixirc_paths(:test), do: ["lib", "dev", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "dev"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:telemetry, "~> 1.4"},
      {:harfbuzz_ex, "~> 1.2", optional: true},
      {:unicode, "~> 1.22"},
      {:decimal, ">= 2.3.0 and < 4.0.0"},
      {:phoenix, "~> 1.7", optional: true},
      {:plug, "~> 1.14", optional: true},
      {:oban, "~> 2.17", optional: true},
      {:stream_data, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:livebook, "~> 0.19.8", only: [:dev, :test], runtime: false},
      {:req, "~> 0.5", only: [:dev, :test]},
      {:jsv, "~> 0.18", only: [:dev, :test], runtime: false},
      {:yaml_elixir, ">= 2.11.0 and < 3.0.0", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      # Mix discovers source tasks before compilation. These aliases compile the
      # dev-only task modules first, keeping catalog tooling out of `lib/` and
      # therefore out of the runtime package.
      "rendro.catalog.gen": [&catalog_gen/1],
      "rendro.catalog.check": [&catalog_check/1],
      ci: ["ci.fast", "ci.proofs"],
      "ci.fast": [
        "format --check-formatted",
        "hex.build",
        "compile --warnings-as-errors",
        "test --exclude quarantine --slowest 10",
        "docs --warnings-as-errors",
        "credo --strict",
        "dialyzer"
      ],
      "ci.proofs": [
        "test --include live_pdf_tools test/rendro/adapters/forms_viewer_evidence_live_test.exs test/rendro/adapters/embedded_files_viewer_evidence_live_test.exs test/rendro/adapters/links_viewer_evidence_live_test.exs test/rendro/adapters/protection_viewer_evidence_live_test.exs test/rendro/adapters/signature_widget_viewer_evidence_live_test.exs test/rendro/adapters/signed_artifact_viewer_evidence_live_test.exs test/rendro/adapters/trust_sensitive_viewer_evidence_live_test.exs",
        "test --include live_signing test/rendro/adapters/signing_live_test.exs",
        "test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs",
        "run scripts/release_preflight_proof.exs --current-version-tag --skip-ci --skip-security-audits --worktree /tmp/rendro-release-proof"
      ],
      "ci.advisory": [
        "test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs",
        "rendro.launch_artifacts.check",
        "rendro.comparison.check",
        "rendro.livebook.check",
        "cmd npm ci --prefix scripts/pdfjs_observer",
        "cmd node scripts/pdfjs_observer/observe.mjs --check",
        "deps.audit",
        "hex.audit"
      ],
      "verify.flake": ["test --include quarantine --only quarantine --slowest 10"],
      "test.all": [
        "test --include quarantine --include live_pdf_tools --include live_signing --include raster_snapshot --slowest 10"
      ]
    ]
  end

  defp catalog_gen(args) do
    Mix.Task.run("compile")
    Mix.Tasks.Rendro.Catalog.Gen.run(args)
  end

  defp catalog_check(args) do
    Mix.Task.run("compile")
    Mix.Tasks.Rendro.Catalog.Check.run(args)
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(
        lib
        assets/rendro
        priv/branded
        priv/examples
        priv/fonts
        bench/results
        guides
        .formatter.exs
        mix.exs
        README.md
        ADOPTION.md
        LICENSE
        NOTICE
        CHANGELOG.md
      )
    ]
  end

  defp docs do
    [
      main: "readme",
      assets: %{"assets" => "assets"},
      before_closing_head_tag: &before_closing_head_tag/1,
      skip_undefined_reference_warnings_on: [
        "CHANGELOG.md",
        "guides/branding.md",
        "guides/integrations.md",
        "guides/comparison.md",
        "guides/livebook/first_invoice.livemd",
        "guides/page_primitive.md",
        "guides/recipes.md",
        "guides/theming.md",
        "guides/user_flows_and_jtbd.md",
        "lib/rendro/document.ex",
        "lib/rendro/font_registry.ex",
        "lib/rendro.ex"
      ],
      skip_code_autolink_to: [
        "Rendro.PDF.CidFont",
        "Rendro.PDF.FontSubsetter",
        "Rendro.Format",
        "Rendro.Color.validate/1"
      ],
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "ADOPTION.md",
        "CHANGELOG.md",
        "guides/integrations.md",
        "guides/branding.md",
        "guides/theming.md",
        "guides/api_stability.md",
        "guides/upgrading_to_1.0.md",
        "guides/viewer_evidence.md",
        "guides/page_primitive.md",
        "guides/recipes.md",
        "guides/user_flows_and_jtbd.md",
        "guides/comparison.md",
        "guides/livebook/first_invoice.livemd"
      ],
      groups_for_extras: [
        Guides: [
          "guides/branding.md",
          "guides/theming.md",
          "guides/integrations.md",
          "guides/user_flows_and_jtbd.md"
        ],
        Evaluation: [
          "guides/comparison.md",
          "guides/livebook/first_invoice.livemd"
        ],
        Policies: [
          "ADOPTION.md",
          "CHANGELOG.md",
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
          Rendro.Error,
          Rendro.Text.Shaper,
          Rendro.Text.Shaper.Simple,
          Rendro.PDF.Font
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
          Rendro.Adapters.HarfBuzz,
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
      img[src^="assets/rendro/"] {
        background: #ffffff;
        border: 1px solid #d8d2c3;
        box-shadow: 0 8px 24px rgba(16, 24, 39, 0.08);
      }
      @media (prefers-color-scheme: dark) {
        img[src^="assets/rendro/"] {
          border-color: #1f2937;
          box-shadow: 0 8px 24px rgba(0, 0, 0, 0.28);
        }
      }
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

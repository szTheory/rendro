defmodule Mix.Tasks.Rendro.Api.Gen do
  use Mix.Task

  @shortdoc "Generate priv/public_api.json from @moduledoc tags: in source"

  @moduledoc """
  Introspects all public Rendro modules for their `tags: [:stable|:adapter]`
  annotation and writes `priv/public_api.json`.

  Run this task after changing module tiers (adding/removing `tags: [:stable]`
  or `tags: [:adapter]` to `@moduledoc` attributes). The generator reads live
  BEAM metadata via `Code.fetch_docs/1` so results reflect the last compile.

  The output is deterministic: running this task twice produces byte-identical
  output. Module keys and function/type lists are sorted alphabetically so the
  file can be diffed and committed without spurious ordering changes.

  Conditional adapters (Threadline, Mailglass, Accrue, Phoenix, Oban.RenderWorker)
  are recompiled before introspection to ensure they appear in the manifest when
  their optional dependencies are present.

  ## Usage

      mix rendro.api.gen

  ## Output

  Writes `priv/public_api.json` — a schema-validated manifest of all public
  Rendro modules with their tier assignment, public functions, and public types.
  This file is checked in and serves as the canonical source of truth for the
  public API surface (API-01). Phase 79's contract test regenerates it in-memory
  and asserts equality to enforce surface drift detection.
  """
  @moduledoc tags: [:adapter]

  @manifest_path "priv/public_api.json"

  # Explicit registry of all public Rendro modules.
  # This list is the source of truth for what appears in priv/public_api.json.
  # Conditional adapters (Threadline, Mailglass, Accrue, Phoenix, Oban.RenderWorker)
  # are included; recompile_conditional_adapters/0 ensures they are present when
  # their optional deps are available.
  @public_modules [
    # Stable tier — core document model and facades
    Rendro,
    Rendro.Artifact,
    Rendro.AssetRegistry,
    Rendro.AssetRegistry.InvalidAssetError,
    Rendro.Block,
    Rendro.Cell,
    Rendro.Component,
    Rendro.Document,
    Rendro.EmbeddedFileRegistry,
    Rendro.Error,
    Rendro.FontRegistry,
    Rendro.FontRegistry.EmbeddedFontFamilyError,
    Rendro.FormField,
    Rendro.Image,
    Rendro.Link,
    Rendro.Metadata,
    Rendro.Page,
    Rendro.PageTemplate,
    Rendro.Path,
    Rendro.Protect,
    Rendro.Recipes,
    Rendro.Region,
    Rendro.Row,
    Rendro.RunningContent,
    Rendro.Section,
    Rendro.Sign,
    Rendro.Table,
    Rendro.Text,
    Rendro.Text.Shaper,
    Rendro.Text.Shaper.Simple,
    # Adapter tier — ecosystem integrations, optional adapters, recipe impls
    Rendro.Adapters.HarfBuzz,
    Rendro.Adapters.Oban.RenderWorker,
    Rendro.Adapters.Pdfium,
    Rendro.Adapters.Pdfsig,
    Rendro.Adapters.Phoenix,
    Rendro.Adapters.Poppler,
    Rendro.Adapters.PyHanko,
    Rendro.Adapters.Qpdf,
    Rendro.Inspector,
    Rendro.Protect.Adapter,
    Rendro.Recipes.BrandedInvoice,
    Rendro.Recipes.Certificate,
    Rendro.Recipes.Invoice,
    Rendro.Recipes.Receipt,
    Rendro.Recipes.Statement,
    Rendro.Sign.Adapter,
    Rendro.Storage,
    Rendro.Storage.Local,
    Rendro.Telemetry,
    # Conditional adapters (only present when optional deps are available)
    Rendro.Adapters.Accrue,
    Rendro.Adapters.Mailglass,
    Rendro.Adapters.Threadline
  ]

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("compile")
    Rendro.PublicApi.recompile_conditional_adapters()

    # Filter to only modules that have BEAM documentation chunks available.
    # Code.ensure_loaded?/1 covers in-memory compiled modules (via Code.compile_file),
    # but Code.fetch_docs/1 requires a BEAM file on disk to read the docs chunk.
    # Conditional adapters compiled in-memory only (no BEAM on disk) would produce
    # :untagged tier — we skip them so the manifest only contains properly documented modules.
    loaded_modules =
      Enum.filter(@public_modules, fn mod ->
        Code.ensure_loaded?(mod) and match?({:docs_v1, _, _, _, _, _, _}, Code.fetch_docs(mod))
      end)

    manifest = Rendro.PublicApi.build_manifest(loaded_modules)

    json = encode_manifest(manifest)

    File.write!(@manifest_path, json <> "\n")
    Mix.shell().info("Wrote #{@manifest_path}")
  rescue
    e ->
      Mix.shell().error("Generation failed: #{Exception.message(e)}")
      exit({:shutdown, 1})
  end

  # Expose the public module list for test use (byte-equality test in manifest_test.exs).
  @doc false
  def public_modules, do: @public_modules

  # Encode the manifest to JSON with deterministic (alphabetically sorted) key order.
  # Jason does not sort large map keys; we use Jason.OrderedObject to guarantee order.
  @doc false
  def encode_manifest(manifest) do
    sorted_modules =
      manifest["modules"]
      |> Enum.sort_by(fn {name, _} -> name end)
      |> Enum.map(fn {name, entry} ->
        sorted_entry =
          %Jason.OrderedObject{
            values: [
              {"functions", entry["functions"]},
              {"tier", entry["tier"]},
              {"types", entry["types"]}
            ]
          }

        {name, sorted_entry}
      end)

    ordered = %Jason.OrderedObject{
      values: [{"modules", %Jason.OrderedObject{values: sorted_modules}}]
    }

    Jason.encode!(ordered, pretty: true)
  end
end

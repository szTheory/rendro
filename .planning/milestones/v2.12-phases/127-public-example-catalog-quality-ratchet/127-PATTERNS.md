# Phase 127: Public example catalog & quality ratchet - Pattern Map

**Mapped:** 2026-08-17  
**Files analyzed:** 15 logical files/artifact groups  
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| lib/rendro/catalog.ex | service | transform, file-I/O | lib/rendro/launch_artifacts.ex | exact |
| lib/mix/tasks/rendro/catalog/gen.ex | utility | request-response, file-I/O | lib/mix/tasks/rendro/launch_artifacts/gen.ex | exact |
| lib/mix/tasks/rendro/catalog/check.ex | utility | request-response, file-I/O | lib/mix/tasks/rendro/launch_artifacts/check.ex | exact |
| assets/rendro/catalog.json | config | transform | assets/rendro/artifacts.json | role-match |
| assets/rendro/catalog/<family>/<brand>/<preset>-<mode>.png (32 files) | config | file-I/O | assets/rendro/gallery/*.png | exact |
| priv/examples/ticket/aurora-live/ticket.json | config | file-I/O | existing ticket fixtures | role-match |
| priv/quality/rubric_scores.json | config | transform | existing scores records | exact |
| priv/schemas/rubric_scores.schema.json | config | transform | existing score_entry definition | exact |
| test/rendro/catalog_test.exs | test | transform, file-I/O | test/rendro/launch_artifacts_test.exs | exact |
| test/docs_contract/catalog_manifest_contract_test.exs | test | file-I/O, transform | launch-artifact contract tests | role-match |
| test/docs_contract/catalog_quality_contract_test.exs | test | transform | test/docs_contract/rubric_manifest_contract_test.exs | exact |
| test/docs_contract/rubric_manifest_contract_test.exs | test | transform | same file’s threshold/provenance assertions | exact |
| mix.exs | config | event-driven | existing ci.advisory alias | exact |
| .github/workflows/ci.yml | config | event-driven | advisory-checks job | exact |
| test/guardrails/required_checks_contract_test.exs | test | event-driven | existing advisory wiring assertions | exact |

## Pattern Assignments

### lib/rendro/catalog.ex (service, transform/file-I/O)

**Analog:** lib/rendro/launch_artifacts.ex

Keep Catalog a sibling private module (@moduledoc false), not a branch of Rendro.LaunchArtifacts. Copy its literal ordered-spec, deterministic render, PDFium, manifest, and all-errors checker structure. Do not copy manual/README/guide generation.

**Module constants and explicit registry pattern** (lib/rendro/launch_artifacts.ex:1-59):

~~~elixir
defmodule Rendro.LaunchArtifacts do
  @moduledoc false
  @asset_root "assets/rendro"
  @dpi 96
  @schema_version 1
  @renderer_kind "pdfium-render"
  @generated_by "mix rendro.launch_artifacts.gen"
  @sha256_regex ~r/^[0-9a-f]{64}$/

  @gallery_specs [
    %{id: "invoice", module: Rendro.Recipes.Invoice, ...}
  ]
end
~~~

Create a literal domain-first @catalog_specs registry as the only membership source. Tests must assert all 32 stable IDs/order and both count == 32 and count <= 32; never call Examples.list/1 or calculate a cross-product.

**Generate/check separation** (lib/rendro/launch_artifacts.ex:235-265):

~~~elixir
def generate(opts \\ []) do
  with_pdfium(opts, fn ->
    with {:ok, renderer_version} <- Rendro.Adapters.Pdfium.version(),
         :ok <- ensure_asset_dirs(),
         {:ok, gallery_entries} <- build_gallery_entries(renderer_version),
         :ok <- write_manifest(manifest) do
      :ok
    end
  end)
end

def check(opts \\ []) do
  with_pdfium(opts, fn ->
    manifest = read_manifest!()
    static_errors = static_contract_errors(manifest)
    raster_errors = raster_contract_errors(manifest, renderer_version)

    case static_errors ++ raster_errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end)
end
~~~

Catalog generation writes only its PNG tree and catalog.json; rubric data is reviewer-owned and must never be mutated by generate/1. check/1 joins generated cells with dispositions and returns every cell-specific error and next action.

**Fixture dispatch and deterministic render** (lib/rendro/launch_artifacts.ex:385-522):

~~~elixir
defp build_source_document("ticket") do
  @ticket_fixture
  |> Rendro.Examples.load!()
  |> Rendro.ExamplesData.transform_ticket()
  |> Rendro.Recipes.Ticket.document(theme: Rendro.Theme.default())
end

defp render_doc(%Rendro.Document{} = doc) do
  Rendro.render(doc, deterministic: true)
end
~~~

Use a finite family dispatcher. Preset cells use Rendro.Theme.Presets.preset/2 then Rendro.Theme.Presets.register_fonts/2 before render; default cells use Theme.default/0 and retain null brand/preset/accent fields.

**Page-one evidence and entry building** (lib/rendro/launch_artifacts.ex:622-650):

~~~elixir
Enum.map(@gallery_specs, fn spec ->
  with {:ok, pdf} <- render_source_pdf(spec),
       {:ok, [png]} <- Rendro.Adapters.Pdfium.render(pdf, dpi: @dpi, pages: "1") do
    File.write!(spec.png_path, png)
    {width, height} = png_dimensions(png)

    {:ok, %{
      "id" => spec.id,
      "png_path" => spec.png_path,
      "png_sha256" => sha256(png),
      "source_pdf_sha256" => sha256(pdf),
      "page" => 1,
      "dpi" => @dpi,
      "width_px" => width,
      "height_px" => height,
      "renderer_kind" => @renderer_kind,
      "renderer_version" => renderer_version,
      "alt" => spec.alt,
      "caption" => spec.caption
    }}
  end
end)
~~~

Adapt with family, truthful metadata, recipe module, fixture reference, complete-PDF page_count, and derived three-state quality. Preserve native geometry and write only page 1; hash/count the complete PDF without committing it.

**Fail-loud validation** (lib/rendro/launch_artifacts.ex:712-835):

~~~elixir
expected_ids = Enum.map(@gallery_specs, & &1.id)

errors
|> add_error_unless(Map.get(manifest, "schema_version") == @schema_version,
  "schema_version must be #{@schema_version}")
|> add_error_unless(Enum.map(gallery, &entry_id/1) == expected_ids,
  "manifest gallery ids must be #{inspect(expected_ids)}")
|> Enum.concat(gallery_entry_shape_errors(gallery))
~~~

Validate literal ID/order, 32 exact/ceiling, safe paths/slugs, duplicate and orphan records, all hashes, page count, renderer identity, and quality/projection freshness. Aggregate errors instead of failing at the first one.

### lib/mix/tasks/rendro/catalog/gen.ex (utility, request-response/file-I/O)

**Analog:** lib/mix/tasks/rendro/launch_artifacts/gen.ex:1-46

~~~elixir
def run(args) do
  Mix.Task.run("app.start")
  opts = parse_opts(args)

  case Rendro.LaunchArtifacts.generate(opts) do
    :ok -> Mix.shell().info("Generated #{Rendro.LaunchArtifacts.manifest_path()}")
    {:error, reason} ->
      Mix.shell().error("Launch artifact generation failed: #{inspect(reason)}")
      exit({:shutdown, 1})
  end
end

defp parse_opts(args) do
  {opts, rest, _invalid} = OptionParser.parse(args, strict: [pdfium: :string])
  case rest do
    [] -> opts
    _ -> Mix.raise("Unexpected arguments: #{Enum.join(rest, " ")}")
  end
end
~~~

Mirror task naming, app startup, --pdfium parsing, and error exit. Catalog gen is the deliberate write/bless action and must state that it does not create or rebind reviews.

### lib/mix/tasks/rendro/catalog/check.ex (utility, request-response/file-I/O)

**Analog:** lib/mix/tasks/rendro/launch_artifacts/check.ex:1-42

~~~elixir
case Rendro.LaunchArtifacts.check(opts) do
  :ok ->
    Mix.shell().info("Launch artifacts VERIFIED")

  {:error, errors} ->
    shell = Mix.shell()
    Enum.each(errors, &shell.error/1)
    exit({:shutdown, 1})
end
~~~

Use the same all-errors output for Rendro.Catalog.check/1. It must never write or bless.

### assets/rendro/catalog.json and assets/rendro/catalog/** (config, transform/file-I/O)

**Analog:** assets/rendro/artifacts.json, generated by lib/rendro/launch_artifacts.ex:678-709.

~~~elixir
%{
  "schema_version" => @schema_version,
  "generated_by" => @generated_by,
  "renderer" => %{
    "kind" => @renderer_kind,
    "version" => renderer_version,
    "dpi" => @dpi,
    "pin_path" => @pdfium_pin_path,
    "pin_version" => pin["version"],
    "pin_sha256" => pin["sha256"]
  },
  "gallery" => gallery_entries
}
~~~

Write a versioned consumer-focused manifest with ordered cells. Store its 32 PNGs at assets/rendro/catalog/<family>/<brand>/<preset>-<mode>.png; do not commit source PDFs or trailing-page PNGs. Project only the required three statuses: Scored — passes current rubric, Scored — needs work, or Not yet scored.

### priv/examples/ticket/aurora-live/ticket.json (config, file-I/O)

**Analog:** lib/rendro/examples.ex:12-21 safe fixture loader.

~~~elixir
def load!(relative_path) do
  safe = safe!(relative_path)

  :rendro
  |> Application.app_dir(@base_dir)
  |> Path.join(safe)
  |> File.read!()
  |> JSON.decode!()
end
~~~

Add Aurora metadata only as schema-compatible fixture/catalog data. Do not add a brand module, calculate paths, or alter its historical unthemed render.

### priv/quality/rubric_scores.json and priv/schemas/rubric_scores.schema.json (config, transform)

**Analog:** priv/schemas/rubric_scores.schema.json:68-152 and test/docs_contract/rubric_manifest_contract_test.exs:35-160.

~~~json
"scores": {
  "type": "array",
  "items": { "$ref": "#/$defs/score_entry" }
},
"additionalProperties": true
~~~

Extend additively: retain legacy scores unchanged and add catalog dispositions with review_status: scored | unscored. Schema is only structural; catalog checks enforce one disposition per ID, no orphan, exact evidence/png/PDF hash binding, dated nonempty unscored reason, and projection freshness.

~~~elixir
defp passed?(dimension_scores, gate_results) do
  hierarchy_ok? = dimension_scores["content_hierarchy"] == 5

  other_cores_ok? =
    dimension_scores
    |> Map.delete("content_hierarchy")
    |> Map.values()
    |> Enum.all?(&(&1 >= 4))

  gates_ok? = gate_results |> Map.values() |> Enum.all?(&(&1 == true))
  hierarchy_ok? and other_cores_ok? and gates_ok?
end
~~~

Reuse the existing score arithmetic for scored dispositions. passed: false is valid evidence; a false-to-true transition needs superseded evidence and a nonempty resolution reference. Never accept a reviewer-entered freshness boolean.

### Catalog tests (test, transform/file-I/O)

**Analogs:** test/rendro/launch_artifacts_test.exs and test/docs_contract/rubric_manifest_contract_test.exs.

**Fixed ordered registry test** (test/rendro/launch_artifacts_test.exs:49-63):

~~~elixir
test "gallery has exactly eleven tiles in the fixed order (D-07)" do
  assert Enum.map(Rendro.LaunchArtifacts.gallery_specs(), & &1.id) == [
           "invoice", "branded_invoice", "statement", "receipt_report",
           "certificate", "payslip", "ticket", "invoice_dark",
           "certificate_dark", "ticket_dark", "invoice_brand"
         ]
end
~~~

test/rendro/catalog_test.exs should copy the direct literal assertion for all 32 catalog IDs and assert both exact count and ceiling. Also cover fixture sourcing, preset font registration, native geometry/page counts, default null semantics, and render-free validation errors.

**Schema contract test** (test/docs_contract/rubric_manifest_contract_test.exs:56-68):

~~~elixir
test "schema validation: checked-in manifest validates against rubric_scores.schema.json" do
  assert {:ok, _} = JSV.validate(manifest(), rubric_schema()),
         "#{@manifest_path} failed validation against #{@schema_path}"
end
~~~

Split the new contracts:

- catalog_manifest_contract_test.exs: static manifest/tree/schema/path/default-null/package/public-API isolation.
- catalog_quality_contract_test.exs: coverage, duplicate/missing/orphan/stale hash/evidence/projection/threshold/false-score tests.
- Update rubric_manifest_contract_test.exs only additively, preserving legacy scores’ contract.

### Advisory wiring (config, event-driven)

**Analog:** mix.exs:90-102 and .github/workflows/ci.yml:183-285.

~~~elixir
"ci.advisory": [
  "test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs",
  "rendro.launch_artifacts.check",
  "rendro.comparison.check"
]
~~~

~~~yaml
- name: Check Launch Artifacts
  run: mix rendro.launch_artifacts.check
~~~

Add rendro.catalog.check alongside—not in place of—the launch check in the graph-disconnected advisory lane. Do not put pinned PDFium/catalog rendering in deterministic required CI.

**Guardrail test style:** test/guardrails/required_checks_contract_test.exs:170-310 derives the advisory job, asserts no needs:, and requires launch-artifact check wiring. Extend that exact test/guardrail metadata pattern for rendro.catalog.check.

## Shared Patterns

### Safe paths

**Source:** lib/rendro/examples.ex:12-51  
**Apply to:** all catalog fixture and asset paths.

~~~elixir
case Path.safe_relative(input) do
  {:ok, safe} -> safe
  :error ->
    raise ArgumentError,
          "unsafe example path rejected (escapes #{@base_dir}): #{inspect(input)}"
end
~~~

Use this defensive posture, but keep public membership solely in the explicit registry.

### Preset fonts are document-owned

**Source:** lib/rendro/theme/presets.ex:35-42  
**Apply to:** all 26 preset cells.

~~~elixir
def register_fonts(%Document{} = document, genre) do
  validate_genre!(genre)

  genre
  |> font_roles()
  |> Enum.reduce(document, &register_font(&2, &1))
end
~~~

Call this after building each preset-backed document. Default cells do not register preset fonts.

### Advisory PDFium boundary

**Source:** lib/rendro/launch_artifacts.ex:329-330; mix.exs:90-102; .github/workflows/ci.yml:183-285  
**Apply to:** Catalog, CI, manifest copy, and tests.

Pinned PDFium PNGs are render evidence, not GUI-viewer proof. Do not imply print, accessibility, PDF/UA, WCAG, or universal-viewer fidelity; retain the required screen-oriented dark-mode caveat.

### Aggregated actionable errors

**Source:** lib/rendro/launch_artifacts.ex:251-265; lib/mix/tasks/rendro/launch_artifacts/check.ex:24-31  
**Apply to:** static, raster, and quality joins.

Report the catalog ID, expected and actual hash/page values, and narrow recovery action (generate, re-score, or deliberate unscored rebind). Never recommend a mass re-bless.

## No Analog Found

None. The catalog-quality relation is new, but both sides have direct precedents: launch artifacts for generated evidence and the rubric manifest for human review. Compose them additively; do not create a runtime subsystem.

## Metadata

**Analog search scope:** lib/rendro, lib/mix/tasks, test/rendro, test/docs_contract, test/guardrails, priv, assets, mix.exs, .github/workflows/ci.yml  
**Files scanned:** 14 primary analog/configuration files  
**Pattern extraction date:** 2026-08-17


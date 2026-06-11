# Phase 86 Pattern Mapping: Self-Proving Launch Artifacts

**Role:** gsd-pattern-mapper  
**Phase:** 86 - Self-Proving Launch Artifacts  
**Output:** `.planning/phases/86-self-proving-launch-artifacts/86-PATTERNS.md`  
**Inputs:** `86-CONTEXT.md`, `86-RESEARCH.md`, `86-UI-SPEC.md`, current codebase

## Executive Summary

Phase 86 should extend the existing launch-artifact scaffold, not recreate it. The current worktree already has the right ownership shape:

- `Rendro.LaunchArtifacts` owns fixture data, PDF rendering, PNG rendering, manifest construction, manual rendering, generated README/guide blocks, static contract checks, and advisory raster checks.
- Required CI/docs contract should call only static/deterministic proof: manifest shape, committed hashes, regenerated source-PDF hashes, regenerated `manual.pdf` hash, docs block equality, public copy guards, and package inclusion.
- Advisory `raster-advisory` should remain graph-disconnected and `continue-on-error: true`; it may install pinned pdfium and run `mix rendro.launch_artifacts.check`.
- Launch-only visual polish should not change canonical recipe defaults. Prefer a private launch fixture transform over public recipe API expansion. Fall back to a narrow inert-default recipe option only if traversal is brittle.

## Likely File Map

| File | Role | Data flow | Closest analog | Pattern to follow |
|---|---|---|---|---|
| `lib/rendro/launch_artifacts.ex` | Launch artifact generator/checker core | recipe fixture data -> recipe document -> deterministic source PDF -> pdfium PNG -> manifest -> manual -> generated docs blocks | `lib/rendro/adapters/pdfium.ex`, `scripts/release_preflight_proof.exs`, recipe modules | Keep one explicit workflow. Split static contract from raster contract. Use actionable drift messages. Do launch-only fixture styling here if possible. |
| `lib/mix/tasks/rendro/launch_artifacts/gen.ex` | Write task | CLI args/env -> `Rendro.LaunchArtifacts.generate/1` -> writes assets/docs | `lib/mix/tasks/docs.contract.ex`, `lib/mix/tasks/release/preflight.ex` | Thin task wrapper, `Mix.Task.run("app.start")`, parse `--pdfium`, clear error output, non-zero exit on failure. |
| `lib/mix/tasks/rendro/launch_artifacts/check.ex` | No-write advisory check task | CLI args/env -> `Rendro.LaunchArtifacts.check/1` -> reports drift | `lib/mix/tasks/docs.contract.ex`, `lib/mix/tasks/verify.ex` | Thin task wrapper, no repo writes, print every drift error, non-zero exit on failure. |
| `assets/rendro/artifacts.json` | Generated manifest | generator output -> docs blocks/tests/package | `priv/pdfium_pin.json`, `priv/support_matrix.json` | Stable JSON shape with exact five gallery IDs, renderer pin metadata, manual hash, per-entry source/PNG hashes, dimensions, alt text, captions. |
| `assets/rendro/gallery/*.png` | Generated visual gallery assets | source PDFs -> pdfium-render page 1 PNGs | `priv/raster_refs/forms_support_fixture/page_1.sha256` | Committed assets are hash-checked statically; regeneration/hash/dimension checks stay advisory. |
| `assets/rendro/manual.pdf` | Self-rendered proof artifact | `Rendro.LaunchArtifacts.render_manual_pdf/0` -> `Rendro.render(..., deterministic: true)` -> manifest/docs SHA | release preflight proof artifact checks | Required docs contract should rerender and compare hash without pdfium. Manual may embed PNG previews if source PDFs/PNGs are separately checked. |
| `README.md` | Concise proof surface | generated block from manifest plus hand-authored first-screen copy | existing generated docs-contract blocks in launch scaffold | Keep first screen concise. Generated launch block uses markers. Do not hand-edit generated block after generator changes. |
| `guides/recipes.md` | Rich HexDocs gallery surface | generated block from manifest plus hand-authored guide copy | `test/docs_contract/recipes_contract_test.exs` | Five entries, linked full-size images, width 320, captions, source PDF SHA-256, PNG SHA-256, manual hash. Fix stale "four canonical recipes" wording. |
| `mix.exs` | Package and ExDoc asset contract | package allowlist + ExDoc `assets` copy + image CSS | branding package tests, ExDoc docs config | Include `assets/rendro`; keep ExDoc image styling centralized in `before_closing_head_tag/1`. Avoid per-page gallery wrappers/scripts. |
| `scripts/verify_docs.exs` | Required docs-contract lane registry | lane list -> `System.cmd("mix", ["test", ...])` | existing docs-contract lanes | Keep launch artifacts as one explicit lane. Update lane-count tests when adding lanes. |
| `.github/workflows/ci.yml` | Required/advisory CI split | `test` job -> `mix ci`; `raster-advisory` -> pinned pdfium + raster snapshot + launch check | Phase 85 raster lane | Do not add pdfium install/check to `test` or `mix ci`. Keep `raster-advisory` disconnected and advisory. |
| `priv/guardrails/required_status_checks.json` | CI status contract registry | required/advisory context metadata -> guardrail tests | `test/guardrails/required_checks_contract_test.exs` | Update `raster-advisory.command`/notes to include launch artifact check, but keep it out of `required_contexts`. |
| `test/docs_contract/launch_artifacts_claims_test.exs` | Required static launch docs contract | reads manifest/docs/CI/package -> assertions | `test/docs_contract/raster_claims_test.exs`, `test/docs_contract/branding_claims_test.exs` | Assert static contract, exact IDs, alt text, copy boundaries, docs lane, advisory CI wiring, package inclusion for all assets, tarball cleanup. |
| `test/guardrails/required_checks_contract_test.exs` | Required/advisory guardrail tests | parses guardrail JSON and CI YAML | existing required context tests | Add negative proof that `mix ci` stays pdfium-free and launch check remains advisory. |
| `test/docs_contract/raster_claims_test.exs` | Raster boundary docs contract | support matrix/pdfium pin/guardrails | existing Phase 85 tests | Reuse for boundary assertions if launch-specific advisory checks naturally fit here. |
| `lib/rendro/recipes/{invoice,branded_invoice,statement,receipt}.ex` | Optional fallback only | recipe opts -> `Rendro.table/2` opts | opts-threading tests, `Rendro.measure_rows/4` table opts | Avoid unless launch-only transform is brittle. If used, option must be inert by default and passed to both measure and render paths. |
| `test/rendro/recipes/*_test.exs` or opts-threading tests | Optional fallback tests | recipe defaults/options -> sections/document output | `test/rendro/recipes/invoice_opts_threading_test.exs`, `test/rendro/recipes/branded_invoice_opts_threading_test.exs` | If recipe opts are added, prove unknown/empty opts remain stable and default output is unchanged. |

## Launch Artifact Generator/Checker Patterns

### Existing Core Shape

Current `Rendro.LaunchArtifacts` already has the desired centralized data flow:

```elixir
@asset_root "assets/rendro"
@gallery_dir Path.join(@asset_root, "gallery")
@manual_path Path.join(@asset_root, "manual.pdf")
@manifest_path Path.join(@asset_root, "artifacts.json")
@dpi 96
@schema_version 1
@renderer_kind "pdfium-render"
```

Pattern summary:

- Keep asset paths, marker strings, DPI, schema, and renderer kind as module attributes.
- Treat `@gallery_specs` as the canonical ordering and metadata source for the five entries.
- Do not duplicate gallery metadata in README/guide/tests. Tests should read manifest/specs where possible.

The current generator sequence is the correct ownership model:

```elixir
with {:ok, renderer_version} <- Rendro.Adapters.Pdfium.version(),
     :ok <- ensure_asset_dirs(),
     {:ok, gallery_entries} <- build_gallery_entries(renderer_version),
     {:ok, manual_sha256} <- write_manual_pdf(),
     {:ok, manifest} <- build_manifest(gallery_entries, manual_sha256, renderer_version),
     :ok <- write_manifest(manifest),
     :ok <- write_docs_blocks(manifest) do
  :ok
end
```

Required pattern:

- Generation may write `assets/rendro/gallery/*.png`, `assets/rendro/manual.pdf`, `assets/rendro/artifacts.json`, `README.md`, and `guides/recipes.md`.
- Checking must not write repo files.
- Manual generation depends on existing PNG files today. Preserve generation order: gallery PNGs before manual.

### Static vs Raster Checks

Current split:

```elixir
def static_contract_errors(manifest) when is_map(manifest) do
  []
  |> collect_manifest_shape_errors(manifest)
  |> collect_asset_hash_errors(manifest)
  |> collect_source_pdf_errors(manifest)
  |> collect_manual_render_errors(manifest)
  |> collect_docs_block_errors(manifest)
end
```

```elixir
defp raster_contract_errors(manifest, renderer_version) do
  ...
  with {:ok, pdf} <- render_source_pdf(spec),
       {:ok, [png]} <- Rendro.Adapters.Pdfium.render(pdf, dpi: @dpi, pages: "1") do
    ...
  end
end
```

Pattern summary:

- `static_contract_errors/0` must stay pdfium-free.
- Source PDFs and `manual.pdf` are deterministic Rendro outputs and belong in required static checks.
- PNG regeneration, dimensions, and renderer-version drift belong in advisory raster checks.
- Static checks may compare committed PNG file hash to manifest hash, because that reads committed bytes only and does not call pdfium.

Additional static detectors to add:

- Manifest renderer/manual/pin field shape and SHA formats.
- Exact five gallery IDs in order.
- README and recipes generated block equality.
- Manual hash appears in both public surfaces.
- Alt text is non-empty and descriptive.
- Package includes manifest, manual, and all five PNGs.
- Public copy avoids GUI-viewer/PDF-A/PDF-UA/every-viewer/browser-wrapper overclaims.
- Required `mix ci` does not run `mix rendro.launch_artifacts.check`, install pdfium, or call raster generation.

### External Tool Isolation

Closest analog: `Rendro.Adapters.Pdfium.render/2`.

```elixir
with :ok <- validate_dpi(dpi),
     :ok <- validate_pages(pages),
     {:ok, executable} <- find_executable(),
     {:ok, tmp_dir} <- make_tmp_dir_for_raster() do
  try do
    render_in_tmp(executable, tmp_dir, pdf_binary, opts)
  after
    File.rm_rf(tmp_dir)
  end
end
```

Pattern summary:

- Use list-form command args, not shell interpolation.
- Keep temporary raster IO isolated and cleaned.
- Surface missing executable as an explicit error.
- Launch check can use `with_pdfium/2` for `--pdfium`/`RENDRO_PDFIUM_CLI`, but static contract must not.

### Error Message Pattern

Current drift messages are concrete:

```elixir
"source PDF hash drift for #{spec.id}: expected #{entry["source_pdf_sha256"]}, got #{actual}"
"manual.pdf hash drift: expected #{expected}, got #{actual}"
"README launch artifact block is stale; run mix rendro.launch_artifacts.gen"
```

Preferred Phase 86 drift wording from UI spec:

```text
Launch artifacts drifted: {artifact}. Run mix rendro.launch_artifacts.gen in the pinned pdfium environment, then re-run the required docs contract and advisory raster check.
```

Pattern summary:

- Keep errors actionable and artifact-specific.
- Mention the generator command.
- For PNG/raster drift, mention pinned pdfium environment.
- Do not hide all drift behind one generic failure.

## Recipe Option and Escape-Hatch Patterns

### Three-Rung Recipe API

Invoice module docs define the project pattern:

```elixir
- `document/2`      - Batteries-included; returns a fully assembled
- `page_template/1` - Layout only; returns the `%Rendro.PageTemplate{}`.
- `sections/2`      - Content only; returns a list of `%Rendro.Section{}`
```

The implementation repeats the same shape:

```elixir
template = page_template(opts)
secs = sections(data, opts)

base_doc =
  Rendro.Document.new()
  |> Rendro.Document.add_template(template)
  |> Rendro.Document.set_template(template.name)

Enum.reduce(secs, base_doc, fn section, doc ->
  Rendro.Document.add_section(doc, section)
end)
```

Pattern summary:

- Launch-specific assembly can use `page_template/1` + `sections/2` without changing public defaults.
- If transforming sections, preserve `%Rendro.Section{}` fields and `%Rendro.Block{}` fields, including `break_before`/`break_after`.
- Branded invoice must preserve `Document.register_embedded_font/3` and `Document.register_image/3`.

### Preferred Launch-Only Table Polish

Use private launch fixture helpers in `Rendro.LaunchArtifacts`, not global recipe defaults.

Target style:

```elixir
@launch_table_style [
  borders: [:outer, :rows],
  border_style: %{color: {216, 210, 195}, width: 0.6},
  header_fill: {247, 243, 234}
]
```

Structs make a private transform feasible:

```elixir
%Rendro.Section{content: [Rendro.Block.t() | Rendro.RunningContent.t()]}
%Rendro.Block{content: Rendro.Text.t() | Rendro.Table.t() | term()}
%Rendro.Table{borders: :none, border_style: nil, header_fill: nil}
```

Pattern summary:

- Transform only `%Rendro.Block{content: %Rendro.Table{}}`.
- Set only table decoration fields: `borders`, `border_style`, `header_fill`.
- Preserve all geometry fields (`column_widths`, `row_heights`, `header_height`, `_grid_layout`) if present. In launch source docs, transform should happen before measurement/render.
- Avoid `borders: :all` for long Statement/Receipt gallery tables.
- Keep Certificate using `Rendro.Recipes.Certificate.document(data, border: true)`.

### Fallback: Narrow Inert-Default Recipe Option

If traversal becomes brittle, add a narrow option such as `table_opts:` to affected recipes.

Relevant existing pattern in Statement/Receipt:

```elixir
table_header = ["Date", "Description", "Amount", lbl.(:balance)]
table_opts = [header: table_header, columns: @table_columns]
{header_h, row_heights} =
  Rendro.measure_rows(formatted_rows, @content_width, doc_for_measure, table_opts)
...
table = Rendro.table(full_page_rows, table_opts)
```

Requirement if using this fallback:

- Merge launch table opts into the same `table_opts` used for both `Rendro.measure_rows/4` and `Rendro.table/2`.
- Default option must be `[]`/nil and preserve default behavior.
- Do not document it as broad styling API unless intentionally supported.

Existing opts-threading tests give the style:

```elixir
sections_no_opts = Invoice.sections(sample_data())
sections_empty_opts = Invoice.sections(sample_data(), [])
assert sections_no_opts == sections_empty_opts
```

## Table Decoration Patterns

`Rendro.table/2` is the normalization path:

```elixir
attrs
|> normalize_table_attrs()
|> Keyword.put(:rows, rows)
|> then(&struct!(Table, &1))
```

Normalization details:

```elixir
@valid_border_atoms [:none, :outer, :rows, :columns, :grid, :all]

atoms
|> Enum.flat_map(&List.wrap(expand_border_atom(&1)))
|> Enum.uniq()
|> Enum.sort()
```

Writer behavior:

```elixir
if borders in [:none, [], nil] and is_nil(table.header_fill) do
  ""
else
  do_table_decoration(table, page, block)
end
```

Pattern summary:

- Defaults are inert. Do not change recipe defaults for launch screenshots.
- `borders: [:outer, :rows]` normalizes to `[:outer, :rows]`.
- `header_fill` and `border_style.color` must use RGB tuples, not hex strings.
- Tests already cover `borders: [:outer, :rows]`, header fill emission, and invalid color guards.

## Docs-Contract Patterns

### Generated Blocks

Current generator owns README and guide block rendering:

```elixir
replace_block!(@readme_path, @readme_start, @readme_end, readme_block(manifest))
replace_block!(@recipes_guide_path, @recipes_start, @recipes_end, recipes_block(manifest))
```

Pattern summary:

- Generated blocks must be exact output of `readme_block/1` and `recipes_block/1`.
- Do not hand-edit between markers.
- Static contract should compare extracted block content to generator output.

README current block shape:

```html
<a href="assets/rendro/gallery/invoice.png"><img src="assets/rendro/gallery/invoice.png" alt="..." width="150"></a>
```

Guide current block shape:

```markdown
### Invoice
<a href="assets/rendro/gallery/invoice.png"><img src="assets/rendro/gallery/invoice.png" alt="..." width="320"></a>
- Source PDF SHA-256: `...`
- PNG SHA-256: `...`
```

UI contract additions:

- README copy should say `curated deterministic recipe fixtures`.
- README must publish manual SHA and proof split.
- Guide must show five entries, width `320`, captions, source PDF hash, PNG hash, manual link/hash.
- Guide opening should not say only four visual examples; replace stale line with five-entry wording.

### Docs Lane Registry

Current lane pattern in `scripts/verify_docs.exs`:

```elixir
lanes = [
  {"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]},
  ...
  {"Launch artifacts claims lane", ["test", "test/docs_contract/launch_artifacts_claims_test.exs"]}
]
```

Test pattern in guardrails:

```elixir
lane_entries = Regex.scan(~r/\{"[^"]+", \["test", "test\/docs_contract\/[^"]+"\]\}/, script)
assert length(lane_entries) == 16
```

Pattern summary:

- Keep launch artifacts as one lane unless another docs-contract file is intentionally added.
- If adding a lane, update lane-count tests and lane-name tests together.
- Required docs-contract tests must not require pdfium.

### Public Copy Guards

Existing launch claims test:

```elixir
assert public_copy =~ "pdfium-render"
refute public_copy =~ "GUI-viewer proof"
refute public_copy =~ "works in every viewer"
refute public_copy =~ "PDF/A compliant"
refute public_copy =~ "PDF/UA compliant"
```

Extend this pattern with UI contract forbidden phrases:

- `full HTML/CSS rendering`
- `browserless viewer`
- `prepress SDK`
- `pixel-perfect HTML-to-PDF`
- `launch gallery shows default recipe styling`

Required positive phrases:

- `Native PDF layout for Elixir.`
- `open-source, Elixir-native PDF layout library`
- `curated deterministic recipe fixtures`
- `Source PDFs and the self-rendered manual are byte-checked`
- `PNG rasters are regenerated and hash-checked`
- `pdfium-render rasters are render proof, not GUI-viewer proof`
- `canonical recipe defaults remain unchanged`

## ExDoc Asset and Package Patterns

Current `mix.exs` package allowlist:

```elixir
files: ~w(
  lib
  assets/rendro
  priv/branded
  guides
  .formatter.exs
  mix.exs
  README.md
  LICENSE
  NOTICE
  CHANGELOG.md
)
```

Current ExDoc asset copy and centralized image CSS:

```elixir
assets: %{"assets" => "assets"},
before_closing_head_tag: &before_closing_head_tag/1
```

```css
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
```

Pattern summary:

- Keep assets under `assets/rendro` so GitHub README, HexDocs, and Hex package paths match.
- Use relative paths in Markdown.
- Keep previews white in dark mode; only frame treatment changes.
- Do not add JavaScript gallery behavior, lightboxes, remote images, or per-guide wrappers.
- Package test should assert all public launch assets, not just one PNG.

Package assertion should cover:

- `assets/rendro/artifacts.json`
- `assets/rendro/manual.pdf`
- `assets/rendro/gallery/invoice.png`
- `assets/rendro/gallery/branded_invoice.png`
- `assets/rendro/gallery/statement.png`
- `assets/rendro/gallery/receipt_report.png`
- `assets/rendro/gallery/certificate.png`

## CI Advisory Lane and Guardrails Patterns

Current CI required job:

```yaml
test:
  steps:
    - name: Run CI
      run: mix ci
```

Current advisory raster job:

```yaml
raster-advisory:
  runs-on: ubuntu-latest
  continue-on-error: true
  # no 'needs:' -> graph-disconnected
  ...
  - name: Install pdfium-cli (pinned)
    run: |
      EXPECTED_SHA256="b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a"
      curl -fsSL -o pdfium-cli \
        "https://github.com/klippa-app/pdfium-cli/releases/download/v0.11.0/pdfium-webassembly-linux-amd64"
      echo "${EXPECTED_SHA256}  pdfium-cli" | sha256sum --check
      chmod +x pdfium-cli
      sudo mv pdfium-cli /usr/local/bin/pdfium-cli
  - name: Run Raster Snapshot Tests
    run: mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs
  - name: Check Launch Artifacts
    run: mix rendro.launch_artifacts.check
```

Current `mix ci` alias:

```elixir
ci: [
  "format --check-formatted",
  "hex.build",
  "compile --warnings-as-errors",
  "test",
  "docs",
  "credo --strict",
  "dialyzer"
]
```

Guardrail JSON currently has `raster-advisory` in `advisory_contexts` and not in `required_contexts`. Update its command to include both raster snapshot and launch artifact check.

Suggested command value:

```text
mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs && mix rendro.launch_artifacts.check
```

Guardrail test additions:

- `refute "raster-advisory" in baseline["required_contexts"]`
- assert advisory context command includes `mix rendro.launch_artifacts.check`
- assert `.github/workflows/ci.yml` has `raster-advisory:` and `continue-on-error: true`
- assert the `test:` job block / `mix ci` alias does not include `rendro.launch_artifacts.check`, `pdfium-cli`, or `curl -fsSL`
- assert `mix ci` alias remains the exact required deterministic list

## Tests That Avoid Generated Tarballs and Noise

Current launch package test leaves a tarball:

```elixir
tarball = "rendro-#{Mix.Project.config()[:version]}.tar"
File.rm(tarball)
{output, 0} = System.cmd("mix", ["hex.build"], stderr_to_stdout: true)
...
```

Closest cleanup patterns:

```elixir
setup do
  File.mkdir_p!(@tmp_dir)
  on_exit(fn -> File.rm_rf!(@tmp_dir) end)
  :ok
end
```

```elixir
on_exit(fn ->
  Application.delete_env(:rendro, :pdfium_cli_executable_finder)
  Application.delete_env(:rendro, :pdfium_cli_command_runner)
end)
```

Release preflight cleans generated Hex artifacts:

```elixir
File.rm_rf!(dir)
File.rm(dir <> ".tar")
```

Required test pattern for launch package assertions:

```elixir
tarball = "rendro-#{Mix.Project.config()[:version]}.tar"
File.rm(tarball)
on_exit(fn -> File.rm(tarball) end)

{output, 0} = System.cmd("mix", ["hex.build"], stderr_to_stdout: true)
assert output =~ tarball
assert File.exists?(tarball)
```

Pattern summary:

- Remove any pre-existing tarball before build.
- Register `on_exit` cleanup immediately after computing/removing the tarball.
- If using `mix hex.build --unpack`, clean both the unpacked directory and `.tar`.
- Do not leave generated source PDFs, temporary PNGs, tarballs, unpacked package dirs, or changed docs blocks from tests.

## Manual PDF Patterns

Current manual shape:

```elixir
Rendro.page_template(
  name: :manual,
  width: 595.28,
  height: 841.89,
  margin_top: 54,
  margin_right: 54,
  margin_bottom: 54,
  margin_left: 54,
  regions: [...]
)
```

Footer:

```elixir
Rendro.page_number(
  format: "Rendro manual - Page {{page_number}} of {{total_pages}}",
  size: 9,
  color: {31, 41, 55}
)
```

Path proof:

```elixir
Rendro.path([{:move, 0, 4}, {:line, 440, 4}],
  width: 440,
  height: 8,
  stroke: %{color: color, width: width}
)
```

Pattern summary:

- Manual should remain compact, roughly 8-12 pages.
- The manual is a proof artifact, not API reference duplication.
- It may embed generated PNG previews, but copy must not imply PDF-in-PDF composition support.
- Required static check should rerender `render_manual_pdf/0` and compare SHA-256.
- Manual SHA is published outside the PDF in README and guide.

## Manifest Pattern

Current manifest fields:

```json
{
  "schema_version": 1,
  "generated_by": "mix rendro.launch_artifacts.gen",
  "renderer": {
    "kind": "pdfium-render",
    "version": "v0.11.0",
    "dpi": 96,
    "pin_path": "priv/pdfium_pin.json",
    "pin_version": "v0.11.0",
    "pin_sha256": "b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a"
  },
  "manual": {
    "path": "assets/rendro/manual.pdf",
    "sha256": "...",
    "source": "Rendro.LaunchArtifacts.render_manual_pdf/0"
  },
  "gallery": [...]
}
```

Per gallery entry required keys:

```elixir
~w(id title recipe_module png_path png_sha256 source_pdf_sha256 page dpi width_px height_px renderer_kind renderer_version alt caption)
```

Pattern summary:

- Preserve stable JSON ordering through `Jason.OrderedObject`.
- Validate all hashes with `/\A[0-9a-f]{64}\z/`.
- Validate `renderer.pin_sha256` matches `priv/pdfium_pin.json`.
- Validate portrait dimensions remain `794x1123` and certificate `1123x794` unless generator and tests intentionally update them.

## Implementation Guardrails

Do:

- Patch current scaffold in place.
- Keep generated docs blocks source-of-truth rendered from manifest.
- Keep table polish launch-only unless a narrow option is demonstrably safer.
- Regenerate assets only after fixture/copy/manual changes settle.
- Visually inspect regenerated PNGs, especially Branded Invoice heading readability.
- Run required static docs-contract tests without pdfium.
- Run advisory launch artifact check only where pinned pdfium is available.

Do not:

- Change global table defaults or canonical recipe defaults for screenshots.
- Put `pdfium-cli` install/download or `mix rendro.launch_artifacts.check` into `mix ci`.
- Upgrade pdfium-render evidence into GUI-viewer proof.
- Hand-edit generated README/guide blocks.
- Add a README marketing hero, browser/printer/prepress visuals, lightboxes, or custom gallery scripts.
- Leave Hex tarballs or unpacked package directories from tests.

## Recommended Verification Targets

Required/static:

```bash
mix test test/docs_contract/launch_artifacts_claims_test.exs
mix test test/guardrails/required_checks_contract_test.exs
mix test test/docs_contract/raster_claims_test.exs
```

If package assertions are changed:

```bash
mix test test/docs_contract/launch_artifacts_claims_test.exs --trace
```

Advisory/pinned pdfium:

```bash
mix rendro.launch_artifacts.check
mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs
```

Full required lane:

```bash
mix ci
```

## PATTERN MAPPING COMPLETE

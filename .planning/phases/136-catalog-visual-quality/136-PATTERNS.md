# Phase 136: Catalog Visual Quality - Pattern Map

**Mapped:** 2026-08-27  
**Files analyzed:** 14 planned source/test/artifact surfaces  
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `dev/rendro/catalog.ex` | dev-only catalog controller | transform / batch | existing `source_document_for/1` and `candidate_manifest/6` | exact |
| `lib/rendro/recipes/invoice.ex` | recipe component | transform / measured pagination | existing Invoice palette/table path | exact |
| `lib/rendro/recipes/statement.ex` | recipe component | transform / measured pagination | existing Statement palette/table path | exact |
| `lib/rendro/recipes/payslip.ex` | recipe component | transform / measured pagination | existing Payslip ledger path | exact (replace profile branch only) |
| `lib/rendro/recipes/ticket.ex` | recipe component | transform / measured table layout | existing Ticket placement-grid path | exact |
| `lib/rendro/recipes/palette.ex` | utility | transform | existing `Palette.resolve/2` | exact (reuse; no change expected) |
| `lib/rendro/recipes/table_cell.ex` | utility | transform | existing `TableCell.content/5` | exact (reuse; change only if role selection needs it) |
| `test/rendro/catalog_test.exs` | integration/contract test | batch / deterministic rendering | existing candidate-manifest tests | exact |
| `test/rendro/recipes/invoice_{test,opts_threading_test}.exs` | recipe tests | deterministic render / transform | existing palette and hierarchy tests | exact |
| `test/rendro/recipes/statement_{test,opts_threading_test}.exs` | recipe tests | deterministic render / transform | existing semantic-cell and closing-balance tests | exact |
| `test/rendro/recipes/payslip_{test,byte_identity_test}.exs` | recipe tests | deterministic render / measured pagination | existing continuation/reconciliation tests | exact |
| `test/rendro/recipes/ticket_{test,byte_identity_test}.exs` | recipe tests | deterministic render / measured table layout | existing placement-grid tests | exact |
| `priv/quality/rubric_scores.json`, `priv/quality/SIGN-OFF.md` | reviewer-owned evidence record | event-driven / provenance | existing rubric and sign-off contract fixtures | exact; update only after validated review |
| `assets/rendro/catalog.json` and `assets/rendro/catalog/` | generated canonical artifact | batch / file-I/O | existing `Rendro.Catalog.generate/1` canonical route | exact; materialize only after gate |

## Pattern Assignments

### `dev/rendro/catalog.ex` (dev-only controller, transform/batch)

**Analog:** `source_document_for/1` (lines 120-140).

Add one private literal six-ID allowlist and map it to *generic private option data*. Apply it at this exact call boundary, after fixture transformation and theme selection. Do not propagate an ID/brand/preset/phase to a recipe.

```elixir
theme = theme_for(spec)
doc = Map.fetch!(spec, :recipe_module).document(data, theme: theme, catalog_layout: true)

if preset = Map.get(spec, :preset_atom),
  do: Rendro.Theme.Presets.register_fonts(doc, preset),
  else: doc
```

The profile helper belongs immediately before this call and should return `[]` for every non-target spec. It may select options such as `presentation_profile: %{semantic_labels: ..., ledger: ..., locator: ...}`; recipes must match only those generic values.

**Candidate isolation analog:** `candidate_manifest/6` (lines 239-297) and `candidate_status/3` (lines 1018-1026).

```elixir
{candidate_cells, diff} =
  Enum.map_reduce(cells, %{changed_scored: [], changed_unscored: [], byte_stable: []}, fn cell, acc ->
    baseline_cell = Map.fetch!(baseline_by_id, cell["id"])
    {status, bucket} = candidate_status(cell, baseline_cell, dispositions[cell["id"]] || %{})
    {candidate_cell, Map.update!(acc, bucket, &(&1 ++ [cell["id"]]))}
  end)
```

```elixir
if cell["png_sha256"] == baseline_cell["png_sha256"] and
     cell["source_pdf_sha256"] == baseline_cell["source_pdf_sha256"] do
  {"byte_stable", :byte_stable}
else
  {"review_required", :changed_scored}
end
```

Preserve this ordered PDF-and-PNG hash classification. Extend tests to assert the exact ordered six changed scored IDs, no changed unscored IDs, and the literal ordered remaining 26 byte-stable IDs; add extra/missing/reordered profile-map negative cases.

### `lib/rendro/recipes/invoice.ex` (recipe component, transform/measured pagination)

**Analog:** Invoice body table construction (lines 296-405), palette seam (lines 674-686), and `TableCell` rendering below.

```elixir
rows = Enum.map(formatted_rows, &table_row(&1, theme, colors, type))
header = ["Item", "Qty", "Price"]

table_opts = [
  header: table_row(header, theme, colors, type),
  columns: @table_columns
]

{header_h, row_heights} =
  Rendro.measure_rows(rows, @content_width, doc_for_measure, table_opts_for_measure(header, theme, colors, type))
pages = Rendro.Recipes.Pagination.chunk_rows_into_pages(rows_with_meta, effective_capacity)
```

Follow the existing option seam: resolve a target profile into a local presentation/palette choice and leave the `nil`/omitted route untouched. Use semantic primary ink for functional labels/table headings and a deliberate secondary role for support facts, retaining the existing display-size `Total Due` code and geometry. Do not retune `Theme.dark/1`, the Corporate preset, or raw default colors globally.

### `lib/rendro/recipes/statement.ex` (recipe component, transform/measured pagination)

**Analog:** Statement body ledger (lines 518-681).

```elixir
table_header = ["Date", "Description", "Amount", lbl.(:balance)]
table_opts = [header: table_header, columns: @table_columns]

formatted_rows =
  Enum.map(rows_with_balance, fn %{date: d, description: desc, amount: amt, balance: bal} ->
    [cell_text(fmt_date.(d), colors, type), cell_text(desc, colors, type),
     cell_text(fmt_amount.(amt), colors, type), cell_text(fmt_amount.(bal), colors, type)]
  end)

{header_h, row_heights} = Rendro.measure_rows(formatted_rows, @content_width, doc_for_measure, table_opts)
pages = Rendro.Recipes.Pagination.chunk_rows_into_pages(rows_with_meta, effective_capacity)
```

Keep this measured, repeat-header path. Introduce generic profile-selected semantic primary/secondary treatments for headers, values, and context, but preserve the existing boxed Closing Balance display anchor, fonts, ledger geometry, and no-profile bytes.

### `lib/rendro/recipes/payslip.ex` (recipe component, transform/measured pagination)

**Analog:** existing single ledger (lines 577-764), particularly its measurement/chunking/reconciliation discipline.

```elixir
{header_h, row_heights} =
  Rendro.measure_rows(all_rows, g.content_w, doc_for_measure, table_opts)

effective_capacity =
  g.body_h - header_h - reconciliation_reserved_height(data) - @row_epsilon

rows_with_meta = Enum.zip(all_rows, row_heights) |> Enum.map(fn {row, height} -> {row, height, nil} end)
pages = Rendro.Recipes.Pagination.chunk_rows_into_pages(rows_with_meta, effective_capacity)
```

The target profile must replace only the paired `zip_pad/2` table with two independently built table blocks in source order: Earnings then Deductions. Use each table's own header and the established table renderer so continued blocks repeat that table header automatically. Reuse the existing column vocabulary with `{:share, weight}` for description and `{:fixed, measured_width}` for Current/YTD, plus `cell_align` for money columns. Do not use `zip_pad/2`, blank padding, guessed capacities, manual coordinates, caller-text edits, or font shrinkage in this profile.

**Atomic text + palette analog:** `cell_text/3` (lines 690-705) and palette resolver (lines 889-899).

```elixir
Rendro.block(
  Rendro.text(text,
    size: type.scale.subtitle,
    font: type.fonts.body,
    line_height: type.leading,
    widows: type.widows,
    orphans: type.orphans,
    color: colors.ink
  )
)
```

```elixir
Rendro.Recipes.Palette.resolve(opts, %{
  ink: {0, 0, 0}, muted: {0, 0, 0}, accent: {0, 0, 0}, on_accent: {0, 0, 0},
  background: {255, 255, 255}, surface: {255, 255, 255}, rule: {0, 0, 0}
})
```

Continue to use the Unicode fallback measurement document and reserve reconciliation height. The existing `build_reconciliation_blocks/6` follows the final table blocks; retain it adjacent to the final sequential ledger and keep Net Pay the sole display anchor. Light/dark profile geometry must be identical; palette roles, not raw black, supply dark header/body/rule colors.

### `lib/rendro/recipes/ticket.ex` (recipe component, transform/measured table layout)

**Analog:** Ticket `main_section/2` placement grid (lines 257-356).

```elixir
header_cells =
  Enum.map(data.placement, fn %{label: l} ->
    Rendro.block(Rendro.text(String.upcase(l), size: type.scale.caption, font: type.fonts.body,
      color: colors.muted, line_height: type.leading, widows: type.widows, orphans: type.orphans))
  end)

value_cells =
  Enum.map(data.placement, fn %{value: v} ->
    Rendro.block(Rendro.text(v, size: roles.placement, font: type.fonts.body,
      color: colors.ink, line_height: type.leading, widows: type.widows, orphans: type.orphans))
  end)

grid = Rendro.table([value_cells], header: header_cells,
  columns: List.duplicate({:share, 1}, length(data.placement)), borders: :none)
```

Keep the generic 1–4 placement-data contract and this one row/equal-share table. The target profile may adjust local font/fit/palette data only: `GA`, `H`, `24`, and `B` remain four source-order atomic cells with labels directly above values. Do not special-case Gate, reorder placement, create a two-row layout, or remove shared fixture data. Apply semantic palette roles to muted label, reference/stub, rules, and terms in dark without changing light/dark geometry.

### Shared palette/table-cell utility (transform)

**Sources:** `lib/rendro/recipes/palette.ex` lines 4-13; `lib/rendro/recipes/table_cell.ex` lines 4-18.

```elixir
def resolve(opts, defaults) do
  base = case opts[:theme] do
    nil -> defaults
    theme -> Rendro.Theme.resolve(theme).colors
  end
  Map.merge(base, Keyword.get(opts, :palette, %{}))
end
```

```elixir
def content(value, _theme, colors, type, role) when is_binary(value) do
  Rendro.block(Rendro.text(value, size: type.scale.body, font: type.fonts.body,
    line_height: type.leading, widows: type.widows, orphans: type.orphans,
    color: Map.fetch!(colors, role)))
end
```

Use named roles (`:ink`, `:muted`, `:rule`, `:surface`, `:on_accent`) and profile-provided palette values. This generic resolution precedence is the correct way to prevent raw/default-black dark fallbacks while maintaining no-theme byte identity.

### Focused ExUnit coverage (tests)

**Catalog analog:** `test/rendro/catalog_test.exs` lines 72-118. It already builds a full manifest, mutates exactly one hash, and proves that candidate generation records hash binding without copying reviewer fields.

```elixir
refute Map.has_key?(changed, "quality")
refute Map.has_key?(changed, "passed")
refute Map.has_key?(changed, "dimension_scores")
assert manifest["diff"]["changed_scored"] == [first["id"]]
```

Extend this file for literal six/26 isolation and private-profile omission/activation. Keep candidate generation free of reviewer values.

**Recipe test homes:**

- Invoice: `test/rendro/recipes/invoice_test.exs` has semantic-cell coverage; `invoice_opts_threading_test.exs` lines 83-145 proves palette precedence and `sections(data) == sections(data, [])`.
- Statement: `test/rendro/recipes/statement_test.exs` contains Closing Balance anchor and deterministic multipage tests; `statement_opts_threading_test.exs` is the matching palette/no-theme seam analog.
- Payslip: `test/rendro/recipes/payslip_test.exs` lines 305-350 proves real pagination, repeated header, final-page reconciliation and double render; `payslip_byte_identity_test.exs` lines 47-58 is the two-render + golden style.
- Ticket: `test/rendro/recipes/ticket_test.exs` lines 223-289 proves every placement label/value reaches the PDF and placement is dominant; `ticket_byte_identity_test.exs` is the two-render control.

Use structurally inspected text/block/table content where possible for palette roles, headers, order, atomic tokens, and equal-share geometry; render twice for deterministic bytes. Add long verbatim description/widest-money continuation cases to Payslip and `GA | H | 24 | B` association/atomicity cases to Ticket in these existing files (or adjacent focused `*_profile_test.exs` files if that makes fixtures clearer).

## Shared Evidence Patterns

### Candidate → review profile boundary

**Source:** `dev/rendro/catalog_review_payload.ex` lines 29-46 and 115-129.

The review payload validates the candidate then copies only binding identity: `catalog_id`, mode, PNG/PDF hashes, renderer version/SHA, commit SHA, and run ID. Do not add scores or approval fields to candidate output.

### Exact-SHA reconciliation and bundle validation

**Sources:** `dev/rendro/catalog_review_reconciliation.ex` lines 64-107; `dev/rendro/catalog_evidence_bundle.ex` lines 5-20, 41-73, 149-223; `.github/workflows/catalog-evidence.yml` lines 32-66 and 125-139.

The existing route checks detached HEAD equals the supplied lowercase 40-char SHA, verifies PDFium executable SHA, emits a closed `review` bundle with 32 candidate records, 12 final review records, 4 multipage checksums, and 12 preset records, then validates the manifest/checksums/roles/counts. Reuse unchanged. Human review starts only after this validation; inspect reconciled full-size family pairs in the locked order.

### Reviewer truth and canonical publication

**Sources:** `test/rendro/catalog_review_payload_contract_test.exs` lines 54-93; `test/docs_contract/rubric_manifest_contract_test.exs` lines 213-258 and 317-347; `test/docs_contract/catalog_quality_contract_test.exs`.

Keep actual per-cell review scores/provenance reviewer-owned in `priv/quality/rubric_scores.json` and `priv/quality/SIGN-OFF.md`. Test the distinction: phase visual target is hierarchy `5`, other visual dimensions `>=4`, and reading order preserved; canonical rubric `passed` still requires `print_safety == true`. Dark records therefore retain `print_safety: false` and are not synthetically promoted. Run canonical generation/check only after all six targets satisfy the phase threshold and candidate diff proves exactly 6 changed / 26 byte-stable controls.

## No Analog Found

None. The phase deliberately consumes existing profile, table, pagination, candidate, bundle, and review facilities; it must not invent a renderer, UI, public API, or evidence route.

## Test Commands

```sh
mix test test/rendro/catalog_test.exs test/rendro/catalog_review_payload_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs test/docs_contract/catalog_quality_contract_test.exs --max-failures 1
mix test test/rendro/recipes/invoice*_test.exs test/rendro/recipes/statement*_test.exs test/rendro/recipes/payslip*_test.exs test/rendro/recipes/ticket*_test.exs --max-failures 1
mix ci.fast
mix quality.governance
mix rendro.catalog.check
mix quality.uat 136 --check
```

For the advisory raster lane only, dispatch the existing exact-SHA `review` workflow; local PDFium is intentionally not the review authority.

## Metadata

**Analog search scope:** `dev/rendro`, `lib/rendro/recipes`, `test/rendro`, `test/docs_contract`, `.github/workflows`  
**Files scanned:** 34 relevant source/test/workflow files enumerated; 18 primary analogs read  
**Pattern extraction date:** 2026-08-27

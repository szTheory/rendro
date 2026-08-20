# Phase 130: Catalog Quality & Evidence Ratchet - Pattern Map

**Mapped:** 2026-08-19  
**Files classified:** 30 likely modified files  
**Analogs found:** 30 / 30

## File Classification

| New/Modified File | Role | Data flow | Closest existing analog / seam | Match quality |
|---|---|---|---|---|
| `lib/rendro/recipes/{invoice,statement,receipt,certificate,payslip,ticket}.ex` | component | transform / pagination | Their existing supplied-theme seams | exact |
| `lib/rendro/recipes/table_cell.ex` | utility | transform | Existing `TableCell.content/5` | exact |
| `test/rendro/recipes/{invoice,statement,receipt,certificate,payslip,ticket}_test.exs` | test | transform | Existing structural hierarchy tests | exact |
| `test/rendro/recipes/{invoice,statement,receipt,certificate,payslip,ticket}_typography_test.exs` | test | transform | Existing theme/materialization tests | exact |
| `test/rendro/recipes/{invoice,statement,receipt,certificate,payslip,ticket}_byte_identity_test.exs` | test | deterministic bytes | Frozen golden suites | exact |
| `test/rendro/catalog_test.exs` | test | file-I/O / request-response | Existing literal registry and checker tests | exact |
| `test/rendro/catalog_raster_review_test.exs` | test | file-I/O / advisory raster | Existing flagship staging test | exact |
| `test/docs_contract/catalog_quality_contract_test.exs` | test | schema / transform | Existing stale-binding and unscored tests | exact |
| `test/docs_contract/rubric_manifest_contract_test.exs` | test | schema / transform | Existing threshold/projection tests | exact |
| `dev/rendro/catalog.ex` | service | batch / file-I/O | Existing literal registry + generator/checker join | exact |
| `.github/workflows/ci.yml` | config | event-driven / batch | Existing phase-127 isolated payload lane | exact |
| `assets/rendro/catalog.json` | artifact/config | batch output | `Rendro.Catalog.generate/1` output | exact |
| `priv/quality/rubric_scores.json` | evidence record | hash-bound transform | Existing `catalog_dispositions` rows | exact |
| `priv/quality/SIGN-OFF.md` | documentation/evidence | reviewer-owned record | Existing phase-127 sign-off format | role-match |

`dev/mix/tasks/rendro/catalog/gen.ex`, `dev/mix/tasks/rendro/catalog/check.ex`, and `priv/schemas/rubric_scores.schema.json` are inspect-first seams: preserve them unless the final-payload/rebind contract cannot be expressed by the current task/schema shape. Do not add a runtime dependency, theme role, preset, public option, or catalog entry.

## Pattern Assignments

### Recipe supplied-theme hierarchy

**Apply to:** the six recipe modules above.  
**Rule:** recipe code owns hierarchy and semantic color. `catalog_layout` may retain only existing capacity accommodation in Statement and Ticket; do not condition type, ink/muted, labels, rules, or focal treatment on it.

**Public caller to remain truthful** — `dev/rendro/catalog.ex:110-127`:

```elixir
theme = theme_for(spec)
doc = Map.fetch!(spec, :recipe_module).document(data, theme: theme, catalog_layout: true)

if preset = Map.get(spec, :preset_atom),
  do: Rendro.Theme.Presets.register_fonts(doc, preset),
  else: doc
```

Copy each recipe's existing `palette/1` / `typography/1` nil branch. The nil branch is the frozen compatibility branch; supplied theme resolves semantic roles and type. For example, Receipt preserves its literal fallback then resolves themed values at `lib/rendro/recipes/receipt.ex:589-645`.

**Per-family semantic seams:**

| Recipe | Modify / copy from | Structural contract to add or strengthen |
|---|---|---|
| Invoice | `header_section/2`, `build_totals_blocks/2`, and `table_row/4`; table cell analog at `invoice.ex:382-388` | `Total Due` larger/stronger than its due-date neighbor while the arithmetic ladder remains; assert through `Invoice.sections(data, theme: theme)`, never with `catalog_layout`. |
| Statement | closing backdrop/header at `statement.ex:330-450`; shared cells at `statement.ex:669+` | preserve full-width closing-balance band and isolated mono amount. Existing test is the direct shape at `statement_test.exs:149-172`. |
| Receipt | `body_section/2`, `build_totals_blocks/2`, `footer_section/2`; exact current raw-cell defect at `receipt.ex:370-440` | header/description/amount cell ink; only genuinely secondary footer/labels muted; one surface+rule arithmetic backdrop; `Total` sole display fact. |
| Certificate | resolve once and use in emitted text + centering calculations, `certificate.ex:316-429` | recipient `display` > credential/title, both centered with exactly the same resolved sizes as measurement. |
| Payslip | semantic summary overlay at `payslip.ex:466-505` | preserve Net Pay band, right-aligned atomic money, then make the band/amount the public-themed focal fact. |
| Ticket | placement grid at `ticket.ex:304-405`, existing capacity-only geometry at `ticket.ex:615-655` | placement > title > compact reference. Existing all-theme assertion is `ticket_test.exs:273-312`; no return to reference-as-display. |

### Receipt structured table cells and measurement/render parity

**Files:** `lib/rendro/recipes/receipt.ex`, `lib/rendro/recipes/table_cell.ex`, Receipt unit/typography/byte tests.  
**Analog:** Invoice’s implemented public-theme table path, `lib/rendro/recipes/invoice.ex:296-399`; Statement’s documented same-cell pattern at `lib/rendro/recipes/statement.ex:669+`.

**Materialize once; feed the exact values to both APIs**:

```elixir
defp table_row(values, theme, colors, type) do
  Enum.map(values, &Rendro.Recipes.TableCell.content(&1, theme, colors, type, :ink))
end

{header_h, row_heights} =
  Rendro.measure_rows(rows, @content_width, doc_for_measure,
    header: table_row(header, theme, colors, type), columns: @table_columns)

table = Rendro.table(page_rows,
  header: table_row(header, theme, colors, type), columns: @table_columns)
```

`TableCell.content/5` itself preserves literal strings for nil theme and otherwise creates a styled block from semantic role (`lib/rendro/recipes/table_cell.ex:4-18`). Do not fork a Receipt-only color helper.

For themed Receipt measurement, copy Invoice's measurement-document/registry bridge (`invoice.ex:326-339,395-428`): validate/register the exact body/mono roles before `measure_rows/4`, so font metrics match the eventual render.

**Footer:** follow existing region construction (`receipt.ex:433-440`), but materialize the themed page-number style using `colors.muted`; do not change nil-theme output.

**Totals overlay:** copy the established no-flow-displacement idiom, not a regular block behind the totals. Existing Ticket comments and code demonstrate the invariant (`ticket.ex:416-476`): a `Rendro.path` rectangle with `height: 0` overlays at the current cursor without changing flow geometry. Use Receipt semantic `colors.surface` fill and `colors.rule` stroke around the existing totals sequence; normal blocks then occupy the same region flow.

### Recipe test style

**Structural hierarchy tests:** use `sections/2`, select a region, inspect `%Rendro.Text{}` / `%Rendro.Path{}`, and compare sizes. The established Statement form is:

```elixir
[header, _body, _footer] = Statement.sections(data)
text_blocks = Enum.filter(header.content, &is_struct(&1.content, Rendro.Text))
assert closing_value_block.content.size > account_block.content.size
assert Enum.any?(header.content, &is_struct(&1.content, Rendro.Path))
```

Source: `test/rendro/recipes/statement_test.exs:149-172`.

For broad supplied-theme ordering, loop default plus the six presets exactly as Ticket does (`ticket_test.exs:273-295`); invoke `sections(data, theme: theme)` without `catalog_layout`.

**Typography/materialization:** retain the local recursive `find_text/texts` helper pattern from `receipt_typography_test.exs:17-34,68-74`; assert exact `size`, `font`, `line_height`, and now semantic `color` for Receipt cells/footer. The known registration/render assertion is `receipt_typography_test.exs:53-65`.

**No-theme compatibility:** extend behavior only behind supplied `:theme`; leave the existing SHA golden and two-render equality intact. Copy the Receipt assertion pattern at `receipt_byte_identity_test.exs:32-51`, including the frozen `@toy_golden_sha256`; never “refresh” it as part of themed repair.

### Catalog generation, order, and hash-bound rebinds

**Files:** `dev/rendro/catalog.ex`, `test/rendro/catalog_test.exs`, `test/docs_contract/catalog_quality_contract_test.exs`, `assets/rendro/catalog.json`, `priv/quality/rubric_scores.json`.

**Literal registry:** retain `@catalog_specs` as the single ordered source (`catalog.ex:12-76`) and the corresponding explicit list/count guard (`catalog_test.exs:45-74`). No discovery, sorting, map iteration, or surface-area change.

**One writer / one checker:** preserve the strict distinction:

```elixir
# writer: dev/rendro/catalog.ex:140-154
{:ok, cells} <- build_cells(renderer_version)
{:ok, cells} <- apply_quality_projections(cells, read_rubric_scores())
File.write(@manifest_path, encode_manifest(build_manifest(cells, renderer_version)) <> "\n")

# checker: dev/rendro/catalog.ex:157-176
errors = static_contract_errors(read_manifest!(), rubric)
errors = if errors == [], do: errors ++ rendered_contract_errors(read_manifest!()), else: errors
```

Use `mix rendro.catalog.gen` once after all six family pairs stabilize. Before that, `mix rendro.catalog.check` is diagnostic only. Compare the generated identity diff, then update only actually changed unscored `catalog_dispositions` with current `evidence_ref`, PNG SHA, source-PDF SHA, `recorded_at`, and a concrete reason. The checker already demands one disposition per cell and current hashes (`catalog.ex:206-236,550-584`); its existing unscored fixture is `catalog_quality_contract_test.exs:21-45`.

Do not score a mechanical rebind. Do not alter threshold arithmetic (`catalog.ex:696-701`) or use generation to invent a verdict; projections are derived at `catalog.ex:659-694`.

### Final twelve-image payload and CI staging

**Files:** `test/rendro/catalog_raster_review_test.exs`, `.github/workflows/ci.yml`.  
**Analog:** current phase-127 isolated raster lane.

Keep canonical IDs as a literal ordered module attribute (`catalog_raster_review_test.exs:8-21`). Retain per-ID source-PDF rerender and both hash assertions:

```elixir
assert {:ok, pdf} = Rendro.Catalog.render_source_pdf(spec)
assert {:ok, [png]} = Pdfium.render(pdf, dpi: cell["dpi"], pages: "1")
assert sha256(png) == cell["png_sha256"]
assert sha256(File.read!(cell["png_path"])) == cell["png_sha256"]
```

Source: `catalog_raster_review_test.exs:35-43`.

Split the current mixed 16-image output: final review directory/test must contain exactly the twelve canonical page-one images; bounded Invoice/Statement multipage proof must be written to a separately named directory or test. Assert each count/order/identity manifest explicitly. Do not let filesystem sort define the reviewer order.

Copy CI’s branch-gated, pinned-PDFium staging sequence at `.github/workflows/ci.yml:264-305`, but make a narrow phase-130 immutable-SHA branch pattern. Stage `catalog.json`, all 32 PNGs, a **review-only 12-image directory**, and an identity manifest containing `GITHUB_SHA`, `GITHUB_RUN_ID`, PDFium version/SHA, and the complete PNG/source-PDF identities. Required `mix rendro.catalog.check` remains its independent normal CI step (`ci.yml:349-359`), not an advisory-test substitute.

### Reviewer-owned score/sign-off closure

**Files:** `priv/quality/rubric_scores.json`, `priv/quality/SIGN-OFF.md`, schema/contract tests.

Follow the existing scored-unhappy-path fixture (`catalog_quality_contract_test.exs:94-118`): a valid scored record may remain `passed: false` (including dark `print_safety: false`) with observed bounded justification. Only after the pinned final payload exists may the twelve scored records and `SIGN-OFF.md` be updated.

For a light promotion, retain both schema and checker closure: `content_hierarchy == 5`, every other core score at least 4, all gates true (`catalog.ex:696-701`), plus signer/date and concrete `supersedes_evidence_ref` / `resolution_ref` (`catalog.ex:586-643`; schema mutation test `rubric_manifest_contract_test.exs:62-93`). Final deterministic regeneration projects that reviewer decision into `catalog.json`; it never creates the decision.

## Shared Patterns

### Theme and byte-identity boundary

**Sources:** `lib/rendro/recipes/receipt.ex:589-645`, `lib/rendro/recipes/table_cell.ex:4-18`.  
**Apply to:** all six supplied-theme repairs.

- Nil theme: retain historical literals/strings/geometry and golden-byte tests.
- Supplied theme: resolve semantic `ink`, `muted`, `surface`, and `rule`, plus typography roles; presets change values, not recipe branches.
- Explicit `:palette` / `:typography` remain the existing override layer.

### Measurement coupling

**Sources:** `invoice.ex:326-339,395-428`; `certificate.ex:321-429`.  
**Apply to:** Receipt tables and any changed calculated/centered hierarchy.

Resolve values once, use them in both measurement math and emitted AST. Register/validate metric fonts before table measurement. Never use raw strings for measurement and styled blocks for rendering.

### Deterministic versus advisory authority

**Sources:** `dev/rendro/catalog.ex:140-176,550-701`; `.github/workflows/ci.yml:264-305,349-359`.  
**Apply to:** all catalog/evidence work.

- Engineering checkpoints: deterministic only; no score/sign-off/projection edits.
- One generation writes the 32-cell artifact manifest after stabilization.
- One checker validates committed artifact/evidence binding.
- Pinned PDFium plus full-size human review is advisory evidence and must be current/hash-bound; it never makes CI’s deterministic lane optional.

## No Analog Found

None. The phase extends established recipe, catalog, evidence, and CI seams; it should not introduce a new architectural role.

## Metadata

**Analog search scope:** `lib/rendro/recipes`, `dev/rendro`, `dev/mix/tasks`, `test/rendro`, `test/docs_contract`, `.github/workflows`, current catalog/evidence artifacts.  
**Files scanned:** 31 primary source/test/config files plus phase artifacts.  
**Pattern extraction date:** 2026-08-19

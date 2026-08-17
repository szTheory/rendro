# Phase 126: Carryover polish — dark-mode legibility, hierarchy decision & golden/typography depth - Pattern Map

**Mapped:** 2026-08-16  
**Files analyzed:** 15 planned new/modified files (plus affected raster reference rows)  
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/recipes/table_cell.ex` | internal recipe utility | transform | `lib/rendro/recipes/{statement,payslip}.ex` `cell_text/3` | exact semantic-cell construction; new nil-theme compatibility branch |
| `lib/rendro/recipes/invoice.ex` | component / recipe | transform | `lib/rendro/recipes/payslip.ex` | partial: explicit themed table cells |
| `lib/rendro/recipes/ticket.ex` | component / recipe | transform | itself: `main_section/2`, `reference_blocks/6`, `typography/1` | exact seam |
| `lib/rendro/recipes/payslip.ex` | component / recipe | transform | itself: `body_section/2` + `cell_text/3` | exact seam |
| `test/rendro/theme/preset_accent_golden_test.exs` | test | batch / transform | `test/rendro/theme/preset_render_matrix_test.exs` | exact |
| `test/rendro/recipes/invoice_typography_test.exs` | test | transform | `test/rendro/recipes/payslip_opts_threading_test.exs` | role-match |
| `test/rendro/recipes/statement_typography_test.exs` | test | transform | `test/rendro/recipes/payslip_opts_threading_test.exs` | role-match |
| `test/rendro/recipes/certificate_typography_test.exs` | test | transform | `test/rendro/recipes/payslip_opts_threading_test.exs` | role-match |
| `test/rendro/recipes/ticket_typography_test.exs` | test | transform | `test/rendro/recipes/payslip_opts_threading_test.exs` | role-match |
| `test/rendro/recipes/branded_invoice_typography_test.exs` | test | transform | `test/rendro/recipes/branded_invoice_opts_threading_test.exs` | exact |
| `test/rendro/recipes/payslip_typography_test.exs` | test | transform | `test/rendro/recipes/payslip_opts_threading_test.exs` | exact |
| `test/rendro/recipes/receipt_typography_test.exs` | test | transform | `test/rendro/recipes/receipt_opts_threading_test.exs` | exact |
| `test/rendro/theme/preset_raster_snapshot_test.exs` | test / evidence adapter | batch / file-I/O | itself: pinned raster and review-output path | exact |
| `.planning/WINDOWS.md` | config / evidence ledger | event-driven | existing ledger rows | exact |
| `priv/quality/SIGN-OFF.md` | documentation / evidence | transform | existing quality table and honest-finding notes | exact |
| `priv/quality/rubric_scores.json` | config / evidence | transform | existing per-demo score record | exact |

## Pattern Assignments

### `lib/rendro/recipes/invoice.ex` (recipe component, transform)

**Analog:** `lib/rendro/recipes/payslip.ex` — this is the closest already-shipped explicit table-cell implementation. Invoice currently sends bare strings to `Rendro.table/2`, so it has no exact local themed-cell implementation to copy.

**Current row / measurement pattern** (`lib/rendro/recipes/invoice.ex:285-337`):

```elixir
formatted_rows =
  Enum.map(items, fn item ->
    [item.name, Integer.to_string(item.qty), format_price(item.price)]
  end)

table_opts = [header: ["Item", "Qty", "Price"], columns: @table_columns]
{header_h, row_heights} =
  Rendro.measure_rows(formatted_rows, @content_width, doc_for_measure, table_opts)
...
table = Rendro.table(page_rows, table_opts)
```

Keep this literal path for `theme: nil`; branch only the themed table header/body cell construction. Preserve the existing `measure_rows/4` -> `chunk_rows_into_pages/2` -> per-page `Rendro.table/2` flow.

**Themed cell construction to copy** (`lib/rendro/recipes/payslip.ex:659-672`):

```elixir
defp cell_text(text, colors, type),
  do:
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

Use the chosen narrowly shared internal `Rendro.Recipes.TableCell` helper: literal nil theme returns the input String unchanged, while a supplied theme returns a block/text cell with an explicit semantic role. Invoice adopts it for all headers/body values. Statement and Payslip already implement the same explicit semantic-cell behavior through their local helpers, and Ticket's placement grid already supplies explicit colors, so migration churn is unnecessary. Assign `ink` to primary values and only use `muted` where current semantic hierarchy warrants it; do not change global `Rendro.Table` defaults.

**Theme / explicit-override precedence** (`lib/rendro/recipes/invoice.ex:572-626`):

```elixir
base =
  case opts[:theme] do
    nil -> %{ink: {0, 0, 0}, muted: {0, 0, 0}, ...}
    theme -> Rendro.Theme.resolve(theme).colors
  end

Map.merge(base, Keyword.get(opts, :palette, %{}))
```

Keep this exact nil-literal / resolved-theme / caller-override ordering for any helper inputs.

---

### `lib/rendro/recipes/ticket.ex` (recipe component, transform)

**Analog:** the existing Ticket role and geometry seams in `main_section/2`, `reference_blocks/6`, and `typography/1`.

**Dominant placement-grid pattern** (`lib/rendro/recipes/ticket.ex:304-350`):

```elixir
value_cells =
  Enum.map(data.placement, fn %{value: v} ->
    Rendro.block(
      Rendro.text(v,
        size: type.scale.title,
        font: type.fonts.body,
        color: colors.ink,
        line_height: type.leading,
        widows: type.widows,
        orphans: type.orphans
      )
    )
  end)

grid =
  Rendro.table([value_cells],
    header: header_cells,
    columns: List.duplicate({:share, 1}, length(data.placement)),
    borders: :none
  )
```

Retain table-based placement geometry; it is the existing robust multi-column layout primitive. For supplied themes, map this role above event title and reference, while retaining nil-theme values byte-for-byte.

**Reference fit seam** (`lib/rendro/recipes/ticket.ex:512-546`):

```elixir
Rendro.block(
  Rendro.text(reference_text,
    size: type.scale.display,
    font: type.fonts.mono,
    color: colors.ink,
    line_height: type.leading,
    widows: type.widows,
    orphans: type.orphans
  ),
  x: text_x,
  width: avail_w
)
```

Use this existing bounded `avail_w` seam to keep the complete, copyable reference on one normal fixture line. Do not truncate, image-replace, or introduce a preset branch.

**Compatibility and precedence seam** (`lib/rendro/recipes/ticket.ex:685-700`):

```elixir
base =
  case opts[:theme] do
    nil -> %{scale: %{display: 8, title: 26, subtitle: 16, body: 10, small: 9, caption: 8}, ...}
    theme -> Rendro.Theme.resolve(theme).typography
  end

Map.merge(base, Keyword.get(opts, :typography, %{}))
```

Make the semantic remap themed-only and preserve this winning `:typography` merge. The existing nil branch documents its frozen non-monotone historical map; do not modify those literals.

---

### `lib/rendro/recipes/payslip.ex` (recipe component, transform)

**Analog:** its existing measured ledger and private `cell_text/3` implementation.

**Measured fixed-column table pattern** (`lib/rendro/recipes/payslip.ex:549-637`):

```elixir
table_opts = [
  header: [lbl.(:earnings), lbl.(:amount), lbl.(:ytd_amount), "", ...],
  columns: [
    {:share, 2}, {:fixed, @current_col_width}, {:fixed, @ytd_col_width},
    {:fixed, @group_spacer_width}, {:share, 2}, {:fixed, @current_col_width},
    {:fixed, @ytd_col_width}
  ],
  borders: :columns,
  cell_align: %{1 => :right, 2 => :right, 5 => :right, 6 => :right}
]

doc_for_measure = Rendro.Document.new() |> with_unicode_fallback_font()
{header_h, row_heights} = Rendro.measure_rows(all_rows, g.content_w, doc_for_measure, table_opts)
```

Retune only the fixed money columns (or use an already-private fitting seam) after measuring realistic largest Current/YTD tokens with their rendered font context. Preserve the spacer, alignment indices, Decimal formatter, pagination, and `:payslip_sans` measurement fallback.

**Atomic cell construction** (`lib/rendro/recipes/payslip.ex:559-574`, `659-672`):

```elixir
cell_text(fmt_amount_or_blank(Map.get(earn, :amount), fmt_amount), colors, type)
cell_text(fmt_amount_or_blank(Map.get(earn, :ytd), fmt_amount), colors, type)
...
Rendro.text(text, size: type.scale.subtitle, font: type.fonts.body, ...)
```

Use this exact shared helper path for both measurement and rendering; do not shrink the whole scale or expose a public no-wrap option.

---

### `test/rendro/theme/preset_accent_golden_test.exs` (new deterministic golden test, batch/transform)

**Analog:** `test/rendro/theme/preset_render_matrix_test.exs`.

**Imports and table-driven deterministic render loop** (`test/rendro/theme/preset_render_matrix_test.exs:1-7, 37-66`):

```elixir
use ExUnit.Case, async: true

alias Rendro.Recipes.{BrandedInvoice, Certificate, Invoice, Payslip, Receipt, Statement, Ticket}
alias Rendro.Theme.Presets

for {id, genre, mode, recipe} <- @rows do
  theme = Rendro.Theme.preset(genre, accent: "#2C6BED", mode: mode)
  document = document_for(recipe, theme)
  registered = Presets.register_fonts(document, genre)

  assert {:ok, first} = Rendro.render(registered, deterministic: true)
  assert {:ok, second} = Rendro.render(registered, deterministic: true)
  assert first == second
end
```

Create a bounded local variant table: one `Theme.from_brand/2` case plus 2–3 `Theme.preset/2` cases across at least two accents. Use one stable realistic fixture, call `Presets.register_fonts/2` only for preset rows, and bind each SHA-256 in an `@expected_hashes` map. Do not expand this into the 12-row genre/mode matrix.

**Hash assertion pattern** (`test/rendro/recipes/payslip_byte_identity_test.exs:47-64`):

```elixir
assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)
assert sha256 == @toy_golden_sha256
```

---

### Typography-contract tests (tests, transform)

**Files:**

- Modify `test/rendro/recipes/invoice_typography_test.exs`
- Modify `test/rendro/recipes/statement_typography_test.exs`
- Modify `test/rendro/recipes/certificate_typography_test.exs`
- Modify `test/rendro/recipes/ticket_typography_test.exs`
- Create `test/rendro/recipes/branded_invoice_typography_test.exs`
- Create `test/rendro/recipes/payslip_typography_test.exs`
- Create `test/rendro/recipes/receipt_typography_test.exs`

**Closest analog for the three new modules:** their recipe's existing `*_opts_threading_test.exs`; copy its module layout, `sample_data/0`, aliases, no-op seam assertion, and explicit-override behavior. For example (`test/rendro/recipes/payslip_opts_threading_test.exs:73-121`):

```elixir
test "no-op: sections(data) equals sections(data, typography: %{})" do
  assert Payslip.sections(data) == Payslip.sections(data, typography: %{})
end

test "a :typography override changes the output (live seam)" do
  refute Payslip.sections(data) == Payslip.sections(data, typography: %{leading: 2.0})
end

assert {:ok, _} = Rendro.render(Payslip.document(data, theme: Rendro.Theme.default()))
```

Deepen this pattern to inspect materialized emitted `%Rendro.Text{}` data for the scale, role font, and leading—not merely inequality or successful render. Cover explicit `typography:` as the winning layer after `theme:`.

**Curated font registration/error pattern** (`test/rendro/recipes/statement_typography_test.exs:50-60`):

```elixir
theme = Rendro.Theme.preset(:swiss, accent: "#2C6BED")
document = Statement.document(sample_data(), theme: theme)

assert {:error, {:unknown_text_font, :rendro_preset_grotesque}} = Build.run(document)

assert {:ok, _} =
  document
  |> Presets.register_fonts(:swiss)
  |> Build.run()
```

Reuse this explicit bridge behavior for curated-font cases. Retain the current typed error/guard assertions as supplementary coverage; they do not alone satisfy the semantic typography contract.

**Ticket-specific contract revision source** (`test/rendro/recipes/ticket_typography_test.exs:42-73`): preserve the existing `Build.run/1` typed-error assertions but add direct ordering/reference-fit assertions reflecting the new themed semantic hierarchy.

**Certificate special error source** (`test/rendro/recipes/certificate_typography_test.exs:73-96`): retain its `:unsupported_centered_font_role` guard and its leading/vertical-centering assertion; Certificate's centered path legitimately differs from the other recipes.

---

### `test/rendro/theme/preset_raster_snapshot_test.exs` and affected `priv/raster_refs/presets/**` (advisory file-I/O evidence)

**Analog:** current pinned-PDFium evidence lane.

**Pinned provenance + separate advisory bless gate** (`test/rendro/theme/preset_raster_snapshot_test.exs:47-88`):

```elixir
@tag raster_snapshot: true
test "six genre pairs render through pinned PDFium to committed page-one hashes" do
  assert_complete_matrix_contract!()
  assert_pinned_pdfium!()
  ...
  assert_or_bless_page_one_hash(genre, mode, png)
end

if raster_blessing?() do
  if System.get_env("GITHUB_ACTIONS") != "true" do
    raise "MIX_RASTER_BLESS=true must only run in the pinned CI container."
  end
  File.write!(reference_path, actual_hash <> "\\n")
else
  assert actual_hash == expected_hash
end
```

Retain the `raster_snapshot` tag and pinned-PDFium verification. Regenerate/alter only affected rows and hashes; the visual lane is evidence and review ergonomics, not the deterministic test gate.

**Readable sequential review-output seam** (`test/rendro/theme/preset_raster_snapshot_test.exs:97-126`):

```elixir
write_review_png(id, png)
...
File.write!(Path.join(expanded_directory, "#{id}_page_1.png"), png)
```

Use the existing one-PNG-per-row output naming for any requested sequential/lightbox-style human review; do not add a shipped catalog UI in this phase.

---

### `.planning/WINDOWS.md`, `priv/quality/SIGN-OFF.md`, and `priv/quality/rubric_scores.json` (evidence records, transform)

**Analog:** existing honest, evidence-first records.

**Ledger status pattern** (`.planning/WINDOWS.md:18-20`): the affected rows list id, phase, file, factual description, status, and timestamps. Close ids 1–3 only after code, focused tests, deterministic suites, and fresh pinned raster evidence exist; replace the description with the actual validation evidence rather than only changing `open` to `fixed`.

**Human sign-off pattern** (`priv/quality/SIGN-OFF.md:25-29, 42-54`): the table records an explicit verdict, numeric hierarchy score, measured comparison, and a frank finding. Update Invoice/Payslip/Ticket from fresh affected imagery and remove obsolete “open finding” language only where evidence resolves it; keep bounded-legibility language and make no WCAG/PDF-UA claim.

**Machine score record pattern** (`priv/quality/rubric_scores.json:214-269`): modify only the affected demo records (`invoice-acme-phoenix-saas` if dark evidence is represented, `payslip-aurora-live`, `ticket-aurora-live`) with evidence-backed `dimension_scores`, `passed`, timestamps, and detailed `justifications`. Preserve schema shape and unrelated records.

## Shared Patterns

### Nil-theme compatibility and explicit option precedence

**Sources:** `lib/rendro/recipes/invoice.ex:572-626`, `lib/rendro/recipes/ticket.ex:644-700`, `lib/rendro/recipes/payslip.ex:851-936`.

All three target recipes use the same contract: nil selects hand-written historical literals; a supplied theme resolves role values; a caller `:palette` or `:typography` map wins through `Map.merge/2`. New themed behavior must live behind the supplied-theme branch, leaving frozen no-theme hashes intact.

### Engine-owned measurement and pagination

**Sources:** `lib/rendro/recipes/invoice.ex:298-337`, `lib/rendro/recipes/payslip.ex:603-637`.

```elixir
{header_h, row_heights} = Rendro.measure_rows(rows, content_width, measurement_document, table_opts)
pages = Rendro.Recipes.Pagination.chunk_rows_into_pages(rows_with_meta, effective_capacity)
```

Do not estimate text widths locally. Pass the same explicit cell blocks and font fallback context used by rendering into `measure_rows/4`.

### Deterministic and advisory evidence remain separate

**Sources:** `test/rendro/theme/preset_render_matrix_test.exs:37-66`; `test/rendro/theme/preset_raster_snapshot_test.exs:13-88`.

Byte equality and SHA-256 belong in ordinary ExUnit tests; PDFium raster comparison stays tagged, pinned, and separately blessed in CI. Quality documents consume both changed behavior and fresh advisory evidence.

### Curated font bridge

**Sources:** `test/rendro/theme/preset_render_matrix_test.exs:39-58`; `test/rendro/recipes/statement_typography_test.exs:50-60`.

Preset themes intentionally require `Rendro.Theme.Presets.register_fonts(document, genre)` before they render. Keep omission-failure assertions rather than silently substituting fonts, and preserve Payslip's `:payslip_sans` fallback in both measurement and render paths.

## No Analog Found

| File / concern | Role | Data Flow | Reason / planner guidance |
|---|---|---|---|
| Shared themed table-cell semantic boundary | internal recipe utility | transform | No existing shared module: create `Rendro.Recipes.TableCell` from the proven Statement/Payslip block/text construction shape, add the nil-theme literal compatibility clause, and adopt it only in Invoice where the bare-string defect exists. |
| Sequential human review presentation | temporary review artifact | file-I/O | The repository writes individual readable PNGs but has no dedicated slideshow/lightbox implementation. Reuse these images or a non-shipped review mechanism; do not introduce catalog UI. |

## Metadata

**Analog search scope:** `lib/rendro/recipes`, `test/rendro/recipes`, `test/rendro/theme`, `.planning`, `priv/quality`, and affected raster references  
**Files scanned:** 15 primary analog/evidence files; 379 source/test/planning candidates indexed  
**Pattern extraction date:** 2026-08-16

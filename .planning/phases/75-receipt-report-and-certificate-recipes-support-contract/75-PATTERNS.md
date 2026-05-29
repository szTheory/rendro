# Phase 75: Receipt/Report and Certificate Recipes + Support Contract — Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 8
**Analogs found:** 8 / 8

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/recipes/pagination.ex` | utility (private helper) | transform | `lib/rendro/recipes/statement.ex` (extraction source) | exact — verbatim lift |
| `lib/rendro/page_size.ex` | utility | transform | `lib/rendro/page_template.ex` (constants source) | role-match |
| `lib/rendro/recipes/receipt.ex` | recipe (controller) | CRUD + pagination | `lib/rendro/recipes/statement.ex` | exact — same skeleton |
| `lib/rendro/recipes/certificate.ex` | recipe (controller) | request-response | `lib/rendro/recipes/branded_invoice.ex` (branding wiring) + `lib/rendro/recipes/invoice.ex` (three-rung) | role-match |
| `lib/rendro/recipes/statement.ex` (MODIFIED) | recipe (controller) | CRUD + pagination | itself | n/a — refactor only |
| `priv/support_matrix.json` (MODIFIED) | config | n/a | existing entries in `priv/support_matrix.json` | exact — additive |
| `test/rendro/recipes/receipt_test.exs` | test | n/a | `test/rendro/recipes/statement_test.exs` | exact — V1..V10 pattern |
| `test/rendro/recipes/certificate_test.exs` | test | n/a | `test/rendro/recipes/branded_invoice_test.exs` + `test/rendro/recipes/statement_test.exs` | role-match |

---

## Pattern Assignments

### `lib/rendro/recipes/pagination.ex` (private utility, transform)

**Analog:** `lib/rendro/recipes/statement.ex` — direct extraction source.

**Module header pattern** — copy verbatim, change module name:
```elixir
defmodule Rendro.Recipes.Pagination do
  @moduledoc false
```

**Functions to extract verbatim** (source lines from `lib/rendro/recipes/statement.ex`):

`formatter/3` (lines 760–763):
```elixir
defp formatter(opts, key, default_fn) do
  formatters = Keyword.get(opts, :formatters, [])
  Keyword.get(formatters, key, default_fn)
end
```
Change `defp` to `def`.

`label_resolver/1` (lines 767–776):
```elixir
defp label_resolver(opts) do
  user_labels = Keyword.get(opts, :labels, %{})
  fn key ->
    case Map.fetch(user_labels, key) do
      {:ok, val} -> val
      :error -> Rendro.Format.label(key)
    end
  end
end
```
Change `defp` to `def`.

`type_name/1` (lines 779–785):
```elixir
defp type_name(value) when is_binary(value), do: "String"
defp type_name(value) when is_integer(value), do: "Integer"
defp type_name(value) when is_float(value), do: "Float"
defp type_name(value) when is_atom(value), do: "Atom"
defp type_name(value) when is_list(value), do: "List"
defp type_name(value) when is_map(value), do: "Map"
defp type_name(_value), do: "Unknown"
```
Change all `defp` to `def`.

**Shared chunker (new generalized function)** — derived from `chunk_into_pages/5` + `do_chunk_pages/5` + `finalize_page/1` (lines 375–436), but with opaque metadata replacing the Statement-specific `balance` field:

The key change: Statement passes `{fmt_row, height, row_data.balance}` triples. The shared module accepts `{fmt_row, height, opaque_meta}` where `opaque_meta` is `balance` for Statement and `nil` for Receipt. `effective_capacity` is computed by the caller, not inside this function.

```elixir
# Accepts [{fmt_row, height, opaque_meta}] triples.
# Returns [{[fmt_row], last_opaque_meta}] page tuples.
# effective_capacity is pre-computed by the caller (recipe-specific formula).
def chunk_rows_into_pages(rows_with_meta, effective_capacity) do
  do_chunk(rows_with_meta, effective_capacity, [], 0.0, [])
end

defp do_chunk([], _cap, [], _h, pages), do: Enum.reverse(pages)
defp do_chunk([], _cap, current, _h, pages) do
  {rows, meta} = finalize_page(current)
  Enum.reverse([{rows, meta} | pages])
end
defp do_chunk([{fmt_row, height, meta} | rest], cap, current, current_h, pages) do
  new_h = current_h + height
  if new_h <= cap or current == [] do
    do_chunk(rest, cap, [{fmt_row, meta} | current], new_h, pages)
  else
    {rows, page_meta} = finalize_page(current)
    do_chunk([{fmt_row, height, meta} | rest], cap, [], 0.0, [{rows, page_meta} | pages])
  end
end

defp finalize_page(acc) do
  reversed = Enum.reverse(acc)
  rows = Enum.map(reversed, fn {r, _} -> r end)
  {_, last_meta} = List.last(reversed)
  {rows, last_meta}
end
```

**Critical note on statement.ex refactor:** After extracting to this module, Statement's `chunk_into_pages/5` private function becomes a thin wrapper that zips rows with meta and calls `Pagination.chunk_rows_into_pages/2`. The `do_chunk_pages/5` and `finalize_page/1` privates are deleted from `statement.ex`. The `formatter/3`, `label_resolver/1`, and `type_name/1` privates in `statement.ex` are replaced by delegation calls: `Rendro.Recipes.Pagination.formatter(opts, key, default_fn)` etc. All 51 Statement tests must remain green post-refactor.

---

### `lib/rendro/page_size.ex` (utility, transform)

**Analog:** `lib/rendro/page_template.ex` — source of the exact A4 dimension constants.

**Constants from `lib/rendro/page_template.ex`** (lines 6–8):
```elixir
@default_width 595.28
@default_height 841.89
```
These are the A4 portrait values that `PageSize.resolve(:a4, :portrait)` must return. US Letter (`612.0 × 792.0`) is an assumption from the PostScript standard — verify before hardcoding (see RESEARCH.md A1).

**Module pattern:**
```elixir
defmodule Rendro.PageSize do
  @moduledoc false  # private; may be promoted in Phase 76 if needed

  @a4_portrait       {595.28, 841.89}   # matches PageTemplate @default_width/@default_height
  @us_letter_portrait {612.0, 792.0}

  @spec resolve(atom() | {number(), number()}, :portrait | :landscape) :: {number(), number()}
  def resolve(size, orientation \\ :portrait)
  def resolve(:a4, :portrait),         do: @a4_portrait
  def resolve(:a4, :landscape),        do: swap(@a4_portrait)
  def resolve(:us_letter, :portrait),  do: @us_letter_portrait
  def resolve(:us_letter, :landscape), do: swap(@us_letter_portrait)
  def resolve({w, h}, :portrait),      do: {w, h}
  def resolve({w, h}, :landscape),     do: swap({w, h})

  defp swap({w, h}), do: {h, w}
end
```

---

### `lib/rendro/recipes/receipt.ex` (recipe, CRUD + pagination)

**Analog:** `lib/rendro/recipes/statement.ex` — same three-rung skeleton, same chunking/footer machinery.

**Module-level constants** — copy from `statement.ex` lines 86–112, adapt for Receipt:
```elixir
# A4 portrait (same as Statement; Receipt uses same page size by default)
@page_width 595.28
@page_height 841.89
@margin 72
@content_width @page_width - 2 * @margin

# Adjust header/footer heights to Receipt layout
@header_height 48    # title + customer + date rows
@footer_height 24    # Page X of Y
@body_y @margin + @header_height
@body_height @page_height - 2 * @margin - @header_height - @footer_height
@footer_y @page_height - @margin - @footer_height

# Receipt columns: Description | Amount (simpler than Statement's 4 columns)
@table_columns [{:share, 1}, {:fixed, 72}]
@row_epsilon 2.0    # same epsilon as Statement
```

**Three-rung public API** — copy from `statement.ex` lines 140–243, adapting module/section names:

`page_template/1` (lines 141–176): same structure, `name: :receipt` default, same three regions (`:header`, `:body`, `:footer`). Non-zero footer height is **mandatory** (same discipline as Statement, Statement lines 95–96 comment).

`sections/2` (lines 199–207): calls `validate_data!(data)` then `[header_section, body_section, footer_section]`.

`document/2` (lines 231–243): exact copy, changing `:statement` → `:receipt`.

**`validate_data!/1`** — copy the What/Where/Why/Next pattern from `statement.ex` lines 484–523. Required keys for Receipt: `:title`, `:date`, `:customer`, `:lines`, and (optional) `:totals`. Float amount → same error message style (lines 654–664). Missing line keys → same style (lines 612–620).

**`body_section/2`** — the key difference from Statement: no balance fold, no CF/BF rows. Capacity formula does NOT include `- 2 * typical_row_h` (no CF/BF overhead). Copy the measure + chunk + block-emit pattern from `statement.ex` lines 270–364, stripped of the CF/BF logic:

```elixir
# Receipt effective_capacity — simpler than Statement (no CF/BF overhead):
effective_capacity = @body_height - @header_height - @footer_height - header_h - @row_epsilon
# NOTE: do NOT subtract 2 * typical_row_h here (no CF/BF rows)

# Build rows_with_meta: [{fmt_row, height, nil}] — nil meta because no balance tracking
rows_with_meta = Enum.zip([formatted_rows, row_heights])
  |> Enum.map(fn {fmt_row, height} -> {fmt_row, height, nil} end)

pages = Rendro.Recipes.Pagination.chunk_rows_into_pages(rows_with_meta, effective_capacity)
```

Then emit blocks the same way as Statement (lines 331–358), but without CF/BF injection:
```elixir
blocks = Enum.with_index(pages) |> Enum.map(fn {{page_rows, _meta}, idx} ->
  table = Rendro.table(page_rows, table_opts)
  Rendro.block(table, break_before: idx > 0)
end)
# Append totals block to last page only (separate Rendro.block after the last table block)
```

**`footer_section/2`** — identical to Statement lines 438–445:
```elixir
defp footer_section(_data, opts) do
  page_number_opts = Keyword.get(opts, :page_number_opts, [])
  Rendro.section(
    name: :receipt_footer,
    region: :footer,
    content: [Rendro.page_number(page_number_opts)]
  )
end
```

**Shared helpers** — do NOT inline `formatter/3`, `label_resolver/1`, `type_name/1`. Call `Rendro.Recipes.Pagination.formatter/3` etc. directly.

**Totals validation** — mirrors `maybe_validate_closing_balance!` from `statement.ex` lines 679–724, but validates `totals.subtotal == sum(lines.amount)` and `totals.total == subtotal + tax - discount` using `Decimal.equal?/2`.

---

### `lib/rendro/recipes/certificate.ex` (recipe, request-response)

**Analog for branding wiring:** `lib/rendro/recipes/branded_invoice.ex` lines 114–136 (the `document/2` function and `validate_data!/1` lines 195–213).

**Analog for three-rung skeleton:** `lib/rendro/recipes/invoice.ex` lines 50–105.

**WARNING — DO NOT COPY from `branded_invoice.ex`:** The hardcoded region coordinates (`x: 152`, `width: 451.28`, `y: 200`, `height: 569.89`, etc. from `branded_invoice.ex` lines 48–91). These are exactly what CERT-02 forbids. Copy branding registration wiring only.

**Module-level constants — NONE for geometry.** All region coordinates are derived at runtime from `PageSize.resolve/2` output. The only permissible module attributes are non-dimensional defaults:
```elixir
@default_page_size :a4
@default_orientation :landscape
@default_margin 72
```

**`page_template/1`** — entirely new pattern (no codebase analog for geometry-derived regions). Uses `Rendro.PageSize.resolve/2`:
```elixir
def page_template(opts \\ []) do
  page_size   = Keyword.get(opts, :page_size, @default_page_size)
  orientation = Keyword.get(opts, :orientation, @default_orientation)
  {pw, ph}    = Rendro.PageSize.resolve(page_size, orientation)
  ml = Keyword.get(opts, :margin_left,   @default_margin)
  mr = Keyword.get(opts, :margin_right,  @default_margin)
  mt = Keyword.get(opts, :margin_top,    @default_margin)
  mb = Keyword.get(opts, :margin_bottom, @default_margin)

  Rendro.page_template(
    name:          Keyword.get(opts, :name, :certificate),
    width:         pw,
    height:        ph,
    margin_top:    mt,
    margin_right:  mr,
    margin_bottom: mb,
    margin_left:   ml,
    regions: [
      Rendro.region(
        name: :body, role: :body, anchor: :flow,
        x: ml, y: mt,
        width:  pw - ml - mr,   # derived — NEVER a literal
        height: ph - mt - mb    # derived — NEVER a literal
      )
    ]
  )
end
```

**`document/2` with optional branding** — copy the branding wiring from `branded_invoice.ex` lines 114–136, but make `data.brand` optional (Certificate unbranded is valid; BrandedInvoice raises if brand absent):
```elixir
def document(data, opts \\ []) do
  validate_data!(data)
  template = page_template(opts)
  secs = sections(data, opts)

  base_doc = Rendro.Document.new()

  base_doc =
    if brand = Map.get(data, :brand) do
      base_doc
      |> Rendro.Document.register_embedded_font(brand.font_name, {:path, Rendro.Branded.font_path()})
      |> Rendro.Document.register_image(brand.logo_name, {:path, Rendro.Branded.logo_path()})
    else
      base_doc
    end

  base_doc
  |> Rendro.Document.add_template(template)
  |> Rendro.Document.set_template(template.name)
  |> then(fn d -> Enum.reduce(secs, d, &Rendro.Document.add_section(&2, &1)) end)
end
```

**`validate_data!/1`** — required keys: `:title`, `:recipient`, `:date`. Optional: `:body`, `:seal_line`, `:brand`. Copy What/Where/Why/Next style from `statement.ex` lines 484–523. For brand validation:
```elixir
defp validate_brand!(nil), do: :ok   # unbranded is OK (differs from BrandedInvoice!)
defp validate_brand!(%{font_name: f, logo_name: l}) when is_atom(f) and is_atom(l), do: :ok
defp validate_brand!(_brand) do
  raise ArgumentError, "data.brand must include atom :font_name and :logo_name keys"
end
```
This is adapted from `branded_invoice.ex` lines 195–213, but with an explicit `nil` pass-through.

**`sections/2`** — single-page; no chunking. Returns `[body_section(data, opts)]` (no footer section needed for single-page certificate). All text blocks use `align: :center` for the centering effect — no absolute x coordinate computation.

**Shared helpers** — call `Rendro.Recipes.Pagination.formatter/3` and `Rendro.Recipes.Pagination.type_name/1` (for validate_data! error messages). No chunking functions needed.

---

### `lib/rendro/recipes/statement.ex` (MODIFIED — refactor only)

**Change scope:** Replace inline `defp chunk_into_pages/5`, `defp do_chunk_pages/5`, `defp finalize_page/1`, `defp formatter/3`, `defp label_resolver/1`, `defp type_name/1` with calls to the new `Rendro.Recipes.Pagination` module.

**Preserved verbatim:** All public API (`document/2`, `page_template/1`, `sections/2`), all module-level constants (lines 86–112), all `validate_data!` functions (lines 484–752), `fold_balance/2` (lines 457–465), all section builders (lines 250–445), the `@row_epsilon` attribute.

**Refactored call site** in `body_section/2` (current lines 302 and 397):
```elixir
# Before (lines 302, 397):
pages = chunk_into_pages(rows_with_balance, formatted_rows, row_heights, header_h, capacity)
# do_chunk_pages/finalize_page called internally

# After:
rows_with_meta =
  Enum.zip([formatted_rows, row_heights, rows_with_balance])
  |> Enum.map(fn {fmt_row, height, row_data} -> {fmt_row, height, row_data.balance} end)

typical_row_h =
  if Enum.empty?(row_heights), do: 14.4, else: Enum.sum(row_heights) / length(row_heights)

effective_capacity = capacity - header_h - 2 * typical_row_h - @row_epsilon

pages = Rendro.Recipes.Pagination.chunk_rows_into_pages(rows_with_meta, effective_capacity)
```

**Refactored helper calls** (replace all `formatter(opts, ...)` / `label_resolver(opts)` / `type_name(value)` call sites with `Rendro.Recipes.Pagination.formatter(...)` etc.).

**Test gate:** All 51 tests in `test/rendro/recipes/statement_test.exs` must pass green before proceeding to Receipt implementation.

---

### `priv/support_matrix.json` (MODIFIED — additive)

**Analog:** Existing entries in `priv/support_matrix.json` for the shape reference. **Critical:** New rows must NOT have a `"viewers"` sub-key — the `viewer_row` `$def` (which requires `"status"` enum and `"evidence"` matching `^priv/viewer_evidence/...`) is only enforced under `"viewers"` sub-objects. Non-viewer rows are plain flat objects.

**Schema constraints confirmed** (`priv/schemas/support_matrix.schema.json` lines 88–163):
- Root has `"additionalProperties": true` (line 88) — new top-level keys pass without schema change.
- `"viewer_row"` $def uses `"additionalProperties": false` with a strict `evidence` pattern `^priv/viewer_evidence/[a-z0-9_]+/[a-z0-9_]+\\.md$` (line 110). New non-viewer rows must NOT trigger this $def.
- `"required"` at root is `["forms", "signing", "embedded_files", "links", "protection"]` (line 7) — all still present.

**Five new top-level keys to add:**

```json
"page_numbering": {
  "surface": "page_numbering",
  "status": "supported",
  "evidence": "test/rendro/pipeline/paginate_test.exs",
  "recorded_at": "2026-05-29",
  "capabilities": {
    "single_pass_substitution": "supported",
    "deterministic_output": "supported"
  }
},
"statement": {
  "surface": "statement",
  "status": "supported",
  "evidence": "test/rendro/recipes/statement_test.exs",
  "recorded_at": "2026-05-29",
  "capabilities": {
    "multi_page_table_continuation": "supported",
    "running_footer_page_number": "supported",
    "deterministic_output": "supported"
  }
},
"receipt_report": {
  "surface": "receipt_report",
  "status": "supported",
  "evidence": "test/rendro/recipes/receipt_test.exs",
  "recorded_at": "2026-05-29",
  "capabilities": {
    "multi_page_table_continuation": "supported",
    "running_footer_page_number": "supported",
    "deterministic_output": "supported"
  }
},
"certificate": {
  "surface": "certificate",
  "status": "supported",
  "evidence": "test/rendro/recipes/certificate_test.exs",
  "recorded_at": "2026-05-29",
  "capabilities": {
    "geometry_derived_layout": "supported",
    "multi_page_size": "supported",
    "branded_output": "supported",
    "deterministic_output": "supported"
  }
}
```

Insert these after the existing `"protection"` block and before `"unsupported"`. Validate with `mix test test/docs_contract/viewer_evidence_claims_test.exs` after each edit.

---

### `test/rendro/recipes/receipt_test.exs` (test)

**Analog:** `test/rendro/recipes/statement_test.exs` — exact V1..V10 structural pattern.

**Module header** (copy from `statement_test.exs` lines 1–8):
```elixir
defmodule Rendro.Recipes.ReceiptTest do
  use ExUnit.Case, async: true
  alias Rendro.Recipes.Receipt
```

**Fixture helper** (adapted from `statement_test.exs` lines 13–42):
```elixir
defp fixture_data(n, opts \\ []) do
  lines = for i <- 1..max(n, 0)//1 do
    %{description: "Item #{i}", amount: Decimal.new("10.00")}
  end
  base = %{
    title: "Payment Receipt",
    date: ~D[2026-05-29],
    customer: %{name: "Acme Corp"},
    lines: if(n <= 0, do: [], else: lines),
    totals: %{
      subtotal: Decimal.mult(Decimal.new("10.00"), Decimal.new(max(n, 0))),
      total: Decimal.mult(Decimal.new("10.00"), Decimal.new(max(n, 0)))
    }
  }
  Enum.reduce(opts, base, fn {k, v}, acc -> Map.put(acc, k, v) end)
end
```

**`rows_per_page` helper** (adapted from `statement_test.exs` lines 57–73 — same pattern, different capacity formula since Receipt has no CF/BF overhead):
```elixir
defp rows_per_page do
  # Receipt capacity formula (no CF/BF subtraction):
  # effective_capacity = body_height - header_h - footer_h - header_h - @row_epsilon
  content_width = 595.28 - 2 * 72
  table_opts = [header: ["Description", "Amount"], columns: [{:share, 1}, {:fixed, 72}]]
  row = ["Item 1", "$10.00"]
  doc = Rendro.Document.new()
  {header_h, row_heights} = Rendro.measure_rows([row], content_width, doc, table_opts)
  row_h = hd(row_heights)
  body_height = 841.89 - 2 * 72 - 48 - 24   # same page geometry as Statement
  capacity = body_height - 48 - 24
  effective_cap = capacity - header_h - 2.0  # no CF/BF subtraction
  trunc(effective_cap / row_h)
end
```

**Test groups** (follow `statement_test.exs` V1..V10 naming, adapted for Receipt):

| Group | Source analog (statement_test.exs) | Key Receipt difference |
|-------|-----------------------------------|-----------------------|
| V1: `document/2` basic | lines 96–140 | `:receipt` template name; `:title`/`:customer` in header |
| V2: single-page page count | lines 146–199 | same `rows_per_page()` helper; "Page 1 of 1" |
| V3: multi-page continuation | lines 146–199 | column headers repeat (via per-page table `header:` option) |
| V4: footer page numbers | lines 372–411 | "Page X of Y" correct; no unresolved tokens |
| V5: totals block | (new) | totals block present on last page only; `Decimal.equal?` validation |
| V6: `validate_data!/1` | lines 418–497 | Float amount raises; missing key raises; malformed totals raises |
| V7: three-rung escape hatch | lines 504–561 | `page_template/1`, `sections/2` callable independently |
| V8: determinism | lines 567–590 | byte-identical with `deterministic: true` |
| V9: no `:content_overflow` | lines 596–614 | boundary row counts render without error |
| V10: no `keep_together` | lines 620–657 | no body block has `keep_together: true`; `break_before: true` on non-first blocks |

**Key test patterns to copy directly from `statement_test.exs`:**

`render_statement!` helper pattern (lines 76–82) — copy as `render_receipt!`.

No-unresolved-tokens assertion (line 407–410):
```elixir
refute pdf =~ "{{page_number}}"
refute pdf =~ "{{total_pages}}"
```

Break-before invariant (lines 628–637):
```elixir
[first | rest] = blocks
refute first.break_before
Enum.each(rest, fn block -> assert block.break_before == true end)
```

Determinism pattern (lines 568–573):
```elixir
doc = Receipt.document(fixture_data(5))
{:ok, pdf1} = Rendro.render(doc, deterministic: true)
{:ok, pdf2} = Rendro.render(doc, deterministic: true)
assert pdf1 == pdf2
```

---

### `test/rendro/recipes/certificate_test.exs` (test)

**Analog 1:** `test/rendro/recipes/branded_invoice_test.exs` — branding registration assertions (lines 70–83).
**Analog 2:** `test/rendro/recipes/statement_test.exs` — determinism pattern (lines 567–590).

**Module header:**
```elixir
defmodule Rendro.Recipes.CertificateTest do
  use ExUnit.Case, async: true
  alias Rendro.Recipes.Certificate
```

**Fixture helper:**
```elixir
defp fixture_data(opts \\ []) do
  base = %{
    title: "Certificate of Completion",
    recipient: "Jane Smith",
    body: "Successfully completed the Elixir PDF generation course.",
    date: ~D[2026-05-29],
    seal_line: "Signed by the Director"
  }
  Enum.reduce(opts, base, fn {k, v}, acc -> Map.put(acc, k, v) end)
end

defp branded_data do
  Map.put(fixture_data(), :brand, %{
    font_name: :brand_heading,
    logo_name: :company_logo
  })
end
```

**C1–C13 test groups** (per RESEARCH.md test plan):

C1–C2: basic render (copy PDF binary assertions from `branded_invoice_test.exs` lines 59–67, adapted).

C3–C7: geometry assertions — no direct codebase analog, entirely new pattern:
```elixir
# C3: Geometry-derived body width at A4-landscape
test "body region width equals page_width - 2*margin for A4-landscape" do
  template = Certificate.page_template(page_size: :a4, orientation: :landscape)
  body = Enum.find(template.regions, & &1.role == :body)
  # A4-landscape: pw = 841.89, ph = 595.28; content_w = 841.89 - 144 = 697.89
  assert_in_delta body.width, 841.89 - 144, 0.01
end

# C5: Width differs between page sizes (proves no hardcoded A4 numerics)
test "body region width differs between A4-landscape and US-Letter-landscape" do
  t_a4 = Certificate.page_template(page_size: :a4, orientation: :landscape)
  t_us = Certificate.page_template(page_size: :us_letter, orientation: :landscape)
  body_a4 = Enum.find(t_a4.regions, & &1.role == :body)
  body_us = Enum.find(t_us.regions, & &1.role == :body)
  refute_in_delta body_a4.width, body_us.width, 0.01
end

# C6: Landscape default (template.width > template.height for A4)
test "default orientation is landscape (template.width > template.height)" do
  template = Certificate.page_template()
  assert template.width > template.height
end
```

C8–C10: branding assertions — copy directly from `branded_invoice_test.exs` lines 70–113:
```elixir
# C8: font/image registered (from branded_invoice_test.exs lines 70–83)
test "brand font is registered as embedded source" do
  doc = Certificate.document(branded_data())
  assert Map.has_key?(doc.font_registry.fonts, :brand_heading)
end

test "brand logo is registered" do
  doc = Certificate.document(branded_data())
  assert Map.has_key?(doc.asset_registry.assets, :company_logo)
end

# C9: unbranded renders without error (new — BrandedInvoice has no equivalent)
test "certificate without brand renders without error" do
  doc = Certificate.document(fixture_data())
  assert {:ok, pdf} = Rendro.render(doc)
  assert is_binary(pdf)
end

# C10: malformed brand raises (from branded_invoice_test.exs lines 86–113, adapted)
test "malformed brand raises ArgumentError" do
  assert_raise ArgumentError, ~r/brand/, fn ->
    Certificate.document(Map.put(fixture_data(), :brand, %{font_name: "not_atom"}))
  end
end
```

C11: determinism — copy from `statement_test.exs` lines 568–573, using `Certificate.document(fixture_data())`.

C12: three-rung — copy from `statement_test.exs` lines 504–561 pattern, adapted for Certificate.

C13: `validate_data!/1` — copy from `statement_test.exs` lines 418–476 pattern:
```elixir
test "missing :title raises ArgumentError" do
  assert_raise ArgumentError, fn ->
    Certificate.document(Map.delete(fixture_data(), :title))
  end
end
```

---

## Shared Patterns

### Three-Rung Escape Hatch (all recipe files)
**Source:** `lib/rendro/recipes/invoice.ex` lines 50–105 + `lib/rendro/recipes/statement.ex` lines 140–243.
**Apply to:** `receipt.ex`, `certificate.ex`.

The canonical pattern (from `invoice.ex` lines 93–105):
```elixir
def document(data, opts \\ []) do
  template = page_template(opts)
  secs = sections(data, opts)
  base_doc =
    Rendro.Document.new()
    |> Rendro.Document.add_template(template)
    |> Rendro.Document.set_template(template.name)
  Enum.reduce(secs, base_doc, fn section, doc ->
    Rendro.Document.add_section(doc, section)
  end)
end
```

### Errors-as-Product Validation Pattern
**Source:** `lib/rendro/recipes/statement.ex` lines 484–523.
**Apply to:** `receipt.ex`, `certificate.ex` validate_data!/1.

The What/Where/Why/Next raise style:
```elixir
raise ArgumentError, """
Rendro.Recipes.Receipt.document/2 — missing required key(s) in data.

What:  Required receipt data keys are missing.
Where: Rendro.Recipes.Receipt.validate_data!/1
Why:   Missing key(s): #{inspect(missing)}.
Next:  Provide all required keys: :title, :date, :customer, :lines.
"""
```

### Non-Zero Footer Height (Receipt)
**Source:** `lib/rendro/recipes/statement.ex` lines 95–96 comment + `test/rendro/recipes/statement_test.exs` lines 527–530.
**Apply to:** `receipt.ex` `page_template/1`.

Footer region MUST have `height: @footer_height` (non-zero) for `body_capacity` to correctly reserve space. The test asserts `footer.height > 0`.

### Decimal.equal?/2 Validation
**Source:** `lib/rendro/recipes/statement.ex` lines 706–721.
**Apply to:** `receipt.ex` totals validation.

```elixir
unless Decimal.equal?(supplied, derived) do
  raise ArgumentError, """
  ...mismatch...
  """
end
```

### Page-Number Footer Section
**Source:** `lib/rendro/recipes/statement.ex` lines 438–445.
**Apply to:** `receipt.ex` `footer_section/2`.

```elixir
defp footer_section(_data, opts) do
  page_number_opts = Keyword.get(opts, :page_number_opts, [])
  Rendro.section(
    name: :receipt_footer,
    region: :footer,
    content: [Rendro.page_number(page_number_opts)]
  )
end
```

### Break-Before Pagination (no keep_together)
**Source:** `lib/rendro/recipes/statement.ex` line 357.
**Apply to:** `receipt.ex` body_section/2 block emission.

```elixir
Rendro.block(table, break_before: idx > 0)
# NEVER: Rendro.block(table, keep_together: true) — causes :content_overflow
```

### Branding Registration Wiring
**Source:** `lib/rendro/recipes/branded_invoice.ex` lines 114–136.
**Apply to:** `certificate.ex` document/2.

Copy the `if brand = Map.get(data, :brand)` conditional registration pattern. For Certificate, the `else` branch returns `base_doc` unchanged (unbranded is valid).

---

## No Analog Found

All files have usable analogs. The following aspects have NO direct codebase analog and must use RESEARCH.md patterns:

| File | Aspect | Reason |
|------|--------|--------|
| `lib/rendro/recipes/certificate.ex` | Geometry-derived region coordinates | Every existing recipe (Statement, Invoice, BrandedInvoice) hardcodes A4 numerics — Certificate deliberately departs from this |
| `lib/rendro/page_size.ex` | Named page-size resolution | No prior `Rendro.PageSize` or equivalent in codebase |
| `test/rendro/recipes/certificate_test.exs` | `assert_in_delta` geometry tests (C3, C4, C5) | No existing recipe tests inspect region geometry |

---

## Metadata

**Analog search scope:** `lib/rendro/recipes/`, `lib/rendro/`, `test/rendro/recipes/`, `priv/`
**Files read:** 10 source files (statement.ex, invoice.ex, branded_invoice.ex, page_template.ex, branded.ex, support_matrix.json, support_matrix.schema.json, statement_test.exs, branded_invoice_test.exs, rendro.ex partial)
**Pattern extraction date:** 2026-05-29

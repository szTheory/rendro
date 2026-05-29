# Phase 75: Receipt/Report and Certificate Recipes + Support Contract — Research

**Researched:** 2026-05-29
**Domain:** Elixir/Phoenix recipe layer — tabular receipt/report recipe, certificate recipe, support-matrix non-viewer rows
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Carried forward from Phase 74 (D-01..D-11 of Phase 74):** `Decimal` money type; signed-`amount` line model; recipe owns pagination; `Rendro.measure_rows/4` for engine-true row heights; `Rendro.Format` deterministic defaults; errors-as-product `validate_data!/1`; bare atom-keyed map data contract; `Rendro.page_number/1` in footer.

**Phase 75 decisions:**
- **D-01:** One `Rendro.Recipes.Receipt` recipe — a long receipt IS a report (no separate module).
- **D-02:** Receipt reuses Statement's table-continuation machinery via D-04 extraction.
- **D-03:** Receipt data map: bare atom-keyed map with required top-level keys for header summary + `lines` + totals; per-line `%{description, amount, ...}` with Decimal; totals are caller-asserted or recipe-derived.
- **D-04:** Extract shared recipe pagination/formatting machinery into a private `Recipes.Base`-style module; refactor Statement onto it; keep private.
- **D-05:** Certificate defaults to landscape orientation (swap width/height).
- **D-06:** All Certificate coordinates derived from template geometry — ZERO hardcoded A4 numerics.
- **D-07:** Add a small named page-size helper (`:a4` → 595.28×841.89, `:us_letter` → 612×792, landscape = swapped). Claude's discretion on placement.
- **D-08:** Certificate branding mirrors `BrandedInvoice` registration path; missing/invalid brand raises.
- **D-09:** Recipe/PAGE-primitive surfaces are NON-viewer-sensitive — recorded as `supported` with determinism+structural-proof evidence, NOT a per-viewer matrix.
- **D-10:** Five new surface rows: `running_header`, `running_footer` (or one `page_numbering` row — align with Phase 73 shipped names), `statement`, `receipt_report`, `certificate`. Backfill Statement row (shipped Phase 74 without one).

### Claude's Discretion
- Exact module layout of `Rendro.Recipes.Receipt` and `Rendro.Recipes.Certificate`.
- Name/placement/internal API of the extracted shared recipe helper (D-04) and page-size helper (D-07).
- Exact Receipt required-key set, totals shape, whether header summary is fixed-key or free block list.
- Precise `validate_data!/1` message wording for both recipes.
- Exact `priv/support_matrix.json` key names/grouping for new surfaces (D-09/D-10).
- Whether page-size helper lives in a new `Rendro.PageSize` module or as options on `Rendro.page_template/1`.

### Deferred Ideas (OUT OF SCOPE)
- Public `Rendro.Recipes.Base` module (stays private this phase).
- Separate `Rendro.Recipes.Report` module.
- Conventional Debit/Credit display columns.
- Currency/locale-aware formatting in core.
- Aligning Invoice/BrandedInvoice onto `Rendro.Format` and geometry-derived coords.
- Reference Phoenix app + HexDocs guides + CONTRACT-02 (Phase 76).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RCPT-01 | Receipt/Report from data map (header summary, line items, totals); table column headers repeat across pages; "Page X of Y" running footer | Chunking machinery from Statement; `stacked_header` in paginate.ex confirms per-table header repetition |
| RCPT-02 | Three-rung escape hatch consistent with Invoice | Invoice.ex and Statement.ex both demonstrate the pattern; direct copy |
| RCPT-03 | Multi-page continuation with running footers, deterministically | Inherited from Statement; same chunking + `Rendro.page_number/1` footer |
| CERT-01 | Certificate from data map (title, recipient, body, date, seal line) | New recipe; no table pagination needed; single-page output |
| CERT-02 | All coordinates from template geometry; renders at multiple page sizes; multi-size test | PageTemplate exposes `width`/`height`/margins; geometry formulas documented below |
| CERT-03 | Branded output (fonts/images) consistent with BrandedInvoice | BrandedInvoice.document/2 is the direct pattern; reuse wiring, not geometry |
| CONTRACT-01 | Terminal `priv/support_matrix.json` rows for every new surface; no silent `unverified` | Schema allows `additionalProperties: true` at root; `viewer_row` $defs used ONLY under `*.viewers` maps; non-viewer surfaces can use a flat object shape; Matrix.enumerate_viewer_cells/1 only scans the 8 existing viewer_maps — new non-viewer rows are schema-valid but not enumerated |
</phase_requirements>

---

## Summary

Phase 75 delivers two new recipes and closes the support-matrix gap for all surfaces introduced in Phases 73-75. All three work-streams are well-bounded by the existing codebase.

**Receipt/Report:** This is a Statement variant without running balances and with a totals block. The D-04 shared-helper extraction is the load-bearing architectural move — Statement's `chunk_into_pages`/`do_chunk_pages`/`effective_capacity` math plus the `formatter`/`label_resolver` helpers are pure functions that can be lifted into a private module with zero logic changes. Receipt then calls the same functions. The only Receipt-specific logic is its simpler body (no CF/BF rows, just line items + totals) and its data-map shape.

**Certificate:** Single-page, landscape, geometry-derived. The central discipline (CERT-02) requires computing all region x/y/width/height as expressions over `pt.width`, `pt.height`, `pt.margin_*` rather than hardcoded numerics. A page-size helper (`Rendro.PageSize` or inline in `Rendro.page_template/1`) converts `:a4`/`:us_letter` atoms to raw point pairs with landscape swap. Branding wiring copies from `BrandedInvoice.document/2` exactly.

**Support contract:** The JSON-Schema validator (`priv/schemas/support_matrix.schema.json`) uses `"additionalProperties": true` at the root level, meaning new top-level keys (e.g. `"page_numbering"`, `"statement"`, `"receipt_report"`, `"certificate"`) pass structural validation without any schema changes. The `viewer_row` $def with its `"status"` enum is only enforced under `*.viewers` sub-objects. Non-viewer surfaces use a flat object shape (capabilities + evidence pointer) that does NOT invoke `viewer_row` validation. `Matrix.enumerate_viewer_cells/1` does NOT enumerate these new keys, so `validate_promotion_complete` will not fail on them — they are schema-valid, orphan-safe, and pass `run_full`.

**Primary recommendation:** Extract D-04 shared helper first (Wave 1), build Receipt on it (Wave 2), build Certificate in parallel with Receipt (Wave 2), then add support-matrix rows and run `mix test` to verify the docs-contract lane still passes (Wave 3).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Receipt pagination (chunking) | Recipe layer (`Recipes.Base` private helper) | Engine (executes `break_before` directives) | Recipe pre-decides page breaks; engine is single-pass |
| Receipt column header repetition | Engine (`paginate.ex stacked_header`) | Recipe (emits one table per page with header option) | Engine's `split_table` already re-emits `table.header` on continuation — recipe DOES re-emit the whole table per page (same as Statement); header appears because `table(rows, header: [...])` is passed per-page |
| Receipt totals | Recipe layer (compute and append as final block) | — | No engine support; recipe builds a separate block after the line items table |
| Receipt "Page X of Y" | Engine (token substitution in `replace_page_numbers/3`) | Recipe (configures non-zero footer height + `Rendro.page_number/1`) | Same as Statement |
| Certificate layout geometry | Recipe layer (`Certificate.page_template/1`) | Engine (renders the regions) | All coords derived in recipe from `pt.width`/`pt.height`/margins; engine just renders |
| Certificate page-size abstraction | Recipe layer (`Rendro.PageSize` or inline helper) | — | Pure deterministic helper; zero engine involvement |
| Certificate branding | Recipe layer (`document/2` registers font+image) | Engine (embeds registered assets) | Mirrors `BrandedInvoice.document/2` exactly |
| Shared chunking/capacity math | Private `Rendro.Recipes.Pagination` (or `Base`) | — | Extracted from Statement; Receipt calls identical functions |
| Support-matrix rows | `priv/support_matrix.json` (additive edit) | `Matrix.enumerate_viewer_cells/1` (unchanged) | New top-level keys are schema-valid; existing validator does not enumerate them |

---

## Standard Stack

### Core (already in mix.exs — no new deps)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `decimal` | `~> 2.3` | Exact monetary arithmetic | Already declared in Phase 74; both recipes use Decimal |
| Elixir stdlib | 1.19+ | Date, Enum, Regex | No additions needed |

[VERIFIED: existing mix.exs] — All deps needed for Phase 75 are already present. Phase 75 adds ZERO new runtime dependencies.

### No New Packages Required

All machinery (measure_rows, page_number, table, block, section, region, page_template, Format, Branded) is already public API in `lib/rendro.ex` and `lib/rendro/format.ex`. The phase is pure recipe-layer composition.

---

## Architecture Patterns

### System Architecture Diagram

```
Receipt.document(data, opts)
  │
  ├─► validate_data!(data)                          [errors-as-product]
  ├─► Receipt.page_template(opts)                   [rung 1]
  │     └─► Rendro.Recipes.Pagination.build_template(:receipt, opts)  [shared helper]
  ├─► Receipt.sections(data, opts)                  [rung 2/3]
  │     ├─► header_section   → summary block(s)
  │     ├─► body_section
  │     │     ├─► Measure rows via Rendro.measure_rows/4
  │     │     ├─► Rendro.Recipes.Pagination.chunk_pages(rows, ...)    [shared helper]
  │     │     └─► emit [Rendro.block(table, break_before: idx > 0), ...]
  │     │           + totals block (final page only, or appended to last block)
  │     └─► footer_section  → Rendro.page_number/1                    [PAGE primitive]
  └─► Rendro.Document.new() |> add_template |> set_template |> reduce add_section

Certificate.document(data, opts)
  │
  ├─► validate_data!(data)
  ├─► Certificate.page_template(opts)
  │     └─► resolve page_size (atom → {w, h} via PageSize helper, landscape swap)
  │         → Rendro.page_template(width: w, height: h, regions: [...derived...])
  ├─► Certificate.sections(data, opts)
  │     ├─► [optional] logo_section   (if brand.logo_name)
  │     ├─► body_section              → centered title + recipient + body + date + seal
  │     └─► [no footer needed for single-page]
  └─► [if branded] doc |> register_embedded_font |> register_image |> ...

Statement (refactored — unchanged public surface)
  └─► calls Rendro.Recipes.Pagination.chunk_pages/... instead of private defp
      (all existing tests pass byte-for-byte)
```

### Recommended Project Structure

```
lib/rendro/recipes/
├── pagination.ex          # NEW private shared helper (D-04); @moduledoc false
├── receipt.ex             # NEW Rendro.Recipes.Receipt
├── certificate.ex         # NEW Rendro.Recipes.Certificate
├── statement.ex           # REFACTORED — calls pagination.ex helpers
├── invoice.ex             # unchanged
└── branded_invoice.ex     # unchanged

lib/rendro/
└── page_size.ex           # NEW (optional) Rendro.PageSize; or inline in rendro.ex

test/rendro/recipes/
├── receipt_test.exs       # NEW
├── certificate_test.exs   # NEW
└── statement_test.exs     # UNCHANGED (all 51 tests must stay green)

priv/support_matrix.json   # ADDITIVE — 5 new top-level keys
```

### Pattern 1: Shared Pagination Helper (D-04) Extraction

**What:** Lift `chunk_into_pages/5`, `do_chunk_pages/5`, `finalize_page/1`, `formatter/3`, `label_resolver/1`, and `type_name/1` from `statement.ex` into a private `Rendro.Recipes.Pagination` module (`@moduledoc false`). Statement's `body_section/2` is refactored to call `Pagination.chunk_into_pages/5` etc. Receipt calls the same functions.

**Exact functions to extract (verified in statement.ex):**

| Function | Signature (as-is) | Shared by |
|----------|-------------------|-----------|
| `chunk_into_pages/5` | `(rows_with_balance, formatted_rows, row_heights, header_h, capacity)` | Statement, Receipt |
| `do_chunk_pages/5` | `([{fmt_row, height, balance} | rest], cap, current_page, current_h, pages)` | Statement, Receipt |
| `finalize_page/1` | `(page_acc)` | Statement, Receipt |
| `formatter/3` | `(opts, key, default_fn)` | Statement, Receipt, Certificate |
| `label_resolver/1` | `(opts)` | Statement, Receipt |
| `type_name/1` | `(value)` | Statement, Receipt, Certificate (validate errors) |

**Important:** `chunk_into_pages/5` is Statement-specific in one detail — it uses a `balance` field from each row tuple `{fmt_row, balance}`. Receipt rows have no balance; Receipt needs a simpler chunker or a variant that doesn't track balance. **Recommendation:** rename the shared function to `chunk_rows_into_pages/5` and have it accept `{fmt_row, height, metadata}` triples where `metadata` is opaque (Statement passes `balance`, Receipt passes `nil`). The `finalize_page/1` returns `{rows, last_metadata}`.

**Preservation of Statement determinism:** The refactoring is purely mechanical — no logic changes, same function bodies, same call sites. Statement's 51 existing tests must all pass green after refactoring. The planner MUST add a test-gate task between the extraction plan and the Receipt plan.

**Where to put it:** `lib/rendro/recipes/pagination.ex`, `defmodule Rendro.Recipes.Pagination`, `@moduledoc false`. Since it is private (not referenced from the public API), no docs or typespec changes in `rendro.ex` are needed.

```elixir
# Source: verified analysis of lib/rendro/recipes/statement.ex
defmodule Rendro.Recipes.Pagination do
  @moduledoc false

  # Returns the formatter function for `key` from opts[:formatters], or falls
  # back to `default_fn`. (Extracted verbatim from statement.ex)
  def formatter(opts, key, default_fn) do
    formatters = Keyword.get(opts, :formatters, [])
    Keyword.get(formatters, key, default_fn)
  end

  # Returns a function that resolves a label key, merging caller-supplied
  # :labels over the Rendro.Format defaults.
  def label_resolver(opts) do
    user_labels = Keyword.get(opts, :labels, %{})
    fn key ->
      case Map.fetch(user_labels, key) do
        {:ok, val} -> val
        :error -> Rendro.Format.label(key)
      end
    end
  end

  # Generic row chunker. `rows_with_meta` is [{fmt_row, height, opaque_meta}].
  # Returns [{[fmt_row], opaque_meta_of_last_row}] page tuples.
  def chunk_rows_into_pages(rows_with_meta, effective_capacity, epsilon \\ 2.0) do
    do_chunk(rows_with_meta, effective_capacity - epsilon, [], 0.0, [])
  end

  # ... do_chunk, finalize_page etc. (verbatim logic from statement.ex)
end
```

**Caption:** `effective_capacity` is computed by the caller (Statement or Receipt) because it is recipe-specific (Statement subtracts 2 * typical_row_h for CF/BF overhead; Receipt subtracts only header_h + epsilon since there are no CF/BF rows).

### Pattern 2: Receipt Body (RCPT-01)

**Data contract (D-03):**

```elixir
# Required top-level keys:
%{
  title:    String.t(),              # e.g. "Payment Receipt"
  date:     Date.t(),               # issue date
  customer: %{name: String.t()},    # or just %{name: "..."}
  lines:    [%{
    description: String.t(),
    amount:      Decimal.t(),
    # Optional: quantity: integer() — recipe renders if present
  }],
  totals: %{
    subtotal: Decimal.t(),          # caller assertion (recipe validates sum)
    # Optional: tax: Decimal.t(), discount: Decimal.t()
    total:    Decimal.t()           # caller assertion (recipe validates)
  }
}
```

**Why this shape:** Mirrors Statement's `account`/`period`/`lines`/`opening_balance` pattern; `totals` as a caller-assertion map parallels Statement's `closing_balance` + `summary` (Decimal.equal? validation). `title` + `customer` + `date` maps to Statement's `account` + `period` header content.

**Column structure (RCPT-01 — repeating table headers):**
The engine handles column header repetition automatically through the `split_table` / `stacked_header` path in `paginate.ex` (lines 106-125). When the recipe emits one table per page (same as Statement), each table's `header:` option re-emits the header row on each page. **There is NO action needed in the recipe beyond the same per-page table approach already used in Statement.** The engine does NOT need to be changed.

**Proven by:** `stacked_header` in `stack_table_cells/1` (paginate.ex ~106): every `%Rendro.Table{}` with a `header` gets its header row stacked at the top of its block. Since each page's block is its own `Rendro.table(page_rows, header: [...])`, the header naturally appears on every page.

**Receipt body sections:**
1. Header region: `title`, `customer.name`, `date` text blocks (no running balance needed).
2. Body region: line-items table (chunked across pages with `break_before`), totals block appended to the last page's content.
3. Footer region: `Rendro.page_number/1` with non-zero reserved height.

**Single-page path:** A short receipt with all lines fitting one page → one body block, `break_before: false`. Footer reads "Page 1 of 1". This is identical to the Statement single-page path — no special case needed.

**Totals validation:** Same discipline as `maybe_validate_closing_balance!` in Statement:
```elixir
# If caller supplies totals.subtotal, validate it equals sum(lines.amount).
# If caller supplies totals.total, validate it equals subtotal + tax - discount.
# Decimal.equal?/2 comparison, not structural ==.
```

**RCPT-03 determinism proof:** Two renders of the same `Receipt.document(data)` with `deterministic: true` produce byte-identical output. Verified by the same test pattern as Statement's V10 test suite.

### Pattern 3: Certificate Geometry Derivation (CERT-02)

**The constraint:** ZERO hardcoded numerics. Every region coordinate is an expression over `pt.width`, `pt.height`, `pt.margin_top`, `pt.margin_right`, `pt.margin_bottom`, `pt.margin_left`.

**Page-size helper (D-07):** Recommended placement is a new `Rendro.PageSize` module:

```elixir
defmodule Rendro.PageSize do
  @moduledoc false  # or public if the planner decides to expose it

  # Portrait (width < height)
  @a4_portrait       {595.28, 841.89}
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

[ASSUMED] — Module name and exact signature; no prior `Rendro.PageSize` in the codebase.

**Certificate `page_template/1` — geometry-derived regions:**

```elixir
# Source: analysis of lib/rendro/page_template.ex + CERT-02 constraint
def page_template(opts \\ []) do
  page_size = Keyword.get(opts, :page_size, :a4)
  orientation = Keyword.get(opts, :orientation, :landscape)  # D-05 default
  {pw, ph} = Rendro.PageSize.resolve(page_size, orientation)

  # Caller-overridable margins (default 72pt = 1 inch)
  ml = Keyword.get(opts, :margin_left, 72)
  mr = Keyword.get(opts, :margin_right, 72)
  mt = Keyword.get(opts, :margin_top, 72)
  mb = Keyword.get(opts, :margin_bottom, 72)

  content_w = pw - ml - mr   # all derived
  content_h = ph - mt - mb

  Rendro.page_template(
    name: Keyword.get(opts, :name, :certificate),
    width: pw,
    height: ph,
    margin_top: mt,
    margin_right: mr,
    margin_bottom: mb,
    margin_left: ml,
    regions: [
      # Body spans the full content area (no running header/footer needed for single-page)
      Rendro.region(
        name: :body,
        role: :body,
        anchor: :flow,
        x: ml,
        y: mt,
        width: content_w,
        height: content_h
      )
    ]
  )
end
```

**Certificate body content — geometry-derived layout:**
Since the body region spans the full content area (`width: content_w`, `height: content_h`), all positioning is handled by block stacking (flow layout). The "centered" effect is achieved via text alignment (`align: :center`), NOT by computing absolute x coordinates. This naturally adapts to any page size.

```elixir
defp body_section(data, opts, pt) do
  # pt = page_template struct; content_w = pt.width - pt.margin_left - pt.margin_right
  # All sizes are relative to content_w, NOT to hardcoded A4 numerics.
  content_w = pt.width - pt.margin_left - pt.margin_right

  Rendro.section(
    name: :certificate_body,
    region: :body,
    content: [
      Rendro.block(Rendro.text(data.title, size: 28, align: :center, font: brand_font)),
      Rendro.block(Rendro.text("This certifies that", size: 12, align: :center)),
      Rendro.block(Rendro.text(data.recipient, size: 20, align: :center, font: brand_font)),
      Rendro.block(Rendro.text(data.body, size: 11, align: :center)),
      Rendro.block(Rendro.text(fmt_date.(data.date), size: 10, align: :center)),
      # Spacer block + seal/signature line
      Rendro.block(Rendro.text(data.seal_line || "", size: 10, align: :center))
    ]
  )
end
```

**CERT-02 multi-size test assertion:**
The test renders at A4-landscape AND US-Letter-landscape and asserts:
1. Both render without `:content_overflow` (body content fits both page sizes).
2. No hardcoded dimensions appear in the rendered block geometry (assert via `doc.pages` inspection that `x`/`y`/`width`/`height` of body region equals the computed values, not hardcoded A4 values).
3. The same `data` map produces `{:ok, pdf}` on both sizes.

```elixir
test "renders at A4-landscape without overflow" do
  doc = Certificate.document(fixture_data(), page_size: :a4, orientation: :landscape)
  assert {:ok, pdf} = Rendro.render(doc)
  assert is_binary(pdf) and String.starts_with?(pdf, "%PDF-")
end

test "renders at US-Letter-landscape without overflow" do
  doc = Certificate.document(fixture_data(), page_size: :us_letter, orientation: :landscape)
  assert {:ok, pdf} = Rendro.render(doc)
  assert is_binary(pdf)
end

test "body region width is derived from page size, not hardcoded" do
  for {size, expected_w} <- [{:a4, 841.89 - 144}, {:us_letter, 792.0 - 144}] do
    template = Certificate.page_template(page_size: size, orientation: :landscape)
    body = Enum.find(template.regions, & &1.role == :body)
    assert_in_delta body.width, expected_w, 0.01
  end
end
```

### Pattern 4: Certificate Branding (CERT-03)

**Copy from BrandedInvoice — wiring only, NOT geometry:**

```elixir
# Source: verified analysis of lib/rendro/recipes/branded_invoice.ex
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
      base_doc  # unbranded — no font/image registration
    end

  base_doc
  |> Rendro.Document.add_template(template)
  |> Rendro.Document.set_template(template.name)
  |> then(fn d -> Enum.reduce(secs, d, &Rendro.Document.add_section(&2, &1)) end)
end
```

**Key difference from BrandedInvoice:** Branding is OPTIONAL for Certificate (an unbranded certificate with default fonts is valid — CERT-03 says "supports branded output", not "requires branding"). BrandedInvoice raises if `data.brand` is missing; Certificate only raises if `data.brand` is present but malformed.

**Validation for Certificate brand:**
```elixir
defp validate_brand!(nil), do: :ok  # unbranded — OK
defp validate_brand!(%{font_name: f, logo_name: l})
  when is_atom(f) and is_atom(l), do: :ok
defp validate_brand!(_brand) do
  raise ArgumentError, "data.brand must include atom :font_name and :logo_name keys"
end
```

**Test assets:** `Rendro.Branded.font_path/0` and `Rendro.Branded.logo_path/0` (verified in `lib/rendro/branded.ex`) are the test/demo assets. These are the same assets used by BrandedInvoice tests.

### Pattern 5: Support-Matrix Non-Viewer Rows (CONTRACT-01 / D-09 / D-10)

**Critical finding:** The JSON-Schema (`priv/schemas/support_matrix.schema.json`) has `"additionalProperties": true` at the root level. The `viewer_row` $def (which enforces `status` enum + promotion keys) is ONLY applied under `#/$defs/viewer_map` which is ONLY referenced from properties that already have `"viewers": {"$ref": "#/$defs/viewer_map"}` sub-objects. New top-level keys WITHOUT a `viewers` sub-key are allowed by the schema with any shape.

**Critical finding:** `Matrix.enumerate_viewer_cells/1` hardcodes the 8 existing `@viewer_maps` paths. It will NOT enumerate new top-level keys (e.g., `"statement"`, `"receipt_report"`). This means:
- `Validator.validate_promotion_complete(matrix)` will NOT fail on new non-viewer rows.
- `Validator.run_full()` will NOT fail on them.
- The orphan-check (`list_orphan_evidence/1`) will NOT flag evidence files that are referenced from the new non-viewer rows (since it only collects referenced paths from `enumerate_viewer_cells`).
- **Implication:** New non-viewer rows do NOT need evidence files in `priv/viewer_evidence/` — there is no path-reference mechanism to check them. The `evidence:` field in the new rows is just informational (a string pointing at a test file or module).

**Recommended shape for non-viewer surface rows (D-09):**

```json
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
},
"page_numbering": {
  "surface": "page_numbering",
  "status": "supported",
  "evidence": "test/rendro/pipeline/paginate_test.exs",
  "recorded_at": "2026-05-29",
  "capabilities": {
    "single_pass_substitution": "supported",
    "deterministic_output": "supported",
    "suppress_on_first_page": "supported"
  }
}
```

**Surface naming alignment (D-10):** Phase 73 shipped `Rendro.page_number/1` as the public helper (not `running_header`/`running_footer` separately). The shipped code has no separate header/footer concept at the API level — it is one `page_number/1` helper that can be placed in either region. Using one `"page_numbering"` key (not two) aligns with the shipped public surface. The planner should confirm Phase 73's shipped names by checking `test/rendro/pipeline/` and the `page_number/1` function name.

**Schema validation:** These rows pass the existing JSON-Schema validator because:
1. The root `"additionalProperties": true` allows new keys.
2. These objects do not have a `"viewers"` sub-key, so `viewer_map` / `viewer_row` validation is not invoked.
3. The `"required": ["forms", "signing", "embedded_files", "links", "protection"]` constraint is still satisfied.

**Docs-contract lane impact:** The existing `viewer_evidence_claims_test.exs` tests will ALL still pass because they operate on `Matrix.enumerate_viewer_cells(matrix)` which only reads the existing 8 paths. The new keys are invisible to the existing test lane. No new docs-contract test file is needed for Phase 75 (CONTRACT-02/HexDocs is Phase 76's responsibility).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Table column header repetition on continuation | Custom per-page header injection | `Rendro.table(rows, header: [...])` per page (engine's `stacked_header` in paginate.ex:106) | Already proven in Statement; the header is part of the Table struct and re-emitted by `stack_table_cells` on every per-page block |
| Money formatting | Custom string interpolation | `Rendro.Format.money/1` | Deterministic, Decimal-safe, already in the codebase |
| Date formatting | `Calendar.strftime` | `Rendro.Format.date/1` | Locale-free, deterministic |
| Row height estimation | Hard-coded pixel estimates | `Rendro.measure_rows/4` | Engine-true heights; estimates cause `:content_overflow` (the Statement D-09 lesson) |
| Page number in footer | Custom token substitution | `Rendro.page_number/1` | Public API wrapping `{{page_number}} of {{total_pages}}` tokens |
| Font/image registration | Custom asset wiring | `Rendro.Document.register_embedded_font/3` + `register_image/3` | Proven in BrandedInvoice |
| Page-size landscape swap | Raw numeric computation inline | `Rendro.PageSize.resolve/2` (new helper D-07) | Centralizes the swap logic; prevents copy-paste errors across Certificate tests |

---

## Common Pitfalls

### Pitfall 1: Hardcoding A4 Numerics in Certificate (CERT-02 — most dangerous)

**What goes wrong:** Developer copies geometry from `statement.ex` or `branded_invoice.ex` and uses `@page_width 595.28`, `@page_height 841.89`, `@margin 72` as module attributes in Certificate. Certificate then fails to render correctly at US-Letter.

**Why it happens:** All existing recipes (Statement, Invoice, BrandedInvoice) hardcode A4. The hardcoded values are immediately available for copy-paste.

**How to avoid:** Certificate MUST compute every x/y/width/height as an expression over the page template struct's fields. Use a single function `page_template/1` that takes `page_size:` as an option, resolves it to `{pw, ph}`, and derives all regions from `pw`/`ph`/`mt`/`mb`/`ml`/`mr`. There must be NO numeric literals in Certificate that equal A4 dimensions.

**Warning signs:** `595.28`, `841.89`, `451.28`, `697.89` appearing anywhere in `certificate.ex`. The multi-size test will catch this if written correctly (assert `body.width` equals the computed value, not a hardcoded expectation).

### Pitfall 2: Off-By-One Page Breaks / `:content_overflow`

**What goes wrong:** `chunk_into_pages` packs rows up to `effective_capacity` but forgets to account for the table header row height (`header_h`) or the epsilon margin (`@row_epsilon 2.0`). A single sub-pixel rounding delta causes the engine to throw `:content_overflow`.

**Why it happens:** Statement's `effective_capacity` formula is:
```
capacity = @body_height - @header_height - @footer_height
effective_capacity = capacity - header_h - 2 * typical_row_h - @row_epsilon
```
The `- 2 * typical_row_h` is Statement-specific (reserves space for CF/BF rows). Receipt does NOT have CF/BF rows, so Receipt's formula is:
```
effective_capacity = capacity - header_h - @row_epsilon
```
**Copying Statement's formula verbatim into Receipt wastes one row of capacity per page**, which is safe but suboptimal. More importantly, forgetting `header_h` entirely causes overflow.

**How to avoid:** Compute `effective_capacity` explicitly in each recipe (not in the shared helper). Document the formula in a comment. The Statement epsilon (`@row_epsilon 2.0`) is a good default to copy.

### Pitfall 3: Double-Pagination (D-10 Anti-Pattern)

**What goes wrong:** Recipe emits multiple blocks per page with `keep_together: true` on groups larger than `body_capacity`. Engine's `place_hard_group` throws `:content_overflow` (paginate.ex:307).

**Why it happens:** Developer tries to keep CF + all txns together. The group is larger than `body_capacity`.

**How to avoid:** Never set `keep_together: true` on any block or group that might exceed `body_capacity`. Receipt has no CF/BF rows so this risk is lower, but totals block + last page's line items must also fit within capacity (the totals block is usually small).

### Pitfall 4: Support-Matrix Schema Rejection

**What goes wrong:** New surface row inadvertently places a `"status"` key inside a `"viewers"` sub-object, triggering the `viewer_row` $def validation, which requires `"evidence"` + `"recorded_at"` + `"viewer_kind"` on `"supported"` rows.

**Why it happens:** Developer mimics an existing `forms.viewers.adobe_acrobat_reader` row structure inside the new non-viewer key.

**How to avoid:** New surface rows should NOT have a `"viewers"` sub-key. The row is a flat object with `"status"`, `"capabilities"`, `"evidence"` (informational string), `"recorded_at"`. Run `mix test test/docs_contract/viewer_evidence_claims_test.exs` after editing `support_matrix.json` to confirm schema validation passes.

### Pitfall 5: Breaking Statement's Determinism During D-04 Extraction

**What goes wrong:** During the extraction of `chunk_into_pages` into the shared module, a subtle change (different argument order, different accumulator direction, missing pattern match) produces different chunking results. Statement's test suite catches the regression, but only if the plan gates Receipt development on a green Statement suite after refactoring.

**Why it happens:** The recursive `do_chunk_pages` accumulates results in reverse (head-prepend) and calls `Enum.reverse` in `finalize_page`. Any change to this pattern changes page assignment.

**How to avoid:** The wave structure must be: (1) extract shared module + refactor Statement → run Statement's 51 tests green before proceeding; (2) build Receipt using the shared module; (3) build Certificate independently.

### Pitfall 6: `Rendro.PageSize` Not Matching `PageTemplate` Defaults

**What goes wrong:** `Rendro.PageSize.resolve(:a4, :portrait)` returns `{595.28, 841.89}` but `%Rendro.PageTemplate{}` defaults (`@default_width 595.28`, `@default_height 841.89` in `page_template.ex`) are the same values. If Certificate calls `Rendro.page_template(width: pw, height: ph)` for A4-portrait, the template is redundant but not wrong. However, if the values diverge (e.g., PageSize rounds), the Certificate body region width will differ from Statement's and tests may assert wrong values.

**How to avoid:** Copy the exact values from `lib/rendro/page_template.ex` (lines 7-8) into `Rendro.PageSize`:
- A4: `595.28 × 841.89` (verified in `page_template.ex:7-8`)
- US Letter: `612.0 × 792.0` [ASSUMED — standard PostScript US Letter dimensions; verify before hardcoding]

### Pitfall 7: Certificate as Multi-Page Accidentally

**What goes wrong:** Certificate body content (title + recipient + body text + date + seal) overflows a single page. Engine splits the body and emits 2 pages, which is visually incorrect for a certificate.

**Why it happens:** Long `data.body` strings or oversized fonts push content past `body_capacity`.

**How to avoid:** Receipt uses multi-page chunking; Certificate does NOT. Certificate should NOT call `chunk_into_pages`. Instead, add a `validate_data!/1` check that warns (or raises) if the body content would overflow — though auto-measurement of text blocks requires `Rendro.measure_rows/4` (tables only) and there is no public text-height measurement API. The practical mitigation is: use conservative defaults (small fonts, short body text in examples), and add a recipe-level comment warning the caller that very long body text may overflow to multiple pages (acceptable for v1). A `validate_data!` length guard on `data.body` (e.g., raise if > 2000 characters) is a reasonable safety hatch.

---

## Code Examples

### Statement Refactoring — Calling the Shared Module

```elixir
# Before (in statement.ex body_section):
pages = chunk_into_pages(rows_with_balance, formatted_rows, row_heights, header_h, capacity)

# After (calling shared module):
rows_with_meta = Enum.zip([formatted_rows, row_heights, rows_with_balance])
  |> Enum.map(fn {fmt_row, height, row_data} -> {fmt_row, height, row_data.balance} end)

effective_capacity = capacity - header_h - 2 * typical_row_h - @row_epsilon

{chunked_pages, _} = Rendro.Recipes.Pagination.chunk_rows_into_pages(rows_with_meta, effective_capacity)
# chunked_pages: [{[fmt_row], last_balance}] — same as before
```

### Receipt Capacity Computation

```elixir
# No CF/BF overhead; simpler than Statement:
effective_capacity = @body_height - @header_height - @footer_height - header_h - @row_epsilon
# where header_h = table header row height from Rendro.measure_rows/4
```

### Certificate Page Template (CERT-02 — geometry only, no A4 literals)

```elixir
def page_template(opts \\ []) do
  page_size   = Keyword.get(opts, :page_size, :a4)
  orientation = Keyword.get(opts, :orientation, :landscape)
  {pw, ph}    = Rendro.PageSize.resolve(page_size, orientation)
  ml = Keyword.get(opts, :margin_left, 72)
  mr = Keyword.get(opts, :margin_right, 72)
  mt = Keyword.get(opts, :margin_top, 72)
  mb = Keyword.get(opts, :margin_bottom, 72)

  Rendro.page_template(
    name: Keyword.get(opts, :name, :certificate),
    width:  pw,
    height: ph,
    margin_top: mt, margin_right: mr, margin_bottom: mb, margin_left: ml,
    regions: [
      Rendro.region(
        name: :body, role: :body, anchor: :flow,
        x: ml, y: mt,
        width:  pw - ml - mr,   # derived
        height: ph - mt - mb    # derived
      )
    ]
  )
end
```

### Support-Matrix Non-Viewer Row Structure

```json
"statement": {
  "surface": "statement",
  "status": "supported",
  "evidence": "test/rendro/recipes/statement_test.exs",
  "recorded_at": "2026-05-29",
  "capabilities": {
    "multi_page_table_continuation": "supported",
    "running_footer_page_number":    "supported",
    "deterministic_output":          "supported"
  }
}
```

---

## Shared-Helper Extraction Detail (D-04 — the load-bearing architectural move)

### What Is Shared vs. Statement-Specific

| Code in statement.ex | Shared? | Notes |
|---------------------|---------|-------|
| `chunk_into_pages/5` | YES (parameterized) | Rename to `chunk_rows_into_pages/3`; `effective_capacity` computed by caller |
| `do_chunk_pages/5` | YES | Verbatim — logic is purely about fitting heights |
| `finalize_page/1` | YES | Verbatim — reverses accumulator |
| `formatter/3` | YES | Verbatim |
| `label_resolver/1` | YES | Verbatim |
| `type_name/1` | YES | Verbatim |
| `fold_balance/2` | NO | Statement-specific (Decimal running-balance fold) |
| `header_section/2` | NO | Statement-specific content (account, period, opening_balance) |
| `footer_section/2` | NO | Both recipes have a footer with `Rendro.page_number/1` — but the section name differs; keep as 1-line private function in each recipe |
| `validate_data!/1` and friends | NO | Recipe-specific data contracts |
| `maybe_validate_closing_balance!/1` | NO | Statement-specific |
| Module attributes (`@page_width` etc.) | NO | Statement uses A4; Receipt will also use A4 but the planner may want geometry-derived coords for Receipt too (Claude's discretion) |

### Proposed API for `Rendro.Recipes.Pagination`

```elixir
defmodule Rendro.Recipes.Pagination do
  @moduledoc false

  # Chunks [{fmt_row, height, opaque_meta}] triples into pages.
  # `opaque_meta` is whatever the caller needs from each row (e.g. balance for
  # Statement, nil for Receipt). Returns [{[fmt_row], last_meta}] page tuples.
  @spec chunk_rows_into_pages([{any(), number(), any()}], number()) ::
          [{[any()], any()}]
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

  # Formatting helpers (shared across all recipes)
  def formatter(opts, key, default_fn) do
    Keyword.get(Keyword.get(opts, :formatters, []), key, default_fn)
  end

  def label_resolver(opts) do
    user_labels = Keyword.get(opts, :labels, %{})
    fn key ->
      case Map.fetch(user_labels, key) do
        {:ok, v} -> v
        :error -> Rendro.Format.label(key)
      end
    end
  end

  def type_name(v) when is_binary(v),  do: "String"
  def type_name(v) when is_integer(v), do: "Integer"
  def type_name(v) when is_float(v),   do: "Float"
  def type_name(v) when is_atom(v),    do: "Atom"
  def type_name(v) when is_list(v),    do: "List"
  def type_name(v) when is_map(v),     do: "Map"
  def type_name(_),                    do: "Unknown"
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded A4 geometry in all recipes | Geometry-derived coords in Certificate (CERT-02) | Phase 75 (this phase) | Certificate correctly renders at multiple page sizes |
| Inline pagination logic per recipe | Shared `Rendro.Recipes.Pagination` private helper | Phase 75 (this phase) | Statement + Receipt use identical, single-sourced chunking |
| No named page-size helper | `Rendro.PageSize.resolve/2` (or inline) | Phase 75 (this phase) | Clean API for specifying page sizes in tests and user code |
| No recipe surface rows in support_matrix.json | 5 new top-level keys (non-viewer-sensitive rows) | Phase 75 (this phase) | v2.3 recording discipline extended to recipe surfaces |

**Not changed / preserved:**
- Engine pagination behavior (single forward pass — PAGE-04)
- `Rendro.measure_rows/4` public API (already shipped Phase 74)
- `Rendro.page_number/1` public API (already shipped Phase 73)
- All 51 Statement tests (must stay green post-refactoring)

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir) |
| Config file | `test/test_helper.exs` (standard) |
| Quick run command | `mix test test/rendro/recipes/receipt_test.exs test/rendro/recipes/certificate_test.exs` |
| Full suite command | `mix test` |
| Statement regression command | `mix test test/rendro/recipes/statement_test.exs` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RCPT-01 | Receipt renders from data map; column headers repeat | unit | `mix test test/rendro/recipes/receipt_test.exs` | ❌ Wave 1 |
| RCPT-01 | Column header repetition on multi-page | unit (check block structure) | see above | ❌ Wave 1 |
| RCPT-02 | Three-rung escape hatch (page_template, sections, document) | unit | see above | ❌ Wave 1 |
| RCPT-03 | Multi-page with "Page X of Y" footer; deterministic | unit | see above | ❌ Wave 1 |
| CERT-01 | Certificate renders from data map | unit | `mix test test/rendro/recipes/certificate_test.exs` | ❌ Wave 2 |
| CERT-02 | Body region width derived from page size (A4 vs US-Letter) | unit (template geometry assertion) | see above | ❌ Wave 2 |
| CERT-02 | Renders at A4-landscape without overflow | unit | see above | ❌ Wave 2 |
| CERT-02 | Renders at US-Letter-landscape without overflow | unit | see above | ❌ Wave 2 |
| CERT-02 | No hardcoded A4 numerics (page_template width/height match resolved size) | unit | see above | ❌ Wave 2 |
| CERT-03 | Branded certificate registers font and image | unit | see above | ❌ Wave 2 |
| CERT-03 | Unbranded certificate renders (brand absent) | unit | see above | ❌ Wave 2 |
| CERT-03 | Malformed brand raises ArgumentError | unit | see above | ❌ Wave 2 |
| CONTRACT-01 | support_matrix.json passes schema validation after adding new rows | docs-contract | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ✅ (already exists) |
| CONTRACT-01 | Statement row exists in support_matrix.json | manual + docs-contract | `grep "statement" priv/support_matrix.json` | ❌ Wave 3 |
| D-04 | Statement tests still pass after extraction | regression | `mix test test/rendro/recipes/statement_test.exs` | ✅ (already exists, 51 tests) |
| D-10 | Deterministic render of Receipt | unit | `mix test test/rendro/recipes/receipt_test.exs` | ❌ Wave 1 |
| D-05/D-06 | Certificate landscape default | unit (template.width > template.height for :a4) | see above | ❌ Wave 2 |

### Receipt Test Suite — Required Coverage

Following the V1..V10 pattern from `statement_test.exs`:

| # | Test Group | Description |
|---|------------|-------------|
| V1 | `document/2` basic | Returns `%Rendro.Document{}`; `Rendro.render` returns `{:ok, pdf}` |
| V2 | Single-page | 0 lines, 1 line, capacity-1 lines all fit 1 page; "Page 1 of 1" |
| V3 | Multi-page | capacity+1 → 2 pages; column headers repeat on page 2 |
| V4 | Footer | "Page X of Y" correct on every page; no unresolved tokens |
| V5 | Totals | Totals block present on last page; `Decimal.equal?` validation |
| V6 | Validation | Float amount raises; missing key raises; malformed data raises |
| V7 | Three-rung | `page_template/1`, `sections/2` callable independently |
| V8 | Determinism | Two renders byte-identical with `deterministic: true` |
| V9 | Overflow safety | Boundary row counts render without `:content_overflow` |
| V10 | No keep_together | No body block has `keep_together: true` |

### Certificate Test Suite — Required Coverage

| # | Test Group | Description |
|---|------------|-------------|
| C1 | `document/2` basic | Renders at A4-landscape; `{:ok, pdf}`; PDF starts with `%PDF-` |
| C2 | Data content | Title, recipient, body text, date appear in rendered output |
| C3 | Geometry-derived | `page_template(page_size: :a4).regions[body].width == 841.89 - 144` (A4-landscape) |
| C4 | Multi-size | A4-landscape AND US-Letter-landscape both render without overflow |
| C5 | No hardcoded A4 | `page_template(page_size: :us_letter).regions[body].width != page_template(page_size: :a4).regions[body].width` |
| C6 | Landscape default | `template.width > template.height` for `page_template()` (default = A4-landscape) |
| C7 | Portrait opt-in | `page_template(orientation: :portrait).height > page_template(orientation: :portrait).width` for A4 |
| C8 | Branded | `doc.font_registry.fonts` has `brand.font_name`; `doc.asset_registry.assets` has `brand.logo_name` |
| C9 | Unbranded | No `data.brand` → no font/image registration error |
| C10 | Brand validation | Malformed `data.brand` raises `ArgumentError` |
| C11 | Determinism | Two renders byte-identical with `deterministic: true` |
| C12 | Three-rung | `page_template/1`, `sections/2` callable independently |
| C13 | `validate_data!/1` | Missing `:title`, `:recipient`, `:date` raises `ArgumentError` |

### Sampling Rate

- **Per task commit:** `mix test test/rendro/recipes/statement_test.exs` (during D-04 extraction), then `mix test test/rendro/recipes/receipt_test.exs` or `certificate_test.exs` (during builds)
- **Per wave merge:** `mix test` (full suite)
- **Phase gate:** Full suite green + `mix test test/docs_contract/viewer_evidence_claims_test.exs` green before `/gsd-verify-work`

### Wave 0 Gaps (files that must be created before implementation)

- [ ] `test/rendro/recipes/receipt_test.exs` — covers RCPT-01..03, V1..V10
- [ ] `test/rendro/recipes/certificate_test.exs` — covers CERT-01..03, C1..C13
- [ ] `lib/rendro/recipes/pagination.ex` — shared helper (Wave 0 scaffold with function stubs)
- [ ] `lib/rendro/page_size.ex` — page-size helper (stub `:a4` and `:us_letter`)

---

## Environment Availability

Step 2.6: SKIPPED — Phase 75 is purely code/config changes with no new external tool dependencies. All dependencies (Decimal, ExUnit, the existing test suite) are already confirmed available from Phase 74.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | US Letter dimensions are 612.0 × 792.0 pt (standard PostScript definition) | Certificate geometry, PageSize helper | Certificate multi-size test would assert wrong body width at US-Letter; fix is trivial (update constant) |
| A2 | `Rendro.PageSize` is the right module name (not `Rendro.page_size/2` helper on rendro.ex) | Standard Stack, Pattern 3 | Module name is Claude's discretion; either placement works; planner should pick one |
| A3 | "page_numbering" is the correct single-row name for the PAGE-primitive surface (vs "running_header"/"running_footer") | Support contract, Pattern 5 | If Phase 73 shipped public API with distinct header/footer naming, two rows may be cleaner; planner should check `test/` for Phase 73 surface names |
| A4 | Receipt's `effective_capacity` formula does NOT need CF/BF overhead (2 × typical_row_h subtracted) | Pattern 2 — Receipt body | If the shared helper or caller gets this wrong, Receipt will either waste capacity (safe) or overflow (bad); verify the formula in the plan |
| A5 | Certificate body content (title + recipient + body + date + seal) reliably fits within an A4-landscape content area at the font sizes shown | Certificate layout | Very long `data.body` strings may overflow; add a character-length guard or accept the limitation in Phase 75 |

---

## Open Questions

1. **Receipt totals block placement:** Should the totals block be appended to the last page's body block (as additional table rows), or rendered as a separate block after the last page's table? Separate block is cleaner (no mixed table/totals in one Rendro.table), but requires capacity accounting to ensure totals + last page's rows fit.
   - **Recommendation:** Separate block, appended only to the last page's body section. Reserve a conservative totals height (e.g., 3-4 rows) when computing `effective_capacity` for the line-items table.

2. **Receipt column layout:** Statement has 4 columns (Date, Description, Amount, Balance). Receipt has at minimum (Description, Amount). Whether a Qty column is included is Claude's discretion.
   - **Recommendation:** Default columns `[Description, Amount]` with `columns: [{:share, 1}, {:fixed, 72}]`. Optionally detect `line.quantity` and add a Qty column if present.

3. **Phase 73 shipped PAGE surface naming:** The research shows `Rendro.page_number/1` is the public function. The CONTEXT says D-10 "or one `page_numbering` surface if the planner finds that cleaner." Need to confirm by inspecting `test/rendro/pipeline/` what surface terminology Phase 73 used in its shipped tests.
   - **Recommendation:** Use `"page_numbering"` as the single matrix key. Planner should verify against Phase 73 test files.

4. **Statement `effective_capacity` bug investigation:** The current code computes:
   ```elixir
   capacity = @body_height - @header_height - @footer_height
   ```
   Note that `@body_height` is already computed as `@page_height - 2 * @margin - @header_height - @footer_height`, so this double-subtracts header and footer. This appears intentional (conservative margin) but the planner should verify this is correct for the Statement test suite. Do NOT change this behavior during D-04 extraction — preserve it verbatim to keep Statement tests green.

---

## Sources

### Primary (HIGH confidence)
- `lib/rendro/recipes/statement.ex` — Direct code reading; exact functions extracted; line-by-line analysis
- `lib/rendro/recipes/branded_invoice.ex` — Direct code reading; branding pattern (CERT-03)
- `lib/rendro/page_template.ex` — Direct code reading; `%PageTemplate{}` struct fields (CERT-02)
- `lib/rendro/pipeline/paginate.ex` — Direct code reading; `stacked_header` (RCPT-01), `maybe_break_before` (D-10), `replace_page_numbers` (PAGE primitive)
- `priv/support_matrix.json` — Direct reading; current structure
- `priv/schemas/support_matrix.schema.json` — Direct reading; `additionalProperties: true` at root; `viewer_row` $def scope
- `lib/rendro/viewer_evidence/matrix.ex` — Direct reading; hardcoded `@viewer_maps` (8 paths only); confirms non-viewer rows are not enumerated
- `test/rendro/recipes/statement_test.exs` — Direct reading; V1..V10 test pattern; rows_per_page helper; determinism assertions

### Secondary (MEDIUM confidence)
- `lib/rendro/viewer_evidence/validator.ex` — Direct reading; `promotion_complete_row?` requirements; `run_full` flow
- `test/docs_contract/viewer_evidence_claims_test.exs` — Direct reading; docs-contract lane structure; which tests run against matrix
- `lib/rendro.ex` — Direct reading; `page_number/1` (~210), `measure_rows/4` (~321), `page_template/1` (~195)
- `lib/rendro/format.ex` — Direct reading; `money/1`, `date/1`, `label/1`

### Tertiary (LOW confidence)
- [ASSUMED] US Letter = 612.0 × 792.0 pt — standard PostScript definition; not verified against a Rendro-specific source

---

## Metadata

**Confidence breakdown:**
- Shared-helper extraction: HIGH — every function is directly read and analyzed from statement.ex
- Receipt recipe design: HIGH — direct analog of Statement; data contract is Claude's discretion
- Certificate geometry: HIGH — `PageTemplate` struct is directly read; CERT-02 constraint is explicit
- Support-matrix row shape: HIGH — JSON-Schema directly analyzed; `enumerate_viewer_cells` directly read; confirms non-viewer rows are schema-valid and not enumerated
- US Letter dimensions: LOW — assumed from PostScript standard; not verified in codebase

**Research date:** 2026-05-29
**Valid until:** 2026-07-01 (stable domain; no external ecosystem churn)

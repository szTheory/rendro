# Phase 115: Invoice anatomy upgrade + Format public promotion + palette/align seams - Research

**Researched:** 2026-07-18
**Domain:** Elixir PDF/document rendering library — additive, byte-compatible recipe upgrade + public-API tier promotion
**Confidence:** HIGH (grounded entirely in the actual codebase; every claim below cites a file:line)

## Summary

Phase 115 is the milestone's only real `lib/` product change, and nearly every piece it needs
already exists in the codebase as a proven pattern on a **sibling recipe**. The work is
overwhelmingly *"mirror `Rendro.Recipes.Receipt` into `Rendro.Recipes.Invoice`"* plus one
genuinely new primitive (`cell_align: :right`) and one irreversible public-API act (promoting
`Rendro.Format`). There is essentially no research risk in the recipe/validation/totals/pagination
work — the exact code to copy is in `lib/rendro/recipes/receipt.ex` and `lib/rendro/recipes/statement.ex`.

Three findings materially shape the plan. **First:** `Rendro.Format` is *already fully written* —
`money/1`, `date/1`, `label/1` all exist with `@spec`s and doctests (`lib/rendro/format.ex`). The
promotion is not "write functions"; it is "flip `@moduledoc false` → `@moduledoc tags: [:adapter]`,
add the module to the generator registry, delete it from the contract test's hidden set, and
regenerate `priv/public_api.json`." **Second:** that hidden-set deletion is a hard-coded list at
`test/docs_contract/public_api_contract_test.exs:90` — this is the "expected red build" STATE.md
warns about. **Third:** `cell_align: :right` is the only net-new engine primitive and the only place
byte-compatibility can silently break; it must be strictly opt-in so that tables with no `cell_align`
key produce byte-identical output.

**Primary recommendation:** Structure the phase as (1) `Format` promotion as its own atomic plan
(the irreversible act, isolated so its deliberate red→green build is clean), (2) `cell_align: :right`
as its own additive-primitive plan with a two-render + golden-hash byte-identity guard, (3) the
Invoice anatomy upgrade (issuer/customer/due_date/terms/totals + Decimal + `validate_data!/1` +
`palette(opts)` + `page_template/1` whitelist) mirroring `Receipt`/`Statement` line-for-line.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Invoice anatomy (issuer/customer/due_date/terms/totals) | Recipe (`Rendro.Recipes.Invoice`, adapter tier) | — | Recipes own data→section composition; INV-01/02/03/06 are all recipe-local |
| Money/date/label formatting | Adapter (`Rendro.Format`) | Recipe (calls it) | Pure, locale-free formatting is a shared adapter-tier utility (INV-02/04) |
| Totals caller-assertion validation | Recipe (`Invoice.validate_data!/1`) | Engine (`Decimal.equal?/2`) | Validation is recipe policy; Decimal is the arithmetic engine (INV-03) |
| Keep-totals-with-last-rows pagination | Recipe helper (`Rendro.Recipes.Pagination`) | Engine (`Rendro.Pipeline.Paginate`) | Recipes own per-page chunking; the engine stays single-pass (INV-03) |
| `cell_align: :right` tabular alignment | Engine primitive (`Table`/`Cell` + `Paginate`/`Writer`) | — | Horizontal text placement is engine layout, not recipe logic (INV-05) |
| Color roles (`palette(opts)`) | Recipe-private (`Invoice.palette/1`) | Engine (`Rendro.Color`) | S1 seam is recipe-private today; becomes `Rendro.Theme` in Milestone B (INV-07) |

## Standard Stack

This phase adds **no new dependencies**. Everything is in-tree or already a declared dep.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:decimal` | `>= 2.3.0 and < 4.0.0` | Exact money arithmetic + `Decimal.equal?/2` caller assertions | Already declared in `mix.exs:59` [VERIFIED: codebase]; used across Statement/Receipt |
| `Rendro.Format` (in-tree) | current | `money/1`/`date/1`/`label/1` formatting | Already implemented (`lib/rendro/format.ex`) [VERIFIED: codebase] |
| `Rendro.Recipes.Pagination` (in-tree) | current | `chunk_rows_into_pages/2`, `formatter/3`, `label_resolver/1`, `type_name/1` | Shared recipe helper (`lib/rendro/recipes/pagination.ex`) [VERIFIED: codebase] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Rendro.render(doc, deterministic: true)` | current | Byte-identical two-render determinism guard | INV-01 / INV-05 byte-compat tests [VERIFIED: codebase — `lib/rendro.ex:62,86`] |
| `mix rendro.api.gen` | current | Regenerate `priv/public_api.json` from `@moduledoc tags:` | After flipping `Format` tier [VERIFIED: codebase — `lib/mix/tasks/rendro/api.gen.ex`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Mirror `Receipt` totals block (`Rendro.text` join) | A dedicated totals `Rendro.table` | A table gives right-alignment "for free" via `cell_align`, but Receipt's text-join is the established, tested pattern — prefer it unless the totals must right-align to match line-item columns |
| `cell_align` as a `Rendro.table/2` option | `cell_align` field on `Rendro.Cell` struct | Both are additive; column-level option is less verbose for "right-align the money column." See landmine in Common Pitfalls. |

**Installation:** No install step. `mix deps.get` already satisfies `:decimal`.

## Package Legitimacy Audit

Not applicable — this phase installs **no external packages**. `:decimal` is already a declared,
long-established dependency (`mix.exs:59`) and is not being added or changed. No `npm`/`pypi`/`crates`
work in scope.

## Architecture Patterns

### System Architecture Diagram

```
data map ──▶ Invoice.document/2 ──▶ validate_data!/1  (NEW — mirrors Receipt)
              │                          │ raises instructive ArgumentError on bad input
              │                          ▼
              ├──▶ page_template/1 ──▶ Keyword.take whitelist (NEW — mirrors Statement)
              │      returns %PageTemplate{}   └─ recipe opts (:formatters/:labels/:palette) do NOT reach struct!
              │
              └──▶ sections/2 ─┬─▶ header_section  ─┐
                               ├─▶ body_section     │  each reads colors via palette(opts) (NEW, S1)
                               └─▶ footer_section  ─┘  no section inlines {0,0,0}
                                       │
                       body_section builds:
                         line-item table (Rendro.table)  ──▶ optional cell_align: :right on money col (NEW)
                         + maybe totals block (only if :totals present)
                                       │
                         totals validated via Decimal.equal?/2 (caller assertion, mirrors Receipt)
                         totals kept with last rows via Rendro.Recipes.Pagination chunking
                                       ▼
        Rendro.render(doc) ──▶ Measure ──▶ Paginate(stack_cells → cell x) ──▶ Writer(render_text_block → text x)
                                                            └─────── cell_align offset applied here (NEW) ──────┘
```

### Component Responsibilities

| File | Current Role | Phase-115 Change |
|------|-------------|------------------|
| `lib/rendro/recipes/invoice.ex` | Toy 3-rung recipe, no validation | Add optional anatomy fields, `validate_data!/1`, `palette/1`, totals, `Keyword.take` whitelist |
| `lib/rendro/format.ex` | `@moduledoc false`, fully implemented | Promote to `@moduledoc tags: [:adapter]` + real moduledoc + migration/"may evolve" note |
| `lib/mix/tasks/rendro/api.gen.ex` | `@public_modules` registry (`public_modules/0`) | Add `Rendro.Format` to the list |
| `test/docs_contract/public_api_contract_test.exs` | Hidden-set asserts `Format` is `:hidden` (line 90) | **Delete `Rendro.Format`** from `hidden_modules` |
| `priv/public_api.json` | No `Format` entry | Regenerate — adds `Elixir.Rendro.Format` adapter entry |
| `lib/rendro/table.ex` / `lib/rendro/cell.ex` | Table/Cell structs (`:stable` tier) | Carry `cell_align` (additive, inert default) |
| `lib/rendro/pipeline/paginate.ex` / `lib/rendro/pdf/writer.ex` | Cell stacking + text placement | Apply right-align x-offset only when `cell_align: :right` |

### Pattern 1: Optional caller-assertion block via `Decimal.equal?/2` (INV-03)
**What:** A `:totals` block that renders only when supplied and is validated against derived values.
**When to use:** INV-03 verbatim.
**Example — copy from `Receipt.maybe_validate_totals!/1` and `build_totals_blocks/2`:**
```elixir
# Source: lib/rendro/recipes/receipt.ex:333-357 (build) and :505-554 (validate)
defp build_totals_blocks(%{totals: totals} = _data, opts) when is_map(totals) do
  fmt_amount = Rendro.Recipes.Pagination.formatter(opts, :amount, &Rendro.Format.money/1)
  lines =
    []
    |> maybe_append_totals_line("Subtotal", Map.get(totals, :subtotal), fmt_amount)
    |> maybe_append_totals_line("Tax", Map.get(totals, :tax), fmt_amount)
    |> maybe_append_totals_line("Discount", Map.get(totals, :discount), fmt_amount)
    |> maybe_append_totals_line("Total", Map.get(totals, :total), fmt_amount)
  if lines == [], do: [], else: [Rendro.block(Rendro.text(Enum.join(lines, "\n"), size: 10))]
end
defp build_totals_blocks(_data, _opts), do: []

# validation: derive subtotal = Σ line amounts, assert Decimal.equal?(supplied, derived), else raise
```
`Statement.maybe_validate_closing_balance!/1` (`statement.ex:663-708`) is the equivalent pattern for
a single-value assertion, also via `Decimal.equal?/2`.

### Pattern 2: `page_template/1` opts whitelist (INV-07, closes the leak)
**What:** Invoice's `page_template/1` currently does `Keyword.merge(defaults, opts)` (`invoice.ex:96`),
which forwards **recipe-level** opts (`:formatters`, `:labels`, and the new `:palette`/`:theme`) into
`struct!(PageTemplate, …)` and would raise `KeyError`. `Statement` already solved this.
**Example:**
```elixir
# Source: lib/rendro/recipes/statement.ex:184-196
template_opts =
  Keyword.take(opts, [:name, :width, :height, :margin_top, :margin_right,
                      :margin_bottom, :margin_left, :regions])
Rendro.page_template(Keyword.merge(defaults, template_opts))
```
Top-level `opts` stays fully open (it threads to `sections/2` and `palette/1`); only the
struct-building call is filtered. This exactly satisfies "leak closed via `Keyword.take` whitelist
while top-level `opts` stays open for B's future `theme:`."

### Pattern 3: `validate_data!/1` errors-as-product (INV-06)
**What:** Every recipe raises a structured multi-line `ArgumentError` (What/Where/Why/Next) instead of
leaking `BadMapError`/`FunctionClauseError`.
**Example — the canonical shape to mirror:**
```elixir
# Source: lib/rendro/recipes/receipt.ex:363-372 (non-map guard) and :479-489 (Float rejection)
defp validate_data!(data) when not is_map(data) do
  raise ArgumentError, """
  Rendro.Recipes.Invoice.document/2 — invalid data argument.

  What:  data must be a map.
  Where: Rendro.Recipes.Invoice.validate_data!/1
  Why:   Received a non-map value: #{inspect(data)}.
  Next:  Pass a map with required keys :id, :date, :items.
  """
end
```
Float rejection uses a dedicated `is_float(value)` guard head *before* the generic non-Decimal head,
with a message pointing at `Decimal.new/1`/`Decimal.from_float/1` — see `receipt.ex:479-502` and
`statement.ex:638-661`. Use `Rendro.Recipes.Pagination.type_name/1` (`pagination.ex:76-82`) for the
human-readable type in the `Why:` line.

### Pattern 4: `palette(opts)` color seam (INV-07 / S1)
**What:** A private function returning a role→RGB map, defaulting to today's literals. No section
inlines `{0,0,0}`.
**Key facts from the codebase:**
- The color roles `ink`/`muted`/`accent`/`on_accent`/`background`/`surface`/`rule` **do not exist
  anywhere yet** [VERIFIED: codebase — grep returned zero matches]. They are Milestone-B's *future*
  vocabulary; Phase 115 introduces them only as `palette/1` map keys defaulting to current literals.
- The Invoice recipe **currently inlines no colors at all** — its `Rendro.text(...)` calls omit
  `color:`, so text falls back to `Rendro.Text`'s struct default `color: {0, 0, 0}` (`text.ex:19`)
  [VERIFIED: codebase]. So "no section inlines `{0,0,0}`" is trivially true today; the requirement's
  intent is that **any color a section does set** (e.g. a muted "Date:" label in the upgraded anatomy)
  must be sourced from `palette(opts)`, never a literal tuple.
```elixir
# Suggested shape (defaults preserve today's all-black output byte-for-byte):
defp palette(opts) do
  overrides = Keyword.get(opts, :palette, %{})
  Map.merge(%{
    ink: {0, 0, 0}, muted: {0, 0, 0}, accent: {0, 0, 0}, on_accent: {0, 0, 0},
    background: {255, 255, 255}, surface: {255, 255, 255}, rule: {0, 0, 0}
  }, overrides)
end
```
RGB tuples are converted to PDF operators by `Rendro.Color.rg/1` (`lib/rendro/color.ex`, `@moduledoc
false` internal) — palette values are plain `{r,g,b}` tuples, consistent with `Rendro.Text.color`.

### Anti-Patterns to Avoid
- **`keep_together` on an oversized group** → hard `:content_overflow`. Both Statement and Receipt
  explicitly warn against this (`statement.ex:396-398`, `receipt.ex:299`). For totals, append the
  totals block after the last table block and rely on `break_before`/capacity reservation, not
  `keep_together`.
- **Changing default (left) cell rendering** when adding `cell_align`. Any code path that touches
  text-x for the no-`cell_align` case breaks byte-compat for every existing table in the library.
- **Rejecting the valid toy call** in `validate_data!/1`. Only `:id`, `:date`, `:items` are required;
  all new anatomy fields are optional. INV-06 explicitly forbids regressing the toy call.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Money formatting | Custom `"$#{...}"` grouping for new fields | `Rendro.Format.money/1` | Already handles rounding, comma-grouping, negative parens, byte-determinism (`format.ex:37-47`). Bare-number `price` keeps `"$#{price}"` per INV-02, but Decimal fields route through `money/1` |
| Totals validation | Ad-hoc `==` on Decimals | `Decimal.equal?/2` | `==` on `%Decimal{}` compares struct fields, not numeric value (`1.0` ≠ `1.00`). Receipt/Statement both use `Decimal.equal?/2` |
| Per-page row chunking | New chunker in Invoice | `Rendro.Recipes.Pagination.chunk_rows_into_pages/2` | Shared, tested, handles the empty-page infinite-loop guard (`pagination.ex:18-49`) |
| Float→Decimal rejection message | New wording | Copy Receipt/Statement `is_float` head | Consistent operator UX across all recipes |
| Formatter/label override plumbing | New opts parsing | `Pagination.formatter/3` + `label_resolver/1` | Already the recipe-wide convention (`pagination.ex:57-73`) |
| Public-API manifest editing | Hand-edit `priv/public_api.json` | `mix rendro.api.gen` | Generator is the source of truth; the contract test regenerates in-memory and asserts byte-equality (`public_api_contract_test.exs:25-79`). Hand edits will drift |

**Key insight:** Phase 115's recipe work is ~90% mechanical mirroring of `Rendro.Recipes.Receipt`
(which already has optional `:totals`, a `:customer`, `Decimal` line amounts, `validate_data!/1`, and
`build_totals_blocks/2`). Treat Receipt as the template and Statement as the reference for
single-value `Decimal.equal?/2` assertions and the `Keyword.take` whitelist.

## Runtime State Inventory

> Applicable because INV-04 mutates a checked-in generated artifact and a hard-coded test list.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no databases/datastores; the library is pure functional | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts / generated files | **`priv/public_api.json`** is a generated, checked-in manifest; **`test/docs_contract/public_api_contract_test.exs:90`** hard-codes `Rendro.Format` in the `:hidden` set; **`lib/mix/tasks/rendro/api.gen.ex`** `@public_modules` list omits `Rendro.Format` | (1) Add `Rendro.Format` to `@public_modules`; (2) delete `Rendro.Format` from the hidden set; (3) run `mix rendro.api.gen` to regenerate `priv/public_api.json`; (4) commit the regenerated file. All four must move together or the contract lane stays red |

**The canonical question — "after code is updated, what still has the old state?":** The
public-API contract lane cross-checks three artifacts against live BEAM metadata. If any one of the
three (`@public_modules`, hidden-set list, `public_api.json`) lags, `public_api_contract_test.exs`
fails. This is the deliberate red build STATE.md flags — plan it as one atomic commit.

## Common Pitfalls

### Pitfall 1: The `Format` promotion is a 4-file atomic change, not a 1-file flip
**What goes wrong:** Flipping `@moduledoc false` → `tags: [:adapter]` alone leaves the contract test
red (hidden-set assertion at `public_api_contract_test.exs:84-118` still expects `:hidden`) AND the
surface-equality assertion red (manifest lacks the entry).
**Why it happens:** Three artifacts encode the surface independently (see Runtime State Inventory).
**How to avoid:** One commit touching all four: `format.ex`, `api.gen.ex` `@public_modules`,
`public_api_contract_test.exs` hidden set, regenerated `priv/public_api.json`.
**Warning signs:** `mix test test/docs_contract/public_api_contract_test.exs` failing with either
"surface has drifted" or "Expected Rendro.Format to have @moduledoc false".

### Pitfall 2: `cell_align: :right` silently breaking existing-table byte-compat (INV-05)
**What goes wrong:** Text x is computed at `writer.ex:703` as `x = block.x + ox + page.margin_left`,
and cell x is set to the column-left in `paginate.ex:594-602` (`stack_cells`). A right-align
implementation that recomputes x for *all* cells changes output for tables that never opted in.
**Why it happens:** The alignment offset needs the measured rendered text width to compute slack
(`col_width - text_width - padding`); it is tempting to centralize that computation for every cell.
**How to avoid:** Gate the offset on an explicit `cell_align == :right`. Default (`nil`/`:left`) must
take the *unchanged* code path. Add a two-render determinism test AND a golden-hash regression on an
existing left-aligned table before touching the layout code.
**Warning signs:** Any diff to the no-`cell_align` text-x path; `certificate_test`/`branded_invoice_test`
two-render assertions flipping.

### Pitfall 3: "Widening the Stable tier" via `cell_align` (guard in the phase goal)
**What goes wrong:** `Rendro.Table` and `Rendro.Cell` are both `@moduledoc tags: [:stable]`
(`table.ex:5`, `cell.ex:5`). Adding a *new public function or type* to either widens the frozen Stable
surface and fails Assertion 5 (`@spec` coverage) and the surface-equality check.
**Why it happens:** Confusing struct fields with manifest surface.
**How to avoid:** `priv/public_api.json` tracks **functions and types only**, not struct fields
[VERIFIED: codebase — manifest entries are `{functions, tier, types}`]. Adding a `cell_align` *field*
to the `Cell`/`Table` defstruct does **not** change the manifest and does not widen the tier. Preferred
surface: accept `cell_align` as an **option** on the existing `Rendro.table/2` (or column rules) — its
arity and `@spec` are unchanged, so no new stable function appears. Do **not** add a new public
`Rendro.cell_align/…` helper.

### Pitfall 4: Bare-number `price` vs Decimal money fields (INV-02)
**What goes wrong:** Blanket-routing all money through `Format.money/1` changes the toy call's
`"$#{price}"` (where `price` is a bare integer like `200`) into `"$200.00"` — breaking INV-01
byte-compat.
**Why it happens:** INV-02 has a deliberate split: legacy `price` stays `"$#{price}"`
(`invoice.ex:169`), only **new Decimal money fields** route through `Format.money/1`.
**How to avoid:** Keep the existing `body_section` line-item mapping exactly as-is for `price`; apply
`Format.money/1` only to the new anatomy money (`:totals`, and any Decimal-typed field). Reject
`%Decimal{}` in the legacy `price` position and `Float` in the new fields, both instructively.

### Pitfall 5: Totals not staying with the last rows across a page break (INV-03)
**What goes wrong:** Appending the totals block naively (as Receipt does at `receipt.ex:308-310`) can
let totals flow to a fresh page if the last table page is near capacity.
**Why it happens:** Receipt appends totals after the last table block without reserving space for it in
`effective_capacity`. For Invoice, INV-03 explicitly requires totals *kept with* the last rows.
**How to avoid:** Reserve totals-block height in the per-page `effective_capacity` for the final page
(the Statement pattern reserves CF/BF rows the same way at `statement.ex:341`), or emit the last table
page + totals as content the chunker treats as one trailing unit. Flag for the planner: this is the
one place Invoice must go *beyond* a pure Receipt copy.

## Code Examples

### Optional field rendering (render only when present)
```elixir
# Header/section builders should match on presence, mirroring how Statement/Receipt
# destructure required keys and Map.get optional ones.
# Source pattern: lib/rendro/recipes/receipt.ex:247-260, statement.ex:271-289
defp header_section(%{id: id, date: date} = data, opts) do
  colors = palette(opts)
  fmt_date = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)
  base = [
    Rendro.block(Rendro.text("INVOICE ##{id}", size: 18, color: colors.ink)),
    Rendro.block(Rendro.text("Date: #{fmt_date.(date)}", size: 10, color: colors.muted))
  ]
  # additive: prepend issuer / append customer/due_date/terms only when present
  content = base
    |> maybe_prepend(Map.get(data, :issuer), &issuer_block(&1, colors))
    |> maybe_append(Map.get(data, :due_date), &due_date_block(&1, colors, fmt_date))
  Rendro.section(name: :invoice_header, region: :header, content: content)
end
```
> ⚠️ Introducing `color:`/`fmt_date` into the *existing* header lines changes byte output. If INV-01
> byte-identity is measured on the toy call, the toy-call code path must remain literally
> `Rendro.text("INVOICE ##{id}", size: 18)` / `"Date: #{date}"` (no formatter, no color) OR the golden
> baseline must be regenerated intentionally. **Decision needed** (see Assumptions Log A1).

### Byte-identity guard (the established pattern)
```elixir
# Source: lib/rendro/recipes/certificate_test.exs:188-193, branded_invoice_test.exs:166-171
{:ok, pdf1} = Rendro.render(doc, deterministic: true)
{:ok, pdf2} = Rendro.render(doc, deterministic: true)
assert pdf1 == pdf2
# For "byte-identical to BEFORE": record a sha256 golden of the toy-call render pre-change and
# assert it post-change (precedent: Plan 114-01 sha256'd a recorded benchmark render).
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Rendro.Format` internal (`@moduledoc false`) | Public adapter/Evolving tier | Phase 115 | The milestone's single irreversible SemVer commitment — output "may evolve" doc note caps the promise |
| Invoice toy `%{id, date, items}` only | Additive anatomy (issuer/customer/due_date/terms/totals) | Phase 115 | Backward-compatible; toy call byte-identical |
| No tabular alignment primitive | `cell_align: :right` | Phase 115 | First horizontal-alignment control; opt-in |
| Colors as struct defaults / literals | `palette(opts)` role map (S1) | Phase 115 | Prepares `Rendro.Theme` (Milestone B) with zero breaking rework |

**Deprecated/outdated:** none removed. All changes additive.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | INV-01 byte-identity is measured on the **toy call** (`%{id, date, items}`) render, so the toy code path must stay literally unchanged (no palette/formatter injected into the two existing header lines and the `"$#{price}"` body). The new anatomy fields render only when present. | Code Examples, Pitfall 4 | If the intent was instead to re-baseline the toy render, the plan can freely refactor the toy path through `palette`/`Format`. Recommend the planner treat the toy path as frozen and only add *new* code for *new* fields. [ASSUMED] |
| A2 | `cell_align` should be surfaced as an **option to `Rendro.table/2`** (column-level), stored as an inert struct field, applied only in the layout/writer path when `:right`. | Pitfall 3, Standard Stack | If the reviewer prefers a `Rendro.Cell` field only, the "don't widen Stable" outcome is identical (fields aren't manifest surface); either is safe. [ASSUMED] |
| A3 | Totals for Invoice should reserve space so they stay on the last table page (INV-03 "kept with the last table rows"), going one step beyond Receipt's naive append. | Pitfall 5 | If "kept with" is satisfied by simple append in practice (short totals, non-full last page), the extra reservation is harmless. Low risk. [ASSUMED] |
| A4 | The seven color roles default to today's literals: `ink`/`muted`/`accent`/`rule` = `{0,0,0}`, `background`/`surface` = `{255,255,255}`, `on_accent` = white-on-accent. Since Invoice inlines no colors today, any all-black default preserves current output. | Pattern 4 | If a section is *given* a non-black color during the anatomy upgrade, that color must be a palette role, and its default must match whatever literal the design intends — confirm exact defaults during planning/discuss. [ASSUMED] |

## Open Questions

1. **Does INV-01 byte-identity permit re-baselining the toy render, or must the toy code path be
   literally frozen?**
   - What we know: existing byte-compat tests are two-render determinism (`pdf1 == pdf2`); Plan 114-01
     used a sha256 golden of a recorded render.
   - What's unclear: whether a committed golden hash of the *current* toy render exists to diff against.
   - Recommendation: Plan a Wave-0 task to render the toy call on `main` and record its sha256 as the
     baseline, then assert equality post-change. Keep the toy code path unchanged (A1).

2. **Where exactly is the `cell_align` x-offset best applied — `stack_cells` (paginate) or
   `render_text_block` (writer)?**
   - What we know: cell x is set in `paginate.ex:594-602`; text x is `block.x + ox + margin` in
     `writer.ex:703`. The measured text width needed for the offset is available post-Measure.
   - What's unclear: whether the measured per-line text width is retrievable at stack time or only at
     write time.
   - Recommendation: Prototype in a spike task; prefer applying the offset where the measured width is
     already known to avoid re-measuring. Guard strictly on `:right`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix toolchain | all | ✓ | project-pinned | — |
| `:decimal` | INV-02/03 | ✓ | `>= 2.3.0 and < 4.0.0` (`mix.exs:59`) | — |
| `mix rendro.api.gen` | INV-04 | ✓ | in-tree task | — |
| `Rendro.render/2 deterministic:` | INV-01/05 tests | ✓ | in-tree (`rendro.ex`) | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

## Validation Architecture

> `workflow.nyquist_validation: true` in `.planning/config.json` — section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (stdlib), `async: true` throughout `test/rendro/recipes/` |
| Config file | none dedicated — `mix test` / `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/recipes/invoice_test.exs test/rendro/format_test.exs` |
| Full suite command | `mix test` (or scoped `mix ci.fast` per C1 aliases) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INV-01 | Optional fields render only when present; toy call byte-identical | unit + golden | `mix test test/rendro/recipes/invoice_test.exs` | ✅ extend `invoice_test.exs` |
| INV-01 | Toy render sha256 == recorded baseline | golden | `mix test test/rendro/recipes/invoice_byte_identity_test.exs` | ❌ Wave 0 |
| INV-02 | Decimal fields via `Format.money/1`; bare `price` stays `"$#{price}"`; Float rejected | unit | `mix test test/rendro/recipes/invoice_test.exs` | ✅ extend |
| INV-03 | Totals renders only when supplied; `Decimal.equal?/2` assertion; kept with last rows | unit + pagination | `mix test test/rendro/recipes/invoice_test.exs` | ✅ extend (mirror `receipt_test.exs` totals cases) |
| INV-04 | `Format` public adapter tier; hidden-set updated; manifest regenerated; contract lane green | contract | `mix test test/docs_contract/public_api_contract_test.exs` | ✅ exists — must go red→green |
| INV-05 | `cell_align: :right` right-aligns; no-`cell_align` tables byte-identical | unit + determinism | `mix test test/rendro/table_test.exs` (or new) | ❌ Wave 0 (new alignment test) |
| INV-06 | `validate_data!/1` raises instructive `ArgumentError`; never rejects toy call | unit | `mix test test/rendro/recipes/invoice_test.exs` | ✅ extend (mirror `receipt`/`statement` validation cases) |
| INV-07 | Sections read colors via `palette(opts)`; no `{0,0,0}` literal; `page_template/1` whitelist | unit | `mix test test/rendro/recipes/invoice_test.exs test/rendro/recipes/invoice_opts_threading_test.exs` | ✅ extend |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/recipes/invoice_test.exs test/rendro/format_test.exs`
- **Per wave merge:** `mix test test/rendro/ test/docs_contract/public_api_contract_test.exs`
- **Phase gate:** full `mix test` green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/rendro/recipes/invoice_byte_identity_test.exs` — record + assert sha256 golden of toy render (INV-01)
- [ ] `cell_align` alignment + no-op byte-identity test — covers INV-05 (extend `test/rendro/table_test.exs` if present, else new file)
- [ ] Confirm a `Format` public-doc example/doctest is added so HexDocs shows the adapter surface (INV-04)

*(Totals, validation, and opts-threading gaps are covered by extending existing `invoice_test.exs` /
`invoice_opts_threading_test.exs` — no new infra needed; mirror `receipt_test.exs`.)*

## Security Domain

> `security_enforcement` is not set to `false` (absent = enabled); included.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Pure library, no auth surface |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A |
| V5 Input Validation | **yes** | `validate_data!/1` errors-as-product — instructive `ArgumentError`, no leaked `BadMapError`/`FunctionClauseError` (INV-06); Decimal-only money fields reject Floats (INV-02) |
| V6 Cryptography | no | No crypto in scope (deterministic render hashing is integrity, not secrecy) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed caller data crashing the recipe / leaking internal errors | Denial of Service / Information Disclosure | `validate_data!/1` structured `ArgumentError` at the boundary (INV-06) — mirrors Statement/Receipt |
| Float money producing silently-wrong financial output | Tampering (data integrity) | Decimal-only new money fields with instructive Float rejection; `Decimal.equal?/2` caller assertions (INV-02/03) |
| Public-API over-exposure freezing more than intended | (SemVer/maintenance risk) | `Format` held to **adapter/Evolving** tier with smallest surface (`money/1`,`date/1`,`label/1`) + "output may evolve" note (INV-04) |
| No PII in scope | — | Invoice fixtures are fictional businesses only (established in Phase 114) |

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` or `./.claude/CLAUDE.md` exists in the working directory. Governing constraints come
from `.planning/STATE.md` Decisions instead:
- Additive minor release (`1.1.0`); **A2 strictly additive** — toy call preserved byte-identical.
- `Format` → **adapter/Evolving** tier, smallest useful surface, "output may evolve" note.
- Editing Phase-79's `public_api_contract_test.exs` hidden set is expected (deliberate red build).
- Engine stays **locale-free** (VAT/sales-tax are data, not engine logic).
- No new text/cell align primitive existed before — `cell_align: :right` is net-new and highest-leverage.
- No `{0,0,0}` inlined in sections; `palette(opts)` keyed on Milestone-B roles, defaults to today's literals.
- `page_template/1` leak closed via `Keyword.take` whitelist; top-level `opts` stays open for future `theme:`.

## Sources

### Primary (HIGH confidence — read this session)
- `lib/rendro/recipes/invoice.ex` — current toy recipe, no validation, `Keyword.merge` leak (`:96`), `"$#{price}"` (`:169`)
- `lib/rendro/recipes/receipt.ex` — the near-exact analog: optional `:totals`, `:customer`, Decimal lines, `validate_data!/1`, `build_totals_blocks/2`, `maybe_validate_totals!/1`
- `lib/rendro/recipes/statement.ex` — `Keyword.take` whitelist (`:184-196`), single-value `Decimal.equal?/2` assertion (`:663-708`), Float rejection heads
- `lib/rendro/format.ex` — `money/1`/`date/1`/`label/1` already implemented with `@spec`, `@moduledoc false`
- `lib/rendro/recipes/pagination.ex` — `chunk_rows_into_pages/2`, `formatter/3`, `label_resolver/1`, `type_name/1`
- `lib/mix/tasks/rendro/api.gen.ex` — `@public_modules` registry; generator semantics
- `test/docs_contract/public_api_contract_test.exs` — hidden set (`:90`), surface-equality (`:25-79`), tier-tag + `@spec` assertions
- `priv/public_api.json` — manifest shape `{functions, tier, types}`; `Format` absent
- `lib/rendro/table.ex`, `lib/rendro/cell.ex` — `:stable` tier structs (alignment target)
- `lib/rendro/pipeline/paginate.ex` (`stack_cells` `:590-602`), `lib/rendro/pdf/writer.ex` (`render_text_block` `:702-740`) — cell/text x placement
- `lib/rendro/text.ex` (`color: {0,0,0}` default `:19`), `lib/rendro/color.ex` (`rg/1`)
- `test/rendro/recipes/{certificate,branded_invoice,invoice,invoice_opts_threading}_test.exs` — byte-identity + opts-threading patterns
- `mix.exs:59` — `:decimal` dependency
- `.planning/{REQUIREMENTS,STATE,ROADMAP}.md`, `.planning/config.json`

### Secondary (MEDIUM confidence)
- None — no web research required for this codebase-internal additive change.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; every library is in-tree or already declared and read this session.
- Architecture: HIGH — patterns copied from live sibling recipes (Receipt/Statement) with file:line anchors.
- Pitfalls: HIGH — each pitfall traced to a specific code path (contract test hidden set, writer text-x, stable-tier tags, bare-price split, totals append).
- `cell_align` implementation detail: MEDIUM — the *offset location* (paginate vs writer) needs a spike (Open Question 2); the requirement and constraint (opt-in, no Stable widening) are HIGH.

**Research date:** 2026-07-18
**Valid until:** 2026-08-17 (stable internal codebase; ~30 days). Re-verify only if `Rendro.Format`,
the recipes, or `public_api_contract_test.exs` change before planning.

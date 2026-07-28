# Phase 115: Invoice anatomy upgrade + Format public promotion + palette/align seams - Pattern Map

**Mapped:** 2026-07-18
**Files analyzed:** 14 (7 lib/gen · 1 registry · 1 contract test · 1 manifest · 4 test)
**Analogs found:** 13 / 14 (1 net-new primitive path has partial analogs only)

> Sourced from `115-RESEARCH.md` (which pre-anchored every analog) plus first-hand reads of each
> analog this session. Every excerpt below was read directly — file:line ranges are current.
> No CONTEXT.md exists; the file list is derived from INV-01..INV-07 + RESEARCH's Component
> Responsibilities map.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/recipes/invoice.ex` (mod) | recipe (adapter tier) | transform (data→sections) | `lib/rendro/recipes/receipt.ex` | exact |
| `lib/rendro/format.ex` (mod) | adapter/utility | transform (pure format) | Receipt moduledoc + `:adapter` tag; manifest peer `Receipt` | role-match |
| `lib/mix/tasks/rendro/api.gen.ex` (mod) | config/registry | batch (codegen input) | existing `@public_modules` entries | exact (list append) |
| `test/docs_contract/public_api_contract_test.exs` (mod) | test (contract) | request-response | existing `hidden_modules` list (line 85-92) | exact (list delete) |
| `priv/public_api.json` (regen) | generated manifest | batch (generated) | `Elixir.Rendro.Recipes.Receipt` entry | exact (add sibling) |
| `lib/rendro/cell.ex` (mod) | model (`:stable` struct) | — | Cell's own inert defstruct defaults | exact (inert field) |
| `lib/rendro/table.ex` (mod) | model (`:stable` struct) | — | Table's inert `borders`/`header_fill` fields | exact (inert field) |
| `lib/rendro.ex` `table/2` (mod) | facade | transform | `normalize_table_attrs/1` pipeline (line 369-390) | exact |
| `lib/rendro/pipeline/paginate.ex` (mod) | engine (layout) | transform (cell→x) | `stack_cells/4` (line 590-602) | self (extend in place) |
| `lib/rendro/pdf/writer.ex` (mod) | engine (PDF emit) | transform (text→x op) | `render_text_block/8` (line 702-740) | self (extend in place) |
| `test/rendro/recipes/invoice_test.exs` (mod) | test | request-response | `test/rendro/recipes/receipt_test.exs` | exact |
| `test/rendro/recipes/invoice_byte_identity_test.exs` (NEW) | test (golden) | request-response | `branded_invoice_test.exs:169-171` | role-match |
| `test/rendro/table_test.exs` (mod/NEW cell_align) | test (determinism) | request-response | `branded_invoice_test.exs` two-render | role-match |
| `test/rendro/recipes/invoice_opts_threading_test.exs` (mod) | test | request-response | `invoice_opts_threading_test.exs` (extend self) | self |

### Two facts that override RESEARCH's framing (verified this session)

1. **`invoice.ex` is ALREADY `@moduledoc tags: [:adapter]`** (`invoice.ex:32`) and Invoice is ALREADY
   in `@public_modules` (`api.gen.ex:90`). The Invoice recipe upgrade does **not** touch tier/registry
   — only `format.ex` does. RESEARCH's "toy 3-rung recipe" is accurate for behavior, not for tier.
2. **The public-API manifest is `{"modules": {"Elixir.<Mod>": {functions, tier, types}}}`** — a nested
   dict under `"modules"`, not a flat top-level map. The `Format` entry is added *inside* `modules`.

---

## Pattern Assignments

### `lib/rendro/recipes/invoice.ex` (recipe, transform) — INV-01/02/03/06/07

**Analog:** `lib/rendro/recipes/receipt.ex` (near-exact) + `lib/rendro/recipes/statement.ex` (whitelist, single-value assert)

**A1 (FROZEN toy path) — do NOT touch these two lines** (`invoice.ex:159-160`):
```elixir
Rendro.block(Rendro.text("INVOICE ##{id}", size: 18)),
Rendro.block(Rendro.text("Date: #{date}", size: 10))
```
INV-01 byte-identity is measured on the toy call. No `color:`/`palette`/`fmt_date` may be injected
into these existing lines, and the legacy body cell stays literally `"$#{item.price}"` (`invoice.ex:168`).
New anatomy fields (`:issuer`/`:customer`/`:due_date`/`:terms`/`:totals`) render only when present.

**`validate_data!/1` wiring** — call it at the top of both `sections/2` and `document/2`, mirroring
Receipt (`receipt.ex:198,229`):
```elixir
def sections(data, opts \\ []) do
  validate_data!(data)
  [header_section(data, opts), body_section(data, opts), footer_section(data, opts)]
end
```

**Non-map + missing-key + Float-reject validation** — copy verbatim, swap module name (`receipt.ex:363-502`):
```elixir
defp validate_data!(data) when not is_map(data) do
  raise ArgumentError, """
  Rendro.Recipes.Invoice.document/2 — invalid data argument.

  What:  data must be a map.
  Where: Rendro.Recipes.Invoice.validate_data!/1
  Why:   Received a non-map value: #{inspect(data)}.
  Next:  Pass a map with required keys :id, :date, :items.
  """
end
# Float head BEFORE generic non-Decimal head (receipt.ex:479-502):
defp validate_line_amount!(value, idx) when is_float(value) do
  raise ArgumentError, """
  ...
  Why:   lines[#{idx}].amount = #{inspect(value)} (Float).
         Float arithmetic is not exact and can produce incorrect financial output.
  Next:  Use Decimal.new/1 — e.g. Decimal.new("#{value}") or Decimal.from_float(#{value}).
  """
end
defp validate_line_amount!(%Decimal{}, _idx), do: :ok
```
> INV-06 landmine: required keys are ONLY `:id`, `:date`, `:items`. All anatomy fields are optional —
> the toy call must never be rejected. Use `Rendro.Recipes.Pagination.type_name/1` (`pagination.ex:76-82`)
> for the `Why:` type string.

**Totals block builder** — copy `build_totals_blocks/2` + `maybe_append_totals_line/4` (`receipt.ex:333-357`):
```elixir
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
defp maybe_append_totals_line(acc, _label, nil, _fmt), do: acc
defp maybe_append_totals_line(acc, label, %Decimal{} = amount, fmt), do: acc ++ ["#{label}: #{fmt.(amount)}"]
```

**Totals caller-assertion via `Decimal.equal?/2`** — copy `maybe_validate_totals!/1` (`receipt.ex:504-556`).
Use `Decimal.equal?/2`, NEVER `==` (struct compare: `1.0` ≠ `1.00`). Single-value equivalent for a lone
`:total` is Statement's `maybe_validate_closing_balance!/1` (`statement.ex:690-708`):
```elixir
derived = Enum.reduce(lines, Decimal.new(0), fn %{amount: amt}, acc -> Decimal.add(acc, amt) end)
unless Decimal.equal?(totals.subtotal, derived) do
  raise ArgumentError, "...:totals.subtotal mismatch... Supplied #{inspect(totals.subtotal)}, Derived #{inspect(derived)}..."
end
```

**INV-03 "kept with last rows" — the ONE place Invoice exceeds a pure Receipt copy.** Receipt appends
totals after the last table block WITHOUT reserving space (`receipt.ex:308-310`), so totals can flow to a
fresh page. Reserve the totals-block height in `effective_capacity` for the final page, mirroring how
Statement reserves 2 forward-rows (`statement.ex:341`):
```elixir
effective_capacity = capacity - header_h - @row_epsilon        # Receipt's formula (receipt.ex:288)
# Invoice: additionally subtract measured totals-block height on the final page.
```
Anti-pattern: do NOT wrap totals in `keep_together` (oversized-group → `:content_overflow`).

**`page_template/1` whitelist (INV-07 seam S1)** — Invoice currently leaks recipe opts via
`Keyword.merge(defaults, opts)` (`invoice.ex:96`); this raises `KeyError` in `struct!(PageTemplate,…)`
once `:palette`/`:formatters` are threaded. Copy Statement's `Keyword.take` (`statement.ex:184-196`):
```elixir
template_opts =
  Keyword.take(opts, [:name, :width, :height, :margin_top, :margin_right,
                      :margin_bottom, :margin_left, :regions])
Rendro.page_template(Keyword.merge(defaults, template_opts))
```
Top-level `opts` stays open (threads to `sections/2` + `palette/1` for B's future `theme:`).

**`palette(opts)` seam (INV-07)** — net-new private helper; no existing analog (color roles don't exist
anywhere in tree yet). Defaults preserve all-black output byte-for-byte (RESEARCH Pattern 4):
```elixir
defp palette(opts) do
  overrides = Keyword.get(opts, :palette, %{})
  Map.merge(%{
    ink: {0, 0, 0}, muted: {0, 0, 0}, accent: {0, 0, 0}, on_accent: {0, 0, 0},
    background: {255, 255, 255}, surface: {255, 255, 255}, rule: {0, 0, 0}
  }, overrides)
end
```
Any NEW section that sets a color must source it from `palette(opts)` (a `{r,g,b}` tuple, consumed by
`Rendro.text(..., color: colors.muted)`). RGB→PDF conversion is `Rendro.Color.rg/1` (internal). Never
inline `{0,0,0}`. The frozen toy lines set no color, so they stay compliant untouched.

**Formatter/label plumbing** — reuse `Rendro.Recipes.Pagination.formatter/3` (`pagination.ex:57-60`) and
`label_resolver/1` (`pagination.ex:64-73`); do not hand-roll opts parsing.

---

### `lib/rendro/format.ex` (adapter/utility, transform) — INV-04

**Analog:** tier-tag + moduledoc pattern from `receipt.ex:1-76`; manifest peer `Elixir.Rendro.Recipes.Receipt`.

**Current state** (`format.ex:1-2`): `@moduledoc false` — functions `money/1`, `date/1`, `label/1` are
ALREADY fully implemented with `@spec`s and doctests (`format.ex:37,59,76`). The promotion writes NO new
functions.

**The flip** — replace `@moduledoc false` with a real moduledoc + adapter tag (mirror the two-attribute
shape at `receipt.ex:2,76` where `@moduledoc """..."""` is followed by `@moduledoc tags: [:adapter]`):
```elixir
@moduledoc """
Pure, locale-free, deterministic formatting helpers for money, dates, and labels.

> Adapter tier — output formatting may evolve across minor versions. Pin exact strings
> only in golden tests you control.
"""
@moduledoc tags: [:adapter]
```
Add a migration/"may evolve" note (INV-04 explicit). The existing doctests already satisfy the
"HexDocs shows the adapter surface" Wave-0 gap; confirm at least one stays public.

**This is a 4-artifact ATOMIC change** (RESEARCH Pitfall 1 / Runtime State Inventory). All four move in
one commit or the contract lane stays red:

1. `lib/rendro/format.ex` — the flip above.
2. `lib/mix/tasks/rendro/api.gen.ex` `@public_modules` — add entry (see below).
3. `test/docs_contract/public_api_contract_test.exs` — delete from hidden set (see below).
4. `priv/public_api.json` — regenerate via `mix rendro.api.gen` (see below).

---

### `lib/mix/tasks/rendro/api.gen.ex` (registry, batch) — INV-04

**Analog:** the existing `@public_modules` list entries (`api.gen.ex:44-101`).

Add `Rendro.Format` to the **Adapter tier** block (alphabetical neighborhood of `Rendro.Inspector`,
`api.gen.ex:86`). Tier is inferred from the module's own `@moduledoc tags:`, so no tier arg is needed
here — the list is just a membership registry:
```elixir
    # Adapter tier — ecosystem integrations, optional adapters, recipe impls
    Rendro.Adapters.HarfBuzz,
    ...
    Rendro.Format,        # ADD — promoted this phase
    Rendro.Inspector,
```

---

### `test/docs_contract/public_api_contract_test.exs` (contract test) — INV-04

**Analog:** the `hidden_modules` list (`public_api_contract_test.exs:85-92`) — this is the deliberate
red-build edit STATE.md flags.

**Delete** `Rendro.Format` (currently `public_api_contract_test.exs:89`) from the list:
```elixir
hidden_modules = [
  Rendro.PDF.CidFont,
  Rendro.PDF.FontSubsetter,
  Rendro.Text.Bidi,
  # Rendro.Format,   <-- DELETE this line (promoted to adapter tier)
  Rendro.Audit,
  Rendro.Examples
]
```
The loop (`:94-118`) asserts each remaining module reports `:hidden` via `@moduledoc false` — leaving
`Format` in the list AFTER the flip fails with "Expected Rendro.Format to have @moduledoc false".

---

### `priv/public_api.json` (generated manifest, batch) — INV-04

**Analog:** the `Elixir.Rendro.Recipes.Receipt` entry (verified shape this session).

Do NOT hand-edit — run `mix rendro.api.gen` to regenerate, then commit. The generator adds an entry under
the top-level `"modules"` object shaped exactly like:
```json
"Elixir.Rendro.Format": {
  "functions": ["date/1", "label/1", "money/1"],
  "tier": "adapter",
  "types": []
}
```
(Manifest tracks **functions + types only**, never struct fields — see cell_align note below.) The
contract test regenerates in-memory and asserts byte-equality against the committed file, so a manual
edit that drifts from generator output fails the surface-equality assertion.

---

### `lib/rendro/cell.ex` + `lib/rendro/table.ex` (`:stable` structs) — INV-05

**Analog:** the inert opt-in fields already on each struct.

**Cell** (`cell.ex:8-21`) — add `cell_align` to the defstruct with an inert default and to the `@type`,
mirroring the existing `keep_together: false` inert fields:
```elixir
defstruct [
  :content, split_policy: :atomic, colspan: 1, rowspan: 1, x: 0, y: 0,
  width: nil, height: nil, keep_together: false, keep_with_next: false,
  break_before: false, break_after: false,
  cell_align: :left      # ADD — inert default; :left == today's unchanged path
]
```

**Table** (`table.ex:8-24`) — mirror the `borders: :none` / `header_fill: nil` "inert by default"
comment block for a column-level `cell_align` rule if surfacing at column granularity:
```elixir
# Opt-in borders / shading fields (all inert by default)
borders: :none, border_style: nil, header_fill: nil,
# ADD (A2): opt-in horizontal alignment, inert default preserves byte-compat
```

> **CRITICAL (RESEARCH Pitfall 3):** `Cell`/`Table` are `@moduledoc tags: [:stable]` (`cell.ex:5`,
> `table.ex:5`). Adding a struct **field** does NOT widen the manifest (functions+types only) and is
> safe. Do NOT add a new public `Rendro.cell_align/…` function — that widens the frozen Stable surface
> and fails the `@spec`-coverage + surface-equality assertions. Prefer surfacing `cell_align` as an
> **option on the existing `Rendro.table/2`** (arity/`@spec` unchanged).

---

### `lib/rendro.ex` `table/2` facade (transform) — INV-05

**Analog:** the `normalize_table_attrs/1` pipeline (`rendro.ex:331-390`).

`table/2` (`rendro.ex:324-335`) funnels attrs through `normalize_table_attrs/1` then `struct!(Table, …)`.
Add a `normalize_table_cell_align/1` stage in the same shape as `normalize_table_borders/1`
(`rendro.ex:394+`) so an unset `cell_align` yields the inert default (unchanged output). `@spec` stays
`@spec table([Table.row()], keyword()) :: Table.t()` — no new public function.

---

### `lib/rendro/pipeline/paginate.ex` `stack_cells` (engine layout) — INV-05

**Analog:** self — extend `stack_cells/4` in place (`paginate.ex:594-602`).

Current code sets each cell's x to the column-left and advances by column width — no alignment slack:
```elixir
defp stack_cells(row, start_x, y, col_widths) when is_list(row) do
  {cells, _} =
    Enum.reduce(Enum.zip(row, col_widths), {[], start_x}, fn {cell, col_w}, {acc, x} ->
      {acc ++ [%{cell | x: x, y: y}], x + col_w}   # <-- default (left) path — MUST stay untouched
    end)
  cells
end
```
Gate any right-align offset strictly on `cell.cell_align == :right`; the `nil`/`:left` branch must take
this exact unchanged path (RESEARCH Pitfall 2). Open Question 2: the measured text width needed for
slack (`col_w - text_width - padding`) may be more available here (post-Measure) than at write time —
prototype a spike before committing the offset location.

---

### `lib/rendro/pdf/writer.ex` `render_text_block` (engine emit) — INV-05

**Analog:** self — extend `render_text_block/8` in place (`writer.ex:702-740`).

Text x is computed once at `writer.ex:703`:
```elixir
x = block.x + ox + page.margin_left     # <-- no-cell_align path — DO NOT alter for left/default cells
```
If the offset is applied here instead of `stack_cells`, add it as `x = base_x + right_align_offset` ONLY
when `:right`. A two-render determinism test AND a golden-hash regression on an existing left-aligned
table must pass before touching this line. Warning sign: `certificate_test`/`branded_invoice_test`
two-render assertions flipping.

---

### `test/rendro/recipes/invoice_test.exs` (test) — INV-01/02/03/06/07

**Analog:** `test/rendro/recipes/receipt_test.exs` — mirror its totals cases, validation cases (non-map /
missing-key / Float-reject / mismatch), and optional-field-present-vs-absent cases. Extend the existing
Invoice file rather than replacing it.

### `test/rendro/recipes/invoice_byte_identity_test.exs` (NEW golden) — INV-01

**Analog:** `branded_invoice_test.exs:169-171` two-render pattern:
```elixir
{:ok, pdf1} = Rendro.render(doc, deterministic: true)
{:ok, pdf2} = Rendro.render(doc, deterministic: true)
assert pdf1 == pdf2
```
For "byte-identical to BEFORE": Wave-0 task records `sha256` of the toy-call render on `main`, then
asserts equality post-change (precedent: Plan 114-01 sha256'd a recorded render). Toy code path stays
frozen (A1).

### `test/rendro/table_test.exs` (mod / NEW cell_align) — INV-05

**Analog:** same two-render determinism assertion. Add (a) a right-align positive test and (b) a
no-`cell_align` byte-identity/golden-hash regression proving existing tables are unchanged.

### `test/rendro/recipes/invoice_opts_threading_test.exs` (mod) — INV-07

**Analog:** self + `branded_invoice_opts_threading_test.exs`. Add cases proving `:palette` and
`:formatters` thread through `opts` to `sections/2` without reaching `struct!(PageTemplate, …)` (the
`Keyword.take` whitelist), and that a `:palette` override changes only the intended section's color.

---

## Shared Patterns

### Errors-as-product `ArgumentError` (What/Where/Why/Next)
**Source:** `receipt.ex:363-502`, `statement.ex:638-708`
**Apply to:** `Invoice.validate_data!/1` (INV-06); the shape is library-wide.
```elixir
raise ArgumentError, """
Rendro.Recipes.Invoice.document/2 — <one-line summary>.

What:  <the rule>.
Where: Rendro.Recipes.Invoice.validate_data!/1
Why:   <what was received> (#{Rendro.Recipes.Pagination.type_name(value)}).
Next:  <how to fix, with a concrete call>.
"""
```

### Decimal caller assertions
**Source:** `receipt.ex:504-556`, `statement.ex:690-708`
**Apply to:** Invoice totals validation (INV-03).
Use `Decimal.equal?/2` (numeric), never `==` (struct-field compare). Derive the expected value by folding
line amounts with `Decimal.add/2` starting from `Decimal.new(0)`.

### Shared recipe plumbing
**Source:** `lib/rendro/recipes/pagination.ex` (`@moduledoc false`)
**Apply to:** Invoice body/totals/header builders.
`formatter/3` (`:57`) for `:amount`/`:date` override plumbing, `label_resolver/1` (`:64`) for labels,
`chunk_rows_into_pages/2` (`:18`) for per-page chunking (has the empty-page infinite-loop guard),
`type_name/1` (`:76`) for error-message type strings.

### Money formatting split (INV-02)
**Source:** `lib/rendro/format.ex:37-47`
**Apply to:** Invoice money.
New Decimal money fields (`:totals`, any Decimal-typed field) route through `Rendro.Format.money/1`.
The legacy bare-number `price` position stays `"$#{item.price}"` (`invoice.ex:168`) — blanket-routing it
would turn `"$200"` into `"$200.00"` and break INV-01 byte-compat (RESEARCH Pitfall 4). Reject `%Decimal{}`
in the legacy `price` slot and `Float` in new fields, both instructively.

---

## No Analog Found

| File / element | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| `Invoice.palette/1` role map | recipe-private helper | transform | Color roles (`ink`/`muted`/`accent`/`on_accent`/`background`/`surface`/`rule`) exist NOWHERE in the tree yet (grep-verified in RESEARCH). This is Milestone-B vocabulary introduced here only as `palette/1` map keys defaulting to today's literals. Use the RESEARCH Pattern-4 shape verbatim. |
| `cell_align: :right` x-offset math | engine layout | transform | First horizontal-alignment primitive in the library — no prior alignment code path to copy. The *struct-field* and *facade-option* halves have exact inert-field analogs (above); only the offset **computation** (slack from measured text width) is genuinely new. RESEARCH Open Question 2 recommends a spike to choose paginate-vs-writer. |

---

## Metadata

**Analog search scope:** `lib/rendro/recipes/`, `lib/rendro/{format,table,cell,color,text}.ex`,
`lib/rendro/pipeline/paginate.ex`, `lib/rendro/pdf/writer.ex`, `lib/rendro.ex`,
`lib/mix/tasks/rendro/api.gen.ex`, `priv/public_api.json`, `test/docs_contract/`, `test/rendro/recipes/`.
**Files scanned:** 14 read + manifest walk.
**Pattern extraction date:** 2026-07-18
</content>
</invoke>

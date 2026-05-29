# Phase 74: statement-recipe - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 6 (3 new, 3 modified)
**Analogs found:** 6 / 6

> All excerpts below are quoted from the live source read this session. Line numbers are re-verified. RESEARCH.md cites several stale line numbers (e.g. `page_number/1` at `rendro.ex:209-214` — correct; but `body_capacity` at `measure.ex:442`, `measure_block/3` at `measure.ex:32` — both verified correct here). Where RESEARCH and the live file disagree, trust this document.

## File Classification

| New/Modified File | New/Mod | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|---------|------|-----------|----------------|---------------|
| `lib/rendro/recipes/statement.ex` | NEW | recipe | transform (data map → Document) | `lib/rendro/recipes/invoice.ex` | exact (recipe + transform) |
| `lib/rendro/format.ex` | NEW | utility | transform (Decimal/Date → string) | `lib/rendro/adapters/accrue.ex` private `format_amount/1` | role-match (extract-to-shared) |
| `lib/rendro.ex` | MOD | engine/public-API | request-response (read-only query) | `lib/rendro.ex` `page_number/1` (self) projecting `measure.ex` `body_capacity/1` | exact (same module) |
| `mix.exs` | MOD | config | n/a | `mix.exs` `deps/0` (self) | exact |
| `test/rendro/recipes/statement_test.exs` | NEW | test | n/a | `test/rendro/recipes/invoice_test.exs` + `branded_invoice_test.exs` | exact |
| `lib/rendro/pipeline/measure.ex` | MOD | engine-internal (expose shim) | transform | `measure.ex` `measure_block/3` Table branch (self) | exact |

> The two test files that exist are `test/rendro/recipes/invoice_test.exs` and `test/rendro/recipes/branded_invoice_test.exs` — no `test/recipes/` dir, no `test/rendro/pipeline/measure_test.exs` yet. RESEARCH's recommended `test/rendro/measure_rows_test.exs` is a Wave-0 gap with no existing analog of its own (closest is the recipe tests' render-assertion style).

---

## Pattern Assignments

### `lib/rendro/recipes/statement.ex` (NEW — recipe, transform)

**Analog:** `lib/rendro/recipes/invoice.ex` (whole-file structural skeleton) + `lib/rendro/recipes/branded_invoice.ex` (validation + explicit-region `page_template`).

Implements D-01, D-02, D-03, D-05, D-06, D-07, D-08, D-10, D-11.

**Module + moduledoc + the three-rung doc contract** (`invoice.ex:1-31`) — copy this moduledoc shape (the "three levels of composability" + zero-to-one + escape-hatch examples):
```elixir
defmodule Rendro.Recipes.Invoice do
  @moduledoc """
  Canonical invoice recipe using the Tiered Composition pattern.

  Exposes three levels of composability:

    - `document/2`      — Batteries-included; returns a fully assembled
                          `%Rendro.Document{}` ready for `Rendro.render/1`.
    - `page_template/1` — Layout only; returns the `%Rendro.PageTemplate{}`.
    - `sections/2`      — Content only; returns a list of `%Rendro.Section{}`
                          structs mapped to named regions.
  ...
  """
```
> Statement: `defmodule Rendro.Recipes.Statement`, add `alias Rendro.Format` (D-11). Note: existing recipes do NOT `alias Rendro.Blocks.{...}` — they call `Rendro.block/2`, `Rendro.text/2`, `Rendro.table/2`, `Rendro.section/1` directly. Follow that (do not invent a `Rendro.Blocks` namespace; it does not exist).

**`document/2` (rung 1)** — copy EXACTLY this builder chain (`invoice.ex:92-105`). It is NOT `Document.new |> put_page_template |> put_sections`; it is `add_template` + `set_template` + `Enum.reduce(add_section)`:
```elixir
@spec document(map(), keyword()) :: Rendro.Document.t()
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
> `Rendro.Document.new/0` exists (`document.ex:103`). For D-08, call `validate_data!(data)` as the first line of `document/2` (BrandedInvoice calls it in BOTH `document/2` `branded_invoice.ex:115` and `sections/2` `:100` — mirror that double-guard so the escape-hatch `sections/2` path is also validated).

**`page_template/1` (rung 2)** — Invoice uses the trivial default-name form (`invoice.ex:50-54`); BrandedInvoice uses the explicit-regions form (`branded_invoice.ex:48-92`). **Statement MUST use the explicit-regions form** because the footer region needs a NON-ZERO height (Pitfall 2; BrandedInvoice's footer is `height: 0` at `:86` which would NOT reserve space). Copy BrandedInvoice's region-list structure, change `name: :statement`, drop `:logo`, and set the footer `height` > 0:
```elixir
# branded_invoice.ex:48-92 — structure to copy
def page_template(opts \\ []) do
  defaults = [
    name: :branded_invoice,
    regions: [
      Rendro.region(name: :header, role: :header, anchor: :top,    x: 152, y: 72,     width: 371.28, height: 112),
      Rendro.region(name: :body,   role: :body,   anchor: :flow,   x: 72,  y: 200,    width: 451.28, height: 569.89),
      Rendro.region(name: :footer, role: :footer, anchor: :bottom, x: 72,  y: 769.89, width: 451.28, height: 0)   # ← Statement: make > 0
    ]
  ]
  Rendro.page_template(Keyword.merge(defaults, opts))
end
```
> `Rendro.region/1` and `Rendro.page_template/1` are public struct builders (`rendro.ex:199-201`, `:194-197`). Default A4 footer height is 0 per RESEARCH (`page_template.ex:44`); Statement overrides it (~24pt).

**`sections/2` (rung 3)** — Invoice form `invoice.ex:68-75` (no validation) vs BrandedInvoice form `branded_invoice.ex:98-108` (validates first). **Use the BrandedInvoice form** (validate first):
```elixir
@spec sections(map(), keyword()) :: [Rendro.Section.t()]
def sections(data, _opts \\ []) do
  validate_data!(data)
  [
    logo_section(data),
    header_section(data),
    body_section(data),
    footer_section(data)
  ]
end
```
> Statement sections per D-02/D-03/D-07: `header_section` (account + period + opening_balance), `body_section` (transaction table with running balance + carried/brought-forward rows), `footer_section` (page number). Keep `opts` (not `_opts`) — the footer + formatters need it.

**Table-row construction pattern** (`invoice.ex:122-139`, identical shape `branded_invoice.ex:166-183`) — the precedent for the transaction table:
```elixir
defp body_section(%{items: items} = _data) do
  table_rows =
    Enum.map(items, fn item ->
      [item.name, Integer.to_string(item.qty), "$#{item.price}"]
    end)

  table =
    Rendro.table(table_rows,
      header: ["Item", "Qty", "Price"],
      columns: [{:share, 1}, {:fixed, 50}, {:fixed, 80}]
    )

  Rendro.section(
    name: :invoice_body,
    region: :body,
    content: [Rendro.block(table)]
  )
end
```
> Statement columns per D-05: `["Date", "Description", "Amount", "Balance"]` (signed Amount + running Balance; NOT separate Charge/Payment — that's deferred). Cells formatted via `Rendro.Format` (D-11), not `"$#{...}"` interpolation. NOTE the existing `"$#{item.price}"` crude formatting is exactly what `Rendro.Format` replaces for Statement (existing recipes' cleanup is deferred per CONTEXT).

**Footer section wiring of the PAGE primitive** (D-03) — build a `:footer`-region section whose content is `Rendro.page_number/1`. The section-builder shape to copy is `invoice.ex:141-149`:
```elixir
defp footer_section(_data) do
  Rendro.section(
    name: :invoice_footer,
    region: :footer,
    content: [
      Rendro.block(Rendro.text("Thank you for your business!", size: 10))
    ]
  )
end
```
> Statement: replace the text block with `Rendro.page_number(Keyword.get(opts, :page_number_opts, []))` (returns a `%Block{}` already — do NOT re-wrap in `Rendro.block`). See `page_number/1` excerpt below.

**Running-balance Decimal fold (D-05/D-06) — NEW logic, no existing analog.**
No running-total reduce exists anywhere in the codebase. Use `Enum.map_reduce/3` seeded with `opening_balance`, accumulating with `Decimal.add/2` (signed amount). RESEARCH Pattern 4 sketch:
```elixir
defp fold_balance(%{opening_balance: ob, lines: lines}) do
  {rows, _final} =
    Enum.map_reduce(lines, ob, fn %{amount: amt} = line, bal ->
      new_bal = Decimal.add(bal, amt)
      {Map.put(line, :balance, new_bal), new_bal}
    end)
  rows
end
```
> The final accumulator is the derived `closing_balance`. Validate an optional caller-supplied `closing_balance` with `Decimal.equal?/2` (Pitfall 5 — structural `==` fails on `"100"` vs `"100.00"`).

**Carried/brought-forward per-page row injection (D-02/D-10) — NEW logic, no analog.** Requires knowing engine break points → uses the new `Rendro.available_height/1` or `Rendro.measure_rows/3` helper (see measure.ex / rendro.ex sections). RESEARCH Open Q1 recommends pre-chunking one table block per page with `break_before: idx > 0`. `break_before` is set via `Rendro.block(content, break_before: true)` (it's a `%Block{}` field — `rendro.ex:216-219` `block/2` forwards arbitrary attrs into `struct!(Block, ...)`).

**`validate_data!/1` raise-with-guidance (D-08)** — copy the GUARD-CLAUSE multi-head style from `branded_invoice.ex:195-214` (NOT a heredoc with a missing-keys list — that approach does not exist in this codebase). The real pattern is a happy-path head returning `:ok`, then progressively-looser heads that `raise ArgumentError` with a precise message:
```elixir
defp validate_data!(%{brand: %{font_name: font_name, logo_name: logo_name}})
     when is_atom(font_name) and is_atom(logo_name),
     do: :ok

defp validate_data!(%{brand: %{font_name: font_name}}) when not is_atom(font_name) do
  raise ArgumentError, "data.brand.font_name must be an atom"
end

defp validate_data!(%{brand: %{logo_name: logo_name}}) when not is_atom(logo_name) do
  raise ArgumentError, "data.brand.logo_name must be an atom"
end

defp validate_data!(%{brand: _brand}) do
  raise ArgumentError, "data.brand must include atom :font_name and :logo_name keys"
end

defp validate_data!(_data) do
  raise ArgumentError,
        "data.brand is required and must include atom :font_name and :logo_name keys"
end
```
> For Statement (D-04/D-05/D-07), heads should: accept `%{period: _, account: _, opening_balance: %Decimal{}, lines: lines}` when `is_list(lines)`; reject `is_float` amounts with the "money must be a Decimal" message (RESEARCH "D-08 validation" code example); reject caller-supplied per-line `:balance` (D-06); reject a malformed `period`. **CRITICAL (Pitfall 6):** raise `ArgumentError`, NOT `Rendro.Error` (`Rendro.Error` is a `defstruct`, not a `defexception` — not raisable). The `%Decimal{}` pattern only compiles once `:decimal` is a declared dep.

---

### `lib/rendro/format.ex` (NEW — utility, transform)

**Analog:** the private `format_amount/*` clauses in `lib/rendro/adapters/accrue.ex:125-127`.

Implements D-11 (and is the consolidation target the adapter re-points to under D-11's "applied to both" spirit; aligning Invoice/BrandedInvoice is DEFERRED).

**Existing precedent** (`accrue.ex:125-127`) — note it handles `nil` and integer and falls through to `to_string/1`:
```elixir
defp format_amount(nil), do: ""
defp format_amount(value) when is_integer(value), do: "$#{value}"
defp format_amount(value), do: to_string(value)
```
> This is the ONLY existing money-formatter. It is crude (`to_string/1` on a Decimal yields the raw coefficient/exponent string, no rounding, no thousands grouping). The Invoice/BrandedInvoice recipes use even cruder inline `"$#{item.price}"` (`invoice.ex:125`, `branded_invoice.ex:169`).

> New `Rendro.Format` shape (D-11 — deterministic, no locale; MUST accept `Decimal`; parentheses for negatives; ISO dates). RESEARCH "Rendro.Format default" code example is the target:
> ```elixir
> defmodule Rendro.Format do
>   @moduledoc "Pure, deterministic money/date formatting for recipes. No CLDR/gettext."
>
>   @spec money(Decimal.t()) :: String.t()
>   def money(%Decimal{} = d) do
>     r = Decimal.round(d, 2)
>     if Decimal.negative?(r),
>       do: "($" <> (r |> Decimal.abs() |> group_thousands()) <> ")",
>       else: "$" <> group_thousands(r)
>   end
>
>   @spec date(Date.t()) :: String.t()
>   def date(%Date{} = d), do: Date.to_iso8601(d)   # locale-independent
>   # group_thousands/1 private — Claude's discretion (D-11 "$1,234.50")
> end
> ```
> The `:formatters` / `:labels` override path (D-11) is dispatched in the recipe (`Keyword.get(opts, :formatters, [])`), defaulting to `&Rendro.Format.money/1` / `&Rendro.Format.date/1`. `Rendro.Format` itself stays a pure default with no opts.

---

### `lib/rendro/adapters/accrue.ex` (NOT modified this phase)

**Decision:** Per CONTEXT Deferred ("Aligning the existing `Invoice`/`BrandedInvoice` recipes onto `Rendro.Format` … a future cleanup, not this phase"), do NOT re-point `accrue.ex` either unless the planner explicitly opts in. The accrue `format_amount/*` (`accrue.ex:125-127`) stays as-is. It is listed in the classification table only as the *analog source* for `Rendro.Format`, not as a file to edit. If the planner does choose to consolidate, keep accrue's `nil`/integer/`to_string` output byte-identical or it will break any accrue snapshot tests.

---

### `lib/rendro/pipeline/measure.ex` (MOD — expose read-only measurement shim, D-09)

**Analog (self):** the private Table branch of `measure_block/3` (`measure.ex:47-79`) and `body_capacity/1` (`measure.ex:442-469`).

**`measure_block/3` Table branch** — produces `header_height` + `row_heights`, the numbers D-09 needs to project:
```elixir
defp measure_block(doc, %Rendro.Block{content: %Rendro.Table{} = table} = block, container_width) do
  width = block.width || container_width || 595.28
  # ...resolve_columns, measure_table_header, project_and_measure_grid...
  table = %{table |
    column_widths: col_widths,
    row_heights: row_heights,
    header_height: header_h,
    ...}
  {:ok, %{block | content: table, width: width, height: height}}
end
```

**`body_capacity/1`** — the `body_h − header_h − footer_h` formula (D-09 read-only projection target):
```elixir
defp body_capacity(%{body_region: %Region{y: body_y, height: body_h},
                     header_region: header_region, footer_region: footer_region})
     when is_number(body_h) do
  header_h = if (header overlaps body), do: header_region.height, else: 0
  footer_h = if (footer overlaps body), do: footer_region.height, else: 0
  body_h - header_h - footer_h
end
defp body_capacity(_layout), do: 0
```

> D-09 plan: add a small PUBLIC function to `measure.ex` (module is currently `@moduledoc false`) that wraps the Table branch — e.g. `def measure_block_public(doc, block, container_width)` delegating to the private `measure_block/3` — so a public `Rendro.measure_rows/3` can build an ephemeral `%Block{content: Rendro.table(rows, opts), width: width}`, measure it, and return `{header_height, row_heights}`. This is a pure read; no pagination behavior changes (PAGE-04 preserved). Do NOT expose `project_and_measure_grid/3` or the grid internals — expose only the thin block-measure entry point. (RESEARCH A4/Open Q1: the engine ALSO auto-splits tables via `Fragmentable`, so this helper is for placing carried/brought-forward rows correctly, not for the split itself.)

---

### `lib/rendro.ex` (MOD — public API, read-only query) — D-09 helper home

**Analog (home pattern):** `page_number/1` (`rendro.ex:209-214`) — the precedent for a small, public, read-only helper that composes existing builders. Also the surrounding struct-builder helpers `page_template/1` (`:194-197`), `region/1` (`:199-201`), `section/1` (`:204-207`), `block/2` (`:216-219`), `table/2` (`:288-299`) show the house style (thin `@spec` + one-liner body).

```elixir
@spec page_number(keyword()) :: Block.t()
def page_number(opts \\ []) do
  format = Keyword.get(opts, :format, "Page {{page_number}} of {{total_pages}}")
  text_opts = Keyword.drop(opts, [:format])
  block(text(format, text_opts))
end
```
> D-09 implementation: add a public `Rendro.measure_rows/3` (RESEARCH-recommended signature) and/or a `Rendro.available_height/1`, placed near `table/2` (`rendro.ex:288`), each delegating to the new public shim in `Rendro.Pipeline.Measure`. Mirror the `page_number/1` shape — `@doc`, `@spec`, thin body:
> ```elixir
> @doc "Read-only: {header_height, row_heights} for `rows` measured as a table of `width`."
> @spec measure_rows([Rendro.Table.row()], number(), Rendro.Document.t(), keyword()) :: {number(), [number()]}
> def measure_rows(rows, width, document, table_opts \\ []) do
>   block = block(table(rows, table_opts), width: width)
>   {:ok, measured} = Rendro.Pipeline.Measure.measure_block_public(document, block, width)
>   {measured.content.header_height || 0, measured.content.row_heights}
> end
> ```
> `Rendro.table/2` (`:288`) and `Rendro.block/2` (`:216`) already exist to build the ephemeral block. Add `Rendro` (and the new helper) to `mix.exs` docs `groups_for_modules` "Core Builder API" only if a new public module is created — `Rendro` is already listed (`mix.exs:122`).

---

### `mix.exs` (MOD — config) — add `:decimal` dep (D-04)

**Analog (self):** `deps/0` (`mix.exs:42-58`):
```elixir
defp deps do
  [
    {:telemetry, "~> 1.4"},
    {:harfbuzz_ex, "~> 1.2"},
    {:unicode_data, "~> 0.8.0"},
    {:phoenix, "~> 1.7", optional: true},
    {:plug, "~> 1.14", optional: true},
    {:oban, "~> 2.17", optional: true},
    {:stream_data, "~> 1.3", only: [:dev, :test], runtime: false},
    # ...
  ]
end
```
> Add `{:decimal, "~> 2.3"}` as a NON-optional core dep (alongside `telemetry`/`harfbuzz_ex`/`unicode_data`). RESEARCH Open Q2: use `~> 2.3` (matches the already-locked 2.3.0 via `ecto`/`jason`/`jsv`), NOT `~> 3.1` (would force a lockfile/dev-dep bump out of scope). Also: `mix.exs:133` `groups_for_modules` "Canonical Recipes" currently lists `Rendro.Recipes`, `Rendro.Recipes.Invoice`, `Rendro.Recipes.BrandedInvoice` — add `Rendro.Recipes.Statement` (and `Rendro.Format` somewhere appropriate, e.g. "Core Builder API") so docs don't warn on the new public modules.

---

### `test/rendro/recipes/statement_test.exs` (NEW — test)

**Analogs:** `test/rendro/recipes/invoice_test.exs` (structure assertions) + `test/rendro/recipes/branded_invoice_test.exs` (validation-raises + determinism + full render). Implements D-11's invariant test and RESEARCH's STMT-01..04 + determinism map.

**`use` + alias + private fixture** (`invoice_test.exs:1-15`):
```elixir
defmodule Rendro.Recipes.InvoiceTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Invoice

  defp sample_data do
    %{
      id: "INV-042",
      date: ~D[2026-04-30],
      items: [
        %{name: "Widget A", qty: 3, price: 200},
        %{name: "Widget B", qty: 1, price: 500}
      ]
    }
  end
```
> Statement fixture per D-07: `%{period: %{from: ~D[...], to: ~D[...]}, account: %{...}, opening_balance: Decimal.new("100.00"), lines: [%{date: ~D[...], description: "...", amount: Decimal.new("50.00")}, ...]}`. Provide a KNOWN multi-page fixture so the `ceil` page-count + balance-continuity assertions are exact (RESEARCH Wave-0 gap).

**`page_template/1` + `sections/2` + `document/2` describe blocks** (`invoice_test.exs:17-116`) — the three-describe layout to mirror (region-name assertions, `match?(%Rendro.Section{}, &1)`, `inspect(... limit: :infinity)` content assertions, `doc.page_template == :invoice`, `doc.page_templates`):
```elixir
describe "page_template/1" do
  test "template has named regions :header, :body, :footer" do
    template = Invoice.page_template()
    region_names = Enum.map(template.regions, & &1.name)
    assert :header in region_names
    assert :body in region_names
    assert :footer in region_names
  end
end

describe "sections/2" do
  test "returns a list of %Rendro.Section{} structs" do
    sections = Invoice.sections(sample_data())
    assert Enum.all?(sections, &match?(%Rendro.Section{}, &1))
  end
end

describe "document/2" do
  test "document has page_template set to :invoice" do
    doc = Invoice.document(sample_data())
    assert doc.page_template == :invoice
  end
end
```

**validate-raises assertion** (`branded_invoice_test.exs:85-113`) — `assert_raise ArgumentError, ~r/.../`:
```elixir
describe "validate_data! (boundary validation D-04)" do
  test "raises when data.brand is missing" do
    assert_raise ArgumentError, ~r/data\.brand/, fn ->
      BrandedInvoice.document(%{id: "INV-001", date: ~D[2026-01-15], items: []})
    end
  end
end
```
> Statement adds: missing-key raise, non-`Decimal`/`Float` amount raise (assert the "money must be a Decimal" message), caller-supplied per-line `:balance` raise, malformed `period` raise.

**Determinism + full-render assertions** (`branded_invoice_test.exs:115-173`) — copy the `%PDF-` prefix check and the byte-identical two-render idiom:
```elixir
describe "regression: byte-identical two-render" do
  test "two deterministic renders are byte-identical" do
    doc = BrandedInvoice.document(sample_data())
    assert {:ok, pdf1} = Rendro.render(doc, deterministic: true)
    assert {:ok, pdf2} = Rendro.render(doc, deterministic: true)
    assert pdf1 == pdf2
  end
end
```
> For STMT-04 page-number assertion, follow the `render_with_diagnostics` + `final_doc.pages` inspection style (`branded_invoice_test.exs:117,131-135`) to read footer-region text per page.

**NEW Statement-only assertions (no analog):** running-balance math (closing == opening + Σ amount via `Decimal.equal?`), page-count == `ceil`, carried-forward = last row of each non-final page, brought-forward = first row of each subsequent page, balance continuity across breaks. RESEARCH Test Map enumerates these — none have an existing analog (existing recipe tests assert structure only, never computed numeric output).

> Optional (recommended, not required by D-11): a small test for `Rendro.measure_rows/3` / `Rendro.available_height/1` asserting heights match the engine and the call is read-only. No existing analog; mirror the recipe tests' assertion style.

---

## Shared Patterns

### Recipe three-rung contract
**Source:** `lib/rendro/recipes/invoice.ex:50-105` (`page_template/1` → `sections/2` → `document/2`); `document/2` chain is `Document.new |> add_template |> set_template` then `Enum.reduce(add_section)` — NOT `put_page_template`/`put_sections`.
**Apply to:** `statement.ex` (D-07/STMT-03). Each rung carries `@spec`.

### validate_data! fail-fast (guard-clause heads, ArgumentError)
**Source:** `lib/rendro/recipes/branded_invoice.ex:195-214` — happy-path head → progressively-looser raising heads; called in both `document/2` (`:115`) and `sections/2` (`:100`).
**Apply to:** `statement.ex` (D-08). Raise `ArgumentError` (never `Rendro.Error` — Pitfall 6).

### Money/date formatting
**Source (today):** `lib/rendro/adapters/accrue.ex:125-127` (`nil`/integer/`to_string`); cruder inline `"$#{...}"` in `invoice.ex:125` / `branded_invoice.ex:169`.
**Becomes:** `lib/rendro/format.ex` (`money/1`, `date/1`, pure, Decimal-first).
**Apply to:** `statement.ex` cells + computed balances (D-11). Existing recipes' migration is DEFERRED.

### Footer page-number wiring
**Source:** `lib/rendro.ex:209-214` `page_number/1` (returns a `%Block{}` already); footer-region section shape `invoice.ex:141-149`.
**Apply to:** `statement.ex` `footer_section/2` with a NON-ZERO footer region height (Pitfall 2; default A4 footer height is 0).

### Read-only engine helper shape
**Source:** `lib/rendro.ex:209-214` `page_number/1` — `@doc` + `@spec` + thin body composing existing builders.
**Apply to:** new `Rendro.measure_rows/3` (and/or `Rendro.available_height/1`, D-09), delegating to a new public shim in `Rendro.Pipeline.Measure` over the private `measure_block/3` Table branch (`measure.ex:47-79`).

### break_before per-page chunking
**Source:** `Rendro.block/2` (`rendro.ex:216-219`) forwards arbitrary attrs into `struct!(Block, ...)`; `break_before` is an honored `%Block{}` field (RESEARCH: `block.ex:14`, `paginate.ex:321`).
**Apply to:** `statement.ex` body — `Rendro.block(table, break_before: idx > 0)` per page (D-10).

### Test module skeleton
**Source:** `test/rendro/recipes/invoice_test.exs:1-15` (`use ExUnit.Case, async: true`, `alias`, private `sample_data/0`) + `branded_invoice_test.exs:85-173` (`assert_raise`, determinism, full render).
**Apply to:** `statement_test.exs` (D-11 + STMT-01..04).

## No Analog Found

| Item | Role | Data Flow | Reason / Guidance |
|------|------|-----------|-------------------|
| Decimal running-balance fold (in `statement.ex`) | recipe logic | transform/reduce | No `Enum.map_reduce`/running-total over `Decimal` anywhere. Use the RESEARCH Pattern 4 sketch. |
| Carried/brought-forward row injection + per-page chunking | recipe logic | transform | No per-page row injection precedent. Uses the new D-09 helper + `break_before`. |
| Closing-balance / page-count `ceil` / continuity assertions (test) | test | n/a | Existing recipe tests assert structure only, never computed numbers. Statement-specific (D-11). |
| `Rendro.measure_rows/3` test (`test/rendro/...`) | test | n/a | No measurement-helper test exists. Closest style = recipe render tests. |
| Currency-symbol / `:formatters` / `:labels` threading | recipe/utility | transform | Existing formatters take no options. D-11 introduces the override path; new behaviour. |

## Metadata

**Analog search scope:** `lib/rendro/recipes/`, `lib/rendro/adapters/`, `lib/rendro/pipeline/measure.ex`, `lib/rendro.ex`, `lib/rendro/document.ex` (signatures), `mix.exs`, `test/rendro/recipes/`
**Files scanned:** 8 read (invoice, branded_invoice, accrue, rendro, measure, invoice_test, branded_invoice_test, mix.exs) + signature greps on `document.ex`/`page_template.ex`/`section.ex`
**Pattern extraction date:** 2026-05-29

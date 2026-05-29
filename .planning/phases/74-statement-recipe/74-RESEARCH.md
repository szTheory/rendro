# Phase 74: Statement Recipe - Research

**Researched:** 2026-05-29
**Domain:** Elixir recipe-layer document assembly on the Rendro deterministic pagination engine; Decimal money arithmetic; recipe-owned table pagination
**Confidence:** HIGH (all engine claims verified against current source; one external dep verified against Hex registry API)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (D-01..D-11 — do NOT relitigate)

- **D-01 — Recipe OWNS pagination of the transaction table.** `sections/2` computes `body_capacity` from declared layout geometry (`body_h − header_h − footer_h`, the engine's own formula), folds the running balance, splits transaction lines into per-page groups, emits them as body blocks with `break_before: true` starting each new page. Engine stays behaviorally unchanged and single-pass. **Rejected:** post-pagination injection seam (zero visibility into per-page body content).
- **D-02 — Carried-forward / brought-forward are REAL BODY ROWS, not running-region content.** Carried-forward = last body row of each non-final page; brought-forward = first body row of each subsequent page. Suppress carried-forward on last page, brought-forward on first page.
- **D-03 — Footer running region carries ONLY "Page X of Y"** via `Rendro.page_number/1` / `fn {page, total}`, mirroring `Invoice.footer_section/1`. Keeps footer reserved height a pure function of geometry.
- **D-04 [RECONCILED] — Monetary amounts and balances are `Decimal`.** Add `:decimal` to `mix.exs` core deps; validate amounts are `Decimal` at the boundary (reject `Float` with an instructive error).
- **D-05 [RECONCILED] — Each transaction line carries a SIGNED `Decimal` `amount`** (positive increases balance, negative decreases). Render signed "Amount" column + running "Balance" column.
- **D-06 — Caller does NOT supply per-line or running balances; the recipe computes them.** `opening_balance + Σ amount` fold. `closing_balance`/`summary` are optional caller assertions the recipe derives when absent; a caller-supplied per-line `:balance` is rejected.
- **D-07 — Bare atom-keyed map, consistent with `Invoice`.** Required top-level keys: `period`, `account`, `opening_balance`, `lines`. Per-line: `%{date: Date.t(), description: String.t(), amount: Decimal.t()}`. `document(data, opts \\ [])`; `opts` forwards to `page_template/1` and carries `:formatters`/`:labels`.
- **D-08 — Validation is "errors-as-product" via `validate_data!/1` that raises** with what/where/why/next, mirroring `BrandedInvoice.validate_data!/1`. No NimbleOptions. Raise for malformed call; `{:ok|:error}` `Rendro.Error` contract stays at `Rendro.render/1`.
- **D-09 — Expose a thin read-only PUBLIC measurement helper AND have the recipe reserve conservative capacity (do BOTH).** Promote a pure measurement projection to public API so the recipe chunks using the engine's own numbers; recipe also packs to `body_capacity − epsilon` as defense-in-depth.
- **D-10 [page-grouping invariant]:** Structure each page's rows as one ordered group `[brought_forward?, ...txns, carried_forward?]` with `break_before: true` on the first block of every page after page 1. Do NOT also rely on engine keep-rules (double-paginates). Never set `keep_together` on a group larger than `body_capacity`. Recipe-level invariant test: page count matches `ceil`, first/last rows carry the right labels.
- **D-11 — Pure `Rendro.Format` default + `:formatters` / `:labels` escape hatch.** `$1,234.50`, parentheses for negatives, ISO `YYYY-MM-DD` dates; labels "Balance"/"Brought forward"/"Carried forward"/"Opening balance"/"Closing balance". No CLDR/gettext in core. Default formatter MUST accept `Decimal`. Applied to BOTH caller amounts AND recipe-computed balances.

### Claude's Discretion
- Exact module layout of `Rendro.Recipes.Statement` (private builders mirroring `invoice.ex`); `Rendro.Format` internal helpers; precise `validate_data!/1` message wording.
- Exact public signature/name/placement of the D-09 measurement helper (researcher confirms read-only + behavior-neutral — see Open Questions resolution below).
- `period` shape (`Date.range/2` vs `%{from:, to:}`) — pick one, guard it, keep consistent.
- Whether `summary` totals are `%{total_debits:, total_credits:, line_count:}` or a superset.

### Deferred Ideas (OUT OF SCOPE)
- Conventional Debit/Credit display columns (via a future `:columns` option).
- Currency/locale-aware formatting in core (the `:formatters` closure is the i18n path).
- Aligning existing `Invoice`/`BrandedInvoice` recipes onto `Rendro.Format` (future cleanup).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STMT-01 | Generate statement from a data map via `Rendro.Recipes.Statement.document/2` (period, opening/closing balance, transaction lines, summary) | Three-rung skeleton verified in `invoice.ex`/`branded_invoice.ex`; data-map + `validate_data!/1` idiom confirmed; `:decimal` dep confirmed absent and must be added |
| STMT-02 | Paginates across pages with carried/brought-forward running balance computed in `sections/2`, deterministic across breaks | Recipe-owned pagination confirmed viable: paginator treats a table as ONE atomic block, honors `break_before` (`paginate.ex:141`), and raises `:content_overflow` if a single block exceeds `body_capacity` (`paginate.ex:263`). Decimal fold is exact/deterministic. |
| STMT-03 | Three-rung escape hatch consistent with `Invoice` | `document/2` → `page_template/1` → `sections/2` pattern read verbatim from `invoice.ex`; `Document.new/add_template/set_template/add_section` chain confirmed |
| STMT-04 | "Page X of Y" via the PAGE primitive | `Rendro.page_number/1` (`rendro.ex:181`) returns `fn {page, total} -> [block] end`; `Section.content` typespec accepts that fn (`section.ex`); paginator evaluates it per-page single-pass |
</phase_requirements>

## Summary

This is a **recipe-layer phase plus one small read-only engine addition**. Everything load-bearing was verified against current source. The three-rung pattern (`document/2`/`page_template/1`/`sections/2`) is small and mechanical to mirror from `Rendro.Recipes.Invoice`. The PAGE footer wiring is a one-liner: `Rendro.section(region: :footer, content: [Rendro.page_number()])` with a non-zero footer region height in the recipe's `page_template/1`.

The genuinely interesting work is **recipe-owned pagination of the transaction table** and the **D-09 measurement helper**. The decisive engine fact: **the paginator treats a `Rendro.Table` as a single atomic block — there is NO row-level table continuation in `paginate.ex`.** A table block lands wholly on one page (and is overflow-checked); the paginator only breaks *between* blocks, honoring `break_before` when the current page is non-empty. Therefore the recipe must **pre-split the transactions into one `Rendro.table` block per page**, each carrying its own repeated header row, optional brought-forward first row, the page's transaction rows, and optional carried-forward last row; every per-page block after the first gets `break_before: true`. Each per-page block MUST be ≤ `body_capacity` or the engine raises `:content_overflow` (`paginate.ex:263`, threshold `used > capacity + 0.01`).

To chunk rows safely the recipe needs the engine's *actual* per-row heights (a recipe-local estimate that drifts produces off-by-one breaks → hard overflow). The private chain `measure_block/3 → measure_table/4 → measure_row/6` already computes exactly this; D-09 promotes a thin read-only projection of it to public API.

**Primary recommendation:** Add `{:decimal, "~> 2.3"}` to core deps. Build `Rendro.Recipes.Statement` mirroring `Invoice` plus a private balance-folder and a per-page row-chunker. Add `Rendro.Format` (pure, deterministic). Add one read-only public measurement helper — recommended `Rendro.measure_rows/3` on `lib/rendro.ex` — that projects `measure_row` heights for a table against a body width. Optionally add `Rendro.Recipes` as a `@moduledoc false` base for shared recipe helpers (this is the roadmap-noted Recipes.Base extraction folded into Phase 74).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Statement data validation | Recipe (`validate_data!/1`) | — | Errors-as-product at the recipe boundary; mirrors `BrandedInvoice` |
| Running-balance fold | Recipe (`sections/2`, data-assembly) | — | D-01/D-06: engine stays stateless/single-pass; balance is pure data math |
| Transaction-table pagination | Recipe (row chunking) | Engine (`break_before` honor) | D-01: recipe decides breaks; engine obeys a directive it already supports |
| Per-row height measurement | Engine (read-only projection, D-09) | Recipe (consumes numbers) | Recipe must use engine's own metrics to avoid overflow drift |
| Carried/brought-forward rows | Recipe (real body rows) | — | D-02: running-region fn cannot see per-page body content |
| "Page X of Y" footer | Engine PAGE primitive (`page_number/1`) | Recipe (wires it into footer section) | D-03/STMT-04: single-pass per-page substitution already shipped in Phase 73 |
| Money/date formatting | Recipe (`Rendro.Format`, pure) | Caller (`:formatters` override) | D-11: no CLDR/locale in core; determinism preserved |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `decimal` | `~> 2.3` (latest 2.3.0) | Exact decimal money arithmetic for balances/amounts | The canonical Elixir money idiom (Ecto `:decimal` columns, `ex_money` build on it); zero transitive deps; exact + deterministic. `[VERIFIED: hex.pm API]` |

### Supporting (already in tree — reuse, do not add)
| Module | Purpose | When to Use |
|--------|---------|-------------|
| `Rendro.Recipes.Invoice` | Three-rung reference skeleton | Copy structure for `Statement` `[VERIFIED: lib/rendro/recipes/invoice.ex]` |
| `Rendro.Recipes.BrandedInvoice.validate_data!/1` | Raise-with-guidance validation idiom | Mirror for D-08 `[VERIFIED: branded_invoice.ex:195-214]` |
| `Rendro.page_number/1` | PAGE footer helper `fn {page,total} -> [block]` | D-03 footer wiring `[VERIFIED: rendro.ex:181]` |
| `Rendro.Block` `break_before:` | Force per-page break (honored by paginator) | D-01/D-10 `[VERIFIED: block.ex:14, paginate.ex:141]` |
| `Rendro.table/2`, `Rendro.section/1`, `Rendro.block/2` | Builder primitives | Body table + footer assembly `[VERIFIED: rendro.ex:145,87,3]` |
| `Rendro.Error` (`defexception`) | Instructive raise for D-08 | `raise Rendro.Error, stage:, reason:, message:, hint:` `[VERIFIED: error.ex:9-16]` |
| `Rendro.Adapters.Accrue.format_amount/1` | Existing `Decimal`-aware formatting precedent | Align `Rendro.Format` defaults `[VERIFIED: accrue.ex:124-134]` |

### Alternatives Considered (all rejected upstream in CONTEXT — do not re-explore)
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Decimal` | integer minor units (cents) | Rejected D-04: off-by-100/exponent footguns, caller friction |
| Signed amount | `type: :debit/:credit` | Rejected D-05: debit/credit balance-direction convention trap |
| Recipe-owned pagination | post-pagination seam | Rejected D-01: seam has zero per-page body visibility |
| `Rendro.Format` | CLDR/gettext in core | Rejected D-11: runtime-locale → non-deterministic |

**Installation:**
```elixir
# mix.exs — add to deps/0 alongside the other non-optional core deps
{:decimal, "~> 2.3"},
```

**Version verification:** `decimal` confirmed against the authoritative Hex registry — latest stable **2.3.0**, released **2025-02-12** (prior: 2.2.0 2024-12-22, 2.1.1 2023-08-08). Source repo `github.com/ericmj/decimal` (maintained by José Valim / Eric Meadows-Jönsson). `[VERIFIED: hex.pm/api/packages/decimal]`

> **Currently absent and required:** `decimal` is NOT in `mix.exs` deps and NOT in `mix.lock`/`deps/` — confirmed by grep. Note: `lib/rendro/adapters/accrue.ex` already *calls* `Decimal.to_string/2` / `Decimal.round/2` but only resolves at runtime in a caller's app that has Decimal; the core has never declared it. Phase 74 makes it a real core dep. After adding, run `mix deps.get` and reinstall any built artifacts. `[VERIFIED: grep mix.lock + deps/]`

## Package Legitimacy Audit

> slopcheck and `mix hex.info` were unavailable offline at research time. `decimal` was verified directly against the authoritative Hex registry API instead.

| Package | Registry | Age | Source Repo | Verdict | Disposition |
|---------|----------|-----|-------------|---------|-------------|
| `decimal` | Hex (hex.pm) | first released ~2015; 2.x line since 2020; 2.3.0 on 2025-02-12 | github.com/ericmj/decimal | Authoritative registry confirmed; canonical ecosystem package (Ecto-grade ubiquity); zero runtime transitive deps | Approved |

**Packages removed due to slop verdict:** none.
**Packages flagged suspicious:** none. (`decimal` is one of the most-depended-on packages in the Elixir ecosystem; registry identity + known source repo + version history all consistent.)

## Architecture Patterns

### System Architecture Diagram

```
caller data map (period, account, opening_balance, lines, [closing_balance], [summary], opts)
        │
        ▼
Rendro.Recipes.Statement.document(data, opts)
        │  ├─► validate_data!(data)  ── raises Rendro.Error/ArgumentError on bad shape / Float amount
        │
        ├─► page_template(opts) ──► %PageTemplate{ header(h=0), body(h=648 default),
        │                                          footer(h=NONZERO, content: page_number/1) }
        │                                          (footer height MUST be > 0 to reserve space)
        │
        └─► sections(data, opts)
                │
                ├─ header_section  (account + period summary)
                │
                ├─ body_section ──────────────────────────────────────────────┐
                │     1. fold running balance: opening_balance + Σ amount      │ (pure Decimal,
                │        → [{line, balance_after}]                             │  data-assembly,
                │     2. compute body_capacity = body.h − header.h − footer.h  │  deterministic)
                │     3. measure candidate row heights via Rendro.measure_rows │
                │        (D-09 — engine's OWN numbers)                         │
                │     4. chunk rows into pages so each page's                  │
                │        [hdr, brought_fwd?, ...txns, carried_fwd?] ≤          │
                │        body_capacity − epsilon  (D-09/D-10)                  │
                │     5. emit one Rendro.table block per page;                 │
                │        break_before: true on every block after the first    │
                │                                                              │
                └─ footer_section: Rendro.section(region: :footer,             │
                       content: [Rendro.page_number()])  (D-03)               │
                                                                              ▼
        ▼                                                          %Rendro.Document{}
Rendro.render(doc)  ──► measure ──► paginate (single pass: places each table block,         
                                    honors break_before, overflow-checks each block,        
                                    substitutes {{page}}/{{total}} per page) ──► render ──► PDF
```

### Recommended Module Structure
```
lib/rendro/recipes/statement.ex   # the recipe (document/2, page_template/1, sections/2 + private builders)
lib/rendro/format.ex              # Rendro.Format — pure deterministic money/date formatting (D-11)
lib/rendro.ex                     # + Rendro.measure_rows/3 public read-only helper (D-09)
lib/rendro/recipes.ex (optional)  # Rendro.Recipes base, @moduledoc false — shared recipe helpers
                                  #   (roadmap-noted "Recipes.Base extraction" folded into Phase 74)
```

### Pattern 1: Three-rung escape hatch (mirror verbatim from Invoice)
**What:** `document/2` composes `page_template/1` + `sections/2` via the Document builder chain.
**When:** Always — this is STMT-03's exact requirement.
```elixir
# Source: lib/rendro/recipes/invoice.ex:93-105 (VERIFIED current)
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

### Pattern 2: Footer wiring of the PAGE primitive (D-03 / STMT-04)
**What:** Put `Rendro.page_number/1`'s function into a footer section AND give the footer region a non-zero height in `page_template/1`.
**Critical:** The default template's footer height is **0** (`page_template.ex:33`). With height 0, `body_capacity` subtracts nothing and the footer overlaps the last body row. The Statement `page_template/1` MUST override the footer region with a real height (e.g. `height: 24`).
```elixir
# footer_section — mirrors Invoice.footer_section/1 shape (invoice.ex:141), content from page_number/1
defp footer_section(_data, opts) do
  Rendro.section(
    name: :statement_footer,
    region: :footer,
    content: [Rendro.page_number(Keyword.get(opts, :page_number_opts, []))]
  )
end

# page_template/1 — override footer height so body_capacity reserves footer space
def page_template(opts \\ []) do
  defaults = [
    name: :statement,
    regions: [
      Rendro.region(name: :header, role: :header, anchor: :top,    x: 72, y: 72,  width: 468, height: HEADER_H),
      Rendro.region(name: :body,   role: :body,   anchor: :flow,   x: 72, y: ...,  width: 468, height: BODY_H),
      Rendro.region(name: :footer, role: :footer, anchor: :bottom, x: 72, y: ...,  width: 468, height: 24)  # NON-ZERO
    ]
  ]
  Rendro.page_template(Keyword.merge(defaults, opts))
end
```
`Rendro.page_number/1` signature `[VERIFIED: rendro.ex:181]`: `fn {page, total} -> [Rendro.block(Rendro.text("Page #{page} of #{total}", size: ...))] end`, opts `:size`/`:prefix`/`:separator`. `Section.content` accepts this fn `[VERIFIED: section.ex typespec]`.

### Pattern 3: Recipe-owned pagination — one table block per page (D-01/D-10)
**What:** Because the paginator treats a table as one atomic block (no row continuation), the recipe emits N table blocks, one per page.
```elixir
# Conceptual body_section
defp body_section(data, opts) do
  template = page_template(opts)
  body_region   = Enum.find(template.regions, & &1.role == :body)
  header_region = Enum.find(template.regions, & &1.role == :header)
  footer_region = Enum.find(template.regions, & &1.role == :footer)
  capacity = body_region.height - header_region.height - footer_region.height  # engine's formula

  rows_with_balance = fold_balance(data)              # [{date, desc, amount, balance}] via Decimal
  pages = chunk_pages(rows_with_balance, capacity, opts) # uses Rendro.measure_rows + epsilon margin

  blocks =
    pages
    |> Enum.with_index()
    |> Enum.map(fn {page_rows, idx} ->
      tbl = Rendro.table(page_rows, header: header_cells(opts), columns: COLS)
      Rendro.block(tbl, break_before: idx > 0)        # break_before on every page after the first
    end)

  Rendro.section(name: :statement_body, region: :body, content: blocks)
end
```
**Why this works:** `place_block/3` (`paginate.ex:112`) breaks before a block iff `Map.get(block.source, :break_before, false) and current_page != []` (`maybe_break_before`, `paginate.ex:141`). A table block that fits goes on the current page; `break_before: true` forces the next one onto a fresh page. `[VERIFIED: paginate.ex:112-145]`

### Pattern 4: Decimal running-balance fold (D-05/D-06)
```elixir
defp fold_balance(%{opening_balance: ob, lines: lines}) do
  {rows, _final} =
    Enum.map_reduce(lines, ob, fn %{amount: amt} = line, bal ->
      new_bal = Decimal.add(bal, amt)        # exact; signed amount
      {Map.put(line, :balance, new_bal), new_bal}
    end)
  rows
end
```
`Decimal.add/2` is exact and deterministic — no float drift, satisfies STMT-02. `[CITED: hexdocs.pm/decimal]`

### Anti-Patterns to Avoid
- **Estimating row heights recipe-locally** instead of using `Rendro.measure_rows` → off-by-one breaks → hard `:content_overflow` (D-09). Use the engine's numbers.
- **Setting `keep_together: true` on a per-page group** that could exceed `body_capacity` → converts a soft re-break into a hard overflow (D-10). Don't.
- **Leaving footer region height at 0** while putting page numbers in it → footer overlaps last body row (PAGE-03 only reserves declared height).
- **Putting carried/brought-forward in the footer/header running region** → impossible; the `fn {page,total}` cannot see per-page body content (D-02).
- **Packing exactly to `body_capacity`** → sub-pixel rounding tips into overflow; pack to `capacity − epsilon` (one row), D-09.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-row table heights | recipe-local font/wrap estimate | `Rendro.measure_rows/3` (D-09, projects `measure_row`) | Must match engine exactly or pagination drifts into overflow |
| Page-number footer | manual `{{page}}` string handling | `Rendro.page_number/1` | Single-pass `{page,total}` substitution already shipped (Phase 73) |
| Decimal arithmetic | float math / manual rounding | `Decimal.add/round/compare` | Exactness + determinism; float money is a correctness bug |
| Page breaks | a second pagination pass in the recipe | engine `break_before` honor | Engine already breaks between blocks single-pass |
| Validation framework | NimbleOptions for nested records | `validate_data!/1` raise idiom | Right tool for nested line records; keeps deps light (D-08) |

**Key insight:** The engine already does measurement and single-pass break-honoring correctly. The recipe's only novel jobs are (a) the Decimal fold and (b) deciding *where* to put breaks — and (b) is correct only if it reuses the engine's measurement (D-09).

## Common Pitfalls

### Pitfall 1: Table treated as atomic — no row continuation
**What goes wrong:** Author assumes the engine will split a long transaction table across pages.
**Why:** `paginate.ex` has NO table-row continuation logic (verified by grep: no split/continue/row logic). A `Rendro.Table` measures to a single `MeasuredBlock` with one summed `height` (`measure_table` → `total_height`). The paginator only breaks *between* blocks.
**How to avoid:** Recipe pre-splits into one table block per page (Pattern 3).
**Warning signs:** A multi-page statement renders as a single overflowing page, or raises `:content_overflow`.

### Pitfall 2: Footer height left at 0
**What goes wrong:** "Page X of Y" overlaps the last body row.
**Why:** `body_capacity = body_h − header_h − footer_h` and default footer height is 0 (`page_template.ex:33`); PAGE-03 reserves only *declared* height.
**How to avoid:** Statement `page_template/1` sets a non-zero footer height.
**Warning signs:** Page number prints on top of the carried-forward row.

### Pitfall 3: Overflow threshold is `used > capacity + 0.01`
**What goes wrong:** A per-page block packed exactly to capacity tips over due to float rounding.
**Why:** `check_overflow!` raises when `used > capacity + 0.01` (`paginate.ex:263`).
**How to avoid:** Chunk to `capacity − epsilon` (one row of slack), D-09 part 2.
**Warning signs:** Intermittent `:content_overflow` on borderline page fills.

### Pitfall 4: Float amounts silently breaking determinism
**What goes wrong:** Caller passes `1.10` (float); `1.10` is not exactly representable → non-deterministic / wrong totals.
**Why:** Money in float is a correctness bug (D-04).
**How to avoid:** `validate_data!/1` rejects `Float` amounts with an instructive `Rendro.Error`.
**Warning signs:** Balances off by a cent; non-byte-identical output across runs.

### Pitfall 5: `Decimal.equal?` vs `==` for closing-balance assertion
**What goes wrong:** Comparing a caller-supplied `closing_balance` to the folded result with `==` fails on differing exponents (`Decimal.new("100") != Decimal.new("100.00")` structurally).
**Why:** `Decimal` `==` is structural; equality must use `Decimal.equal?/2` or `Decimal.compare/2`.
**How to avoid:** Use `Decimal.equal?/2` when validating the optional `closing_balance` assertion (D-06).
**Warning signs:** Valid statements rejected for a "mismatched" closing balance.

## Code Examples

### D-09 measurement helper — RECOMMENDED signature (read-only projection)
```elixir
# Source: projects the existing private chain measure_block/3 → measure_table/4 →
#         measure_row/6 (lib/rendro/pipeline/measure.ex:142,290). Read-only; no pagination change.
# Placement: lib/rendro.ex (public Builder API surface, near table/2 and page_number/1).

@doc """
Returns the measured heights (in points) of each row of `rows` as it would be
laid out in a `Rendro.table/2` of total width `width`, using `document`'s font
metrics. Read-only: does not paginate, render, or mutate. Lets recipes chunk
rows by the engine's own measurement (avoids off-by-one page breaks).
"""
@spec measure_rows([[String.t()]], number(), Rendro.Document.t()) :: [float()]
def measure_rows(rows, width, document) do
  # Build an ephemeral table block, run it through the existing measure_table
  # projection, and return [row.height]. Reuses measure_row → MeasuredRow.height.
end
```
**Why this signature:** `measure_row/6` needs (row, col_widths, table, document, opts, kind). `col_widths` derive from the table block's resolved width (`resolve_column_widths` ← `block_width` ← region/default width). `document` supplies font metrics / default content width (`block_width` falls back to `default_content_width(document)`). So the minimal public surface is `(rows, width, document)`. Returning a list of per-row heights lets the recipe cumulatively chunk including the repeated header/brought-forward/carried-forward rows. This is a pure read of existing logic — PAGE-04 single-pass preserved, no behavior change. `[VERIFIED: measure.ex:142,207,214,290; measured.ex MeasuredRow]`

> **Alternative considered:** `Rendro.Recipes.row_capacity(template, document)` returning an integer row count. Rejected as the public primitive because row heights vary (wrapped descriptions, multi-line cells); a per-row height list is more honest and composes with the brought/carried rows. The recipe can wrap `measure_rows` in a private `row_capacity` helper.

### Decimal validation in validate_data!/1 (D-08, reject Float)
```elixir
defp validate_amount!(%Decimal{}), do: :ok
defp validate_amount!(amt) when is_float(amt) do
  raise Rendro.Error,
    stage: :recipe,
    reason: :invalid_amount,
    message: "Transaction amount #{inspect(amt)} is a float; money must be a Decimal.",
    hint: "Pass Decimal.new(\"#{amt}\") (or your Ecto :decimal value) instead of a float literal."
end
defp validate_amount!(other) do
  raise ArgumentError, "Transaction :amount must be a Decimal, got: #{inspect(other)}"
end
```
`Rendro.Error` is a `defexception [:stage, :reason, :message, :hint, :details]` supporting the keyword raise form `[VERIFIED: error.ex:9]`. Note `%Decimal{}` pattern compiles once `:decimal` is a dep.

### Rendro.Format default (D-11, deterministic, no locale)
```elixir
# Source: aligns with Rendro.Adapters.Accrue.format_amount/1 (accrue.ex:124)
def money(%Decimal{} = d) do
  rounded = Decimal.round(d, 2)
  if Decimal.negative?(rounded) do
    "($" <> (rounded |> Decimal.abs() |> group_thousands()) <> ")"   # parentheses for negatives
  else
    "$" <> group_thousands(rounded)
  end
end
def date(%Date{} = d), do: Date.to_iso8601(d)   # YYYY-MM-DD, locale-independent
```

## Runtime State Inventory

Not applicable — Phase 74 is greenfield recipe code plus one additive public function and one new core dependency. No rename/refactor/migration of stored data, services, OS state, secrets, or artifacts.

**Stored data:** None — no datastore touched.
**Live service config:** None.
**OS-registered state:** None.
**Secrets/env vars:** None.
**Build artifacts:** Adding `:decimal` requires `mix deps.get`; no stale artifacts to migrate (decimal was never built into the package before). `[VERIFIED: deps/ has no decimal]`

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `{{page_number}}` token only | `fn {page, total} -> content` primitive + `page_number/1` sugar | Phase 73 | Statement uses the fn/helper directly (D-03) |
| `body_capacity = body_h` (ignored footer) | `body_h − header_h − footer_h` with overlap guards | Phase 73 (73-02) | Statement footer height now correctly reserves space |
| Invoice `"$#{price}"` crude formatting | `Rendro.Format` pure deterministic | Phase 74 (this) | Statement formats Decimal correctly; Invoice cleanup deferred |

**Deprecated/outdated:** none relevant.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Rendro.measure_rows/3` is the right name/placement for the D-09 helper | Code Examples / Open Q | Low — name is Claude's-discretion; planner may rename. Signature shape (rows, width, document) is grounded in `measure_row/6`'s real inputs. |
| A2 | A non-zero footer height ~24pt is adequate for one line of page-number text at default size 9 | Pattern 2 | Low — exact value tunable; the *requirement* (height > 0) is verified, the magnitude is an estimate. |
| A3 | `Decimal` `==` is structural (needs `Decimal.equal?`) for closing-balance check | Pitfall 5 | Low — standard Decimal behavior; verify against `hexdocs.pm/decimal` during implementation. `[CITED]` |
| A4 | `default_content_width(document)` exists as the fallback for `block_width` | D-09 helper | Low — referenced in `block_width/3` (`measure.ex:207`); planner confirms the exact helper when wiring `measure_rows`. |

## Open Questions

1. **D-09 helper exact name/placement** — RESOLVED to a recommendation. Recommend `Rendro.measure_rows(rows, width, document) :: [float()]` on `lib/rendro.ex`. It is a pure read-only projection of `measure_table`/`measure_row`; PAGE-04 single-pass is preserved because it never paginates or substitutes. Planner finalizes the name and whether to also expose a `row_capacity` convenience (recommend keeping `row_capacity` private inside the recipe).
2. **`period` shape** — Claude's discretion. Recommend `%{from: Date.t(), to: Date.t()}` over `Date.range/2`: explicit, easy to validate, easy to format with `Rendro.Format.date/1` for each endpoint, and avoids `Date.range` step/inclusivity surprises. Guard it in `validate_data!/1`.
3. **`summary` totals shape** — Claude's discretion. Recommend deriving `%{total_debits:, total_credits:, line_count:, closing_balance:}` when absent (sum of positive amounts, abs sum of negatives, count, final folded balance) and, if the caller supplies any of these, validate with `Decimal.equal?/2`.
4. **Recipes base extraction** — STATE.md notes `Rendro.Recipes.Base` is enabling work folded into Phase 74. The `Rendro.Recipes` module is referenced in `mix.exs` docs `groups_for_modules` but **does not yet exist as a file** (verified: only `invoice.ex` + `branded_invoice.ex` in `lib/rendro/recipes/`). Planner decides whether to create `lib/rendro/recipes.ex` (`@moduledoc false`) now for shared helpers (balance fold, row chunking, format dispatch) or keep them private to `Statement`. Low risk either way; extraction can be minimal at coarse granularity.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `decimal` (Hex) | money arithmetic (D-04) | ✗ (not yet declared) | target `~> 2.3` (2.3.0) | none — must add to deps + `mix deps.get` |
| Elixir | all | ✓ | `~> 1.19` | — |
| Existing Rendro engine | recipe consumes | ✓ | in-tree | — |

**Missing dependencies with no fallback:** `decimal` — but trivially resolved by adding the dep (the whole point of D-04). No blocker.

## Validation Architecture

> nyquist_validation is enabled (config.json `workflow.nyquist_validation: true`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (`use ExUnit.Case, async: true`) `[VERIFIED: test/rendro/recipes/invoice_test.exs]` |
| Config file | none beyond `test/test_helper.exs` (standard mix) |
| Quick run command | `mix test test/rendro/recipes/statement_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STMT-01 | `document/2` returns a renderable `%Document{}` from a data map; `Rendro.render/1` returns `{:ok, pdf}` | unit | `mix test test/rendro/recipes/statement_test.exs` | ❌ Wave 0 |
| STMT-01 | `validate_data!/1` raises on missing keys / non-Decimal / Float amount / malformed period | unit | same | ❌ Wave 0 |
| STMT-02 | Multi-page statement: page count == `ceil(total_rows / rows_per_page)` (invariant test, D-10) | unit (paginate) | same | ❌ Wave 0 |
| STMT-02 | Carried-forward is the last row of each non-final page; suppressed on last page | unit | same | ❌ Wave 0 |
| STMT-02 | Brought-forward is the first row of each page after the first; suppressed on page 1 | unit | same | ❌ Wave 0 |
| STMT-02 | Running balance correct across page breaks (brought-forward of page N+1 == carried-forward of page N == folded balance) | unit | same | ❌ Wave 0 |
| STMT-02 | No `:content_overflow` raised for a realistic large statement (epsilon-margin works) | unit | same | ❌ Wave 0 |
| STMT-03 | `page_template/1` and `sections/2` callable independently; structurally consistent with Invoice (region names/roles) | unit | same | ❌ Wave 0 |
| STMT-04 | "Page X of Y" present and correct on every page including the last (total == real page count) | unit (paginate) | `mix test test/rendro/recipes/statement_test.exs` + assert on paginated pages' footer region text | ❌ Wave 0 |
| STMT-04 | Footer region has non-zero reserved height; body content does not overlap footer | unit | same | ❌ Wave 0 |
| STMT-02 | Determinism: render twice with `deterministic: true` → byte-identical (`pdf1 == pdf2`) | unit | `mix test` (mirror determinism_test idiom) | ❌ Wave 0 |
| (helper) | `Rendro.measure_rows/3` returns per-row heights matching engine measurement; read-only | unit | `mix test test/rendro/measure_rows_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/recipes/statement_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** full suite green + `mix ci` (format/compile-warnings-as-errors/credo/dialyzer) before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/rendro/recipes/statement_test.exs` — covers STMT-01..04 + determinism
- [ ] `test/rendro/measure_rows_test.exs` — covers the D-09 helper (read-only, heights match)
- [ ] (optional) shared fixtures: a `statement_fixture/1` building a known multi-page data map (e.g. opening_balance + N signed Decimal lines) so page-count `ceil` and balance-continuity assertions are exact

*Framework already present (ExUnit); no install needed.*

## Security Domain

> `security_enforcement` is not set in config.json. This phase is pure local document assembly with no auth, no network, no user-supplied executable content, no persistence. ASVS surface is minimal.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a — no auth in recipe layer |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a |
| V5 Input Validation | yes | `validate_data!/1` rejects malformed data / Float amounts with instructive errors (D-08) |
| V6 Cryptography | no | n/a — no crypto in this phase |

### Known Threat Patterns for {Elixir recipe layer}
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Caller-supplied text in transaction descriptions reaching PDF text stream | Tampering / Injection | Rendro text shaping treats content as literal glyphs (no template injection); only curated running-region tokens substitute (per v2.4 out-of-scope: no arbitrary substitution). No new surface here. |
| Float/precision corruption of financial totals | Tampering (data integrity) | Decimal-only amounts + `validate_data!/1` reject Float (D-04/D-08) |
| Non-deterministic output undermining auditability | Repudiation | Deterministic Decimal fold + locale-free `Rendro.Format`; `deterministic: true` byte-identical test (D-11/PAGE-04) |

## Sources

### Primary (HIGH confidence — verified against current source this session)
- `lib/rendro/recipes/invoice.ex` (full) — three-rung skeleton, `document/2`/`page_template/1`/`sections/2`, Document builder chain
- `lib/rendro/recipes/branded_invoice.ex:48-214` — `validate_data!/1` raise idiom, non-default `page_template` with explicit region heights
- `lib/rendro/pipeline/paginate.ex:54-280` — `do_paginate`, `paginate_body`, `place_block`, `maybe_break_before` (`Map.get(block.source,:break_before,false) and current_page != []`), `body_capacity` (body−header−footer with overlap guards), `check_overflow!` (`used > capacity + 0.01` → `Rendro.Error{reason: :content_overflow}`). No table-row continuation (grep-verified).
- `lib/rendro/pipeline/measure.ex:24,32,142,207,214,290,442` — `measure/2`, `measure_block/3`, `measure_table/4`, `block_width/3`, `resolve_column_widths/3`, `measure_row/6`, `body_capacity(layout)=body−header−footer`
- `lib/rendro/pipeline/measured.ex` — MeasuredBlock/Table/Row/Cell structs (`MeasuredRow{height, kind}`)
- `lib/rendro.ex:145,181,210` — `table/2`, `page_number/1` (`fn {page,total} -> [block]`, opts size/prefix/separator), `render/2` (`{:ok,binary}|{:error,Error.t()}`)
- `lib/rendro/block.ex:14` — `break_before:` public field
- `lib/rendro/region.ex` — `height` (default 0), `suppress_on` selector
- `lib/rendro/section.ex` — `content` typespec accepts `fn {page,total} -> [block]`
- `lib/rendro/page_template.ex` — default regions (footer height **0**, body height 648, US Letter)
- `lib/rendro/document.ex:12` — Document struct (`deterministic: false`, `page_size {612,792}`)
- `lib/rendro/error.ex:9` — `defexception [:stage,:reason,:message,:hint,:details]`
- `lib/rendro/adapters/accrue.ex:124-134` — `format_amount/1` Decimal precedent
- `mix.exs` / `mix.lock` / `deps/` — `:decimal` confirmed ABSENT
- `test/rendro/recipes/invoice_test.exs`, `test/rendro/pipeline/determinism_test.exs` — ExUnit idioms (`{:ok,pdf}=Rendro.render(doc)`, `pdf1==pdf2`)
- `.planning/phases/74-statement-recipe/74-CONTEXT.md`, `73-CONTEXT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`

### Secondary (MEDIUM-HIGH — authoritative registry/docs)
- `hex.pm/api/packages/decimal` — `decimal` 2.3.0 (2025-02-12), source github.com/ericmj/decimal
- `hexdocs.pm/decimal` — `Decimal.add/round/equal?/compare/negative?/abs` semantics (CITED)

### Tertiary (LOW — none load-bearing)
- General WebSearch on decimal (superseded by the Hex API fetch)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every reused module verified against current source; `decimal` verified against Hex registry
- Architecture (recipe-owned pagination, one-table-block-per-page): HIGH — paginator break/overflow logic read line-by-line; no row-continuation confirmed by grep
- D-09 helper design: HIGH on feasibility / MEDIUM on exact name — signature grounded in real `measure_row/6` inputs; name is Claude's discretion
- Pitfalls: HIGH — each tied to a verified code site (overflow threshold, footer height 0, atomic table)

**Research date:** 2026-05-29
**Valid until:** ~2026-06-28 (stable in-tree engine; only external dep `decimal` is mature/slow-moving)

## RESEARCH COMPLETE

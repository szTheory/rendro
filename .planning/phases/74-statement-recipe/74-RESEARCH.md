# Phase 74: Statement Recipe - Research

**Researched:** 2026-05-29
**Domain:** Elixir recipe-layer document assembly on the Rendro deterministic pagination engine; Decimal money arithmetic; running-balance pagination
**Confidence:** HIGH (all engine claims verified line-by-line against current source; external dep verified against Hex registry + `mix hex.info`)

> **IMPORTANT for the planner — a scout-era assumption is WRONG.** The CONTEXT.md decisions (D-01, D-10) were written assuming the engine does NOT split tables across pages, so the recipe must pre-chunk transactions into one table block per page. **That premise is false.** The engine ALREADY splits a single `Rendro.Table` row-by-row across pages (`Rendro.Fragmentable` impl for `Rendro.Table`, default `split_policy: :row_atomic`, `repeat_header: true`), and this is already test-covered. This does not invalidate the *spirit* of D-01 (recipe owns the running-balance math and the carried/brought-forward rows — the engine genuinely cannot compute those), but it materially changes the recommended pagination mechanism. See **Open Question 1** and the **Recipe-Owned Pagination** pattern below for the reconciliation. This is the single most important finding in this document.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (D-01..D-11 — do NOT relitigate the *intent*; D-01/D-10 *mechanism* needs the reconciliation below)

- **D-01 — Recipe OWNS pagination of the transaction table.** Recipe computes `body_capacity`, folds the running balance, splits transactions into per-page groups, emits body blocks with `break_before: true`. Engine stays single-pass/behaviorally unchanged. **Rejected:** post-pagination injection seam (zero visibility into per-page body content). *(Mechanism reconciliation required — see Open Q1: the engine auto-splits tables, so the recipe does NOT have to emit one block per page to paginate; it must still own balance math + carried/brought-forward rows.)*
- **D-02 — Carried-forward / brought-forward are REAL BODY ROWS, not running-region content.** Carried-forward = last body row of each non-final page; brought-forward = first body row of each subsequent page. Suppress carried-forward on last page, brought-forward on first page.
- **D-03 — Footer running region carries ONLY "Page X of Y"** via `Rendro.page_number/1` / `fn {page, total}`, mirroring `Invoice.footer_section/1`. Keeps footer reserved height a pure function of geometry.
- **D-04 [RECONCILED] — Monetary amounts and balances are `Decimal`.** Add `:decimal` to `mix.exs` core deps; validate amounts are `Decimal` (reject `Float`) with an instructive error.
- **D-05 [RECONCILED] — Each transaction line carries a SIGNED `Decimal` `amount`** (positive increases balance, negative decreases). Render signed "Amount" column + running "Balance" column.
- **D-06 — Caller does NOT supply per-line or running balances; the recipe computes them.** `opening_balance + Σ amount` fold. `closing_balance`/`summary` are optional caller assertions the recipe derives when absent; caller-supplied per-line `:balance` is rejected.
- **D-07 — Bare atom-keyed map, consistent with `Invoice`.** Required keys: `period`, `account`, `opening_balance`, `lines`. Per-line: `%{date: Date.t(), description: String.t(), amount: Decimal.t()}`. `document(data, opts \\ [])`; `opts` forwards to `page_template/1` and carries `:formatters`/`:labels`.
- **D-08 — Validation is "errors-as-product" via `validate_data!/1` that raises** with what/where/why/next, mirroring `BrandedInvoice.validate_data!/1`. No NimbleOptions. Raise for malformed call; `{:ok|:error}` `Rendro.Error` contract stays at `Rendro.render/1`.
- **D-09 — Expose a thin read-only PUBLIC measurement helper AND have the recipe reserve conservative capacity.** *(Still valuable — see Open Q1. Even under engine auto-split, the recipe needs row heights to know WHERE pages break so it can place carried/brought-forward rows correctly.)*
- **D-10 [page-grouping invariant]:** Structure each page's rows as `[brought_forward?, ...txns, carried_forward?]` with `break_before: true` on the first block of every page after page 1. Never set `keep_together` on a group larger than `body_capacity`. Invariant test: page count matches `ceil`, first/last rows carry right labels. *(Mechanism reconciliation — see Open Q1.)*
- **D-11 — Pure `Rendro.Format` default + `:formatters` / `:labels` escape hatch.** `$1,234.50`, parentheses for negatives, ISO `YYYY-MM-DD` dates; labels "Balance"/"Brought forward"/"Carried forward"/"Opening balance"/"Closing balance". No CLDR/gettext in core. Default formatter MUST accept `Decimal`. Applied to BOTH caller amounts AND recipe-computed balances.

### Claude's Discretion
- Exact module layout of `Rendro.Recipes.Statement`; `Rendro.Format` internals; precise `validate_data!/1` wording.
- Exact public signature/name/placement of the D-09 measurement helper.
- `period` shape (`Date.range/2` vs `%{from:, to:}`).
- `summary` totals shape.

### Deferred Ideas (OUT OF SCOPE)
- Conventional Debit/Credit display columns (future `:columns` option).
- Currency/locale-aware formatting in core (`:formatters` closure is the i18n path).
- Aligning existing `Invoice`/`BrandedInvoice` recipes onto `Rendro.Format`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STMT-01 | Generate statement from a data map via `Rendro.Recipes.Statement.document/2` | Three-rung skeleton verified in `invoice.ex`; `validate_data!/1` idiom verified in `branded_invoice.ex:195`; `:decimal` present transitively but must be declared as a core dep (D-04) |
| STMT-02 | Paginates across pages with carried/brought-forward balance computed in `sections/2`, deterministic across breaks | **Engine auto-splits tables** (`fragmentable.ex:107` Table impl, `split_policy: :row_atomic`, `repeat_header: true`) — VERIFIED + test-covered (`paginate_test.exs:73`). Recipe owns Decimal fold + carried/brought-forward row injection. |
| STMT-03 | Three-rung escape hatch consistent with `Invoice` | `document/2`→`page_template/1`→`sections/2` read verbatim from `invoice.ex:51-105`; Document builder chain confirmed |
| STMT-04 | "Page X of Y" via the PAGE primitive | `Rendro.page_number/1` (`rendro.ex:210`) returns a `%Block{}` wrapping `%Text{content: "Page {{page_number}} of {{total_pages}}"}`; substituted per-page single-pass in `replace_page_numbers/3` (`paginate.ex:426`) — VERIFIED |
</phase_requirements>

## Summary

This is a **recipe-layer phase plus one small read-only engine addition**. The three-rung pattern (`document/2`/`page_template/1`/`sections/2`) is mechanical to mirror from `Rendro.Recipes.Invoice`. The PAGE footer wiring is small: a footer section containing `Rendro.page_number()` plus a **non-zero footer region height** in the recipe's `page_template/1` (the default footer height is `0`, which reserves no space — `page_template.ex:44`).

The decisive engine fact, verified line-by-line: **the engine already paginates a single transaction table across pages, row by row, repeating the header.** `Rendro.Table` defaults to `split_policy: :row_atomic` and `repeat_header: true` (`table.ex:11-12`); `paginate_block/5` (`paginate.ex:144`) places a table block whole if it fits, otherwise calls `Rendro.Fragmentable.split/2`, whose `Rendro.Table` impl (`fragmentable.ex:107`) packs as many whole rows as fit into the available height, carries the rest to the next page, and re-measures downstream. `:content_overflow` is only raised when a *single row* cannot fit a whole empty page (`paginate.ex:196-209`). `break_before: true` on a block forces a page break when the current page is non-empty (`maybe_break_before`, `paginate.ex:321`). All of this is already test-covered (`paginate_test.exs:73` "table spanning multiple pages splits", `:108` repeat_header, `:115` break_before).

This reframes the recipe's job. The recipe genuinely OWNS what the engine cannot compute: (a) the **Decimal running-balance fold** (D-05/D-06), and (b) the **carried-forward / brought-forward rows** (D-02), because those depend on *which rows land on which page* — knowledge the post-pagination running-region seam does not have (the D-01 rejection of that seam stands). The open design question (Open Q1) is whether the recipe lets the engine auto-split a single table (simplest; but then the recipe cannot inject per-page carried/brought-forward rows without knowing the engine's break points), or pre-chunks into one table block per page (D-10's literal approach; gives the recipe full control of carried/brought-forward placement; needs the D-09 measurement helper to chunk by the engine's own row heights). **Recommendation: pre-chunk per page (D-10's intent), using the D-09 helper** — it is the only approach that makes per-page carried/brought-forward rows correct and the `ceil` page-count invariant testable. The engine's auto-split then becomes a *safety net* (each pre-chunked block is ≤ capacity, so it won't re-split).

**Primary recommendation:** Add `{:decimal, "~> 2.3"}` to core deps (note the version conflict in Open Q2 — `~> 2.3` is required for compatibility with the already-locked 2.3.0; `~> 3.1` is the newest line but would force a lockfile bump). Build `Rendro.Recipes.Statement` mirroring `Invoice`, plus a private Decimal balance-folder and a per-page row-chunker that uses a new read-only `Rendro.measure_rows/3`. Add a pure `Rendro.Format`. Give the Statement footer region a non-zero height.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Statement data validation | Recipe (`validate_data!/1`) | — | Errors-as-product at recipe boundary; mirrors `BrandedInvoice` |
| Running-balance fold | Recipe (`sections/2`) | — | D-01/D-06: engine is stateless/single-pass; balance is pure data math |
| Row→page assignment | **Engine** (auto-split) OR Recipe (pre-chunk) | the other as safety net | Engine CAN split tables; recipe pre-chunks only to control carried/brought-forward placement (Open Q1) |
| Per-row height measurement | Engine (read-only projection, D-09) | Recipe (consumes) | Recipe must use engine's own metrics to know break points / avoid overflow drift |
| Carried/brought-forward rows | Recipe (real body rows) | — | D-02: running-region fn cannot see per-page body content |
| "Page X of Y" footer | Engine PAGE primitive (`page_number/1`) | Recipe (wires into footer section + sets footer height) | D-03/STMT-04: per-page token substitution already shipped (Phase 73) |
| Money/date formatting | Recipe (`Rendro.Format`, pure) | Caller (`:formatters` override) | D-11: no CLDR/locale in core |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `decimal` | `~> 2.3` (see Open Q2) | Exact decimal money arithmetic | Canonical Elixir money idiom (Ecto `:decimal`, `ex_money`); zero runtime transitive deps. `[VERIFIED: hex.pm + mix.lock]` |

### Supporting (already in tree — reuse, do not add)
| Module | Purpose | Provenance |
|--------|---------|------------|
| `Rendro.Recipes.Invoice` | Three-rung reference skeleton | `[VERIFIED: invoice.ex:51-149]` |
| `Rendro.Recipes.BrandedInvoice.validate_data!/1` | Raise-with-guidance validation idiom | `[VERIFIED: branded_invoice.ex:195-214]` |
| `Rendro.page_number/1` | PAGE footer helper → `%Block{}` with `{{page_number}}`/`{{total_pages}}` text | `[VERIFIED: rendro.ex:209-214]` |
| `Rendro.Block` `break_before:` | Force per-page break (honored) | `[VERIFIED: block.ex:14, paginate.ex:321]` |
| `Rendro.Table` (`split_policy: :row_atomic`, `repeat_header: true`) | Auto-splitting table primitive | `[VERIFIED: table.ex:11-12, fragmentable.ex:107]` |
| `Rendro.table/2`, `Rendro.section/1`, `Rendro.block/2`, `Rendro.text/2` | Builder primitives | `[VERIFIED: rendro.ex:289,205,217,222]` |
| `Rendro.Error` (`from_stage/3`) | Structured pipeline error | `[VERIFIED: error.ex:9,29]` — see Pitfall 6 (NOT a `defexception`) |
| `Rendro.Adapters.Accrue.format_amount/1` | Existing amount-formatting precedent | `[VERIFIED: accrue.ex (private)]` |

### Alternatives Considered (rejected upstream in CONTEXT — do not re-explore)
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Decimal` | integer cents | Rejected D-04 |
| Signed amount | `type: :debit/:credit` | Rejected D-05 |
| Recipe balance math | post-pagination seam | Rejected D-01 (seam has zero per-page body visibility — VERIFIED: `replace_page_numbers/3` only rewrites text tokens, `paginate.ex:426`) |
| `Rendro.Format` | CLDR/gettext in core | Rejected D-11 |

**Installation:**
```elixir
# mix.exs — add to deps/0 (non-optional core dep)
{:decimal, "~> 2.3"},
```

**Version verification (IMPORTANT — there is a version conflict, see Open Q2):**
- `decimal` is **already present in `mix.lock` at 2.3.0** (transitively, via dev/test/optional deps `ecto`, `jason`, `jsv` which all constrain `~> 2.0`). It is also unpacked in `deps/decimal/`. `[VERIFIED: mix.lock]`
- The **newest** `decimal` is **3.1.1 (2026-05-27)**; `mix hex.info decimal` recommends `{:decimal, "~> 3.1"}`. `[VERIFIED: mix hex.info decimal]`
- Because `ecto`/`jason` (dev/test) pin `~> 2.0`, declaring `{:decimal, "~> 3.1"}` would create a resolver conflict unless those are also bumped. **Recommend `{:decimal, "~> 2.3"}`** to match the already-resolved 2.3.0 and avoid a lockfile churn that is out of this phase's scope. Source repo: `github.com/ericmj/decimal` (José Valim / Eric Meadows-Jönsson).

## Package Legitimacy Audit

> slopcheck unavailable offline. `decimal` verified directly against Hex (`mix hex.info` + lockfile) — it is one of the most-depended-on packages in the ecosystem.

| Package | Registry | Locked | Newest | Source Repo | Verdict | Disposition |
|---------|----------|--------|--------|-------------|---------|-------------|
| `decimal` | Hex | 2.3.0 (already in mix.lock) | 3.1.1 (2026-05-27) | github.com/ericmj/decimal | Canonical; zero runtime transitive deps; already a transitive dep | Approved — declare `~> 2.3` |

**Removed (slop):** none. **Flagged suspicious:** none.

## Architecture Patterns

### System Architecture Diagram

```
caller data map (period, account, opening_balance, lines, [closing_balance], [summary], opts)
        │
        ▼
Rendro.Recipes.Statement.document(data, opts)
        │  ├─► validate_data!(data)  ── raises on bad shape / Float amount / per-line :balance
        │
        ├─► page_template(opts) ──► %PageTemplate{ header, body, footer(height: NONZERO,
        │                                          content: page_number/1) }
        │
        └─► sections(data, opts)
                ├─ header_section  (account + period + opening_balance summary)
                ├─ body_section ───────────────────────────────────────────────┐
                │    1. fold running balance (pure Decimal):                    │
                │       opening_balance + Σ amount → [{date,desc,amount,bal}]   │ deterministic
                │    2. capacity = body.h − header.h − footer.h (engine formula)│ data-assembly
                │    3. measure row heights via Rendro.measure_rows/3 (D-09)    │
                │    4. chunk into pages; inject brought_forward (rows>page1)   │
                │       + carried_forward (rows<lastpage)                       │
                │    5a. RECOMMENDED: one table block per page,                 │
                │        break_before: true after page 1 (D-10)                 │
                │    5b. ALT: single auto-splitting table (engine splits;       │
                │        but cannot inject per-page carried/brought rows)       │
                └─ footer_section: section(region: :footer,                     │
                       content: [Rendro.page_number()])  (D-03)                 │
        ▼                                                                       ▼
Rendro.render(doc) ──► build ──► compose ──► measure ──► paginate ──► render ──► validate ──► PDF
   paginate: single pass; places/auto-splits table blocks; honors break_before;
             substitutes {{page_number}}/{{total_pages}} per page (single-pass)
```

### Recommended Module Structure
```
lib/rendro/recipes/statement.ex   # document/2, page_template/1, sections/2 + private builders
lib/rendro/format.ex              # Rendro.Format — pure deterministic money/date formatting (D-11)
lib/rendro.ex                     # + Rendro.measure_rows/3 read-only helper (D-09)
lib/rendro/recipes.ex (optional)  # Rendro.Recipes base, @moduledoc false — shared helpers
                                  #   (roadmap-noted "Recipes.Base extraction" folded into P74;
                                  #    NOTE: referenced in mix.exs docs but file does NOT yet exist)
```

### Pattern 1: Three-rung escape hatch (mirror verbatim from Invoice)
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
**Critical:** default footer region height is **0** (`page_template.ex:44`), and `body_capacity` only subtracts a footer height when the footer overlaps the body band (`measure.ex:458-466` / `paginate.ex:552-560`). With height 0 nothing is reserved and the page number overlaps the last body row. The Statement `page_template/1` MUST set a non-zero footer height.
```elixir
defp footer_section(_data, opts) do
  page_number_opts = Keyword.get(opts, :page_number_opts, [])
  Rendro.section(
    name: :statement_footer,
    region: :footer,
    content: [Rendro.page_number(page_number_opts)]   # %Block{} with {{page_number}}/{{total_pages}}
  )
end

def page_template(opts \\ []) do
  defaults = [
    name: :statement,
    regions: [
      Rendro.region(name: :header, role: :header, anchor: :top,    x: 72, y: 72,  width: 451.28, height: HEADER_H),
      Rendro.region(name: :body,   role: :body,   anchor: :flow,   x: 72, y: ...,  width: 451.28, height: BODY_H),
      Rendro.region(name: :footer, role: :footer, anchor: :bottom, x: 72, y: ...,  width: 451.28, height: 24)  # NON-ZERO
    ]
  ]
  Rendro.page_template(Keyword.merge(defaults, opts))
end
```
`Rendro.page_number/1` `[VERIFIED: rendro.ex:209-214]`: `def page_number(opts \\ []), do: block(text(Keyword.get(opts,:format,"Page {{page_number}} of {{total_pages}}"), Keyword.drop(opts,[:format])))`. It returns a plain text `%Block{}` carrying the tokens — substitution happens in `replace_page_numbers/3` per page (NOT a `RunningContent` fn, though the engine ALSO supports `%Rendro.RunningContent{fun: fn {page,total} -> ... end}` via `evaluate_fn_blocks/3`, `paginate.ex:464`).

### Pattern 3 (RECOMMENDED): Recipe-owned per-page chunking for correct carried/brought-forward (D-02/D-10)
**Why pre-chunk even though the engine auto-splits:** if the recipe emits one big auto-splitting table, the *engine* decides the row→page boundaries, and the recipe has no hook to insert a "Carried forward $X" row at the bottom of each page or a "Brought forward $X" row at the top of the next. To make D-02 correct, the recipe must know the break points itself — which is exactly what the D-09 `measure_rows` helper gives it.
```elixir
defp body_section(data, opts) do
  template = page_template(opts)
  body   = Enum.find(template.regions, & &1.role == :body)
  header = Enum.find(template.regions, & &1.role == :header)
  footer = Enum.find(template.regions, & &1.role == :footer)
  capacity = body.height - region_h(header) - region_h(footer)   # engine's own formula

  rows = fold_balance(data)                                       # [{date,desc,amount,balance}] (Decimal)
  pages = chunk_pages(rows, capacity, table_opts(opts), data)     # uses Rendro.measure_rows + epsilon margin
                                                                  # injects brought_forward / carried_forward

  blocks =
    pages
    |> Enum.with_index()
    |> Enum.map(fn {page_rows, idx} ->
      tbl = Rendro.table(page_rows, header: header_cells(opts), columns: COLS)
      Rendro.block(tbl, break_before: idx > 0)                    # break_before on every page after the first
    end)

  Rendro.section(name: :statement_body, region: :body, content: blocks)
end
```
Each pre-chunked block is ≤ `capacity`, so the engine's auto-split never re-fires inside a block (no double-pagination, no stranded carried-forward row — D-10). `break_before: true` forces the next block to a fresh page (`maybe_break_before`, `paginate.ex:321`: breaks iff `hd(group).break_before and current_page.blocks != []`).

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
`Decimal.add/2` is exact and deterministic. The final accumulator is the derived `closing_balance` (validate caller's optional assertion with `Decimal.equal?/2` — Pitfall 5). `[CITED: hexdocs.pm/decimal]`

### Anti-Patterns to Avoid
- **Recipe-local row-height estimate** that diverges from `measure_row` → wrong break points → carried/brought-forward rows on the wrong page, or `:content_overflow`. Use `Rendro.measure_rows` (D-09).
- **`keep_together: true` on a per-page group** larger than `body_capacity` → `place_hard_group` raises `:content_overflow` when `group_h > max_h` (`paginate.ex:305-318`). Don't.
- **Footer region height 0** while placing page numbers → overlap.
- **Carried/brought-forward in the footer/header running region** → impossible (D-02; the `fn {page,total}` cannot see body content).
- **Packing exactly to `body_capacity`** → leave one-row epsilon (overflow comparisons use `<=`/`>` on float sums; `paginate.ex:164,358`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-row table heights | recipe-local font/wrap estimate | `Rendro.measure_rows/3` (D-09, projects `measure_block`→`measure_table`→row heights) | Must match engine or break points drift |
| Table row→page splitting (fallback) | manual split | engine `Fragmentable` Table impl (`split_policy: :row_atomic`) | Already implemented + tested |
| Repeating table headers across pages | manual header re-emit | `repeat_header: true` (default) | Already implemented |
| Page-number footer | manual `{{page}}` handling | `Rendro.page_number/1` | Single-pass substitution shipped (Phase 73) |
| Decimal arithmetic | float math | `Decimal.add/round/compare/equal?` | Exactness + determinism |
| Validation framework | NimbleOptions for nested records | `validate_data!/1` raise idiom | D-08 |

**Key insight:** The engine measures, splits tables, repeats headers, and breaks on `break_before` — all single-pass and tested. The recipe's genuinely novel work is the **Decimal fold** and the **carried/brought-forward row injection**, which require knowing break points (hence D-09).

## Common Pitfalls

### Pitfall 1: Believing the engine cannot split tables (the scout-era assumption)
**What goes wrong:** Designing the recipe to pre-chunk "because the engine treats a table as atomic."
**Reality:** The engine DOES split tables row-by-row (`fragmentable.ex:107`, `split_policy: :row_atomic` default, tested at `paginate_test.exs:73`). Pre-chunking is still the RECOMMENDED approach — but for carried/brought-forward control (D-02), not because the engine can't paginate.
**How to avoid:** Read `fragmentable.ex` and `paginate_block/handle_split` before planning the body section.

### Pitfall 2: Footer height left at 0
**Why:** `body_capacity` reserves only the *declared* overlapping footer height; default is 0 (`page_template.ex:44`). `measure.ex` returns `:no_body_capacity` only if capacity `<= 0` (`measure.ex:403`), so a 0-height footer silently overlaps rather than erroring.
**How to avoid:** Statement `page_template/1` sets a non-zero footer height.

### Pitfall 3: A single transaction row taller than a whole page
**What goes wrong:** A very long `description` wraps to more lines than fit one empty page → `handle_split` hits `{nil,_}` with `current_h == 0` and throws `:content_overflow` with `row_index: 0` (`paginate.ex:196-209`).
**How to avoid:** This is an inherent limit; document it. The epsilon margin does not help here (it's a single oversized row). Validation could optionally cap description length, but that's beyond locked scope.

### Pitfall 4: Float amounts breaking determinism
**Why:** `1.10` is not exactly representable; money in float is a correctness bug (D-04).
**How to avoid:** `validate_data!/1` rejects `Float` amounts with an instructive error.

### Pitfall 5: `Decimal` structural `==` vs `Decimal.equal?/2`
**Why:** `Decimal.new("100")` and `Decimal.new("100.00")` are structurally unequal; `==`/pattern-match fails.
**How to avoid:** Use `Decimal.equal?/2` (or `Decimal.compare/2 == :eq`) for the optional `closing_balance`/`summary` assertions (D-06).

### Pitfall 6: `Rendro.Error` is NOT a `defexception`
**What goes wrong:** Writing `raise Rendro.Error, stage: ...` — but `Rendro.Error` is a plain struct (`defstruct`, NOT `defexception`), built via `Rendro.Error.from_stage/3` (`error.ex:9,29`). It is NOT raisable directly.
**How to avoid:** For D-08 recipe-boundary validation, **`raise ArgumentError, "...instructive message..."`** (this is exactly what `BrandedInvoice.validate_data!/1` does — `branded_invoice.ex:200`). Reserve `Rendro.Error` (via `from_stage`) for the `{:ok|:error}` pipeline contract at `Rendro.render/1`, not for `validate_data!/1` raises. This corrects a common assumption — the D-08 idiom to mirror is `ArgumentError`, not `Rendro.Error`.

## Code Examples

### D-09 measurement helper — RECOMMENDED signature (read-only projection)
```elixir
# Placement: lib/rendro.ex (public Builder API surface, near table/2 at :289).
# Projects the existing private measure_block→measure_table grid measurement.
# Read-only: builds an ephemeral block, measures it, returns geometry. No paginate/render/mutate.

@doc """
Returns `{header_height, row_heights}` (points) for `rows` laid out as a
`Rendro.table/2` of total `width`, using `document`'s font metrics. Read-only —
lets recipes chunk rows by the engine's own measurement to place page breaks and
carried/brought-forward rows correctly. PAGE-04 single-pass preserved.
"""
@spec measure_rows([Rendro.Table.row()], number(), Rendro.Document.t(), keyword()) ::
        {number(), [number()]}
def measure_rows(rows, width, document, table_opts \\ []) do
  # block = %Block{content: Rendro.table(rows, table_opts), width: width}
  # {:ok, measured} = <public projection of Measure.measure_block/3>
  # {measured.content.header_height || 0, measured.content.row_heights}
end
```
**Why this signature:** `measure_block/3` for a `%Table{}` sets `block.width || container_width || 595.28` (`measure.ex:52`), resolves column widths from that width, and produces `header_height` + `row_heights` (`measure.ex:60-77`). So the minimal public surface is `(rows, width, document, table_opts)`. Returning `{header_height, row_heights}` lets the recipe cumulatively pack `header + Σ rows ≤ capacity − epsilon`, accounting for the repeated header on each page and the extra carried/brought-forward rows. The implementation needs the planner to expose a thin public wrapper over `Measure.measure_block/3` (currently `defp`) — e.g. a `Rendro.Pipeline.Measure.measure_block_public/3` shim, or move the table-measuring branch into a small public function. This is a pure read; no pagination behavior changes. `[VERIFIED: measure.ex:32,47-79]`

> **Alternative:** `Rendro.Recipes.row_capacity(template, document)` returning an integer row count. Rejected as the primitive because row heights vary (wrapped descriptions); a height list is more honest and composes with the variable extra rows. Keep `row_capacity` private inside the recipe.

### D-08 validation — raise ArgumentError (mirror BrandedInvoice)
```elixir
defp validate_data!(%{period: _, account: _, opening_balance: ob, lines: lines} = data)
     when is_list(lines) do
  validate_decimal!(ob, "opening_balance")
  Enum.each(lines, &validate_line!/1)
  reject_caller_balance!(data)      # caller-supplied per-line :balance is rejected (D-06)
  :ok
end
defp validate_data!(_),
  do: raise(ArgumentError, "Statement data requires :period, :account, :opening_balance, :lines")

defp validate_line!(%{date: %Date{}, description: d, amount: amt}) when is_binary(d),
  do: validate_decimal!(amt, "line amount")
defp validate_line!(other),
  do: raise(ArgumentError, "Each line needs %{date: Date, description: String, amount: Decimal}; got: #{inspect(other)}")

defp validate_decimal!(%Decimal{}, _label), do: :ok
defp validate_decimal!(v, label) when is_float(v),
  do: raise(ArgumentError, "#{label} #{inspect(v)} is a float; money must be a Decimal (e.g. Decimal.new(\"#{v}\")).")
defp validate_decimal!(v, label),
  do: raise(ArgumentError, "#{label} must be a Decimal, got: #{inspect(v)}")
```
`%Decimal{}` pattern compiles once `:decimal` is declared. `[VERIFIED idiom: branded_invoice.ex:195-214]`

### Rendro.Format default (D-11, deterministic, no locale)
```elixir
def money(%Decimal{} = d) do
  r = Decimal.round(d, 2)
  if Decimal.negative?(r),
    do: "($" <> (r |> Decimal.abs() |> group_thousands()) <> ")",
    else: "$" <> group_thousands(r)
end
def date(%Date{} = d), do: Date.to_iso8601(d)   # YYYY-MM-DD, locale-independent
```

## Runtime State Inventory

Not applicable — Phase 74 is greenfield recipe code + one additive public function + one dep declaration. No rename/refactor/migration.

- **Stored data:** None.
- **Live service config:** None.
- **OS-registered state:** None.
- **Secrets/env vars:** None.
- **Build artifacts:** `:decimal` is already compiled in `deps/decimal/`; declaring it as a core dep needs only `mix deps.get` (no migration). `[VERIFIED: deps/decimal/ present]`

## State of the Art

| Old Approach | Current Approach | When | Impact |
|--------------|------------------|------|--------|
| `{{page_number}}` token only | `fn {page,total}` primitive + `page_number/1` sugar | Phase 73 | Statement uses `page_number/1` directly (D-03) |
| `body_capacity = body_h` (footer ignored) | `body_h − header_h − footer_h` w/ overlap guards | Phase 73 (73-02) | Statement footer height now reserves space |
| Invoice `"$#{price}"` | `Rendro.Format` pure deterministic | Phase 74 | Statement formats Decimal; Invoice cleanup deferred |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Rendro.measure_rows/3` name/placement for D-09 | Code Examples | Low — name is Claude's-discretion; signature grounded in real `measure_block/3` inputs |
| A2 | A ~24pt footer height fits one line of page-number text at default size | Pattern 2 | Low — magnitude tunable; the *requirement* (height > 0) is verified |
| A3 | `Decimal` `==` is structural; use `Decimal.equal?` | Pitfall 5 | Low — standard Decimal behavior `[CITED]` |
| A4 | Exposing a public wrapper over `Measure.measure_block/3` stays behavior-neutral | D-09 helper | Low-Med — it's a read; planner must ensure the shim doesn't alter the private fn |
| A5 | `{:decimal, "~> 2.3"}` resolves cleanly against the locked 2.3.0 | Standard Stack / Open Q2 | Low — 2.3.0 is already locked; `~> 2.3` is satisfied |

## Open Questions

1. **(LOAD-BEARING) Single auto-splitting table vs. recipe pre-chunked per-page blocks.** The engine auto-splits tables (`fragmentable.ex:107`), so a single table block paginates "for free." BUT D-02's carried/brought-forward rows require the recipe to know break points to inject per-page rows. **Recommendation: pre-chunk per page** (D-10's literal structure), using `Rendro.measure_rows/3` (D-09) to chunk by the engine's own row heights, with `break_before: true` after page 1. The engine's auto-split then only acts as a safety net. This is the only approach that makes per-page carried/brought-forward correct and the `ceil` page-count invariant testable. The planner should confirm and lock this mechanism (it honors D-01's intent — recipe owns the breaks — while acknowledging the engine's real capability).

2. **`decimal` version: `~> 2.3` vs `~> 3.1`.** Locked transitively at 2.3.0 (via `ecto`/`jason` `~> 2.0`); newest is 3.1.1; `mix hex.info` suggests `~> 3.1`. **Recommend `~> 2.3`** to avoid forcing a resolver bump of dev/test deps (out of scope). Planner decides; if `~> 3.1` is wanted, it requires checking `ecto`/`jason`/`jsv` compatibility and a lockfile update.

3. **`period` shape** — Claude's discretion. **Recommend `%{from: Date.t(), to: Date.t()}`** (explicit, easy to validate + format per-endpoint) over `Date.range/2`. Guard in `validate_data!/1`.

4. **`summary` totals shape** — Claude's discretion. **Recommend deriving `%{total_debits:, total_credits:, line_count:, closing_balance:}`** when absent; validate any caller-supplied values with `Decimal.equal?/2`.

5. **Recipes base extraction.** `Rendro.Recipes` is referenced in `mix.exs` `groups_for_modules` but **the file does not exist** (only `invoice.ex` + `branded_invoice.ex` in `lib/rendro/recipes/`). STATE.md folds `Rendro.Recipes.Base` into Phase 74. Planner decides whether to create `lib/rendro/recipes.ex` (`@moduledoc false`) now for shared helpers (fold, chunk, format dispatch) or keep them private to `Statement`. Low risk either way.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `decimal` (Hex) | money arithmetic (D-04) | ✓ (transitively; declare as core dep) | 2.3.0 locked | none needed |
| Elixir / mix | all | ✓ | `~> 1.19` | — |
| Rendro engine | recipe consumes | ✓ | in-tree | — |

**Missing with no fallback:** none. **Note:** `decimal` present but undeclared as a direct dep — declaring it is the D-04 action item, not a blocker.

## Validation Architecture

> nyquist_validation is enabled (`config.json` → `workflow.nyquist_validation: true`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (`use ExUnit.Case, async: true`) `[VERIFIED: test/rendro/recipes/invoice_test.exs:2]` |
| Config file | none beyond `test/test_helper.exs` (standard mix) |
| Quick run command | `mix test test/rendro/recipes/statement_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STMT-01 | `document/2` returns a renderable `%Document{}`; `Rendro.render/1` → `{:ok, pdf}` | unit | `mix test test/rendro/recipes/statement_test.exs` | ❌ Wave 0 |
| STMT-01 | `validate_data!/1` raises `ArgumentError` on missing keys / non-Decimal / Float / per-line `:balance` / malformed period | unit | same | ❌ Wave 0 |
| STMT-02 | Multi-page page count == `ceil(rows / rows_per_page)` (D-10 invariant) | unit | same | ❌ Wave 0 |
| STMT-02 | Carried-forward is last row of each non-final page; suppressed on last page | unit | same | ❌ Wave 0 |
| STMT-02 | Brought-forward is first row of each page after page 1; suppressed on page 1 | unit | same | ❌ Wave 0 |
| STMT-02 | Running balance continuous across breaks (brought-fwd[N+1] == carried-fwd[N] == folded balance) | unit | same | ❌ Wave 0 |
| STMT-02 | No `:content_overflow` for a realistic large statement (epsilon margin) | unit | same | ❌ Wave 0 |
| STMT-03 | `page_template/1` + `sections/2` callable independently; region names/roles consistent with Invoice | unit | same | ❌ Wave 0 |
| STMT-04 | "Page X of Y" correct on every page incl. last (total == real page count) | unit | assert on paginated pages' footer-region text | ❌ Wave 0 |
| STMT-04 | Footer region non-zero height; body does not overlap footer | unit | same | ❌ Wave 0 |
| STMT-02 | Determinism: render twice with `deterministic: true` → `pdf1 == pdf2` | unit | mirror `test/rendro/deterministic_test.exs` | ❌ Wave 0 |
| (helper) | `Rendro.measure_rows/3` returns header+row heights matching engine; read-only | unit | `mix test test/rendro/measure_rows_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/recipes/statement_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** full suite green + `mix ci` (format / compile-warnings-as-errors / credo --strict / dialyzer) before `/gsd-verify-work` `[VERIFIED: mix.exs ci alias]`

### Wave 0 Gaps
- [ ] `test/rendro/recipes/statement_test.exs` — STMT-01..04 + determinism
- [ ] `test/rendro/measure_rows_test.exs` — D-09 helper (read-only, heights match `measure.ex`)
- [ ] (optional) `statement_fixture/1` building a known multi-page data map so `ceil` page-count + balance-continuity assertions are exact

*Framework already present (ExUnit); no install needed.*

## Security Domain

> `security_enforcement` not set in `config.json`. Phase is pure local document assembly: no auth, no network, no persistence, no user-supplied executable content. Minimal ASVS surface.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a |
| V5 Input Validation | yes | `validate_data!/1` rejects malformed data / Float amounts (D-08) |
| V6 Cryptography | no | n/a |

### Known Threat Patterns
| Pattern | STRIDE | Mitigation |
|---------|--------|------------|
| Caller text in descriptions reaching PDF text stream | Tampering/Injection | Text shaping treats content as literal glyphs; only curated running-region tokens substitute (`replace_page_numbers/3` rewrites `{{page_number}}`/`{{total_pages}}` only) — no arbitrary substitution surface |
| Float corruption of financial totals | Tampering | Decimal-only + `validate_data!/1` reject Float (D-04/D-08) |
| Non-deterministic output undermining audit | Repudiation | Deterministic Decimal fold + locale-free `Rendro.Format`; byte-identical determinism test |

## Sources

### Primary (HIGH — verified line-by-line against current source this session)
- `lib/rendro/recipes/invoice.ex:51-149` — three-rung skeleton + Document builder chain + private `*_section/1`
- `lib/rendro/recipes/branded_invoice.ex:48-214` — `validate_data!/1` raises `ArgumentError`; non-default `page_template` with explicit region heights
- `lib/rendro/fragmentable.ex:107-140` — **Table `Fragmentable.split/2`: row-by-row split, keeps whole rows that fit, carries rest** (the key correction)
- `lib/rendro/table.ex:11-12` — `split_policy: :row_atomic`, `repeat_header: true` defaults
- `lib/rendro/pipeline/paginate.ex:144-248` (`paginate_block`/`handle_split`: place-whole-or-`Fragmentable.split`; single-row overflow at `:196-209`), `:321` (`maybe_break_before`), `:305-318` (`place_hard_group` keep-rule overflow), `:426-462` (`replace_page_numbers/3` token substitution), `:464-489` (`evaluate_fn_blocks` RunningContent), `:552-565`/`:442-469` (`body_capacity` overlap-aware)
- `lib/rendro/pipeline/measure.ex:32,47-79` (`measure_block/3` Table branch → `header_height`+`row_heights`), `:403` (`:no_body_capacity` if capacity ≤ 0), `:442-469` (`body_capacity`)
- `lib/rendro.ex:209-214` (`page_number/1`), `:289` (`table/2`), `:205/217/222` (`section`/`block`/`text`), `:43` (`render/2`)
- `lib/rendro/block.ex:14` (`break_before`), `lib/rendro/region.ex` (`height` nilable), `lib/rendro/section.ex` (`content: [Block | RunningContent]`, `suppress_on`), `lib/rendro/page_template.ex:20-44` (default footer height **0**, body 697.89, A4 595.28×841.89)
- `lib/rendro/error.ex:9,29` — `Rendro.Error` is `defstruct` (NOT `defexception`); built via `from_stage/3`
- `mix.exs` — `:decimal` absent from deps/0; `ci` alias; `Rendro.Recipes` in docs but no file
- `mix.lock` — `decimal 2.3.0` locked (via `ecto`/`jason`/`jsv` `~> 2.0`)
- `test/rendro/recipes/invoice_test.exs`, `test/rendro/pipeline/paginate_test.exs:60-130` (table-split, repeat_header, break_before, footer page-number coverage), `test/rendro/deterministic_test.exs` (`pdf1 == pdf2` idiom)
- `.planning/` 74-CONTEXT, 73-CONTEXT, REQUIREMENTS, ROADMAP, STATE; `AGENTS.md` (conventions: pure core, no hard Phoenix/Oban dep, docs-as-contract)

### Secondary (HIGH — authoritative registry)
- `mix hex.info decimal` → newest 3.1.1 (2026-05-27), 3.1.0 (2026-05-08); locked 2.3.0; recommends `~> 3.1`
- `hexdocs.pm/decimal` — `Decimal.add/round/equal?/compare/negative?/abs` (CITED)

## Metadata

**Confidence breakdown:**
- Standard stack / dep: HIGH — verified against lockfile + `mix hex.info`; version conflict surfaced honestly
- Engine pagination reality (table auto-split, break_before, body_capacity): HIGH — read line-by-line + cross-checked against existing tests
- D-09 helper design: HIGH feasibility / MEDIUM exact name+shim placement
- D-08 idiom (ArgumentError, not Rendro.Error): HIGH — `Rendro.Error` confirmed not a `defexception`
- Pitfalls: HIGH — each tied to a verified code site

**Research date:** 2026-05-29
**Valid until:** ~2026-06-28 (stable in-tree engine; `decimal` mature)

## RESEARCH COMPLETE

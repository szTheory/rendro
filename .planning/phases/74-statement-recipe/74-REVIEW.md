---
phase: 74-statement-recipe
reviewed: 2026-05-29T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - lib/rendro.ex
  - lib/rendro/format.ex
  - lib/rendro/pipeline/measure.ex
  - lib/rendro/recipes/statement.ex
  - mix.exs
  - test/rendro/format_test.exs
  - test/rendro/measure_rows_test.exs
  - test/rendro/recipes/statement_test.exs
findings:
  critical: 1
  warning: 6
  info: 3
  total: 10
status: issues_found
---

# Phase 74: Code Review Report

**Reviewed:** 2026-05-29T00:00:00Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the Statement recipe (`Rendro.Recipes.Statement`), the new `Rendro.Format`
deterministic formatter, the `Rendro.measure_rows/4` projection (in `Rendro` and
`Rendro.Pipeline.Measure`), and their tests. All 67 tests + 8 doctests pass and the
code compiles cleanly under `--warnings-as-errors`.

However, the passing tests mask several real defects, because key test constants
(`rows_per_page/0` in `statement_test.exs`) re-derive the *same* capacity formula the
production code uses, so they cannot detect a wrong formula. Adversarial probing
surfaced:

- A **descending-range bug** in the shared grid builder (`0..-1`) reachable through the
  new public `Rendro.measure_rows/4` API, producing a spurious column index and a
  runtime deprecation warning.
- A **documentation/behavior contract violation**: the moduledoc and the
  `validate_data!/1` comment both promise the top-level `:closing_balance` is "derived
  and validated via `Decimal.equal?/2`", but only its *type* is checked — a wrong
  closing balance is silently accepted.
- A **capacity miscalculation** in the recipe that over-paginates (35 rows/page where the
  engine could fit 38) and whose justifying comment is factually wrong about the engine's
  overlap logic.
- An **unvalidated `:account` shape** that crashes with `BadMapError` instead of the
  promised instructive `ArgumentError`.

No structural-findings substrate was supplied with this review.

## Critical Issues

### CR-01: Descending range `0..(col_count - 1)` corrupts grid layout for zero-column tables

**File:** `lib/rendro/pipeline/measure.ex:284-289`
**Issue:** In `do_build_grid/4`, the grid-layout comprehension builds inner columns with
`for c <- 0..(col_count - 1)`. When `col_count` is `0` (rows present but every row has
zero cells, and no header/columns supplied), this becomes `0..-1`, which in current
Elixir is a **descending range** yielding `[0, -1]` — not an empty range. This:

1. Emits a runtime deprecation warning (`Range.new/2 ... default to a step of -1`), and
2. Builds a grid row containing a bogus `c = -1` entry, i.e. `Map.get(grid_map, {r, -1}, ...)`.

Reproduced directly via the new public API:

```elixir
Rendro.Pipeline.Measure.measure_rows(doc, [[], []], 400, [])
# => emits "Range.new/2 ... step of -1" warning at measure.ex:286
# => {:ok, {0, [0, 0]}} but _grid_layout contains spurious {r, -1} cells
```

This is reachable through `Rendro.measure_rows/4`, which is a documented public builder
(`lib/rendro.ex:319`). A malformed/empty-cell input silently produces a corrupted
`_grid_layout` and a deprecation warning that will become a hard error in a future Elixir.

**Fix:** Guard the range with the explicit-empty form so a zero count yields an empty list:

```elixir
grid_layout =
  for r <- 0..(length(rows) - 1)//1 do
    for c <- 0..(col_count - 1)//1 do
      Map.get(grid_map, {r, c}, %{is_continuation: false, cell: nil})
    end
  end
```

`0..-1//1` correctly produces `[]`. Alternatively short-circuit when `col_count == 0`
(return `{:ok, {measured_rows, row_heights, []}}`). Note the `r` range at line 285 is
safe today only because `project_and_measure_grid/3` short-circuits empty `rows`; apply
the `//1` step there too for defense-in-depth.

## Warnings

### WR-01: Top-level `:closing_balance` is type-checked but never validated against the derived balance

**File:** `lib/rendro/recipes/statement.ex:679-701` (and moduledoc lines 32-33; comment line 481)
**Issue:** The moduledoc states `:closing_balance` is "caller assertion; derived and
**validated** via `Decimal.equal?/2` when present", and the `validate_data!/1` comment
(line 481) lists "Optional `:closing_balance` not a `%Decimal{}` when present" but the
implementation (`maybe_validate_closing_balance!/1`) only checks the *type*. A caller who
supplies a wrong closing balance has it silently ignored:

```elixir
Statement.document(%{
  period: %{from: ~D[2026-05-01], to: ~D[2026-05-31]},
  account: %{name: "Acme"},
  opening_balance: Decimal.new("1000.00"),
  closing_balance: Decimal.new("99999.99"),  # wrong; derived is 1000.00
  lines: []
})
# => no raise; the bogus assertion is accepted
```

This is the exact "masking correctness bugs" failure the recipe explicitly guards against
for per-line `:balance` (line 599). The `:summary.closing_balance` path *is* validated
(line 713-724), making the top-level omission an inconsistency, not a deliberate choice.

**Fix:** After the type check, derive the closing balance and compare, mirroring
`maybe_validate_summary!/1`:

```elixir
defp maybe_validate_closing_balance!(%{closing_balance: %Decimal{} = cb, opening_balance: ob, lines: lines}) do
  derived = Enum.reduce(lines, ob, fn %{amount: a}, acc -> Decimal.add(acc, a) end)
  unless Decimal.equal?(cb, derived) do
    raise ArgumentError, "..."  # instructive mismatch message
  end
  :ok
end
```

(Order matters: this must run after `validate_lines!/1` so amounts are known-Decimal.)

### WR-02: Recipe over-paginates — `capacity` double-subtracts header/footer and the justifying comment is wrong

**File:** `lib/rendro/recipes/statement.ex:293-297`
**Issue:** `@body_height` (line 102) is already `@page_height - 2*@margin - @header_height - @footer_height` = `625.89`. Line 297 then computes:

```elixir
capacity = @body_height - @header_height - @footer_height   # => 553.89
```

subtracting header and footer a **second** time. The comment (lines 293-296) claims this
"mirrors measure.ex `body_capacity/1`" and that "header and footer are always adjacent to
body, so the full subtraction applies." That reasoning is factually wrong: tracing the
engine's `body_capacity/1` (`measure.ex:473-500`) against the statement template, the
header region does **not** overlap the body (`body_y < header.y + header.height` is
`120 < 120` = false), so the engine subtracts only the footer, yielding `601.89`, not
`553.89`. Net effect: the recipe packs **35 rows/page where the engine could fit 38**
(~8% more pages than necessary).

This is conservative (it under-packs, so it does not cause `:content_overflow`), hence a
WARNING rather than a BLOCKER — but it wastes a header-height's worth of capacity per page
and ships an incorrect rationale comment. The tests do not catch it because
`statement_test.exs:rows_per_page/0` (lines 69-72) re-derives the identical wrong formula.

**Fix:** Use the engine's actual body-region height as the base (it already nets out
header/footer once) and subtract only what the engine subtracts. At minimum:

```elixir
# @body_height is the body REGION height the engine starts from; the engine
# subtracts only the footer for this template (header does not overlap body).
capacity = @body_height - @footer_height
```

Better: query the engine's `body_capacity` rather than re-deriving a parallel formula, and
add a test asserting the recipe's `capacity` equals the engine's computed `body_capacity`
for the statement template so the two can never drift again.

### WR-03: `:account` shape is unvalidated — non-map crashes with `BadMapError` instead of instructive `ArgumentError`

**File:** `lib/rendro/recipes/statement.ex:505-523, 250-257`
**Issue:** `validate_required_keys!/1` only checks key *presence*. `:account` is never
validated for shape. `header_section/2` then calls `Map.get(account, :name, "")`
(line 257), so a non-map `:account` raises `BadMapError` deep in section construction:

```elixir
Statement.document(%{period: ..., account: "Acme", opening_balance: Decimal.new("1000.00"), lines: []})
# => ** (BadMapError) expected a map, got: "Acme"
```

This violates the recipe's stated "errors-as-product" contract (comment line 469) — every
other malformed field produces a structured, instructive `ArgumentError`; `:account` alone
produces an opaque crash from the standard library.

**Fix:** Add a `validate_account!/1` clause invoked from `validate_data!/1`:

```elixir
defp validate_account!(%{name: name}) when is_binary(name), do: :ok
defp validate_account!(value) do
  raise ArgumentError, """
  ... :account must be a map with a string :name. Received: #{inspect(value)} ...
  """
end
```

### WR-04: `:summary` validation only checks `:closing_balance`, ignoring the documented `total_debits`/`total_credits`/`line_count`

**File:** `lib/rendro/recipes/statement.ex:703-727` (contract lines 34-36)
**Issue:** The data contract documents `:summary` as
`%{total_debits, total_credits, line_count, closing_balance}` and calls it a "caller
assertion". But `maybe_validate_summary!/1` validates *only* `summary.closing_balance`
(and only when that key is present). A caller-supplied `total_debits`, `total_credits`, or
`line_count` that disagrees with the actual data is silently ignored — the same
assertion-masking-bug hazard the recipe elsewhere takes pains to reject. Either the
fields are load-bearing assertions (then validate them) or they are not (then do not
document them as such).

**Fix:** Validate each present summary field against its derived value (sum of positive
amounts → `total_debits`/`total_credits` per sign convention, `length(lines)` →
`line_count`), or narrow the moduledoc to state explicitly that only `:closing_balance`
is checked and the other summary fields are advisory/unvalidated.

### WR-05: Extra/overflow cells beyond `col_count` are appended unmeasured and never advance the column cursor

**File:** `lib/rendro/pipeline/measure.ex:301-306, 367-377`
**Issue:** In `fill_row_cells/6`, when `find_next_empty_col/4` returns `next_c >= col_count`
(a row has more cells than there are columns), the cell is appended to `m_cells` **raw and
unmeasured** (no `width`/`height`/`x`/`y`) and `next_c` is left unchanged, so every
subsequent overflow cell in that row hits the same branch. Probed via the new public API:

```elixir
Rendro.Pipeline.Measure.measure_rows(doc, [["A","B","C"]], 400, [header: ["H"], columns: [{:fixed, 100}]])
# col_count == 1; cells "B" and "C" are dropped/unmeasured into the grid
```

The returned `row_heights` silently ignore the overflow cells' content. For the Statement
recipe this is latent (it always supplies 4 matching columns), but `measure_rows/4` is a
public builder and the silent drop can produce wrong geometry without any error. There is
no validation or diagnostic that the row is wider than the table.

**Fix:** Either return `{:error, {:row_wider_than_columns, ...}}` when `next_c >= col_count`,
or clamp/measure the overflow explicitly. At minimum do not append an unmeasured cell that
downstream rendering will treat as measured.

### WR-06: `measure_rows/4` raising `ArgumentError` propagates out of `Statement.document/2`, turning recoverable input into a crash

**File:** `lib/rendro.ex:319-331`, `lib/rendro/recipes/statement.ex:290-291`
**Issue:** `Rendro.measure_rows/4` raises `ArgumentError` on any measurement failure (e.g.
a `:description` containing an unsupported glyph). The recipe calls it from
`body_section/2` (line 290) after `validate_data!/1` has already passed — so a description
string with an unsupported script crashes `document/2` with a measurement-internal
`ArgumentError` (`"could not measure the table: {:unsupported_script, ...}"`) rather than
the instructive, field-scoped error the recipe's validation layer produces for every other
bad input. The error message also leaks engine internals (`inspect(reason)`).

**Fix:** Either validate `:description` against the resolvable font chain during
`validate_data!/1` (preferred, consistent with errors-as-product), or catch the
measurement failure in `body_section/2` and re-raise a recipe-scoped, field-indexed
`ArgumentError` that names the offending line.

## Info

### IN-01: Comment claims "median/mean or conservative max" but code uses plain mean

**File:** `lib/rendro/recipes/statement.ex:376-383`
**Issue:** The comment for `typical_row_h` says "Use the median/mean or a conservative max
to reserve space," but the code computes only the arithmetic mean
(`Enum.sum/length`). For wildly varying row heights the mean under-reserves relative to a
max. Not a correctness bug for the uniform recipe rows, but the comment is misleading.
**Fix:** Update the comment to state "arithmetic mean", or switch to
`Enum.max(row_heights)` if a conservative reservation was the intent.

### IN-02: Magic-number fallback row height `14.4`

**File:** `lib/rendro/recipes/statement.ex:380`
**Issue:** The empty-`row_heights` fallback `14.4` is an unexplained literal (it happens to
equal `12 * 1.2`, the default size × line_height). Extract a named module attribute, e.g.
`@default_row_height 14.4`, with a comment deriving it, so it stays in sync with the
default text metrics.

### IN-03: Dead computation in `maybe_validate_summary!/1`

**File:** `lib/rendro/recipes/statement.ex:705-711`
**Issue:** `maybe_validate_summary!/1` builds a `rows` list via `Enum.map_reduce/3` then
discards it with `_ = rows` — only `derived_closing` is used. The `Enum.map_reduce` should
be `Enum.reduce/3` to drop the unused accumulated list:

```elixir
derived_closing =
  Enum.reduce(lines, ob, fn %{amount: amt}, bal -> Decimal.add(bal, amt) end)
```

This also makes the function identical in shape to the `fold_balance/2` it duplicates;
consider extracting a single private `derive_closing/2` used by both `fold_balance/2` and
the two validators (also relevant to WR-01).

---

_Reviewed: 2026-05-29T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

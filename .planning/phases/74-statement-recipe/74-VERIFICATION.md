---
phase: 74-statement-recipe
verified: 2026-05-29T17:00:00Z
status: passed
score: 4/4 roadmap success criteria verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/4 (2 blockers in anti-patterns)
  gaps_closed:
    - "CR-01: do_build_grid/4 comprehension ranges now pinned to //1 — descending-range deprecation eliminated"
    - "WR-01: maybe_validate_closing_balance!/1 now derives closing balance and compares via Decimal.equal?/2 — moduledoc contract fulfilled"
  gaps_remaining: []
  regressions: []
---

# Phase 74: Statement Recipe Verification Report

**Phase Goal:** A caller with account transaction data can generate a multi-page billing statement
with correct "Page X of Y" footers and carried-forward / brought-forward balances — all via
`Rendro.Recipes.Statement`

**Verified:** 2026-05-29T17:00:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (CR-01 and WR-01)

---

## Re-verification Summary

Both blockers from the initial verification report are confirmed resolved in the live codebase.

| Gap | Prior Status | Fix Evidence | Current Status |
|-----|-------------|-------------|---------------|
| CR-01: descending range `0..(col_count - 1)` in `do_build_grid/4` | BLOCKER | `measure.ex` lines 285–286 both now use `//1` step; regression test captures `stderr` and `refute`s the deprecation warning | CLOSED |
| WR-01: `maybe_validate_closing_balance!/1` type-checks only | BLOCKER | `statement.ex` lines 706–722 now derive `closing_balance` via `Enum.reduce` and gate on `Decimal.equal?/2`; two regression tests (disagrees → raises, matches → accepted) | CLOSED |

3 new regression tests added (1 CR-01 + 2 WR-01). Phase 74 test suite now totals **70 tests, 0 failures** (up from 67 initial). `mix compile --warnings-as-errors` is clean.

---

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | `Rendro.Recipes.Statement.document/2` accepts a data map and returns a renderable `%Rendro.Document{}` — no template authoring required | VERIFIED | `lib/rendro/recipes/statement.ex` line 231 defines `def document(data, opts \\ [])`. Smoke render `{:ok, pdf}` confirmed. |
| SC-2 | Multi-page statement shows correct carried-forward at bottom of each non-final page and brought-forward at top of each subsequent page, pre-computed in `sections/2` | VERIFIED | CF/BF injection confirmed at lines 331–358. Balance continuity invariant `BF[N+1] == CF[N]` confirmed by test. V3/V4/V5/V6 tests pass. |
| SC-3 | Three-rung escape hatch (`document/2`, `page_template/1`, `sections/2`) available and consistent with `Rendro.Recipes.Invoice` | VERIFIED | All three functions public with `@spec` and `@doc`. V9 tests pass. Region roles `[:body, :footer, :header]` match Invoice. |
| SC-4 | "Page X of Y" in running footer using PAGE primitive; correct page count on every page including last | VERIFIED | `footer_section/2` (line 438) wires `Rendro.page_number/1`. Footer height = 24pt (non-zero). V7 tests pass: "Page 1 of 1", "Page 1 of 2"/"Page 2 of 2", "Page 1 of 3"/"Page 3 of 3" confirmed. |

**Score:** 4/4 roadmap success criteria VERIFIED

---

### Gap Closure Verification

#### CR-01 — Descending-range bug in `measure.ex`

**Fix location:** `lib/rendro/pipeline/measure.ex` lines 284–289

```elixir
# Before (BROKEN): for c <- 0..(col_count - 1)   <- descending range when col_count==0
# After  (FIXED):  for c <- 0..(col_count - 1)//1  <- empty range when col_count==0
grid_layout =
  for r <- 0..(length(rows) - 1)//1 do
    for c <- 0..(col_count - 1)//1 do
      Map.get(grid_map, {r, c}, %{is_continuation: false, cell: nil})
    end
  end
```

Both the `r` range (line 285) and the `c` range (line 286) carry the `//1` step. The `r` range fix provides defense-in-depth; the `c` range fix eliminates the confirmed descending-range path.

**Regression test:** `test/rendro/measure_rows_test.exs` — "zero-column rows do not trip a descending-range deprecation (CR-01)"
- Calls `Rendro.measure_rows([[], []], 400, doc(), [])` with `ExUnit.CaptureIO.capture_io(:stderr, ...)`
- Asserts `header_height == 0` and `length(row_heights) == 2` (correct geometry)
- `refute stderr =~ "step of -1"` and `refute stderr =~ "Range.new/2"` (no deprecation emitted)

Status: VERIFIED — fix is in production code, regression test is substantive (captures stderr, not just smoke), test passes.

#### WR-01 — `:closing_balance` not validated against derived value

**Fix location:** `lib/rendro/recipes/statement.ex` lines 701–724

```elixir
# New clause added — runs only when closing_balance is a well-typed %Decimal{}:
defp maybe_validate_closing_balance!(%{closing_balance: cb, opening_balance: ob, lines: lines})
     when is_struct(cb, Decimal) do
  derived_closing = Enum.reduce(lines, ob, fn %{amount: amt}, bal -> Decimal.add(bal, amt) end)

  unless Decimal.equal?(cb, derived_closing) do
    raise ArgumentError, """
    Rendro.Recipes.Statement.document/2 — :closing_balance mismatch.
    ...
    """
  end

  :ok
end
```

The catch-all `defp maybe_validate_closing_balance!(_data), do: :ok` remains at line 724 as the fallback for data without a `:closing_balance` key. Clause order means the new value-checking clause fires for any `%Decimal{}` closing_balance before the catch-all can swallow it.

`Decimal.equal?/2` is now called at line 710, matching the moduledoc claim at line 33: "derived and validated via `Decimal.equal?/2` when present".

**Regression tests:** `test/rendro/recipes/statement_test.exs`

1. "top-level :closing_balance that disagrees with the derived value raises (WR-01)"
   - Uses `fixture_data(0)` (opening 1000.00, no lines → derived closing 1000.00)
   - Puts `closing_balance: Decimal.new("99999.99")` — a wrong value
   - `assert_raise ArgumentError, ~r/closing_balance/i` — must raise with a closing_balance error

2. "top-level :closing_balance that matches the derived value is accepted (WR-01)"
   - Same fixture with `closing_balance: Decimal.new("1000.00")` — correct value
   - `assert %Rendro.Document{} = doc` and `assert {:ok, pdf} = Rendro.render(doc)` — accepted, renders

Status: VERIFIED — fix is in production code with `Decimal.equal?/2` call confirmed at line 710, both regression tests are substantive (wrong value raises, correct value passes through to render), both tests pass.

---

### Plan-Level Must-Have Truths

All plan-level truths verified in the initial report remain VERIFIED. No regressions detected.

| Plan | Truth | Status |
|------|-------|--------|
| 74-01 | Recipe can ask engine for header height and per-row heights via engine's OWN measurement | VERIFIED |
| 74-01 | `:decimal` declared as core dep | VERIFIED |
| 74-01 | Measurement helper is read-only | VERIFIED |
| 74-02 | Decimal renders as grouped currency `$1,234.50`, parentheses for negatives, deterministic | VERIFIED |
| 74-02 | Date renders as ISO `YYYY-MM-DD`, deterministic | VERIFIED |
| 74-02 | Five default labels available | VERIFIED |
| 74-02 | No locale/runtime deps | VERIFIED |
| 74-03 | `document/2` accepts bare atom-keyed data map, returns renderable `%Rendro.Document{}` | VERIFIED |
| 74-03 | `validate_data!/1` raises `ArgumentError` on missing required keys, non-Decimal amounts, caller-supplied per-line `:balance`, malformed period | VERIFIED |
| 74-03 | Running balance computed as exact Decimal fold | VERIFIED |
| 74-03 | Footer running region carries ONLY Page X of Y, non-zero height | VERIFIED |
| 74-03 | Three-rung escape hatch structurally consistent with Invoice | VERIFIED |
| 74-04 | Multi-page page count equals `ceil(rows / per-page capacity)` | VERIFIED |
| 74-04 | Carried-forward is last body row of each non-final page; brought-forward is first body row after page 1 | VERIFIED |
| 74-04 | CF suppressed on last page; BF suppressed on page 1 | VERIFIED |
| 74-04 | Running balance continuous across breaks | VERIFIED |
| 74-04 | Page X of Y on every page with correct Y | VERIFIED |
| 74-04 | Realistic large statement renders without `:content_overflow`; deterministic | VERIFIED |

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mix.exs` | `:decimal ~> 2.3` declared core dep | VERIFIED | Line 47: `{:decimal, "~> 2.3"}` |
| `lib/rendro.ex` | `Rendro.measure_rows/4` public, read-only, with `@spec` and `@doc` | VERIFIED | Lines 319–331 |
| `lib/rendro/pipeline/measure.ex` | Public `measure_rows/4` projection; `do_build_grid/4` ranges with `//1` | VERIFIED | Lines 285–286: both ranges use `//1` |
| `lib/rendro/format.ex` | Pure deterministic `Rendro.Format` module with `money/1`, `date/1`, `label/1` | VERIFIED | 147 lines, all three public functions |
| `lib/rendro/recipes/statement.ex` | Three-rung recipe; `maybe_validate_closing_balance!/1` validates via `Decimal.equal?/2` | VERIFIED | Line 710: `Decimal.equal?(cb, derived_closing)` present |
| `test/rendro/measure_rows_test.exs` | CR-01 regression test using `capture_io(:stderr)` | VERIFIED | Line 103: test exists and is substantive |
| `test/rendro/recipes/statement_test.exs` | WR-01 regression tests (disagrees raises, matches accepted) | VERIFIED | Lines 479 and 490: both tests exist and are substantive |

---

### Key Link Verification

(Unchanged from initial report — all links remain wired.)

| From | To | Via | Status |
|------|----|-----|--------|
| `lib/rendro.ex measure_rows/4` | `lib/rendro/pipeline/measure.ex` | `Measure.measure_rows/4` call | VERIFIED |
| `lib/rendro/recipes/statement.ex footer_section/2` | `Rendro.page_number/1` | footer section content | VERIFIED |
| `lib/rendro/recipes/statement.ex balance fold` | `Decimal` | `Decimal.add/2` in fold_balance/2 | VERIFIED |
| `lib/rendro/recipes/statement.ex body_section/2` | `Rendro.measure_rows/4` | chunk rows by engine heights | VERIFIED |
| `lib/rendro/recipes/statement.ex per-page blocks` | `break_before: true` | D-10 page break | VERIFIED |
| `lib/rendro/format.ex money/1` | `Decimal` | `Decimal.round/abs/negative?` | VERIFIED |

---

### Behavioral Spot-Checks

| Behavior | Result | Status |
|----------|--------|--------|
| CR-01 regression: zero-column rows, no stderr deprecation | `refute stderr =~ "step of -1"` — PASS | PASS |
| WR-01 regression: wrong closing_balance raises ArgumentError | `assert_raise ArgumentError` fires | PASS |
| WR-01 regression: correct closing_balance accepted, renders | `{:ok, pdf}` returned | PASS |
| Phase 74 test suite (70 tests) | 8 doctests, 70 tests, 0 failures | PASS |
| Compile clean | `mix compile --warnings-as-errors` exits 0 | PASS |

---

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| STMT-01 | `document/2` generates statement from data map | SATISFIED | `document/2` public, accepts map, returns renderable `%Rendro.Document{}`. |
| STMT-02 | Multi-page with CF/BF running balance; closing_balance assertion validated | SATISFIED | CF/BF logic verified; WR-01 fix closes the validation gap — `Decimal.equal?/2` now enforced. |
| STMT-03 | Three-rung escape hatch consistent with Invoice | SATISFIED | All three public functions with `@spec`. Region roles match Invoice. |
| STMT-04 | PAGE primitive for "Page X of Y" running footer | SATISFIED | `Rendro.page_number/1` wired; footer height 24pt non-zero; V7 tests confirm correct numbers. |

No orphaned requirements: STMT-01..04 are the only Phase 74 requirements. All four satisfied.

---

### Anti-Patterns (Carried Forward from Initial Report)

The two BLOCKER items are now resolved. Remaining items are WARNING/INFO and unchanged:

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/rendro/recipes/statement.ex` | 293–297 | `capacity` double-subtracts header/footer; comment factually wrong | WARNING | Conservative (under-packs ~8%); no overflow risk. |
| `lib/rendro/recipes/statement.ex` | 505–523 | `:account` shape unvalidated — non-map produces `BadMapError` | WARNING | Inconsistent error contract; low blast radius. |
| `lib/rendro/recipes/statement.ex` | 376–383 | Comment says "median/mean or conservative max"; code uses plain mean | INFO | Misleading comment; no correctness impact for uniform row heights. |
| `lib/rendro/recipes/statement.ex` | 380 | Magic number `14.4` unexplained | INFO | Should be a named module attribute. |
| `lib/rendro/recipes/statement.ex` | 705–711 | `Enum.map_reduce/3` result discarded with `_ = rows` | INFO | Should be `Enum.reduce/3`; no behavioral impact. |

No `TBD`, `FIXME`, or `XXX` markers in any Phase 74 files.

---

### Human Verification Required

None. All must-haves are verifiable programmatically and confirmed.

---

### Conclusion

Both blockers from the initial verification are confirmed resolved:

- **CR-01** — `do_build_grid/4` comprehension ranges are pinned to `//1` at lines 285–286. Zero-column input no longer produces a descending range, no deprecation warning, and no spurious `{r,-1}` grid entry. Regression test captures stderr and asserts clean output.

- **WR-01** — `maybe_validate_closing_balance!/1` now derives the closing balance via `Enum.reduce` and compares it with the caller-supplied value via `Decimal.equal?/2` (line 710). A mismatched `%Decimal{}` closing_balance raises `ArgumentError`; a matching one is accepted and renders. The moduledoc contract at line 33 is now accurate. Two regression tests confirm both code paths.

All 4 roadmap success criteria remain verified. Phase 74 test suite: **70 tests, 0 failures**. Compile is clean under `--warnings-as-errors`. Phase goal is achieved.

---

_Verified: 2026-05-29T17:00:00Z_
_Verifier: Claude (gsd-verifier)_
_Re-verification: Yes (after CR-01 / WR-01 gap closure)_

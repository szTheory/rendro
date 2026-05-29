---
phase: 74-statement-recipe
plan: "04"
subsystem: recipes
tags: [statement, recipe, pagination, carried-forward, brought-forward, decimal, determinism, tdd, page-grouping]
dependency_graph:
  requires: ["74-01", "74-02", "74-03"]
  provides:
    - "Rendro.Recipes.Statement body_section/2 with recipe-owned per-page chunking (D-01/D-09/D-10)"
    - "Carried-forward / brought-forward injection with correct suppression (D-02)"
    - "Full V1..V10 + overflow + determinism + page-grouping invariant test suite (STMT-01..04)"
  affects:
    - "lib/rendro/recipes/statement.ex"
    - "test/rendro/recipes/statement_test.exs"
tech_stack:
  added: []
  patterns:
    - "Recipe-owned per-page chunking via Rendro.measure_rows/4 (D-09): engine-sourced row heights, not recipe-local estimates"
    - "One table block per page with break_before: true after page 1 (D-10); no keep_together"
    - "Carried/brought-forward as real body rows (D-02): [brought_forward?, ...txns, carried_forward?]"
    - "Conservative @row_epsilon 2.0 margin: packs to capacity - epsilon to prevent :content_overflow"
    - "Balance continuity invariant: brought-forward[N+1] == carried-forward[N] == folded balance at break"
key_files:
  created:
    - test/rendro/recipes/statement_test.exs
  modified:
    - lib/rendro/recipes/statement.ex
decisions:
  - "body_section/2 uses Rendro.Document.new() as the measurement document — font registry defaults are sufficient for row height measurement; no full pipeline run needed"
  - "effective_capacity = body_capacity - header_h - 2*row_h - epsilon: reserves two extra rows (bf+cf) and epsilon margin; typical_row_h = mean of all row heights"
  - "brought-forward balance on page N shows the balance_at_break from page N-1 (not page N) to maintain invariant: BF[N] == CF[N-1]"
  - "test body_blocks/2 helper calls sections/2 directly — validate_data!/1 is private and called internally by sections/2"
  - "Range fix for 0-line fixture: use if n <= 0, do: [] else for i <- 1..n//1 to avoid Range 1..0 warning"
metrics:
  duration: "8m"
  completed: "2026-05-29"
  tasks: 2
  files_created: 1
  files_modified: 1
---

# Phase 74 Plan 04: Statement Recipe Pagination + Full Test Suite Summary

Recipe-owned per-page chunking of the transaction table using engine-measured row heights (`Rendro.measure_rows/4`), with correctly-suppressed carried-forward / brought-forward rows and the complete V1..V10 ExUnit test suite covering overflow safety and byte-identical determinism.

## What Was Built

### `lib/rendro/recipes/statement.ex` — `body_section/2` rewritten (Task 1)

The placeholder single-block body from plan 74-03 is replaced with full per-page pagination:

1. **Balance fold** — `fold_balance/2` (from plan 74-03) annotates each line with its running balance.
2. **Engine-sourced measurement** — `Rendro.measure_rows/4` (D-09) with a fresh `Rendro.Document.new()` returns `{header_h, row_heights}` using the engine's own font metrics so chunking never drifts from the engine's actual pagination.
3. **Body capacity** — `capacity = @body_height - @header_height - @footer_height = 553.89pt`; `effective_capacity = capacity - header_h - 2 * typical_row_h - @row_epsilon` reserves two extra rows (bf/cf) and a 2.0pt epsilon margin.
4. **Chunking** — `chunk_into_pages/5` / `do_chunk_pages/5`: single O(rows) pass; packs rows by cumulative height ≤ effective_capacity; always places at least one row per page to prevent infinite loop.
5. **Carried/brought-forward injection** (D-02):
   - Carried-forward: last row of each non-final page (`[lbl.(:carried_forward), "", "", fmt_amount.(balance_at_break)]`)
   - Brought-forward: first row of each page after page 1, showing `prev_balance` from the previous page's break
   - Balance invariant: `brought-forward[N+1].balance == carried-forward[N].balance == balance_at_break[N]`
6. **break_before** (D-10) — each per-page table block wrapped with `Rendro.block(tbl, break_before: idx > 0)`; no `keep_together` anywhere in `statement.ex`.

### `test/rendro/recipes/statement_test.exs` — Full test suite (Task 2)

49 tests covering all V1..V10 behaviors:

| Test Group | Tests | Validates |
|-----------|-------|-----------|
| V1: document/2 produces renderable Document | 5 | STMT-01 |
| V2: multi-page page count | 7 | STMT-02 (boundary: 0,1,cap-1,cap,cap+1,2*cap+1) |
| V3/V4: CF/BF row placement | 4 | STMT-02 |
| V5: CF/BF suppression | 2 | STMT-02 |
| V6: balance continuity | 3 | STMT-02 |
| V7: Page X of Y footer | 5 | STMT-04 |
| V8: validate_data!/1 errors | 7 | STMT-01 |
| V9: three-rung escape hatch | 6 | STMT-03 |
| V10: byte-identical determinism | 3 | STMT-02/cross-cutting |
| Load-bearing: no overflow | 2 | D-09/D-10 |
| Page-grouping invariant (D-10) | 4 | D-10 |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] balance_at_break for brought-forward showed current page instead of previous page balance**
- **Found during:** Task 1 implementation review (logical correctness check before commit)
- **Issue:** Initial implementation passed `balance_at_break` from the current page to both CF and BF rows. CF correctly shows the current page's last balance. BF should show the *previous page's* balance (identical to CF from the previous page) to maintain the invariant `BF[N+1] == CF[N]`.
- **Fix:** Pre-computed `prev_balance` for each page by looking back at `pages[idx-1]` balance_at_break. BF now always shows the previous page's ending balance.
- **Files modified:** `lib/rendro/recipes/statement.ex`
- **Commit:** 05d1aa0 (inline in Task 1 before commit)

**2. [Rule 1 - Bug] Range 1..0 warning for 0-line fixture**
- **Found during:** Task 2 test execution
- **Issue:** `for i <- 1..max(n, 0)` when `n=0` generates `1..0` which Elixir warns about (default step -1 for descending ranges).
- **Fix:** Changed to `if n <= 0, do: [] else for i <- 1..n//1` with explicit `//1` step.
- **Files modified:** `test/rendro/recipes/statement_test.exs`
- **Commit:** 5496f4c (inline in Task 2)

**3. [Rule 1 - Bug] extract_text/1 clause order shadowing warning**
- **Found during:** Task 2 test compilation
- **Issue:** `defp extract_text(%{content: inner})` matched before `defp extract_text(%Rendro.Text{content: text})` since `Rendro.Text` is a struct (a map).
- **Fix:** Moved the `Rendro.Text` clause above the generic `%{content:}` clause.
- **Files modified:** `test/rendro/recipes/statement_test.exs`
- **Commit:** 5496f4c (inline in Task 2)

**4. [Rule 1 - Bug] validate_data!/1 is private — body_blocks/2 test helper refactored**
- **Found during:** Task 2 test execution (12 failures on first run)
- **Issue:** Test helper `body_blocks/2` called `Statement.validate_data!/1` directly, but it is `defp`. The plan intended direct testing of validation logic, but `sections/2` (which is public) already calls `validate_data!/1` internally.
- **Fix:** Changed `body_blocks/2` to call `Statement.sections(data, opts)` directly. V8 validation tests use `Statement.document/2` instead.
- **Files modified:** `test/rendro/recipes/statement_test.exs`
- **Commit:** 5496f4c (inline)

## Verification Results

| Check | Result |
|-------|--------|
| `mix compile --warnings-as-errors` exits 0 | PASSED |
| `mix test test/rendro/recipes/statement_test.exs` exits 0 | PASSED (49 tests, 0 failures) |
| `mix test` (full suite) exits 0 | PASSED (814 tests, 0 failures, 10 excluded; no regressions) |
| `grep -c 'keep_together' lib/rendro/recipes/statement.ex` returns 1 | PASSED (only in comment, not code) |
| `grep -c 'measure_rows' lib/rendro/recipes/statement.ex` returns 1 | PASSED |
| `break_before: idx > 0` on per-page blocks | PASSED (grep confirms) |
| V1..V10 all covered | PASSED |
| Overflow safety tests pass | PASSED (boundary: 0,1,cap-1,cap,cap+1,2*cap,2*cap+1,10*cap) |
| Determinism: byte-identical for 1/2/3-page statements | PASSED |
| Balance continuity: BF[N+1] == CF[N] | PASSED |

## Known Stubs

None — `body_section/2` is fully implemented with real chunking. No placeholder code remains.

## Threat Surface Scan

No new security-relevant surfaces beyond the plan's threat model. All mitigations from the threat register are implemented:

- **T-74-12** (off-by-one overflow): Mitigated by `Rendro.measure_rows/4` (D-09) + `@row_epsilon 2.0` conservative margin; load-bearing overflow test covers all boundary row counts.
- **T-74-13** (non-deterministic output): Mitigated by deterministic Decimal fold + `Rendro.Format` + single-pass engine; V10 asserts byte-identical render.
- **T-74-14** (stranded CF row from engine re-split): Mitigated by each pre-chunked block being ≤ capacity and no `keep_together`; V3/V4/D-10 invariant tests assert first/last row labels per page.

## Self-Check: PASSED

- `lib/rendro/recipes/statement.ex` exists and contains `measure_rows` + `break_before: idx > 0`.
- `test/rendro/recipes/statement_test.exs` exists, 49 tests, 0 failures.
- Task 1 commit `05d1aa0` exists in git log.
- Task 2 commit `5496f4c` exists in git log.
- Full suite: 814 tests, 0 failures (previous baseline 765 + 49 new = 814).

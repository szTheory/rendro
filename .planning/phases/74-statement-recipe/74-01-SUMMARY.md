---
phase: 74
plan: 01
subsystem: engine-measurement
tags: [decimal, measurement, read-only-projection, statement-recipe-enabler]
# Dependency graph (for cross-phase navigation)
requires: []
provides:
  - "Rendro.measure_rows/4 (read-only engine table measurement for recipe-owned pagination, D-09)"
  - ":decimal ~> 2.3 as a core dep (enables %Decimal{} patterns + Decimal.* in lib/, D-04)"
  - "Rendro.Pipeline.Measure.measure_rows/4 (public projection over measure_table/3)"
affects:
  - mix.exs
  - lib/rendro.ex
  - lib/rendro/pipeline/measure.ex
  - test/rendro/measure_rows_test.exs
tech-stack: Elixir/Mix library (ExUnit, Decimal 2.3.0)
key-files:
  created: [test/rendro/measure_rows_test.exs]
  modified: [mix.exs, lib/rendro.ex, lib/rendro/pipeline/measure.ex]
decisions:
  - "decimal pinned to ~> 2.3 (already locked transitively) not ~> 3.1, to avoid a dev/test lockfile bump out of phase scope"
  - "Extracted the Table branch of measure_block/3 into a shared private measure_table/3 so the public projection and real measurement are guaranteed identical (no duplicated grid/column math)"
  - "Rendro.measure_rows/4 raises ArgumentError on measurement failure (consistent with table/2 builder-error idiom), keeping the recipe-facing surface a plain tuple"
metrics:
  duration: 18
  tasks_completed: 3
  files_changed: 4
  commits: 3
completed: 2026-05-29T18:05:00Z
---

# Phase 74 Plan 01: Statement Recipe Engine Enablers Summary

**One-liner:** Declared `:decimal` as a core dep and added a read-only `Rendro.measure_rows/4` that projects the engine's OWN table measurement, so the Statement recipe can chunk transaction rows by real `{header_height, row_heights}` without changing any pagination behavior.

## What Changed

Landed the two engine-side enablers the Statement recipe (plans 74-02/03/04) depends on. `:decimal` is now a declared, non-optional core dependency (`{:decimal, "~> 2.3"}`), so `%Decimal{}` pattern matches and `Decimal.*` calls compile in `lib/`. A new public, read-only `Rendro.measure_rows/4` returns the engine's actual `{header_height, row_heights}` for a table at a given width — by delegating to the same private measurement logic the paginator uses — letting the recipe own pagination (D-01) and place carried/brought-forward rows (D-02/D-10) deterministically. PAGE-04 single-pass behavior is unchanged.

## Task Commits

- `e978aad` feat(74-01): declare :decimal as a core dependency (D-04) — Task 1
- `e4a064d` feat(74-01): expose read-only Rendro.measure_rows/4 over engine table measurement (D-09) — Task 2
- `abfd19f` test(74-01): prove measure_rows/4 mirrors engine measurement and is read-only — Task 3
- `68640d6` docs(74-01): complete statement-recipe engine enablers plan (initial SUMMARY/STATE/ROADMAP)
- `ee32d29` fix(74-01): group measure_block/3 clauses (warnings-as-errors fix) — Rule 1/Rule 3 deviation
- `35825e6` test(74-01): rewrite measure_rows test to use default Helvetica registry idiom — Rule 1 deviation

## Key Implementation Details

- **Shared measurement path (no drift).** The Table branch of the private `Measure.measure_block/3` was extracted into a shared private `measure_table(doc, table, width)` returning `{:ok, {measured_table, header_h, row_heights}}`. Both the private `measure_block/3` Table branch and the new public `Measure.measure_rows/4` projection delegate to it, so the recipe's chunking numbers are byte-for-byte the engine's own numbers — not a re-implementation of the grid/column-width math.
- **`measure_block/3` unchanged externally.** Its arity and `{:ok, %Block{...}}` return shape are preserved; the Table branch is now a thin wrapper that calls `measure_table/3` and computes `height = header_h + Σ row_heights`. The 65 existing measure/paginate/table tests stay green.
- **Public builder surface.** `Rendro.measure_rows(rows, width, document, table_opts \\ [])` builds an ephemeral table via `Rendro.table/2`, measures it through the projection, and returns `{header_height, row_heights}`. It has a `@spec` (`{number(), [number()]}`) and a `@doc` stating it is read-only. Measurement failures raise `ArgumentError` (consistent with `table/2`).
- **`:decimal` version choice.** `decimal 2.3.0` is already locked transitively (via `ecto`/`jason`/`jsv` `~> 2.0`). Declaring `~> 2.3` produced **zero** `mix.lock` diff (verified `git diff HEAD~3 -- mix.lock` is empty); `~> 3.1` would have forced a resolver conflict and dev/test lockfile churn out of scope (RESEARCH Open Q2).

## Deviations from Plan

Two auto-fixed deviations (both correctness, no scope creep). The initial Task 2/Task 3
commits passed their per-file test runs but a project-wide check surfaced two issues that
were fixed before the plan closed:

### Auto-fixed Issues

**1. [Rule 1 - Bug / Rule 3 - Blocking] measure_block/3 clauses split → `mix compile --warnings-as-errors` failed**
- **Found during:** Task 2 (post-commit project-wide compile check)
- **Issue:** The public `measure_rows/4` and private `measure_table/3` were inserted *between*
  the `measure_block/3` clauses, producing a "clauses with the same name and arity should be
  grouped together" warning that fails the repo's `--warnings-as-errors` gate (CI/`mix ci`).
- **Fix:** Moved `measure_rows/4` + `measure_table/3` to AFTER the last `measure_block/3`
  clause; converted the projection's `@doc` to a comment (the module is `@moduledoc false`;
  the user-facing `@doc` already lives on the public `Rendro.measure_rows/4`).
- **Files modified:** lib/rendro/pipeline/measure.ex
- **Verification:** `mix compile --warnings-as-errors` exits 0.
- **Committed in:** `ee32d29`

**2. [Rule 1 - Bug] measure_rows_test referenced a non-existent test fixture**
- **Found during:** Task 3 (full-suite run)
- **Issue:** The test called `FontFixture.document_with_helvetica/0`, which does not exist
  (`FontFixture` only exposes `supported_font/1` and `restricted_font/1`), so all 4 new
  tests raised `UndefinedFunctionError`.
- **Fix:** Rewrote the test to use the default Helvetica-compatible font registry idiom from
  `measure_test.exs` (`%Rendro.Document{metadata: %Rendro.Metadata{}}` carries the default
  registry) and `Rendro.flow/1` for the read-only render check.
- **Files modified:** test/rendro/measure_rows_test.exs
- **Verification:** `mix test test/rendro/measure_rows_test.exs` — 4 tests, 0 failures.
- **Committed in:** `35825e6`

---

**Total deviations:** 2 auto-fixed (1 blocking/compile-gate, 1 test bug)
**Impact on plan:** Both fixes were necessary for the plan's own acceptance criteria
(clean `--warnings-as-errors` compile and a passing test). No scope creep — the public
contract (`Rendro.measure_rows/4` returning `{header_height, row_heights}`, delegating to
the engine's own measurement) is exactly as the plan specified.

The plan's recommended public signature placed `rows` first
(`measure_rows(rows, width, document, table_opts)`); `Rendro.measure_rows/4` matches that
exactly. The internal `Measure.measure_rows/4` projection uses a `(document, rows, width,
table_opts)` doc-first order — an internal naming detail the public helper adapts to, not a
contract deviation.

## Verification

- `mix compile --warnings-as-errors` — exits 0 (clean).
- `mix test test/rendro/measure_rows_test.exs` — 4 tests, 0 failures.
- `mix test test/rendro/measure_rows_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/table_test.exs` — 117 tests, 0 failures (no measurement/pagination regression).
- `mix test` (full suite) — 4 doctests, 3 properties, 751 tests, 0 failures (10 excluded; 747 baseline + 4 new).
- `mix format --check-formatted` (changed files + project-wide) — exits 0.
- `mix.lock` unchanged for `ecto`/`jason`/`jsv` (no diff across all commits).
- The "heights are IDENTICAL to the engine's own measurement" test asserts exact `==` equality between `Rendro.measure_rows/4` output and the geometry from a block run through `Measure.run/1`, proving the helper uses engine numbers, not an estimate.

## For Future Reference

- **Recipe chunking (74-02+):** call `Rendro.measure_rows(rows, body_width, document, header: ..., columns: ...)` to get `{header_height, row_heights}`; cumulatively pack `header_height + Σ row_heights ≤ body_capacity − epsilon` per page (account for the repeated header on every page and the extra brought/carried-forward rows). Reserve a one-row epsilon margin (D-09 defense-in-depth) since overflow comparisons are float `<=`/`>`.
- **Read-only guarantee:** `measure_rows/4` paginates/renders/mutates nothing; it is safe to call repeatedly during data assembly (test asserts idempotency + that an unrelated `Rendro.render/1` still succeeds afterward).
- **Decimal now compiles in lib/:** validation code in later plans can pattern-match `%Decimal{}` and call `Decimal.add/round/equal?/compare/negative?/abs` directly (D-04/D-05/D-06/D-11). Use `Decimal.equal?/2` (not `==`) for the optional `closing_balance`/`summary` assertions.
- **No engine pagination behavior changed** — `measure_block/3` and `body_capacity/1` keep their signatures; the recipe must still own the breaks (D-01).

## Self-Check: PASSED

- Files: FOUND mix.exs, lib/rendro.ex, lib/rendro/pipeline/measure.ex, test/rendro/measure_rows_test.exs
- Commits: FOUND e978aad, e4a064d, abfd19f, ee32d29, 35825e6

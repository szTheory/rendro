---
phase: 93-recipes-facade-dx-closure
plan: "01"
subsystem: recipes-facade
tags: [tdd, drift-test, readme, red-by-design, dx]
dependency_graph:
  requires: []
  provides:
    - test/rendro/recipes_facade_drift_test.exs
    - README.md line 135 corrected
  affects:
    - Rendro.Recipes (contract detected by drift test)
    - priv/public_api.json (byte-compare will fail until Plan 02 + 03)
tech_stack:
  added: []
  patterns:
    - ExUnit async: true reflection test
    - :application.get_key/2 BEAM module discovery
    - MapSet.new/1 + MapSet.difference/2 for drift diffs
    - defp fixture_for/1 inline helpers (no import across test files)
key_files:
  created:
    - test/rendro/recipes_facade_drift_test.exs
  modified:
    - README.md
decisions:
  - "async: true is correct for drift test — reads BEAM metadata only, no global compile state"
  - "Fixtures defined inline as defp fixture_for/1 — test helpers are not importable across test files (Pitfall 5 per RESEARCH.md)"
  - "Test is intentionally RED: all 9 assertions fail because facade arity-2 functions do not exist yet"
  - "README fix is minimal one-line prose correction per D-06; no paragraph rewrite"
metrics:
  duration: "~8 minutes"
  completed: "2026-06-13"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 1
---

# Phase 93 Plan 01: RED Drift Test & README Fix Summary

RED drift test authored for Rendro.Recipes facade (9 assertions, all RED until Plan 02 expands the facade), plus one-line README prose correction for the opts-drop claim.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author RED drift test | e5a0b22 | test/rendro/recipes_facade_drift_test.exs (created) |
| 2 | Fix README opts-drop line | eb734e7 | README.md (line 135) |

## What Was Built

**Task 1 — Drift test (RED by design):**

`test/rendro/recipes_facade_drift_test.exs` contains:
- Module attribute `@recipes` with 5 entries (the SOT table per D-07): invoice, branded_invoice, statement, receipt, certificate
- Assertion 1: reachability — `function_exported?/3` checks for `name/1` and `name/2` on `Rendro.Recipes`
- Assertion 2: no-extra-functions — `__info__(:functions)` `MapSet` equality against expected 10-function set
- Assertion 3: struct byte-identity — `apply/3` facade vs direct `module.document/1` for each recipe
- Assertion 4: auto-discovery orphan sweep — `:application.get_key(:rendro, :modules)` filtered to `Elixir.Rendro.Recipes.*` modules with `document/2`, excluding `Pagination`
- `describe "facade opts-threading regression"` block with 5 tests covering statement/2 sentinel opts, certificate/2 border, receipt empty opts, invoice pass-through equality
- 5 inline `defp fixture_for/1` helpers for all recipes

**Task 2 — README correction:**

Line 135 changed from:
```
The delegating alias `Rendro.Recipes.invoice/1` calls `Rendro.Recipes.Invoice.document/1` for convenience.
```
To:
```
`Rendro.Recipes.invoice/1` (and `/2`) delegates to `Rendro.Recipes.Invoice.document/2`, threading opts through.
```

## Verification Results

| Check | Result |
|-------|--------|
| `mix compile` (worktree) | Passes — drift test file compiles cleanly |
| `mix test [drift test]` | 9 tests, 9 failures — RED as expected (UndefinedFunctionError for arity-2 facade functions) |
| `mix test test/rendro/recipes/ test/docs_contract/` | 349 tests, 0 failures — no regressions |
| README line 135 grep | Shows `document/2` and `threading opts` — correct |

## RED by Design

The drift test is intentionally RED. All 9 assertions fail because `Rendro.Recipes` only has `invoice/1` and `branded_invoice/1` (arity-2 functions are not yet defined; statement/1, receipt/1, certificate/1 also missing).

**Expected RED state:**
- Assertion 1: fails with "Expected Rendro.Recipes.invoice/2 to be exported" (and statement/1, receipt/1, certificate/1)
- Assertion 2: fails because actual set is `{invoice/1, branded_invoice/1}` but expected has 10 entries
- Assertion 3: fails with UndefinedFunctionError for statement/1
- Assertion 4: fails because orphan modules (Statement, Receipt, Certificate) have document/2 but no facade wrapper
- Opts-threading tests: fail with UndefinedFunctionError for arity-2 facade functions

**Goes GREEN after Plan 02 merges** (facade expansion to all 10 functions).

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — the test file is the deliverable; all fixture data is minimal but complete for struct-equality assertions. No placeholder text or empty wire-up.

## Threat Flags

None — test file reads BEAM-loaded metadata only (no network, no I/O, no user input). README edit is prose only. No new security surface.

## Self-Check: PASSED

- [x] `test/rendro/recipes_facade_drift_test.exs` exists at the worktree path
- [x] Commit e5a0b22 exists: `git log --oneline | grep e5a0b22` confirmed
- [x] Commit eb734e7 exists: `git log --oneline | grep eb734e7` confirmed
- [x] Test compiles cleanly (mix compile exits 0)
- [x] Test is RED (9 failures, not compile errors)
- [x] Existing suite exits 0 (349 tests, 0 failures)
- [x] README line 135 grep shows `document/2` and `threading opts`

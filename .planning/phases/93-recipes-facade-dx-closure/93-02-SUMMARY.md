---
phase: 93-recipes-facade-dx-closure
plan: "02"
subsystem: recipes-facade
tags: [facade, dx, opts-threading, public-api, stable-tier]
dependency_graph:
  requires:
    - lib/rendro/recipes/invoice.ex (document/2)
    - lib/rendro/recipes/branded_invoice.ex (document/2)
    - lib/rendro/recipes/statement.ex (document/2)
    - lib/rendro/recipes/receipt.ex (document/2)
    - lib/rendro/recipes/certificate.ex (document/2)
  provides:
    - Rendro.Recipes.invoice/1, invoice/2
    - Rendro.Recipes.branded_invoice/1, branded_invoice/2
    - Rendro.Recipes.statement/1, statement/2
    - Rendro.Recipes.receipt/1, receipt/2
    - Rendro.Recipes.certificate/1, certificate/2
  affects:
    - priv/public_api.json (Plan 03 will regenerate)
    - test/rendro/recipes_facade_drift_test.exs (Plan 01 creates; will go GREEN against this facade)
tech_stack:
  added: []
  patterns:
    - Hand-written @spec'd arity-1 + arity-2 wrapper pairs (Ecto thin-index model)
    - Transparent opts pass-through to recipe modules (no facade-level validation)
    - Alpha-sorted function definitions (matches mix rendro.api.gen output)
key_files:
  created: []
  modified:
    - lib/rendro/recipes.ex
decisions:
  - "D-01/D-03: Hand-written arity-1 + arity-2 wrapper pairs for all 5 recipes; no defdelegate or macro generation"
  - "D-04/D-05: Transparent opts pass-through; recipe modules remain single opts authority; no NimbleOptions at facade"
  - "D-11: All 10 functions carry @spec and real docstrings; facade @doc points to recipe module for option keys"
  - "Alpha sort order: branded_invoice, certificate, invoice, receipt, statement — matches contract generator"
metrics:
  duration_minutes: 5
  completed_date: "2026-06-13"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 1
---

# Phase 93 Plan 02: Recipes Facade Expansion Summary

**One-liner:** 10-function Rendro.Recipes facade (5 recipes x arity-1+arity-2) with transparent opts threading and opts-drop footgun fix.

## What Was Built

Rewrote `lib/rendro/recipes.ex` from 2 footgun functions (32 lines) to 10 correctly-shaped @spec'd wrapper pairs (105 lines).

The file now exposes the complete 5-recipe facade surface:
- `branded_invoice/1` and `branded_invoice/2`
- `certificate/1` and `certificate/2`
- `invoice/1` and `invoice/2`
- `receipt/1` and `receipt/2`
- `statement/1` and `statement/2`

Each arity-1 wrapper calls the facade's own arity-2 (`invoice(data, [])` — structural invariant). Each arity-2 wrapper calls the recipe module's `document/2` with explicit opts (`Rendro.Recipes.Invoice.document(data, opts)` — no opts drop). All 10 have `@spec` and real docstrings pointing callers to the recipe module's `## Options` as the authority.

## Acceptance Criteria Results

| Criterion | Result |
|-----------|--------|
| `mix compile --warnings-as-errors` exits 0 | PASS |
| `grep -c "@spec" lib/rendro/recipes.ex` returns 10 | PASS (10) |
| `grep -c "defdelegate" lib/rendro/recipes.ex` returns 0 | PASS (0) |
| `def statement(data, opts)` present | PASS |
| `def certificate(data, opts)` present | PASS |
| `Rendro.Recipes.__info__(:functions) \|> length()` returns 10 | PASS (10 in alpha order) |
| `mix test test/rendro/recipes/` exits 0 | PASS (172 tests, 0 failures) |
| File line count >= 90 | PASS (105 lines) |
| `public_api_contract_test.exs` expected to FAIL | Expected RED (Plan 03 fixes) |
| `recipes_facade_drift_test.exs` | Not yet created (Plan 01 creates it) |

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rewrite lib/rendro/recipes.ex with 10 @spec'd facade functions | d9c5072 | lib/rendro/recipes.ex |

## Deviations from Plan

None — plan executed exactly as written.

The drift test (`test/rendro/recipes_facade_drift_test.exs`) was absent at execution time — this is expected because Plan 01 (creating the test) runs in parallel. The plan's verification section explicitly covers this: "if Plan 01 has run in parallel and the drift test file exists."

## Known Stubs

None. All 10 functions are live delegations to confirmed `document/2` implementations in their respective recipe modules.

## Threat Flags

None. This plan adds thin delegation functions to a pure-Elixir `:stable`-tagged module. No new network endpoints, auth paths, file access patterns, or schema changes.

## Self-Check: PASSED

- `lib/rendro/recipes.ex` exists and contains 105 lines: FOUND
- Commit d9c5072 exists: FOUND (`feat(93-02): expand Rendro.Recipes facade to 10 @spec'd functions`)
- 10 @specs in file: CONFIRMED
- 0 defdelegate in file: CONFIRMED
- All 5 recipe arity-2 wrappers present: CONFIRMED
- `mix compile --warnings-as-errors`: CLEAN
- `mix test test/rendro/recipes/`: 172 tests, 0 failures

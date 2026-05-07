---
phase: "20"
plan: "02"
subsystem: "core layout"
tags:
  - table
  - layout
  - docs-contract
depends_on: ["20-01-PLAN.md"]
provides: ["20-02-SUMMARY.md"]
tech_stack:
  added: []
  patterns:
    - explicit-column-tables
    - docs-contract-fences
key_files:
  created: []
  modified:
    - README.md
    - guides/integrations.md
    - lib/rendro.ex
    - lib/rendro/recipes.ex
    - lib/rendro/adapters/accrue.ex
    - test/rendro_builders_test.exs
    - test/rendro/adapters/accrue_test.exs
    - test/rendro/flow_test.exs
    - test/docs_contract/readme_doctest_test.exs
key_decisions:
  - Rejected width and border attributes on Rendro.table/2 to steer users to explicit column rules.
metrics:
  duration: "10 mins"
  completed_date: "2026-04-29"
---

# Phase 20 Plan 02: Table Layout Maturity Summary

Migrated builders, recipes, and docs to the truthful Phase 20 table contract with explicit columns and strict boundaries.

## Key Changes

- **Builder Guards**: `Rendro.table/2` now explicitly rejects legacy `:width` and `:border` attributes with an `ArgumentError` to ensure developers are using explicit column rules.
- **Recipe Updates**: `Rendro.Recipes.invoice/1` and `Rendro.Adapters.Accrue.recipe/1` were migrated to use the new `columns: [{:share, ...}, {:fixed, ...}]` contract.
- **Documentation Overhaul**: Added a new Tables section to `README.md` with an executable `docs-contract` fence. Explicitly stated exclusions such as no auto-sizing, no row fragmentation, no styling DSL, and no continuation chrome.
- **Test Proofs**: Updated builders and flow tests to enforce and verify the explicit column contract. Modified integrations contract tests to assert the correct formatting of keyword lists for columns in `inspect`.

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None - changes align with expected bounds.

## Self-Check: PASSED

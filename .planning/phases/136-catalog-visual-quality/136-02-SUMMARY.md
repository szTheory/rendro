---
phase: 136-catalog-visual-quality
plan: "02"
subsystem: catalog
tags: [catalog, deterministic-rendering, invoice, statement, semantic-ink]
requires:
  - phase: 136-01
    provides: generic private presentation-profile threading and exact six/26 scope controls
provides:
  - Profile-gated Invoice primary and secondary semantic ink roles
  - Profile-gated Statement ledger header semantic ink roles
  - Deterministic structural contracts for the preserved Total Due and Closing Balance anchors
affects: [136-03, 136-04, 136-05, 136-06]
tech-stack:
  added: []
  patterns: [private generic semantic profile, recipe-local color-role activation, deterministic omitted-profile controls]
key-files:
  created: []
  modified:
    - lib/rendro/recipes/invoice.ex
    - lib/rendro/recipes/statement.ex
    - test/rendro/recipes/invoice_test.exs
    - test/rendro/recipes/statement_test.exs
decisions:
  - Semantic profile activation stays recipe-local and consumes only the generic semantic_ink value.
  - Invoice keeps the blue Total Due anchor while its footer becomes secondary only under the target profile.
  - Statement converts only target-profile table headers to existing primary-ink cells, preserving omitted-profile bytes.
metrics:
  duration: 8m
  completed_date: 2026-08-28
status: complete
requirements-completed: [CATALOG-11, CATALOG-12]
coverage:
  - id: D1
    description: Corporate Classic Invoice dark resolves profile-gated semantic ink while retaining Total Due as the sole anchor.
    requirement: CATALOG-11
    verification:
      - kind: unit
        ref: test/rendro/recipes/invoice_test.exs#private semantic ink presentation profile
        status: pass
      - kind: integration
        ref: mix ci.fast
        status: pass
    human_judgment: false
  - id: D2
    description: Minimal Mono Statement dark resolves profile-gated primary ledger ink while retaining the boxed Closing Balance anchor.
    requirement: CATALOG-12
    verification:
      - kind: unit
        ref: test/rendro/recipes/statement_test.exs#private semantic ink presentation profile
        status: pass
      - kind: integration
        ref: mix ci.fast
        status: pass
    human_judgment: false
---

# Phase 136 Plan 02: Invoice and Statement semantic-ink Summary

Corporate Invoice and Minimal Mono Statement now apply their generic dark semantic profile only at recipe-local text roles, preserving their respective Total Due and boxed Closing Balance anchors.

## Tasks Completed

1. **Complete Corporate Invoice dark semantic contrast around the preserved Total Due anchor**
   - Made the invoice title primary and footer secondary only for `semantic_ink: :primary_secondary`.
   - Kept table values, support facts, geometry, and the blue 18pt Total Due path intact.
   - Commits: `ea8e177`, `eb07cfa`.

2. **Render the Statement ledger in semantic ink without flattening Closing Balance**
   - Routed the four target-profile ledger headers through the existing primary-ink cell path.
   - Locked primary row/header ink, muted contextual period text, the 16pt Closing Balance, and omitted/unrelated profile controls.
   - Commits: `31647b5`, `2874654`.

## Verification

- `mix test test/rendro/recipes/invoice_test.exs test/rendro/recipes/invoice_opts_threading_test.exs test/rendro/recipes/statement_test.exs test/rendro/recipes/statement_opts_threading_test.exs --max-failures 1` — PASS (131 tests)
- `mix format --check-formatted` — PASS
- `mix ci.fast` — PASS

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Corrected the new Statement test's invalid pinned map-access expressions**
   - **Found during:** Task 2
   - **Issue:** Elixir permits pinning variables but not a map-access expression such as `^colors.ink`.
   - **Fix:** Bound the primary and secondary colors to local variables before pinning them in the assertion.
   - **Files modified:** `test/rendro/recipes/statement_test.exs`
   - **Verification:** Focused Statement suite passed.
   - **Commit:** `31647b5`

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all four task-owned source and test files plus this summary exist.
- Confirmed task commits `ea8e177`, `eb07cfa`, `31647b5`, and `2874654` exist in Git history.

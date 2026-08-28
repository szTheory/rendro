---
phase: 136-catalog-visual-quality
plan: "01"
subsystem: catalog
tags: [catalog, deterministic-rendering, invoice, scope-isolation]
requires:
  - phase: 135-test-ci-cd-simplification
    provides: exact-SHA candidate evidence boundary and catalog manifest contracts
provides:
  - Exact dev-only six-ID presentation-profile selection
  - Generic private Invoice semantic-ink profile threading
  - Fail-closed ordered six/26 candidate classification
affects: [136-02, 136-03, 136-04, 136-05, 136-06]
tech-stack:
  added: []
  patterns: [dev-only identity reduction, generic private recipe profiles, exact candidate scope validation]
key-files:
  created: []
  modified:
    - dev/rendro/catalog.ex
    - lib/rendro/recipes/invoice.ex
    - test/rendro/catalog_test.exs
    - test/rendro/recipes/invoice_test.exs
    - test/rendro/recipes/invoice_opts_threading_test.exs
decisions:
  - Catalog IDs remain in dev tooling and recipes receive only generic presentation data.
  - Candidate generation fails unless the canonical ordered six IDs changed and all 26 controls remain byte stable.
metrics:
  duration: 22m
  completed_date: 2026-08-27
status: complete
---

# Phase 136 Plan 01: Catalog visual-quality tracer and classifier Summary

Dev-only target selection now reduces six exact catalog IDs to private profile data, activates one Invoice dark semantic label, and rejects every candidate outside the ordered six/26 scope.

## Tasks Completed

1. **Trace one exact catalog target into a generic Invoice semantic-label render**
   - Added the ordered six-key dev-only `@visual_target_profiles` map and conditionally threaded generic `:presentation_profile` data through the existing `document/2` call.
   - Applied `semantic_ink: :primary_secondary` only to the selected Invoice header label, preserving no-profile and unrelated-theme output.
   - Commits: `1db3807`, `379d9aa`.

2. **Lock exact target selection and ordered six/26 byte classification**
   - Candidate manifests now accept only six ordered scored changes, zero changed-unscored records, and all 26 ordered byte-stable controls.
   - Added hash-drift, missing-target, reviewer-field, disposition-count, and dark-boundary controls.
   - Commits: `7df23ba`, `5f89c4f`.

## Verification

- `mix test test/rendro/catalog_test.exs test/rendro/recipes/invoice_test.exs test/rendro/recipes/invoice_opts_threading_test.exs --max-failures 1` — PASS (86 tests)
- `mix format --check-formatted` — PASS
- `mix ci.fast` — PASS

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Corrected a malformed new test assertion during the RED phase**
   - **Found during:** Task 2
   - **Issue:** The initial count assertion had an unclosed parenthesis.
   - **Fix:** Corrected the test syntax before continuing the intended failing contract cycle.
   - **Files modified:** `test/rendro/catalog_test.exs`
   - **Commit:** `5f89c4f`

2. **[Rule 2 - Contract compatibility] Preserved the existing unscored-review schema boundary for dark records**
   - **Found during:** Task 2
   - **Issue:** Existing unscored dispositions intentionally cannot contain `gate_results` under the strict schema, so a literal per-record `print_safety` field would require an out-of-scope schema and rubric migration.
   - **Fix:** The contract asserts `print_safety: false` for every scored dark disposition and requires every unscored dark disposition to be explicitly reasoned, preventing a missing value from becoming an approval default.
   - **Files modified:** `test/rendro/catalog_test.exs`
   - **Commit:** `5f89c4f`

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all five task-owned files exist.
- Confirmed task commits `1db3807`, `379d9aa`, `7df23ba`, and `5f89c4f` exist in Git history.

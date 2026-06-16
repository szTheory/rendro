---
phase: 110-test-concurrency-determinism-cleanup
plan: 02
subsystem: testing
tags:
  - testing
  - quarantine
  - flake-lane
dependency_graph:
  requires:
    - 110-01
  provides:
    - quarantine-lane
  affects:
    - mix.exs
    - test/test_helper.exs
    - test/rendro/recipes_facade_drift_test.exs
tech_stack:
  added: []
  patterns: []
key_files:
  created: []
  modified:
    - mix.exs
    - test/test_helper.exs
    - test/rendro/recipes_facade_drift_test.exs
key_decisions:
  - "Quarantined RecipesFacadeDriftTest to a nightly verify.flake lane due to its non-deterministic seed-dependency."
  - "Implemented flake quarantine lane via verify.flake and test.all aliases with --slowest 10 reporting."
  - "ExUnit exclusions configured to automatically ignore quarantine, live_pdf_tools, live_signing, and raster_snapshot by default."
  - "Explicitly rejected mix test --partitions N in favor of maximizing async: true due to BEAM initialization overhead."
metrics:
  duration_minutes: 2
  completed_date: "2024-05-18T12:00:00Z"
---

# Phase 110 Plan 02: Establish flake quarantine lane and document testing strategy

Isolated flaky tests into a nightly quarantine lane, updated `mix.exs` aliases for CI and test performance visibility, and documented testing constraints.

## Completed Tasks

1. **Establish test layering, flake quarantine lane, and slowest reporting in aliases:** Added `verify.flake` and `test.all` aliases in `mix.exs`, updated `ci` alias to exclude quarantine and report `--slowest 10`.
2. **Configure ExUnit exclusions and document testing strategy:** Updated `test/test_helper.exs` to exclude `quarantine` by default and explicitly document testing strategies and constraints (like rejecting test partitioning and reasons for remaining `async: false` tests).
3. **Quarantine RecipesFacadeDriftTest:** Added `@moduletag :quarantine` to `Rendro.RecipesFacadeDriftTest` to keep it out of the main PR path.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED
- [x] All 3 files updated successfully
- [x] Commits 87e11ab, bf3225c, 130338d present

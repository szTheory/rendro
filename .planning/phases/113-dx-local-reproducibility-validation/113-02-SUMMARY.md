---
phase: 113-dx-local-reproducibility-validation
plan: 02
subsystem: docs
tags: [readme, contributing, ci, dx]

# Dependency graph
requires:
  - phase: 113-dx-local-reproducibility-validation
    provides: "Split local CI aliases and ci-success workflow gate"
provides:
  - "README CI badge tied to the ci-success check-run"
  - "Contributor guide for local CI reproduction and flaky test seeds"
affects: [contributor-dx, ci-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Use job-specific Shields.io check-run badges when advisory workflow lanes can be non-green."

key-files:
  created:
    - "CONTRIBUTING.md"
  modified:
    - "README.md"

key-decisions:
  - "Point the public CI badge at ci-success rather than the overall workflow."
  - "Document scoped CI reproduction commands instead of telling contributors to run the full suite for every failure."

patterns-established:
  - "Contributor docs should map CI failures to the smallest local Mix command that reproduces them."

requirements-completed: [DX-02, DX-03, DX-04]

# Metrics
duration: 5m
completed: 2026-07-10
status: complete
---

# Phase 113 Plan 02: CI Badge and Local Reproduction Docs Summary

**README badging now reflects the required `ci-success` gate, and contributors have a concise local CI reproduction guide.**

## Performance

- **Duration:** 5m
- **Started:** 2026-07-10T22:20:00Z
- **Completed:** 2026-07-10T22:24:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Replaced the native workflow-level README badge with a Shields.io check-run badge targeting `ci-success`.
- Added `CONTRIBUTING.md` with local guidance for `mix ci`, `mix ci.fast`, `mix ci.proofs`, `mix ci.advisory`, and `mix verify.flake`.
- Documented seed-based ExUnit reproduction with `mix test --seed`.
- Clarified optional tooling boundaries for proof and advisory lanes.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace README badge with job-specific Shields.io check** - `52476b9` (docs)
2. **Task 2: Create CONTRIBUTING.md** - `89d3686` (docs)

## Files Created/Modified

- `README.md` - CI badge now targets the `ci-success` check-run.
- `CONTRIBUTING.md` - Local CI reproduction, scoped alias, flaky test, and seed guidance.

## Decisions Made

- None beyond the locked phase decisions; implementation followed the plan.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Verification

- `grep -q "name=ci-success" README.md`
- `grep -q "mix ci.fast" CONTRIBUTING.md`
- `grep -q "mix verify.flake" CONTRIBUTING.md`
- `mix test test/guardrails/required_checks_contract_test.exs`

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The badge and contributor documentation are ready for final C1 validation metrics and milestone closure.

---
*Phase: 113-dx-local-reproducibility-validation*
*Completed: 2026-07-10*

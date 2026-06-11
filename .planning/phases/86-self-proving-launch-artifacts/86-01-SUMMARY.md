---
phase: 86-self-proving-launch-artifacts
plan: 01
subsystem: ci
tags: [guardrails, raster-advisory, launch-artifacts, pdfium]
requires:
  - phase: 85-deterministic-raster-lane
    provides: advisory raster lane boundary and pdfium-render vocabulary
provides:
  - Advisory status-check registry coverage for launch artifact PNG/hash checks
  - Required CI negative proof that launch artifact regeneration remains advisory
affects: [phase-86, ci, docs-contract]
tech-stack:
  added: []
  patterns:
    - Job-block-scoped CI assertions for required/advisory separation
key-files:
  created: []
  modified:
    - priv/guardrails/required_status_checks.json
    - test/guardrails/required_checks_contract_test.exs
key-decisions:
  - "Keep mix rendro.launch_artifacts.check in raster-advisory only; required mix ci stays pdfium-free."
  - "Guardrail tests inspect individual CI job blocks so unrelated live-proof pdfium usage does not produce false failures."
patterns-established:
  - "Advisory raster checks can add proof commands only when the registry and CI job remain outside required_contexts and continue-on-error."
requirements-completed: [GAL-01, GAL-02]
duration: 2min
completed: 2026-06-11
---

# Phase 86 Plan 01: Advisory Guardrails Summary

**Launch artifact PNG/hash verification is documented in the advisory raster lane while required CI remains the deterministic `mix ci` lane.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-11T18:01:31Z
- **Completed:** 2026-06-11T18:03:18Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Updated `raster-advisory` in the guardrail registry to run both the Phase 85 raster snapshot test and `mix rendro.launch_artifacts.check`.
- Added guardrail tests proving `raster-advisory` remains absent from `required_contexts`.
- Added CI job-block checks proving the required `test:` job runs `mix ci` without pdfium install/download or launch artifact regeneration.

## Task Commits

1. **Task 1: Update the advisory status-check registry for launch artifacts** - `93c20b6` (chore)
2. **Task 2: Add negative guardrail tests for required/advisory separation** - `a604660` (test)

## Files Created/Modified

- `priv/guardrails/required_status_checks.json` - Adds the launch artifact check to the advisory raster command and notes.
- `test/guardrails/required_checks_contract_test.exs` - Adds advisory-context, required-job, and raster-job separation assertions.

## Decisions Made

- Kept `mix rendro.launch_artifacts.check` out of required CI and out of the `mix ci` alias.
- Scoped CI assertions to exact job blocks to avoid confusing advisory/live-proof pdfium jobs with the required `test:` job.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `jq -e '.required_contexts == ["long-lived-live-proof", "release-proof", "signing-live-proof", "test"] and (.advisory_contexts[] | select(.name == "raster-advisory") | (.command | contains("mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs")) and (.command | contains("mix rendro.launch_artifacts.check")) and (.notes | contains("Phase 86")) and (.notes | contains("not required")))' priv/guardrails/required_status_checks.json` - passed
- `mix test test/guardrails/required_checks_contract_test.exs` - 14 tests, 0 failures
- `mix test test/docs_contract/raster_claims_test.exs` - 8 tests, 0 failures

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 86-02. The required/advisory CI boundary is locked before strengthening static launch artifact proof.

---
*Phase: 86-self-proving-launch-artifacts*
*Completed: 2026-06-11*

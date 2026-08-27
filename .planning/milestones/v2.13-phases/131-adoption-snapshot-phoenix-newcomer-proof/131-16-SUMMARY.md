---
phase: 131
plan: "16"
status: complete
subsystem: release-provenance
tags: [hexdocs, phoenix, provenance, testing]
requires:
  - phase: 131-18
    provides: verified-v1.3.4-public-prerequisite
provides:
  - fail-closed clean-room prerequisite validation aligned with the public verifier
  - shared canonical-fixture regression for HexDocs durable candidate binding
affects: [131-17, phoenix-clean-room-proof, public-release-verification]
tech-stack:
  added: []
  patterns: [shared committed provenance fixture, fail-closed nested workflow binding]
key-files:
  created: []
  modified:
    - scripts/phoenix_clean_room_proof.exs
    - test/scripts/phoenix_clean_room_proof_test.exs
key-decisions:
  - "The clean-room gate accepts only the current hexdocs_workflow_dispatch provenance route."
  - "Protected-main control identity must agree with the authoritative workflow head and durable candidate binding."
requirements-completed: [JOURNEY-01, JOURNEY-02, JOURNEY-03, JOURNEY-04]
coverage:
  - id: D1
    description: "Clean-room prerequisite acceptance matches the current public release verifier contract."
    requirement: JOURNEY-01
    verification:
      - kind: integration
        ref: "mix test test/scripts/public_release_verifier_test.exs test/scripts/phoenix_clean_room_proof_test.exs --max-failures 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Legacy provenance and malformed durable candidate bindings fail closed before the Phoenix journey runs."
    requirement: JOURNEY-04
    verification:
      - kind: integration
        ref: "test/scripts/phoenix_clean_room_proof_test.exs#shares the current HexDocs workflow-dispatch prerequisite contract with the public verifier"
        status: pass
    human_judgment: false
---

# Phase 131 Plan 16: Clean-Room Provenance Contract Summary

The Phoenix clean-room gate now accepts only the verifier-approved HexDocs workflow-dispatch prerequisite, bound to protected main, the sealed v1.3.4 candidate, and its durable workflow run.

## Performance

- **Duration:** 2 min
- **Started:** 2026-08-25T21:19:15Z
- **Completed:** 2026-08-25T21:21:00Z
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Replaced the retired `protected_release_publish` clean-room route with the current `hexdocs_workflow_dispatch` route.
- Required a numeric run ID, valid lowercase workflow control SHA, successful HexDocs dispatch, and exact protected-main durable binding identities.
- Added one committed canonical fixture exercised by both validators, plus fail-closed legacy and binding-mutation regressions.

## Task Commits

1. **Task 1: Align verifier and clean-room prerequisite acceptance end to end** - `304d99d` (test), `b8ad360` (feat)

## Files Created/Modified

- `scripts/phoenix_clean_room_proof.exs` - Enforces current HexDocs workflow-dispatch and durable-binding provenance before clean-room execution.
- `test/scripts/phoenix_clean_room_proof_test.exs` - Loads the canonical prerequisite and tests shared acceptance plus mutation rejection through both validators.

## Decisions Made

- The clean-room consumer has no compatibility fallback for legacy release-publish provenance.
- The HexDocs workflow control SHA may differ from the candidate, but it must exactly match the durable binding control SHA; requested, peeled, and detached artifact identities must equal the sealed candidate.

## Verification

- `mix test test/scripts/public_release_verifier_test.exs test/scripts/phoenix_clean_room_proof_test.exs --max-failures 1` — passed (43 tests, 0 failures).
- Regression coverage rejects missing binding, non-main control ref, control/artifact/tag/run mismatches, malformed control SHA, wrong workflow event/name, and unsuccessful conclusion.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

An empty disposable temporary directory from the intentionally failing RED test run caused the harness's nonempty-root guard to reject a repeated test. The verified empty directory was removed before the final deterministic run; no repository code or evidence changed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 131-17 can rerun the clean Phoenix journey only from the current verifier-approved prerequisite shape.

## Self-Check: PASSED

- Confirmed both modified files exist.
- Confirmed task commits `304d99d` and `b8ad360` exist in git history.
- Confirmed the focused combined verifier and clean-room test suites pass.

---

*Phase: 131-adoption-snapshot-phoenix-newcomer-proof*
*Completed: 2026-08-25*

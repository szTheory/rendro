---
phase: 136-catalog-visual-quality
plan: "05"
subsystem: catalog-evidence
tags: [catalog, evidence, pdfium, review, provenance, deferral]
requires:
  - phase: 135-test-ci-cd-simplification
    provides: closed exact-SHA Catalog Evidence workflow and bundle validator
  - phase: 136-catalog-visual-quality
    provides: six bounded visual candidate repairs from Plans 01-04
provides:
  - Fail-closed validation of bundle control SHA, run ID, and attempt.
  - Validation-first full-size review runbook with explicit advisory deferral.
  - Phase 136 unreviewed/unpromoted record for unavailable exact-SHA evidence.
affects: [136-06, catalog-canonicalization, catalog-review]
tech-stack:
  added: []
  patterns: [exact immutable provenance before review, advisory deferral without synthetic judgment]
key-files:
  created: []
  modified:
    - dev/rendro/catalog_evidence_bundle.ex
    - .github/workflows/CATALOG-EVIDENCE.md
    - priv/quality/SIGN-OFF.md
    - test/rendro/catalog_evidence_bundle_test.exs
    - test/rendro/catalog_review_payload_contract_test.exs
    - test/docs_contract/catalog_evidence_runbook_test.exs
key-decisions:
  - "A failed remote checkout is explicit unavailable evidence, not an approval or a reason to reuse older score records."
  - "Phase 136 targets stay unreviewed and unpromoted until one complete named review binds to the exact candidate bundle."
patterns-established:
  - "Review eligibility: validate full SHA, HEAD, control, renderer, run, attempt, roles, counts, and hashes before opening images."
requirements-completed: [CATALOG-11, CATALOG-13]
coverage:
  - id: D1
    description: Closed bundle provenance and candidate-quality-field rejection.
    requirement: CATALOG-11
    verification:
      - kind: unit
        ref: mix test test/rendro/catalog_evidence_bundle_test.exs test/rendro/catalog_review_payload_contract_test.exs --max-failures 1
        status: pass
    human_judgment: false
  - id: D2
    description: Validation-first review runbook and documented non-blocking deferral.
    requirement: CATALOG-13
    verification:
      - kind: unit
        ref: mix test test/docs_contract/catalog_evidence_runbook_test.exs test/docs_contract/rubric_manifest_contract_test.exs --max-failures 1
        status: pass
    human_judgment: false
  - id: D3
    description: Advisory full-size visual evaluation of the six target cells.
    requirement: CATALOG-13
    verification: []
    human_judgment: true
    rationale: No remote-reachable exact candidate bundle or named reviewer record was available; the explicit deferral preserves this as unpromoted evidence.
duration: 9min
completed: 2026-08-28
status: complete
---

# Phase 136 Plan 05: Validation-First Catalog Review Summary

**Fail-closed exact-SHA review intake with a truthful, unpromoted deferral when the remote candidate bundle cannot be produced.**

## Performance

- **Duration:** 9 min
- **Completed:** 2026-08-28T03:32:45Z
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Enforced positive run identity/attempt and control-SHA validation for closed evidence bundles, while preserving rejection of candidate-authored quality fields.
- Added all validation-first review states, full-size-only locked family order, and exact no-evidence continuation behavior to the Catalog Evidence runbook.
- Dispatched exact candidate review run `33139093669`; it failed before checkout because the remote does not contain `d547bbfa60760d43f19a15372d88a2d159bfa327`. The six Phase 136 targets remain unreviewed and unpromoted with a bounded next action.

## Task Commits

1. **Task 1: Validate one exact-SHA bundle before any image interpretation** — `2a8fd18` (RED tests), `77cdb06` (implementation).
2. **Task 2: Intake named advisory scores or continue with explicit deferral** — `60e5d9f` (explicit deferral).

## Files Created/Modified

- `dev/rendro/catalog_evidence_bundle.ex` — validates exact control/run/attempt provenance.
- `.github/workflows/CATALOG-EVIDENCE.md` — documents validation states and advisory score intake.
- `priv/quality/SIGN-OFF.md` — records the unavailable candidate evidence and next action without overwriting historical review records.
- `test/rendro/catalog_evidence_bundle_test.exs` — covers invalid bundle provenance.
- `test/rendro/catalog_review_payload_contract_test.exs` — covers uppercase/truncated candidate identities.
- `test/docs_contract/catalog_evidence_runbook_test.exs` — locks the validation-first review contract.

## Decisions Made

- Historical Phase 130 score records remain bound to their own immutable evidence and were not re-associated with Phase 136.
- The failed dispatch is an explicit deferral: publish the exact candidate object to a remote-reachable ref, then dispatch, validate, and obtain named reviewer records before any canonical promotion.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Closed manifest validation did not reject missing/invalid control SHA, run ID, or run attempt.**
- **Found during:** Task 1
- **Fix:** Added fail-closed validation and deterministic coverage for those provenance fields.
- **Files modified:** `dev/rendro/catalog_evidence_bundle.ex`, `test/rendro/catalog_evidence_bundle_test.exs`
- **Verification:** Targeted bundle/payload/runbook tests pass.
- **Committed in:** `77cdb06`

**Total deviations:** 1 auto-fixed (Rule 2).

## Issues Encountered

- Review dispatch `33139093669` failed before candidate checkout: GitHub could not fetch the local-only candidate SHA. This is recorded as advisory evidence unavailable, not a failed visual score.

## Next Phase Readiness

- Plan 06 must treat the six targets as canonical-ineligible and preserve canonical assets.
- To revisit: publish `d547bbfa60760d43f19a15372d88a2d159bfa327` to a remote-reachable ref, dispatch a new `review` workflow, validate its one closed bundle, and obtain six complete named records or append actual misses.

## Self-Check: PASSED

- Task commits `2a8fd18`, `77cdb06`, and `60e5d9f` exist.
- All six documented files exist; no reviewer score or approval was fabricated.

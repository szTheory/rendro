---
phase: 71-record-new-trust-sensitive-surfaces-and-explicit-deferrals
plan: 03
subsystem: docs-contract
tags: [viewer-evidence, support-matrix, changelog, api-stability]

requires: [71-02]
provides:
  - All 20 Phase 71 trust-sensitive cells terminal in priv/support_matrix.json
  - api_stability mirrors and signing-prep equivalence note
  - Appendix B deferral templates in guides/viewer_evidence.md
  - CHANGELOG Phase 71 bullets and extended docs-contract tests
affects: [72]

tech-stack:
  added: []
  patterns:
    - "Atomic D-01 closure: evidence + matrix + docs in one PR"

key-files:
  modified:
    - priv/support_matrix.json
    - guides/api_stability.md
    - guides/viewer_evidence.md
    - CHANGELOG.md
    - .github/workflows/ci.yml
    - lib/mix/tasks/rendro/viewer_evidence.ex
    - test/docs_contract/viewer_evidence_claims_test.exs
    - test/docs_contract/signing_claims_test.exs
    - test/docs_contract/forms_claims_test.exs
    - test/docs_contract/embedded_artifact_claims_test.exs
    - test/docs_contract/protection_claims_test.exs

key-decisions:
  - "embedded_files×apple_preview demoted from unverified to explicit_deferral with named reason"
  - "viewer-evidence-live-proof CI job extended with pyhanko-cli and Phase 71 live tests"

requirements-completed: [VIEWER-02, VIEWER-03, VIEWER-04, VIEWER-05, VIEWER-06, VIEWER-07]

duration: 45min
completed: 2026-05-29
---

# Phase 71 Plan 03 Summary

**Atomic public-contract closure: matrix terminal states, api_stability mirrors, CHANGELOG, and docs-contract green.**

## Accomplishments

- Updated priv/support_matrix.json — 20 trust-sensitive cells terminal (supported or explicit_deferral)
- Added signing-preparation × signature-widget equivalence note to api_stability.md
- Added Appendix B deferral templates (UPSTREAM_ISSUE, NO_SIG_VALIDATION, NO_LTV_INDICATORS, SURFACE_EQUIVALENCE)
- Extended CHANGELOG with Phase 71 promotion and deferral bullets
- Updated five docs-contract test modules for terminal matrix posture
- Extended viewer-evidence-live-proof CI job with pyhanko and Phase 71 test files

## Verification

- `grep -c '"status": "unverified"' priv/support_matrix.json` → 0
- `mix rendro.viewer_evidence missing` → empty
- `mix rendro.viewer_evidence validate` → passed
- `mix docs.contract` → 8/8 lanes PASS

## Deviations

None — plan executed as specified with structural-proxy model from amended 71-CONTEXT.

## Next

Phase 72 closure audit, polish, and ship.

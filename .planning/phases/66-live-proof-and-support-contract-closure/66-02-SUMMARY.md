---
phase: 66-live-proof-and-support-contract-closure
plan: "02"
subsystem: docs
tags: [support-contract, docs-contract, support-matrix, api-stability]
requires:
  - phase: 66-live-proof-and-support-contract-closure
    plan: "01"
    provides: proof-backed long-lived live lane
provides:
  - nested signing.long_lived support taxonomy
  - exact long-lived guide wording with canonical local and CI recipes
  - docs-contract lock on long-lived trust and compliance boundaries
affects: [TRUST-07, TRUST-08]
tech-stack:
  added: []
  patterns: [nested support taxonomies, prose-plus-matrix lockstep, executable claim regression]
key-files:
  created: []
  modified:
    - guides/api_stability.md
    - priv/support_matrix.json
    - test/docs_contract/signing_claims_test.exs
key-decisions:
  - "Publish long-lived evidence as `signing.long_lived` rather than a new top-level family."
  - "Document one exact local recipe and one exact CI recipe, both downstream of the same live-proof command."
  - "Keep trust, viewer posture, and blanket compliance claims visibly separate from timestamp and revocation evidence posture."
requirements_completed: [TRUST-07, TRUST-08]
duration: 20 min
completed: 2026-05-07
---

# Phase 66 Plan 02: Support Contract Summary

**Nested long-lived taxonomy, exact operator recipes, and executable docs lockstep**

## Performance

- **Duration:** 20 min
- **Tasks:** 2
- **Commits:** 0

## Accomplishments

- Added a dedicated `Long-Lived Evidence Support Boundary` section to the API stability guide with one exact `sign -> augment -> validate` story.
- Published long-lived evidence as a first-class `signing.long_lived` subtree in `priv/support_matrix.json`.
- Locked the guide and matrix together with updated docs-contract assertions that reject viewer promotion, signer-trust ownership, LT/LTA wording, and blanket compliance drift.

## Verification

- `mix test test/docs_contract/signing_claims_test.exs`
- `mix docs.contract`

## Deviations from Plan

None. `scripts/verify_docs.exs` already ran the signing lane cleanly, so no lane-name change was required.

## User Setup Required

None for the docs surface. The only remaining manual checkpoint for the phase is the repository required-check update recorded in `66-VALIDATION.md`.

## Next Phase Readiness

- The public support contract now names exactly the path proven in `66-01`.
- Phase 66 can be marked complete once tracking files reflect the closed requirements and the required-check policy is updated after push.

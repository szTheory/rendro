---
phase: 57
plan: 01
subsystem: docs
tags: [forms, signatures, support-matrix, docs-contract]
requires:
  - phase: 56-02
    provides: rendered unsigned signature widgets and the artifact-first signing-preparation seam
provides:
  - machine-readable unsigned-widget and signing-preparation support metadata
  - public API-stability wording that separates unsigned widgets from signing preparation and unsupported signing narratives
  - docs-contract coverage for the new signature support vocabulary
affects: [57-02, v2.0-closeout, docs-contract]
key-files:
  created:
    - test/docs_contract/signing_claims_test.exs
  modified:
    - priv/support_matrix.json
    - guides/api_stability.md
    - scripts/verify_docs.exs
    - test/docs_contract/forms_claims_test.exs
    - test/docs_contract/embedded_artifact_claims_test.exs
completed: 2026-05-07
---

# Phase 57 Plan 01 Summary

**Published the narrow public signature support contract as two separate surfaces: unsigned signature widgets and artifact-first signing preparation.**

## Accomplishments

- Promoted `forms.widgets.signature` to a rendered unsigned-widget contract without widening into digital-signature or viewer-support claims.
- Added a sibling `signing_preparation` family with explicit supported preparation leaves and explicit unsupported trust/compliance leaves.
- Rewrote the signing portion of `guides/api_stability.md` around one short lifecycle preamble plus separate unsigned-widget and signing-preparation sections.
- Added a dedicated signing docs-contract lane and repaired one stale cross-lane assertion in the embedded-artifact test that still froze the old pre-Phase-57 signature posture.

## Verification

- `mix test test/docs_contract/forms_claims_test.exs test/docs_contract/signing_claims_test.exs`
- `mix run scripts/verify_docs.exs`

## Deviations from Plan

- The embedded-artifact docs-contract lane needed a small in-scope update because it still asserted the old `forms.widgets.signature = unsupported` value. The fix narrowed that stale assertion without widening embedded-artifact scope.

## Self-Check: PASSED

- The support matrix, guide, and docs-contract lanes now publish the same signature vocabulary.
- The docs verification runner includes the new signing lane and passes end-to-end.

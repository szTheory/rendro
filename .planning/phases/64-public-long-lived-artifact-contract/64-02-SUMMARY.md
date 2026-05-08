---
phase: 64
plan: 02
subsystem: signing
tags: [signing, long-lived, metadata, redaction, determinism]
requires:
  - phase: 64-public-long-lived-artifact-contract
    provides: augment seam and typed `:augment` failures
provides:
  - canonical `metadata.long_lived` posture contract
  - canonical `metadata.long_lived_adapter` allowlist
  - deterministic-vs-augmented proof coverage
affects: [SIGN-08, SIGN-09, long-lived-signing, artifact-metadata]
tech-stack:
  added: []
  patterns:
    - posture-only shared long-lived metadata
    - explicit adapter-metadata allowlist
key-files:
  created: []
  modified:
    - lib/rendro/sign.ex
    - test/rendro/sign_test.exs
key-decisions:
  - Persist shared long-lived posture under `metadata.long_lived` and keep tool-shaped facts under `metadata.long_lived_adapter`.
  - Allowlist only `:tool`, `:tool_family`, `:evidence_profile`, `:timestamp_authority`, `:revocation_sources`, and `:passphrase_supplied` in persisted adapter metadata.
  - Keep docs/support files unchanged in Phase 64 and prove that deferral by running the docs-contract lane.
requirements-completed: [SIGN-08, SIGN-09]
completed: 2026-05-08
---

# Phase 64 Plan 02: Long-Lived Metadata Posture Summary

Locked the canonical long-lived artifact metadata contract so augmented artifacts now expose posture-only shared metadata, separate sanitized adapter details, and explicit non-determinism without widening support-surface claims.

## Outcomes

- Successful `Rendro.Sign.augment/2` calls now persist `metadata.long_lived` and `metadata.long_lived_adapter` instead of the earlier provisional key shape.
- Shared metadata now carries only augmentation posture fields, while adapter-local persisted facts are restricted to the plan’s explicit allowlist.
- Regression coverage now proves augmented bytes and hashes differ from the source signed artifact, `metadata.deterministic` remains `false`, and secrets/tool output stay out of both shared and adapter-local metadata.
- The docs-contract lane stays green without touching support-copy files, proving Phase 64 remained runtime-only as planned.

## Deviations from Plan

No functional deviations. Existing `64-01` augment-stage error coverage was sufficient, so no additional runtime behavior changes were needed outside the metadata contract and proof updates.

## Verification

- `mix test test/rendro/sign_test.exs`
- `mix test test/rendro/sign_test.exs test/rendro/error_test.exs test/docs_contract/signing_claims_test.exs`

## Task Commits

1. `eb23a70` `feat(64-02): narrow long-lived artifact metadata`

## Self-Check: PASSED

- Verified the canonical long-lived metadata keys and allowlist are persisted on augmented artifacts only.
- Verified deterministic-vs-augmented behavior and docs-contract deferral through focused automated lanes.

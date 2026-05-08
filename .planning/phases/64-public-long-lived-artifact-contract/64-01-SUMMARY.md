---
phase: 64
plan: 01
subsystem: signing
tags: [signing, long-lived, api-contract, redaction, errors]
requires:
  - phase: 60-public-cryptographic-signing-contract
    provides: signed artifact seam and sign-stage error contract
provides:
  - explicit `Rendro.Sign.augment/2` post-sign seam
  - typed redacted `:augment`-stage failures
  - signed-artifact-only augmentation preflight
affects: [SIGN-07, SIGN-08, long-lived-signing, error-contract]
tech-stack:
  added: []
  patterns:
    - artifact-first post-sign augmentation seam
    - typed redacted augmentation failures
key-files:
  created: []
  modified:
    - lib/rendro/sign.ex
    - lib/rendro/sign/adapter.ex
    - lib/rendro/error.ex
    - test/rendro/sign_test.exs
    - test/rendro/error_test.exs
key-decisions:
  - Keep long-lived augmentation as a separate `Rendro.Sign.augment/2` API instead of widening `sign/2` or render semantics.
  - Reject unsigned, prepared, unsupported, and already-augmented artifacts in core before any augmentation adapter callback runs.
  - Restrict public augment failure details to artifact posture, adapter identity, and adapter option keys.
requirements-completed: [SIGN-07, SIGN-08]
completed: 2026-05-07
---

# Phase 64 Plan 01: Long-Lived Augment Seam Summary

Implemented a signed-artifact-only `Rendro.Sign.augment/2` seam with typed `:augment` errors and preflight rejection/redaction rules that keep long-lived augmentation separate from core render and sign semantics.

## Outcomes

- `Rendro.Sign.augment/2` now exists as the explicit post-sign entrypoint and validates adapter presence, callback support, and adapter option shape before execution.
- Core artifact guards now reject unsigned, prepared, unsupported, and already-augmented artifacts before any long-lived adapter callback fires.
- `Rendro.Error` now emits augment-specific `what/why/next` wording so public failures do not reuse preparation, signing, or protection guidance.
- Regression coverage now proves the public augment contract, unsupported-state rejection path, and redaction boundary for adapter failures.

## Deviations from Plan

No functional deviations. Execution required a manual orchestrator fallback because the local `gsd-sdk` install does not expose the workflow `query` interface expected by the skill.

## Verification

- `mix test test/rendro/sign_test.exs`
- `mix test test/rendro/sign_test.exs test/rendro/error_test.exs`

## Task Commits

1. `03ffae6` `test(64-01): add augment contract coverage`
2. `9f4d8a5` `feat(64-01): add signed-artifact augment seam`

## Self-Check: PASSED

- Verified augment preflight blocks unsupported artifact states before adapter execution.
- Verified augment-stage wording and redaction coverage through focused sign/error ExUnit lanes.

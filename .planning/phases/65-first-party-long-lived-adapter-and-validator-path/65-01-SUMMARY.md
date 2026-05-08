---
phase: 65-first-party-long-lived-adapter-and-validator-path
plan: 01
subsystem: signing
tags: [signing, pyhanko, long-lived, augmentation, redaction]
requires:
  - phase: 64-public-long-lived-artifact-contract
    provides: explicit `Rendro.Sign.augment/2` seam and long-lived metadata posture
provides:
  - first-party pyHanko augmentation callback
  - narrow adapter-local timestamp plus revocation option schema
  - temp-file-safe and redaction-safe augmentation proof coverage
affects: [ADAPT-07, long-lived-signing, adapter-runtime-boundary]
tech-stack:
  added: []
  patterns:
    - reusable pyHanko runtime boundary across sign and augment
    - posture-only long-lived metadata with adapter-local allowlist
key-files:
  created: []
  modified:
    - lib/rendro/adapters/py_hanko.ex
    - lib/rendro/error.ex
    - test/rendro/adapters/py_hanko_test.exs
    - test/rendro/error_test.exs
    - test/rendro/sign_test.exs
key-decisions:
  - Keep the first shipped long-lived path on `Rendro.Sign.augment/2` only; no new public long-lived options were added to `Rendro.Sign.sign/2`.
  - Require one narrow adapter-local schema centered on `:tsa_url` and `:trust_roots`, with optional supporting inputs kept fully adapter-local.
  - Reuse the signing adapter's private temp-dir, injected executable lookup, and redacted failure posture for augmentation instead of inventing a second runtime boundary.
requirements-completed: [ADAPT-07]
completed: 2026-05-08
---

# Phase 65 Plan 01: First-Party Long-Lived Augmentation Summary

Shipped the first proof-backed pyHanko augmentation path so Rendro can extend an already signed artifact with timestamp and revocation evidence through one explicit optional adapter seam.

## Outcomes

- `Rendro.Adapters.PyHanko` now implements `augment/2` with a narrow adapter-local schema and the same private temp-file and injected-runner safety posture used by signing.
- Successful augmentation returns only the shared posture fields needed by Phase 64 (`timestamp`, `revocation`, `compliance_evidence`) plus a small adapter-local allowlist.
- Regression coverage now proves CLI shaping, cleanup on failure, missing-option classification, and public-seam redaction for the first-party adapter path.

## Deviations from Plan

No functional deviations. The implementation kept tool vocabulary adapter-local and deferred live pyHanko proof exactly as planned.

## Verification

- `mix test test/rendro/adapters/py_hanko_test.exs test/rendro/sign_test.exs test/rendro/error_test.exs`

## Self-Check: PASSED

- Verified augmentation remains explicit on `Rendro.Sign.augment/2`.
- Verified secrets, temp paths, and raw stderr stay out of public errors and persisted metadata.
- Verified missing or malformed adapter-local inputs fail before command execution.

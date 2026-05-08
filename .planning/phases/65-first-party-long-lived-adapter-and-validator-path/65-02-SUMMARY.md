---
phase: 65-first-party-long-lived-adapter-and-validator-path
plan: 02
subsystem: signing
tags: [signing, pyhanko, validation, compliance, posture]
requires:
  - phase: 65-first-party-long-lived-adapter-and-validator-path
    provides: first-party pyHanko augmentation path and long-lived metadata precedent
provides:
  - pyHanko-backed validation posture path
  - explicit timestamp and revocation fields on signature validation output
  - narrow embedded-validation-evidence compliance map
affects: [ADAPT-08, validate-surface, support-contract-proof]
tech-stack:
  added: []
  patterns:
    - compact `%{adapter, signatures}` validation envelope with explicit evidence posture
    - integrity-first `validate/2` and trust-explicit `validate_trust/2`
key-files:
  created:
    - priv/support/pyhanko_validate.py
  modified:
    - lib/rendro/adapters/py_hanko.ex
    - lib/rendro/error.ex
    - lib/rendro/sign.ex
    - test/rendro/adapters/pdfsig_test.exs
    - test/rendro/adapters/py_hanko_test.exs
    - test/rendro/error_test.exs
    - test/rendro/sign_test.exs
key-decisions:
  - Preserve `%{adapter, signatures}` while extending each signature with explicit `timestamp`, `revocation`, and `compliance` posture.
  - Keep compliance wording narrow under `scope: :embedded_validation_evidence` with `level: :present | :incomplete | :not_assessed`.
  - Freeze `pdfsig` as the integrity/trust-only validator and route long-lived evidence classification through the pyHanko adapter path.
requirements-completed: [ADAPT-08]
completed: 2026-05-08
---

# Phase 65 Plan 02: Long-Lived Validation Posture Summary

Extended the public validation seam so Rendro can report integrity, trust, timestamp presence, revocation evidence, and narrow embedded-evidence compliance posture without widening into blanket compliance claims.

## Outcomes

- `Rendro.Sign.validate/2` and `validate_trust/2` now return explicit `timestamp`, `revocation`, and `compliance` fields on every signature while preserving the compact `%{adapter, signatures}` envelope.
- `Rendro.Adapters.PyHanko.validate/2` now normalizes machine-readable helper output into stable posture facts, and `pdfsig` tests lock its narrower role.
- Public error wording and regression coverage now keep the new validator path redacted and stage-specific.

## Deviations from Plan

No functional deviations. The helper file is present as the stable integration seam, while live pyHanko proof remains deferred to Phase 66.

## Verification

- `mix test test/rendro/adapters/py_hanko_test.exs test/rendro/adapters/pdfsig_test.exs test/rendro/error_test.exs`
- `mix test test/rendro/adapters/py_hanko_test.exs test/rendro/adapters/pdfsig_test.exs test/rendro/sign_test.exs test/rendro/error_test.exs test/docs_contract/signing_claims_test.exs`

## Self-Check: PASSED

- Verified `validate/2` keeps trust skipped by default while preserving evidence posture.
- Verified `validate_trust/2` changes only the trust signal.
- Verified compliance remains evidence-oriented and does not expose signer identity or blanket compliance language.

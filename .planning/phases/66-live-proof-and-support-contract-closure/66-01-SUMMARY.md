---
phase: 66-live-proof-and-support-contract-closure
plan: "01"
subsystem: signing
tags: [pyhanko, pdfsig, certomancer, live-proof, ci]
requires:
  - phase: 65-first-party-long-lived-adapter-and-validator-path
    provides: pyhanko-backed sign-augment-validate seams
provides:
  - offline long-lived live proof over the public Rendro signing seam
  - dedicated long-lived live-proof CI gate
  - certomancer-backed local TSA and revocation fixture infrastructure
affects: [ADAPT-09]
tech-stack:
  added: [certomancer]
  patterns: [offline localhost PKI fixtures, helper-backed validation, integrity-first fallback parsing]
key-files:
  created:
    - test/fixtures/signing/certomancer/certomancer.yml
  modified:
    - priv/support/pyhanko_validate.py
    - lib/rendro/adapters/py_hanko.ex
    - lib/rendro/adapters/pdfsig.ex
    - test/rendro/adapters/signing_live_test.exs
    - .github/workflows/ci.yml
key-decisions:
  - "Use a localhost certomancer PKI/TSA/OCSP service so the required long-lived proof remains offline and reproducible."
  - "Keep pyHanko authoritative for timestamp, revocation, and embedded-validation-evidence posture while treating pdfsig as secondary integrity-only confirmation."
  - "Parse pdfsig output even on non-zero exit when signature blocks are present, since host trust-store issues do not invalidate integrity facts."
requirements_completed: [ADAPT-09]
duration: 65 min
completed: 2026-05-07
---

# Phase 66 Plan 01: Live Proof Summary

**Offline long-lived proof lane, helper/runtime correction, and dedicated CI gating**

## Performance

- **Duration:** 65 min
- **Tasks:** 3
- **Commits:** 2

## Accomplishments

- Finished the pyHanko validation helper so it emits stable timestamp, revocation, and compliance-evidence facts from real DSS and document-timestamp data.
- Corrected the pyHanko runtime integration to match the real `ltvfix` CLI shape and kept helper JSON isolated from stderr noise.
- Added an offline `live_pdf_tools` proof that stands up a localhost certomancer PKI, signs a runtime-generated artifact, augments it, validates it through `Rendro.Sign.validate/2`, and checks secondary `pdfsig` integrity parity.
- Replaced the old `signing-live-proof` CI lane with a dedicated `long-lived-live-proof` job that provisions pyHanko, certomancer, and pdfsig without widening deterministic `mix ci`.

## Verification

- `mix test test/rendro/adapters/py_hanko_test.exs test/rendro/error_test.exs`
- `mix test test/rendro/adapters/pdfsig_test.exs test/rendro/adapters/py_hanko_test.exs test/rendro/sign_test.exs`
- `PATH=/tmp/rendro-certomancer-venv/bin:$PATH mix test --include live_pdf_tools test/rendro/adapters/signing_live_test.exs`
- `rg -n "long-lived-live-proof:|needs: test|mix ci|live_pdf_tools|pyhanko|pdfsig|certomancer" .github/workflows/ci.yml`

## Commits

| Commit | Purpose |
|--------|---------|
| `4b3f134` | finalize pyHanko helper payload and adapter-side evidence classification |
| `3fe889e` | add offline certomancer-backed live proof lane and dedicated CI job |

## Deviations from Plan

None in scope. The only manual checkpoint remains repository required-check enforcement after the workflow is pushed.

## User Setup Required

- Update branch protection or repository rulesets so `long-lived-live-proof` is a required status check after this branch lands.

## Next Phase Readiness

- The exact proof-backed long-lived path now exists and is operationally isolated.
- `66-02` can now publish the nested support contract and docs assertions downstream of this evidence.

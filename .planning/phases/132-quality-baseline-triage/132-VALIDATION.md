---
phase: 132
slug: quality-baseline-triage
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-26
validated: 2026-08-26
---

# Phase 132 — Validation Strategy

> Terminal Nyquist contract: deterministic checks establish completion; advisory and explicit-deferral evidence preserves authority boundaries without becoming a completion gate.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit bundled with Elixir 1.19.5 and Node built-in test runner |
| Focused baseline | `mix quality.baseline` |
| Governance fixtures | `node --test scripts/quality_governance.cjs` |
| CI topology | `mix test test/guardrails/required_checks_contract_test.exs` |
| Full deterministic lane | `mix ci.fast` |

`mix ci.proofs` and `mix ci.advisory` retain their own evidence authority. Their unavailable remote or renderer evidence is recorded as explicit deferral and cannot satisfy or block an automated Phase 132 claim.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Automated Command | File Status | Status |
|---------|------|------|-------------|------------|-------------------|-------------|--------|
| 132-01-01 | 01 | 0 | AUDIT-02, AUDIT-03 | T-132-01, T-132-03 | `mix quality.baseline` | present | ✅ green |
| 132-01-02 | 01 | 0 | AUDIT-01 | T-132-01, T-132-02, T-132-04 | `mix quality.baseline` | present | ✅ green |
| 132-01-03 | 01 | 0 | AUDIT-02, AUDIT-03, AUDIT-04 | T-132-03 | `mix quality.baseline` | present | ✅ green |
| 132-02-01 | 02 | 1 | AUDIT-01, AUDIT-04 | T-132-02, T-132-04 | `mix quality.baseline` | present | ✅ green |
| 132-02-02 | 02 | 1 | AUDIT-02, AUDIT-03, AUDIT-04 | T-132-01, T-132-03 | `mix quality.baseline` | present | ✅ green |
| 132-03-01 | 03 | 2 | AUDIT-01, AUDIT-02 | T-132-G01, T-132-G02 | `node --test scripts/quality_governance.cjs && mix quality.baseline` | present | ✅ green |
| 132-03-02 | 03 | 2 | AUDIT-02, AUDIT-03, AUDIT-04 | T-132-G03, T-132-G04, T-132-G05 | `mix quality.baseline && node --test scripts/quality_governance.cjs && mix format --check-formatted mix.exs test/quality/baseline_ledger_contract_test.exs` | present | ✅ green |
| 132-04-01 | 04 | 3 | AUDIT-01, AUDIT-02, AUDIT-03, AUDIT-04 | T-132-G08, T-132-G09 | `mix test test/guardrails/required_checks_contract_test.exs` | present | ✅ green |
| 132-04-02 | 04 | 3 | AUDIT-01, AUDIT-02, AUDIT-03, AUDIT-04 | T-132-G06, T-132-G07 | `mix quality.baseline && node --test scripts/quality_governance.cjs && mix test test/guardrails/required_checks_contract_test.exs && node scripts/quality_governance.cjs --check-active --allow-stale-verification-sha 1ade3d2f9e772ff2871253c435662fb33b146d13f61c54d8422e2ec7d13b2dfd --allow-stale-verification-source-commit be640780df7852387b493b392b7eb148308ea01b` | present | ✅ green |

## Advisory and Explicit Deferral

| Evidence | Authority | Completion Semantics | Reason and Next Action |
|----------|-----------|----------------------|------------------------|
| Remote primary CI and GitHub artifact evidence | pinned remote CI | explicit deferral | Local execution cannot fabricate remote authority; collect a source-SHA-bound run or artifact when the applicable CI route executes. |
| Pinned PDFium and visual review evidence | proof/advisory | explicit deferral | Local PDFium absence remains unavailable; rerun the documented proof/advisory lane in an environment with the pinned renderer. |
| Qualitative maintainer feedback | human-review evidence | advisory | It may enrich later disposition review but does not satisfy or block Phase 132's deterministic structural claims. |

## Threat Model References

- **T-132-01 through T-132-04:** schema, identity, authority lane, closure, and redaction invariants are exercised by `mix quality.baseline`.
- **T-132-G01 through T-132-G05:** closed Node fixtures and bounded record/consumer mutations are exercised by `node --test scripts/quality_governance.cjs` and the focused contract.
- **T-132-G06 through T-132-G07:** exact task evidence and the staged stale-verifier handoff reject remaining active artifact blockers.
- **T-132-G08 through T-132-G09:** parsed workflow/registry topology keeps governance fail-closed in the `ci-success` roll-up while branch protection remains exactly `ci-success`.

## Validation Sign-Off

- [x] Every Plan 132 task has an executed automated command and a green verification row.
- [x] Deterministic, proof, advisory, and human-review authority remain separate.
- [x] The immutable initial snapshot is verified before and after focused validation.
- [x] `nyquist_compliant: true` and `wave_0_complete: true` record terminal automated validation.

**Approval:** automated validation complete

---
phase: 08
slug: bounded-async-timeout-telemetry
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
updated: 2026-04-28
---

# Phase 08 — Validation Strategy

> Per-phase validation contract for the Phase 14 artifact backfill of bounded async and timeout telemetry.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + docs-contract regression tests + verification artifact grep |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/policy_test.exs test/rendro/adapters/threadline_test.exs test/docs_contract/integrations_claims_test.exs` |
| **Full suite command** | `mix test test/rendro/policy_test.exs test/rendro/adapters/threadline_test.exs test/docs_contract/integrations_claims_test.exs` plus artifact grep checks |
| **Estimated runtime** | ~60-120 seconds |

---

## Sampling Rate

- After every task commit: run the current policy, Threadline, and docs-contract proof set plus artifact grep checks.
- After every plan wave: confirm `08-VERIFICATION.md` and `08-01-SUMMARY.md` still agree on which requirements are actually `Done`.
- Before `$gsd-verify-work`: re-check that the timeout-audit gap is still documented as a mixed verdict rather than silently promoted to `Done`.
- Max feedback latency: 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-02 | 01 | 1 | ADPT-04, ADPT-05, OBS-02, OBS-04 | T-14-02 / T-14-03 | Phase 08 artifact verdicts distinguish proven metrics correlation from currently partial Oban-bound and timeout-audit claims, and summary metadata derives from those final verdicts only. | integration + docs parity | `mix test test/rendro/policy_test.exs test/rendro/adapters/threadline_test.exs test/docs_contract/integrations_claims_test.exs && rg -n "^## Requirement: ADPT-04$|^## Requirement: ADPT-05$|^## Requirement: OBS-02$|^## Requirement: OBS-04$|requirements_completed:|OBS-02|OBS-04" .planning/phases/08-bounded-async-timeout-telemetry/08-VERIFICATION.md .planning/phases/08-bounded-async-timeout-telemetry/08-01-SUMMARY.md .planning/phases/08-bounded-async-timeout-telemetry/08-VALIDATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ mixed*

---

## Wave 0 Requirements

- [x] `test/rendro/policy_test.exs` exists as the current proof for `max_pages`, `max_bytes`, and `timeout` enforcement.
- [x] `test/rendro/adapters/threadline_test.exs` exists as the current proof for correlated render metadata.
- [x] `test/docs_contract/integrations_claims_test.exs` exists as the current truthful timeout-limitation proof surface.
- [x] `lib/rendro/adapters/oban/render_worker.ex` exists for direct verification of the present async worker behavior.

---

## Manual-Only Verifications

None. This backfill relies entirely on current committed proof surfaces, including committed proof that some original Phase 08 claims remain only partially closed.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all proof surfaces referenced in `08-VERIFICATION.md`
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated coverage complete; mixed verdicts are intentional and reflect the current executable proof


---
phase: 09
slug: ci-and-release-hardening
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
updated: 2026-04-28
---

# Phase 09 — Validation Strategy

> Nyquist validation contract for the Phase 09 quality-chain re-verification backfill.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix task integration commands + committed proof artifacts |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/verify_test.exs test/mix/tasks/ci_alias_contract_test.exs test/mix/tasks/docs_contract_task_test.exs test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs` |
| **Full suite command** | `mix test ...`, `mix docs.contract`, and artifact grep checks over `09-VERIFICATION.md`, `09-VALIDATION.md`, and the corrected summaries |
| **Estimated runtime** | ~30-90 seconds |

---

## Sampling Rate

- **After every task commit:** Run the narrowest Phase 09 regression suite plus artifact grep checks for the updated files.
- **After every plan wave:** Run `mix docs.contract` and confirm the re-verification artifact still points at the authoritative Phase 12 and 13 proof surfaces.
- **Before `$gsd-verify-work`:** Re-run the full Phase 09 backfill proof set, including the synthetic exact-tag release helper regression tests.
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-02-01 | 02 | 1 | QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05 | T-14-04 | `09-VERIFICATION.md` cites later proof directly so current milestone truth comes from committed Phase 12 and 13 evidence instead of stale Phase 09 narrative. | targeted regression + artifact grep | `mix test test/mix/tasks/verify_test.exs test/mix/tasks/ci_alias_contract_test.exs test/mix/tasks/docs_contract_task_test.exs test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs && mix docs.contract && rg -n "12-VERIFICATION.md|13-VERIFICATION.md|Re-verification" .planning/phases/09-ci-and-release-hardening/09-VERIFICATION.md` | ✅ | ✅ green |
| 14-02-02 | 02 | 1 | QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05 | T-14-05 / T-14-06 | The Nyquist contract and both corrected summaries keep the authoritative proof chain explicit, including the synthetic exact-tag `release-proof` path for `QUAL-04`. | artifact contract + targeted regression | `rg -n "phase: 09|nyquist_compliant: true|Per-Task Verification Map|requirements_completed:|09-VERIFICATION.md|re-verification|QUAL-04|release-proof|current-version-tag" .planning/phases/09-ci-and-release-hardening/09-VALIDATION.md .planning/phases/09-ci-and-release-hardening/09-01-SUMMARY.md .planning/phases/09-ci-and-release-hardening/09-02-SUMMARY.md && test ! -f .planning/phases/09-ci-and-release-hardening/VALIDATION.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `09-VERIFICATION.md` exists and cites `12-VERIFICATION.md` plus `13-VERIFICATION.md` directly.
- [x] A Nyquist-format validation file now exists under the phase-prefixed filename `09-VALIDATION.md`.
- [x] The old prose-only `VALIDATION.md` filename is retired.
- [x] The synthetic exact-tag `QUAL-04` proof remains explicit through committed helper and CI evidence, not through active-workspace release state.

---

## Manual-Only Verifications

None. The exact-tag release happy path is already automated through `scripts/release_preflight_proof.exs --current-version-tag`, its regression tests, and the hosted `release-proof` CI job documented in Phase 13.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or committed proof-surface dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers the renamed validation artifact and summary metadata drift
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated coverage complete; Phase 09 milestone truth now routes through later committed re-verification evidence

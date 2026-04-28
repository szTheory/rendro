---
phase: 07
slug: phoenix-adapter-hardening
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
updated: 2026-04-28
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for the Phase 14 artifact backfill of Phoenix adapter hardening.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix compile checks + verification artifact grep |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/adapters/phoenix_test.exs test/rendro/error_test.exs test/rendro/pipeline_test.exs` |
| **Full suite command** | `mix compile --no-optional-deps --warnings-as-errors`, `mix test test/rendro/adapters/phoenix_test.exs test/rendro/error_test.exs test/rendro/pipeline_test.exs`, plus artifact grep checks |
| **Estimated runtime** | ~60-120 seconds |

---

## Sampling Rate

- After every task commit: run the Phoenix boundary suite plus the smallest requirement-specific command set for structured-error evidence and artifact grep checks.
- After every plan wave: rerun the compile check for optional-dependency proof and verify the summary metadata still matches `07-VERIFICATION.md`.
- Before `$gsd-verify-work`: confirm `QUAL-03` still points at current Phase 12 hosted proof and that no manual-only proof remains.
- Max feedback latency: 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | ADPT-01, ADPT-02, ADPT-03, OBS-03, QUAL-03 | T-14-01 / T-14-03 | Phase 07 artifact verdicts cite current Phoenix boundary and hosted-CI proof only, and summary metadata derives from the final verification statuses. | integration + compile + docs parity | `mix compile --no-optional-deps --warnings-as-errors && mix test test/rendro/adapters/phoenix_test.exs test/rendro/error_test.exs test/rendro/pipeline_test.exs && rg -n "^## Requirement: ADPT-01$|^## Requirement: ADPT-02$|^## Requirement: ADPT-03$|^## Requirement: OBS-03$|^## Requirement: QUAL-03$|12-VERIFICATION.md|requirements_completed:" .planning/phases/07-phoenix-adapter-hardening/07-VERIFICATION.md .planning/phases/07-phoenix-adapter-hardening/07-01-SUMMARY.md .planning/phases/07-phoenix-adapter-hardening/07-VALIDATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ mixed*

---

## Wave 0 Requirements

- [x] `test/rendro/adapters/phoenix_test.exs` exists as the live conn-boundary proof for download and preview helpers.
- [x] `test/rendro/error_test.exs` and `test/rendro/pipeline_test.exs` exist as current structured-error proof surfaces.
- [x] Phase 12 hosted verification evidence exists and is committed for `QUAL-03`.

---

## Manual-Only Verifications

None. This backfill relies entirely on existing committed proof surfaces; no new manual Phoenix browser proof is required.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all proof surfaces referenced in `07-VERIFICATION.md`
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated coverage complete; `OBS-03` remains intentionally `Partial` until a live Phoenix error-response test exists


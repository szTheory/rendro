---
phase: 23
slug: table-split-policy-runtime-wiring
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-30
updated: 2026-04-30
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for authored table split-policy runtime wiring and truthful `LAY-10` re-verification closure.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + artifact reads |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro_builders_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | ~15-25 seconds |

---

## Sampling Rate

- **After every task commit:** run the smallest affected test slice or artifact read.
- **After Plan 23-01:** run the Phase 23 quick test suite.
- **After Plan 23-02:** read both verification artifacts and confirm `REQUIREMENTS.md` and `ROADMAP.md` reflect the new closure state.
- **Before `$gsd-verify-work`:** `mix ci` should pass and the verification artifacts must cite the final authoritative proof surfaces.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 23-01-01 | 01 | 1 | LAY-10 | T-23-01, T-23-02 | Public table builders and types expose an explicit row-atomic split policy contract, with any temporary `:atomic` alias handled intentionally rather than implicitly. | unit | `mix test test/rendro_builders_test.exs` | ✅ | ⬜ pending |
| 23-01-02 | 01 | 1 | LAY-10 | T-23-02, T-23-03, T-23-04 | Pagination consumes authored split policy, repeats headers, preserves row atomicity, and returns typed overflow details when a fresh page still cannot fit the next row. | unit + integration | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` | ✅ | ⬜ pending |
| 23-02-01 | 02 | 2 | LAY-10 | T-23-05, T-23-06 | `20-VERIFICATION.md` truthfully records the original Phase 20 gap and the later closure evidence without misrepresenting historical execution. | artifact | `test -f .planning/phases/20-table-layout-maturity/20-VERIFICATION.md` | ✅ | ⬜ pending |
| 23-02-02 | 02 | 2 | LAY-10 | T-23-05, T-23-07 | `23-VERIFICATION.md`, `REQUIREMENTS.md`, and `ROADMAP.md` agree on the final authoritative closure state only after the runtime fix is proven. | artifact + docs | `test -f .planning/phases/23-table-split-policy-runtime-wiring/23-VERIFICATION.md && rg -n \"LAY-10|Phase 20|Phase 23\" .planning/REQUIREMENTS.md .planning/ROADMAP.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure is already sufficient. The proof gaps for this phase are:

- `23-01-01` — builder/type proof for explicit `split_policy` semantics
- `23-01-02` — runtime proof that pagination consumes authored split policy
- `23-02-01` — historical backfill artifact for Phase 20
- `23-02-02` — authoritative closure artifact and traceability sync

---

## Manual-Only Verifications

None. Phase 23 should close through committed tests plus committed planning artifacts.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers both code-level and artifact-level proof surfaces
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-30

---
phase: 96
slug: adoption-signal-review-stewardship-posture
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
---

# Phase 96 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/docs_contract` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/docs_contract`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 96-01-01 | 01 | 1 | SIGNAL-01 | — | N/A | static | `grep -v '^#' ADOPTION.md \| grep -c "2026-06-13.*HOLD"` | ✅ W0 | ⬜ pending |
| 96-01-02 | 01 | 1 | STEW-01 | — | N/A | static | `grep -c "Stewardship Posture (Done-Enough)" .planning/MILESTONE-ARC.md` | ✅ W0 | ⬜ pending |
| 96-01-03 | 01 | 1 | STEW-01 | T-96-01 / T-96-02 | No SLA promised, valid links | static | `grep -c "Project Status & Stewardship" guides/api_stability.md` | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. No new test stubs are strictly required since this is a pure markdown phase verified via static grep commands and `mix test` docs compilation checks.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Formatting check | SIGNAL-01, STEW-01 | Visual validation | Generate docs (`mix docs`) and verify the tables and links are formatted correctly. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-13
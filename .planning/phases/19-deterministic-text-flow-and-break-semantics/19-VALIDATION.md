---
phase: 19
slug: deterministic-text-flow-and-break-semantics
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-29
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green and `mix run scripts/verify_docs.exs` must pass
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 19-01-01 | 01 | 1 | LAY-06, LAY-09 | T-19-01, T-19-03 | Public builder structs keep geometry on `Block`, styling on `Text`, and break intent on `Block` without widening the authoring API. | unit | `mix test test/rendro_builders_test.exs` | ✅ | ⬜ pending |
| 19-01-02 | 01 | 1 | LAY-06 | T-19-02, T-19-03 | Wrapped text produces stable measured lines, preserves explicit newlines, and uses deterministic long-token fallback. | unit + property | `mix test test/rendro/pipeline/measure_test.exs` | ✅ | ⬜ pending |
| 19-02-01 | 02 | 2 | LAY-09 | T-19-04 | `Paginate` applies `keep_together`, `keep_with_next`, `break_before`, and `break_after` deterministically after measurement. | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ | ⬜ pending |
| 19-02-02 | 02 | 2 | LAY-09 | T-19-05, T-19-06 | Impossible keep layouts and fixed-page directive misuse return typed paginate errors with stable details. | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ | ⬜ pending |
| 19-03-01 | 03 | 3 | LAY-06 | T-19-07 | Writer serialization emits the exact measured wrapped lines as multiple PDF text placements. | unit + integration | `mix test test/rendro/pdf/writer_test.exs test/rendro/flow_test.exs` | ✅ | ⬜ pending |
| 19-03-02 | 03 | 3 | LAY-06, LAY-09 | T-19-08, T-19-09 | Public docs teach wrapped flow text and keep/break semantics truthfully and remain inside the project support boundary. | docs-contract | `mix run scripts/verify_docs.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all framework/bootstrap prerequisites for this phase.

Implementation coverage gaps are already assigned to execution tasks:
- `19-01-02` — property-style determinism coverage in `test/rendro/pipeline/measure_test.exs`
- `19-03-01` — wrapped multi-line serialization proof in `test/rendro/pdf/writer_test.exs`
- `19-03-02` — README/docs examples verified by `mix run scripts/verify_docs.exs`

---

## Manual-Only Verifications

All phase behaviors should have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-29

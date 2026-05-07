---
phase: 18
slug: layout-contract-and-page-template-model
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
updated: 2026-04-28
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for layout templates, bounded regions, and truthful fit checks.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/document_test.exs test/rendro/page_test.exs test/rendro_builders_test.exs test/rendro/pipeline/compose_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~10-20 seconds |

---

## Sampling Rate

- After every task commit: run the smallest affected layout subset.
- After every plan wave: run the full Phase 18 quick suite.
- Before `$gsd-verify-work`: `mix test` must be green.
- Max feedback latency: 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 18-01-01 | 01 | 1 | LAY-07 | T-18-01 | Public builders expose explicit page templates and regions without hidden defaults. | unit | `mix test test/rendro/document_test.exs test/rendro/page_test.exs test/rendro_builders_test.exs` | ✅ | ⬜ pending |
| 18-02-01 | 02 | 2 | LAY-07, LAY-08 | T-18-02 | Flow documents normalize template-backed sections and anchored regions through one engine. | unit | `mix test test/rendro/pipeline/compose_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` | ✅ | ⬜ pending |
| 18-03-01 | 03 | 3 | LAY-11 | T-18-03 | Fixed-position and bounded-region overflow fails truthfully with deterministic `%Rendro.Error{}` details. | unit | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

---

## Wave 0 Requirements

- [x] `test/rendro/document_test.exs` and `test/rendro/page_test.exs` exist for pure-data builder proofs.
- [x] `test/rendro/pipeline/compose_test.exs`, `test/rendro/pipeline/paginate_test.exs`, and `test/rendro/flow_test.exs` exist for normalization and pagination behavior.
- [x] No additional test framework setup is required.

---

## Manual-Only Verifications

None. Phase 18 should close entirely through committed ExUnit proof.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all proof surfaces referenced in research and plans
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated coverage complete; ready for planning and execution.

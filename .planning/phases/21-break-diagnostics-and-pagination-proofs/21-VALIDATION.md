---
phase: 21
slug: break-diagnostics-and-pagination-proofs
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-29
updated: 2026-04-30
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for structured pagination diagnostics and deterministic inspector proof.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs test/rendro/inspector_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** run the touched diagnostics or inspector subset.
- **After every plan wave:** run the full Phase 21 quick suite.
- **Before `$gsd-verify-work`:** the Phase 21 quick suite must be green.
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 1 | OBS-05 | T-21-01 | The final document accumulates structured diagnostics as map-based layout-debug data without moving those events into telemetry. | unit | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline_test.exs` | ✅ | ⬜ pending |
| 21-02-01 | 02 | 1 | QUAL-06 | T-21-02 | Deterministic inspector output proves pagination structure and emitted diagnostics in reviewable ASCII form. | unit | `mix test test/rendro/inspector_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

---

## Wave 0 Requirements

- [x] `test/rendro/pipeline/paginate_test.exs`, `test/rendro/pipeline_test.exs`, and `test/rendro/inspector_test.exs` exist for the public diagnostics and inspector seams.
- [x] No extra test framework or snapshot dependency is required.
- [x] The proof lane stays deterministic and text-based.

---

## Manual-Only Verifications

None. Phase 21 should close entirely through committed ExUnit proof.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all proof surfaces referenced in research and plans
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** normalized to Nyquist structure on 2026-04-30.

---
phase: 26
slug: deterministic-font-metrics-and-pdf-embedding
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-30
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/document_test.exs test/rendro_builders_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/pdf/font_test.exs test/rendro/pdf/writer_test.exs` |
| **Full suite command** | `mix test && mix run scripts/verify_docs.exs` |
| **Estimated runtime** | ~30 seconds |

## Sampling Rate

- **After every task commit:** Run the smallest affected typography command from the per-task map.
- **After every plan wave:** Run `mix test test/rendro/document_test.exs test/rendro_builders_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/pdf/font_test.exs test/rendro/pdf/writer_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-01-01 | 01 | 1 | FONT-03 | T-26-01 / T-26-02 | Embedded font inputs are normalized into owned pure data and invalid sources fail early | unit | `mix test test/rendro/document_test.exs test/rendro_builders_test.exs` | ✅ | ⬜ pending |
| 26-01-02 | 01 | 1 | FONT-03 | T-26-03 | Build rejects unreadable, unsupported, or non-embeddable explicit font setup deterministically | unit | `mix test test/rendro/pdf/font_test.exs test/rendro/pipeline/measure_test.exs` | ✅ | ⬜ pending |
| 26-02-01 | 02 | 2 | FONT-02 | T-26-04 | Measure uses the same resolved metrics source as render and preserves wrapped-line determinism | unit | `mix test test/rendro/pipeline/measure_test.exs` | ✅ | ⬜ pending |
| 26-02-02 | 02 | 2 | FONT-02 | T-26-04 | Pagination consumes embedded-font-derived heights without drift | regression | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ | ⬜ pending |
| 26-03-01 | 03 | 3 | FONT-03 | T-26-05 | Writer emits the expected embedded font resources/objects for supported custom fonts | regression | `mix test test/rendro/pdf/writer_test.exs` | ✅ | ⬜ pending |
| 26-03-02 | 03 | 3 | FONT-02, FONT-03 | T-26-04 / T-26-05 | Shared descriptor parity is preserved end-to-end across measure, paginate, and writer | regression | `mix test test/rendro/deterministic_test.exs test/docs_contract/integrations_claims_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

- All phase behaviors have automated verification.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

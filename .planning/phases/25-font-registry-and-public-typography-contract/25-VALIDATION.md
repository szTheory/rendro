---
phase: 25
slug: font-registry-and-public-typography-contract
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-30
updated: 2026-04-30
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for the font registry surface and deterministic logical font resolution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + docs verification |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/document_test.exs test/rendro/text_test.exs test/rendro_builders_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pdf/font_test.exs test/rendro/pdf/writer_test.exs` |
| **Full suite command** | `mix test && mix run scripts/verify_docs.exs` |
| **Estimated runtime** | ~20-30 seconds |

---

## Sampling Rate

- **After every task commit:** run the smallest affected font-focused test subset.
- **After every plan wave:** run the full quick command.
- **Before `$gsd-verify-work`:** full suite plus docs verification must be green.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 1 | FONT-01 | T-25-01, T-25-02 | `%Rendro.Document{}` owns an explicit font registry and default logical font without leaking PDF internals. | unit | `mix test test/rendro/document_test.exs test/rendro_builders_test.exs` | ✅ | ⬜ pending |
| 25-01-02 | 01 | 1 | FONT-01 | T-25-02 | `%Rendro.Text{}` truthfully accepts logical font references and retains compatibility for the current built-in default path. | unit | `mix test test/rendro/text_test.exs test/rendro_builders_test.exs` | ✅ | ⬜ pending |
| 25-02-01 | 02 | 2 | FONT-01 | T-25-03, T-25-04 | `Measure` and `Writer` both consume one resolved logical-font contract so author intent is not lost between layout and render. | unit | `mix test test/rendro/pipeline/measure_test.exs test/rendro/pdf/font_test.exs test/rendro/pdf/writer_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

---

## Wave 0 Requirements

- [x] Existing ExUnit coverage files already exist for document, text, builder, measure, font, and writer surfaces.
- [x] No new test framework or fixtures are required.
- [x] Docs verification already exists through `mix run scripts/verify_docs.exs`.

---

## Manual-Only Verifications

None. Phase 25 should close through deterministic automated tests and docs verification only.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all referenced proof surfaces
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready for execution on 2026-04-30.

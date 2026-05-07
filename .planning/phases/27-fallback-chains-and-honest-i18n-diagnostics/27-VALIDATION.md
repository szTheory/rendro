---
phase: 27
slug: fallback-chains-and-honest-i18n-diagnostics
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-30
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/font_registry_test.exs test/rendro/i18n/analyzer_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pdf/writer_test.exs test/rendro/i18n_test.exs` |
| **Full suite command** | `mix test && mix run scripts/verify_docs.exs` |
| **Estimated runtime** | ~30 seconds |

## Sampling Rate

- **After every task commit:** Run the smallest affected typography command from the per-task map.
- **After every plan wave:** Run `mix test test/rendro/font_registry_test.exs test/rendro/i18n/analyzer_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pdf/writer_test.exs test/rendro/i18n_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 1 | FONT-04 | T-27-01 | FontRegistry accepts and resolves fallback chains correctly | unit | `mix test test/rendro/font_registry_test.exs` | ⬜ | ⬜ pending |
| 27-01-02 | 01 | 1 | I18N-02 | T-27-02 | I18n Analyzer correctly identifies RTL and complex shaping codepoints | unit | `mix test test/rendro/i18n/analyzer_test.exs` | ⬜ | ⬜ pending |
| 27-02-01 | 02 | 2 | FONT-04, I18N-01 | T-27-03 | Measure correctly splits text into runs and emits diagnostics for missing glyphs | unit | `mix test test/rendro/pipeline/measure_test.exs` | ✅ | ⬜ pending |
| 27-03-01 | 03 | 3 | FONT-04 | T-27-04 | PDF Writer emits correct inline font switching instructions for text runs | unit | `mix test test/rendro/pdf/writer_test.exs` | ✅ | ⬜ pending |
| 27-03-02 | 03 | 3 | I18N-01, I18N-02 | T-27-05 | Honest I18n support matrix is fully verified | integration | `mix test test/rendro/i18n_test.exs` | ⬜ | ⬜ pending |

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
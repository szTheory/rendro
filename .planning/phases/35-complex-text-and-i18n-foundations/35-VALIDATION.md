---
phase: 35
slug: complex-text-and-i18n-foundations
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-03
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/i18n/ test/rendro/pdf/ test/rendro/pipeline/` |
| **Full suite command** | `mix test && mix run scripts/verify_docs.exs` |
| **Estimated runtime** | ~30 seconds |

## Sampling Rate

- **After every task commit:** Run the smallest affected typography/i18n command from the per-task map.
- **After every plan wave:** Run `mix test test/rendro/i18n/ test/rendro/pdf/ test/rendro/pipeline/`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 1 | i18n | | Sets up core dependencies and pure i18n APIs | unit | `mix test test/rendro/i18n/` | ❌ | ⬜ pending |
| 35-02-01 | 02 | 2 | Typography | | Implements pure Elixir TrueType subsetter | unit | `mix test test/rendro/pdf/font_subsetter_test.exs` | ❌ | ⬜ pending |
| 35-03-01 | 03 | 2 | Typography | | Upgrades PDF writer to emit Type0/CID keyed fonts | unit | `mix test test/rendro/pdf/cid_font_test.exs` | ❌ | ⬜ pending |
| 35-04-01 | 04 | 3 | i18n, Typography | | Aligns Build, Compose, Measure pipelines | unit | `mix test test/rendro/pipeline/` | ❌ | ⬜ pending |
| 35-05-01 | 05 | 4 | i18n, Typography | | Aligns Paginate, Render, Validate pipelines | unit | `mix test test/rendro/pipeline/` | ❌ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- Test files must be created for i18n and subsetting logic.

## Manual-Only Verifications

- None.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

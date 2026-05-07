---
phase: 46
slug: checkbox-and-radio-button-widgets
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
updated: 2026-05-05
---

# Phase 46 — Validation Strategy

> Per-phase validation contract for deterministic checkbox and radio button widget authoring and serialization.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/rules/check_form_fields_test.exs test/rendro_builders_test.exs test/rendro/pdf/writer_test.exs` |
| **Full suite command** | `mix test test/rendro/rules/check_form_fields_test.exs test/rendro_builders_test.exs test/rendro/pdf/writer_test.exs` |
| **Estimated runtime** | ~10-20 seconds |

## Sampling Rate

- After every task commit: run the smallest affected test target.
- After each plan wave: run the full quick suite.
- Before execution handoff: the full Phase 46 suite must be green.
- Max feedback latency: 20 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 46-01-01 | 01 | 1 | M4-FORMS | T-46-01 | `Rendro.FormField` and `Rendro.form_field/3` express checkbox/radio metadata without a second DSL surface. | unit | `mix test test/rendro_builders_test.exs` | ✅ | ⬜ pending |
| 46-01-02 | 01 | 1 | M4-FORMS | T-46-02 | Validation rejects missing radio group/export semantics and contradictory default radio selections. | unit | `mix test test/rendro/rules/check_form_fields_test.exs` | ✅ | ⬜ pending |
| 46-02-01 | 02 | 2 | M4-FORMS | T-46-03 | Writer emits valid `/FT /Btn` checkbox widgets with deterministic on/off appearance states. | unit | `mix test test/rendro/pdf/writer_test.exs` | ✅ | ⬜ pending |
| 46-02-02 | 02 | 2 | M4-FORMS | T-46-04 | Writer emits grouped radio widgets with deterministic parent/child structure and correct page annotations. | unit | `mix test test/rendro/pdf/writer_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

## Wave 0 Requirements

- [x] Existing form-field builder, rule, and writer test files already exist and can absorb Phase 46 coverage.
- [x] No new test framework or external viewer dependency is required for the core proof lane.
- [x] Existing writer substring assertions are sufficient for deterministic PDF-structure verification in this phase.

## Manual-Only Verifications

- Optional viewer spot-check in Acrobat/Preview may be useful later, but it is not required for the planning-time automated proof lane.

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all proof surfaces referenced in research and plans
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Phase 46 validation lane approved on 2026-05-05.

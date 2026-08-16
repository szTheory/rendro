---
phase: 125
slug: foundation-curated-fonts-style-genre-presets-brand-fixtures
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-16
---

# Phase 125 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (project Mix test suite) |
| **Config file** | `mix.exs`; no separate test config required |
| **Quick run command** | `mix test test/rendro/theme/presets_test.exs test/rendro/theme/preset_fonts_test.exs test/rendro/pdf/font_subsetter_test.exs test/docs_contract/examples_schema_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | Focused tests under 60 seconds; full suite runtime measured during execution |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit file(s) named by the task plus `mix format --check-formatted`.
- **After every plan wave:** Run `mix test`.
- **Before `$gsd-verify-work`:** Full deterministic suite must be green; run the pinned-PDFium raster lane separately for advisory human review.
- **Max feedback latency:** 60 seconds for focused tests; longer package/raster checks are explicit wave gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 125-01-01 | 01 | 1 | PRESET-01, PRESET-04, PRESET-05, FONT-04 | T-125-01, T-125-03 | Strict validation; explicit registration; typed omission failure; real render tracer | unit + integration + E2E | `mix test test/rendro/theme/presets_test.exs` | ❌ task creates | ⬜ pending |
| 125-02-01 | 02 | 2 | PRESET-02, PRESET-03, PRESET-06 | T-125-06 | Exact structural token matrix, source confinement, complete Brutalist semantics | unit + source contract | `mix test test/rendro/theme/presets_test.exs test/docs_contract/theme_industry_guard_test.exs` | ❌ task creates/extends | ⬜ pending |
| 125-02-02 | 02 | 2 | PRESET-04, PRESET-05, FONT-04 | T-125-07, T-125-08 | Certificate exact metrics, bounded recipe/mode/font matrix, no silent fallback | integration + deterministic E2E | `mix test test/rendro/recipes/certificate_typography_test.exs test/rendro/theme/preset_render_matrix_test.exs` | ❌ task creates/extends | ⬜ pending |
| 125-04-02 | 04 | 3 | PRESET-02, PRESET-04, PRESET-06 | T-125-17, T-125-18 | Pinned-PDFium genre review remains advisory and separately approved | advisory raster + human | `mix test --include raster_snapshot test/rendro/theme/preset_raster_snapshot_test.exs` | ❌ Plan 02 creates | ⬜ pending |
| 125-01-02 | 01 | 1 | FONT-01, FONT-02 | T-125-01, T-125-02 | Vendored static TTFs pass strict preflight and immutable provenance checks | unit | `mix test test/rendro/theme/preset_fonts_test.exs` | ❌ task creates | ⬜ pending |
| 125-01-02 | 01 | 1 | FONT-03 | T-125-02 | Every referenced font and NOTICE entry is present in the Hex tarball | package integration | `mix test test/docs_contract/preset_fonts_package_contract_test.exs` | ❌ task creates | ⬜ pending |
| 125-01-02 | 01 | 1 | FONT-05 | T-125-01 | Empty/equal glyph sets yield parseable byte-identical subsets for all four fonts | unit | `mix test test/rendro/pdf/font_subsetter_test.exs` | ✅ extend | ⬜ pending |
| 125-03-01..02 | 03 | 1 | CATALOG-05 | T-125-11, T-125-15 | Fixture paths remain local/safe, arithmetic exact, and every brand satisfies the generic schema | schema + fixture + package | `mix test test/docs_contract/examples_schema_contract_test.exs` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Plan 01 Task 1 creates `test/rendro/theme/presets_test.exs` before tracer implementation.
- [ ] Plan 01 Task 2 creates `test/rendro/theme/preset_fonts_test.exs` and `test/docs_contract/preset_fonts_package_contract_test.exs`, and extends `test/rendro/pdf/font_subsetter_test.exs`, before expansion implementation.
- [ ] Plan 02 Task 2 creates `test/rendro/theme/preset_render_matrix_test.exs` and `test/rendro/theme/preset_raster_snapshot_test.exs` before recipe/matrix implementation.
- [ ] Plan 03 Task 1 extends `test/docs_contract/examples_schema_contract_test.exs` before fixture/schema implementation.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Genre-distinct, printable recipe output in light and dark modes | PRESET-02, PRESET-04, PRESET-06 | Visual quality/distinctness is advisory and cannot be truthfully reduced to byte/token checks | Render the locked preset/recipe matrix with the pinned PDFium lane, compare rasters, and record human approval without making accessibility, PDF/UA, or print-safety claims. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or explicit test-first creation in the same task.
- [x] Sampling continuity: no three consecutive tasks without automated verification.
- [x] Wave 0 gaps are bound to the first behavior-producing task that consumes each test.
- [x] No watch-mode flags.
- [x] Focused feedback latency targets under 60 seconds; package/full/raster commands are explicit wave/phase gates.
- [x] Deterministic and advisory verification lanes remain separate.
- [x] `nyquist_compliant: true` set in frontmatter after plan binding.

**Approval:** pending

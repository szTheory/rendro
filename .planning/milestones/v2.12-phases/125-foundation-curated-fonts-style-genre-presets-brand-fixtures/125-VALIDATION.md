---
phase: 125
slug: foundation-curated-fonts-style-genre-presets-brand-fixtures
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-16
revised: 2026-08-16
---

# Phase 125 — Validation Strategy

> Per-phase validation contract with one explicit automated binding per revised task.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit |
| Config | `mix.exs`; no separate test config |
| Quick command | `mix test test/rendro/theme/presets_test.exs test/rendro/theme/preset_fonts_test.exs test/rendro/pdf/font_subsetter_test.exs test/docs_contract/examples_schema_contract_test.exs` |
| Full command | `mix test` |
| Lane boundary | Default tests are deterministic; `:raster_snapshot` is separately included and pinned |

## Sampling Rate

- After every task commit: run that task's focused command plus `mix format --check-formatted` where the plan specifies it.
- After every plan wave: run `mix test`.
- Before verification: run all focused deterministic contracts, full `mix test`, and `mix ci.fast`; then run pinned PDFium separately.
- Focused feedback target is under 60 seconds; package/full/raster checks are explicit wave or phase gates.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|---:|---:|---|---|---|---|---|---|---|
| 125-01-01 | 01 | 1 | PRESET-01, PRESET-04, PRESET-05, FONT-04 | T-125-01, T-125-03 | Strict real-font tracer, explicit registration, typed omission, isolated collisions | E2E + integration | `mix test test/rendro/theme/presets_test.exs test/rendro/recipes/invoice_byte_identity_test.exs` | ✅ | ✅ green |
| 125-02-01 | 02 | 2 | FONT-01, FONT-02, FONT-03, FONT-04 | T-125-02, T-125-04 | Four-face preflight/provenance/descriptor/package proof | unit + package | `mix test test/rendro/theme/preset_fonts_test.exs test/docs_contract/preset_fonts_package_contract_test.exs` | ✅ | ✅ green |
| 125-02-02 | 02 | 2 | FONT-05 | T-125-20 | Empty/equal glyph sets yield parseable identical subsets | unit | `mix test test/rendro/pdf/font_subsetter_test.exs` | ✅ | ✅ green |
| 125-03-01 | 03 | 3 | PRESET-01, PRESET-02, PRESET-03, PRESET-04, PRESET-06 | T-125-06, T-125-21 | Exact grammar, strict dispatch, complete Brutalist, source confinement | unit + source contract | `mix test test/rendro/theme/presets_test.exs test/docs_contract/theme_industry_guard_test.exs` | ✅ | ✅ green |
| 125-04-01 | 04 | 4 | PRESET-04, PRESET-05, FONT-04 | T-125-07, T-125-08 | Exact curated Certificate metrics; no fallback; default bytes stable | integration | `mix test test/rendro/recipes/certificate_typography_test.exs test/rendro/recipes/certificate_byte_identity_test.exs` | ✅ | ✅ green |
| 125-04-02 | 04 | 4 | PRESET-04, PRESET-05, PRESET-06, FONT-04 | T-125-22 | Twelve deterministic rows, all recipes/faces, typed omission, repeat bytes | deterministic E2E | `mix test test/rendro/theme/preset_render_matrix_test.exs test/rendro/recipes/*_byte_identity_test.exs` | ✅ | ✅ green |
| 125-05-01 | 05 | 5 | PRESET-02, PRESET-04 | T-125-09, T-125-18 | First six row IDs use pinned, default-excluded raster evidence | advisory raster | `mix test --include raster_snapshot test/rendro/theme/preset_raster_snapshot_test.exs` | ✅ | ✅ green |
| 125-06-01 | 06 | 6 | PRESET-02, PRESET-04, PRESET-06 | T-125-23 | Complete twelve-row unique pinned hash binding | advisory raster | `mix test --include raster_snapshot test/rendro/theme/preset_raster_snapshot_test.exs` | ✅ | ✅ green |
| 125-07-01 | 07 | 1 | CATALOG-05 | T-125-11, T-125-12, T-125-13 | Generic schema, safe SVGs, exact Invoice tuples and arithmetic | schema + fixture | `mix test test/docs_contract/examples_schema_contract_test.exs` | ✅ | ✅ green |
| 125-07-02 | 07 | 1 | CATALOG-05 | T-125-12, T-125-13 | Cross-domain identity reuse and exact Payslip reconciliation | fixture + loader | `mix test test/docs_contract/examples_schema_contract_test.exs test/rendro/examples_data_test.exs` | ✅ | ✅ green |
| 125-08-01 | 08 | 2 | CATALOG-05 | T-125-14, T-125-15 | Statement balance continuity and safe locked marks | schema + fixture | `mix test test/docs_contract/examples_schema_contract_test.exs` | ✅ | ✅ green |
| 125-08-02 | 08 | 2 | CATALOG-05 | T-125-14, T-125-15 | Receipt exact totals and safe locked marks | fixture + loader | `mix test test/docs_contract/examples_schema_contract_test.exs test/rendro/examples_data_test.exs` | ✅ | ✅ green |
| 125-09-01 | 09 | 3 | CATALOG-05 | T-125-13 | Certificate exact tuples, synthetic content, and safe marks | schema + fixture | `mix test test/docs_contract/examples_schema_contract_test.exs` | ✅ | ✅ green |
| 125-09-02 | 09 | 3 | CATALOG-05 | T-125-13, T-125-24 | Six-domain counts, twelve identities/logos, old bytes, Hex extensions | fixture + package | `mix test test/docs_contract/examples_schema_contract_test.exs test/rendro/examples_data_test.exs` | ✅ | ✅ green |
| 125-10-01 | 10 | 7 | ALL PHASE REQUIREMENTS | T-125-16, T-125-18 | Deterministic phase gate, exact counts, source and threat audit | full suite + CI | `mix test &amp;&amp; mix ci.fast &amp;&amp; git diff --exit-code -- priv/goldens` | ✅ | ✅ green |
| 125-10-02 | 10 | 7 | PRESET-02, PRESET-04, PRESET-06 | T-125-17, T-125-18 | Complete pinned matrix remains advisory and gets explicit bounded review | advisory + human | `RENDRO_PRESET_RASTER_REVIEW_DIR=tmp/rendro_preset_raster_review mix test --include raster_snapshot test/rendro/theme/preset_raster_snapshot_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [x] Plan 01 Task 1 created `test/rendro/theme/presets_test.exs` before tracer implementation.
- [x] Plan 02 Task 1 created `test/rendro/theme/preset_fonts_test.exs` and `test/docs_contract/preset_fonts_package_contract_test.exs` before font/package implementation.
- [x] Plan 03 Task 1 extended preset/source-guard contracts before completing the grammar.
- [x] Plan 04 Task 2 created `test/rendro/theme/preset_render_matrix_test.exs` before deterministic matrix implementation.
- [x] Plan 05 Task 1 created `test/rendro/theme/preset_raster_snapshot_test.exs` before adding first-batch references.
- [x] Plan 07 Task 1 extended `test/docs_contract/examples_schema_contract_test.exs` before schema/fixture implementation; Plans 08-09 progressed that same contract before each domain batch.

## Manual-Only Verification

| Behavior | Requirement | Why Manual | Test Instructions |
|---|---|---|---|
| Bounded genre distinctness, clipping/overflow, and exact-face Certificate centering across light/dark | PRESET-02, PRESET-04, PRESET-06 | Visual judgment cannot be truthfully reduced to token/hash equality | Render the locked twelve-row matrix with pinned PDFium, compare all six light/dark pairs, and record row-specific approval/findings without quality/compliance claims. |

## Validation Sign-Off

- [x] Every revised task ID has one explicit automated verification row.
- [x] No combined task ranges or duplicate task-ID bindings remain.
- [x] Sampling continuity has no three consecutive tasks without automation.
- [x] Deterministic and advisory lanes remain separate.
- [x] No watch-mode flags.
- [x] `nyquist_compliant: true` remains set after rebinding.

**Approval:** validated — 2026-08-19

## Validation Audit 2026-08-19

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Evidence: all sixteen task bindings exist and passed during phase execution; the deterministic phase gate and separately pinned advisory raster review are recorded in `125-10-SUMMARY.md` and `125-VERIFICATION.md` (28/28 must-haves).

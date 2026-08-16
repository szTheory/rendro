---
phase: 125
slug: foundation-curated-fonts-style-genre-presets-brand-fixtures
status: draft
nyquist_compliant: false
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
| TBD | TBD | TBD | PRESET-01..04 | T-125-01 | Strict option/color validation; deterministic light/dark composition | unit + integration | `mix test test/rendro/theme/presets_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | PRESET-05 | T-125-02 | Unregistered roles retain typed failure; no silent fallback | integration | `mix test test/rendro/theme/presets_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | PRESET-06 | T-125-03 | Brutalist is absent unless completely implemented and verified | unit + advisory raster | `mix test test/rendro/theme/presets_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | FONT-01..02 | T-125-04 | Vendored-only static TTFs pass strict preflight and immutable provenance checks | unit | `mix test test/rendro/theme/preset_fonts_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | FONT-03 | T-125-05 | Every referenced font and NOTICE entry is present in the Hex tarball | package integration | `mix test test/docs_contract/preset_fonts_package_contract_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | FONT-04 | T-125-06 | Registration is idempotent for identical descriptors and rejects caller-owned collisions | integration | `mix test test/rendro/theme/presets_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | FONT-05 | T-125-07 | Glyph permutations and duplicates yield identical subset bytes for all four fonts | unit | `mix test test/rendro/pdf/font_subsetter_test.exs` | ✅ extend | ⬜ pending |
| TBD | TBD | TBD | CATALOG-05 | T-125-08 | Fixture paths remain local/safe and every brand satisfies the generic schema | schema + fixture | `mix test test/docs_contract/examples_schema_contract_test.exs` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/theme/presets_test.exs` — constructor, token, registration, collision, missing-role, recipe, and Certificate coverage.
- [ ] `test/rendro/theme/preset_fonts_test.exs` — curated-font format, embedding, provenance, and NOTICE checks.
- [ ] `test/docs_contract/preset_fonts_package_contract_test.exs` — positive Hex tarball-content proof for every preset font/NOTICE file.
- [ ] Extend `test/rendro/pdf/font_subsetter_test.exs` with permutation and duplicate-glyph determinism cases for all four curated faces.
- [ ] Extend `test/docs_contract/examples_schema_contract_test.exs` with fixture count, generic brand data, local logo, and domain invariant checks.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Genre-distinct, printable recipe output in light and dark modes | PRESET-02, PRESET-04, PRESET-06 | Visual quality/distinctness is advisory and cannot be truthfully reduced to byte/token checks | Render the locked preset/recipe matrix with the pinned PDFium lane, compare rasters, and record human approval without making accessibility, PDF/UA, or print-safety claims. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing test references.
- [ ] No watch-mode flags.
- [ ] Focused feedback latency is under 60 seconds.
- [ ] Deterministic and advisory verification lanes remain separate.
- [ ] `nyquist_compliant: true` set in frontmatter after validation.

**Approval:** pending

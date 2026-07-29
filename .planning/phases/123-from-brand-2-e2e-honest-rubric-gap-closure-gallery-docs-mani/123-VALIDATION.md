---
phase: 123
slug: from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-28
validated: 2026-07-28
---

# Phase 123 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir stdlib), `async: true` throughout `test/docs_contract/` |
| **Config file** | `test/test_helper.exs` (+ `.formatter.exs`) |
| **Quick run command** | `mix test test/docs_contract/<file>.exs` |
| **Full suite command** | `mix test --exclude quarantine` (mirrors `ci.fast`) |
| **Estimated runtime** | ~60–120 seconds (full); <10s per docs-contract file |

Additional lanes:
- **Gallery regen/verify:** `mix rendro.launch_artifacts.gen` then `mix rendro.launch_artifacts.check`
- **Tarball lane:** `mix hex.build` (in `ci.fast`; `branding_claims_test` reads the build output)
- **Advisory raster lane:** `mix ci.advisory` (raster snapshot + `launch_artifacts.check` + audits)

---

## Sampling Rate

- **After every task commit:** Run the touched `test/docs_contract/<file>.exs` + any affected recipe golden
- **After every plan wave:** Run `mix test --exclude quarantine` + `mix rendro.launch_artifacts.check`
- **Before `/gsd-verify-work`:** `mix ci.fast` green (includes `hex.build` tarball lane + `docs --warnings-as-errors`) AND `mix ci.advisory` green (gallery hash + raster)
- **Max feedback latency:** ~120 seconds (full suite)

---

## Per-Task Verification Map

| Req | Behavior | Test Type | Automated Command | Status |
|-----|----------|-----------|-------------------|--------|
| DEFAULT-02 (data) | invoice transform yields issuer/customer/totals | unit | `mix test test/rendro/examples_data_test.exs` | ✅ |
| DEFAULT-01 (leading) | themed recipes emit `line_height: 1.35`; no-theme goldens unchanged | golden/unit | `mix test test/rendro/theme_test.exs test/rendro/recipes/` (byte goldens stay green) | ✅ |
| DEFAULT-01 (from_brand) | accent coerce + on_accent both-ways (teal→white, amber→ink) | docs-contract | `mix test test/docs_contract/theming_contract_test.exs` | ✅ |
| DEFAULT-02 (re-score) | recorded `passed` == recomputation; sign-off fields present + evidence exists & is manifest-covered | docs-contract | `mix test test/docs_contract/rubric_manifest_contract_test.exs` | ✅ |
| DEFAULT-03 (gallery) | 11 ordered rows; S6 tags valid; hashes match | docs-contract | `mix test test/docs_contract/launch_artifacts_claims_test.exs` | ✅ |
| CONTRACT-02 (guide) | fence IDs in order + evaluable | docs-contract | `mix test test/docs_contract/theming_contract_test.exs` | ✅ |
| CONTRACT-02 (matrix) | theming rows proof-backed; no overclaim; `guides/theming.md` exists | docs-contract | `mix test test/docs_contract/theming_claims_test.exs` | ✅ |
| CONTRACT-02 (tarball) | `priv/quality`/`support_matrix`/rubric-schema excluded; assets+guides ship | docs-contract | `mix test test/docs_contract/branding_claims_test.exs` | ✅ |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> **Audit 2026-07-28:** all 8 rows re-run green — `mix test` across the 8 files above: **4 properties, 140 tests, 0 failures**. Every plan-time ❌ W0 gap was filled during execution (123-01 data test, 123-04 theming fences/claims, 123-05 rubric teeth). The `mix rendro.launch_artifacts.check` byte-raster re-verification (advisory lane) additionally needs `pdfium-cli` on PATH (WINDOWS.md id 7, env-tooling gap) — but the gallery's 11-row manifest, S6 tags, and every `png_sha256`/`source_pdf_sha256` are already asserted from the checked-in manifest by `launch_artifacts_claims_test.exs` (green, no external binary), so DEFAULT-03 has full automated coverage without the raster lane.

---

## Wave 0 Requirements

- [x] `test/docs_contract/theming_contract_test.exs` — NEW; mirrors `branding_contract_test.exs`, asserts `guides/theming.md` fence IDs in order + `evaluate!` each (covers DEFAULT-01 from_brand / CONTRACT-02 guide) — landed 123-04 (`b161772`)
- [x] `guides/theming.md` — NEW; `# docs-contract:` fences (accent-only, both-ways contrast, orthogonal) + an 11-row gallery block with SHA-256s — landed 123-04 (`ae6eb2a`)
- [x] Data-survival test (invoice issuer/customer/totals) — extended `test/rendro/examples_data_test.exs` — landed 123-01 (`ad8439b`)
- [x] Rubric sign-off teeth — extended `rubric_manifest_contract_test.exs` (`for entry` loop) + schema `if/then` — landed 123-05 (`5eda766`)
- [x] `priv/quality/SIGN-OFF.md` — NEW (SCORECARD house style) — landed 123-05 (`5eda766`)
- [x] Update `launch_artifacts_claims_test.exs` count 7→11 (123-03 `53e1ba7`); invert `theming_claims_test.exs` guides/theming.md existence guard (123-04 `814e1df`)
- [x] `mix.exs` `docs` extras/skip-warnings for `guides/theming.md` — landed 123-04 (`ae6eb2a`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Honest human sign-off of the 6 re-scored rubric demos | DEFAULT-02 | Rubric "reader quality" is a human judgment (hierarchy = 5, core ≥ 4); the machine only enforces that a `passed:true` carries a signed evidence_ref, not that the judgment is correct | Review the 6 pre-computed themed `default/0` PNG rasters + per-demo measured glyph-height deltas; confirm the Certificate `content_hierarchy == 5` honestly (recipient/title ratio ~1.27 is the flagged risk); sign `priv/quality/SIGN-OFF.md` + add `Signed-off-by` git trailer only on an honest clear |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-07-28

---

## Validation Audit 2026-07-28

| Metric | Count |
|--------|-------|
| Requirements mapped | 4 (DEFAULT-01, DEFAULT-02, DEFAULT-03, CONTRACT-02) |
| Behaviors tracked | 8 |
| Gaps found (plan-time ❌ W0) | 3 |
| Resolved (filled during execution) | 3 |
| Escalated / still MISSING | 0 |
| Manual-only (inherent human judgment) | 1 (rubric sign-off) |

**Verdict:** NYQUIST-COMPLIANT. All 8 tracked behaviors have automated verification that runs green (`mix test` across the 8 files: 4 properties, 140 tests, 0 failures). No test generation or auditor spawn was required — the three plan-time gaps (`theming_contract_test.exs`, invoice data-survival assertion, rubric sign-off teeth) were all filled by execution plans 123-01/04/05. The single manual-only item (honest human rubric sign-off) is an inherent visual judgment layered on top of the machine-enforced honesty gate, not a requirement lacking automation.

---
phase: 123
slug: from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-28
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

| Req | Behavior | Test Type | Automated Command | Exists? |
|-----|----------|-----------|-------------------|---------|
| DEFAULT-02 (data) | invoice transform yields issuer/customer/totals | unit | `mix test test/rendro/examples_data_test.exs` (add assertion) | ❌ W0 (new test) |
| DEFAULT-01 (leading) | themed recipes emit `line_height: 1.35`; no-theme goldens unchanged | golden/unit | `mix test test/rendro/recipes/*` (existing byte goldens stay green) | ✅ |
| DEFAULT-01 (from_brand) | accent coerce + on_accent both-ways (teal→white, amber→ink) | docs-contract | `mix test test/docs_contract/theming_contract_test.exs` | ❌ W0 (new) |
| DEFAULT-02 (re-score) | recorded `passed` == recomputation; sign-off fields present + evidence exists & is manifest-covered | docs-contract | `mix test test/docs_contract/rubric_manifest_contract_test.exs` | ✅ (add teeth) |
| DEFAULT-03 (gallery) | 11 ordered rows; S6 tags valid; hashes match | docs-contract + advisory | `mix test test/docs_contract/launch_artifacts_claims_test.exs` + `mix rendro.launch_artifacts.check` | ✅ (count 7→11) |
| CONTRACT-02 (guide) | fence IDs in order + evaluable | docs-contract | `mix test test/docs_contract/theming_contract_test.exs` | ❌ W0 (new) |
| CONTRACT-02 (matrix) | theming rows proof-backed; no overclaim; `guides/theming.md` exists | docs-contract | `mix test test/docs_contract/theming_claims_test.exs` | ✅ (flip L163 + add) |
| CONTRACT-02 (tarball) | `priv/quality`/`support_matrix`/rubric-schema excluded; assets+guides ship | docs-contract | `mix test test/docs_contract/branding_claims_test.exs` | ✅ |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/docs_contract/theming_contract_test.exs` — NEW; mirrors `branding_contract_test.exs`, asserts `guides/theming.md` fence IDs in order + `evaluate!` each (covers DEFAULT-01 from_brand / CONTRACT-02 guide)
- [ ] `guides/theming.md` — NEW; `# docs-contract:` fences (accent-only, both-ways contrast, orthogonal) + an 11-row gallery block with SHA-256s
- [ ] Data-survival test (invoice issuer/customer/totals) — NEW (Commit 1); extend `test/rendro/examples_data_test.exs` if present, else a small new file
- [ ] Rubric sign-off teeth — extend `rubric_manifest_contract_test.exs` (new `for entry` loop) + schema `if/then`
- [ ] `priv/quality/SIGN-OFF.md` — NEW (SCORECARD house style)
- [ ] Update `launch_artifacts_claims_test.exs` L12 count 7→11; invert `theming_claims_test.exs` L163 (guides/theming.md existence)
- [ ] `mix.exs` `docs` extras/skip-warnings for `guides/theming.md`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Honest human sign-off of the 6 re-scored rubric demos | DEFAULT-02 | Rubric "reader quality" is a human judgment (hierarchy = 5, core ≥ 4); the machine only enforces that a `passed:true` carries a signed evidence_ref, not that the judgment is correct | Review the 6 pre-computed themed `default/0` PNG rasters + per-demo measured glyph-height deltas; confirm the Certificate `content_hierarchy == 5` honestly (recipient/title ratio ~1.27 is the flagged risk); sign `priv/quality/SIGN-OFF.md` + add `Signed-off-by` git trailer only on an honest clear |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

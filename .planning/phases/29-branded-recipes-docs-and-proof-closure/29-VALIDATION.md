---
phase: 29
slug: branded-recipes-docs-and-proof-closure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-01
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built into Elixir 1.19) |
| **Config file** | `mix.exs` `aliases.ci` and `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/recipes/branded_invoice_test.exs test/docs_contract/branding_contract_test.exs test/docs_contract/branding_claims_test.exs` |
| **Full suite command** | `mix ci` (format, hex.build, compile --warnings-as-errors, test, docs, credo --strict, dialyzer) |
| **Estimated runtime** | ~30s quick / ~3 min full |

---

## Sampling Rate

- **After every task commit:** Run quick command (the three new test files)
- **After every plan wave:** Run `mix test` (full unit + doctest + docs-contract suite)
- **Before `/gsd-verify-work`:** `mix ci` must be green
- **Max feedback latency:** ~30s (quick); ~3min (full suite)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 29-01-* | 01 (Assets+License) | 1 | QUAL-07 | V14 | NOTICE+OFL header substring committed; B612 153_192 bytes; logo <2KB | claim | `mix test test/docs_contract/branding_claims_test.exs` | ❌ W0 | ⬜ pending |
| 29-02-* | 02 (Rendro.Branded) | 1 | LAY-13 | V12 | `Application.app_dir/2` resolves; no user-controlled paths | unit | `mix test test/rendro/branded_test.exs` | ❌ W0 | ⬜ pending |
| 29-03-* | 03 (BrandedInvoice + doctests) | 2 | LAY-13 | V5 | `data.brand` boundary validation hard-fails; D-04 typed errors | unit + doctest | `mix test test/rendro/recipes/branded_invoice_test.exs --include doctest` | ❌ W0 | ⬜ pending |
| 29-04-* | 04 (Regression suite) | 2 | QUAL-07 | — | Page count, header line breaks, image XObject inclusion, font dictionary entries; byte-identical 2-render regression (internal only, D-30) | regression | `mix test test/rendro/recipes/branded_invoice_test.exs` | ❌ W0 | ⬜ pending |
| 29-05-* | 05 (guides/branding.md) | 2 | QUAL-07 | — | 4 verified fences + ≤1 schematic fence per D-21/D-22 | docs-contract | `mix test test/docs_contract/branding_contract_test.exs` | ❌ W0 | ⬜ pending |
| 29-06-* | 06 (docs-contract tests) | 3 | QUAL-07 | V5/V14 | `evaluate!/2` runs all 4 fences; structural `%Rendro.Error{}` assertion (D-26) | docs-contract + claim | `mix test test/docs_contract/branding_*_test.exs` | ❌ W0 | ⬜ pending |
| 29-07-* | 07 (Phoenix example) | 3 | LAY-13 | V5 | `GET /branded/download` returns `%PDF-`; document has registered brand font + image | integration | `cd examples/phoenix_example && mix test` | ❌ W0 | ⬜ pending |
| 29-08-* | 08 (README + mix.exs) | 3 | QUAL-07 | V14 | `:extras` includes branding.md; `:files` enumerates `priv/branded/**`+`NOTICE`; tarball-presence check | claim | `mix test test/docs_contract/branding_claims_test.exs` | ❌ W0 | ⬜ pending |
| 29-09-* | 09 (ROADMAP v1.3 capture) | 4 | LAY-13/QUAL-07 | — | Phase 999.1 has v1.3-readiness-blockers subsection per D-28 | claim | `grep -q "v1.3 readiness blockers" .planning/ROADMAP.md` | n/a (state file) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/branded_test.exs` — covers LAY-13 path-resolver behavior (`Rendro.Branded.font_path/0`, `.logo_path/0`)
- [ ] `test/rendro/recipes/branded_invoice_test.exs` — covers LAY-13 (page_template/1, sections/2, document/2, delegate `Rendro.Recipes.branded_invoice/1`) + QUAL-07 (regression: page count, line breaks, XObject, font dict, byte-identical 2-render)
- [ ] `test/docs_contract/branding_contract_test.exs` — covers QUAL-07 (4 verified fences via `Rendro.Test.DocsContract.verified_fences/1` + `evaluate!/2`)
- [ ] `test/docs_contract/branding_claims_test.exs` — covers QUAL-07 (README "Branded Documents" pointer, `mix.exs :extras` includes `guides/branding.md`, NOTICE+OFL header substring, font byte size 153_192, logo byte size <2_000, tarball-presence claim, structural `%Rendro.Error{}` on missing-asset)
- [ ] Two new `describe` blocks in `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` — covers LAY-13 Phoenix integration proof (`GET /branded/download`, `GET /branded/preview`)
- No new framework install — ExUnit already configured, `Rendro.Test.DocsContract` helpers already exist, no new deps.
- No new shared fixtures — sample data lives inside test modules (mirrors `invoice_test.exs` precedent).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual quality of branded PDF (font legibility, logo placement, header emphasis) | LAY-13 (DX feel) | Subjective design judgment; not amenable to automated assertion. Structural fields are auto-verified. | Run `cd examples/phoenix_example && mix phx.server`; open `http://localhost:4000`; click "Branded invoice (preview)"; visually confirm logo renders + header uses brand font. |
| Hex tarball publishability dry-run | QUAL-07 (release readiness, D-28) | `mix hex.publish --dry-run` requires Hex auth context that varies by user; cannot be a CI gate. | Run `mix hex.build` (offline); inspect `tar tzf rendro-*.tar.gz` for `priv/branded/fonts/B612-Regular.ttf`, `priv/branded/images/rendro-logo.png`, `NOTICE`. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (quick) / < 3min (full)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

---
phase: 126
slug: carryover-polish-dark-mode-legibility-hierarchy-decision-gol
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-16
---

# Phase 126 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/theme/preset_render_matrix_test.exs test/rendro/recipes/*typography_test.exs` |
| **Full suite command** | `mix test && mix ci.fast` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit files named by that task plus `mix format --check-formatted`.
- **After every plan wave:** Run `mix test`.
- **Before `$gsd-verify-work`:** Run `mix test && mix ci.fast`; both commands must pass.
- **Advisory evidence:** Run only the affected pinned-PDFium raster rows after deterministic checks pass; do not merge this lane into `mix ci.fast`.
- **Max feedback latency:** 180 seconds for deterministic feedback.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 126-01-01 | 01 | 1 | POLISH-01 | T-126-01, T-126-02 | Shared internal themed cells use requested semantic roles while literal nil-theme callers and frozen Invoice bytes remain unchanged. | unit + byte golden | `mix test test/rendro/recipes/table_cell_test.exs test/rendro/recipes/invoice*_test.exs` | ❌ shared seam/focused assertions; ✅ byte baseline | ⬜ pending |
| 126-01-02 | 01 | 1 | POLISH-02 | T-126-01, T-126-02 | Required Ticket text remains visible and copyable; no new public input surface. | unit + deterministic matrix | `mix test test/rendro/recipes/ticket*_test.exs test/rendro/theme/preset_render_matrix_test.exs` | ✅ baseline / ❌ hierarchy assertions | ⬜ pending |
| 126-01-03 | 01 | 1 | POLISH-03 | T-126-01, T-126-03 | Existing Decimal formatting and recipe validation remain authoritative. | unit + deterministic matrix | `mix test test/rendro/recipes/payslip*_test.exs test/rendro/theme/preset_render_matrix_test.exs` | ✅ baseline / ❌ atomic-money assertions | ⬜ pending |
| 126-02-01 | 02 | 1 | POLISH-04 | T-126-05 | SHA-256 evidence is produced by the existing cryptographic primitive and deterministic renderer, independently of PDFium and advisory blessing. | byte golden | `mix test test/rendro/theme/preset_accent_golden_test.exs` | ❌ W0 | ⬜ pending |
| 126-02-02 | 02 | 1 | POLISH-05 | T-126-06 | Typography overrides stay within existing validated theme/recipe APIs. | unit | `mix test test/rendro/recipes/*typography_test.exs` | ❌ W0 additions | ⬜ pending |
| 126-02-03 | 02 | 1 | POLISH-05 | T-126-06 | Existing Invoice/Statement/Certificate/Ticket contracts retain typed guards while adding semantic scale/font/leading/override proof. | unit | `mix test test/rendro/recipes/invoice_typography_test.exs test/rendro/recipes/statement_typography_test.exs test/rendro/recipes/certificate_typography_test.exs test/rendro/recipes/ticket_typography_test.exs` | ✅ baseline / ❌ deep assertions | ⬜ pending |
| 126-03-01 | 03 | 2 | POLISH-01, POLISH-02, POLISH-03 | T-126-09, T-126-10 | Guardrails remove job-level failure masking and keep only the adapter compare-only step non-blocking with `MIX_RASTER_BLESS: "false"` and `continue-on-error: true`; preset blessing, staging, and upload remain blocking and the required job has no blessing. Exact run discovery and bounded completion polling validate event/ref/SHA; an exact run-job query requires the sole `advisory-checks` job to conclude success before manifest-bound artifact import. Whole-run conclusion, adapter outcome, and every unrelated failure are disclosed separately. | advisory CI + exact-job artifact contract | `mix test test/guardrails/required_checks_contract_test.exs && test -f tmp/phase126_ci_raster_artifact/manifest.txt` plus bounded exact-selector discovery/completion, exact `advisory-checks` success, and exact six-file/six-PNG gates | ❌ adapter-step recovery contract/artifact; ✅ both raster harnesses | ⬜ pending |
| 126-03-02 | 03 | 2 | POLISH-01, POLISH-02, POLISH-03 | T-126-09, T-126-10 | Human confirms exact run/ref/SHA, successful `advisory-checks`, disclosed adapter compare-only outcome, successful preset blessing, and exact pinned manifest/payload without requiring overall run success. Failed run 31996940001 and eventual accepted evidence remain recorded through cleanup. | automated artifact fence + manual provenance checkpoint | `test -f tmp/phase126_ci_raster_artifact/manifest.txt && mix test test/guardrails/required_checks_contract_test.exs` plus exact job/step provenance, six-file diff gate, and checkpoint approval | ❌ external artifact | ⬜ pending |
| 126-04-01 | 04 | 3 | POLISH-01, POLISH-02, POLISH-03 | T-126-12 | Six stable-row PNGs are reviewed individually full-size for semantic ink, Ticket hierarchy/reference fit, money integrity, and regressions; approved summary provenance explicitly authorizes deletion of the isolated CI ref only after all evidence is committed. | automated presence gate + manual visual checkpoint | `test -f tmp/rendro_phase126_review/swiss_invoice_light_page_1.png && test -f tmp/rendro_phase126_review/corporate_classic_invoice_dark_page_1.png && test -f tmp/rendro_phase126_review/editorial_ticket_dark_page_1.png && test -f tmp/rendro_phase126_review/minimal_mono_ticket_dark_page_1.png && test -f tmp/rendro_phase126_review/humanist_payslip_dark_page_1.png && test -f tmp/rendro_phase126_review/brutalist_payslip_dark_page_1.png` plus checkpoint approval and committed `visual_review: approved` / `cleanup_authorized: true` fields | ❌ CI artifact / human disposition | ⬜ pending |
| 126-05-01 | 05 | 4 | POLISH-01–POLISH-05 | T-126-14, T-126-15 | Only affected quality/WINDOWS records close from approved deterministic, pinned-CI, and human evidence; Validation completion is evidence-gated. | schema + docs contract + ledger check | `jq empty priv/quality/rubric_scores.json && mix test test/docs_contract/rubric_manifest_contract_test.exs && node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs windows list` | ✅ validators / ❌ updated records | ⬜ pending |
| 126-05-02 | 05 | 4 | POLISH-01–POLISH-05 | T-126-16 | Full deterministic phase gate, source audit, ten probes, and prohibitions pass without folding in advisory raster execution; after committed provenance, artifact changes, and Plan 04 approval are proven, every `retained_ci_ref` from failed and eventual evidence is deleted and remote absence is verified per ref. | focused + full deterministic suite + approved remote cleanup | `mix test test/rendro/recipes/invoice*_test.exs test/rendro/recipes/ticket*_test.exs test/rendro/recipes/payslip*_test.exs test/rendro/recipes/*_typography_test.exs test/rendro/theme/preset_accent_golden_test.exs test/rendro/theme/preset_render_matrix_test.exs --max-failures 1 && mix test && mix ci.fast` plus per-ref `git push origin --delete "$CI_REF"` and non-zero `git ls-remote --exit-code --heads origin "$CI_REF"`, with failed/eventual provenance and every cleanup result recorded in `126-05-SUMMARY.md` | ✅ harness / ❌ phase changes and cleanup evidence | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/theme/preset_accent_golden_test.exs` — bounded `from_brand`/preset × accent byte goldens for POLISH-04.
- [ ] `test/rendro/recipes/branded_invoice_typography_test.exs` — dedicated BrandedInvoice materialized typography contract.
- [ ] `test/rendro/recipes/payslip_typography_test.exs` — dedicated Payslip materialized typography and fallback contract.
- [ ] `test/rendro/recipes/receipt_typography_test.exs` — dedicated Receipt materialized typography contract.
- [ ] Focused assertions in the existing Invoice, Statement, Certificate, and Ticket typography modules for scale, font roles, leading, and explicit override precedence.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| The downloaded blessing artifact came from the guarded isolated-ref `push` of the exact tested commit and repository-pinned PDFium binary, with blessing confined to the successful `advisory-checks` job. | POLISH-01, POLISH-02, POLISH-03 | GitHub Actions is an external trust boundary; automated exact run/job selection and manifest checks are supplemented by an explicit run-log provenance disposition. | Open the Task 126-03-01 evidence run URL; confirm exact push/ref/SHA and `advisory-checks` success, disclose the adapter compare-only outcome, verify preset blessing/staging/upload and pinned manifest/payload, and inspect but do not require whole-run success. |
| Affected Invoice, Ticket, and Payslip rows remain legible with the intended hierarchy and no clipping. | POLISH-01, POLISH-02, POLISH-03 | Raster hashes prove pinned reproducibility but not reader-facing quality. | Render only affected rows through the pinned PDFium lane, then review each image full-size in a sequential slideshow/lightbox presentation. Record findings in `priv/quality/SIGN-OFF.md`, `priv/quality/rubric_scores.json`, and `.planning/WINDOWS.md`. |

---

## Validation Sign-Off

- [ ] All tasks have automated verification or explicit Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks lack automated verification.
- [ ] Wave 0 covers every missing test artifact.
- [ ] No watch-mode flags are used.
- [ ] Deterministic and advisory lanes remain separate.
- [ ] Feedback latency remains below 180 seconds for focused deterministic checks.
- [ ] `nyquist_compliant: true` is set after validation coverage is implemented and audited.

**Approval:** pending

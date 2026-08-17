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
| 126-01-01 | 01 | 1 | POLISH-01 | T-126-01 | Themed cells use validated semantic roles without changing unthemed callers. | unit + byte golden | `mix test test/rendro/recipes/invoice*_test.exs` | ✅ baseline / ❌ focused assertions | ⬜ pending |
| 126-01-02 | 01 | 1 | POLISH-02 | Required Ticket text remains visible and copyable; no new public input surface. | unit + deterministic matrix | `mix test test/rendro/recipes/ticket*_test.exs test/rendro/theme/preset_render_matrix_test.exs` | ✅ baseline / ❌ hierarchy assertions | ⬜ pending |
| 126-01-03 | 01 | 1 | POLISH-03 | Existing Decimal formatting and recipe validation remain authoritative. | unit + deterministic matrix | `mix test test/rendro/recipes/payslip*_test.exs test/rendro/theme/preset_render_matrix_test.exs` | ✅ baseline / ❌ atomic-money assertions | ⬜ pending |
| 126-02-01 | 02 | 1 | POLISH-04 | SHA-256 evidence is produced by the existing cryptographic primitive and deterministic renderer. | byte golden | `mix test test/rendro/theme/preset_accent_golden_test.exs` | ❌ W0 | ⬜ pending |
| 126-02-02 | 02 | 1 | POLISH-05 | Typography overrides stay within existing validated theme/recipe APIs. | unit | `mix test test/rendro/recipes/*typography_test.exs` | ❌ W0 additions | ⬜ pending |
| 126-03-01 | 03 | 2 | POLISH-01, POLISH-02, POLISH-03 | Raster evidence is accepted only from the pinned PDFium provenance route. | advisory raster + records | `mix test --include raster_snapshot test/rendro/theme/preset_raster_snapshot_test.exs` | ✅ harness | ⬜ pending |
| 126-03-02 | 03 | 2 | POLISH-01–POLISH-05 | Documentation records bounded evidence without WCAG/PDF-UA claims. | deterministic full suite | `mix test && mix ci.fast` | ✅ | ⬜ pending |

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

---
phase: 130
slug: catalog-quality-evidence-ratchet
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-19
revised: 2026-08-19
---

# Phase 130 — Validation Strategy

> Deterministic checks are merge authority. Candidate generation, pinned-PDFium output, and human review remain explicitly bounded evidence stages.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit, Elixir 1.19.5 / OTP 28 |
| Quick recipe command | modified family's structural, typography, and byte-identity suites |
| Candidate command | `mix rendro.catalog.candidate` under the pinned PDFium environment; fixed output `tmp/phase130-candidate` |
| Full deterministic command | `mix test --exclude quarantine --slowest 10 && mix rendro.catalog.check` |
| Advisory command | `RENDRO_CATALOG_REVIEW_DIR="$PWD/tmp/phase130-review" mix test --include raster_snapshot test/rendro/catalog_raster_review_test.exs` |

## Sampling Rate

- Run the focused three-file recipe command after each recipe task.
- Run payload/CI contract tests before any candidate generation.
- Run the candidate contract and exact 32-cell/diff gate immediately after the single pinned candidate batch.
- Begin human review only after the complete twelve-image identity-bound payload exists.
- After review transcription, run canonical generation exactly once, require candidate identity equality, then run all deterministic gates.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Evidence / secure behavior | Automated command or checkpoint evidence | File Exists | Status |
|---|---:|---:|---|---|---|---|---|---|
| 130-01-01 | 01 | 1 | CATALOG-06,07 | T-130-01A/B/C | Receipt semantic cells share measure/render identity; nil-theme bytes frozen | `mix test test/rendro/recipes/receipt_test.exs test/rendro/recipes/receipt_typography_test.exs test/rendro/recipes/receipt_byte_identity_test.exs --max-failures 1` | ✅ tests exist; assertions added by task | ⬜ pending |
| 130-01-02 | 01 | 1 | CATALOG-06 | T-130-01A/C | Invoice public-theme Total Due/due-date hierarchy | `mix test test/rendro/recipes/invoice_test.exs test/rendro/recipes/invoice_typography_test.exs test/rendro/recipes/invoice_byte_identity_test.exs --max-failures 1` | ✅ tests exist; assertions added by task | ⬜ pending |
| 130-01-03 | 01 | 1 | CATALOG-06 | T-130-01A/C | Statement public-theme closing-balance hierarchy | `mix test test/rendro/recipes/statement_test.exs test/rendro/recipes/statement_typography_test.exs test/rendro/recipes/statement_byte_identity_test.exs --max-failures 1` | ✅ tests exist; assertions added by task | ⬜ pending |
| 130-02-01 | 02 | 1 | CATALOG-06 | T-130-02A/B/C | Certificate rank and centering share exact resolved sizes | `mix test test/rendro/recipes/certificate_test.exs test/rendro/recipes/certificate_typography_test.exs test/rendro/recipes/certificate_byte_identity_test.exs --max-failures 1` | ✅ tests exist; assertions added by task | ⬜ pending |
| 130-02-02 | 02 | 1 | CATALOG-06 | T-130-02A/B/C | Payslip Net Pay hierarchy and atomic money | `mix test test/rendro/recipes/payslip_test.exs test/rendro/recipes/payslip_typography_test.exs test/rendro/recipes/payslip_byte_identity_test.exs --max-failures 1` | ✅ tests exist; assertions added by task | ⬜ pending |
| 130-02-03 | 02 | 1 | CATALOG-06 | T-130-02A/B/C | Ticket placement-first hierarchy and complete reference | `mix test test/rendro/recipes/ticket_test.exs test/rendro/recipes/ticket_typography_test.exs test/rendro/recipes/ticket_byte_identity_test.exs --max-failures 1` | ✅ tests exist; assertions added by task | ⬜ pending |
| 130-03-01 | 03 | 2 | CATALOG-09 | T-130-03A/C | Candidate-manifest-driven exact twelve-image payload; multipage separate | `mix format --check-formatted test/rendro/catalog_raster_review_test.exs && mix test test/rendro/catalog_raster_review_test.exs --exclude raster_snapshot --max-failures 1` | ✅ file exists; candidate assertions added by task | ⬜ pending |
| 130-03-02 | 03 | 2 | CATALOG-09 | T-130-03B/C | Full-40-SHA ref equality; advisory remains non-required | `mix test test/guardrails/required_checks_contract_test.exs --max-failures 1` | ✅ files exist; phase route assertions added by task | ⬜ pending |
| 130-04-01 | 04 | 3 | CATALOG-08,09 | T-130-04A/B/C/D | Fixed-target quality-free candidate seam; atomic cleanup; canonical bytes unchanged | `mix test test/rendro/catalog_test.exs test/docs_contract/catalog_quality_contract_test.exs --max-failures 1` | ✅ source/tests exist; candidate task is created here | ⬜ pending |
| 130-04-02 | 04 | 3 | CATALOG-08,09 | T-130-04A/D | Blocking exact-SHA authorization and pinned external batch provenance | Checkpoint evidence: approved full SHA/ref + successful job/run/pin + 32 candidate PNGs + 12 review PNGs | ❌ external artifacts absent until checkpoint | ⬜ pending |
| 130-04-03 | 04 | 3 | CATALOG-08,09 | T-130-04A/B/C/D | Exact 32 order/hash/page/dimension and three-way actual diff; canonical/evidence unchanged | six-family focused command + catalog/contracts + `jq` complete diff partition from Plan 04 | ❌ candidate manifest absent until Task 2 | ⬜ pending |
| 130-05-01 | 05 | 4 | CATALOG-09 | T-130-05A/B/C | Blocking full-size review; twelve exact integer/boolean/hash/provenance records | Checkpoint evidence: twelve complete records or `review blocked`; automated 12-image/unique-ID/candidate-count gate | ❌ review records absent until checkpoint | ⬜ pending |
| 130-06-01 | 06 | 5 | CATALOG-08,09 | T-130-06A/B/C | Exact transcription, actual changed-unscored rebind, one canonical generation, candidate identity equality | `jq` 12 scored + `mix rendro.catalog.check` + catalog/quality/rubric contract tests | ✅ durable files/tests exist; current records added by task | ⬜ pending |
| 130-06-02 | 06 | 5 | CATALOG-06,07,08,09 | T-130-06A/B/C/D | Complete deterministic/source/security gate and exact external-ref cleanup | six-family suites + catalog/contracts + full suite + `mix ci.fast` + 32/12 cardinality + validation flag | ✅ validation file exists; closure evidence pending | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ prerequisite artifact absent · ⚠️ flaky*

## Wave 0 Requirements and Owning Test-First Tasks

There is no separate prerequisite plan. Each gap is closed red-first by the earliest task that consumes it:

| Wave 0 gap | Owning task | Created assertion / proof |
|---|---|---|
| Receipt ink/muted, same structured cells, metric-font registration, nil-theme stability | 130-01-01 | Receipt structural/typography/byte assertions precede implementation |
| Invoice public supplied-theme hierarchy | 130-01-02 | Invoice structural assertion precedes hierarchy change |
| Statement public supplied-theme hierarchy | 130-01-03 | Statement structural assertion precedes hierarchy change |
| Certificate rank/centering coupling | 130-02-01 | Certificate structural assertion precedes hierarchy change |
| Payslip Net Pay/atomic money hierarchy | 130-02-02 | Payslip structural assertion precedes hierarchy change |
| Ticket placement/reference hierarchy | 130-02-03 | Ticket structural assertion precedes hierarchy change |
| Candidate-driven twelve-image/multipage split | 130-03-01 | Raster payload contract precedes staging implementation |
| Full-SHA phase-130 route and deterministic/advisory separation | 130-03-02 | Guardrail assertions precede CI change |
| Candidate-only generation, stale-score representation, atomic cleanup, actual-diff partition | 130-04-01 | Catalog/quality contract assertions precede dev-only seam |

`wave_0_complete` becomes true only when tasks 130-01-01 through 130-04-01 have committed their red-first assertions and pass green.

## Manual / External Evidence

| Task | Why non-automated | Required evidence |
|---|---|---|
| 130-04-02 | Pinned Linux PDFium and remote run identity are unavailable locally | Explicit exact-ref authorization; job bound to full SHA and pin; downloaded candidate/final/multipage artifacts |
| 130-05-01 | Aesthetic hierarchy/craft and bounded justification are human judgments | Full-size sequential inspection; twelve complete exact-identity records; every miss/dark remains needs_work |

## Validation Sign-Off

- [ ] All 14 final tasks/checkpoints are mapped above with real plan/wave/requirement/threat/evidence.
- [ ] All Wave 0 gaps map to the exact red-first task that creates the missing assertion.
- [ ] Candidate generation cannot write canonical assets or reviewer-owned evidence.
- [ ] Canonical generation occurs exactly once after review transcription and reproduces candidate identities.
- [ ] Deterministic and advisory lanes remain separate.
- [ ] `nyquist_compliant: true` is set only after 130-06-02 evidence exists.

**Approval:** pending execution evidence

---
phase: 136
slug: catalog-visual-quality
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-27
---

# Phase 136 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5 / OTP 28 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/catalog_test.exs test/rendro/catalog_review_payload_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs test/docs_contract/catalog_quality_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.fast` |
| **Estimated runtime** | ~90 seconds quick; repository-dependent for full suite |

---

## Sampling Rate

- **After every task commit:** Run the quick command plus the affected recipe test file(s).
- **After every plan wave:** Run `mix ci.fast` and `mix quality.governance`.
- **Before `$gsd-verify-work`:** Run `mix rendro.catalog.check`, `mix ci.fast`, and `mix quality.uat 136 --check`.
- **Evidence gate:** Dispatch one exact-SHA `review` workflow, validate the bundle before human review, and dispatch/check `canonical` only after the six-changed/26-identical proof and all six visual targets pass.
- **Max deterministic feedback latency:** 120 seconds for the focused lane; remote pinned-PDFium evidence is a separate advisory lane.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 136-01-01 | 01 | 1 | CATALOG-10, CATALOG-12 | T-136-01, T-136-02 | Exact dev-only six-ID map reaches one generic Invoice semantic path without recipe identity leakage | tracer contract/render | `mix test test/rendro/catalog_test.exs test/rendro/recipes/invoice_test.exs test/rendro/recipes/invoice_opts_threading_test.exs --max-failures 1` | ✅ existing files; additions pending | ⬜ pending |
| 136-01-02 | 01 | 1 | CATALOG-10, CATALOG-12 | T-136-01, T-136-03, T-136-04 | Ordered classifier proves six changed, zero changed-unscored, and 26 PDF/PNG byte-identical controls | deterministic catalog contract | `mix test test/rendro/catalog_test.exs --max-failures 1` | ✅ existing file; additions pending | ⬜ pending |
| 136-02-01 | 02 | 2 | CATALOG-11, CATALOG-12 | T-136-20, T-136-21, T-136-22, T-136-23 | Invoice semantic primary/secondary roles preserve Total Due, states, long content, and default bytes | recipe unit/render | `mix test test/rendro/recipes/invoice_test.exs test/rendro/recipes/invoice_opts_threading_test.exs --max-failures 1` | ✅ existing files; additions pending | ⬜ pending |
| 136-02-02 | 02 | 2 | CATALOG-11, CATALOG-12 | T-136-20, T-136-21, T-136-22, T-136-23 | Statement semantic ledger roles preserve Closing Balance, measured pagination, states, long content, and default bytes | recipe unit/render | `mix test test/rendro/recipes/statement_test.exs test/rendro/recipes/statement_opts_threading_test.exs --max-failures 1` | ✅ existing files; additions pending | ⬜ pending |
| 136-03-01 | 03 | 2 | CATALOG-11, CATALOG-12 | T-136-30, T-136-31, T-136-34 | Real Swiss target renders sequential measured ledgers with verbatim labels, atomic money, semantic dark roles, and dominant Net Pay | recipe tracer/render | `mix test test/rendro/recipes/payslip_test.exs --max-failures 1` | ✅ existing file; additions pending | ⬜ pending |
| 136-03-02 | 03 | 2 | CATALOG-11, CATALOG-12 | T-136-30, T-136-31, T-136-32, T-136-33, T-136-34 | Native continuation repeats owning headers, reserves reconciliation, proves edge states, geometry parity, and bytes | measured pagination/render | `mix test test/rendro/recipes/payslip_test.exs test/rendro/recipes/payslip_byte_identity_test.exs --max-failures 1` | ✅ existing files; additions pending | ⬜ pending |
| 136-04-01 | 04 | 2 | CATALOG-11, CATALOG-12 | T-136-40, T-136-41 | Ticket preserves one equal-share row and exact Section/GA, Row/H, Seat/24, Gate/B atomic association | recipe tracer/render | `mix test test/rendro/recipes/ticket_test.exs --max-failures 1` | ✅ existing file; additions pending | ⬜ pending |
| 136-04-02 | 04 | 2 | CATALOG-11, CATALOG-12 | T-136-42, T-136-43, T-136-44 | Ticket light/dark geometry parity, muted semantic contrast, held-out prose, default identity, and determinism | recipe unit/render | `mix test test/rendro/recipes/ticket_test.exs test/rendro/recipes/ticket_byte_identity_test.exs --max-failures 1` | ✅ existing files; additions pending | ⬜ pending |
| 136-05-01 | 05 | 3 | CATALOG-11, CATALOG-13 | T-136-50, T-136-51, T-136-52, T-136-54, T-136-55 | Exact-SHA bundle validates closed identities/roles/counts/hashes before any image interpretation; absence defers explicitly | bundle/reconciliation/docs contract | `mix test test/rendro/catalog_review_payload_contract_test.exs test/rendro/catalog_raster_review_test.exs test/docs_contract/catalog_evidence_runbook_test.exs --max-failures 1` | ✅ existing files; additions pending | ⬜ pending |
| 136-05-02 | 05 | 3 | CATALOG-11, CATALOG-13 | T-136-53, T-136-54, T-136-55 | Advisory named records bind exactly or remain unreviewed/unpromoted with non-blocking deferral/next action | advisory review + deterministic authority contract | `mix test test/rendro/catalog_review_payload_contract_test.exs test/docs_contract/catalog_evidence_runbook_test.exs --max-failures 1` | ✅ existing files; additions pending | ⬜ pending |
| 136-06-01 | 06 | 4 | CATALOG-10, CATALOG-11, CATALOG-12, CATALOG-13 | T-136-60, T-136-61, T-136-62, T-136-64 | Exact eligibility separates phase threshold from full passed and yields eligible or ineligible/no-write deterministically | docs/schema/catalog contract | `mix test test/docs_contract/rubric_manifest_contract_test.exs test/docs_contract/catalog_quality_contract_test.exs --max-failures 1` | ✅ existing files; additions pending | ⬜ pending |
| 136-06-02 | 06 | 4 | CATALOG-10, CATALOG-11, CATALOG-12, CATALOG-13 | T-136-60, T-136-61, T-136-62, T-136-63, T-136-64 | Eligible path materializes exact six targets/26 controls; ineligible path preserves canonical bytes and records next action | canonical materialization/check | `mix rendro.catalog.check` | ✅ existing files/artifacts; additions pending | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Task File Ownership

| Task ID | Exact owned files |
|---|---|
| 136-01-01 | `dev/rendro/catalog.ex`; `lib/rendro/recipes/invoice.ex`; `test/rendro/catalog_test.exs`; `test/rendro/recipes/invoice_test.exs`; `test/rendro/recipes/invoice_opts_threading_test.exs` |
| 136-01-02 | `dev/rendro/catalog.ex`; `test/rendro/catalog_test.exs` |
| 136-02-01 | `lib/rendro/recipes/invoice.ex`; `test/rendro/recipes/invoice_test.exs` |
| 136-02-02 | `lib/rendro/recipes/statement.ex`; `test/rendro/recipes/statement_test.exs` |
| 136-03-01 | `lib/rendro/recipes/payslip.ex`; `test/rendro/recipes/payslip_test.exs` |
| 136-03-02 | `lib/rendro/recipes/payslip.ex`; `test/rendro/recipes/payslip_test.exs`; `test/rendro/recipes/payslip_byte_identity_test.exs` |
| 136-04-01 | `lib/rendro/recipes/ticket.ex`; `test/rendro/recipes/ticket_test.exs` |
| 136-04-02 | `lib/rendro/recipes/ticket.ex`; `test/rendro/recipes/ticket_test.exs`; `test/rendro/recipes/ticket_byte_identity_test.exs` |
| 136-05-01 | `.github/workflows/CATALOG-EVIDENCE.md`; `test/docs_contract/catalog_evidence_runbook_test.exs`; `test/rendro/catalog_review_payload_contract_test.exs`; `test/rendro/catalog_raster_review_test.exs` |
| 136-05-02 | `priv/quality/rubric_scores.json`; `priv/quality/SIGN-OFF.md` |
| 136-06-01 | `test/docs_contract/rubric_manifest_contract_test.exs`; `test/docs_contract/catalog_quality_contract_test.exs` |
| 136-06-02 | `assets/rendro/catalog.json`; `assets/rendro/catalog/invoice/cedar-mutual/corporate-classic-dark.png`; `assets/rendro/catalog/statement/signal-ledger/minimal-mono-dark.png`; `assets/rendro/catalog/payslip/northline-logistics/swiss-light.png`; `assets/rendro/catalog/payslip/northline-logistics/swiss-dark.png`; `assets/rendro/catalog/ticket/aurora-live/brutalist-light.png`; `assets/rendro/catalog/ticket/aurora-live/brutalist-dark.png` |

Plans 136-02, 136-03, and 136-04 have zero cross-plan file overlap in Wave 2. Within-plan task overlap is intentional expansion from each tracer and remains serial inside that plan.

---

## Wave 0 Requirements

- [ ] Task 136-01-01 adds profile omission/activation, first semantic label, focal-anchor, identity-leakage, no-theme, and unrelated-theme cases to existing `catalog_test.exs`, `invoice_test.exs`, and `invoice_opts_threading_test.exs`.
- [ ] Task 136-01-02 adds exact ordered six/26 plus extra/missing/duplicate/reordered/empty/neighbor/hash-drift cases to existing `catalog_test.exs`.
- [ ] Tasks 136-02-01/02 add Invoice/Statement semantic, anchor, state, long-content, deterministic, and default-byte cases to their exact existing test files.
- [ ] Tasks 136-03-01/02 add Swiss sequential-ledger, long/wide, pagination/header/reconciliation, Unicode, geometry, and determinism cases to the two exact existing Payslip files.
- [ ] Tasks 136-04-01/02 add Ticket association/atomicity, semantic contrast, held-out prose, geometry, and determinism cases to the two exact existing Ticket files.
- [ ] Tasks 136-05-01/02 and 136-06-01 add exact evidence/advisory-deferral/eligibility negative controls to the exact existing evidence and docs-contract files named in the task map.

`wave_0_complete` remains `false` because every referenced test file already exists but the listed Phase 136 cases are intentionally created during execution by the owning task. The map is Nyquist-complete now; implementation evidence is not falsely marked complete before those tasks run.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Each target reaches hierarchy 5 and every other scored visual dimension at least 4 in the frozen rubric | CATALOG-11 | Visual hierarchy, association, rhythm, density, and polish require named human judgment | After exact bundle validation, optionally inspect eight full-size family-paired images and record six target results. Absence/incomplete/miss remains advisory, unreviewed/unpromoted, and routes to explicit deferral/next action without blocking deterministic completion. |
| Phase target success remains distinct from full rubric `passed` | CATALOG-11, CATALOG-12 | Human scores cannot establish print/compliance truth | Deterministic Plan 06 tests recompute the separate predicates; every dark record retains `print_safety: false`, and absent/missed review leaves canonical assets unchanged. |

Human review is advisory evidence. Deterministic checks establish reproducible completion coverage and cannot be replaced by an informal visual approval.

---

## Validation Sign-Off

- [x] All 12 tasks have exact `<automated>` verification commands.
- [x] Sampling continuity: every task has automated verification.
- [x] Wave 0 maps every pending test addition to an existing exact file and owner task.
- [x] No wildcard or watch-mode command remains.
- [x] Focused deterministic feedback latency is under 120 seconds.
- [x] Exact-SHA bundle validation precedes optional advisory image review.
- [x] Human absence/miss has an explicit non-blocking unreviewed/ineligible/no-write route.
- [x] `nyquist_compliant: true` reflects the finalized 12-task executable map while `wave_0_complete: false` truthfully reflects pending execution additions.

**Approval:** validation map complete; execution evidence pending

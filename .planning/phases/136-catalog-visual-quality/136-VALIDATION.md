---
phase: 136
slug: catalog-visual-quality
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
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
| 136-01-01 | 01 | 1 | CATALOG-10 | T-136-01 | Exact private six-ID allowlist; no catalog identity reaches recipes | contract/integration | `mix test test/rendro/catalog_test.exs --max-failures 1` | ❌ W0 additions | ⬜ pending |
| 136-01-02 | 01 | 1 | CATALOG-10, CATALOG-12 | T-136-01 | Candidate classification proves six changed and 26 byte-identical controls | deterministic render/contract | `mix test test/rendro/catalog_test.exs test/docs_contract/catalog_quality_contract_test.exs --max-failures 1` | ❌ W0 additions | ⬜ pending |
| 136-02-01 | 02 | 2 | CATALOG-11, CATALOG-12 | — | Dark invoice/statement semantic contrast changes remain target-scoped and preserve focal anchors | recipe unit/render | `mix test test/rendro/recipes/invoice*_test.exs test/rendro/recipes/statement*_test.exs --max-failures 1` | ❌ W0/profile coverage | ⬜ pending |
| 136-03-01 | 03 | 2 | CATALOG-11, CATALOG-12 | — | Payslip uses sequential measured ledgers with verbatim labels, atomic money, repeated headers, reconciliation, and light/dark geometry parity | recipe unit/render | `mix test test/rendro/recipes/payslip*_test.exs --max-failures 1` | ❌ W0/profile coverage | ⬜ pending |
| 136-04-01 | 04 | 2 | CATALOG-11, CATALOG-12 | — | Ticket preserves one-row `GA | H | 24 | B` source order and atomic label/value association in both themes | recipe unit/render | `mix test test/rendro/recipes/ticket*_test.exs --max-failures 1` | ❌ W0/profile coverage | ⬜ pending |
| 136-05-01 | 05 | 3 | CATALOG-11, CATALOG-13 | T-136-01, T-136-02 | Bundle identity, safe paths, closed roles/counts, hashes, run/attempt, and reviewer ownership validate before interpretation | bundle/reconciliation | `mix test test/rendro/catalog_review_payload_contract_test.exs test/rendro/catalog_raster_review_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 136-05-02 | 05 | 3 | CATALOG-11, CATALOG-12, CATALOG-13 | T-136-02 | Exact-SHA review records actual scores without promoting dark `print_safety: false` or equating phase thresholds with full rubric `passed` | docs/schema/contract + advisory review | `mix test test/docs_contract/rubric_manifest_contract_test.exs test/docs_contract/catalog_quality_contract_test.exs --max-failures 1` | ✅ (extend if needed) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Add focused coverage for generic profile omission/activation, semantic dark label roles, focal anchors, and no-theme/non-target byte identity.
- [ ] Add Payslip cases for verbatim long descriptions, widest money token, sequential headers, native continuation/repeated headers, reconciliation adjacency, and two-render identity.
- [ ] Add Ticket cases for `GA`, `H`, `24`, `B` source order, atomic values, label/value association, and light/dark identical geometry.
- [ ] Add candidate classification cases asserting the exact ordered six changed IDs and 26 byte-identical controls, including extra/missing/reordered negative controls.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Each target reaches hierarchy 5 and every other scored visual dimension at least 4 in the frozen rubric | CATALOG-11 | Visual hierarchy, association, rhythm, density, and polish require named human judgment | Validate the exact-SHA pinned-PDFium `review` bundle first; inspect the six full-size PNGs in family-paired order; record per-cell scores, reviewer identity, notes, and disposition without altering generator output. |
| Phase target success remains distinct from full rubric `passed` | CATALOG-11, CATALOG-12 | The reviewer must confirm the record communicates the truthful dark screen-only boundary | Confirm every dark record retains `print_safety: false`; do not set `passed: true` unless the existing complete rubric arithmetic independently permits it. |

Human review is advisory evidence. Deterministic checks establish reproducible completion coverage and cannot be replaced by an informal visual approval.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Focused deterministic feedback latency is under 120 seconds.
- [ ] Exact-SHA bundle validation precedes human image review.
- [ ] `nyquist_compliant: true` is set only after the plan/task map is finalized and executable.

**Approval:** pending

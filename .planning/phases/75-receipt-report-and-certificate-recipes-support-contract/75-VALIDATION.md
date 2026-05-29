---
phase: 75
slug: receipt-report-and-certificate-recipes-support-contract
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-29
---

# Phase 75 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in Elixir) |
| **Config file** | `test/test_helper.exs` (standard) |
| **Quick run command** | `mix test test/rendro/recipes/receipt_test.exs test/rendro/recipes/certificate_test.exs` |
| **Full suite command** | `mix test` |
| **Statement regression command** | `mix test test/rendro/recipes/statement_test.exs` |
| **Docs-contract command** | `mix test test/docs_contract/viewer_evidence_claims_test.exs` |
| **Estimated runtime** | ~30 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run the affected recipe test (`statement_test.exs` during D-04 extraction; `receipt_test.exs` / `certificate_test.exs` during builds)
- **After every plan wave:** Run `mix test` (full suite)
- **Before `/gsd-verify-work`:** Full suite green AND `mix test test/docs_contract/viewer_evidence_claims_test.exs` green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 75-01-xx | 01 | 1 | D-04 | — | N/A | regression | `mix test test/rendro/recipes/statement_test.exs` | ✅ (51 tests) | ⬜ pending |
| 75-02-xx | 02 | 2 | RCPT-01/02/03, D-10 | — | N/A | unit | `mix test test/rendro/recipes/receipt_test.exs` | ❌ W0 | ⬜ pending |
| 75-03-xx | 03 | 2 | CERT-01/02/03, D-05/D-06 | — | N/A | unit | `mix test test/rendro/recipes/certificate_test.exs` | ❌ W0 | ⬜ pending |
| 75-04-xx | 04 | 3 | CONTRACT-01 | — | input not trusted as proof | docs-contract | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ✅ (21 tests) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Requirement → Behavior Coverage

| Req ID | Behavior | Test Type | Command |
|--------|----------|-----------|---------|
| RCPT-01 | Receipt renders from data map; column headers repeat on multi-page | unit | `mix test test/rendro/recipes/receipt_test.exs` |
| RCPT-02 | Three-rung escape hatch (`page_template/1`, `sections/2`, `document/2`) callable independently | unit | same |
| RCPT-03 | Multi-page with correct "Page X of Y" footer; byte-identical determinism | unit | same |
| CERT-01 | Certificate renders from data map (title, recipient, body, date, seal) | unit | `mix test test/rendro/recipes/certificate_test.exs` |
| CERT-02 | Region geometry derived from page size; A4-landscape ≠ US-Letter body width; both render without overflow; no hardcoded A4 | unit | same |
| CERT-03 | Branded registers font+image; unbranded renders; malformed brand raises | unit | same |
| CONTRACT-01 | support_matrix.json passes schema validation with 5 new + backfilled Statement rows; no silent `unverified` | docs-contract | `mix test test/docs_contract/viewer_evidence_claims_test.exs` |
| D-04 | Statement's 51 tests still pass after shared-helper extraction (determinism preserved) | regression | `mix test test/rendro/recipes/statement_test.exs` |

---

## Wave 0 Requirements

- [ ] `test/rendro/recipes/receipt_test.exs` — covers RCPT-01..03, V1..V10
- [ ] `test/rendro/recipes/certificate_test.exs` — covers CERT-01..03, C1..C13
- [ ] `lib/rendro/recipes/pagination.ex` (or chosen name) — shared helper scaffold with function stubs
- [ ] `lib/rendro/page_size.ex` (or chosen placement) — page-size helper stub (`:a4`, `:us_letter`, landscape swap)

*Statement test suite already exists (51 tests) and is the D-04 regression gate — no Wave 0 work for it.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Statement support-matrix row backfilled | CONTRACT-01 | Presence check of a JSON key | `grep "statement" priv/support_matrix.json` returns a terminal row |

*All other phase behaviors have automated verification via ExUnit / docs-contract lanes.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (receipt_test, certificate_test, shared helper, page-size helper)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

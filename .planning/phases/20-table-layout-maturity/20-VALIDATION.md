---
phase: 20
slug: table-layout-maturity
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-29
updated: 2026-04-29
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for deterministic table geometry, atomic-row pagination, and truthful public-surface cleanup.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro_builders_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/pdf/writer_test.exs test/rendro/flow_test.exs test/rendro/adapters/accrue_test.exs test/docs_contract/readme_doctest_test.exs test/docs_contract/integrations_contract_test.exs` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | ~15-25 seconds |

---

## Sampling Rate

- **After every task commit:** run the smallest affected subset for the touched seam.
- **After every plan wave:** run the full Phase 20 quick suite.
- **Before `$gsd-verify-work`:** `mix ci` and `mix run scripts/verify_docs.exs` must both pass.
- **Max feedback latency:** 25 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-01-01 | 01 | 1 | LAY-10 | T-20-01, T-20-02 | Public table builders expose explicit deterministic `columns` rules and atomic row-split policy without preserving misleading `width`/`border` geometry inputs. | unit | `mix test test/rendro_builders_test.exs test/rendro/pipeline/measure_test.exs` | ✅ | ⬜ pending |
| 20-01-02 | 01 | 1 | LAY-10 | T-20-02, T-20-03, T-20-04 | Measured column widths, row/header heights, repeated headers, and impossible-row overflow details drive continuation and rendering through one engine path. | unit + integration | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/pdf/writer_test.exs test/rendro/flow_test.exs` | ✅ | ⬜ pending |
| 20-02-01 | 02 | 2 | LAY-10 | T-20-05, T-20-06, T-20-07 | Public builders, recipes, and adapters expose only the supported Phase 20 table contract and reject removed legacy attrs with migration-oriented guidance. | unit + integration | `mix test test/rendro_builders_test.exs test/rendro/adapters/accrue_test.exs test/rendro/flow_test.exs` | ✅ | ⬜ pending |
| 20-02-02 | 02 | 2 | LAY-10 | T-20-05, T-20-08 | README, integration guide, and docs-contract fixtures teach explicit columns, repeated headers, atomic rows, and unsupported-boundary language truthfully. | docs-contract + integration | `mix test test/docs_contract/readme_doctest_test.exs test/docs_contract/integrations_contract_test.exs test/rendro/flow_test.exs && mix run scripts/verify_docs.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers the framework/bootstrap prerequisites for this phase.

Implementation-proof gaps are already assigned to execution tasks:
- `20-01-01` — add deterministic column-rule and measured row-height coverage in `test/rendro/pipeline/measure_test.exs`
- `20-01-02` — add repeated-header continuation, impossible-row overflow, and writer-coordinate proofs
- `20-02-01` — add builder rejection or migration-path coverage for removed `:width` and `:border` attrs
- `20-02-02` — add docs-contract coverage for the narrowed public table examples

---

## Manual-Only Verifications

None. Phase 20 should close entirely through committed ExUnit and docs-contract proof.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all proof surfaces referenced in research and plans
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-29

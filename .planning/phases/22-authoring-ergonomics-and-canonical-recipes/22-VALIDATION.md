---
phase: 22
slug: authoring-ergonomics-and-canonical-recipes
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-29
updated: 2026-04-30
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for the builder API, tiered-composition recipes, and the Phoenix example handoff.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/document_test.exs test/rendro/recipes/invoice_test.exs test/rendro/adapters/accrue_test.exs test/docs_contract/readme_doctest_test.exs && cd examples/phoenix_example && mix test test/phoenix_example_web/controllers/pdf_controller_test.exs` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | ~20-30 seconds |

---

## Sampling Rate

- **After every task commit:** run the smallest affected authoring/docs subset.
- **After every plan wave:** run the full Phase 22 quick suite.
- **Before `$gsd-verify-work`:** `mix ci` plus the Phoenix example controller test must be green.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | LAY-12 | T-22-01 | `Rendro.Document` exposes a pipeable builder API that accumulates templates, sections, metadata, and options deterministically. | unit | `mix test test/rendro/document_test.exs` | ✅ | ⬜ pending |
| 22-02-01 | 02 | 2 | LAY-12 | T-22-02 | Canonical invoice and Accrue recipes use tiered composition plus explicit page-template regions instead of legacy header/footer kwargs. | unit + integration | `mix test test/rendro/recipes/invoice_test.exs test/rendro/adapters/accrue_test.exs` | ✅ | ⬜ pending |
| 22-03-01 | 03 | 3 | LAY-12 | T-22-03 | README guidance and the Phoenix example controller teach the supported authoring surface truthfully through the canonical recipe path. | docs-contract + integration | `mix test test/docs_contract/readme_doctest_test.exs && cd examples/phoenix_example && mix test test/phoenix_example_web/controllers/pdf_controller_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ mixed*

---

## Wave 0 Requirements

- [x] `test/rendro/document_test.exs`, `test/rendro/recipes/invoice_test.exs`, `test/rendro/adapters/accrue_test.exs`, and `test/docs_contract/readme_doctest_test.exs` exist for core proof.
- [x] `examples/phoenix_example/test/phoenix_example_web/controllers/pdf_controller_test.exs` exists for the end-to-end example seam.
- [x] No additional framework setup is required beyond the existing test projects.

---

## Manual-Only Verifications

None. Phase 22 should close through committed ExUnit, docs-contract, and example-controller proof.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all proof surfaces referenced in research and plans
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** normalized to Nyquist structure on 2026-04-30.

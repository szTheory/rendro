---
phase: 134
slug: core-architecture-readability
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-26
---

# Phase 134 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test <focused-files>` |
| **Full suite command** | `mix ci.fast` |
| **Estimated runtime** | Focused checks under 30 seconds; full suite uses the current CI baseline |

---

## Sampling Rate

- **After every task commit:** Run the candidate-specific focused ExUnit files plus `mix quality.governance` after ledger edits.
- **After every plan wave:** Run the public-manifest contracts and affected deterministic byte-identity tests.
- **Before `$gsd-verify-work`:** `mix ci.fast` must be green.
- **Max feedback latency:** 30 seconds for focused checks; advisory/remote evidence remains separately classified and non-blocking.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 134-01-01 | 01 | 1 | ARCH-02, ARCH-03, ARCH-04 | T-134-01 | Historical candidates receive evidence-backed ledger dispositions before repair | governance/xref | `mix quality.governance && mix xref callers Rendro.I18n.Analyzer` | ✅ governance | ⬜ pending |
| 134-01-02 | 01 | 1 | ARCH-01, ARCH-03 | T-134-03 | Accepted palette extraction receives a targeted fail-first characterization before implementation | unit/RED | `mix test test/rendro/recipes/palette_test.exs` must fail for the missing helper contract | ❌ W0 palette test | ⬜ pending |
| 134-02-01 | 02 | 2 | ARCH-01, ARCH-02 | T-134-04 | Dead-code removal cannot delete a public, dynamic, or compiled production dependency or alter deterministic rendered bytes | focused/render | `mix test test/rendro/text/shaper_test.exs test/rendro/error_test.exs test/rendro/i18n_test.exs test/rendro/pipeline/measure_test.exs test/rendro/recipes/*_byte_identity_test.exs` | ✅ | ⬜ pending |
| 134-02-02 | 02 | 2 | ARCH-01, ARCH-02 | T-134-05 | Analyzer closure records public-manifest and deterministic rendered-byte identity against the repository's final pair state | contract/render/governance | `mix test test/rendro/public_api/manifest_test.exs test/docs_contract/public_api_contract_test.exs test/rendro/recipes/*_byte_identity_test.exs && mix quality.governance` | ✅ | ⬜ pending |
| 134-03-01 | 03 | 3 | ARCH-01, ARCH-02, ARCH-03 | T-134-06, T-134-07 | Uniform palette defaults, theme resolution, failure shape, and `:palette` last-wins precedence become green through one hidden helper before migration | unit/GREEN | `mix test test/rendro/recipes/palette_test.exs` | ❌ W0 palette test | ⬜ pending |
| 134-04-01 | 04 | 4 | ARCH-01, ARCH-02, ARCH-03 | T-134-06, T-134-07 | First four recipe migrations retain exact deterministic, option, and failure contracts | render/contract | focused byte-identity and opts-threading tests for Invoice, Receipt, BrandedInvoice, and Payslip | ✅ | ⬜ pending |
| 134-04-02 | 04 | 4 | ARCH-01, ARCH-02, ARCH-03 | T-134-06, T-134-07 | Remaining three recipe migrations retain exact deterministic, option, and failure contracts | render/contract | focused byte-identity and opts-threading tests for Ticket, Statement, and Certificate plus palette/themed smoke | ✅ | ⬜ pending |
| 134-05-01 | 05 | 5 | ARCH-02, ARCH-04 | T-134-08 | Bounded narration/spec/doc/comment audit requires a line-specific accepted finding for edits and otherwise preserves source/provenance through no-op/reject_signal | governance/docs/static/type | `mix quality.governance && mix docs --warnings-as-errors && mix credo --strict && mix dialyzer` | ✅ infrastructure | ⬜ pending |
| 134-05-02 | 05 | 5 | ARCH-01, ARCH-02, ARCH-03, ARCH-04 | T-134-09 | Original finding lifecycles close only with focused, manifest, rendered-byte, docs/type/static, governance, and full-CI proof | terminal | `mix test test/rendro/public_api/manifest_test.exs test/docs_contract/public_api_contract_test.exs test/rendro/recipes/*_byte_identity_test.exs test/rendro/recipes/themed_render_smoke_test.exs && mix docs --warnings-as-errors && mix credo --strict && mix dialyzer && mix quality.governance && mix ci.fast` | ✅ infrastructure | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/recipes/palette_test.exs` — characterize all seven recipe legacy-default maps, `:theme` resolution, and `:palette` last-wins precedence before accepting an extraction.
- [ ] Permanent ledger records for each validated historical candidate — add only after the evidence slice determines identity, impact, disposition, scope, verification, and trigger.

---

## Manual-Only Verifications

All Phase 134 completion claims have automated verification. Optional maintainer review may enrich evidence but cannot block or substitute for deterministic closure.

---

## Threat Model References

- **T-134-01–T-134-03:** Candidate intake, provenance, and palette Wave 0 authorization are gated by current evidence and explicit ledger dispositions.
- **T-134-04–T-134-05:** Analyzer deletion and closure require zero-consumer proof, active-shaper tests, public-manifest identity, deterministic rendered-byte identity without golden refresh, and agreement between ledger and repository state.
- **T-134-06–T-134-07:** Shared palette resolution preserves every legacy default, merge tie-break, invalid-input failure, and affected deterministic byte golden.
- **T-134-08–T-134-09:** Comment/spec truthfulness and terminal ledger closure preserve provenance and require line-specific evidence plus docs, Credo, Dialyzer, governance, and full deterministic CI.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

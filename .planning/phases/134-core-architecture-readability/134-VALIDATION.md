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
| 134-01-01 | 01 | 1 | ARCH-02, ARCH-03 | T-134-01 | Historical candidates receive evidence-backed ledger dispositions before repair | governance/xref | `mix quality.governance && mix xref callers Rendro.I18n.Analyzer` | ✅ governance | ⬜ pending |
| 134-02-01 | 02 | 2 | ARCH-01, ARCH-02 | T-134-02 | Dead-code removal cannot delete a public, dynamic, or compiled production dependency | contract/focused | `mix test test/rendro/public_api/manifest_test.exs test/docs_contract/public_api_contract_test.exs test/rendro/i18n_test.exs` | ✅ | ⬜ pending |
| 134-03-01 | 03 | 2 | ARCH-01, ARCH-03 | T-134-03 | Palette defaults, theme resolution, and `:palette` last-wins precedence stay exact | unit/render | `mix test test/rendro/recipes/palette_test.exs test/rendro/recipes/*_byte_identity_test.exs` | ❌ W0 palette test | ⬜ pending |
| 134-04-01 | 04 | 3 | ARCH-01, ARCH-04 | T-134-04 | Truthful docs/spec/comment cleanup preserves public surface, types, bytes, and provenance | docs/static/type/terminal | `mix docs --warnings-as-errors && mix credo --strict && mix dialyzer && mix ci.fast` | ✅ infrastructure | ⬜ pending |

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

- **T-134-01:** A diagnostic or historical note is promoted into repair work without current concrete harm. Mitigation: ledger disposition before repair and explicit `reject_signal`/deferral paths.
- **T-134-02:** Dead-code deletion removes a public, dynamic, compile-time, or documentation consumer. Mitigation: source/xref/manifest/docs checks before deletion plus focused active-path tests.
- **T-134-03:** Shared palette resolution changes a legacy default or override precedence. Mitigation: Wave 0 characterization and affected byte-identity tests.
- **T-134-04:** Comment/spec cleanup erases operational provenance or changes a public contract. Mitigation: line-specific evidence, public-manifest identity, docs warnings-as-errors, Credo, Dialyzer, and full deterministic CI.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

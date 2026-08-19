---
phase: 129
slug: docs-manifest-closure
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-19
---

# Phase 129 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/docs_contract/presets_claims_test.exs test/docs_contract/theming_claims_test.exs test/docs_contract/public_api_contract_test.exs test/guardrails/required_checks_contract_test.exs` |
| **Full suite command** | `mix ci.fast` |
| **Estimated runtime** | Quick: under 30 seconds; full: under 10 minutes |

---

## Sampling Rate

- **After every task commit:** Run the narrowest affected ExUnit file plus `test/docs_contract/presets_claims_test.exs` once it exists.
- **After every plan wave:** Run the quick command above, substituting the new test path only after its Wave 0 task creates it.
- **Before `$gsd-verify-work`:** `mix ci.fast` must be green.
- **Max feedback latency:** 30 seconds for task-level checks; 10 minutes for the phase-wide gate.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 129-01-01 | 01 | 1 | DOCS-01 | — | Public claims fail closed on missing proof, forbidden guarantees, broken links, or omitted package assets. | semantic/integration contract | `mix test test/docs_contract/presets_claims_test.exs` | ❌ W0 | ⬜ pending |
| 129-02-01 | 02 | 2 | DOCS-01 | — | Guide and README expose only formatter-owned code and evidence-bounded copy. | executable docs contract | `mix test test/docs_contract/presets_claims_test.exs test/docs_contract/theming_claims_test.exs` | ❌ W0 | ⬜ pending |
| 129-03-01 | 03 | 3 | DOCS-01 | — | API/support/guardrail manifests agree with generated code and the 27-lane registry. | deterministic manifest/guardrail contract | `mix test test/docs_contract/public_api_contract_test.exs test/docs_contract/presets_claims_test.exs test/guardrails/required_checks_contract_test.exs` | Mixed: existing + ❌ W0 | ⬜ pending |
| 129-03-02 | 03 | 3 | DOCS-01 | — | Source, Hex tarball, and generated ExDoc paths resolve while private assets remain excluded. | package/docs integration | `mix test test/docs_contract/presets_claims_test.exs && mix docs --warnings-as-errors` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/docs_contract/presets_claims_test.exs` — cross-surface required/forbidden language, formatter snippet parity, proof-backed support row, mutation teeth, and source/tarball/ExDoc link checks for DOCS-01.
- [ ] Extend the existing package-content assertions through the new lane or the closest established tarball contract so the required public catalog/configurator/token payload is positively asserted and private exclusions remain intact.

---

## Manual-Only Verifications

All phase behaviors should have automated verification. Human prose review may supplement the contract tests but cannot replace them.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency stays within the limits above.
- [ ] `nyquist_compliant: true` is set after validation evidence exists.

**Approval:** pending

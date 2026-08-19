---
phase: 129
slug: docs-manifest-closure
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| 129-01-01 | 01 | 1 | DOCS-01 | — | Public claims fail closed on missing proof, forbidden guarantees, broken links, or omitted package assets. | semantic/integration contract | `mix test test/docs_contract/presets_claims_test.exs` | ✅ | ✅ green |
| 129-02-01 | 02 | 2 | DOCS-01 | — | Guide and README expose only formatter-owned code and evidence-bounded copy, including preview, screen-output, and quality-label disclosures. | executable docs contract | `mix test test/docs_contract/presets_claims_test.exs test/docs_contract/theming_claims_test.exs` | ✅ | ✅ green |
| 129-03-01 | 03 | 3 | DOCS-01 | — | API/support/guardrail manifests agree with generated code and the 27-lane registry. | deterministic manifest/guardrail contract | `mix test test/docs_contract/public_api_contract_test.exs test/docs_contract/presets_claims_test.exs test/guardrails/required_checks_contract_test.exs` | ✅ | ✅ green |
| 129-03-02 | 03 | 3 | DOCS-01 | — | Source, Hex tarball, and generated ExDoc paths resolve while private assets remain excluded. | package/docs integration | `mix test test/docs_contract/presets_claims_test.exs && mix docs --warnings-as-errors` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/docs_contract/presets_claims_test.exs` — cross-surface required/forbidden language, formatter snippet parity, proof-backed support row, mutation teeth, visible preview/output/quality disclosures, and source/tarball/ExDoc link checks for DOCS-01.
- [x] Package-content assertions positively cover the public catalog/configurator/token payload and retain private evidence exclusions; the shared Hex archive cache is isolated across concurrent BEAM VMs.

---

## Manual-Only Verifications

All phase behaviors should have automated verification. Human prose review may supplement the contract tests but cannot replace them.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or completed Wave 0 dependencies.
- [x] Sampling continuity: no three consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency stays within the limits above.
- [x] `nyquist_compliant: true` is set after validation evidence exists.

**Approval:** validated — 2026-08-19

## Validation Audit 2026-08-19

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

Evidence: the 60-test Phase 129 focus set, all 27 deterministic docs lanes, and `mix ci.fast` pass from the audited HEAD. The added contract locks the exact/representative/unavailable preview states, screen-oriented dark-output boundary, and all three quality labels.

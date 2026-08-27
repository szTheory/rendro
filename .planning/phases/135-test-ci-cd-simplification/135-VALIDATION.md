---
phase: 135
slug: test-ci-cd-simplification
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-27
---

# Phase 135 — Validation Strategy

> Per-phase validation contract. Deterministic local checks establish structural and behavioral contracts; source-SHA-bound Ubuntu/PDFium runs establish remote parity without becoming ordinary `ci-success` authority.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/catalog_evidence_bundle_test.exs test/rendro/catalog_evidence_parity_test.exs test/docs_contract/phase_135_test_inventory_contract_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.fast` |
| **Estimated runtime** | Focused checks under 30 seconds; remote paired evidence runs separately on GitHub-hosted Ubuntu with pinned PDFium |

---

## Sampling Rate

- **After every task commit:** Run the narrowest affected ExUnit file and `mix format --check-formatted` for changed Elixir files.
- **After every plan wave:** Run `mix ci.fast`; run `mix ci` when aliases or proof-lane guardrails change.
- **Before `$gsd-verify-work`:** The deterministic suite must be green, focused negative controls must demonstrate rejection, and the four source-SHA-bound remote parity rows must be recorded before legacy-route deletion.
- **Max feedback latency:** 30 seconds for focused deterministic checks. Remote Ubuntu/PDFium evidence has separate availability and authority semantics.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 135-W0-01 | 135-01 | 0 | TEST-01, TEST-02 | T-135-01 | Inventory has exactly the two authorized ordered D-05 rows, required columns, and valid result states; only the proven duplicate assertion is removed | docs contract/regression | `mix test test/docs_contract/phase_135_test_inventory_contract_test.exs test/rendro/recipes/themed_render_smoke_test.exs test/rendro/recipes/payslip_opts_threading_test.exs test/rendro/recipes/certificate*_test.exs --max-failures 1` | ❌ Wave 0 | ⬜ pending |
| 135-W0-02 | TBD | 0 | CI-01, CI-04 | T-135-02, T-135-03 | Closed inputs, exact SHA/HEAD binding, safe paths, read-only permissions, pinned actions, no secrets/caches, and one valid bundle fail closed | unit/workflow contract | `mix test test/rendro/catalog_evidence_bundle_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` | ❌ Wave 0 | ⬜ pending |
| 135-W0-03 | 135-01, 135-03 | 0 | CI-02 | T-135-04 | Comparator equates only shared semantic/authority facts; it accepts different valid per-side run/attempt/artifact/digest provenance and rejects missing, malformed, or misbound provenance; inventory contract pins exactly four route rows/states | unit + docs contract + remote parity | `mix test test/rendro/catalog_evidence_parity_test.exs test/docs_contract/phase_135_test_inventory_contract_test.exs --max-failures 1` plus paired remote dispatches | ❌ Wave 0 | ⬜ pending |
| 135-W0-04 | TBD | 0 | CI-03 | T-135-05 | Deterministic, proof, and advisory lanes plus authoritative `ci-success` topology remain unchanged | guardrail | `mix test test/guardrails/required_checks_contract_test.exs --max-failures 1` | ✅ extend existing | ⬜ pending |
| 135-W0-05 | TBD | 0 | CI-05 | T-135-06 | Current runbook exposes supported commands, identities, limits, authority, and failure recovery without requiring archived plans | docs contract | `mix test test/docs_contract/catalog_evidence_runbook_test.exs --max-failures 1` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/catalog_evidence_bundle_test.exs` — bundle schema, path confinement, checksum, cardinality, duplicate, unsafe-path, SHA-binding, and operation-negative controls for CI-01/CI-04.
- [ ] `test/rendro/catalog_evidence_parity_test.exs` — normalized role/hash/authority comparator with a deliberately mismatched fixture for CI-02.
- [ ] `test/docs_contract/phase_135_test_inventory_contract_test.exs` — exact two-row D-05 recipe schema/order/state and four-row D-18 parity route/order/state contract.
- [ ] `test/docs_contract/catalog_evidence_runbook_test.exs` — supported operator commands and truthful authority/limit claims for CI-05.
- [ ] Extend `test/guardrails/required_checks_contract_test.exs` — generic-workflow security, unchanged `ci-success` topology, and post-cutover legacy-route absence.
- [ ] `135-test-inventory.md` — bounded TEST-01/TEST-02 owner-oracle-failure-negative-control inventory and four-row remote parity matrix consumed by the focused contract.

---

## Remote Authority and Explicit Deferral

| Evidence | Authority | Completion Semantics | Rule |
|----------|-----------|----------------------|------|
| Local ExUnit/workflow contracts | deterministic | blocking | Must reject malformed bundles, unsafe workflow structure, mismatched parity fixtures, and false documentation claims. |
| GitHub-hosted Ubuntu/PDFium paired runs | remote proof/advisory | blocks Plan 135-03 legacy-route deletion only; never Plans 135-01/02 | Compare shared semantic/authority facts on the same full candidate SHA, validate distinct per-side provenance independently, and commit one passing row for Phase 126 bless, Phase 127 bless, Phase 130 review, and Phase 130 canonical. |
| Repeated generic remote runs | corroborating | non-substitutive | May enrich confidence but cannot replace any required route-specific parity row. |
| Qualitative maintainer feedback | advisory | non-blocking | May improve operator ergonomics but cannot satisfy deterministic or remote parity claims. |

---

## Threat Model References

- **T-135-01:** Similar test wording can conceal distinct oracles; inventory and focused regression checks prevent accidental behavior loss.
- **T-135-02:** The default-branch workflow definition is trusted control plane while checked-out candidate code is untrusted input; exact SHA/HEAD binding and environment-mediated inputs prevent substitution and script injection.
- **T-135-03:** Read-only permissions, no secrets, no caches, no privilege bridge, safe path handling, and full-SHA action pins contain workflow and supply-chain risk.
- **T-135-04:** Shared semantic role/hash/count and authority equality plus independent per-side run/attempt/artifact/digest validation prevent both packaging noise and misbound provenance from masquerading as parity.
- **T-135-05:** The new evidence workflow remains disconnected from `ci-success`; existing deterministic, proof, and advisory authorities cannot collapse.
- **T-135-06:** One current adjacent runbook with concrete what/where/why/next microcopy prevents archived planning artifacts or backend implementation details from becoming the operator interface.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing test references.
- [ ] No watch-mode flags.
- [ ] Focused deterministic feedback latency stays under 30 seconds.
- [ ] Four required remote parity rows bind to one exact full candidate SHA before route deletion.
- [ ] `nyquist_compliant: true` is set after execution evidence is captured.

**Approval:** pending

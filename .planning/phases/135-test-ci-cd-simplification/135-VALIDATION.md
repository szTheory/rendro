---
phase: 135
slug: test-ci-cd-simplification
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false)
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| 135-01-01 | 135-01 | 1 | CI-01, CI-04 | T-135-01, T-135-02, T-135-03 | Closed manifest bundle rejects invalid operation/SHA/HEAD, unsafe role/path, incorrect record count, payload hash drift, and review approval claims | unit | `mix test test/rendro/catalog_evidence_bundle_test.exs --max-failures 1` | ✅ | ✅ green |
| 135-01-02 | 135-01 | 1 | CI-02 | T-135-04 | Sealed provenance record rejects malformed/misbound transport facts, duplicate IDs, hash/cardinality drift, scalar role records, and fabricated statuses | unit | `mix test test/rendro/catalog_evidence_parity_test.exs --max-failures 1` | ✅ | ✅ green |
| 135-01-03 | 135-01 | 1 | TEST-01, TEST-02, CI-02 | T-135-01, T-135-04 | Inventory uses exactly two ordered recipe rows and four ordered, same-SHA parity rows; every one of the 16 parity columns is bound to the sealed-record projection and each one-cell mutation fails | docs contract | `mix test test/docs_contract/phase_135_test_inventory_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 135-01-04 | 135-01 | 1 | TEST-01, TEST-02 | T-135-01 | Retained Payslip smoke owner rejects a removed fallback registry while distinct opts, typography, deterministic-byte, and Certificate construction contracts remain | regression | `mix test test/rendro/recipes/themed_render_smoke_test.exs test/rendro/recipes/payslip_opts_threading_test.exs test/rendro/recipes/payslip_typography_test.exs test/rendro/recipes/certificate_typography_test.exs --max-failures 1` | ✅ | ✅ green |
| 135-02-01 | 135-02 | 2 | CI-01, CI-03, CI-04 | T-135-02, T-135-03, T-135-05 | Parsed workflow guardrails enforce manual-only exact-SHA isolation, credential-free checkouts, immutable pins, no secrets/cache/write/bridge, bounded uploads, unchanged CI lanes and sole `ci-success`; post-cutover retired routes are absent | workflow contract | `mix test test/guardrails/required_checks_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 135-02-02 | 135-02 | 2 | CI-05 | T-135-06 | One current adjacent runbook contains dispatch/download/validation/reproduction/recovery commands and explicit non-authority boundaries; its docs lane and helper link are registered exactly once | docs contract | `mix test test/docs_contract/catalog_evidence_runbook_test.exs && mix run scripts/verify_docs.exs` | ✅ | ✅ green |
| 135-03-01 | 135-03 | 3 | CI-02, CI-03, CI-04 | T-135-04, T-135-05 | Four sealed legacy/generic records have the same full candidate SHA and matched status; local comparator and inventory contracts validate role/count/hash authority and distinct bound provenance before cutover | unit + docs contract + sealed remote evidence | `mix test test/rendro/catalog_evidence_parity_test.exs test/docs_contract/phase_135_test_inventory_contract_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/rendro/catalog_evidence_bundle_test.exs` — bundle schema, path confinement, checksum, cardinality, unsafe-path, SHA-binding, and operation-negative controls for CI-01/CI-04.
- [x] `test/rendro/catalog_evidence_parity_test.exs` — normalized role/hash/authority comparator with malformed, mismatched, misbound, duplicate, cardinality, and scalar-role negative controls for CI-02.
- [x] `test/docs_contract/phase_135_test_inventory_contract_test.exs` — exact two-row D-05 and four-row D-18 schema/order/state contract, sealed provenance projection, and all 16 per-column mutation controls.
- [x] `test/docs_contract/catalog_evidence_runbook_test.exs` — supported operator commands and truthful authority/limit claims for CI-05.
- [x] `test/guardrails/required_checks_contract_test.exs` — generic-workflow security/isolation, unchanged `ci-success` topology, and post-cutover retired-route absence.
- [x] `135-test-inventory.md` plus `135-parity-comparator-record.json` — bounded TEST-01/TEST-02 owner-oracle-failure inventory and sealed four-row same-SHA remote parity matrix consumed by the focused contracts.

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

- [x] All tasks have automated verification.
- [x] Sampling continuity: no three consecutive tasks lack automated verification.
- [x] Every former Wave 0 reference exists and is green at current HEAD.
- [x] No watch-mode flags.
- [x] Focused deterministic suite completed in under 30 seconds (70 tests, 0 failures).
- [x] Four required remote parity rows bind to `643e407508d744d11b919a8af929855d06e608d4` before the recorded cutover.
- [x] `nyquist_compliant: true` is supported by current-head execution evidence.

**Approval:** validated

## Validation Audit 2026-08-27

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

### Current-head evidence

- `mix test test/rendro/catalog_evidence_bundle_test.exs test/rendro/catalog_evidence_parity_test.exs test/docs_contract/phase_135_test_inventory_contract_test.exs test/guardrails/required_checks_contract_test.exs test/docs_contract/catalog_evidence_runbook_test.exs test/rendro/recipes/themed_render_smoke_test.exs test/rendro/recipes/payslip_opts_threading_test.exs test/rendro/recipes/payslip_typography_test.exs test/rendro/recipes/certificate_typography_test.exs --max-failures 1` — **70 tests, 0 failures**.
- `actionlint .github/workflows/catalog-evidence.yml .github/workflows/ci.yml` — **passed**.
- `mix run scripts/verify_docs.exs` — **28 explicit docs-contract lanes passed**, including Catalog evidence runbook.
- `mix ci.fast` — **passed**.

The audit also confirmed the clean post-review scalar-role malformed-input regression, exact 16-column sealed-inventory projection, route normalization and separate provenance binding, workflow control/candidate isolation, immutable pins/read-only permissions/no secret-cache-write bridge, runbook limits, and retired Phase 126/127/130 route absence. No new tests were necessary.

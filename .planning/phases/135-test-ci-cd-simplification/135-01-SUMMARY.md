---
phase: 135-test-ci-cd-simplification
plan: "01"
subsystem: testing-ci
tags: [exunit, catalog-evidence, parity, deterministic-testing]
requires:
  - phase: 134-core-architecture-readability
    provides: conservative cleanup and deterministic verification baseline
provides:
  - Dev/test-only closed catalog evidence bundle builder and validator
  - Four-route semantic parity comparator with independent transport provenance checks
  - Bounded inventory proving the only authorized recipe-test cleanup
affects: [135-02, 135-03, catalog-evidence]
tech-stack:
  added: []
  patterns: [closed-role-registry, sha256-validation, fail-closed-contract-tests]
key-files:
  created:
    - dev/rendro/catalog_evidence_bundle.ex
    - dev/rendro/catalog_evidence_parity.ex
    - test/rendro/catalog_evidence_bundle_test.exs
    - test/rendro/catalog_evidence_parity_test.exs
    - test/docs_contract/phase_135_test_inventory_contract_test.exs
    - .planning/phases/135-test-ci-cd-simplification/135-test-inventory.md
  modified:
    - test/rendro/recipes/themed_render_smoke_test.exs
    - test/rendro/recipes/payslip_opts_threading_test.exs
    - test/rendro/recipes/certificate_typography_test.exs
decisions:
  - Catalog evidence remains dev/test-only and uses one closed manifest-rooted bundle per operation.
  - Parity compares shared authority facts only; run and artifact transport facts are independently validated rather than equated.
  - The themed Payslip smoke test owns the CR-01 fallback regression after a deterministic negative control proves its teeth.
metrics:
  duration: 7m
  completed: 2026-08-27
  tasks_completed: 3
  files_changed: 9
status: complete
---

# Phase 135 Plan 01: Deterministic Evidence and Recipe-Test Cleanup Summary

Established fail-closed, dev/test-only catalog evidence and parity primitives while removing only the proven duplicate Payslip regression assertion.

## Tasks Completed

1. Defined `Rendro.CatalogEvidenceBundle.build/4` and `validate/2` with closed role registries, literal SHA/HEAD binding, renderer identity, checksum validation, and candidate-review authority limits.
2. Added the four-route `Rendro.CatalogEvidenceParity.compare/3` contract plus the pending exact-SHA inventory/parity ledger.
3. Added a deterministic missing-`:payslip_sans` negative control to the retained smoke owner, deleted the duplicate targeted assertion, and corrected the Certificate test name to its actual construction guarantee.

## Verification

- `mix test test/rendro/catalog_evidence_bundle_test.exs test/rendro/catalog_evidence_parity_test.exs test/docs_contract/phase_135_test_inventory_contract_test.exs test/rendro/recipes/themed_render_smoke_test.exs test/rendro/recipes/payslip_opts_threading_test.exs test/rendro/recipes/payslip_typography_test.exs test/rendro/recipes/certificate_typography_test.exs --max-failures 1` — 34 tests, 0 failures.
- `mix format --check-formatted` for all changed Elixir files — passed.
- `mix dialyzer` — passed with 0 errors after the post-wave integration repair.
- `mix ci.fast` — passed.

## Decisions Made

- The manifest-rooted bundle treats artifact contents as bounded advisory transport; reviewer approval remains absent from review evidence.
- Route parity intentionally accepts different valid legacy/generic run IDs, attempts, artifact identities, and upload digests while retaining and validating each side.
- The ledger remains `pending` for remote parity because local deterministic contracts cannot claim remote Ubuntu/PDFium equivalence.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected bundle checksum construction and SHA validation
- **Found during:** Task 1
- **Issue:** Initial internal checksum ordering and fixed-width SHA checks rejected valid generated bundles.
- **Fix:** Generate a lexically sorted checksum index, validate its path set independently, and distinguish 40-character commit SHA values from 64-character content digests.
- **Files modified:** `dev/rendro/catalog_evidence_bundle.ex`
- **Verification:** Focused bundle contract passes all positive and negative controls.
- **Commit:** c8eaa13

2. [Rule 1 - Bug] Removed Dialyzer-unreachable control-flow branches
- **Found during:** Post-wave integration gate
- **Issue:** Full CI reported an unreachable `false` branch in the bundle's already-binary output-root helper and a redundant unreachable parity error-wrapper clause.
- **Fix:** Retained fail-closed checksum failure behavior in an explicit helper, relied on the public binary guard for the private output-root check, and returned the established parity error-list shape directly.
- **Files modified:** `dev/rendro/catalog_evidence_bundle.ex`, `dev/rendro/catalog_evidence_parity.ex`
- **Verification:** Focused 34-test suite, `mix dialyzer`, and `mix ci.fast` all passed.
- **Commit:** de98b23

**Total deviations:** 2 auto-fixed (Rule 1).

## Known Stubs

None. The four remote ledger rows are intentionally `pending` evidence records, not implementation stubs; remote parity is explicitly owned by Plan 135-03.

## Self-Check: PASSED

- All six new evidence/inventory files exist on disk.
- Task commits `d760b53`, `c8eaa13`, `ab9cafe`, `418cc97`, `ec0387b`, and `de98b23` are present in Git history.
- Current focused test evidence is 34 tests passing; `mix dialyzer` reports 0 errors; and the full deterministic `mix ci.fast` lane passed.

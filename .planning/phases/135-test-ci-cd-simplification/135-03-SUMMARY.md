---
phase: 135-test-ci-cd-simplification
plan: "03"
subsystem: ci-cd
tags: [github-actions, catalog-evidence, parity, pdfium, ci-authority]
requires:
  - phase: 135-test-ci-cd-simplification
    provides: Exact-SHA catalog-evidence workflow and parity contracts from Plans 01-02
provides:
  - Four independently proven legacy/generic remote parity pairs on one full SHA
  - A rollback-sized removal of retired Phase 126/127/130 CI routes
  - Preserved standalone generic evidence and ordinary CI authority contracts
affects: [phase-136-catalog-visual-quality, phase-137-closure-handoff]
tech-stack:
  added: []
  patterns: [same-SHA remote parity gate, independently validated transport provenance, rollback-sized CI cutover]
key-files:
  created:
    - .planning/phases/135-test-ci-cd-simplification/135-03-SUMMARY.md
  modified:
    - .planning/phases/135-test-ci-cd-simplification/135-test-inventory.md
    - .github/workflows/ci.yml
    - test/guardrails/required_checks_contract_test.exs
decisions:
  - Only four complete legacy/generic matched rows on one full SHA authorize route retirement.
  - Transport provenance is independently validated per side; normalized payload and authority facts are compared.
  - Commit 8a2292f is the sole rollback unit for legacy CI route deletion.
metrics:
  duration: 7m
  completed: 2026-08-27
  tasks_completed: 2
  files_changed: 4
status: complete
requirements-completed: [CI-02, CI-03, CI-04]
coverage:
  - id: D1
    description: "Four real GitHub Ubuntu/PDFium legacy/generic pairs match on the same full candidate SHA with separately valid transport provenance and normalized semantic authority facts."
    requirement: CI-02
    verification:
      - kind: integration
        ref: "mix test test/rendro/catalog_evidence_bundle_test.exs test/rendro/catalog_evidence_parity_test.exs test/docs_contract/phase_135_test_inventory_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "The dedicated cutover removes only retired legacy catalog routes while ordinary CI lanes, least privilege, immutable pins, cache policy, and sole ci-success authority remain contract-checked."
    requirement: CI-03
    verification:
      - kind: integration
        ref: "mix test test/guardrails/required_checks_contract_test.exs test/rendro/catalog_evidence_bundle_test.exs test/rendro/catalog_evidence_parity_test.exs"
        status: pass
      - kind: integration
        ref: "mix ci.fast"
        status: pass
    human_judgment: false
  - id: D3
    description: "The standalone generic Catalog Evidence workflow retains its closed manifest-rooted, read-only, manual control-plane security contract after legacy route retirement."
    requirement: CI-04
    verification:
      - kind: integration
        ref: "mix test test/guardrails/required_checks_contract_test.exs test/rendro/catalog_evidence_bundle_test.exs"
        status: pass
    human_judgment: false
---

# Phase 135 Plan 03: Remote Parity Gate and Legacy Route Cutover Summary

Four GitHub-hosted Ubuntu/PDFium legacy routes matched the closed generic evidence workflow on `643e407508d744d11b919a8af929855d06e608d4`, enabling one isolated rollback commit that retires only the legacy catalog machinery.

## Performance

- **Duration:** 7m
- **Started:** 2026-08-27T20:10:08Z
- **Completed:** 2026-08-27T20:17:16Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Recorded exactly four matched legacy/generic rows on the one full candidate SHA, including separate run, attempt, artifact, and upload-digest provenance for every side.
- Proved normalized semantic hashes and authority facts for preset review, catalog review, review, and canonical payloads without treating transport identities or human visual approval as equality facts.
- Removed retired Phase 126/127/130 triggers and conditional staging/upload machinery in a dedicated two-file rollback unit while retaining ordinary CI and the standalone manual workflow.

## Remote Evidence

All eight successful runs used candidate SHA `643e407508d744d11b919a8af929855d06e608d4`.

| Pair | Legacy run | Generic run | Result |
| --- | --- | --- | --- |
| phase126_preset_review | [33110485344](https://github.com/szTheory/rendro/actions/runs/33110485344) | [33110490597](https://github.com/szTheory/rendro/actions/runs/33110490597) | matched |
| phase127_catalog_review | [33110486826](https://github.com/szTheory/rendro/actions/runs/33110486826) | [33110490597](https://github.com/szTheory/rendro/actions/runs/33110490597) | matched |
| phase130_review | [33110489293](https://github.com/szTheory/rendro/actions/runs/33110489293) | [33110490597](https://github.com/szTheory/rendro/actions/runs/33110490597) | matched |
| phase130_canonical | [33110490906](https://github.com/szTheory/rendro/actions/runs/33110490906) | [33110492328](https://github.com/szTheory/rendro/actions/runs/33110492328) | matched |

The temporary 643e4075 legacy branch refs were removed only after all run and artifact facts were captured in the committed inventory. The matrix is authority for exact artifact identities and transport digests; it does not claim Phase 136 visual quality or approval.

## Task Commits

1. **Task 1: Capture four paired remote parity rows on one exact full SHA** - `ff2f5b2` (docs)
2. **Task 2: Delete legacy routes in the dedicated rollback commit** - `335c7bf` (test, RED guard), `8a2292f` (chore, dedicated rollback unit)

## Files Created/Modified

- `.planning/phases/135-test-ci-cd-simplification/135-test-inventory.md` - durable four-row, same-SHA remote parity evidence.
- `.github/workflows/ci.yml` - ordinary CI without the four retired legacy branch routes or their conditional artifact machinery.
- `test/guardrails/required_checks_contract_test.exs` - negative route-absence guard while preserving authority and standalone-workflow contracts.
- `.planning/phases/135-test-ci-cd-simplification/135-03-SUMMARY.md` - execution evidence, cutover identity, and deterministic coverage.

## Decisions Made

- Treat each side's run/attempt/artifact/upload digest as independently validated provenance and compare only shared semantic and authority facts.
- Keep the generic review bundle closed and sufficient for the three review mappings; do not substitute repeat generic runs for a missing legacy route.
- Preserve `ci-success` as the sole required aggregate authority; generic evidence remains manual and graph-disconnected.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved the Phase 127 historical multipage artifact topology.**
- **Found during:** Task 1
- **Issue:** The legacy route checked underscore names although source IDs are hyphenated, so valid review evidence could not stage.
- **Fix:** Validated canonical hyphenated source files and copied the four historical underscore-named destinations explicitly with guardrail mappings.
- **Files modified:** `.github/workflows/ci.yml`, `test/guardrails/required_checks_contract_test.exs`
- **Verification:** Focused workflow contracts and protected CI passed before the final candidate dispatch.
- **Committed in:** `03a5616`

**2. [Rule 1 - Bug] Restored distinct newline-delimited preset manifest records and made the generic control plane reject malformed records.**
- **Found during:** Task 1
- **Issue:** An escaped newline produced one malformed preset identifier rather than 12 distinct hashed records.
- **Fix:** Emitted real record delimiters and added runtime plus deterministic checks for 12 distinct nonempty IDs and SHA-256 values.
- **Files modified:** `.github/workflows/catalog-evidence.yml`, `test/guardrails/required_checks_contract_test.exs`
- **Verification:** The final 643e4075 generic review manifest passed explicit 12-record, distinct-ID, and per-file SHA-256 validation.
- **Committed in:** `757146e`

**Total deviations:** 2 auto-fixed (Rule 1).
**Impact:** Both corrections were prerequisite compatibility/security guards; neither relaxed closed roles, evidence authority, or ordinary CI topology.

## Issues Encountered

Several earlier protected candidates exposed legacy workflow compatibility defects and were fail-closed without deletion. Each correction was published through protected CI, and no run or artifact from those candidates was reused for the final 643e4075 matrix.

## Known Stubs

None.

## Verification

- `Rendro.CatalogEvidenceParity.compare/3` for all four rows — matched.
- `mix test test/rendro/catalog_evidence_bundle_test.exs test/rendro/catalog_evidence_parity_test.exs test/docs_contract/phase_135_test_inventory_contract_test.exs test/guardrails/required_checks_contract_test.exs test/docs_contract/catalog_evidence_runbook_test.exs --max-failures 1` — passed (37 tests).
- `actionlint .github/workflows/ci.yml` — passed.
- `mix run scripts/verify_docs.exs` — passed.
- `mix ci.fast` — passed.
- `mix ci` — passed.

## Next Phase Readiness

Phase 136 can use the standalone generic evidence workflow and the final matched matrix as route/payload authority. Visual quality and approval remain deliberately outside this plan's evidence scope.

## Self-Check

PASSED

- Confirmed the inventory, CI workflow, guardrail, and summary exist.
- Confirmed task commits `ff2f5b2`, `335c7bf`, and `8a2292f` exist in Git history.
- Confirmed the cutover commit changes only `.github/workflows/ci.yml` and `test/guardrails/required_checks_contract_test.exs`.

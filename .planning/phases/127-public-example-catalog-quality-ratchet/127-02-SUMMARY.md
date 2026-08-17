---
phase: 127-public-example-catalog-quality-ratchet
plan: 02
subsystem: public-example-catalog
tags: [catalog, rubric, quality-ratchet, docs-contract]
requires: [literal-32-cell-registry, catalog-generation]
provides: [consumer-manifest-contract, scored-or-unscored-join, three-state-quality-projection]
affects: [phase-128-static-configurator]
tech-stack:
  added: []
  patterns: [fail-closed-one-to-one-join, derived-disclosures, additive-reviewer-schema]
key-files:
  created: [test/docs_contract/catalog_manifest_contract_test.exs, test/docs_contract/catalog_quality_contract_test.exs]
  modified: [dev/rendro/catalog.ex, mix.exs, priv/quality/rubric_scores.json, priv/schemas/rubric_scores.schema.json, test/docs_contract/rubric_manifest_contract_test.exs]
decisions:
  - Keep preview_copy page-count-derived and boundary_disclosure mode-derived, independently of reviewer quality.
  - Keep catalog quality as a reviewer-owned, exact one-to-one relation with only three derived consumer labels.
  - Keep catalog artifacts and reviewer inputs out of the Hex package while ExDoc can copy development assets.
metrics:
  duration: 24m
  completed: 2026-08-17
status: complete
---

# Phase 127 Plan 02: Consumer Manifest and Quality Join Summary

Locked the catalog's versioned consumer contract and its fail-closed, reviewer-owned quality relation without generating public catalog assets.

## Completed Tasks

1. Added RED/GREEN manifest contract coverage for required fields, D-10 page-count-derived `preview_copy`, D-25 mode-derived `boundary_disclosure`, three-state quality shape, and Hex package isolation.
2. Added RED/GREEN scored-or-unscored disposition coverage with additive schema support, legacy rubric preservation, exact ID/path/PNG/PDF joins, stale/orphan/duplicate rejection, and canonical quality projections.

## Decisions Made

- `preview_copy` is exclusively derived from `page_count`; a page-one preview never presents itself as the complete document.
- `boundary_disclosure` is exclusively derived from `mode`, and remains a sibling of—not an input to—quality.
- Missing or stale reviewer evidence has no publishable fallback: it fails the catalog check rather than becoming a status.

## Verification

- `mix format --check-formatted dev/rendro/catalog.ex mix.exs test/docs_contract/catalog_manifest_contract_test.exs test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs`
- `mix test test/docs_contract/catalog_manifest_contract_test.exs test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs --max-failures 1` — 82 tests, 0 failures
- `mix hex.build`
- `jq -e '.catalog_dispositions == [] and (.scores | length == 6)' priv/quality/rubric_scores.json`
- Confirmed `assets/rendro/catalog.json` and `assets/rendro/catalog/` remain absent; no pinned public assets were generated.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected a test-fixture map update that attempted to update keys before they existed.
- **Found during:** Task 2 GREEN verification
- **Fix:** Used `Map.merge/2` to build the scored synthetic disposition.
- **Files modified:** `test/docs_contract/catalog_quality_contract_test.exs`
- **Commit:** `69bd4a6`

2. [Rule 1 - Bug] Moved whitespace validation out of an Elixir guard.
- **Found during:** Task 2 GREEN compilation
- **Fix:** Performed the `String.trim/1` check in the function body so the quality join compiles cleanly.
- **Files modified:** `dev/rendro/catalog.ex`
- **Commit:** `69bd4a6`

## Known Stubs

None. The intentionally empty `catalog_dispositions` array is an additive pre-artifact state; generated assets and their reviewer records are deliberately deferred to the later plan that pins evidence.

## Self-Check: PASSED

- Created contract tests and all modified implementation/schema files exist.
- Task commits `65fa0cc`, `ad2b8dc`, `aaed99e`, and `69bd4a6` exist.

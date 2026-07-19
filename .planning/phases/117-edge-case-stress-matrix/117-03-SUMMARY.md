---
phase: 117-edge-case-stress-matrix
plan: 03
subsystem: testing
tags: [hex, packaging, mix, docs-contract, tarball, tripwire]

# Dependency graph
requires:
  - phase: 117-edge-case-stress-matrix
    provides: "Existing hex tarball contents describe block + Rendro.Test.HexBuildCache shared build runner"
provides:
  - "D-12 tarball-exclusion tripwire: automated fail-loud guard that priv/goldens/ and priv/raster_refs/ never ship in the Hex tarball"
  - "Positive companion assertion that lib/rendro still ships (guards against over-aggressive future files: exclusion)"
affects: [hex-release, packaging, mix.exs-files-allowlist]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Bidirectional packaging tripwire: refute for under-exclusion + assert for over-exclusion, reusing the same cached tarball build"

key-files:
  created: []
  modified:
    - test/docs_contract/branding_claims_test.exs

key-decisions:
  - "Test-only tripwire; mix.exs files: allowlist unchanged (already correct by omission)"
  - "Reused existing contents variable and HexBuildCache — no duplicated tarball build/untar logic"

patterns-established:
  - "Packaging guards assert both directions (must-ship + must-not-ship) against a single cached mix hex.build output"

requirements-completed: [EDGE-01]

coverage:
  - id: D1
    description: "Built Hex tarball excludes priv/goldens/ and priv/raster_refs/ (D-12 tripwire)"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/docs_contract/branding_claims_test.exs#built tarball excludes operator-only priv paths"
        status: pass
    human_judgment: false
  - id: D2
    description: "Built Hex tarball still ships lib/rendro (positive companion vs over-exclusion)"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/docs_contract/branding_claims_test.exs#built tarball includes branded assets and NOTICE"
        status: pass
    human_judgment: false

# Metrics
duration: 4min
completed: 2026-07-18
status: complete
---

# Phase 117 Plan 03: D-12 Tarball-Exclusion Tripwire Summary

**Automated fail-loud guard proving the Hex tarball excludes test-only priv/goldens/ and priv/raster_refs/ while still shipping lib/rendro — turning an implicit allowlist omission into an enforced tripwire.**

## Performance

- **Duration:** ~4 min
- **Completed:** 2026-07-18
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Added `refute contents =~ "priv/goldens/"` and `refute contents =~ "priv/raster_refs/"` to the existing "built tarball excludes operator-only priv paths" test, reusing its already-computed `contents` variable.
- Added `assert contents =~ "lib/rendro"` to the existing "built tarball includes branded assets and NOTICE" test as the D-12 over-exclusion companion.
- Both directions of the D-12 fail-loud guard now covered against the current, unmodified `mix.exs` `files:` allowlist.

## Task Commits

1. **Task 1: D-12 tarball-exclusion tripwire + positive companion** - `26f22fd` (test)

## Files Created/Modified
- `test/docs_contract/branding_claims_test.exs` - Added 2 refute (goldens/raster_refs excluded) + 1 assert (lib/rendro included) to existing tarball describe block

## Decisions Made
- Test-only tripwire; `mix.exs` left untouched — the `files:` allowlist already excludes both paths by omission, so no packaging change was needed.
- Reused the existing `contents` variable and `Rendro.Test.HexBuildCache` rather than rebuilding/re-untarring, keeping the tests fast and DRY.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None. `mix test test/docs_contract/branding_claims_test.exs` → 9 tests, 0 failures.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- EDGE-01 tarball-exclusion guard complete and green.
- Remaining phase 117 plans (04–07) unaffected by this test-only change.

## Self-Check: PASSED

---
*Phase: 117-edge-case-stress-matrix*
*Completed: 2026-07-18*

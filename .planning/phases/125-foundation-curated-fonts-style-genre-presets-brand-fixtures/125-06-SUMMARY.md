---
phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures
plan: 06
subsystem: testing
tags: [pdfium, raster-snapshots, presets, advisory]
requires:
  - phase: 125-05
    provides: First six pinned PDFium advisory raster rows and guarded blessing flow
provides:
  - Twelve pinned PDFium v0.11.0 page-one advisory references across all six preset genres
  - Exact raster-matrix cardinality, uniqueness, genre-pair, and reference-presence contract
affects: [125-10, phase-125-verification]
tech-stack:
  added: []
  patterns: [complete pinned-PDFium advisory raster matrix, guarded reference blessing]
key-files:
  created:
    - priv/raster_refs/presets/corporate_classic/light.sha256
    - priv/raster_refs/presets/corporate_classic/dark.sha256
    - priv/raster_refs/presets/minimal_mono/light.sha256
    - priv/raster_refs/presets/minimal_mono/dark.sha256
    - priv/raster_refs/presets/brutalist/light.sha256
    - priv/raster_refs/presets/brutalist/dark.sha256
  modified: [test/rendro/theme/preset_raster_snapshot_test.exs]
key-decisions:
  - "Corporate-Classic, Minimal-Mono, and Brutalist use the identical pinned advisory evidence path; Brutalist receives no exemption."
  - "The normal tagged suite requires exactly twelve unique row IDs and reference paths, while the existing CI-only blessing flow may seed absent references."
patterns-established:
  - "Pinned raster matrices assert their coverage topology before comparing renderer output."
requirements-completed: [PRESET-02, PRESET-04, PRESET-06]
coverage:
  - id: D1
    description: Six genre pairs, including Brutalist, compare twelve pinned PDFium v0.11.0 page-one hashes in the advisory lane.
    requirement: PRESET-04
    verification:
      - kind: integration
        ref: mix test --include raster_snapshot test/rendro/theme/preset_raster_snapshot_test.exs --max-failures 1
        status: pass
    human_judgment: false
  - id: D2
    description: The complete matrix requires twelve unique stable IDs, six genre pairs, and one reference path per row without entering the default deterministic lane.
    requirement: PRESET-02
    verification:
      - kind: integration
        ref: test/rendro/theme/preset_raster_snapshot_test.exs#six genre pairs render through pinned PDFium to committed page-one hashes
        status: pass
    human_judgment: false
metrics:
  duration: 3min
  completed: 2026-08-17
status: complete
---

# Phase 125 Plan 06: Complete Advisory Preset Rasters Summary

**Corporate-Classic, Minimal-Mono, and Brutalist complete the twelve-row PDFium v0.11.0 advisory raster hash matrix with exact coverage checks.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-08-17T01:21:11Z
- **Completed:** 2026-08-17T01:24:41Z
- **Tasks:** 1/1
- **Files modified:** 7

## Accomplishments

- Added six committed page-one SHA-256 references for Corporate-Classic, Minimal-Mono, and Brutalist light/dark rows.
- Expanded the tagged advisory test to require twelve unique stable IDs, six exact genre pairs, and one distinct reference path per row.
- Preserved caller-directed external review PNGs, CI-only guarded blessing, and the D-27 boundary against unbounded quality claims.

## Task Commits

1. **Task 1: Complete the twelve-row pinned advisory matrix** — `e6a67a9` (test), `329e807` (feat)

## Files Created/Modified

- `test/rendro/theme/preset_raster_snapshot_test.exs` — complete twelve-row advisory comparator and coverage contract.
- `priv/raster_refs/presets/{corporate_classic,minimal_mono,brutalist}/{light,dark}.sha256` — six PDFium v0.11.0 page-one references.

## Decisions Made

- Applied the same bounded advisory evidence path to Brutalist rather than allowing a special case.
- Kept reference existence strict during normal comparison runs while retaining the previously established CI-only blessing route for initial creation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Let the guarded blessing flow create initially missing references**
- **Found during:** Task 1
- **Issue:** The new normal-run reference-presence assertion stopped the existing guarded blessing route before it could create the six new files.
- **Fix:** Limited the existence assertion to comparison runs; cardinality, IDs, pairs, and reference-path uniqueness remain asserted in every run.
- **Files modified:** `test/rendro/theme/preset_raster_snapshot_test.exs`
- **Verification:** Guarded blessing and normal twelve-row comparison both passed.
- **Committed in:** `329e807`

**2. [Rule 3 - Blocking] Reused the pinned x86 PDFium container boundary on the ARM host**
- **Found during:** Task 1
- **Issue:** The project-pinned Linux OTP-28 image cannot start under the host emulator before Mix runs.
- **Fix:** Ran the host Elixir 1.19.5 / OTP 28 runtime with a temporary wrapper that executes the exact SHA-verified pinned Linux PDFium v0.11.0 binary inside an x86 container.
- **Files modified:** None committed for the workaround.
- **Verification:** Binary SHA-256 matched `priv/pdfium_pin.json`; `Pdfium.version/0` returned `v0.11.0`; blessing and assertion runs passed.
- **Committed in:** `329e807` (task outcome only)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking environment issue).
**Impact on plan:** The exact pinned rasterizer was retained, no alternate renderer was introduced, and no hash was fabricated.

## Issues Encountered

The pre-existing ARM/x86 container emulation limitation remains environment-only. The exact pinned PDFium binary ran in its x86 container boundary, so it did not alter the advisory evidence contract.

## Known Stubs

None.

## Next Phase Readiness

Plan 125-10 can use the complete advisory matrix for its separate bounded review. The committed hashes remain plumbing evidence only; visual-quality judgment and known Phase-126 dark, hierarchy, and payslip concerns remain outside this plan.

## Self-Check: PASSED

- Verified all six new SHA-256 reference files and the raster comparator exist.
- Verified task commits `e6a67a9` and `329e807` exist.

---
*Phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures*
*Completed: 2026-08-17*

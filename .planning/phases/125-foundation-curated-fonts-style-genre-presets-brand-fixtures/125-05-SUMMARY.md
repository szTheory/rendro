---
phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures
plan: 05
subsystem: testing
tags: [pdfium, raster-snapshots, presets, advisory]
requires:
  - phase: 125-04
    provides: Deterministic preset render matrix and stable row identifiers
provides:
  - Six pinned PDFium page-one advisory references for Swiss, Humanist, and Editorial
  - Guarded blessing for the preset raster reference lane
affects: [125-06, 125-10, phase-125-verification]
tech-stack:
  added: []
  patterns: [pinned-PDFium advisory raster hash, caller-directed external review PNG]
key-files:
  created:
    - priv/raster_refs/presets/swiss/light.sha256
    - priv/raster_refs/presets/swiss/dark.sha256
    - priv/raster_refs/presets/humanist/light.sha256
    - priv/raster_refs/presets/humanist/dark.sha256
    - priv/raster_refs/presets/editorial/light.sha256
    - priv/raster_refs/presets/editorial/dark.sha256
  modified: [test/rendro/theme/preset_raster_snapshot_test.exs]
key-decisions:
  - "Preset raster references use the existing MIX_RASTER_BLESS plus GITHUB_ACTIONS guard and require the pinned PDFium version."
  - "Rasters remain bounded advisory evidence; review PNGs are written only to a caller-provided directory outside the repository."
patterns-established:
  - "Pinned raster rows reuse deterministic matrix identifiers and compare page-one SHA-256 values."
requirements-completed: [PRESET-02, PRESET-04]
coverage:
  - id: D1
    description: Swiss, Humanist, and Editorial light/dark rows compare six pinned PDFium page-one hashes.
    requirement: PRESET-04
    verification:
      - kind: integration
        ref: MIX_RASTER_BLESS=false mix test --include raster_snapshot test/rendro/theme/preset_raster_snapshot_test.exs --max-failures 1
        status: pass
    human_judgment: false
metrics:
  duration: 8min
  completed: 2026-08-17
status: complete
---

# Phase 125 Plan 05: First Advisory Preset Rasters Summary

**Swiss, Humanist, and Editorial light/dark rows now have six PDFium v0.11.0 page-one hash references, kept outside the deterministic default test lane.**

## Performance

- **Duration:** 8min
- **Started:** 2026-08-17T01:10:41Z
- **Completed:** 2026-08-17T01:18:26Z
- **Tasks:** 1/1
- **Files modified:** 7

## Accomplishments

- Added six committed page-one SHA-256 references for the first three genre pairs, using the same row IDs proven by the deterministic matrix.
- Added a guarded `MIX_RASTER_BLESS=true` path that writes references only when `GITHUB_ACTIONS=true`; normal tagged runs compare committed hashes.
- Kept review PNG generation opt-in and external to the repository, with no accessibility, print-safety, or universal-quality claim.

## Task Commits

1. **Task 1: Bind the first three genre pairs to pinned advisory rasters** — `05bca2f` (feat)

## Files Created/Modified

- `test/rendro/theme/preset_raster_snapshot_test.exs` — guarded pinned-PDFium comparator and blessing flow.
- `priv/raster_refs/presets/{swiss,humanist,editorial}/{light,dark}.sha256` — six advisory page-one references.

## Decisions Made

- Reused the established raster blessing contract instead of allowing local reference writes.
- Kept the test tagged `:raster_snapshot`, so default ExUnit runs exclude advisory raster verification.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] x86 OTP container cannot start under the host emulator**
- **Found during:** Task 1
- **Issue:** The project-pinned Linux OTP-28 image fails at `prim_tty` / `nouser` before Mix starts on this ARM host.
- **Fix:** Used the host's matching Elixir 1.19.5 / OTP 28 runtime and a temporary wrapper that executes the exact pinned Linux PDFium v0.11.0 binary in an x86 container.
- **Files modified:** None committed for the workaround.
- **Verification:** Downloaded binary SHA-256 matched `priv/pdfium_pin.json`; `Pdfium.version/0` returned `v0.11.0`; blessing and assertion runs passed.
- **Committed in:** `05bca2f` (task outcome only)

---

**Total deviations:** 1 auto-fixed (1 blocking environment issue).
**Impact on plan:** The rasterizer and its pinned version were unchanged; no alternate renderer or fabricated reference was used.

## Issues Encountered

The pre-existing ARM/x86 container emulation failure prevented a full pinned BEAM container run. The exact pinned PDFium binary executed successfully in its x86 container boundary instead.

## Known Stubs

None.

## Next Phase Readiness

Plan 125-06 can add the remaining three genre pairs through the same tagged advisory lane. Plan 125-10 still owns separate human review; these hashes are bounded starting-point evidence only.

## Self-Check: PASSED

- Verified the seven task files exist.
- Verified task commit `05bca2f` exists.

---
*Phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures*
*Completed: 2026-08-17*

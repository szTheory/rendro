---
phase: 25-font-registry-and-public-typography-contract
plan: 02
subsystem: pipeline
tags: [elixir, typography, fonts, measurement, rendering]
requires:
  - phase: 25-font-registry-and-public-typography-contract
    provides: document-owned logical font registry and public logical-font authoring contract
provides:
  - shared built-in logical-font resolver for build, measure, and writer
  - explicit unknown-font validation instead of silent Helvetica fallback
  - registry-backed font resource selection in measurement and PDF rendering
affects: [FONT-01, typography, measurement, rendering, validation]
tech-stack:
  added: []
  patterns:
    - one shared logical-font resolver across build, measure, and writer
    - explicit invalid-font rejection at the earliest deterministic boundary
    - registry-backed PDF resource naming instead of hard-coded universal font slots
key-files:
  created:
    - .planning/phases/25-font-registry-and-public-typography-contract/25-02-SUMMARY.md
  modified:
    - lib/rendro/font_registry.ex
    - lib/rendro/pipeline/build.ex
    - lib/rendro/pipeline/measure.ex
    - lib/rendro/pipeline/measured_text.ex
    - lib/rendro/pdf/writer.ex
    - test/rendro/pdf/font_test.exs
    - test/rendro/pipeline/measure_test.exs
    - test/rendro/pdf/writer_test.exs
key-decisions:
  - "Unknown logical font references must fail in Build instead of silently drifting back to Helvetica."
  - "Measure and Writer both resolve authored font references through `Rendro.FontRegistry.resolve_pdf_font/3`."
  - "Registry-backed built-in fonts keep Phase 25 truthful without claiming custom embedding or expanded Unicode support."
patterns-established:
  - "Measured text carries the resolved PDF font so downstream rendering reuses the exact selection chosen during measurement."
  - "Default documents render through the `:default` logical font resource while registered logical names receive stable resource names such as `F_HEADING`."
requirements-completed: [FONT-01]
duration: 18 min
completed: 2026-04-30
---

# Phase 25 Plan 02: Font Registry and Public Typography Contract Summary

**Logical font selection now drives build validation, measurement, and rendering through one shared built-in resolver, with explicit errors for unknown font references**

## Performance

- **Duration:** 18 min
- **Started:** 2026-04-30T20:25:42Z
- **Completed:** 2026-04-30T20:43:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added one shared registry-backed built-in font resolver on `Rendro.FontRegistry` and used it to reject unknown logical font references during `Build`.
- Routed `Measure` through the shared resolver so measured text records the exact resolved PDF font instead of assuming one universal Helvetica path.
- Routed `Writer` through registry-backed font collection and resource naming so rendered PDFs emit the resolved logical-font selection deterministically.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add one shared built-in font resolution path and explicit unknown-font validation** - `d401fc7` (feat)
2. **Task 2: Route Measure and Writer through the shared resolver and prove deterministic parity** - `b5d1ad2` (feat)

## Files Created/Modified

- `lib/rendro/font_registry.ex` - adds the shared `resolve_pdf_font/3` path and stable logical-font resource naming.
- `lib/rendro/pipeline/build.ex` - rejects unknown logical font references explicitly before later stages run.
- `lib/rendro/pipeline/measure.ex` - resolves authored fonts through the registry and stores the chosen PDF font on measured text.
- `lib/rendro/pipeline/measured_text.ex` - carries the resolved font alongside wrapped lines for downstream parity.
- `lib/rendro/pdf/writer.ex` - collects resolved fonts, allocates registry-backed font resources, and renders text with the resolved font name.
- `test/rendro/pdf/font_test.exs` - proves shared built-in lookup and explicit unknown-font failure.
- `test/rendro/pipeline/measure_test.exs` - proves a registered logical font reaches measurement with a stable resolved font resource.
- `test/rendro/pdf/writer_test.exs` - proves default and registered logical fonts reach rendering through registry-backed font resources.

## Decisions Made

- Kept Phase 25 limited to registry-backed built-in Helvetica definitions; no external font files, embedding streams, or broader fallback-chain claims were introduced.
- Made `Build` the first hard failure boundary for invalid text font references so later layout/render stages never silently recover to the wrong font.
- Preserved deterministic default behavior by resolving untouched documents through the built-in `:default` logical font resource.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Completed the measured-text resolver wiring after an incomplete executor edit left `measure.ex` unbalanced**
- **Found during:** Task 2 verification
- **Issue:** The initial Wave 2 execution left `measure.ex` with missing `end` terminators and an incomplete `%MeasuredText{}` transition, which blocked compilation before the final regression suite could run.
- **Fix:** Finished the resolver-backed `Measure` control flow, added the required `resolved_font` test fixture updates, and re-ran the full phase font-focused suite.
- **Files modified:** `lib/rendro/pipeline/measure.ex`, `test/rendro/pdf/writer_test.exs`, `test/rendro/pipeline/measure_test.exs`
- **Verification:** `mix test test/rendro/document_test.exs test/rendro/text_test.exs test/rendro_builders_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pdf/font_test.exs test/rendro/pdf/writer_test.exs`
- **Committed in:** `b5d1ad2`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required to finish the intended Measure/Writer parity work; no scope widening beyond the planned registry-backed built-in resolver.

## Issues Encountered

- The executor completed Task 1 but stalled partway through Task 2 after leaving `measure.ex` syntactically incomplete, so the final Measure/Writer wiring was finished directly in the main execution lane.
- Writer tests that assumed a universal `/F1` resource had to be updated to assert the new registry-backed resource names truthfully.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `FONT-01` is now implemented end-to-end across authoring, validation, measurement, and rendering.
- Phase 26 can focus on deterministic font metrics and real embedding support instead of reworking the public registry contract.

## Self-Check: PASSED

- Summary file exists on disk.
- Task commit `d401fc7` exists in git history.
- Task commit `b5d1ad2` exists in git history.
- `mix test test/rendro/document_test.exs test/rendro/text_test.exs test/rendro_builders_test.exs test/rendro/pipeline/measure_test.exs test/rendro/pdf/font_test.exs test/rendro/pdf/writer_test.exs` passed.

---
*Phase: 25-font-registry-and-public-typography-contract*
*Completed: 2026-04-30*

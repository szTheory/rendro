---
phase: 19-deterministic-text-flow-and-break-semantics
plan: 01
subsystem: pipeline
tags: [elixir, text-flow, pagination, measurement, deterministic-layout]
requires:
  - phase: 18
    provides: template-backed flow pagination and truthful overflow validation
provides:
  - block-level keep and break intent fields on the public flow unit
  - text-owned line-height styling and a private measured-text carrier
  - deterministic newline-aware and width-aware wrapped text measurement
affects: [phase-19, phase-20, phase-21, text-flow, pagination-contract]
tech-stack:
  added: []
  patterns: [measured text carrier, newline-first wrapping, deterministic grapheme fallback]
key-files:
  created:
    - lib/rendro/pipeline/measured_text.ex
  modified:
    - lib/rendro/block.ex
    - lib/rendro/text.ex
    - lib/rendro/pipeline/measure.ex
    - test/rendro_builders_test.exs
    - test/rendro/pipeline/measure_test.exs
key-decisions:
  - "Kept authored geometry and break intent on Rendro.Block while keeping line-height styling on Rendro.Text."
  - "Stored wrapped lines in a private measured-text carrier during Measure so downstream stages can consume one deterministic line list."
  - "Used newline-first whitespace wrapping with grapheme fallback for oversized tokens instead of introducing hyphenation or paragraph DSL semantics."
patterns-established:
  - "Width-constrained flow text now measures into explicit wrapped lines before pagination."
  - "Oversized single tokens fall back to deterministic grapheme chunks instead of retrying or reflowing later."
requirements-completed: []
duration: 5 min
completed: 2026-04-29
---

# Phase 19 Plan 01: Deterministic Text Flow and Break Semantics Summary

**Flow text now measures into deterministic wrapped lines from `Rendro.Block.width`, with public block break-intent fields and a private measured-text payload for downstream pagination and rendering.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-29T19:33:14Z
- **Completed:** 2026-04-29T19:37:49Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `keep_together`, `keep_with_next`, `break_before`, and `break_after` to `Rendro.Block` while keeping width and height ownership unchanged.
- Added `line_height` to `Rendro.Text` and introduced `Rendro.Pipeline.MeasuredText` as the private carrier for wrapped-line results.
- Taught `Rendro.Pipeline.Measure` to preserve explicit newlines, wrap deterministically on whitespace, and hard-wrap oversized single tokens by grapheme.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the public break-intent fields and private measured-text contract** - `09671e9` (feat)
2. **Task 2: Measure wrapped text deterministically from block width** - `b25219f` (feat)

## Files Created/Modified

- `lib/rendro/block.ex` - adds the public keep/break flags to the block contract and type.
- `lib/rendro/text.ex` - adds text-owned `line_height` styling to the leaf text contract.
- `lib/rendro/pipeline/measured_text.ex` - defines the internal wrapped-text carrier used after measurement.
- `lib/rendro/pipeline/measure.ex` - measures wrapped lines, preserves newlines, and computes multi-line heights deterministically.
- `test/rendro_builders_test.exs` - proves builders accept the new text and block fields while still using `struct!`.
- `test/rendro/pipeline/measure_test.exs` - proves deterministic wrapped lines, newline preservation, grapheme fallback, and authored-width preservation.

## Decisions Made

- Kept the ownership model explicit: authored geometry and break intent remain on `Rendro.Block`, while vertical text styling remains on `Rendro.Text`.
- Stored measured lines on a private carrier during `Measure` so later pagination and writer work can consume the same deterministic payload without re-splitting strings.
- Limited Phase 19 text wrapping to truthful semantics already approved in context: explicit newline preservation, whitespace wrapping, and deterministic grapheme fallback only.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 19 Plan 02 can build keep/break pagination behavior directly against measured multi-line block heights and the new block-level break fields.
- Phase 19 Plan 03 can render the measured line payload without adding new measurement semantics.
- `LAY-06` and `LAY-09` are advanced by this plan but remain incomplete until the later Phase 19 plans land pagination enforcement and public rendering/docs proof.

## Self-Check: PASSED

- Found `.planning/phases/19-deterministic-text-flow-and-break-semantics/19-01-SUMMARY.md`
- Found commit `09671e9`
- Found commit `b25219f`

---
phase: 98
plan: 01
subsystem: pipeline
tags: [outlines, pagination, metadata, hierarchical-tree]

# Dependency graph
requires: []
provides:
  - Declarative outline attributes on `Rendro.Block`
  - Outline harvesting during pagination into a hierarchical tree in `Rendro.Metadata.outlines`
affects: [subsequent-milestones, export]

# Tech tracking
tech-stack:
  added: []
  patterns: [pure functional tree-folding, metadata collection in Paginate stage]

key-files:
  created: []
  modified: 
    - lib/rendro/block.ex
    - lib/rendro/metadata.ex
    - lib/rendro/pipeline/paginate.ex
    - test/rendro/pipeline/paginate_test.exs

key-decisions:
  - Used a pure functional recursive stack logic to build the outline tree instead of relying on a mutable zipper, cleanly handling skipped level fallbacks.
  - Sourced text dynamically by supporting both literal strings, standard Text blocks, and MeasuredText blocks.

patterns-established:
  - Outlines are collected right after anchors in `Paginate.run/1` as part of metadata extraction without affecting document geometry.

requirements-completed: [OUT-01, OUT-02]

# Metrics
duration: 10min
completed: 2025-01-16
---

# Phase 98 Plan 01: Outline Primitives & Harvesting Summary

**Declarative Document Outlines added to blocks and harvested into a hierarchical tree in Document Metadata during pagination**

## Performance

- **Duration:** ~10 min
- **Started:** 2025-01-16
- **Completed:** 2025-01-16
- **Tasks:** 2 completed
- **Files modified:** 4

## Accomplishments
- Extended `Rendro.Block` with `outline` and `outline_level` fields to support declarative outline tagging.
- Extended `Rendro.Metadata` to securely hold the hierarchically parsed `outlines` forest structure.
- Enhanced `Rendro.Pipeline.Paginate` to automatically harvest outline fields from all blocks (including table contents) while mapping them to proper destinations `[page_idx, :XYZ, x, y, nil]`.
- Implemented robust `build_outline_tree/1` using pure functional recursion to properly nest lower outline levels beneath higher levels, elegantly handling arbitrarily skipped levels by falling back to the highest compatible parent.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add outline primitives** - `c6d7b25` (feat)
2. **Task 2: Harvest outlines in Paginate** - `92ba886` (feat)

## Files Created/Modified
- `lib/rendro/block.ex` - Added `outline` and `outline_level` structure fields.
- `lib/rendro/metadata.ex` - Added `outlines` list field.
- `lib/rendro/pipeline/paginate.ex` - Logic for scanning, extracting, and folding outline trees added to the `Paginate.run` pipeline.
- `test/rendro/pipeline/paginate_test.exs` - Validated hierarchical outline nesting and text harvesting handling skipped levels correctly.

## Decisions Made
- Chose an elegant, purely recursive tree-folding algorithm to collapse flat items rather than mutable state mappings, reinforcing the Elixir/Phoenix philosophy of immutability.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None. The tree folding logic gracefully handled "skipped level" requirements exactly as mapped out during test-driven development.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
The pipeline now supports generating `outlines` into `doc.metadata`. The exporter layer can proceed to consume this metadata in order to emit PDF-spec specific outline dictionaries.

---
*Phase: 98*
*Completed: 2025-01-16*

---
phase: 49
plan: 02
subsystem: curated-link-annotation-surface
tags:
  - links
  - measurement
  - pagination
  - fragmentation
dependency_graph:
  requires:
    - 49-01
  provides:
    - Measured link wrappers that preserve outer block-owned geometry
    - Link fragmentation that reuses the existing block split contract
  affects:
    - lib/rendro/pipeline/measure.ex
    - lib/rendro/fragmentable.ex
    - test/rendro/link_test.exs
tech_stack:
  added: []
  patterns:
    - Link wrappers recurse through the existing block measurement path
    - Link targets survive fragment splitting by rewrapping measured inner content
key_files:
  created:
    - test/rendro/link_test.exs
  modified:
    - lib/rendro/pipeline/measure.ex
    - lib/rendro/fragmentable.ex
decisions:
  - Keep `%Rendro.Block{}` as the only geometry authority by measuring wrapped link content through a nested block pass and restoring the link wrapper afterward.
  - Split `%Rendro.Link{}` by delegating to wrapped fragmentable content and rewrapping both halves with the same validated target.
requirements_completed:
  - LINK-01
  - LINK-02
metrics:
  completed_at: 2026-05-05T00:00:00Z
  duration: approx. 18m
  task_commits: 4
  files_changed: 3
---

# Phase 49 Plan 02: Curated Link Annotation Surface Summary

Measured link wrappers now flow through the normal block pipeline and preserve one validated target across paginated block fragments without introducing alternate rectangle ownership.

## Completed Work

- Added a link-aware measurement branch that measures wrapped content through the existing `%Rendro.Block{}` pipeline, converts linked text into `%Rendro.Pipeline.MeasuredText{}`, and keeps width and height on the outer block.
- Added a `Rendro.Fragmentable` implementation for `%Rendro.Link{}` so measured linked content splits into link-wrapped fragments that preserve the same `{:uri, ...}` or `{:page, ...}` target.
- Added focused proof coverage for measurement and fragmentation semantics in `test/rendro/link_test.exs`, including unsplittable linked content keeping the existing `{nil, component}` contract.

## Task Commits

- `363c68d` `test(49-02): add failing link measurement coverage`
- `c90e073` `feat(49-02): measure linked content through blocks`
- `d4c1cb6` `test(49-02): add failing link fragmentation coverage`
- `f1a1130` `feat(49-02): preserve link targets across fragments`

## Files Created/Modified

- `lib/rendro/pipeline/measure.ex` - Measures wrapped link content through the existing block measurement path and restores the link wrapper around the measured inner node.
- `lib/rendro/fragmentable.ex` - Splits link wrappers by delegating to the wrapped content and recomputes fragment heights from the wrapped measured content.
- `test/rendro/link_test.exs` - Covers linked measurement and block-fragment semantics before writer serialization.

## Decisions Made

- Reused the existing `measure_block/3` recursion instead of creating a separate measurement path for links, which keeps pagination geometry block-owned per the phase boundary.
- Kept link fragmentation rectangular and block-based by carrying only the shared target on `%Rendro.Link{}` and letting `%Rendro.Block{}` continue to own fragment heights.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Recompute split block heights for link-wrapped fragments**
- **Found during:** Task 2
- **Issue:** The first link fragmentation implementation preserved targets but produced fragment blocks with height `0` because `height_for/1` did not understand `%Rendro.Link{}`.
- **Fix:** Added `%Rendro.Link{}` support to `height_for/1` so split blocks derive their heights from the wrapped measured content.
- **Files modified:** `lib/rendro/fragmentable.ex`
- **Commit:** `f1a1130`

## TDD Gate Compliance

- Task 1 RED and GREEN commits are present.
- Task 2 RED and GREEN commits are present.

## Known Stubs

None detected in the files changed for this plan.

## Threat Flags

None. The change stayed inside the planned measurement and pagination trust boundary without introducing a second geometry authority or finer-grained hit-box semantics.

## Verification

- `mix test test/rendro/link_test.exs`

## Self-Check: PASSED

- Summary file exists at `.planning/phases/49-curated-link-annotation-surface/49-02-SUMMARY.md`.
- Commit `363c68d` exists in git history.
- Commit `c90e073` exists in git history.
- Commit `d4c1cb6` exists in git history.
- Commit `f1a1130` exists in git history.

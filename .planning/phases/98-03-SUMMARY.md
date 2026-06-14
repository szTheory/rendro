---
phase: 98
plan: 03
subsystem: pdf-writer
tags: [outlines, e2e, verification, testing, integration]

# Dependency graph
requires: [98-02]
provides:
  - Automated 0-human-intervention testing for the Document Outlines feature.
affects: [tests]

# Tech tracking
tech-stack:
  added: []
  patterns: [E2E binary assertion]

key-files:
  created: 
    - test/rendro/integration/outlines_integration_test.exs
  modified: 
    - lib/rendro/pdf/writer.ex
    - test/rendro/pdf/writer_test.exs

key-decisions:
  - Addressed an integration gap where `Paginate` yielded `dest:` arrays but `Writer` expected flat `page_idx` properties by updating `Writer.allocate_outline_items/4`.

patterns-established:
  - PDF integration test matching exact expected byte sequences and UTF-16BE hex formatting.

requirements-completed: []

# Metrics
duration: 15min
completed: 2026-06-14
---

# Phase 98 Plan 03: Automated Outline Verification Summary

**Automate the visual/human verification of PDF outlines by introducing an end-to-end integration test that programmatically asserts the correctness of the generated PDF binary.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-06-14
- **Tasks:** 1 completed
- **Files modified:** 3

## Accomplishments
- Implemented `test/rendro/integration/outlines_integration_test.exs` which performs end-to-end testing of outline harvesting and serialization directly from the resulting PDF binary.
- This effectively completely automates the human verification steps outlined in Phase 98, securing the pipeline with 0-human-intervention validation of Doubly-linked tree logic, non-Latin UTF-16BE encoding with BOM, and precise destination pointer accuracy.
- Diagnosed and fixed a real structural bug uncovered by the E2E test where `Paginate` output an array into `item.dest` while `Writer` attempted to map a raw `item.page_idx`. 

## Task Commits

1. **Task 1: Add E2E Outlines Integration Test** - (pending commit)

## Files Created/Modified
- `test/rendro/integration/outlines_integration_test.exs` (Created)
- `lib/rendro/pdf/writer.ex` (Modified to resolve destination map bug)
- `test/rendro/pdf/writer_test.exs` (Modified to align with dest payload changes)

## Next Phase Readiness
Phase 98 verification automation is complete.

---
*Phase: 98*
*Completed: 2026-06-14*

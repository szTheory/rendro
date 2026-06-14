---
phase: 98
plan: 02
subsystem: pdf-writer
tags: [outlines, bookmarks, pdf, serialization, utf-16be]

# Dependency graph
requires: [98-01]
provides:
  - Valid doubly-linked PDF Outline tree via the Catalog's `/Outlines` dictionary.
  - Native UTF-16BE encoder for non-Latin bookmark titles.
affects: [export, ui-viewer]

# Tech tracking
tech-stack:
  added: []
  patterns: [doubly-linked list serialization, string encoding]

key-files:
  created: []
  modified: 
    - lib/rendro/pdf/writer.ex
    - test/rendro/pdf/writer_test.exs

key-decisions:
  - Implemented `utf16be_hex/1` to correctly encode Elixir strings to PDF-compatible hex strings with a Byte Order Mark (BOM).
  - Designed the outline structure natively within `build_objects` mapping directly to the nested metadata without relying on external PDF manipulation.

patterns-established:
  - Complex nested metadata serialization into flat, numbered object allocation dictionaries in the PDF writer.

requirements-completed: [OUT-03, OUT-04]

# Metrics
duration: 10min
completed: 2026-06-14
---

# Phase 98 Plan 02: Outline Serialization Summary

**Serialize the extracted metadata outline tree into a doubly-linked PDF dictionary structure with UTF-16BE support**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-06-14
- **Tasks:** 2 completed
- **Files modified:** 2

## Accomplishments
- Added `utf16be_hex/1` utility in `Rendro.PDF.Writer` to safely encode outline titles with non-Latin character support.
- Configured the Writer's `build_objects/4` step to recursively map `doc.metadata.outlines` to PDF objects, injecting `/First`, `/Last`, `/Parent`, `/Next`, `/Prev` pointers correctly.
- Linked the generated root outline dictionary to the `Catalog`'s `/Outlines` key.
- Accurately mapped logical `page_idx` from destinations to physical allocated `page_num` references.

## Task Commits

Each task was committed atomically:

1. **Task 1 & 2: Allocate and serialize outline tree** - `a76dc68` (feat) (with `f72c032` for tests)

## Files Created/Modified
- `lib/rendro/pdf/writer.ex` - Added UTF-16BE conversion and hierarchical outline serialization logic.
- `test/rendro/pdf/writer_test.exs` - Validated accurate destination mapping, linked structures, and string encodings.

## Decisions Made
- Omitted `/Count` from outline items, enforcing a default collapsed state in viewers which avoids unnecessary counting complexity.
- Implemented serialization locally within Writer without breaking out a dedicated builder module to keep PR footprint lean and coupled to other allocation logic.

## Deviations from Plan
None.

## Issues Encountered
None.

## User Setup Required
None.

## Next Phase Readiness
Phase 98 implementation is complete.

---
*Phase: 98*
*Completed: 2026-06-14*

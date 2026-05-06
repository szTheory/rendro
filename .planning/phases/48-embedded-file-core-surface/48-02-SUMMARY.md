---
phase: 48-embedded-file-core-surface
plan: 02
subsystem: core
tags: [embedded-files, pdf, deterministic]
requires:
  - phase: 48-01
    provides: validated embedded-file registry descriptors on the document
provides:
  - deterministic embedded-file stream and file-spec serialization in the PDF writer
  - opt-in catalog `/Names` and `/AF` wiring for document-level embedded files
  - proof tests for attachment ordering, params metadata, and no page-level attachment annotations
affects: [49-01, 50-01]
tech-stack:
  added: []
  patterns: [writer allocation helpers, conditional catalog injection, deterministic attachment ordering]
key-files:
  created: []
  modified:
    - lib/rendro/pdf/writer.ex
    - test/rendro/pdf/writer_test.exs
    - test/rendro/deterministic_test.exs
key-decisions:
  - "Embedded files extend the existing writer allocation/build funnel instead of adding an inline serializer or separate PDF surface."
  - "Attachment catalog wiring stays document-level only: `/Names`, `/EmbeddedFiles`, and `/AF` are emitted without any page-level file-attachment annotations."
patterns-established:
  - "Validated registry descriptors are sorted by stable authored keys before PDF object allocation."
  - "Catalog-level optional PDF surfaces follow the same conditional injection seam as AcroForm wiring."
requirements-completed: [EMBED-01, EMBED-02, EMBED-03]
duration: 5min
completed: 2026-05-06
---

# Phase 48 Plan 02: Embedded File Core Surface Summary

**Deterministic embedded-file streams, file specs, and catalog names-tree wiring in the core PDF writer**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-06T01:20:32Z
- **Completed:** 2026-05-06T01:25:03Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Extended `Rendro.PDF.Writer` with deterministic embedded-file allocation helpers and object builders parallel to the existing font/image/form-field pipeline.
- Added catalog-level `/Names`, `/EmbeddedFiles`, and `/AF` wiring that appears only when embedded files exist and stays sorted by stable authored keys.
- Added proof tests for `/EmbeddedFile`, `/Filespec`, `/EF`, `/Params`, metadata dates, deterministic attachment ordering, and the absence of page-level file-attachment annotations.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add deterministic embedded-file object allocation and serialization** - `efdc9c8` (test), `7f001b3` (feat)
2. **Task 2: Wire catalog `/Names` and `/AF` deterministically** - `cd42602` (test), `c0bb999` (feat)

## Files Created/Modified

- `lib/rendro/pdf/writer.ex` - allocates embedded-file objects, serializes file specs and params metadata, and injects catalog attachment wiring only when needed.
- `test/rendro/pdf/writer_test.exs` - proves embedded-file stream/file-spec structure, names-tree and `/AF` output, metadata params, and no page-level attachment annotations.
- `test/rendro/deterministic_test.exs` - proves deterministic output remains identical across different embedded-file registration orders.

## Decisions Made

- Reused the writer’s existing allocation/build/catalog seams so embedded files follow the same deterministic object-planning model as other PDF resources.
- Kept the attachment surface strictly document-level to satisfy the phase threat model and avoid widening Rendro into generic attachment-annotation behavior.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial Task 2 tests used `String.index/2`, which is unavailable in the current Elixir version; the assertions were corrected to use binary offsets before the RED commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The writer now emits deterministic, validated embedded-file catalog surfaces that later docs/support phases can reference directly.
- Link-annotation work can extend the existing page annotation seam independently because this plan kept attachment behavior out of page-level `/Annots`.

## Self-Check: PASSED

- Found summary file: `.planning/phases/48-embedded-file-core-surface/48-02-SUMMARY.md`
- Found task commit: `efdc9c8`
- Found task commit: `7f001b3`
- Found task commit: `cd42602`
- Found task commit: `c0bb999`

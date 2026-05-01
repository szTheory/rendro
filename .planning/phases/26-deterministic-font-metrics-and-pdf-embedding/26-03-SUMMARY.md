---
phase: 26-deterministic-font-metrics-and-pdf-embedding
plan: 03
subsystem: typography
tags: [fonts, pdf, truetype, deterministic-layout, docs-contract]
requires:
  - phase: 26-deterministic-font-metrics-and-pdf-embedding
    provides: embedded font registration, preflighted metrics payloads, and measurement/pagination parity proof
provides:
  - writer-side embedded TrueType font object/resource construction from shared resolved descriptors
  - structural regression proof for embedded font resources and no-fallback writer failures
  - repeated-run deterministic proof tying embedded font layout parity to final PDF resources
affects: [phase-27, writer, deterministic-tests, docs-contract]
tech-stack:
  added: []
  patterns: [shared resolved font payload, explicit built-in-versus-embedded writer branches, structural embedding proofs]
key-files:
  created: []
  modified: [lib/rendro/pdf/writer.ex, test/rendro/pdf/writer_test.exs, test/rendro/deterministic_test.exs, test/docs_contract/integrations_claims_test.exs]
key-decisions:
  - "Kept built-in and embedded writer paths explicit while sharing one collection and resource-allocation pipeline."
  - "Drove embedded PDF objects from the existing resolved Rendro.PDF.Font payload instead of reparsing font sources in Writer."
  - "Locked the public proof surface to repeated-run layout/resource parity instead of expanding the support claim into broad byte-identity or fallback promises."
patterns-established:
  - "Writer allocates one logical font map for both built-in Type1 fonts and embedded TrueType font object graphs."
  - "Deterministic typography proof should assert wrapped lines, page count, resolved logical font identity, and embedded PDF resources together."
requirements-completed: [FONT-02, FONT-03]
duration: 4 min
completed: 2026-05-01
---

# Phase 26 Plan 03: Deterministic Font Metrics and PDF Embedding Summary

**Writer now embeds supported custom fonts through shared resolved descriptors and the test suite proves deterministic wrapped-line/page-count parity against the final embedded PDF resource graph**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-01T01:35:00Z
- **Completed:** 2026-05-01T01:39:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Extended `Rendro.PDF.Writer` to emit embedded TrueType font dictionaries, width tables, font descriptors, and font-file streams from the preflighted resolved font payload.
- Added structural writer regressions proving supported embedded fonts allocate explicit PDF resources and invalid explicit embedded fonts fail instead of silently degrading to Helvetica.
- Added a repeated-run deterministic proof that the same embedded logical font drives wrapping, pagination, and final PDF resources while keeping docs-contract claims narrow.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add embedded-font object/resource construction to Writer** - `981a94a` (feat)
2. **Task 2: Lock the truthful deterministic proof surface for custom fonts** - `46a9265` (test)

## Files Created/Modified
- `lib/rendro/pdf/writer.ex` - Added embedded-font object allocation, serialization, width scaling, and strict resource resolution.
- `test/rendro/pdf/writer_test.exs` - Added structural embedded-font PDF assertions and an invalid-font no-fallback regression.
- `test/rendro/deterministic_test.exs` - Added repeated-run parity coverage across measurement, pagination, and final embedded PDF resources.
- `test/docs_contract/integrations_claims_test.exs` - Pinned the narrow custom-font support claim against broad fallback or language promises.

## Decisions Made

- Kept one logical font collection pipeline and one resource map, but preserved explicit built-in versus embedded object construction because the PDF object graphs differ materially.
- Reused the resolved `Rendro.PDF.Font` payload already produced by registration/preflight instead of reopening files or reparsing font inputs inside Writer.
- Treated deterministic byte identity as an internal regression that can still exist, while making the new Phase 26 proof focus on layout stability plus structural embedding.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first writer patch accidentally mixed numbered-object tuples into the PDF body assembly and inverted one width-scaling call for embedded fonts. Both regressions were corrected before the Task 1 verification commit landed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 27 can build fallback and unsupported-glyph behavior on top of a closed measure-to-writer shared-font contract.
- Custom-font support is now proved narrowly around deterministic layout/resource parity without implying fallback-chain or broad Unicode behavior.

## Self-Check: PASSED

---
*Phase: 26-deterministic-font-metrics-and-pdf-embedding*
*Completed: 2026-05-01*

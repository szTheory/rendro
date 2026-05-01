---
phase: 26-deterministic-font-metrics-and-pdf-embedding
plan: 01
subsystem: typography
tags: [fonts, truetype, pdf, deterministic-layout, build-validation]
requires:
  - phase: 25-font-registry-and-public-typography-contract
    provides: document-owned logical font registry and shared font resolution seam
provides:
  - explicit embedded-font registration on document and top-level APIs
  - eager path and binary normalization into owned registry bytes
  - build-time embedded font preflight with cached shared metrics payload
affects: [phase-26-plan-02, phase-26-plan-03, font-registry, measurement, writer]
tech-stack:
  added: [in-repo truetype parser]
  patterns: [document-owned source normalization, build-time font preflight cache, explicit embedded-vs-built-in APIs]
key-files:
  created: [lib/rendro/pdf/font_parser.ex, test/support/font_fixture.ex]
  modified: [lib/rendro/document.ex, lib/rendro.ex, lib/rendro/font_registry.ex, lib/rendro/pipeline/build.ex, lib/rendro/pdf/font.ex, test/rendro/document_test.exs, test/rendro_builders_test.exs, test/rendro/pdf/font_test.exs]
key-decisions:
  - "Kept embedded font registration separate from built-in registration to preserve explicit product scope."
  - "Normalized {:path, path} and {:binary, bytes} into owned bytes at registration so later stages never reopen filesystem paths."
  - "Used Build as the deterministic preflight boundary and cached parsed PDF font metrics on the registry for later stage reuse."
patterns-established:
  - "Explicit embedded font family helper registers narrow regular/bold/italic/bold_italic logical names and rejects partial families before mutation."
  - "Shared font resolution now carries preflighted metrics data for both built-in and embedded fonts through the existing registry seam."
requirements-completed: [FONT-03]
duration: 16 min
completed: 2026-05-01
---

# Phase 26 Plan 01: Deterministic Font Metrics and PDF Embedding Summary

**Explicit embedded-font registration with owned source normalization and Build-time TrueType preflight cached onto the shared font registry**

## Performance

- **Duration:** 16 min
- **Started:** 2026-05-01T01:10:00Z
- **Completed:** 2026-05-01T01:26:26Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- Added explicit document and top-level APIs for embedded font registration without overloading the built-in font path.
- Normalized tagged path and binary font inputs into owned bytes on the document registry and added a narrow four-variant family helper with typed partial-family failures.
- Preflighted embedded TrueType fonts during Build, cached parsed metrics as shared `Rendro.PDF.Font` data, and failed unsupported or non-embeddable fonts before measure or render.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add explicit embedded-font registration and eager input normalization** - `0b8bd05` (feat)
2. **Task 2: Preflight embedded-font readiness and generalize the shared font descriptor** - `8d8f4d7` (feat)

## Files Created/Modified
- `lib/rendro/document.ex` - Added document-owned embedded font and family registration helpers.
- `lib/rendro.ex` - Added top-level wrappers for embedded font registration.
- `lib/rendro/font_registry.ex` - Extended registry descriptors, family validation, normalization, and preflight caching.
- `lib/rendro/pipeline/build.ex` - Added deterministic registry preflight before downstream validation.
- `lib/rendro/pdf/font.ex` - Generalized the metrics carrier for built-in and embedded fonts.
- `lib/rendro/pdf/font_parser.ex` - Parsed supported TrueType data into deterministic widths and embeddability metadata.
- `test/rendro/document_test.exs` - Covered path/binary normalization and typed partial-family failures.
- `test/rendro_builders_test.exs` - Covered top-level embedded font helpers and explicit variant registration.
- `test/rendro/pdf/font_test.exs` - Covered successful preflight, unsupported data failure, and Build-stage non-embeddable rejection.
- `test/support/font_fixture.ex` - Provided deterministic test-font discovery and restricted-license mutation helpers.

## Decisions Made

- Kept the public contract explicit: built-in registration stays on `register_font/3`, while embedded fonts use dedicated helpers.
- Treated path inputs as authoring ergonomics only; registration immediately captures bytes so later stages stay independent from temp files or host layout.
- Narrowed support to preflighted TrueType sources for this slice and surfaced unsupported formats through typed Build errors instead of fallback.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added a small in-repo TrueType parser/helper layer**
- **Found during:** Task 2 (Preflight embedded-font readiness and generalize the shared font descriptor)
- **Issue:** The repo had no existing embedded-font parser or deterministic fixture seam, so Build could not preflight supported custom fonts or cache shared metrics.
- **Fix:** Added `lib/rendro/pdf/font_parser.ex` plus `test/support/font_fixture.ex` to parse supported TrueType inputs, enforce embeddability, and drive focused verification.
- **Files modified:** `lib/rendro/pdf/font_parser.ex`, `test/support/font_fixture.ex`, `lib/rendro/font_registry.ex`, `lib/rendro/pdf/font.ex`
- **Verification:** `mix test test/rendro/pdf/font_test.exs test/rendro/pipeline/measure_test.exs`
- **Committed in:** `8d8f4d7`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary to make Build-time deterministic preflight real. No broader scope such as fallback chains, shaping, or writer embedding was added.

## Issues Encountered

- No repo-local font fixture existed, so test support now locates a known TrueType font from common system paths and mutates its OS/2 embedding flag for the non-embeddable regression.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Measurement can now reuse the same preflighted `Rendro.PDF.Font` payload for embedded fonts without changing the wrapping algorithm.
- Writer embedding object construction is still pending in later Phase 26 plans; this plan intentionally stopped at registration, metrics, and early failure boundaries.

## Self-Check: PASSED

---
*Phase: 26-deterministic-font-metrics-and-pdf-embedding*
*Completed: 2026-05-01*

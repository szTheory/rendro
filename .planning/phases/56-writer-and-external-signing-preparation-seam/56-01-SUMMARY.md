---
phase: 56-writer-and-external-signing-preparation-seam
plan: 01
subsystem: writer
tags: [pdf, signatures, determinism, exunit]
requires:
  - phase: 55-02
    provides: authored unsigned signature-field contract and truthful support boundary
provides:
  - deterministic unsigned `/Sig` widget serialization on the existing AcroForm seam
  - negative guardrails against signing-value and signer-policy placeholders in ordinary render output
  - repeated-render proof for byte-identical unsigned signature documents
affects: [lib/rendro/pdf/writer.ex, test/rendro/pdf/writer_test.exs, test/rendro/deterministic_test.exs]
tech-stack:
  added: []
  patterns: [standalone widget allocation reuse, Rendro-owned signature appearance stream, deterministic render regression]
key-files:
  created: []
  modified:
    - lib/rendro/pdf/writer.ex
    - test/rendro/pdf/writer_test.exs
    - test/rendro/deterministic_test.exs
key-decisions:
  - "Keep `:signature` on the existing standalone widget allocation path instead of introducing a signature-only writer subsystem."
  - "Emit visible unsigned `/Sig` widgets with a Rendro-owned `/AP` stream while omitting `/V`, signing placeholder reservation, and signer-policy dictionaries."
  - "Lock deterministic behavior with repeated render assertions at ordinary render time only."
patterns-established:
  - "Signature widgets follow the same page `/Annots` and catalog `/AcroForm` seams as other standalone fields."
  - "Negative regression checks distinguish signer-owned `/Contents` placeholders from normal page `/Contents` references."
requirements-completed: [SIGN-03]
duration: 2min
completed: 2026-05-06
---

# Phase 56 Plan 01: Writer Signature Widget Seam Summary

**Rendro now serializes visible unsigned signature widgets deterministically through the existing writer seam without introducing signing-value placeholders or signer-policy dictionaries into ordinary render output.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-06T21:39:42-04:00
- **Completed:** 2026-05-06T21:41:15-04:00
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added a dedicated `:signature` branch inside `Rendro.PDF.Writer` that reuses standalone field allocation, page annotation wiring, and catalog AcroForm wiring.
- Serialized visible unsigned signature widgets with `/Subtype /Widget`, `/FT /Sig`, `/Rect`, `/T`, `/P`, and a Rendro-owned `/AP` appearance stream while omitting `/V`, `/ByteRange`, signer-owned `/Contents` placeholders, `/Lock`, `/SV`, `/Reference`, `/Filter`, and `/SubFilter`.
- Added deterministic regression coverage proving the same authored signature document renders to byte-identical output across repeated deterministic renders.

## Task Commits

1. **Task 1: Extend the existing standalone widget writer path for visible unsigned signature fields**
   - `3a4952a` (`test`) RED: failing writer and deterministic coverage for unsigned signature widgets
   - `98024df` (`feat`) GREEN: standalone `/Sig` widget serialization plus passing writer regressions
2. **Task 2: Prove repeated deterministic renders of the same signature document produce identical bytes**
   - `3a4952a` (`test`) RED: failing repeated-render signature determinism coverage
   - `98024df` (`feat`) GREEN: passing repeated-render signature determinism proof against the writer seam

## Files Created/Modified

- `lib/rendro/pdf/writer.ex` - adds a dedicated unsigned signature widget serializer and visible appearance stream on the existing standalone field path.
- `test/rendro/pdf/writer_test.exs` - adds structural assertions for unsigned `/Sig` widgets and negative guardrails against signing placeholders and policy dictionaries.
- `test/rendro/deterministic_test.exs` - adds repeated deterministic render proof for a signature-field document.

## Decisions Made

- Signature widgets stay on the existing standalone field allocation path with no new writer subsystem.
- Ordinary render remains strictly unsigned; signer-owned dictionaries and placeholder reservation stay out of base render output.
- `/Contents` negative coverage is scoped to signer-placeholder forms (`/Contents <` and `/Contents (`) so it does not conflict with the normal page `/Contents` reference.

## Deviations from Plan

### Execution Environment

- `gsd-sdk query ...` was unavailable in this environment; state/roadmap automation could not be run from the prescribed executor flow.

### Auto-fixed Issues

- **1. [Rule 1 - Test bug] Narrowed the `/Contents` negative assertions**
  - **Found during:** Task 1 verification
  - **Issue:** A blanket `refute pdf =~ "/Contents"` incorrectly matched the normal page `/Contents` entry instead of signer-owned placeholder content.
  - **Fix:** Tightened the assertions to refute only signer-placeholder forms: `/Contents <` and `/Contents (`.
  - **Files modified:** `test/rendro/pdf/writer_test.exs`, `test/rendro/deterministic_test.exs`
  - **Commit:** `98024df`

## Known Stubs

None.

## Threat Flags

None.

## Issues Encountered

- `mix test` emits pre-existing adapter module redefinition warnings for `Rendro.Adapters.Mailglass` and `Rendro.Adapters.Accrue`; this plan left them untouched.

## Next Phase Readiness

- The writer now emits a deterministic unsigned `/Sig` structure that later preparation work can target without adding prepare-time placeholders or mutating ordinary render semantics.

## Self-Check: PASSED

- Verified modified files exist: `lib/rendro/pdf/writer.ex`, `test/rendro/pdf/writer_test.exs`, `test/rendro/deterministic_test.exs`
- Verified commits exist: `3a4952a`, `98024df`
- Verified plan commands pass: `mix test test/rendro/pdf/writer_test.exs` and `mix test test/rendro/deterministic_test.exs test/rendro/pdf/writer_test.exs`

---
*Phase: 56-writer-and-external-signing-preparation-seam*
*Completed: 2026-05-06*

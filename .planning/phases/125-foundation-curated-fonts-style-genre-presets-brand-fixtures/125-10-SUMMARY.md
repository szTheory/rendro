---
phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures
plan: 10
subsystem: verification
tags: [presets, fonts, cid-widths, pdfium, raster-snapshots, deterministic]
requires:
  - phase: 125-06
    provides: Twelve-row pinned-PDFium advisory raster matrix
  - phase: 125-09
    provides: Complete six-domain data-only fixture corpus
provides:
  - Correct glyph-ID CID advance widths for every embedded TrueType font
  - Regenerated, pinned PDFium v0.11.0 references and an approved bounded twelve-row preset review
  - Green deterministic Phase 125 gates with regenerated affected release artifacts
affects: [phase-126-polish, phase-127-public-example-catalog, embedded-font-rendering]
tech-stack:
  added: []
  patterns: [separate Unicode layout metrics from CID glyph-ID widths, pinned-PDFium advisory references]
key-files:
  created: [test/rendro/pdf/cid_font_test.exs]
  modified: [lib/rendro/pdf/font_parser.ex, lib/rendro/pdf/cid_font.ex, priv/raster_refs/presets, assets/rendro/artifacts.json]
key-decisions:
  - "CID /W tables use parsed glyph-ID metrics while shaping and Certificate centering retain Unicode-codepoint metrics."
  - "All twelve advisory references were re-blessed through the SHA-verified PDFium v0.11.0 container boundary after the corrected embedded-font bytes changed."
patterns-established:
  - "Embedded font descriptors retain both codepoint and glyph-ID width maps for their distinct consumers."
requirements-completed: [PRESET-01, PRESET-02, PRESET-03, PRESET-04, PRESET-05, PRESET-06, FONT-01, FONT-02, FONT-03, FONT-04, FONT-05, CATALOG-05]
coverage:
  - id: D1
    description: "Embedded CID widths match emitted glyph IDs, preventing collapsed advances in curated-font PDFs."
    requirement: FONT-04
    verification:
      - kind: unit
        ref: test/rendro/pdf/cid_font_test.exs#CID-widths-follow-emitted-glyph-IDs-rather-than-Unicode-codepoints
        status: pass
    human_judgment: false
  - id: D2
    description: "The complete twelve-row pinned-PDFium preset matrix matches committed hashes."
    requirement: PRESET-04
    verification:
      - kind: integration
        ref: PATH=/private/tmp/rendro-pdfium-Riomtw/bin:$PATH mix test --include raster_snapshot test/rendro/theme/preset_raster_snapshot_test.exs --max-failures 1
        status: pass
    human_judgment: false
  - id: D3
    description: "Bounded visual review confirms genre distinction, no new overflow, Certificate centering, and Brutalist legibility."
    verification:
      - kind: manual_procedural
        ref: tmp/rendro_preset_raster_review/*_page_1.png
        status: pass
    human_judgment: true
    rationale: "Pinned raster output supports bounded reader judgment but is not a universal quality or compliance guarantee."
metrics:
  duration: 15min
  completed: 2026-08-17
status: complete
---

# Phase 125 Plan 10: Deterministic Gate and Preset Raster Review Summary

**Correct embedded-font CID advances restore readable, centered Certificate typography and close the twelve-row pinned-PDFium preset review.**

## Performance

- **Duration:** 15 min (continuation)
- **Completed:** 2026-08-17T01:41:53Z
- **Tasks:** 2/2
- **Files modified:** 26

## Accomplishments

- Repaired embedded TrueType CID `/W` generation to use glyph-ID metrics rather than Unicode codepoint metrics; layout and Certificate centering keep their correct codepoint-width map.
- Added a deterministic regression test that proves emitted CIDs receive their glyph-specific advances.
- Re-blessed all twelve changed PDFium v0.11.0 page-one references using the verified pinned binary/container path, then reran the ordinary comparator successfully.
- Reviewed all twelve generated PNGs. The repaired Brutalist/Editorial/Swiss Certificate rows are legible and centered, genre differences remain visible, and no newly introduced clipping or overflow was observed. Existing Phase 126 dark-cell, hierarchy, and Payslip-polish ownership remains unchanged.
- Regenerated only affected launch artifacts and their manifest/documentation hashes; all deterministic tests, `mix ci.fast`, and the unchanged `priv/goldens` check pass.

## Task Commits

1. **Task 1: Run the deterministic phase gate and coverage audit** — `76727dc`
2. **Task 2: Review the fixed pinned-PDFium preset matrix** — `0bba3b9`, `6c92b9c`

## Files Created/Modified

- `lib/rendro/pdf/font_parser.ex`, `lib/rendro/pdf/font.ex`, `lib/rendro/font_registry.ex`, `lib/rendro/pdf/cid_font.ex` — preserve and consume glyph-indexed widths for PDF CID tables.
- `test/rendro/pdf/cid_font_test.exs` — prevents codepoint-indexed CID width regressions.
- `priv/raster_refs/presets/**` — twelve genuine PDFium v0.11.0 reference hashes.
- `assets/rendro/gallery/payslip.png`, `assets/rendro/manual.pdf`, `assets/rendro/artifacts.json`, `README.md`, and `guides/*.md` — regenerated affected release evidence and derived hash documentation.

## Decisions Made

- Kept the fix at the font descriptor/CID boundary, avoiding Certificate-specific masking and fixing every embedded-font renderer path.
- Retained the advisory boundary: raster review is bounded visual evidence, not a quality, accessibility, PDF/UA, WCAG, or print-safety guarantee.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected CID width indexing for embedded fonts**
- **Found during:** Task 2
- **Issue:** PDF text emitted glyph IDs while the CID `/W` table used Unicode-codepoint keys, causing corrupt or overlapping advances in Certificate rows.
- **Fix:** Added parser-provided glyph widths to embedded font descriptors and used that map for the Identity-H CID width table.
- **Files modified:** `lib/rendro/pdf/{font_parser,font,cid_font}.ex`, `lib/rendro/font_registry.ex`, `test/rendro/pdf/cid_font_test.exs`
- **Verification:** Focused font/Certificate contracts, full suite, `mix ci.fast`, and pinned raster comparator passed.
- **Committed in:** `6c92b9c`

**2. [Rule 1 - Bug] Regenerated affected byte baselines and release artifacts**
- **Found during:** Task 2
- **Issue:** Corrected embedded-font advances changed two frozen PDF byte baselines and the Payslip launch artifact source/raster hashes.
- **Fix:** Rendered the canonical fixtures, regenerated launch artifacts through the pinned PDFium path, and updated derived documentation hashes.
- **Files modified:** byte-identity tests, `assets/rendro/**`, `README.md`, and `guides/**`
- **Verification:** `mix test` and `mix ci.fast` passed with no `priv/goldens` drift.
- **Committed in:** `6c92b9c`

**Total deviations:** 2 auto-fixed Rule 1 bugs.

## Known Stubs

None.

## Next Phase Readiness

Phase 125 is mechanically green and has an explicit bounded visual disposition. Phase 126 retains ownership of the previously documented dark-cell, Ticket hierarchy, and Payslip wrapping polish; no new Phase 125 blocker remains.

## Self-Check: PASSED

- Verified all twelve committed raster references and all twelve external review PNGs exist.
- Verified task commits `76727dc`, `0bba3b9`, and `6c92b9c` exist.
- Verified the focused contracts, `mix test`, `mix ci.fast`, pinned normal comparator, and `git diff --exit-code -- priv/goldens` all pass.

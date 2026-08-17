---
phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures
plan: "02"
subsystem: typography
tags: [fonts, provenance, hex, true-type, deterministic-subsetting]
requires:
  - phase: 125-01
    provides: Swiss preset tracer with explicit curated-font registration
provides:
  - Four pinned static Regular TrueType faces with auditable provenance
  - All four stable curated role descriptors and genre registration sets
  - Positive Hex archive inclusion proof for font assets and NOTICE
  - Deterministic normalized glyph input at the subsetter boundary
affects: [preset rendering, package delivery, public catalog]
tech-stack:
  added: []
  patterns: [official-release provenance records, package tarball contract, sorted unique glyph inputs]
key-files:
  created:
    - priv/fonts/source-sans-3/SourceSans3-Regular.ttf
    - priv/fonts/source-serif-4/SourceSerif4-Regular.ttf
    - test/rendro/theme/preset_fonts_test.exs
    - test/docs_contract/preset_fonts_package_contract_test.exs
  modified:
    - lib/rendro/theme/presets.ex
    - lib/rendro/pdf/font_subsetter.ex
    - NOTICE
    - test/rendro/pdf/font_subsetter_test.exs
decisions:
  - Curated roles use one unmodified static Regular face per family; registration remains explicit and document-owned.
  - Glyph inputs are sorted and deduplicated before subset dependency traversal.
metrics:
  duration: 4m
  completed_date: 2026-08-17
  tasks_completed: 2
  files_changed: 9
status: complete
---

# Phase 125 Plan 02: Curated Font Provenance and Deterministic Subsetting Summary

Four pinned static Regular TrueType faces now ship with auditable provenance, Hex package proof, stable descriptor roles, and deterministic glyph-set subsetting.

## Accomplishments

- Vendored Source Sans 3 3.052R and Source Serif 4 4.005R from their official pinned release archives without transforming their bytes.
- Completed the four-role `Rendro.Theme.Presets` descriptor map and genre role sets for Swiss, Humanist, Editorial, Corporate Classic, and Minimal Mono.
- Added four delimited `NOTICE` records with source identity, OFL 1.1 reference, tag, commit, archive member, SHA-256, and retained-RFN/unmodified-byte statements.
- Added parser, preflight, provenance, package-tarball, permutation, duplicate, empty-input, and two-run byte-determinism contracts.
- Normalized caller glyph IDs with `Enum.uniq/1` and `Enum.sort/1` before subset dependency traversal.

## Verification

- `mix test test/rendro/theme/preset_fonts_test.exs test/docs_contract/preset_fonts_package_contract_test.exs test/rendro/pdf/font_subsetter_test.exs --max-failures 1` — 8 tests, 0 failures.
- `mix hex.build` — succeeded; direct archive inspection found `NOTICE` and all four exact `priv/fonts/...ttf` paths.
- `mix format --check-formatted` — passed.
- SHA-256 values from disk match their respective four delimited `NOTICE` records.

## Task Commits

1. `99b195a` — `feat(125-02): complete curated font provenance and packaging`
2. `f5a1eb6` — `feat(125-02): normalize subset glyph inputs`

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Verified both newly vendored static TTF files exist.
- Verified both task commits exist in git history.

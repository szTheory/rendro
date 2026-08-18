---
phase: 127-public-example-catalog-quality-ratchet
plan: 03
subsystem: catalog-evidence
tags: [pdfium, catalog, provenance, ci]
requires:
  - phase: 127-02
    provides: catalog quality join
provides:
  - 32 hash-bound public catalog previews
  - pinned PDFium advisory provenance and bounded review evidence
affects: [127-04, 127-05, 128]
tech-stack:
  added: []
  patterns: [isolated pinned-raster import, reviewer-owned dispositions]
key-files:
  created: [assets/rendro/catalog.json, assets/rendro/catalog]
  modified: [.github/workflows/ci.yml, priv/quality/rubric_scores.json]
key-decisions:
  - "Initial hash capture skips catalog check only before all 32 reviewer bindings exist."
  - "First/final multipage proof uses PDFium's actual raster page list."
requirements-completed: [CATALOG-01, CATALOG-03, CATALOG-04]
duration: 1h
completed: 2026-08-17
status: complete
---

# Phase 127 Plan 03: Public Catalog Evidence Summary

Pinned PDFium evidence now binds exactly 32 public page-one previews to explicit unscored reviewer dispositions.

## Accomplishments

- Imported exactly 32 catalog PNGs and no source PDFs or trailing public pages.
- Bound 12 flagship-pending and 20 bounded-unscored dispositions to PNG and complete-PDF hashes.
- Added graph-disconnected isolated CI generation, full-size 16-image review output, and fail-closed provenance guards.

## Provenance

- **Initial authority:** ref `gsd/phase-127-catalog-bless-9479ee24801d`, SHA `9479ee24801db5e9075705a88da66737fd55fc3d`, run `32083898604`, advisory job `95552265981`.
- **Post-binding authority:** ref `gsd/phase-127-catalog-bless-2f8d20303ffe`, SHA `2f8d20303ffe7999688e3320b9d38a486bd9db95`, run `32084695699`, advisory job `95554693775`.
- **PDFium:** `v0.11.0`, SHA-256 `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`.
- **Imported paths:** `assets/rendro/catalog.json`, `assets/rendro/catalog/**` (32 PNGs), and `tmp/rendro_phase127_review/**` (16 review PNGs; untracked/ignored external review evidence).

## Retained CI Refs for Plan 05 Cleanup

- `gsd/phase-127-catalog-bless-f24f19f32dc3` — run `32079289456`, job `95538919550` (dynamic atom failure).
- `gsd/phase-127-catalog-bless-9f2d2551d699` — run `32079891632`, job `95540674861` (review hash helper failure).
- `gsd/phase-127-catalog-bless-4394c8ee75ac` — run `32080463323`, job `95542312733` (missing review directory).
- `gsd/phase-127-catalog-bless-3016cd1f5f17` — run `32082280090`, job `95547446859` (PDF page-count mismatch).
- `gsd/phase-127-catalog-bless-1d872e4df1db` — run `32082874361`, job `95549124618` (pre-binding check failure).
- `gsd/phase-127-catalog-bless-16818db494e0` — run `32083414414`, job `95550770044` (skeleton-manifest check failure).

## Verification

- `mix ci.fast` — passed (1,778 tests, 0 failures).
- Focused catalog/rubric contracts — passed (83 tests).
- Successful advisory jobs verified the exact 32/16 payload cardinalities, commit SHA, run ID, and PDFium pin.

## Deviations from Plan

### Auto-fixed Issues

- Rule 1: Removed fresh-process dynamic atom conversion, corrected review hashing and directory creation, and derived bounded proof endpoints from actual PDFium output.
- Rule 3: Allowed initial hash capture without reviewer records while preserving a fail-closed check once all 32 bindings exist.

## Self-Check: PASSED

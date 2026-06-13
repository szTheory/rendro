---
phase: 86-self-proving-launch-artifacts
plan: 02
subsystem: docs-contract
tags: [launch-artifacts, manifest, package, docs-contract, pdfium-boundary]
requires:
  - phase: 86-self-proving-launch-artifacts
    provides: 86-01 advisory CI boundary
provides:
  - Static manifest validation for launch artifacts
  - Required docs-contract assertions for generated README/guide blocks and package assets
affects: [phase-86, docs-contract, package]
tech-stack:
  added: []
  patterns:
    - Static launch proof checks committed bytes and Rendro-rendered PDFs without invoking pdfium
    - Hex package tests register tarball cleanup immediately after computing the package path
key-files:
  created: []
  modified:
    - lib/rendro/launch_artifacts.ex
    - test/docs_contract/launch_artifacts_claims_test.exs
key-decisions:
  - "Manifest shape drift, hash drift, docs block drift, package omissions, alt text, and overclaims are required docs-contract concerns."
  - "PNG regeneration and renderer-version drift remain advisory/raster concerns."
patterns-established:
  - "Expose generated docs blocks as deterministic functions and compare public Markdown blocks exactly."
  - "Use manifest-map mutation tests for static drift coverage instead of writing temporary PDFs or PNGs."
requirements-completed: [GAL-01, GAL-02, GAL-03]
duration: 5min
completed: 2026-06-11
---

# Phase 86 Plan 02: Static Docs-Contract Proof Summary

**Launch artifact manifest, docs, manual, and package contents are now statically checked without requiring pdfium.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-11T18:03:20Z
- **Completed:** 2026-06-11T18:08:26Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Expanded `Rendro.LaunchArtifacts.static_contract_errors/1` to validate manifest metadata, renderer pin fields, SHA-256 formats, gallery IDs, dimensions, alt text, captions, committed asset hashes, source PDF hashes, manual hash, and generated docs blocks.
- Added required docs-contract tests for exact README/recipes generated block equality, image links, alt text, source/PNG hashes, manual link/hash, bounded public copy, and launch lane registration.
- Hardened the Hex package test so the manifest, manual, and all five gallery PNGs are included and the generated tarball is removed after the test.

## Task Commits

1. **Task 1: Expand static manifest and drift validation without pdfium** - `7c2a9ef` (test)
2. **Task 2: Harden launch artifact docs-contract tests and package inclusion** - `c76697c` (test)

## Files Created/Modified

- `lib/rendro/launch_artifacts.ex` - Adds strict static manifest/hash validation and malformed-manifest guards.
- `test/docs_contract/launch_artifacts_claims_test.exs` - Adds docs block equality, package inclusion, copy, alt text, link, and drift assertions.

## Decisions Made

- Kept `static_contract_errors/0` pdfium-free: it reads committed files, renders Rendro source PDFs/manual, and compares hashes.
- Allowed negative `not GUI-viewer proof` language by rejecting positive overclaims such as `is GUI-viewer proof` and `are GUI-viewer proof`.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `mix run -e 'case Rendro.LaunchArtifacts.static_contract_errors() do [] -> IO.puts("static ok"); errors -> raise Enum.join(errors, "\n") end'` - passed
- Pin drift probe using `static_contract_errors/1` - passed
- Empty alt-text probe using `static_contract_errors/1` - passed
- Manual hash drift probe using `static_contract_errors/1` - passed
- `mix test test/docs_contract/launch_artifacts_claims_test.exs` - 9 tests, 0 failures
- `mix test test/docs_contract/launch_artifacts_claims_test.exs --trace` - 9 tests, 0 failures
- `test ! -f rendro-1.0.0.tar` - passed

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 86-03. The static proof lane is strict enough to catch fixture, docs, manual, and package drift before final raster regeneration.

---
*Phase: 86-self-proving-launch-artifacts*
*Completed: 2026-06-11*

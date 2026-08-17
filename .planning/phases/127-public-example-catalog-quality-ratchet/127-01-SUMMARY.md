---
phase: 127-public-example-catalog-quality-ratchet
plan: 01
subsystem: public-example-catalog
tags: [catalog, deterministic-rendering, mix-tasks, presets]
requires: [phase-126-polish]
provides: [literal-32-cell-registry, catalog-generation, catalog-check]
affects: [phase-128-static-configurator]
tech-stack:
  added: []
  patterns: [dev-only catalog tooling, literal membership, deterministic source PDF provenance]
key-files:
  created: [dev/rendro/catalog.ex, dev/mix/tasks/rendro/catalog/gen.ex, dev/mix/tasks/rendro/catalog/check.ex, test/rendro/catalog_test.exs]
  modified: [mix.exs, priv/examples/ticket/aurora-live/ticket.json, lib/rendro/recipes/statement.ex, lib/rendro/recipes/ticket.ex]
decisions:
  - Keep catalog membership as an explicit, ordered 32-row registry compiled only in dev/test.
  - Keep catalog generation and checking as separate bounded Mix operations.
metrics:
  duration: 25m
  completed: 2026-08-17
status: complete
---

# Phase 127 Plan 01: Public Catalog Spine Summary

Delivered a dev-only, literal 32-cell catalog that deterministically renders complete source PDFs and reserves only page-one PNGs for public artifacts.

## Completed Tasks

1. Traced the default Invoice fixture through safe loading, transformation, theme construction, and byte-stable rendering.
2. Added the locked, domain-first 32-cell registry with default baselines, curated light/dark pairs, preset font registration, and Aurora Live metadata.
3. Added deliberate `mix rendro.catalog.gen` and read-only `mix rendro.catalog.check` operations with manifest/provenance validation.

## Decisions Made

- Catalog tooling lives under `dev/` and is compiled only in dev/test, preserving the pure runtime package surface.
- The registry is explicit and ordered; it has exact-count, hard-ceiling, unique-ID, and unique-output-path checks rather than fixture discovery or product generation.
- Generation owns only catalog PNGs and `catalog.json`; it does not write quality or reviewer records.

## Verification

- `mix test test/rendro/catalog_test.exs --max-failures 1`
- `mix help rendro.catalog.gen`
- `mix help rendro.catalog.check`
- Full 32-cell deterministic source-PDF render sweep
- `MIX_ENV=prod mix compile --warnings-as-errors`

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Expanded themed Statement header capacity
- **Found during:** Task 2 full-registry render sweep
- **Issue:** The Editorial Statement fixture overflowed the themed header region.
- **Fix:** Increased the shared themed header budget so section pagination and template geometry remain aligned.
- **Files modified:** `lib/rendro/recipes/statement.ex`
- **Commit:** `8958b40`

2. [Rule 1 - Bug] Reserved enough native A6 Ticket band capacity for themed realistic fixtures
- **Found during:** Task 2 full-registry render sweep
- **Issue:** The Editorial Ticket title/subtitle and placement content overflowed the fixed main band.
- **Fix:** Applied a themed-only minimum band height while preserving the no-theme layout and native A6 page size.
- **Files modified:** `lib/rendro/recipes/ticket.ex`
- **Commit:** `8958b40`

## Known Stubs

None.

## Self-Check: PASSED

- Catalog module, both Mix tasks, focused test, and this summary exist.
- Task commits `1cc42ce`, `8c71609`, `2a341ea`, `8958b40`, `f950f67`, and `fe3c7c0` exist.

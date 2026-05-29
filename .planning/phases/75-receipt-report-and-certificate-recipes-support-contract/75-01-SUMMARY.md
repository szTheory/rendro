---
phase: 75-receipt-report-and-certificate-recipes-support-contract
plan: 01
subsystem: recipes
tags: [elixir, pdf, pagination, recipes, refactoring, page-size]

# Dependency graph
requires:
  - phase: 74-statement-recipe
    provides: statement.ex with inline chunk_into_pages/formatter/label_resolver/type_name helpers that are now extracted
provides:
  - "Rendro.Recipes.Pagination (@moduledoc false): chunk_rows_into_pages/2, formatter/3, label_resolver/1, type_name/1"
  - "Rendro.PageSize (@moduledoc false): resolve/2 with :a4/:us_letter atoms + landscape swap"
  - "statement.ex refactored onto shared Pagination module with all 51 tests passing"
affects:
  - 75-02-receipt
  - 75-03-certificate
  - any plan using Rendro.Recipes.Pagination or Rendro.PageSize

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Opaque-meta chunker: chunk_rows_into_pages/2 accepts {fmt_row, height, opaque_meta} triples; caller passes balance (Statement) or nil (Receipt)"
    - "Caller-owned effective_capacity: each recipe computes capacity - header_h - [recipe-specific overhead] - epsilon; shared helper receives the pre-computed value"
    - "Named page-size resolution: Rendro.PageSize.resolve(atom_or_tuple, orientation) with landscape swap"

key-files:
  created:
    - lib/rendro/recipes/pagination.ex
    - lib/rendro/page_size.ex
  modified:
    - lib/rendro/recipes/statement.ex

key-decisions:
  - "D-04 extraction is purely mechanical: no logic changes, no behavior changes, same function bodies — only defp->def and module qualification"
  - "Statement's conservative capacity formula (capacity - header_h - 2 * typical_row_h - @row_epsilon) preserved VERBATIM in the call site in statement.ex"
  - "Pagination module stays @moduledoc false (private) — no public API surface added this phase per D-04/D-07"

patterns-established:
  - "Pattern: Shared recipe helper stays private (@moduledoc false) until a concrete external caller need emerges"
  - "Pattern: effective_capacity is recipe-owned (not helper-owned) to allow recipe-specific CF/BF overhead"

requirements-completed:
  - RCPT-01
  - RCPT-02
  - RCPT-03
  - CERT-01
  - CERT-02

# Metrics
duration: 3min
completed: 2026-05-29
---

# Phase 75 Plan 01: D-04 Shared Pagination Helper Extraction Summary

**Extracted chunk_rows_into_pages, formatter, label_resolver, type_name from statement.ex into private Rendro.Recipes.Pagination; added Rendro.PageSize.resolve/2 — all 51 Statement tests green (D-04 determinism gate)**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-29T20:48:23Z
- **Completed:** 2026-05-29T20:51:02Z
- **Tasks:** 2
- **Files modified:** 3 (2 created, 1 refactored)

## Accomplishments

- Created `Rendro.Recipes.Pagination` (@moduledoc false) with 4 public functions: `chunk_rows_into_pages/2`, `formatter/3`, `label_resolver/1`, `type_name/1` — extracted verbatim from `statement.ex` (defp → def only)
- Created `Rendro.PageSize` (@moduledoc false) with `resolve/2` covering `:a4/:portrait`, `:a4/:landscape`, `:us_letter/:portrait`, `:us_letter/:landscape`, and raw `{w, h}` passthrough; A4 constants match `PageTemplate` defaults exactly
- Refactored `statement.ex` onto the shared module: deleted 6 private function definitions (116 lines removed), replaced all call sites with qualified `Rendro.Recipes.Pagination.*` calls
- D-04 determinism gate: `mix test test/rendro/recipes/statement_test.exs` → 51 tests, 0 failures

## Task Commits

1. **Task 1: Create Rendro.Recipes.Pagination and Rendro.PageSize** - `ce36ff4` (feat)
2. **Task 2: Refactor statement.ex onto Rendro.Recipes.Pagination + regression gate** - `e9c909c` (refactor)

**Plan metadata:** (see final_commit below)

## Files Created/Modified

- `lib/rendro/recipes/pagination.ex` — NEW: private shared chunking helper with opaque-meta row chunker and formatting helpers
- `lib/rendro/page_size.ex` — NEW: named page-size resolution (:a4, :us_letter) with landscape swap
- `lib/rendro/recipes/statement.ex` — REFACTORED: removed 6 private functions, replaced call sites with qualified Pagination module calls; capacity formula preserved verbatim

## Decisions Made

- Statement's conservative `effective_capacity` formula (`capacity - header_h - 2 * typical_row_h - @row_epsilon`) is inlined at the call site in `body_section/2` rather than inside the shared helper — preserves Statement determinism exactly per RESEARCH.md pitfall 5
- `do_chunk/5` and `finalize_page/1` remain private (`defp`) inside `pagination.ex` — only the 4 callable functions are public
- `Rendro.PageSize` placed in `lib/rendro/page_size.ex` (peer to `page_template.ex`) not in the recipes subdirectory, since it is useful beyond recipes

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `Rendro.Recipes.Pagination` and `Rendro.PageSize` are ready for Plan 02 (Receipt recipe) and Plan 03 (Certificate recipe)
- Receipt can call `Pagination.chunk_rows_into_pages/2` with its simpler `effective_capacity = capacity - header_h - @row_epsilon` (no CF/BF overhead)
- Certificate can call `PageSize.resolve/2` for multi-size geometry derivation (CERT-02)
- Statement tests remain green — no regression from the mechanical refactor

## Self-Check: PASSED

- `lib/rendro/recipes/pagination.ex` — FOUND
- `lib/rendro/page_size.ex` — FOUND
- `lib/rendro/recipes/statement.ex` — modified and verified
- Task commits: `ce36ff4`, `e9c909c` — both exist in git log
- `mix test test/rendro/recipes/statement_test.exs` — 51 tests, 0 failures

---
*Phase: 75-receipt-report-and-certificate-recipes-support-contract*
*Completed: 2026-05-29*

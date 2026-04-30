---
phase: 22-authoring-ergonomics-and-canonical-recipes
plan: 02
subsystem: recipes
tags: [elixir, recipe, invoice, tiered-composition, sections, page-template, refactor]

# Dependency graph
requires:
  - "Rendro.Document pipeline builder API (22-01)"
provides:
  - "Rendro.Recipes.Invoice.document/2 — fully assembled Document via builder API"
  - "Rendro.Recipes.Invoice.page_template/1 — %Rendro.PageTemplate{name: :invoice} with :header/:body/:footer regions"
  - "Rendro.Recipes.Invoice.sections/2 — list of three %Rendro.Section{} targeting named regions"
  - "Rendro.Recipes.invoice/1 delegates to Rendro.Recipes.Invoice.document/1"
  - "Rendro.Adapters.Accrue.recipe/1 uses explicit sections and page template (no legacy kwargs)"
affects:
  - 22-03

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tiered Composition recipe pattern: document/2 (batteries-included), page_template/1 (layout), sections/2 (content)"
    - "Pipeline builder used in recipes: new |> add_template |> set_template |> add_section..."
    - "All content routed through named regions via %Rendro.Section{region: :header/:body/:footer}"

key-files:
  created:
    - lib/rendro/recipes/invoice.ex
    - test/rendro/recipes/invoice_test.exs
  modified:
    - lib/rendro/recipes.ex
    - lib/rendro/adapters/accrue.ex
    - test/rendro/adapters/accrue_test.exs

key-decisions:
  - "Invoice recipe exposes three tier levels (document/page_template/sections) for zero-to-one and advanced escape-hatch use"
  - "Accrue adapter builds %Rendro.PageTemplate{name: :accrue_invoice} via Rendro.page_template/1 (defaults supply :header/:body/:footer regions)"
  - "All content assigned through Rendro.section/1 with explicit region: field; doc.header and doc.footer remain empty"
  - "Rendro.Recipes.invoice/1 now delegates to Rendro.Recipes.Invoice.document/1 for backward compatibility"

requirements-completed:
  - LAY-12

# Metrics
duration: ~2 min
completed: 2026-04-30
---

# Phase 22 Plan 02: Tiered Composition Invoice Recipe and Accrue Adapter Refactor Summary

**Canonical invoice recipe with Tiered Composition pattern plus Accrue adapter refactored to explicit page template sections, eliminating all legacy header:/footer: kwargs**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-04-30T15:44:57Z
- **Completed:** 2026-04-30T15:47:12Z
- **Tasks:** 2 (both TDD: RED + GREEN per task)
- **Files modified:** 5

## Accomplishments

- Created `Rendro.Recipes.Invoice` with full Tiered Composition API (`document/2`, `page_template/1`, `sections/2`), enabling both zero-to-one usage and advanced escape hatches
- `Rendro.Recipes.invoice/1` now delegates to `Rendro.Recipes.Invoice.document/1`, maintaining backward compatibility while adopting explicit sections
- Refactored `Rendro.Adapters.Accrue.recipe/1` to define a `%Rendro.PageTemplate{}` and assign all content through three `%Rendro.Section{}` structs; legacy `header:` and `footer:` kwargs are fully eliminated
- 14 new invoice recipe tests + 9 updated Accrue adapter tests; full suite went from 298 to 316 tests, 0 failures

## Task Commits

1. **Task 1: Create Tiered Composition Invoice Recipe (RED)** - `b486e46` (test)
2. **Task 1: Create Tiered Composition Invoice Recipe (GREEN)** - `9118c92` (feat)
3. **Task 2: Refactor Accrue Adapter Recipe to use Sections (RED)** - `6a2b9f7` (test)
4. **Task 2: Refactor Accrue Adapter Recipe to use Sections (GREEN)** - `f1c9bba` (feat)

## Files Created/Modified

- `lib/rendro/recipes/invoice.ex` (created) — Tiered Composition recipe module with `page_template/1`, `sections/2`, `document/2`; uses builder API internally
- `test/rendro/recipes/invoice_test.exs` (created) — 14 AST-based tests covering all three API tiers plus legacy field absence
- `lib/rendro/recipes.ex` (modified) — `invoice/1` now delegates to `Rendro.Recipes.Invoice.document/1`
- `lib/rendro/adapters/accrue.ex` (modified) — Replaced `Rendro.flow/2` with builder pipeline; all content in three explicit sections
- `test/rendro/adapters/accrue_test.exs` (modified) — Updated to assert explicit sections structure, absent legacy fields, source-level no-kwargs check

## Decisions Made

- The Tiered Composition pattern is implemented exactly as specified: `document/2` (complete), `page_template/1` (layout only), `sections/2` (content only)
- Accrue template uses `Rendro.page_template(name: :accrue_invoice)` which inherits the default three regions from `%Rendro.PageTemplate{}` defaults
- `doc.header` and `doc.footer` remain `[]` in all new recipes; the source-level test guards against regression

## Deviations from Plan

None - plan executed exactly as written.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Recipe modules ingest data maps and produce document ASTs deterministically. Disposition: accept (T-22-02 per plan threat register).

## Known Stubs

None. All three regions receive real content from invoice data.

## Self-Check: PASSED

- `lib/rendro/recipes/invoice.ex` — FOUND
- `test/rendro/recipes/invoice_test.exs` — FOUND
- `lib/rendro/recipes.ex` — FOUND (updated)
- `lib/rendro/adapters/accrue.ex` — FOUND (updated)
- `test/rendro/adapters/accrue_test.exs` — FOUND (updated)
- RED commit `b486e46` — FOUND
- GREEN commit `9118c92` — FOUND
- RED commit `6a2b9f7` — FOUND
- GREEN commit `f1c9bba` — FOUND
- `mix test test/rendro/recipes/invoice_test.exs test/rendro/adapters/accrue_test.exs` — 23 tests, 0 failures
- `mix test` — 316 tests, 0 failures
- `lib/rendro/adapters/accrue.ex` contains no `Rendro.flow/2` calls with `header:` or `footer:` kwargs — CONFIRMED

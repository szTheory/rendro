---
phase: 115-invoice-anatomy-upgrade-format-public-promotion-palette-alig
plan: 01
subsystem: testing
tags: [sha256, byte-identity, golden-test, invoice, table, determinism]

requires: []
provides:
  - "Committed sha256 golden of the pre-Phase-115 toy Invoice render (INV-01 baseline)"
  - "Committed sha256 golden of a pre-cell_align table render (INV-05 baseline)"
affects: [115-03, 115-04]

tech-stack:
  added: []
  patterns:
    - "Golden-hash regression test: two-render determinism assertion + fresh-render sha256-equals-frozen-constant assertion, mirroring the existing branded_invoice_test.exs two-render pattern"

key-files:
  created:
    - test/rendro/recipes/invoice_byte_identity_test.exs
    - test/rendro/table_byte_identity_test.exs
  modified: []

key-decisions:
  - "Toy fixture uses 2 items with integer qty and bare-number (float) price, matching invoice.ex's frozen `\"$#{item.price}\"` string-interpolation path exactly, so the golden captures the real byte-for-byte toy-call output."
  - "Table golden built via Rendro.flow/1 (not the Invoice recipe) with a mix of {:share, 1} and {:fixed, N} columns and 3 rows, header included, NO cell_align key set anywhere — proving the default-alignment path baseline that Plan 03 must not perturb."

requirements-completed: [INV-01, INV-05]

coverage:
  - id: D1
    description: "sha256 golden of the pre-upgrade toy Invoice render is committed and a fresh render is asserted equal to it"
    requirement: "INV-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/invoice_byte_identity_test.exs#INV-01 baseline: toy-call byte identity fresh render sha256 matches the frozen pre-Phase-115 golden"
        status: pass
    human_judgment: false
  - id: D2
    description: "sha256 golden of a no-cell_align table render is committed and a fresh render is asserted equal to it"
    requirement: "INV-05"
    verification:
      - kind: unit
        ref: "test/rendro/table_byte_identity_test.exs#INV-05 baseline: no-cell_align table byte identity fresh render sha256 matches the frozen pre-cell_align golden"
        status: pass
    human_judgment: false

duration: ~3min
completed: 2026-07-18
status: complete
---

# Phase 115 Plan 01: Byte-Identity Baseline Freeze Summary

**Froze two sha256 goldens — pre-upgrade toy Invoice render and pre-`cell_align` table render — on pristine code, resolving RESEARCH OQ1 before any `lib/` edit lands in this phase.**

## Performance

- **Duration:** ~3 min
- **Completed:** 2026-07-18T18:06:34Z
- **Tasks:** 2 completed
- **Files modified:** 2 (both new test files; zero `lib/` edits)

## Accomplishments
- Captured `@toy_golden_sha256` (`c3625eb5...`) from a live render of `Rendro.Recipes.Invoice.document/1` on the pristine (pre-Phase-115) `invoice.ex`, using a fixed toy data map with ONLY `:id`, `:date`, `:items` keys — exercising the frozen toy-call path exactly.
- Captured `@table_golden_sha256` (`aad74904...`) from a live render of a representative multi-column, multi-row `Rendro.table/2` (mix of `{:share, 1}`/`{:fixed, N}` columns, header, 3 rows) with no `cell_align` option set anywhere — the regression guard Plan 03's additive `cell_align: :right` primitive must not perturb.
- Both test files assert two-render determinism (`pdf1 == pdf2`) plus a fresh-render sha256-equals-frozen-constant check, mirroring the existing `branded_invoice_test.exs` pattern.
- Confirmed zero `lib/` diff — this plan only records references, as required by the plan's success criteria.

## Task Commits

Each task was committed atomically:

1. **Task 1: Freeze toy-call render sha256 golden (INV-01 baseline)** - `603f1db` (test)
2. **Task 2: Freeze existing no-cell_align table render sha256 golden (INV-05 baseline)** - `34f4705` (test)

_Note: no feat/refactor commits needed — both tasks were pure golden-capture test additions._

## Files Created/Modified
- `test/rendro/recipes/invoice_byte_identity_test.exs` - INV-01 baseline: `@toy_golden_sha256` + two-render determinism + sha256-equality assertions against the pristine toy `Invoice.document/1` render.
- `test/rendro/table_byte_identity_test.exs` - INV-05 baseline: `@table_golden_sha256` + two-render determinism + sha256-equality assertions against a no-`cell_align` `Rendro.table/2` render wrapped in `Rendro.flow/1`.

## Decisions Made
- Used `Rendro.flow/1` (not the Invoice recipe) to build the minimal document/section wrapper for the table golden — it is the established lightweight pattern already used by `table_borders_test.exs` for exercising `Rendro.table/2` through the full render pipeline without recipe-specific coupling.
- Golden hashes were computed by actually running the render on pristine code via `mix run` (not hand-typed), then embedded as `@toy_golden_sha256` / `@table_golden_sha256` module attributes — eliminating any risk of a mistyped/stale golden silently freezing wrong bytes (per the plan's threat model T-115-01-01).

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
Both frozen goldens are committed and green, unblocking Plan 03 (additive `cell_align: :right`) and Plan 04 (Invoice anatomy upgrade) to be byte-checked against these frozen pre-upgrade references. No blockers.

---
*Phase: 115-invoice-anatomy-upgrade-format-public-promotion-palette-alig*
*Completed: 2026-07-18*

## Self-Check: PASSED

- FOUND: test/rendro/recipes/invoice_byte_identity_test.exs
- FOUND: test/rendro/table_byte_identity_test.exs
- FOUND: 603f1db
- FOUND: 34f4705

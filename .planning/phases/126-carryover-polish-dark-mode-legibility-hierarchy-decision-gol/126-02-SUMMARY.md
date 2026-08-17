---
phase: 126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol
plan: 02
subsystem: testing
tags: [elixir, exunit, deterministic-pdf, themes, typography, sha256]
requires:
  - phase: 126-01
    provides: themed recipe repairs and preserved nil-theme compatibility paths
provides:
  - bounded three-row from_brand/preset accent SHA-256 golden
  - semantic typography contracts for all seven recipes
affects: [126-03, 126-05, preset catalog quality ratchet]
tech-stack:
  added: []
  patterns: [bounded deterministic byte golden, semantic Text-node typography assertions]
key-files:
  created:
    - test/rendro/theme/preset_accent_golden_test.exs
    - test/rendro/recipes/branded_invoice_typography_test.exs
    - test/rendro/recipes/payslip_typography_test.exs
    - test/rendro/recipes/receipt_typography_test.exs
  modified:
    - test/rendro/recipes/invoice_typography_test.exs
    - test/rendro/recipes/statement_typography_test.exs
    - test/rendro/recipes/certificate_typography_test.exs
    - test/rendro/recipes/ticket_typography_test.exs
key-decisions:
  - "Hash only the ordered three-row accent slice; retain the twelve-row preset matrix as a separate lane."
  - "Assert recipe typography by semantic emitted Text content, not traversal ordering."
  - "Treat Payslip's payslip_sans fallback as its recipe-specific font contract."
patterns-established:
  - "Typography contracts assert scale, role font, leading, and a complete winning override."
requirements-completed: [POLISH-04, POLISH-05]
coverage:
  - id: D1
    description: Bounded deterministic accent golden across from_brand and preset constructors.
    requirement: POLISH-04
    verification:
      - kind: unit
        ref: mix test test/rendro/theme/preset_accent_golden_test.exs --max-failures 1 (run twice)
        status: pass
    human_judgment: false
  - id: D2
    description: Semantic typography contracts for all seven recipes.
    requirement: POLISH-05
    verification:
      - kind: unit
        ref: mix test test/rendro/recipes/*_typography_test.exs --max-failures 1
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-08-17
status: complete
---

# Phase 126 Plan 02: Accent Golden and Typography Contracts Summary

**A bounded three-row accent SHA-256 golden and explicit semantic typography contracts now cover all seven recipes.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-08-17T04:45:17Z
- **Completed:** 2026-08-17T04:54:15Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added ordered `from_brand`, Swiss, and Minimal-Mono accent variants with two-run byte equality, actual SHA-256 values, and explicit curated-font omission checks.
- Added dedicated BrandedInvoice, Payslip, and Receipt contracts for materialized scale, role font, leading, override precedence, and registration/fallback behavior.
- Deepened Invoice, Statement, Certificate, and Ticket contracts while retaining their specialized typed-error, centering, and historical hierarchy assertions.

## Task Commits

1. **Task 1: Trace one realistic fixture through from_brand and preset accent goldens** - `a23fe22` (test)
2. **Task 2: Add dedicated BrandedInvoice, Payslip, and Receipt typography contracts** - `a5c94c2` (test)
3. **Task 3: Deepen the four existing typography modules to the same contract** - `8488e5b` (test)

## Files Created/Modified

- `test/rendro/theme/preset_accent_golden_test.exs` - exact bounded accent hash lane.
- `test/rendro/recipes/branded_invoice_typography_test.exs` - BrandedInvoice contract.
- `test/rendro/recipes/payslip_typography_test.exs` - Payslip fallback-aware contract.
- `test/rendro/recipes/receipt_typography_test.exs` - Receipt contract.
- `test/rendro/recipes/{invoice,statement,certificate,ticket}_typography_test.exs` - deepened semantic contracts.

## Decisions Made

- Kept the new golden to exactly three ordered variants rather than duplicating the twelve-row preset matrix.
- Selected emitted text by semantic content; no new global equal-node ordering contract is inferred.
- Preserved Payslip's `:payslip_sans` fallback as the correct recipe-specific themed font bridge.

## Verification

- `mix format --check-formatted` passed for all eight changed test modules.
- `mix test test/rendro/theme/preset_accent_golden_test.exs --max-failures 1` passed twice consecutively.
- `mix test test/rendro/recipes/*_typography_test.exs --max-failures 1` passed with 34 tests.
- `mix test test/rendro/theme/preset_render_matrix_test.exs --max-failures 1` passed with 2 tests.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 03 can rely on bounded deterministic accent evidence and complete recipe typography coverage while keeping its PDFium advisory workflow separate.

## Self-Check: PASSED

- All eight planned test files exist.
- Task commits `a23fe22`, `a5c94c2`, and `8488e5b` exist in git history.

---
*Phase: 126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol*
*Completed: 2026-08-17*

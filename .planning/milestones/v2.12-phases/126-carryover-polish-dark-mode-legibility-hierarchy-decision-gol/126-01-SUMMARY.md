---
phase: 126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol
plan: 01
subsystem: recipes
tags: [elixir, theming, invoice, ticket, payslip, deterministic-pdf]
requires:
  - phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures
    provides: curated theme presets and font registration bridge
provides:
  - Themed Invoice table cells with semantic ink and literal nil-theme compatibility
  - Monotonic themed Ticket placement/title/reference hierarchy
  - Measured themed Payslip money-column boundaries
affects: [phase-126-plan-02, catalog-evidence, preset-render-matrix]
tech-stack:
  added: []
  patterns: [private themed-only compatibility seams, metric-only curated font registration]
key-files:
  created: [lib/rendro/recipes/table_cell.ex, test/rendro/recipes/table_cell_test.exs]
  modified: [lib/rendro/recipes/invoice.ex, lib/rendro/recipes/ticket.ex, lib/rendro/recipes/payslip.ex, test/rendro/recipes/invoice_test.exs, test/rendro/recipes/ticket_test.exs, test/rendro/recipes/payslip_test.exs]
key-decisions:
  - "Keep nil-theme table strings and Payslip widths literal; apply visual repairs only when a theme is supplied."
  - "Use display/title/caption for themed Ticket placement/title/reference while retaining historical nil-theme roles."
  - "Use 61pt Current and 68pt YTD themed Payslip widths, proven by Humanist one-point controls."
patterns-established:
  - "Measure themed recipe cells with a document-owned metric context without widening the render-time font boundary."
requirements-completed: [POLISH-01, POLISH-02, POLISH-03]
metrics:
  duration: 29m
  completed_date: 2026-08-17
  tasks_completed: 3
  files_changed: 8
status: complete
---

# Phase 126 Plan 01: Recipe legibility repairs Summary

Themed Invoice tables now use semantic ink, Ticket restores placement-first hierarchy, and Payslip money cells stay atomic across all curated themes without changing nil-theme PDF bytes.

## Tasks Completed

1. **Semantic Invoice table cells** — Added private `Rendro.Recipes.TableCell.content/5`; themed headers and rows use resolved `:ink`, while nil themes return the original strings exactly.
2. **Ticket hierarchy** — Added a private role selector that maps supplied themes to placement `display`, title `title`, and reference `caption`; the legacy nil-theme roles remain untouched.
3. **Payslip money boundary** — Kept historical nil-theme widths and uses themed-only 61pt Current / 68pt YTD widths, with isolated production-cell measurements across all six presets.

## Verification

- `mix test test/rendro/recipes/invoice*_test.exs test/rendro/recipes/ticket*_test.exs test/rendro/recipes/payslip*_test.exs test/rendro/theme/preset_render_matrix_test.exs` — 152 tests, 0 failures.
- Task-level formatter and focused regression suites passed for Invoice, Ticket, and Payslip.
- Legacy Invoice, Ticket, and Payslip byte-identity tests passed.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Restored themed Invoice measurement font context**
   - **Found during:** Task 2 verification
   - **Issue:** Explicit themed Invoice cells caused the preset matrix to fail before its intentional render-time missing-font assertion.
   - **Fix:** Register curated fonts only in the ephemeral measurement document and measure unknown caller font roles with default metrics, preserving the final render-time typed omission failure.
   - **Commit:** `9994e7d`, `aa6763c`

2. **[Rule 1 - Bug] Preserved Payslip nil-theme byte identity**
   - **Found during:** Task 3 verification
   - **Issue:** A global column-width adjustment changed frozen no-theme bytes.
   - **Fix:** Retained historical nil-theme widths and selected measured widths only in the supplied-theme branch.
   - **Commit:** `5c1925d`

## Known Stubs

None.

## Self-Check: PASSED

- Required production files and focused regression tests exist.
- Task commits `23918bb`, `c2fca0b`, `9994e7d`, `fb6cfc2`, `e2f8dfd`, `d9b4b32`, `5c1925d`, and `aa6763c` exist in git history.

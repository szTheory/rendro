---
phase: 126
fixed_at: 2026-08-17T06:25:29Z
review_path: /Users/jon/projects/rendro/.planning/phases/126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol/126-REVIEW.md
iteration: 2
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 126: Code Review Fix Report

**Fixed at:** 2026-08-17T06:25:29Z
**Source review:** /Users/jon/projects/rendro/.planning/phases/126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol/126-REVIEW.md
**Iteration:** 2

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-01: The new typography regression tests fail because their error regex has the terms reversed

**Files modified:** `test/rendro/recipes/invoice_typography_test.exs`
**Commit:** fe38262
**Applied fix:** Corrects all three error-message regexes to match the emitted font name before `:font_registry`.

### WR-02: Invoice rejects an unregistered `heading` font even though it never renders or measures that role

**Files modified:** `lib/rendro/recipes/invoice.ex`, `test/rendro/recipes/invoice_typography_test.exs`
**Commit:** 449cccc
**Applied fix:** Limits measurement registration and validation to Invoice's emitted `:body` and `:mono` roles, with regression coverage proving an unused unregistered heading role is accepted.

## Post-Review Authorized Golden Reconciliation

**Commit:** 1a7fee7
**Files reconciled:** `priv/goldens/invoice/odd_even_running_content.sha256`, `priv/goldens/invoice/line_items_page_boundary.sha256`, `priv/goldens/invoice/pagination_boundary.sha256`, `priv/goldens/invoice/line_items_60_plus.sha256`

The edge-matrix blessing path (`MIX_GOLDEN_BLESS=true mix test test/rendro/edge_matrix_test.exs`) changed exactly these four authorized Invoice goldens after the intentional pagination-capacity correction. The unblessed edge matrix then passed (65 tests), as did the focused Invoice suites (56 tests).

---

_Fixed: 2026-08-17T06:25:29Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_

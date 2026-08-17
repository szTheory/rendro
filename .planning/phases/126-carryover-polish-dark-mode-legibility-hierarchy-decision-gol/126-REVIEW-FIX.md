---
phase: 126
fixed_at: 2026-08-17T06:19:01Z
review_path: /Users/jon/projects/rendro/.planning/phases/126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol/126-REVIEW.md
iteration: 2
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 126: Code Review Fix Report

**Fixed at:** 2026-08-17T06:19:01Z
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

---

_Fixed: 2026-08-17T06:19:01Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_

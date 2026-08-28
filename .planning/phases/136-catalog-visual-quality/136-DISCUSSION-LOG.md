# Phase 136: Catalog Visual Quality - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-27
**Phase:** 136-catalog-visual-quality
**Areas discussed:** Dark-label contrast, Swiss Payslip table density, Brutalist Ticket placement grid, Review and promotion

---

## Dark-label Contrast

| Option | Description | Selected |
|--------|-------------|----------|
| Target-scoped internal treatment | Use semantic primary/secondary label handling only for Corporate Classic Invoice dark and Minimal Mono Statement dark. | ✓ |
| Recipe-wide semantic labels | Convert every themed Invoice/Statement label site to semantic colors. | |
| Global dark-token retune | Change `Theme.dark/1` or preset dark tokens for all dark renders. | |

**User's choice:** Accepted the researched recommendation set as a whole.
**Notes:** Preserve Total Due and Closing Balance as the unique focal anchors. Use contrast as a screen-readability diagnostic without adding WCAG, PDF/UA, accessibility, viewer, or print claims. Prove that no non-target cell changes.

---

## Swiss Payslip Table Density

| Option | Description | Selected |
|--------|-------------|----------|
| Rebalance paired ledger | Retain the seven-column earnings/deductions table and tune existing widths. | |
| Shorten catalog copy | Abbreviate realistic descriptions to avoid wrapping. | |
| Sequential full-width ledgers | Render separate `Earnings | Current | YTD` and `Deductions | Current | YTD` tables. | ✓ |

**User's choice:** Accepted the researched recommendation set as a whole.
**Notes:** Preserve descriptions verbatim, right-align and keep money atomic, use measured explicit amount widths, repeat table headers on continuation pages, keep Net Pay dominant, and retain the final gross-to-net reconciliation.

---

## Brutalist Ticket Placement Grid

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve and tune four slots | Keep Section `GA`, Row `H`, Seat `24`, Gate `B` in one ordered row and repair token fit/association. | ✓ |
| Collapse absent fields | Remove a genuinely missing field and re-share the remaining columns. | |
| Two-row locator grid | Reshape the placement block into a more spacious multi-row layout. | |

**User's choice:** Accepted the researched recommendation set as a whole.
**Notes:** The Gate value is present; the current image only makes it look associated with Seat. Do not edit the shared Aurora fixture or create a new responsive/archetype capability. Keep light/dark geometry identical.

---

## Review and Promotion

| Option | Description | Selected |
|--------|-------------|----------|
| Independent unpaired review | Review and publish each cell without family controls. | |
| Family-paired, per-cell truth | Review full-size light/dark family pairs, record each cell independently, and publish atomically after all six meet phase thresholds. | ✓ |
| All-or-nothing scoring | Treat the six targets as one shared approval/disposition. | |

**User's choice:** Accepted the researched recommendation set as a whole.
**Notes:** Use one validated exact-SHA bundle. Verify exactly six changed IDs and 26 unchanged controls. Preserve the distinction between meeting Phase 136's visual dimensions and the complete `passed` calculation: dark remains `print_safety: false` and must not be falsely promoted.

---

## the agent's Discretion

- Exact internal presentation-profile names and data shapes.
- Exact column widths, theme-role sizes, secondary dark tones, focused test filenames, and commit boundaries within the locked visual and compatibility behavior.
- Implementation details that keep catalog IDs in dev-only tooling and recipes generic/data-first.

## Deferred Ideas

- None. Global theme redesign, recipe-wide visual cleanup, public layout APIs, responsive ticket archetypes, and broader catalog review were explicitly kept outside Phase 136.

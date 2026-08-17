# Phase 126: Carryover polish — dark-mode legibility, hierarchy decision & golden/typography depth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-16
**Phase:** 126-carryover-polish-dark-mode-legibility-hierarchy-decision-golden-typography-depth
**Mode:** `--auto`
**Areas discussed:** Dark table color semantics, Ticket hierarchy disposition, Payslip numeric integrity, Golden and typography depth, Evidence closure and review ergonomics

---

## Dark table color semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Shared semantic cell styling | Carry theme ink through a reusable themed cell path while preserving legacy String cells. | ✓ |
| Lighten dark surfaces | Avoid the black-text collision by making dark table surfaces light. | |
| Invoice-only palette patch | Special-case Invoice colors without fixing the reusable boundary. | |

**Auto-selected choice:** Shared semantic cell styling (recommended).
**Notes:** The concrete failure is Invoice's bare String rows, but the requirement is a shared semantic solution. Unthemed bytes remain frozen.

---

## Ticket hierarchy disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Fix semantic hierarchy | Placement dominates, title is secondary, reference stays compact; preserve no-theme bytes. | ✓ |
| Record an exemption | Accept the inversion and encode it as an explicit quality carve-out. | |
| Flatten all ticket sizes | Reduce contrast across every ticket element. | |

**Auto-selected choice:** Fix semantic hierarchy (recommended).
**Notes:** The roadmap permits an exemption, but the established reader job and known three-line reference failure make a real fix the stronger default.

---

## Payslip numeric integrity

| Option | Description | Selected |
|--------|-------------|----------|
| Protect numeric tokens locally | Retune/fix amount cells while preserving the overall type scale and alignment. | ✓ |
| Shrink all body typography | Reduce every Payslip cell to make amounts fit. | |
| Allow taller wrapped rows | Keep mid-number wrapping and absorb it into layout height. | |

**Auto-selected choice:** Protect numeric tokens locally (recommended).
**Notes:** Description cells may wrap; formatted money should remain visually atomic under all curated presets.

---

## Golden and typography depth

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded representative matrix | One stable fixture, multiple accent derivations, repeated bytes, plus dedicated tests for all recipes. | ✓ |
| Full Cartesian golden matrix | Every preset, accent, mode, and recipe becomes a new byte golden. | |
| Smoke tests only | Keep successful rendering as the only cross-recipe assertion. | |

**Auto-selected choice:** Bounded representative matrix (recommended).
**Notes:** Existing Phase 125 matrices already cover the broad combinatorics; this phase adds missing proof depth without duplicating them.

---

## Evidence closure and review ergonomics

| Option | Description | Selected |
|--------|-------------|----------|
| Focused tests plus bounded raster review | Prove each defect, update honest records, and inspect readable full-size affected images. | ✓ |
| Unit tests only | Close visual findings from structural assertions alone. | |
| Rebuild the entire catalog early | Generate Phase 127 artifacts before the polish phase is complete. | |

**Auto-selected choice:** Focused tests plus bounded raster review (recommended).
**Notes:** The user approved Phase 125's contact sheet but asked that future review be a slideshow rather than “pictures for ants.”

## the agent's Discretion

- Private helper names and exact test partitioning.
- The narrowest existing/private seam for table ink and amount fitting.
- The representative recipe, accents, and affected raster row subset used for proof.

## Deferred Ideas

- A reusable shipped slideshow/lightbox belongs to later review tooling or Phase 128 if it naturally fits catalog browsing; Phase 126 only requires readable sequential review presentation.

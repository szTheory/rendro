# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## launch-source-pdf-identity — publication plan checked an unpaired manifest
- **Date:** 2026-08-20
- **Error patterns:** source-PDF hash drift, static launch contract, canonical manifest, staged artifact
- **Root cause(s):** Plan 130-06 ran source-PDF validation against the canonical prior manifest before it overlaid the accepted staged launch family.
- **Fix:** Validate staging identity first; overlay only the explicit staged launch/golden family; then run existing launch/contracts checks on the paired uncommitted batch before its sole publication commit.
- **Files changed:** .planning/phases/130-catalog-quality-evidence-ratchet/130-06-PLAN.md
- **Why not caught:** no gate existed for publication-plan ordering against an intentionally unpaired canonical manifest.
- **Recurrence guard:** explicit Plan 130-06 sequencing clause plus its executor post-copy launch/contracts gate.
---

---
created: 2026-08-28T17:09:30.956Z
title: Unify catalog recipe visual design system
area: ui
severity: cosmetic
files:
  - brand/tokens/tokens.json
  - lib/rendro/recipes/palette.ex
  - lib/rendro/recipes/invoice.ex:603
  - lib/rendro/recipes/statement.ex
  - lib/rendro/recipes/payslip.ex
  - lib/rendro/recipes/ticket.ex
  - .planning/phases/136-catalog-visual-quality/136-UI-SPEC.md:54
---

## Problem

The Phase 136 exact-six gallery is functionally reasonable, but the rendered recipes do not yet feel like a consistently authored graphic-design system. The review is an advisory pass with non-blocking visual debt, not an aesthetic endorsement.

Specific feedback:

- `invoice--cedar-mutual--corporate-classic--dark` renders `Total Due` as a large blue monospaced focal element that feels disconnected from the rest of the invoice.
- The warm-neutral dark surfaces read as muddy or brown rather than as an intentional dark palette.
- Spacing, padding, typography, and grouping sometimes look accidental rather than token-driven; several elements need more natural breathing room.
- Recipe families do not consistently communicate one deliberate rhythm for spacing, type scale, color roles, padding, and hierarchy.

The current Phase 136 contract deliberately preserved the blue `Total Due` anchor and warm-neutral dark surface. A future cleanup should explicitly revisit those decisions rather than treating their current presence as proof that they are visually successful.

## Solution

Plan a bounded catalog-wide visual-system cleanup. Audit the rendered families together, then define and apply a small semantic token palette for spacing/rhythm, typography scale and leading, surface/ink/accent roles, and component padding. Start with the Cedar Mutual Corporate Classic dark invoice and validate the revised `Total Due` treatment and dark surface before propagating reusable roles.

Shift repeatable constraints into deterministic tests and CI where truthful: require approved semantic roles/tokens, reject ad hoc spacing/color/type literals in target paths, preserve deterministic pagination and byte-stable out-of-scope controls, and continue producing the hash-bound gallery for advisory inspection. Subjective craft and taste must remain advisory or explicitly deferred; automation must not manufacture visual approval.

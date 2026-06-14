# Phase 102 — Design Tokens · SUMMARY

**Status:** Complete · 2026-06-14

## Delivered
- `brand/tokens/tokens.json` — single source of truth: raw palette (primitives), semantic roles (light + dark), type scale, spacing, radius, border, shadow, motion, state, grid, and a computed `$contrast` block.
- `brand/tokens/tokens.css` — GENERATED. `:root` custom properties (raw + light semantic), `@media (prefers-color-scheme: dark)` + `[data-theme="dark"]` overrides, `prefers-reduced-motion` block.
- `brand/tokens/tailwind.tokens.js` — GENERATED `theme.extend` excerpt (raw hex colors + semantic colors as CSS vars + fontFamily/fontSize/spacing/borderRadius).
- `lib/mix/tasks/brand.gen.ex` — dev-only, zero-dependency generator (Elixir 1.19 built-in `JSON`). `mix brand.gen` regenerates; `mix brand.gen --check` is the determinism gate.

## Disposition rulings honored (from 101)
- KEEP ink/paper/blue primitives + names. ADD semantic roles, interaction states, and a **warm-neutral dark** mode (`night-*` scale) — closes C3, I1.
- TIGHTEN contrast: replaced asserted verdicts with **computed WCAG 2.2 ratios** (`$contrast`). Confirmed `blue-600` on paper = 4.28 (large text only), `amber-600` on white = 3.07 (never body) — both documented as constraints. Closes I2.
- ADD focus-ring token + reduced-motion handling. Closes the focus-state gap.
- `plum-700` demoted to non-core (not referenced by any semantic role). Closes N5.

## Verification (TOK-01..04)
- [x] TOK-01 Every semantic role resolves to a raw value in light AND dark (generator raises on unknown alias).
- [x] TOK-02 Closed token set — type/spacing/radius/border/state all present, no orphan refs.
- [x] TOK-03 `mix brand.gen` emits both outputs; `--check` passes → CSS/JSON 1:1 and deterministic.
- [x] TOK-04 WCAG AA contrast computed + documented for all key pairings.

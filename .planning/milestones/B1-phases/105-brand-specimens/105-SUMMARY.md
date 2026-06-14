# Phase 105 — Visual Specimens · SUMMARY

**Status:** Complete · 2026-06-14

## Delivered (`brand/specimens/`, all SVG, render-verified)
- `palette.svg` — raw palette swatches (named + hex) + semantic roles card + contrast notes.
- `typography.svg` — the full type scale with live samples.
- `components.svg` — buttons (primary/secondary/quiet), card, badges, four callouts.
- `code-block.svg` — dark Elixir code panel (JetBrains Mono, syntax-colored).
- `readme-header.svg` — README hero mock (locked logo + tagline + badges + page motif).
- `social-card.svg` — 1200×630 OG/social card (logo + tagline + supporting line + grid motif).

Logo geometry in the header/social specimens is copied verbatim from the locked `rendro-primary.svg`
(page-frame R, seam, fold), recolored with explicit hex. Every value comes from the tokens.

## Verification (SPEC-01..05)
- [x] SPEC-01 palette (raw + semantic). [x] SPEC-02 typography scale.
- [x] SPEC-03 components + callout states. [x] SPEC-04 code block.
- [x] SPEC-05 README header + 1200×630 social card.
- All `xmllint`-valid and rendered via `qlmanage`.

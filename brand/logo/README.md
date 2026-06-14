# Rendro logo system

The Rendro mark is a **page-frame R**: the bowl is a page with a folded corner, the stem
carries a single structural seam, and the leg kicks past the baseline — content becoming a
finished document. The wordmark sets "endro" as a geometric stencil in the same construction
language, so the R is unmistakably the hero. Concept lineage and rejected directions live in
[`options/`](options/) and [`lab/`](lab/).

## Files

| File | Use |
|------|-----|
| `rendro-primary.svg` | **Default.** Full lockup, no tagline. Use almost everywhere. |
| `rendro-mark.svg` | The R alone — app icon, inline glyph, tight spaces. |
| `rendro-mono.svg` | One-color lockup (no blue accent) — single-ink print, etch, embroidery, knockout. |
| `rendro-subtitle.svg` | Lockup + "Native PDF layout for Elixir" — hero/launch surfaces only. |
| `favicon.svg` | Square-framed R for favicons / tab icons. |
| `social-avatar.svg` | Paper R on ink, rounded square — GitHub org / social avatar (square or circular crop). |

All except `social-avatar.svg` are **self-theming**: they use `currentColor` + a
`prefers-color-scheme` block, so they render ink on light and paper on dark automatically.
To force a theme, wrap in an element that sets `color`, or edit the inline `<style>`.

## Color

- Ink `#101827` (light) / Paper `#F2ECE0` (dark) — the letterforms.
- Blue `#2C6BED` (light) / `#7FA9FF` (dark) — **only** the folded corner. Never recolor the whole mark.
- One-color contexts: use `rendro-mono.svg` (the fold becomes ink too).

## Clear space & minimum sizes

- **Clear space:** keep the height of the lowercase "n" clear on all sides of the lockup.
- **Minimum sizes:** full lockup ≥ 96px wide (digital) / 0.75in (print); mark ≥ 24px; favicon ≥ 16px.
- Below 24px use `rendro-mark.svg` / `favicon.svg`, not the full lockup.

## Do

- Place the mark directly on the page — it has no bounding box by design.
- Use the self-theming files on both light and dark surfaces.
- Pair with Inter (UI/marketing) and JetBrains Mono (code), per `../tokens/`.

## Don't

- Don't add a box, plate, gradient, or shadow behind the mark (the avatar's fill is the one sanctioned exception).
- Don't recolor the letterforms or make the whole mark blue.
- Don't add a subtitle to the primary lockup — use `rendro-subtitle.svg` when a tagline is required.
- Don't stretch, condense, rotate, or re-space the letters.
- Don't rebuild "endro" in a different typeface — the stencil construction is part of the identity.

## Editing / outlining

These SVGs use live `<text>` only in `rendro-subtitle.svg` (the tagline, Inter, with a system
fallback). The mark and wordmark are geometric paths/rects — no font dependency. If you need the
tagline as pure vector (e.g. for a context without Inter), outline that one `<text>` element in a
vector editor; everything else is already path-only.

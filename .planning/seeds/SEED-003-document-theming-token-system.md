---
id: SEED-003
status: complete
completed_as: v2.11
completed: 2026-07-28
planted: 2026-07-10
planted_during: C1 (post-archive, awaiting next milestone)
trigger_when: any product/feature milestone touching document visual / branding / theming / color / typography capability — part of the Happy-Path program (recommended after SEED-002, but surface whenever theming/branding scope arises)
scope: Large (full milestone)
part_of: "Happy-Path Home Runs program (Milestone B of 4 — see SEED-002, SEED-004, SEED-005)"
---

# SEED-003: Document Theming & Design-Token System (Milestone B)

Give rendro a real, **public, deterministic PDF theming contract** so every layout is **fully themable**
(plug in brand colors + typography), gets **light/dark** for free, and ships a **strong unbranded
default**. This is the capability that lets business documents look great and on-brand out of the box.

**Milestone B of a 4-milestone program.** A (**[[SEED-002]]** realistic examples) → B (this) →
C (**[[SEED-004]]** presets + catalog + static configurator) → D (**[[SEED-005]]** optional live Studio).
Full program plan: `~/.claude/plans/btw-what-is-rendro-spicy-giraffe.md`.

## Why This Matters

**Rendro has NO document color-theming system today.** Recipe branding is **font + logo only**
(`Rendro.Recipes.BrandedInvoice` takes `brand: %{font_name, logo_name}` atoms wired to hardcoded demo
assets; plain `Invoice` has no color/theme knob). The B1 "Brand System" milestone built the *project's
own website brand* (`brand/tokens/tokens.json` — rich light/dark CSS/Tailwind tokens) but it is **excluded
from the Hex package** and never touches PDF output. So "fully themable layouts" + "light/dark PDFs" is
genuinely new `lib/` capability, and it's a public API contract that deserves its own design discovery.

The user wants every layout fully themable: colors + typography at minimum, ideally spacing/radius too —
so a user plugs in their brand tokens and gets a cohesive, "ooze-quality" branded document.

## When to Surface

**Trigger:** surface whenever a milestone touches **document visual / branding / theming / color /
typography** capability (a theme system, brandable documents, light/dark, design polish). Recommended
*after* Milestone A, but this is guidance, not a gate — surface it any time theming/branding scope arises
so it isn't skipped. B is the prerequisite for C and D.

## Scope Estimate

**Large — a full milestone.** New public `lib/` contract + recipe plumbing across all recipes.

### What maps to deterministic PDF (grounds the token contract — verified against the engine)

`lib/rendro/{color,text,path}.ex` + `lib/rendro/pdf/writer.ex`:
- **Maps cleanly:** colors (`{r,g,b}`; hex→tuple at boundary), font size + family (resolved font
  resource), line-height (emulated, faithful), border/rule width (stroke), corner radius
  (`{:rounded_rect,…,radius}`), spacing values in points.
- **Partial / new concept:** typography has NO type-scale, NO numeric weight axis, NO letter-spacing, NO
  native leading — a **type-scale is something this milestone introduces**. Spacing has no scale
  abstraction (px≠pt).
- **Does NOT map — permanently EXCLUDE from the theme contract:** shadow/elevation (no native
  shadow/gradient/vector-alpha; express elevation flatly via `surface` tint + `rule` hairline), z-index
  (draw order only), motion, focus-ring/hover/selection, opacity/gradient, grid max-widths.

### Design (locked)

- **`Rendro.Theme` struct** (`lib/rendro/theme.ex`) — a pure inert value resolved once and threaded
  through the 3 rungs. **Define the FULL shape up front** (public contract; widening later is breaking),
  **implement in tiers**:
  - `colors` — semantic **roles** `{r,g,b}`: `ink`, `muted`, `accent`, `on_accent`, `background`,
    `surface`, `rule` (+ optional `positive`/`negative`). *(fully wired)*
  - `typography` — `fonts: %{heading, body, mono}` (logical atoms) + `scale` (named pt steps:
    display/title/subtitle/body/small/caption) + `leading` + `widows`/`orphans`. *(fully wired)*
  - `mode: :light | :dark` — a variant selector, not separate art. `Rendro.Theme.dark/1` swaps
    `background`/`ink`/`surface`/`on_accent`; recipes prepend a full-page `{:rect}` background fill. Every
    recipe gets light+dark for free by reading roles, never literals. *(fully wired)*
  - `spacing`, `rules` (hairline/regular/heavy), `radius` (none/sm/md), `density`
    (:comfortable|:compact). *(honored as optional tokens with sane defaults)*
  - **EXCLUDED permanently:** shadow, z-index, motion, focus/hover, opacity/gradient.
- **Recipe plumbing** — `theme:` opt resolved at `document/2` (`Rendro.Theme.resolve/1`, default
  `Rendro.Theme.default/0`), threaded through `page_template/1` + `sections/2`; sections read
  `theme.colors.ink` etc.
- **Unbranded default** — `Rendro.Theme.default()`, a restrained neutral-ink (Swiss-ish) palette that
  looks strong on its own (NOT everything-is-blue). Must clear the Milestone-A quality rubric on its own.
- **`brand:` stays orthogonal** — assets (logo + brand font *files*) = *who*; `theme:` (tokens) = *how*.
  `Rendro.Theme.from_brand/2` + a single `accent:` seed so "plug in my palette" is one color. `Theme` is
  pure presentation, industry-agnostic — family-recipe boundary held. **Design systems = code, brands =
  data.**

## Breadcrumbs

- `lib/rendro/color.ex` — the `{r,g,b}` contract every color-role token conforms to.
- `lib/rendro/path.ex` — `{:rect}` (page/dark background + surface fills), `{:rounded_rect,…,radius}`,
  stroke width (rule tokens).
- `lib/rendro/text.ex` — `font`/`size`/`color`/`line_height`/`widows`/`orphans`, the fields typography
  tokens drive.
- `lib/rendro/recipes/branded_invoice.ex`, `lib/rendro/recipes/certificate.ex` — current brand injection
  (font+logo) + "optional/unbranded" convention; the seam `theme:` extends.
- `brand/tokens/tokens.json` — web-only light/dark token source to MINE for `{r,g,b}` values (excluded
  from Hex; convert hex→tuple).
- `priv/public_api.json`, `priv/support_matrix.json` — machine-checked manifests the new `Theme` API
  updates.
- New files: `lib/rendro/theme.ex`. Related: [[SEED-002]], [[SEED-004]].

## Notes

Planted 2026-07-10 as Milestone B of the restructured Happy-Path Home Runs program. The token-vs-excluded
discipline above is the honest answer to "ideally shadow/z-index/etc." — only what maps to deterministic
PDF goes in the contract; the rest is explicitly out.

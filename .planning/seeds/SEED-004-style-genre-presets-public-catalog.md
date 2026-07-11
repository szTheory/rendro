---
id: SEED-004
status: dormant
planted: 2026-07-10
planted_during: C1 (post-archive, awaiting next milestone)
trigger_when: after Milestone B (SEED-003) — once the Rendro.Theme token contract + light/dark exist
scope: Large (full milestone)
part_of: "Happy-Path Home Runs program (Milestone C of 3 — see SEED-002, SEED-003)"
---

# SEED-004: Style-Genre Presets & Public Example Catalog (Milestone C)

Make GREAT-looking branded documents **turnkey** — pick a design *style* + plug in your palette/logo —
and show the whole thing off as a **public by-domain example catalog** that doubles as a standing
**quality ratchet**.

**Milestone C of a 3-milestone program.** A (**[[SEED-002]]** realistic examples) → B (**[[SEED-003]]**
theming) → C (this). Depends on B's `Rendro.Theme` contract. Full program plan:
`~/.claude/plans/btw-what-is-rendro-spicy-giraffe.md`.

## Why This Matters

Raw tokens (colors/fonts/logo) let a user theme a document, but getting a *cohesive, tasteful* result
still takes design skill. **Style-genre presets** ("meta-themes" / brand lanes) bundle a coherent set of
token choices per named graphic-design style so a user picks a genre, plugs in palette + logo, and gets
an "ooze-quality" branded document with near-zero effort. And the user wants a **public catalog** of all
example documents — by domain, each in 2–3 example brands × light/dark + a strong unbranded default —
that demonstrates robustness/brandability AND acts as a visual quality-bar the user reviews to hold and
*ratchet* the design bar over time (so all layouts eventually look award-winning, including the unbranded
default).

## When to Surface

**Trigger:** after Milestone B ships — presets ARE `%Rendro.Theme{}` values, and the catalog needs the
token contract + light/dark + unbranded default to exist. The catalog's ratchet value only materializes
once B is in place.

## Scope Estimate

**Large — a full milestone.** Preset library + curated fonts + catalog generation + rubric tracking.

### Design (locked)

- **Style-genre presets** (`lib/rendro/theme/presets.ex`) — each a `%Theme{}` with everything filled
  except palette + assets (font-role pairing intent, type scale, spacing rhythm, rule weights, radius,
  density, color-role usage). Starter set (business-document-appropriate genres):
  - **Swiss / International** — neutral grotesque, tight grid, hairline rules, high contrast (also the
    `Theme.default()` basis; "the serious default").
  - **Humanist** — warmer humanist sans, larger leading, softer rules; SaaS/consumer.
  - **Editorial** — serif headings + sans body, high type-scale contrast; reports/statements/certificates.
  - **Corporate-Classic** — conservative serif, boxed/ruled totals, restrained navy/gray; finance/
    insurance/legal.
  - **Minimal-Mono** — mono-accented tracked-caps labels, tabular figures, ultra-restrained; dev-tool/
    fintech.
  - **Brutalist** *(ship if time)* — heavy rules, blocky high-contrast, `radius.none`; tickets/edgy
    brands, kept within business-doc legibility.
  - Deferred candidates: Compact-Operational (better as `density: :compact`), Refined/Boutique (Editorial
    variant).
- **Curated open-license fonts** in `priv/fonts/` (a grotesque, a humanist sans, a text serif, a mono) so
  flagship presets render out of the box. A preset referencing an unregistered font role raises the
  existing typed error — no silent substitution.
- **Ergonomics:** `theme: Rendro.Theme.preset(:editorial, accent: {12,74,110}, mode: :dark)`. Presets
  compose with the unbranded default + light/dark uniformly (dark derived from roles).
- **Public example catalog** — every domain × {2–3 example brands / presets} × {light, dark} + unbranded
  default, generated as **deterministic hash-checked artifacts** (extends `mix rendro.launch_artifacts.gen`),
  organized **by domain, brand-tagged**. Doubles as the **standing quality-bar ratchet**: track the
  Milestone-A rubric scores across the whole grid over time so every layout "oozes quality," including the
  unbranded default on its own.
- **Boundary preserved:** design systems = code (`lib/rendro/theme*`), example brands = data
  (`priv/examples/`) — a brand is never a module.

## Breadcrumbs

- `lib/rendro/theme.ex` (from [[SEED-003]]) — the struct presets are built on.
- `lib/mix/tasks/rendro/launch_artifacts/gen.ex` — gallery + hash-check generator the catalog extends.
- `assets/rendro/gallery/`, `assets/rendro/artifacts.json` — existing gallery + hash manifest to expand.
- `priv/examples/<domain>/` — fixtures + `DOMAIN.md` (from [[SEED-002]]) + example-brand palettes/logos as
  data.
- `priv/public_api.json`, `priv/support_matrix.json` — manifests the preset API updates.
- New files: `lib/rendro/theme/presets.ex`, `priv/fonts/` (curated preset fonts). Related: [[SEED-002]],
  [[SEED-003]].

## Notes

Planted 2026-07-10 as Milestone C of the restructured Happy-Path Home Runs program. Presets deferred here
(rather than into the B theming milestone) because they need curated fonts + real design labor and should
not block the token contract. "Award-winning within the bounds of function" quality bar = the
Milestone-A rubric, applied across the catalog grid as the ratchet.

---
id: SEED-004
status: dormant
planted: 2026-07-10
planted_during: C1 (post-archive, awaiting next milestone)
trigger_when: any milestone touching style presets, the public example catalog, a theme/brand configurator, or design polish — part of the Happy-Path program (needs SEED-003's theme contract; surface whenever presets/catalog/configurator scope arises)
scope: Large (full milestone)
part_of: "Happy-Path Home Runs program (Milestone C of 4 — see SEED-002, SEED-003, SEED-005)"
---

# SEED-004: Style-Genre Presets, Public Catalog & Static Configurator (Milestone C)

Make GREAT-looking branded documents **turnkey** — pick a design *style* + plug in your palette/logo —
and show the whole thing off as a **public by-domain example catalog** that doubles as a standing
**quality ratchet**.

**Milestone C of a 4-milestone program.** A (**[[SEED-002]]** realistic examples) → B (**[[SEED-003]]**
theming) → C (this) → D (**[[SEED-005]]** optional live Studio). Depends on B's `Rendro.Theme` contract.
Full program plan: `~/.claude/plans/btw-what-is-rendro-spicy-giraffe.md`.

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

**Trigger:** surface whenever a milestone touches **style presets, the public example catalog, a
theme/brand configurator, or design polish**. Presets ARE `%Rendro.Theme{}` values, so this needs
SEED-003's token contract + light/dark to exist — recommended after B, but that's guidance, not a gate;
surface it any time presets/catalog/configurator scope arises so it isn't skipped.

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
- **Static client-side configurator + code export** *(the "browse → pick → copy code" 90% path)* — over
  the pre-rendered static catalog, a **client-side** configurator: pick a preset + a sample accent from a
  small palette, see the nearest pre-rendered preview, and **one-click copy** the terminal action — a
  `Rendro.Theme.preset(:editorial, accent: {…}, mode: :dark)` snippet + recipe usage. Config state in the
  **URL query string** (shareable); **no server compute, no DB**. Plus a `mix rendro.gen.theme <preset>
  --accent "#…"` codegen task (models the existing `mix brand.gen`: opts → writes `lib/my_app/…_theme.ex`
  + a `--check` drift gate) for users who want a materialized module. Extend the existing Livebook as a
  third tinkerer surface. *(The heavier live, in-app, server-rendered theme playground is [[SEED-005]]
  Milestone D — this static path covers the common case at zero compute.)*
- **Boundary preserved:** design systems = code (`lib/rendro/theme*`), example brands = data
  (`priv/examples/`) — a brand is never a module.

## Breadcrumbs

- `lib/rendro/theme.ex` (from [[SEED-003]]) — the struct presets are built on.
- `lib/mix/tasks/rendro/launch_artifacts/gen.ex` — gallery + hash-check generator the catalog extends.
- `assets/rendro/gallery/`, `assets/rendro/artifacts.json` — existing gallery + hash manifest to expand.
- `priv/examples/<domain>/` — fixtures + `DOMAIN.md` (from [[SEED-002]]) + example-brand palettes/logos as
  data.
- `priv/public_api.json`, `priv/support_matrix.json` — manifests the preset API updates.
- `lib/mix/tasks/brand.gen.ex` — codegen template (opts → generated files + `--check` drift gate) for
  `mix rendro.gen.theme`.
- New files: `lib/rendro/theme/presets.ex`, `priv/fonts/` (curated preset fonts),
  `lib/mix/tasks/rendro/gen/theme.ex` (codegen). Related: [[SEED-002]], [[SEED-003]], [[SEED-005]].

## Notes

Planted 2026-07-10 as Milestone C of the restructured Happy-Path Home Runs program. Presets deferred here
(rather than into the B theming milestone) because they need curated fonts + real design labor and should
not block the token contract. "Award-winning within the bounds of function" quality bar = the
Milestone-A rubric, applied across the catalog grid as the ratchet.

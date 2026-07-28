# Requirements: Rendro — v2.11 Document Theming & Design-Token System

**Defined:** 2026-07-19
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Milestone:** v2.11 (Milestone B / `SEED-003`), additive minor, hex `1.2.0` intent. Phases continue from **119**.
**Research:** `.planning/research/milestone-b/SUMMARY.md` — direction GREEN, zero new deps, low technical / high discipline risk.

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase.

### Theme Contract (THEME)

- [x] **THEME-01**: A public `Rendro.Theme` struct defines the FULL token shape up front — color roles, typography, spacing, rules, radius, density, mode — including honored-with-defaults tiers, so later milestones append token *values* never *fields*.
- [x] **THEME-02**: `Rendro.Theme.resolve/1` returns an idempotent, fully-resolved theme with every color role an integer `{r,g,b}` validated via `Rendro.Color.validate/1`, raising an instructive errors-as-product error on an invalid token.
- [x] **THEME-03**: `Rendro.Theme` ships on the **adapter/Evolving** tier in `priv/public_api.json` with `@spec` on every public function and a doc note that token values and rendered output may evolve while the field shape stays stable; all derivation helpers (`on_accent`, dark-swap, hex→tuple, normalize) stay private/`@doc false`.
- [x] **THEME-04**: Web concepts that do not map to deterministic PDF (shadow/elevation, z-index, motion, focus/hover, opacity/gradient, raw color scales, numeric weight axis, letter-spacing, wide-gamut color) are excluded *by construction* — never present as `%Theme{}` fields — with the honest flat-elevation guidance (express elevation via `surface` tint + `rule` hairline).

### Color Roles & Brand (COLOR)

- [x] **COLOR-01**: Semantic color roles — `ink`, `muted`, `accent`, `on_accent`, `background`, `surface`, `rule` (+ optional `positive`/`negative`) — are `{r,g,b}` tokens that recipe sections read by role, never as inline literals.
- [x] **COLOR-02**: `Rendro.Theme.from_brand/2` produces a theme from a single `accent:` seed (+ optional brand tokens) with `on_accent` deterministically derived; it emits only tokens and never registers an asset, keeping `brand:` (who — logo/font files) orthogonal to `theme:` (how — tokens).

### Typography (TYPE)

- [x] **TYPE-01**: A named type scale (`display`/`title`/`subtitle`/`body`/`small`/`caption`) is materialized as explicit point sizes (not a runtime formula) and threaded into `%Text{}` size fields.
- [x] **TYPE-02**: Font roles (`heading`/`body`/`mono`) resolve through the existing `FontRegistry`; a theme referencing an unregistered font role raises the existing typed `{:unknown_text_font, _}` error and never silently substitutes.
- [x] **TYPE-03**: `leading` (a line-height multiplier matching `Text.line_height` semantics) plus widows/orphans are theme-driven, and `default/0`'s scale/leading is a metric no-op so existing Phase-117 stress goldens are unchanged.

### Light / Dark Mode (MODE)

- [x] **MODE-01**: A `mode: :light | :dark` selector with `Rendro.Theme.dark/1` deriving dark by swapping pre-resolved role tuples (background/ink/surface/on_accent) — no separate art and no transcendental color math at draw time.
- [x] **MODE-02**: Dark mode paints a full-page background on EVERY page (including paginate-generated overflow pages) via a page-template `:background` region; the light default emits no background rect and stays byte-identical to v2.10.
- [x] **MODE-03**: Dark is documented as a screen-oriented mode with an explicit non-print-recommended boundary and a support-matrix row — no print-safety or accessibility/PDF-UA claim; every shipped demo is light.

### Recipe Plumbing (PLUMB)

- [x] **PLUMB-01**: The 4 un-seamed recipes (Statement, Certificate, Receipt, BrandedInvoice) are retrofitted with a byte-identical `palette/1` seam (defaults = today's exact literals), proven by fresh sha256 goldens in commits *separate* from any theme wiring.
- [x] **PLUMB-02**: All 7 recipes thread a resolved `theme:` through the 3-rung pattern (`document/2` → `page_template/1` → `sections/2`), reading `theme.colors.*` / `theme.typography.*`, with each recipe's opts whitelist admitting `:theme`.
- [x] **PLUMB-03**: `document(data)` with no `theme:` opt is a byte-identity no-op for all 7 recipes — reproduces v2.10 bytes (the milestone's central regression guard).

### Unbranded Default & Rubric Closure (DEFAULT)

- [ ] **DEFAULT-01**: `Rendro.Theme.default/0` is a restrained neutral-ink (Swiss-ish) unbranded default (`{r,g,b}` mined from `brand/tokens/tokens.json`) that looks strong on its own.
- [ ] **DEFAULT-02**: The Phase-118 SHOW-01 rubric gap is closed *honestly* — the demo DATA is fixed first (`Rendro.ExamplesData.transform_invoice` parties/totals restored; the one key fact made structurally dominant), THEN `default/0` applied, THEN re-scored against the Milestone-A reader-quality rubric (hierarchy = 5, core ≥ 4, gates pass) with human sign-off; a `passed:true` score is committed only on an honest clear.
- [ ] **DEFAULT-03**: Themed and dark gallery renders populate the existing S6 `theme`/`mode` tags on `assets/rendro/artifacts.json` (hash-checked), each `(recipe × mode)` a distinct blessed gallery row (`preset` stays `null` for Milestone C).

### Contract, Docs & Boundary (CONTRACT)

- [x] **CONTRACT-01**: `priv/public_api.json` is regenerated via `mix rendro.api.gen` with the `Theme` entry and `public_api_contract_test.exs` reconciled — ALL hidden-modules assertions (including any duplicate in `manifest_test.exs`) green, as a pre-declared planned red→green step.
- [ ] **CONTRACT-02**: `priv/support_matrix.json` gains proof-backed theming row(s), a `guides/theming.md` + claims test binds every public theming claim to proof, and docs-contract + Hex-tarball lanes stay green (theme is pure code — no new asset ships in the tarball).
- [x] **CONTRACT-03**: An industry-agnostic `lib/` guard fails if `theme.ex` references an industry or named brand, holding the family-not-industry / "brands = data, design systems = code" boundary; B ships exactly one theme (`default/0`) + `from_brand/2` — no genre presets, catalog, or configurator.

## v2 Requirements (deferred — NOT anti-features; they map fine but belong to later milestones)

### Milestone C (`SEED-004`) — Presets, Catalog & Configurator

- **PRESET-01**: Style-genre presets (Swiss/Humanist/Editorial/Corporate-Classic/Minimal-Mono/Brutalist) as `%Theme{}` values.
- **PRESET-02**: Curated open-license preset fonts in `priv/fonts/`.
- **CATALOG-01**: Public example catalog (domain × brands × light/dark grid) as hash-checked artifacts, doubling as the standing quality ratchet.
- **CONFIG-01**: Static client-side configurator + URL state + `mix rendro.gen.theme` codegen.

### Milestone D (`SEED-005`)

- **STUDIO-01**: Live server-rendered theme playground.

### Demand-gated future

- **OTF-01**: Tabular figures / small-caps / OpenType features (need new engine primitives).

## Out of Scope

Explicitly excluded from the theme contract. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Shadow / elevation | No native PDF shadow; express flatly via `surface` tint + `rule` hairline. Excluded by construction. |
| z-index, motion, focus/hover/selection | Deterministic static PDF has no interaction/stacking model. |
| Opacity / gradient / wide-gamut color | No faithful deterministic-PDF mapping; engine speaks one DeviceRGB model. |
| Raw color scales (Radix-style 12-step) | Rendro ships semantic *roles*, not palettes; a palette is a Milestone-C preset concern. |
| Numeric weight axis, letter-spacing | No matching engine primitive today; demand-gated. |
| New runtime/optional/dev dependencies | Everything is Elixir stdlib on existing Color/Text/Path/FontRegistry surfaces + the S1 seam. |
| CLDR / gettext / locale-aware theming | Engine stays locale-free by standing Key Decision. |
| Print-safety or accessibility/PDF-UA claim for dark mode | No overclaim culture; dark is screen-oriented with an explicit boundary. |
| Genre presets / catalog / configurator / Studio in `lib/` | Milestones C and D; B ships one `default/0` + `from_brand/2` only. |

## Traceability

Which phases cover which requirements. Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| THEME-01 | Phase 119 | Complete |
| THEME-02 | Phase 119 | Complete |
| THEME-03 | Phase 119 | Complete |
| THEME-04 | Phase 119 | Complete |
| COLOR-01 | Phase 119 | Complete |
| COLOR-02 | Phase 119 | Complete |
| TYPE-01 | Phase 122 | Complete |
| TYPE-02 | Phase 122 | Complete |
| TYPE-03 | Phase 122 | Complete |
| MODE-01 | Phase 121 | Complete |
| MODE-02 | Phase 121 | Complete |
| MODE-03 | Phase 121 | Complete |
| PLUMB-01 | Phase 120 | Complete |
| PLUMB-02 | Phase 120 | Complete |
| PLUMB-03 | Phase 120 | Complete |
| DEFAULT-01 | Phase 123 | Pending |
| DEFAULT-02 | Phase 123 | Pending |
| DEFAULT-03 | Phase 123 | Pending |
| CONTRACT-01 | Phase 119 | Complete |
| CONTRACT-02 | Phase 123 | Pending |
| CONTRACT-03 | Phase 119 | Complete |

**Coverage:**

- v1 requirements: 21 total
- Mapped to phases: 21 (100% — each requirement in exactly one phase) ✓
- Unmapped: 0 ✓

**Per-phase counts:**

- Phase 119 (`Rendro.Theme` core module): 8 — THEME-01, THEME-02, THEME-03, THEME-04, COLOR-01, COLOR-02, CONTRACT-01, CONTRACT-03
- Phase 120 (S1 retrofit + `theme:` swap): 3 — PLUMB-01, PLUMB-02, PLUMB-03
- Phase 121 (light/dark mechanism): 3 — MODE-01, MODE-02, MODE-03
- Phase 122 (typography application): 3 — TYPE-01, TYPE-02, TYPE-03
- Phase 123 (`from_brand/2` E2E + rubric/docs closure): 4 — DEFAULT-01, DEFAULT-02, DEFAULT-03, CONTRACT-02

## Open Questions for Phase Planning (calibration, not architecture — locked recommendations)

- **Type-scale numbers**: lock one restrained ramp (major-second→major-third, ~1.125–1.25) as explicit points in the Theme-core phase. *Recommendation:* caption 8 / small 9 / body 10.5 / subtitle 12.5 / title 16 / display 22 — tune during rubric closure.
- **`on_accent` derivation**: auto-derive via internal WCAG-luminance heuristic (kept private, deterministic, no AA-conformance claim). *Recommendation:* auto-derive, allow explicit override.
- **Legacy `:palette` opt**: `grep -rn ":palette" test/` during the plumbing phase; *recommendation:* preserve via a final `Map.merge(theme.colors, opts[:palette])` so existing callers don't break.
- **Support-matrix granularity**: *recommendation:* score `theming.light` and `theming.dark` as separate rows (mirrors the v2.3 per-viewer evidence idiom).
- **`density: :compact`**: *recommendation:* present-and-defaulted in B (honored shallowly via `resolve/1` nudging leading/spacing); deep wiring deferred to C.

---
*Requirements defined: 2026-07-19*
*Last updated: 2026-07-23 — roadmap created, all 21 requirements mapped to Phases 119-123 (100% coverage)*

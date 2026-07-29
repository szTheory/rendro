# Requirements — Milestone v2.12: Style-Genre Presets, Public Catalog & Static Configurator

> Milestone C of the "Happy-Path Home Runs" program (`SEED-004`). Builds on the shipped v2.11 `Rendro.Theme` contract. Additive minor (hex `1.3.0` intent; release is a separate tag step). Phases continue global numbering from 125.
>
> **Goal:** Make great-looking branded documents turnkey — pick a design *style* + plug in palette/logo — and show it all off as a public by-domain example catalog that doubles as a standing quality ratchet.
>
> **Locked constraints (from research + prior decisions):**
> - Preset/genre/catalog/configurator vocabulary MUST NOT appear in `lib/rendro/theme.ex` (the `theme_industry_guard_test.exs` tripwire). Presets live in a new `lib/rendro/theme/presets.ex`.
> - New sibling module/manifest, never grow the existing one in place (`Rendro.Catalog` separate from `Rendro.LaunchArtifacts`).
> - Design systems = code (`lib/rendro/theme*`); example brands = data (`priv/examples/`) — a brand is never a module.
> - Zero new runtime dependencies; zero server/DB; no Node/npm in required CI or as a Hex runtime dep.
> - Byte-reproducibility preserved: no per-draw float math in preset derivation; deterministic font subsetting.
> - No-overclaim: every new public claim gets a proof artifact + matching `support_matrix.json` row + docs-contract tripwire. No design-quality guarantee, no accessibility/print-safety claim on dark cells.

## v2.12 Requirements

### Presets (PRESET)

- [ ] **PRESET-01**: A user can call `Rendro.Theme.preset(genre, accent: {r,g,b}, mode: :light | :dark)` and receive a fully-resolved `%Rendro.Theme{}`, composing over the existing `resolve/1` deep-merge and `dark/1` role-swap with `:accent`/`:mode` supplied at call time.
- [ ] **PRESET-02**: Five locked genre presets ship — Swiss/International, Humanist, Editorial, Corporate-Classic, Minimal-Mono — each a concrete, quantified token delta from `Theme.default()` (scale-contrast ratio, leading, rule weights, radius, spacing rhythm/density, color-role usage).
- [ ] **PRESET-03**: All preset genre token tables and dispatch live only in the new `lib/rendro/theme/presets.ex`; `theme.ex` gains at most a thin public `preset/2` delegation, keeping the `theme_industry_guard_test.exs` tripwire green (forbidden-word list never edited).
- [ ] **PRESET-04**: Every preset composes uniformly with light/dark and any caller accent without introducing nondeterminism — preset derivation adds no per-draw float math, and the un-themed/`default()` render stays byte-identical to prior goldens.
- [ ] **PRESET-05**: A preset referencing a font role that is not registered raises the existing typed `FontRegistry` error (no silent substitution).
- [ ] **PRESET-06** *(P2 / ship-if-time)*: A Brutalist preset ships (`radius: none`, `rules.thick` motif, steepest display:body contrast in the set) kept within business-document legibility.

### Curated Fonts (FONT)

- [ ] **FONT-01**: Four curated open-license fonts — a grotesque, a humanist sans, a text serif, a mono — are vendored as static TrueType (glyf/loca) builds under `priv/fonts/` so flagship presets render out of the box.
- [ ] **FONT-02**: Each vendored font carries a delimited `NOTICE` attribution block with a pinned upstream version; every license is verified redistributable inside a Hex package (SIL OFL 1.1 / Apache-2.0 class), with RFN/embedding constraints respected.
- [ ] **FONT-03**: `priv/fonts/` is added to the `mix.exs` `package.files` allowlist and its inclusion is proven by a positive tarball-content test (fonts actually ship to Hex consumers).
- [ ] **FONT-04**: Curated fonts register into `FontRegistry` under logical genre roles through an explicit `Rendro.Theme.Presets.register_fonts/2` bridge that is a caller step, never auto-invoked inside recipe `document/2` (Theme stays registry-pure).
- [ ] **FONT-05**: Font subsetting stays deterministic at catalog scale — glyph sets are sorted/deduped at the call site (or defensively in `subset/2`), proven by a double-subset byte-identity determinism test per vendored font.

### Carryover Polish (POLISH) — lands before dark-mode catalog generation

- [ ] **POLISH-01**: `invoice_dark` table-body cells are legible on the dark background (WINDOWS id 1), fixed at the shared color-role level so all recipes inherit the fix, not per-recipe.
- [ ] **POLISH-02**: The Ticket themed display/title hierarchy inversion (WINDOWS id 2, a locked Phase-122 decision) is explicitly resolved — either fixed, or given a named `stress_exemption`-style carve-out — so the quality ratchet never flags an accepted deviation as a regression.
- [ ] **POLISH-03**: `payslip` themed numeric cells no longer wrap mid-number (WINDOWS id 3) — a direct prerequisite for Minimal-Mono's tight tabular-figure columns.
- [ ] **POLISH-04**: A dedicated `from_brand`/preset accent-op byte golden covers preset × accent combinations (not just the original single `from_brand` call site).
- [ ] **POLISH-05**: Typography-test depth is extended to the 4 recipes currently on byte-identity + smoke coverage only, bringing all 7 recipes to explicit type-scale coverage.

### Public Catalog & Quality Ratchet (CATALOG)

- [ ] **CATALOG-01**: A public example catalog is generated as deterministic hash-checked artifacts (raster + `sha256`) covering each domain family × curated brand/preset combos × {light, dark} + one unbranded `default()` row per family, via a new `Rendro.Catalog` module + `assets/rendro/catalog.json` + `assets/rendro/catalog/` tree — never growing `@gallery_specs` in place.
- [ ] **CATALOG-02**: The catalog grid is bounded by an explicit, machine-tested combinatorial row-count budget/ceiling (curated `{brand × preset}` pairs per domain, never the full cross product), locked during catalog-phase planning against CI/tarball cost.
- [ ] **CATALOG-03**: Catalog artifacts are organized by-domain and brand-tagged, populating the already-reserved `preset`/`theme`/`mode` manifest keys (no schema migration).
- [ ] **CATALOG-04**: The Milestone-A rubric becomes a standing ratchet — `priv/quality/rubric_scores.json` is extended additively (`brand`/`preset`/`mode` fields), every catalog cell is scored or explicitly flagged unscored, thresholds are enforced, and a fail-loud coverage guard prevents new/changed cells from silently shipping unscored or stale. Scoring stays human (flagship-subset sign-off, not auto-scored, not 100%-grid-gated).
- [ ] **CATALOG-05**: Additional example brands are added as data tuples under `priv/examples/<domain>/` (never modules) to supply the catalog's brand variety, preserving the brands-as-data boundary.

### Static Configurator & Codegen (CONFIG)

- [ ] **CONFIG-01**: A static client-side configurator (`assets/rendro/configurator/`, HTML/CSS/vanilla JS, zero server/DB/build step) offers preset + accent + mode + document-family pickers over the pre-rendered catalog, served through the existing ExDoc `docs: [assets: ...]` copy-through with no new CI surface.
- [ ] **CONFIG-02**: The configurator snaps an accent selection to the nearest pre-rendered catalog preview via an exact-match lookup against a closed, curated accent palette, and transparently discloses "nearest preview vs. your exact copied code" (no fuzzy color-distance approximation).
- [ ] **CONFIG-03**: The configurator provides one-click copy of a `Rendro.Theme.preset(...)` + recipe-usage snippet with explicit success feedback.
- [ ] **CONFIG-04**: Configurator state (preset, accent, mode, family) is encoded in the URL query string — shareable, deep-linkable per cell, and restored deterministically on load; no XSS-unsafe interpolation of URL state into the DOM.
- [ ] **CONFIG-05**: `mix rendro.gen.theme <preset> --accent "#…"` generates a materialized theme module modeled on `mix brand.gen` (opts → generated file), with a `--check` drift gate that re-derives and byte-compares; it shares one canonical snippet-format template with the configurator's copy button (never two independent implementations that can drift).
- [ ] **CONFIG-06** *(P2)*: The existing Livebook is extended as a third tinkerer surface into the same `Theme.preset/2` vocabulary.

### Docs & Manifest Closure (DOCS)

- [ ] **DOCS-01**: Public surfaces are reconciled with no overclaim — a proof-backed `theming.presets` row in `priv/support_matrix.json`, a presets guide (`guides/presets.md` or extended `guides/theming.md`), `priv/public_api.json` regenerated for `Theme.preset/2`, README/HexDocs wiring, and docs-contract + guardrails-lockstep extensions bounding catalog/configurator claim language (a "strong starting point," never a design-quality or accessibility guarantee).

## Future Requirements (deferred)

- Live, server-rendered Studio with arbitrary token values and live render → **Milestone D (`SEED-005`)**.
- Hosted/DB-backed saved-theme, accounts, or theme-marketplace surfaces → out of scope (contradicts static/zero-backend design).
- Full WYSIWYG token editing beyond preset + accent + mode → Milestone D.
- OpenType tabular-figures / small-caps / feature toggles → demand-gated (needs new engine primitives).

## Out of Scope (explicit exclusions)

- **New `%Rendro.Theme{}` struct fields** (4th rule weight, modular-scale formula, per-preset custom groups) — SEED-003 locked the field *shape* as a stable contract; genre distinctiveness comes from chosen *values*, not new fields.
- **Auto-scoring the rubric** (LLM/heuristic assigning `dimension_scores`) — human sign-off is the one honest quality signal; automating it erodes it.
- **Per-brand custom fonts in the public catalog** beyond the 4 curated open-license files — avoids tarball bloat and licensing traps; brand rows vary accent + preset + logo only.
- **Server compute, databases, auth, or a Node/npm build step** anywhere in the configurator or required CI — the URL query string *is* the save mechanism.
- **Growing `@gallery_specs` / `theme.ex` in place** for catalog/preset logic — new sibling module/manifest is a locked structural constraint.
- **Any design-quality, accessibility, PDF/UA, print-safety, or WCAG claim** on presets, the catalog, or dark-mode cells.

## Traceability

_Filled by the roadmapper — every requirement maps to exactly one phase._

| REQ-ID | Phase |
|--------|-------|
| PRESET-01 | Phase 125 |
| PRESET-02 | Phase 125 |
| PRESET-03 | Phase 125 |
| PRESET-04 | Phase 125 |
| PRESET-05 | Phase 125 |
| PRESET-06 | Phase 125 |
| FONT-01 | Phase 125 |
| FONT-02 | Phase 125 |
| FONT-03 | Phase 125 |
| FONT-04 | Phase 125 |
| FONT-05 | Phase 125 |
| CATALOG-05 | Phase 125 |
| POLISH-01 | Phase 126 |
| POLISH-02 | Phase 126 |
| POLISH-03 | Phase 126 |
| POLISH-04 | Phase 126 |
| POLISH-05 | Phase 126 |
| CATALOG-01 | Phase 127 |
| CATALOG-02 | Phase 127 |
| CATALOG-03 | Phase 127 |
| CATALOG-04 | Phase 127 |
| CONFIG-01 | Phase 128 |
| CONFIG-02 | Phase 128 |
| CONFIG-03 | Phase 128 |
| CONFIG-04 | Phase 128 |
| CONFIG-05 | Phase 128 |
| CONFIG-06 | Phase 128 |
| DOCS-01 | Phase 129 |

**Coverage:** 28/28 requirements mapped, 100% — every requirement in exactly one phase, no orphans.

**Note on CATALOG-05 placement:** CATALOG-05 (additional example-brand data fixtures) is mapped to Phase 125 rather than the Phase 127 catalog-generation phase. Research (`ARCHITECTURE.md`) establishes it as "parallel-safe with Fonts+Presets — depends only on the shipped v2.11 theme contract, not on presets." It is pure data-fixture work with no catalog-machinery dependency, so it is grouped with the other foundational, independently-provable Phase 125 work; Phase 127 then consumes the fixtures Phase 125 produces.

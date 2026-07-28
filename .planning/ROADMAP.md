# ROADMAP — Rendro

## Milestones

- 🚧 **v2.11 Document Theming & Design-Token System** — Phases 119-123 (planning; additive minor `1.2.0`, Milestone B of the Happy-Path program / `SEED-003`)
- ✅ **v2.10 Realistic Business-Document Examples & Anatomy** — Phases 114-118 (shipped 2026-07-19; additive minor `1.1.0`, Milestone A)
- ✅ **C1 CI/CD Performance & Reliability** — Phases 108-113 (shipped 2026-07-11; non-version infra milestone, no Hex release)
- ✅ **B1 Brand System & Identity Lab** — Phases 101-107 (shipped 2026-06-14)
- ✅ **v2.9 TOC & Document Navigation** — Phases 97-100 (shipped 2026-06-14)

## Phases

### 🚧 v2.11 Document Theming & Design-Token System (Phases 119-123) — PLANNING

**Milestone Goal:** Give Rendro a public, deterministic PDF theming contract so every recipe is fully themable (brand colors + typography), gets light/dark for free, and ships a strong unbranded default that clears the Milestone-A reader-quality rubric — without widening the deterministic core or the family-not-industry boundary. The single irreversible act is shipping the new public `Rendro.Theme` value on the adapter/Evolving tier. The central regression guard is that an un-themed call reproduces v2.10 bytes exactly for all 7 recipes. Direction locked GREEN by research: zero new dependencies, zero deterministic-core surface — low technical risk, high discipline risk (freeze the right shape once; keep dark mode + type scale byte-stable; close the folded-in Phase-118 rubric gap by fixing DATA, not by cranking the theme).

- [x] **Phase 119: `Rendro.Theme` core module (the one-way door)** — ship `lib/rendro/theme.ex` with the full token shape defined up front on the adapter tier (`resolve/1`/`default/0`/`dark/1`/`from_brand/2`), web-concept exclusions by construction, the industry-agnostic guard, and the planned red→green `public_api_contract_test.exs` reconciliation — zero recipe change, so every existing golden is untouched. (completed 2026-07-27)
- [x] **Phase 120: S1 seam retrofit + full `theme:` swap across all 7 recipes** — retrofit the 4 un-seamed recipes (Statement/Certificate/Receipt/BrandedInvoice) with a byte-identical `palette/1` seam first, then swap all 7 to read `theme.colors.*` threaded through the 3 rungs; the no-theme call stays a byte-identity no-op. (completed 2026-07-27)
- [ ] **Phase 121: Light/dark background-fill mechanism (all 7 recipes)** — a role-derived full-page `:background` page-template region that repeats on every page (including overflow), giving every recipe dark for free, with the light default emitting no rect and staying byte-identical.
- [x] **Phase 122: Typography type-scale application + font-role/leading wiring** — thread the materialized named type scale, `FontRegistry` font roles, and `leading`/widows/orphans into `%Text{}` across recipes (the biggest rubric-hierarchy lever), with `default/0` a metric no-op that leaves Phase-117 goldens unchanged. (completed 2026-07-28)
- [ ] **Phase 123: `from_brand/2` E2E + honest rubric-gap closure + gallery/docs/manifest closure** — deliver the strong unbranded `default/0` and brand-seeded theming end-to-end, close the Phase-118 SHOW-01 gap in the honest order (fix DATA first, theme second, re-score with human sign-off), populate S6 gallery tags, and land `guides/theming.md` + support-matrix rows with all lanes green.

<details>
<summary>✅ v2.10 Realistic Business-Document Examples & Anatomy (Phases 114-118) — SHIPPED 2026-07-19</summary>

- [x] **Phase 114: Domain research, reader-quality rubric & realistic example-data library** — realistic `priv/examples/` fixtures + `@moduledoc false` loader + de-quarantine + per-domain `DOMAIN.md` + schema-backed appendable rubric manifest. (completed 2026-07-18)
- [x] **Phase 115: Invoice anatomy upgrade + Format public promotion + palette/align seams** — additive Invoice anatomy, `Format` promoted to the public adapter tier, `cell_align: :right`, and the S1 palette seam (the milestone's only real product `lib/` change). (completed 2026-07-18)
- [x] **Phase 116: New families — Payslip & Ticket** — two production-grade recipes on the 3-rung pattern reusing the palette seam, registered in `public_api.json` + `support_matrix.json`. (completed 2026-07-19)
- [x] **Phase 117: Edge-case stress matrix** — deterministic hash-checked goldens + pdfium raster refs + errors-as-product across the family × stress-dimension grid. (completed 2026-07-19)
- [x] **Phase 118: Rubric-gated demonstration set, gallery & docs closure** — family×domain demos passing the rubric (SHOW-01 gate closed via 118-08/09), gallery/`artifacts.json` regen with S6 tags, and guides/Livebook/phoenix_example/README/support_matrix reconciliation. (completed 2026-07-19)

**Archive:** `milestones/v2.10-ROADMAP.md`, `milestones/v2.10-REQUIREMENTS.md`

**Delivered:** `SEED-002` — realistic example corpus + loaders, additive Invoice anatomy + `Rendro.Format` adapter-tier promotion, Payslip & Ticket families, edge-case stress matrix, and rubric-gated demos. Four forward-compat "shape-now" seams (S1 palette, S4 brand slot, S5 rubric manifest, S6 artifact tags) keep Milestones B/C/D free of breaking rework. Known carryover folded into v2.11: the Phase-118 SHOW-01 rubric gap.

</details>

<details>
<summary>✅ C1 CI/CD Performance & Reliability (Phases 108-113) — SHIPPED 2026-07-11</summary>

- [x] **Phase 108: Baseline & Audit Report** — measured current CI topology, critical path, test/check classes, and P0-P3 recommendations. (completed 2026-06-14)
- [x] **Phase 109: Caching & setup-beam Foundation** — added keyed deps, `_build`, and PLT caching with unified SHA-pinned setup-beam. (completed 2026-06-15)
- [x] **Phase 110: Test Concurrency, Determinism & Cleanup** — improved test concurrency, documented non-async reasons, and quarantined/fixed nondeterministic paths. (completed 2026-06-16)
- [x] **Phase 111: Workflow Topology, Triggers & Matrix** — rationalized CI jobs, triggers, matrix policy, PR cancellation, and the stable `ci-success` required gate. (completed 2026-06-16)
- [x] **Phase 112: Security, Supply-chain & Release Hardening** — pinned actions, configured Dependabot, separated advisory audits, and hardened release preflight behavior. (completed 2026-06-16)
- [x] **Phase 113: DX, Local Reproducibility & Validation** — added scoped local CI aliases, contributor docs, README badge, final metrics, and remote validation evidence. (completed 2026-07-10)

**Archive:** `milestones/C1-ROADMAP.md`, `milestones/C1-REQUIREMENTS.md`, `milestones/C1-MILESTONE-AUDIT.md`. Validation: passed (30/30 requirements, 18/18 plans, 6/6 phases, three green remote `ci.yml` runs).

</details>

<details>
<summary>✅ v2.9 TOC & Document Navigation (Phases 97-100) — SHIPPED 2026-06-14</summary>

- [x] **Phase 97: Location Tracking & Primitives** — established exact X/Y physical locations and bounds as a foundational engine primitive. (completed 2026-06-13)
- [x] **Phase 98: Document Outlines (Bookmarks)** — introduced native, declarative doubly-linked PDF outline serialization. (completed 2026-06-14)
- [x] **Phase 99: Cross-References & Validation** — added validated internal document links that point to explicit physical destinations. (completed 2026-06-14)
- [x] **Phase 100: Printable Table of Contents Primitive** — provided safe post-layout substitution tokens for visual Tables of Contents. (completed 2026-06-14)

</details>

## Phase Details

### Phase 119: `Rendro.Theme` core module (the one-way door)

**Goal**: Ship the full public `Rendro.Theme` value contract — the complete token shape defined up front, resolved once, on the adapter/Evolving tier — with **zero recipe change** so every existing v2.10 golden is untouched. This is the milestone's only one-way door: once `%Theme{}` ships, its field set, nesting shape, and computed values become an observable contract.
**Depends on**: Nothing (first phase of the milestone; builds on the shipped v2.10 S1 `palette` seam)
**Requirements**: THEME-01, THEME-02, THEME-03, THEME-04, COLOR-01, COLOR-02, CONTRACT-01, CONTRACT-03
**Success Criteria** (what must be TRUE):

  1. `Rendro.Theme` exposes the FULL token shape up front — color roles + typography + spacing + rules + radius + density + mode, including honored-with-defaults tiers — constructed only via `resolve/1`/`default/0`/`dark/1`/`from_brand/2`, so later milestones append token *values* never *fields*.
  2. `Rendro.Theme.resolve/1` is idempotent and returns every color role as an integer `{r,g,b}` validated via `Rendro.Color.validate/1`, raising an instructive errors-as-product error on an invalid token; `from_brand/2` produces a theme from a single `accent:` seed with `on_accent` deterministically derived, emitting only tokens and never registering an asset (brand = *who* stays orthogonal to theme = *how*).
  3. Semantic color roles (`ink`/`muted`/`accent`/`on_accent`/`background`/`surface`/`rule` + optional `positive`/`negative`) are the only color surface, and web concepts that do not map to deterministic PDF (shadow/elevation, z-index, motion, focus/hover, opacity/gradient, raw color scales, numeric weight axis, letter-spacing, wide-gamut color) are absent from `%Theme{}` **by construction**, with honest flat-elevation guidance (express elevation via `surface` tint + `rule` hairline).
  4. `Rendro.Theme` ships on the **adapter/Evolving** tier in a regenerated `priv/public_api.json` (`mix rendro.api.gen`) with `@spec` on every public function, a doc note that token values and rendered output may evolve while the field shape stays stable, and all derivation helpers (`on_accent`, dark-swap, hex→tuple, normalize) private/`@doc false`; `public_api_contract_test.exs` and **every** duplicate hidden-modules assertion (including any in `manifest_test.exs`) reconcile green as a pre-declared planned red→green step.
  5. An industry-agnostic `lib/` guard fails if `theme.ex` references any industry or named brand, holding the family-not-industry / "brands = data, design systems = code" boundary; B ships exactly one theme (`default/0`) + `from_brand/2` — no genre presets, catalog, or configurator.

**Plans**: 2/2 plans complete

- [x] 119-01-PLAN.md
- [x] 119-02-PLAN.md

### Phase 120: S1 seam retrofit + full `theme:` swap across all 7 recipes

**Goal**: Make every recipe fully themable by threading a resolved `theme:` through the 3-rung pattern — retrofitting the 4 un-seamed recipes byte-identically **first**, then swapping all 7 to read `theme.colors.*` — while an un-themed call reproduces v2.10 bytes exactly. (Code-grounded correction: the S1 seam exists in only 3 of 7 recipes today; 4 need a byte-identical retrofit before any theme swap can touch them.)
**Depends on**: Phase 119 (`Rendro.Theme` value + `resolve/1`)
**Requirements**: PLUMB-01, PLUMB-02, PLUMB-03
**Success Criteria** (what must be TRUE):

  1. The 4 un-seamed recipes (Statement, Certificate, Receipt, BrandedInvoice) gain a byte-identical `palette/1` seam whose defaults equal today's exact literals (including any non-black default such as Certificate's `{34,34,34}` frame), each proven by a fresh sha256 golden committed **separately** from any theme wiring.
  2. All 7 recipes thread a resolved `theme:` through `document/2` → `page_template/1` → `sections/2`, reading `theme.colors.*` by role with no inline `{r,g,b}` literals in sections, and each recipe's `Keyword.take` opts whitelist admits `:theme` (legacy `:palette` callers preserved).
  3. `document(data)` with no `theme:` opt is a **byte-identity no-op for all 7 recipes**, reproducing v2.10 bytes — the milestone's central regression guard.

**Plans**: 4 plans

Plans:
**Wave 1**

- [x] 120-01-PLAN.md — Retrofit Statement + Certificate (byte-identical palette/1 seams, non-black {34,34,34} stress case, 2 frozen goldens) [Wave 1]
- [x] 120-02-PLAN.md — Retrofit Receipt + BrandedInvoice (ink seam D-03, KeyError whitelist fixes, net-new branded golden) [Wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 120-03-PLAN.md — Swap the 4 retrofitted recipes to theme.colors + threading tests [Wave 2]
- [x] 120-04-PLAN.md — Swap Invoice/Payslip/Ticket + phase-wide no-inline-literal source-scan test [Wave 2]

### Phase 121: Light/dark background-fill mechanism (all 7 recipes)

**Goal**: Give every recipe dark mode "for free" via a role-derived full-page background region that the paginator already repeats on every page — with the light default staying byte-identical to v2.10. This is a dedicated determinism-golden slice because the fill must appear on overflow pages too, and any per-draw float tint math would break byte-reproducibility.
**Depends on**: Phase 120 (theme threaded through all 7 recipes' 3 rungs)
**Requirements**: MODE-01, MODE-02, MODE-03
**Success Criteria** (what must be TRUE):

  1. A `mode: :light | :dark` selector with `Rendro.Theme.dark/1` derives dark by swapping **pre-resolved integer** role tuples (background/ink/surface/on_accent) — no separate art and no transcendental color math at draw time.
  2. Dark mode paints a full-page background on **EVERY** page including paginate-generated overflow pages (via a first-in-list `:background` page-template region, zero paginate change), while the light default emits **no** background rect and stays **byte-identical** to v2.10 — both proven by determinism goldens (light emits no rect; dark paints a forced-overflow page).
  3. Dark is documented as a screen-oriented mode with an explicit non-print-recommended boundary and a `theming.dark` support-matrix row — no print-safety or accessibility/PDF-UA claim; every shipped demo is light.

**Plans**: 3/4 plans executed

Plans:
**Wave 1**

- [x] 121-01-PLAN.md — TRACER: `Rendro.Recipes.Background` helper + Statement end-to-end (region/section/text-seam/nil-branch) + dark golden test (page-1 first-op + forced-overflow), bless Statement dark golden [Wave 1]
- [x] 121-04-PLAN.md — Docs-contract boundary: `theming` support-matrix rows + `dark/1` @doc non-print sentence + `theming_claims_test.exs` (overclaim tripwire) [Wave 1]

**Wave 2** *(blocked on 121-01: shared helper + dark golden test file)*

- [x] 121-02-PLAN.md — Certificate wiring + text seam (colors.ink) + landscape dark golden (non-portrait geometry proof), bless Certificate dark golden [Wave 2]
- [x] 121-03-PLAN.md — Background region+section wiring for the 5 verify-only recipes (Payslip/Invoice/Receipt/BrandedInvoice/Ticket) [Wave 2]

### Phase 122: Typography type-scale application + font-role/leading wiring

**Goal**: Apply the theme's typography across all recipes — the single biggest lever for the Phase-118 hierarchy gap — by threading the materialized named type scale, `FontRegistry` font roles, and `leading`/widows/orphans into `%Text{}`, while `default/0` stays a metric no-op that leaves Phase-117 stress goldens unchanged. The type scale is the one genuinely net-new surface in this milestone.
**Depends on**: Phase 120 (theme threaded through all 7 recipes)
**Requirements**: TYPE-01, TYPE-02, TYPE-03
**Success Criteria** (what must be TRUE):

  1. A named type scale (`display`/`title`/`subtitle`/`body`/`small`/`caption`) is materialized as **explicit point sizes** (not a runtime formula) and threaded into `%Text{}` size fields across the recipes, making the one key fact the visual anchor.
  2. Font roles (`heading`/`body`/`mono`) resolve through the existing `FontRegistry`; a theme referencing an unregistered font role raises the existing typed `{:unknown_text_font, _}` error and **never silently substitutes** Helvetica.
  3. `leading` (a line-height multiplier matching `Text.line_height` semantics) plus widows/orphans are theme-driven, and `default/0`'s scale/leading is a **metric no-op** — existing Phase-117 stress goldens render byte-identically.

**Plans**: 1/4 plans executed
**Wave 1**

- [x] 122-01-PLAN.md — Tracer: fully seam Invoice end-to-end across TYPE-01/02/03 (typography/1 seam, D-04 relaxation, raise-path) [Wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 122-02-PLAN.md — Expansion: seam the 3 clean recipes (Statement/Receipt/Payslip) [Wave 2]
- [x] 122-03-PLAN.md — Expansion: seam the 3 risk recipes resolving Q1/Q2/Q3 (BrandedInvoice/Certificate/Ticket) [Wave 2]

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 122-04-PLAN.md — Consolidation: no-inline-size-literals teeth test + full-suite phase gate [Wave 3]

### Phase 123: `from_brand/2` E2E + honest rubric-gap closure + gallery/docs/manifest closure

**Goal**: Close the milestone honestly — deliver a strong unbranded `default/0` and brand-seeded theming end-to-end, remediate the folded-in Phase-118 SHOW-01 rubric gap **in the honest order (fix DATA first, theme second)**, populate the S6 gallery tags, and reconcile the support matrix and docs so every theming claim is proof-backed. The trap this phase must avoid: applying a slick accent palette, declaring the demos prettier, and marking the rubric passed — a better palette raises craft/restraint, which were *not* the failing dimensions.
**Depends on**: Phase 121, Phase 122 (full theming + dark + typography required before honest rubric closure and gallery renders)
**Requirements**: DEFAULT-01, DEFAULT-02, DEFAULT-03, CONTRACT-02
**Success Criteria** (what must be TRUE):

  1. `Rendro.Theme.default/0` is a restrained neutral-ink (Swiss-ish) unbranded default with `{r,g,b}` mined from `brand/tokens/tokens.json` that looks strong on its own, and `from_brand/2` produces a themed document end-to-end from a single `accent:` seed with `brand:` assets (logo/font files) staying orthogonal.
  2. The Phase-118 SHOW-01 rubric gap is closed honestly and **in order** — the demo DATA is fixed first (`Rendro.ExamplesData.transform_invoice` parties/totals restored; the one key fact made structurally dominant), THEN `default/0` applied, THEN re-scored against the Milestone-A reader-quality rubric (hierarchy = 5, core ≥ 4, gates pass) with **human sign-off**; a `passed:true` score is committed only on an honest clear.
  3. Themed and dark gallery renders populate the existing S6 `theme`/`mode` tags on `assets/rendro/artifacts.json` (hash-checked), each `(recipe × mode)` a distinct blessed gallery row, with `preset` staying `null` (presets are Milestone C).
  4. `priv/support_matrix.json` gains proof-backed `theming.light`/`theming.dark` rows, a `guides/theming.md` + claims test binds every public theming claim to proof, and docs-contract + Hex-tarball lanes stay green (theme is pure code — no new asset ships in the tarball).

**Plans**: 5/5 plans executed

Plans:
**Wave 1**

- [x] 123-01-PLAN.md — Commit 1: DATA verify/attest (invoice issuer/customer/totals survival test; no theme, no scores) [Wave 1]

**Wave 2** *(blocked on 123-01: honest-order Commit-1 isolation)*

- [x] 123-02-PLAN.md — Commit 2a: `default/0` `leading: 1.35` value change + Certificate themed single-page fit-check + no-theme byte-identity guard [Wave 2]

**Wave 3** *(blocked on 123-02: leading applied before themed re-bless)*

- [x] 123-03-PLAN.md — Commit 2b: gallery closure — 11 rows (7 themed-default re-bless + invoice_dark/certificate_dark/ticket_dark + invoice_brand), readme_hero, count 7→11, pre-computed themed glyph deltas [Wave 3]

**Wave 4** *(blocked on 123-03: blessed rasters/hashes as evidence)*

- [x] 123-04-PLAN.md — `from_brand/2` E2E via `guides/theming.md` fences + `theming_contract_test.exs`; flip guides guard; proof-backed support-matrix; tarball lane green [Wave 4]
- [x] 123-05-PLAN.md — Commit 3: HONEST RE-SCORE (score-flip) — sign-off fields + schema if/then + test teeth + `SIGN-OFF.md` + human sign-off; zero-colour-code commit [Wave 4]

## Progress

**Execution Order:** Phases execute in numeric order: 119 → 120 → 121 → 122 → 123

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 119. `Rendro.Theme` core module (the one-way door) | v2.11 | 2/2 | Complete    | 2026-07-24 |
| 120. S1 seam retrofit + full `theme:` swap (7 recipes) | v2.11 | 4/4 | Complete    | 2026-07-27 |
| 121. Light/dark background-fill mechanism (7 recipes) | v2.11 | 4/4 | Complete    | 2026-07-28 |
| 122. Typography type-scale + font-role/leading wiring | v2.11 | 5/5 | Complete    | 2026-07-28 |
| 123. `from_brand/2` E2E + honest rubric-gap + docs closure | v2.11 | 5/5 | In Progress|  |

## Current Focus

🚧 **v2.11 Document Theming & Design-Token System** (Phases 119-123) — planning. All 21 requirements mapped (100% coverage, each requirement in exactly one phase); ready to plan Phase 119 with `/gsd-plan-phase 119`.

## Planned Next — "Happy-Path Home Runs" program (dormant seeds)

A sequenced 4-milestone program to make rendro's business-document happy paths shine: realistic,
award-quality example documents; a full document theming/design-token system; style-genre presets + a
public example catalog; and an optional interactive theme studio. Milestone A (`SEED-002`) shipped as
v2.10; Milestone B (`SEED-003`) is now active as v2.11. Remaining seeds live under `.planning/seeds/`.
See all seeds: `/gsd-capture --list-seeds`.

| # | Milestone | Seed | Status |
|---|-----------|------|--------|
| A | Realistic Business-Document Examples & Anatomy | `SEED-002` | ✅ shipped as v2.10 (Phases 114-118) |
| B | Document Theming & Design-Token System (`Rendro.Theme`, light/dark, unbranded default) | `SEED-003` | 🚧 active as v2.11 (Phases 119-123) |
| C | Style-Genre Presets, Public Catalog & Static Configurator | `SEED-004` | dormant |
| D | Rendro Studio: optional mountable theme playground (LiveView) | `SEED-005` *(optional)* | dormant |

Dependency order: A → B → C → D. Each is a right-sized milestone; D is optional/deferrable.

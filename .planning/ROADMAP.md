# ROADMAP — Rendro

## Milestones

- 🚧 **v2.12 Style-Genre Presets, Public Catalog & Static Configurator** — Phases 125-129 (planning; additive minor `1.3.0` intent, Milestone C of the Happy-Path program / `SEED-004`)
- ✅ **v2.11 Document Theming & Design-Token System** — Phases 119-124 (shipped 2026-07-28; additive minor `1.2.0`, Milestone B of the Happy-Path program / `SEED-003`)
- ✅ **v2.10 Realistic Business-Document Examples & Anatomy** — Phases 114-118 (shipped 2026-07-19; additive minor `1.1.0`, Milestone A)
- ✅ **C1 CI/CD Performance & Reliability** — Phases 108-113 (shipped 2026-07-11; non-version infra milestone, no Hex release)
- ✅ **B1 Brand System & Identity Lab** — Phases 101-107 (shipped 2026-06-14)
- ✅ **v2.9 TOC & Document Navigation** — Phases 97-100 (shipped 2026-06-14)

## Phases

### 🚧 v2.12 Style-Genre Presets, Public Catalog & Static Configurator (Phases 125-129) — PLANNING

**Milestone Goal:** Make great-looking branded documents turnkey — pick a design *style* + plug in palette/logo — and show it all off as a public by-domain example catalog that doubles as a standing quality ratchet. Builds directly on the shipped v2.11 `Rendro.Theme` contract. Folds in the three deferred v2.11 dark-mode/hierarchy polish items (WINDOWS ids 1-3) so the catalog's dark cells and the reader-quality ratchet start from an honest baseline rather than baking a known-bad baseline into a standing artifact. Preset/genre/catalog/configurator vocabulary is structurally confined to new sibling modules/manifests (`lib/rendro/theme/presets.ex`, `Rendro.Catalog` + `assets/rendro/catalog.json`) — `theme.ex` and the existing 11-row `@gallery_specs` are never grown in place (the `theme_industry_guard_test.exs` tripwire). Zero new runtime dependencies; zero server/DB; no Node/npm in required CI or as a Hex runtime dep. Direction locked HIGH-confidence by research: every capability is pure composition over already-shipped machinery (`Theme.resolve/1`/`dark/1`, `FontRegistry`, `LaunchArtifacts`, ExDoc's asset copy-through, `mix brand.gen`'s `--check` idiom).

**Phase-ordering note:** the research SUMMARY's literal Phase-1 was Carryover Polish; this roadmap sequences Foundation (fonts + presets) *before* Carryover Polish instead, because POLISH-04 (a dedicated `from_brand`/preset accent-op byte golden covering *preset* × accent combinations) cannot be satisfied until `Theme.preset/2` exists. The locked constraint — polish must land before any dark-mode catalog generation — is preserved: polish (Phase 126) still lands two phases before the catalog (Phase 127), not last.

- [x] **Phase 125: Foundation — Curated fonts, style-genre presets & brand fixtures** - `Theme.preset/2` ships 5 (6 if time allows) locked genre presets backed by 4 curated open-license embedded fonts, plus additional example-brand fixture data to seed catalog variety (completed 2026-08-16)
- [x] **Phase 126: Carryover polish — dark-mode legibility, hierarchy decision & golden/typography depth** - closes the 3 deferred v2.11 WINDOWS defects and deepens golden/typography-test coverage before any dark-mode catalog cell is generated (completed 2026-08-17)
- [x] **Phase 127: Public example catalog & quality ratchet** - a bounded, hash-checked domain × brand × preset × mode catalog with a fail-loud rubric-scoring coverage guard, as a new sibling of the existing launch gallery (completed 2026-08-17)
- [ ] **Phase 128: Static configurator, theme codegen & Livebook** - a zero-server browse → pick → copy configurator riding the catalog, `mix rendro.gen.theme --check`, and the Livebook as a third tinkerer surface
- [ ] **Phase 129: Docs & manifest closure** - a proof-backed `theming.presets` support-matrix row, a presets guide, and no-overclaim docs-contract coverage for every new public surface

<details>
<summary>✅ v2.11 Document Theming & Design-Token System (Phases 119-124) — SHIPPED 2026-07-28</summary>

- [x] **Phase 119: `Rendro.Theme` core module (the one-way door)** — shipped `lib/rendro/theme.ex` with the full token shape on the adapter/Evolving tier (`resolve/1`/`default/0`/`dark/1`/`from_brand/2`), web-concept exclusions by construction, the industry-agnostic guard, and the planned red→green `public_api_contract_test.exs` reconciliation — zero recipe change, every existing golden untouched. (completed 2026-07-24)
- [x] **Phase 120: S1 seam retrofit + full `theme:` swap across all 7 recipes** — retrofitted the 4 un-seamed recipes with byte-identical `palette/1` seams first, then swapped all 7 to read `theme.colors.*` through the 3 rungs; the no-theme call stays a byte-identity no-op (PLUMB-03). (completed 2026-07-27)
- [x] **Phase 121: Light/dark background-fill mechanism (all 7 recipes)** — role-derived full-page `:background` page-template region repeating on every page including overflow, giving every recipe dark for free, with the light default emitting no rect and staying byte-identical; dark bounded as screen-oriented. (completed 2026-07-28)
- [x] **Phase 122: Typography type-scale application + font-role/leading wiring** — threaded the materialized named type scale, `FontRegistry` font roles, and `leading`/widows/orphans into `%Text{}` across recipes (the biggest rubric-hierarchy lever), with `default/0` a metric no-op leaving Phase-117 goldens unchanged. (completed 2026-07-28)
- [x] **Phase 123: `from_brand/2` E2E + honest rubric-gap closure + gallery/docs/manifest closure** — delivered the strong unbranded `default/0` and brand-seeded theming end-to-end, closed the Phase-118 SHOW-01 gap in the honest order (DATA first, theme second, human sign-off), populated S6 gallery tags, and landed `guides/theming.md` + support-matrix rows with all lanes green. (completed 2026-07-28)
- [x] **Phase 124: Address v2.11 tech debt (stale 113 docs-contract test, formatter drift, dialyzer contract)** — cleared the 3 non-blocking CI items so `mix ci.fast` runs green end-to-end (1697 tests, 0 failures; dialyzer 0), with zero rendered-output change and the locked Ticket hierarchy regression untouched. (completed 2026-07-28)

**Archive:** `milestones/v2.11-ROADMAP.md`, `milestones/v2.11-REQUIREMENTS.md`, `milestones/v2.11-MILESTONE-AUDIT.md`, `milestones/v2.11-phases/`

**Delivered:** `SEED-003` — a public, deterministic PDF theming contract (`Rendro.Theme`) making all 7 recipes fully themable (brand colors + typography), light/dark "for free" via a repeating background region, and a strong unbranded `default/0` that clears the Milestone-A reader-quality rubric — without widening the deterministic core or the family-not-industry boundary. The un-themed call reproduces v2.10 bytes exactly (central regression guard). Known carryover: Ticket themed-hierarchy inversion + two dark-mode polish items (WINDOWS ids 1-3, deferred to follow-up / Milestone C).

</details>

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

### Phase 125: Foundation — Curated fonts, style-genre presets & brand fixtures

**Goal**: Callers can generate distinctive, correctly-licensed, on-brand documents via `Rendro.Theme.preset/2` backed by real embedded fonts and expanded brand-fixture data — every piece independently provable (`Theme.preset/2` → recipe `document/2` → render → pdfium raster) with no catalog or configurator dependency.
**Depends on**: Nothing (first phase of the milestone; builds on the shipped v2.11 `Rendro.Theme` contract)
**Requirements**: PRESET-01, PRESET-02, PRESET-03, PRESET-04, PRESET-05, PRESET-06, FONT-01, FONT-02, FONT-03, FONT-04, FONT-05, CATALOG-05
**Success Criteria** (what must be TRUE):

  1. Calling `Rendro.Theme.preset(:editorial, accent: {r,g,b}, mode: :dark)` (and the other 4 locked genres — Swiss, Humanist, Corporate-Classic, Minimal-Mono, plus Brutalist if time allows) returns a fully-resolved `%Rendro.Theme{}` that composes over the existing `resolve/1`/`dark/1` pipeline and renders through an existing recipe with the 4 curated fonts embedded, producing a genre-distinct, printable PDF.
  2. `theme_industry_guard_test.exs` stays green with its forbidden-word list unmodified — all preset/genre token tables and dispatch live only in `lib/rendro/theme/presets.ex`, with `theme.ex` gaining at most a thin `preset/2` delegation.
  3. `mix hex.build` output contains every `priv/fonts/**` file referenced by a shipped preset, each with its own clearly-delimited `NOTICE` attribution block and pinned upstream version, proven by a positive tarball-content test.
  4. Referencing an unregistered preset font role raises the existing typed `FontRegistry` error (no silent substitution), and a double-subset determinism test proves byte-identical subsetting output for every vendored font.
  5. At least one additional example brand exists per domain family under `priv/examples/<domain>/` as a data tuple (never a module), and the un-themed/`default()` render stays byte-identical to prior goldens (zero per-draw float math in preset derivation).

**Plans**: 10/10 plans executed

Plans:
**Wave 1**

- [x] 125-01-PLAN.md — Trace one real Swiss invoice through strict preset construction, explicit registration, and real embedded fonts.
- [x] 125-07-PLAN.md — Establish the generic brand schema with Invoice and Payslip fixture pairs.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 125-02-PLAN.md — Complete four-face provenance, Hex packaging, role descriptors, and deterministic subsetting.
- [x] 125-08-PLAN.md — Add Statement and Receipt fixture pairs with progressive corpus contracts.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 125-03-PLAN.md — Expand and guard the complete six-row structural genre grammar.
- [x] 125-09-PLAN.md — Add Certificate and Ticket fixture pairs and close corpus/package invariants.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 125-04-PLAN.md — Repair Certificate exact-font metrics and prove the deterministic twelve-row render matrix.

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 125-05-PLAN.md — Bind Swiss, Humanist, and Editorial light/dark rows to pinned advisory rasters.

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 125-06-PLAN.md — Complete the pinned raster matrix with Corporate-Classic, Minimal-Mono, and Brutalist.

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 125-10-PLAN.md — Run the deterministic phase gate and conduct separately pinned-PDFium human review.

**UI hint**: no — pure library API + vendored data files, no browser-rendered surface

### Phase 126: Carryover polish — dark-mode legibility, hierarchy decision & golden/typography depth

**Goal**: Resolve or honestly exempt every deferred v2.11 dark-mode/hierarchy defect, and deepen golden/typography coverage — including a preset × accent golden now that `Theme.preset/2` exists — so the first catalog generation isn't the first real stress test of these paths.
**Depends on**: Phase 125 (`Theme.preset/2` must exist for POLISH-04's preset × accent byte golden)
**Requirements**: POLISH-01, POLISH-02, POLISH-03, POLISH-04, POLISH-05
**Success Criteria** (what must be TRUE):

  1. `invoice_dark` table-body cells render with legible ink-on-background contrast, fixed at the shared color-role level so every recipe inherits the fix rather than a per-recipe patch.
  2. The Ticket display/title hierarchy inversion (a locked Phase-122 outcome) is either fixed, or carries an explicit, schema-enforced `stress_exemption`-style carve-out so the quality ratchet never silently flags the accepted deviation as a regression.
  3. `payslip` themed numeric cells no longer wrap mid-number, including under Minimal-Mono's tight tabular-figure columns.
  4. A dedicated byte-identity golden exercises `from_brand`/preset accent-op combinations (not just the single original `from_brand` call site).
  5. All 7 recipes (not just 3) have dedicated typography-test coverage of the materialized type scale, closing the byte-identity-plus-smoke-only gap on the remaining 4.

**Plans**: 5/5 plans executed

Plans:
**Wave 1**

- [x] 126-01-PLAN.md — Repair themed Invoice ink, Ticket hierarchy/reference fit, and Payslip atomic money cells while preserving nil-theme bytes.
- [x] 126-02-PLAN.md — Add the bounded preset/accent byte golden and semantic typography contracts for all seven recipes.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 126-03-PLAN.md — Refresh only affected pinned-PDFium hashes and produce full-size row-addressable review images.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 126-04-PLAN.md — Review all affected rows sequentially at full size and record a bounded human disposition.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 126-05-PLAN.md — Reconcile quality/WINDOWS evidence and run the complete deterministic phase gate.

**UI hint**: no — recipe/render-path bug fixes and test-depth work, no browser-rendered surface

### Phase 127: Public example catalog & quality ratchet

**Goal**: A public, hash-checked, by-domain example catalog exists at an explicitly bounded scale — a new sibling of the existing 11-row launch gallery, never grown in place — with every generated cell either human-scored against the reader-quality rubric or explicitly flagged unscored, never silently unverified.
**Depends on**: Phase 125 (presets, fonts, brand fixtures), Phase 126 (polish must land first so dark-mode cells are legible from the very first generation)
**Requirements**: CATALOG-01, CATALOG-02, CATALOG-03, CATALOG-04
**Success Criteria** (what must be TRUE):

  1. Running the new catalog-generation task produces a deterministic, sha256 hash-checked artifact tree under `assets/rendro/catalog/<domain>/<brand>/` plus `assets/rendro/catalog.json` via a new sibling `Rendro.Catalog` module, covering every domain family's unbranded default plus curated brand/preset combos in light and dark — without modifying the existing `@gallery_specs`/`artifacts.json`.
  2. A machine-tested combinatorial row-count ceiling fails the build if a future change silently grows the grid toward the full domain × brand × preset × mode cross product.
  3. Every generated catalog row populates the already-reserved `preset`/`theme`/`mode` manifest keys (no schema migration) and is organized on disk by domain, brand-tagged.
  4. `priv/quality/rubric_scores.json` carries a scored or explicitly-flagged-unscored entry for every catalog cell, a fail-loud coverage guard blocks new/changed cells from shipping silently unscored, and no existing `passed:false` entry (e.g. Ticket) is ever flipped to `true` without addressing its underlying defect.

**Plans**: 5/5 plans executed

- [x] 127-01-PLAN.md
- [x] 127-02-PLAN.md
- [x] 127-03-PLAN.md
- [x] 127-04-PLAN.md
- [x] 127-05-PLAN.md

**UI hint**: no — build-time artifact generation, no interactive browser surface (the catalog's own public presentation ships in Phase 128's configurator)

### Phase 128: Static configurator, theme codegen & Livebook

**Goal**: A user can browse the public catalog from a zero-server static page, pick a preset/accent/mode/family, see the nearest truthful pre-rendered preview, and copy a working Elixir snippet or generate a committed theme module — three tinkerer surfaces (configurator, `mix rendro.gen.theme`, Livebook) sharing one canonical snippet format.
**Depends on**: Phase 127 (the catalog must exist as the configurator's pre-rendered data source — "nearest preview" has nothing to snap to without it)
**Requirements**: CONFIG-01, CONFIG-02, CONFIG-03, CONFIG-04, CONFIG-05, CONFIG-06
**Success Criteria** (what must be TRUE):

  1. `assets/rendro/configurator/` loads and works as a static HTML/CSS/vanilla-JS page — no `package.json`, no build step, no server/DB call anywhere in its shipped path — served through the existing ExDoc `assets:` copy-through.
  2. Picking a preset + accent + mode + family shows the exact pre-rendered catalog tile for that exact-match combination (never a fuzzy color-distance approximation against an open picker), and clicking copy places a working `Rendro.Theme.preset(...)` snippet on the clipboard with visible success feedback.
  3. Reloading a shared configurator URL restores the same selection from the query string alone, and every URL-derived value is rendered via safe DOM APIs (`textContent`/`setAttribute`, never `innerHTML` string interpolation of untrusted state).
  4. `mix rendro.gen.theme <preset> --accent "#…"` writes a generated theme module and `--check` fails loudly on drift; the generated snippet and the configurator's copy button provably share one canonical template (a compile-round-trip test covers the full producible preset × mode × accent enum).
  5. The existing Livebook exercises `Theme.preset/2` live as a third tinkerer surface alongside the configurator and `mix rendro.gen.theme`.

**Plans**: 5 plans

Plans:
- [ ] 128-01-PLAN.md — Establish the canonical packaged formatter and deterministic 504-record configurator index.
- [ ] 128-02-PLAN.md — Ship the safe application-owned theme generator and read-only drift gate.
- [ ] 128-03-PLAN.md — Build the truthful static configurator, four-key URL contract, and exact clipboard path.
- [ ] 128-04-PLAN.md — Extend the existing Livebook with one formatter-owned preset render and bounded proof.
- [ ] 128-05-PLAN.md — Run the complete post-integration static, CI, Livebook, drift, browser, and assistive-technology gates.
**UI hint**: yes — a real static HTML/CSS/vanilla-JS browser surface (distinct from this project's PDF-domain "theme"/"page"/"layout" terms that otherwise false-positive the UI gate on recipe phases)

### Phase 129: Docs & manifest closure

**Goal**: Every new public surface this milestone shipped — presets, the catalog, and the configurator — is reconciled into Rendro's proof-backed public claim surface with no overclaim, closing the loop honestly now that the actual shipped scope is known.
**Depends on**: Phase 125, Phase 126, Phase 127, Phase 128 (every functional surface must exist before docs can honestly describe it)
**Requirements**: DOCS-01
**Success Criteria** (what must be TRUE):

  1. `priv/support_matrix.json` carries a proof-backed `theming.presets` row, and `priv/public_api.json` is regenerated (`mix rendro.api.gen`) to include `Theme.preset/2`.
  2. A presets guide (new `guides/presets.md` or an extended `guides/theming.md`) plus README/HexDocs wiring describe presets/catalog/configurator only as "a strong starting point," never a design-quality, accessibility, or print-safety guarantee.
  3. Docs-contract + guardrails-lockstep lanes (lane count, `required_checks_contract_test.exs` assertion, `priv/guardrails/required_status_checks.json`) are extended together, in the same commit, to bound catalog/configurator claim language, and `mix ci.fast` runs green end-to-end.

**Plans**: TBD
**UI hint**: no — docs/manifest reconciliation only

## Progress

**Execution Order:** Phases execute in numeric order: 125 → 126 → 127 → 128 → 129

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 125. Foundation — Curated fonts, style-genre presets & brand fixtures | v2.12 | 10/10 | Complete    | 2026-08-16 |
| 126. Carryover polish — dark-mode legibility, hierarchy & golden depth | v2.12 | 5/5 | Complete    | 2026-08-17 |
| 127. Public example catalog & quality ratchet | v2.12 | 5/5 | Complete    | 2026-08-17 |
| 128. Static configurator, theme codegen & Livebook | v2.12 | 0/TBD | Not started | - |
| 129. Docs & manifest closure | v2.12 | 0/TBD | Not started | - |

## Current Focus

🚧 **v2.12 Style-Genre Presets, Public Catalog & Static Configurator** (Phases 125-129) — planning. All 28 requirements mapped (100% coverage, each requirement in exactly one phase); ready to plan Phase 125 with `/gsd-plan-phase 125`.

## Planned Next — "Happy-Path Home Runs" program (dormant seeds)

A sequenced 4-milestone program to make rendro's business-document happy paths shine: realistic,
award-quality example documents; a full document theming/design-token system; style-genre presets + a
public example catalog; and an optional interactive theme studio. Milestone A (`SEED-002`) shipped as
v2.10; Milestone B (`SEED-003`) shipped as v2.11. Milestone C (`SEED-004`) roadmap is now created.
See all seeds: `/gsd-capture --list-seeds`.

| # | Milestone | Seed | Status |
|---|-----------|------|--------|
| A | Realistic Business-Document Examples & Anatomy | `SEED-002` | ✅ shipped as v2.10 (Phases 114-118) |
| B | Document Theming & Design-Token System (`Rendro.Theme`, light/dark, unbranded default) | `SEED-003` | ✅ shipped as v2.11 (Phases 119-124) |
| C | Style-Genre Presets, Public Catalog & Static Configurator | `SEED-004` | 🚧 active — roadmap created (Phases 125-129) |
| D | Rendro Studio: optional mountable theme playground (LiveView) | `SEED-005` *(optional)* | dormant |

Dependency order: A → B → C → D. Each is a right-sized milestone; D is optional/deferrable.

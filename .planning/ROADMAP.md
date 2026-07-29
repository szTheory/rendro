# ROADMAP — Rendro

## Milestones

- ✅ **v2.11 Document Theming & Design-Token System** — Phases 119-124 (shipped 2026-07-28; additive minor `1.2.0`, Milestone B of the Happy-Path program / `SEED-003`)
- ✅ **v2.10 Realistic Business-Document Examples & Anatomy** — Phases 114-118 (shipped 2026-07-19; additive minor `1.1.0`, Milestone A)
- ✅ **C1 CI/CD Performance & Reliability** — Phases 108-113 (shipped 2026-07-11; non-version infra milestone, no Hex release)
- ✅ **B1 Brand System & Identity Lab** — Phases 101-107 (shipped 2026-06-14)
- ✅ **v2.9 TOC & Document Navigation** — Phases 97-100 (shipped 2026-06-14)

## Phases

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

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 119. `Rendro.Theme` core module (the one-way door) | v2.11 | 2/2 | Complete | 2026-07-24 |
| 120. S1 seam retrofit + full `theme:` swap (7 recipes) | v2.11 | 4/4 | Complete | 2026-07-27 |
| 121. Light/dark background-fill mechanism (7 recipes) | v2.11 | 4/4 | Complete | 2026-07-28 |
| 122. Typography type-scale + font-role/leading wiring | v2.11 | 5/5 | Complete | 2026-07-28 |
| 123. `from_brand/2` E2E + honest rubric-gap + docs closure | v2.11 | 5/5 | Complete | 2026-07-28 |
| 124. Address v2.11 tech debt (CI-green remediation) | v2.11 | 1/1 | Complete | 2026-07-28 |

## Current Focus

✅ **v2.11 Document Theming & Design-Token System shipped** (Phases 119-124, 2026-07-28). All 21 requirements complete; milestone audit `passed`; archived under `milestones/v2.11-*`. Next: plan Milestone C (`SEED-004`) via `/gsd-new-milestone`.

## Planned Next — "Happy-Path Home Runs" program (dormant seeds)

A sequenced 4-milestone program to make rendro's business-document happy paths shine: realistic,
award-quality example documents; a full document theming/design-token system; style-genre presets + a
public example catalog; and an optional interactive theme studio. Milestone A (`SEED-002`) shipped as
v2.10; Milestone B (`SEED-003`) shipped as v2.11. Remaining seeds live under `.planning/seeds/`.
See all seeds: `/gsd-capture --list-seeds`.

| # | Milestone | Seed | Status |
|---|-----------|------|--------|
| A | Realistic Business-Document Examples & Anatomy | `SEED-002` | ✅ shipped as v2.10 (Phases 114-118) |
| B | Document Theming & Design-Token System (`Rendro.Theme`, light/dark, unbranded default) | `SEED-003` | ✅ shipped as v2.11 (Phases 119-124) |
| C | Style-Genre Presets, Public Catalog & Static Configurator | `SEED-004` | dormant — next up |
| D | Rendro Studio: optional mountable theme playground (LiveView) | `SEED-005` *(optional)* | dormant |

Dependency order: A → B → C → D. Each is a right-sized milestone; D is optional/deferrable.

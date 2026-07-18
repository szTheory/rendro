# ROADMAP — Rendro

## Milestones

- 🚧 **v2.10 Realistic Business-Document Examples & Anatomy** — Phases 114-118 (in progress; additive minor `1.1.0`, Milestone A of the Happy-Path program)
- ✅ **C1 CI/CD Performance & Reliability** — Phases 108-113 (shipped 2026-07-11; non-version infra milestone, no Hex release)
- ✅ **v2.9 TOC & Document Navigation** — Phases 97-100 (shipped 2026-06-14)
- ✅ **B1 Brand System & Identity Lab** — Phases 101-107 (shipped 2026-06-14)

## Phases

### 🚧 v2.10 Realistic Business-Document Examples & Anatomy (Phases 114-118)

**Milestone Goal:** Close the toy→production gap so a serious user can adopt an award-quality, domain-correct business document immediately — a realistic example corpus + reader-quality rubric, an additive Invoice anatomy upgrade, two new families (Payslip, Ticket), an edge-case stress matrix, and rubric-gated demos — without widening the deterministic core or the family-not-industry boundary. The one irreversible act is promoting `Rendro.Format` to the public adapter tier. Four forward-compat "shape-now" seams (S1 palette, S4 brand slot, S5 rubric manifest, S6 artifact tags) keep Milestones B/C/D free of breaking rework.

- [x] **Phase 114: Domain research, reader-quality rubric & realistic example-data library** — realistic `priv/examples/` fixtures + `@moduledoc false` loader + de-quarantine + per-domain `DOMAIN.md` + schema-backed appendable rubric manifest (no `lib/` product change beyond the loader). (completed 2026-07-18)
- [ ] **Phase 115: Invoice anatomy upgrade + Format public promotion + palette/align seams** — additive Invoice anatomy (issuer/customer/due_date/terms/totals + Decimal money), `Format` promoted to the public adapter tier, `cell_align: :right`, and the S1 palette seam (the milestone's only real product `lib/` change).
- [ ] **Phase 116: New families — Payslip & Ticket** — two production-grade recipes on the 3-rung pattern reusing the palette seam, registered in `public_api.json` (adapter tier) + `support_matrix.json`.
- [ ] **Phase 117: Edge-case stress matrix** — deterministic hash-checked goldens + pdfium raster refs + errors-as-product across the family × stress-dimension grid.
- [ ] **Phase 118: Rubric-gated demonstration set, gallery & docs closure** — family×domain demos passing the rubric, gallery/`artifacts.json` regen with S6 tags, and guides/Livebook/phoenix_example/README/support_matrix reconciliation.

## Phase Details

### Phase 114: Domain research, reader-quality rubric & realistic example-data library

**Goal**: Establish the milestone's data + quality foundation — a realistic, schema-validated example corpus with a load-bearing loader, per-domain domain research, and an appendable reader-quality rubric — with no `lib/` product change except the `@moduledoc false` loader.
**Depends on**: Nothing (first phase of the milestone; builds on shipped C1/1.0 infrastructure)
**Requirements**: EXL-01, EXL-02, EXL-03, EXL-04, EXL-05, EXL-06, RUB-01, RUB-02, RUB-03
**Success Criteria** (what must be TRUE):

  1. Fixtures exist at `priv/examples/<domain>/<business>/<family>.json` encoding the domain language with real-shaped fictional businesses (addresses, terms, tax) and Decimal-safe money as strings (never JSON floats), each carrying an optional empty `brand`/`logo` slot (seam S4); every fixture validates against a repo-only `priv/schemas/examples.schema.json` via a docs-contract lane folded into the required `test` job.
  2. A `Rendro.Examples` loader (`lib/rendro/examples.ex`, `@moduledoc false`) reads fixtures for tests, bench, guides, and Livebook, resolves via `app_dir` for shipped consumers, and is asserted **absent** from `priv/public_api.json` (stays out of the public tier).
  3. The single realistic invoice fixture is de-quarantined from `bench/comparison/fixtures/invoice_data.json` into the example library and the bench harness is repointed, with `mix rendro.comparison.check` staying green — the move is a provable no-op (money-string normalization committed separately).
  4. `priv/examples/` ships in the Hex tarball as **text-only** (`.json`/`.md`/`.svg`), added to the `mix.exs` package allowlist + exact-allowlist tarball audit, with a raster-ban test mirroring `brand/`.
  5. Each domain has a co-located `DOMAIN.md` (domain language, personas + JTBD, reading context, layout/typographic conventions), and the reader-quality rubric (6 core 1–5 dims + 2 pass/fail gates with non-designer anchors) is recorded as a schema-backed **appendable** manifest (`priv/quality/rubric_scores.json` + schema) whose docs-contract lane enforces structure and threshold arithmetic (hierarchy = 5, core ≥ 4, gates pass) — not the subjective score (seam S5).

**Plans**: 7 plans

Plans:
**Wave 1**

- [x] 114-01-PLAN.md — De-quarantine invoice fixture (verbatim move + repoint, provable no-op) — EXL-04
- [x] 114-02-PLAN.md — Author examples.schema.json + rubric_scores.schema.json — EXL-03, RUB-03
- [x] 114-05-PLAN.md — Author Invoice DOMAIN.md + domain_md_contract_test.exs — RUB-01

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 114-03-PLAN.md — Normalize money to Decimal-safe strings + S4 brand slot + fixture schema-contract test — EXL-01, EXL-03, EXL-06
- [x] 114-04-PLAN.md — Rendro.Examples loader (load!/1, list/1) + loader test + public_api hidden-list extension — EXL-02, EXL-05
- [x] 114-06-PLAN.md — Reader-quality rubric content + rubric_scores.json manifest + contract test — RUB-02, RUB-03

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 114-07-PLAN.md — Hex packaging: mix.exs allowlist, .gitignore raster-ban, tarball inclusion/exclusion tests — EXL-05

### Phase 115: Invoice anatomy upgrade + Format public promotion + palette/align seams

**Goal**: Deliver the milestone's one real product `lib/` change — an additive, byte-compatible Invoice anatomy upgrade, the public promotion of `Rendro.Format`, the additive `cell_align: :right` primitive, and the S1 palette seam — without breaking the toy call or widening the Stable tier.
**Depends on**: Phase 114 (realistic invoice fixtures + Decimal money strings + rubric)
**Requirements**: INV-01, INV-02, INV-03, INV-04, INV-05, INV-06, INV-07
**Success Criteria** (what must be TRUE):

  1. `Rendro.Recipes.Invoice` accepts additive optional `:issuer`, `:customer`, `:due_date`, `:terms`, and `:totals`, rendering each only when present, and the pre-upgrade toy call (`%{id:, date:, items:}`) renders **byte-identically** to before (additive / backward-compat guard).
  2. Invoice money uses `%Decimal{}` routed through `Rendro.Format.money/1` (bare-number `price` still renders `"$#{price}"`), new money fields are Decimal-only and reject Floats instructively, and a `:totals` block renders only when supplied, is validated as a caller assertion via `Decimal.equal?/2`, and is kept with the last table rows across a page break via `Recipes.Pagination`.
  3. `Rendro.Format` is promoted from `@moduledoc false` to the public **adapter** tier with a minimal surface (`money/1`, `date/1`, `label/1`), `@spec`s, a `public_api.json` entry, a migration note, and a documented "output may evolve" note; the Phase-79 public-API contract lane (including the hidden set) passes (Format adapter-tier freeze discipline — the milestone's single irreversible act).
  4. An additive `cell_align: :right` option right-aligns tabular money while existing tables (no `cell_align`) render byte-identically, and `Rendro.Recipes.Invoice.validate_data!/1` raises an instructive `ArgumentError` on malformed input (never leaking `BadMapError`/`FunctionClauseError`) and never rejects a valid toy call.
  5. Invoice sections read colors through a private `palette(opts)` keyed on Milestone-B's locked color roles (`ink`/`muted`/`accent`/`on_accent`/`background`/`surface`/`rule`) defaulting to today's literals — no section inlines `{0,0,0}`; the `page_template/1` opts leak is closed via a `Keyword.take` whitelist while top-level `opts` stays open for B's future `theme:` (seam S1).

**Plans**: 4 plans
**Wave 1**

- [ ] 115-01-PLAN.md — Wave-0 byte-identity golden baselines (toy render + no-cell_align table) [INV-01, INV-05]

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 115-02-PLAN.md — `Rendro.Format` public adapter-tier promotion (atomic 4-artifact, irreversible) [INV-04]
- [ ] 115-03-PLAN.md — additive `cell_align: :right` primitive (spike + gated offset + no-op guard) [INV-05]

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 115-04-PLAN.md — Invoice anatomy upgrade (validate_data!/palette/whitelist/anatomy/Decimal money/totals) [INV-01, INV-02, INV-03, INV-06, INV-07]

### Phase 116: New families — Payslip & Ticket

**Goal**: Add two production-grade document families on the proven 3-rung pattern — a Payslip (flow, anchor = net pay) and a Ticket (fixed-box, anchor = seat/gate) — reusing the S1 palette seam and the errors-as-product contract, with jurisdiction differences kept as data.
**Depends on**: Phase 115 (palette seam S1, `Format` adapter tier, `Recipes.Pagination` reuse)
**Requirements**: FAM-01, FAM-02, FAM-03
**Success Criteria** (what must be TRUE):

  1. `Rendro.Recipes.Payslip` renders a production-grade payslip on the 3-rung pattern (`document/2` / `page_template/1` / `sections/2`) with net pay as the visual anchor, side-by-side earnings/deductions, and YTD totals; jurisdiction differences (e.g. PAYE/NI vs FICA/401k) are label **data**, not engine logic; fixtures use fictional employees only (no real PII).
  2. `Rendro.Recipes.Ticket` renders a fixed-box ticket/boarding-pass on the 3-rung pattern with seat/gate/section as the anchor, a boxed code-area + human-readable reference + perforation line, and an optional caller-supplied PNG code image; content overflow raises a typed error.
  3. Both recipes validate input as errors-as-product (instructive `ArgumentError`) and read colors via the `palette(opts)` seam (S1) — no section inlines `{0,0,0}`.
  4. Both recipes are registered in `priv/public_api.json` (adapter tier) and `priv/support_matrix.json` with proof-backed rows.

**Plans**: TBD

### Phase 117: Edge-case stress matrix

**Goal**: Prove the whole recipe surface is robust and deterministic under stress — a family × stress-dimension grid of hash-checked goldens and typed-error assertions — exempt from the rubric's beauty gate because it proves robustness, not aesthetics.
**Depends on**: Phase 116 (all six families exist to stress-test)
**Requirements**: EDGE-01, EDGE-02, EDGE-03
**Success Criteria** (what must be TRUE):

  1. Each family × stress dimension (text length/wrapping, line-item counts 0/1/few/page-boundary/60+, missing optional fields, numeric edges $0.00/negatives-as-parens/$1M+/cents-rounding/zero-qty, USD vs GBP/EUR + VAT vs sales-tax labels, pagination boundaries, A4 vs US Letter, odd/even running content) renders a deterministic golden artifact verified by SHA-256, with matching pdfium raster refs where applicable (byte-determinism guard); goldens and raster refs are excluded from the Hex tarball (package-size guard).
  2. Overflow (`:content_overflow`), a single row taller than the body, and RTL input each raise an instructive typed `Rendro.Error`/`ArgumentError` — never silent truncation or a leaked internal error.
  3. Stress fixtures are explicitly exempt from the rubric beauty gate (they prove robustness, not aesthetics), and this exemption is explicit in the rubric manifest/tests.

**Plans**: TBD

### Phase 118: Rubric-gated demonstration set, gallery & docs closure

**Goal**: Close the milestone with a rubric-passing family×domain demonstration set, regenerated gallery/artifacts (with S6 tags), and reconciled docs/support so every new family and claim is proof-backed and no accessibility overclaim is made.
**Depends on**: Phase 117 (and the upgraded Invoice + new families + rubric from 114–116)
**Requirements**: SHOW-01, SHOW-02, SHOW-03, SHOW-04
**Success Criteria** (what must be TRUE):

  1. The family × domain demonstration matrix (Invoice/Statement/Receipt/Certificate/Payslip/Ticket across the named fictional businesses) is rendered via recipes + the escape hatch, each demo citing its `DOMAIN.md` and passing the rubric (hierarchy = 5, core ≥ 4, gates pass), with scores appended to the rubric manifest (seam S5).
  2. `guides/recipes.md`, `guides/branding.md`, `guides/livebook/first_invoice.livemd`, and `examples/phoenix_example` are updated to demonstrate the upgraded Invoice + new families against the realistic example library, with docs-contract claims bounded to evidence.
  3. `assets/rendro/gallery/` and `assets/rendro/artifacts.json` are regenerated via `mix rendro.launch_artifacts.gen` to realistic renders with matching SHA-256 hashes, and `artifacts.json` gains optional `theme`/`mode`/`preset` tags (seam S6) so Milestone C's grid needs no re-keying.
  4. `priv/support_matrix.json` and README are reconciled so every new family/claim is proof-backed and the milestone makes no tagged-PDF/PDF-UA accessibility claim ("production-grade" wording guarded).

**Plans**: TBD

<details>
<summary>✅ C1 CI/CD Performance & Reliability (Phases 108-113) — SHIPPED 2026-07-11</summary>

- [x] **Phase 108: Baseline & Audit Report** — measured current CI topology, critical path, test/check classes, and P0-P3 recommendations. (completed 2026-06-14)
- [x] **Phase 109: Caching & setup-beam Foundation** — added keyed deps, `_build`, and PLT caching with unified SHA-pinned setup-beam. (completed 2026-06-15)
- [x] **Phase 110: Test Concurrency, Determinism & Cleanup** — improved test concurrency, documented non-async reasons, and quarantined/fixed nondeterministic paths. (completed 2026-06-16)
- [x] **Phase 111: Workflow Topology, Triggers & Matrix** — rationalized CI jobs, triggers, matrix policy, PR cancellation, and the stable `ci-success` required gate. (completed 2026-06-16)
- [x] **Phase 112: Security, Supply-chain & Release Hardening** — pinned actions, configured Dependabot, separated advisory audits, and hardened release preflight behavior. (completed 2026-06-16)
- [x] **Phase 113: DX, Local Reproducibility & Validation** — added scoped local CI aliases, contributor docs, README badge, final metrics, and remote validation evidence. (completed 2026-07-10)

**Archive:** `milestones/C1-ROADMAP.md`, `milestones/C1-REQUIREMENTS.md`, `milestones/C1-MILESTONE-AUDIT.md`

**Validation:** passed. 30/30 requirements, 18/18 plans, 6/6 phases, three green remote `ci.yml` runs, `mix ci.fast` green locally with 1219 tests, 12 doctests, 4 properties, 0 failures.

</details>

<details>
<summary>✅ v2.9 TOC & Document Navigation (Phases 97-100) — SHIPPED 2026-06-14</summary>

- [x] **Phase 97: Location Tracking & Primitives** — established exact X/Y physical locations and bounds as a foundational engine primitive. (completed 2026-06-13)
- [x] **Phase 98: Document Outlines (Bookmarks)** — introduced native, declarative doubly-linked PDF outline serialization. (completed 2026-06-14)
- [x] **Phase 99: Cross-References & Validation** — added validated internal document links that point to explicit physical destinations. (completed 2026-06-14)
- [x] **Phase 100: Printable Table of Contents Primitive** — provided safe post-layout substitution tokens for visual Tables of Contents. (completed 2026-06-14)

</details>

## Progress

**Execution Order:** Phases execute in numeric order: 114 → 115 → 116 → 117 → 118

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 114. Domain research, rubric & example-data library | v2.10 | 7/7 | Complete    | 2026-07-11 |
| 115. Invoice anatomy + Format promotion + seams | v2.10 | 0/TBD | Not started | - |
| 116. New families — Payslip & Ticket | v2.10 | 0/TBD | Not started | - |
| 117. Edge-case stress matrix | v2.10 | 0/TBD | Not started | - |
| 118. Rubric-gated demos, gallery & docs closure | v2.10 | 0/TBD | Not started | - |
| 108. Baseline & Audit Report | C1 | 3/3 | Complete | 2026-06-14 |
| 109. Caching & setup-beam Foundation | C1 | 2/2 | Complete | 2026-06-15 |
| 110. Test Concurrency, Determinism & Cleanup | C1 | 3/3 | Complete | 2026-06-16 |
| 111. Workflow Topology, Triggers & Matrix | C1 | 3/3 | Complete | 2026-06-16 |
| 112. Security, Supply-chain & Release Hardening | C1 | 4/4 | Complete | 2026-06-16 |
| 113. DX, Local Reproducibility & Validation | C1 | 3/3 | Complete | 2026-07-10 |

## Current Focus

🚧 **v2.10 Realistic Business-Document Examples & Anatomy** (Phases 114-118) — planning. All 26 requirements mapped; ready to plan Phase 114 with `/gsd-plan-phase 114`.

## Planned Next — "Happy-Path Home Runs" program (dormant seeds)

A sequenced 4-milestone program to make rendro's business-document happy paths shine: realistic,
award-quality example documents; a full document theming/design-token system; style-genre presets + a
public example catalog; and an optional interactive theme studio. Milestone A (`SEED-002`) is now active
as v2.10. Remaining seeds live under `.planning/seeds/`. See all seeds: `/gsd-capture --list-seeds`.
Full program plan: `~/.claude/plans/btw-what-is-rendro-spicy-giraffe.md`.

| # | Milestone | Seed | Status |
|---|-----------|------|--------|
| A | Realistic Business-Document Examples & Anatomy (domain research + rubric, realistic fixtures, Invoice anatomy upgrade, Payslip + Ticket families) | `SEED-002` | 🚧 active as v2.10 (Phases 114-118) |
| B | Document Theming & Design-Token System (`Rendro.Theme`, light/dark, unbranded default) | `SEED-003` | dormant |
| C | Style-Genre Presets, Public Catalog & Static Configurator | `SEED-004` | dormant |
| D | Rendro Studio: optional mountable theme playground (LiveView) | `SEED-005` *(optional)* | dormant |

Dependency order: A → B → C → D. Each is a right-sized milestone; D is optional/deferrable.

# Roadmap: Rendro

**Phase numbering:** sequential and continuous across milestones (never restarts at 01). v2.5 closed at phase 82; v2.6 starts at phase 83.

## Milestones

- ✅ **v1.0 MVP** — deterministic core rendering (shipped)
- ✅ **v1.1 Layout Authoring** — templates/regions, pagination semantics (shipped)
- ✅ **v1.2 Typography & Assets** — deterministic typography, honest Unicode boundaries (shipped)
- ✅ **v1.3 Hex Release Readiness** — first public package boundary (shipped 2026-05-03)
- ✅ **v1.4 Async Delivery & Artifact Ops** — queued lifecycle, artifact metadata, integrations (shipped 2026-05-05)
- ✅ **v1.5 Validation & Trust Surfaces** — Poppler structural validation, support matrix (shipped 2026-05-05)
- ✅ **v1.8 Interactive PDF Forms** — Phases 45-47 (shipped 2026-05-05)
- ✅ **v1.9 Embedded Artifact Surfaces** — Phases 48-50 (shipped 2026-05-06)
- ✅ **v1.10 Protected Delivery Hooks** — Phases 51-54 (shipped 2026-05-06)
- ✅ **v2.0 Signature Fields & Signing Prep** — Phases 55-59 (shipped 2026-05-07)
- ✅ **v2.1 Cryptographic Signing** — Phases 60-63 (shipped 2026-05-07)
- ✅ **v2.2 Long-Lived Signatures** — Phases 64-67 (shipped 2026-05-08)
- ✅ **v2.3 Viewer Proof & Interop Closure** — Phases 68-72 (shipped 2026-05-29, tag v0.3.1)
- ✅ **v2.4 Batteries-Included Workflow & Adoption Closure** — Phases 73-77 (shipped 2026-05-30)
- ✅ **v2.5 1.0 Release Capstone** — Phases 78-82 (shipped 2026-06-05, hex tag 1.0.0)
- 🚧 **v2.6 Public Launch & Adoption Bootstrap** — Phases 83-88 (active)
- 💤 **v2.7 Global Text Shaping & Script Support** — conditional, only if v2.6 demand gate triggers

## Phases

<details>
<summary>✅ v1.0 – v2.5 (Phases 1-82) — SHIPPED</summary>

Earlier milestones are archived individually under `.planning/milestones/v[X.Y]-ROADMAP.md` with matching `-REQUIREMENTS.md` and (where present) `-MILESTONE-AUDIT.md`. See `.planning/MILESTONES.md` for the per-milestone accomplishment ledger. v2.5 (Phases 78-82) shipped 2026-06-05 — first public hex release (`1.0.0`), 16/16 requirements, archived in `milestones/v2.5-ROADMAP.md`.

</details>

### 🚧 v2.6 Public Launch & Adoption Bootstrap (Active)

**Milestone Goal:** Convert Rendro's proof-backed depth into its first real adopters — fix claim accuracy, polish visible output, build the deterministic raster toolchain, ship self-proving launch artifacts, execute a coordinated ecosystem launch, and define a concrete demand gate for conditional v2.7 global text shaping.

- [x] **Phase 83: Claim-Accuracy & Shaping Hygiene** - Make `harfbuzz_ex` optional, fix shaping bug, migrate off dead `unicode_data`, declare complex-script deferrals — restoring the "pure Elixir core" claim before any launch content ships (completed 2026-06-10)
- [x] **Phase 84: Drawn-Path Primitive & Visible Polish** - Declarative `%Rendro.Path{}` block element, opt-in table borders/rules/header-band, Certificate border frame, byte-determinism goldens (completed 2026-06-10)
- [ ] **Phase 85: Deterministic Raster Lane** - `Pdfium.render/2`, golden-PNG snapshot harness, advisory CI lane, honest `pdfium-render` evidence vocabulary (verification found gaps — 6/9 must-haves; gap closure pending)
- [ ] **Phase 86: Self-Proving Launch Artifacts** - CI-hash-checked visual recipe gallery in README/HexDocs, self-rendered `manual.pdf` with published SHA-256, brand-book-conformant presentation
- [ ] **Phase 87: Comparison Page & Livebook** - Reproducible benchmark harness vs ChromicPDF/pdf_generator/Typst-CLI, HexDocs comparison guide, CI-executed Livebook tutorial with badges
- [ ] **Phase 88: Launch Execution & Demand Instrumentation** - Coordinated ecosystem launch, mobile viewer evidence beat, concrete v2.7 shaping demand gate + ADOPTION.md ledger

## Phase Details

### Phase 83: Claim-Accuracy & Shaping Hygiene

**Goal**: The "pure Elixir core / no hard NIF dependencies" claim is restored to truth before any launch content ships — `harfbuzz_ex` is an optional dep behind a behaviour, complex scripts fail instructively, the shaping bug is fixed, and dead `unicode_data` is replaced.
**Depends on**: Nothing (first phase; must merge before Phase 88 executes)
**Requirements**: HYG-01, HYG-02, HYG-03, HYG-04, HYG-05
**Success Criteria** (what must be TRUE):

  1. A project that does not include `harfbuzz_ex` in its `mix.exs` can compile and render Latin-script PDFs without any NIF-compilation step — `mix.exs` lists `harfbuzz_ex` as `optional: true`.
  2. Rendering text in Arabic, Hebrew, Devanagari, or Thai with no shaping adapter configured raises a deterministic, instructive error that names the script and the fix — never silent wrong/disconnected glyph output.
  3. All existing Latin-script golden tests pass byte-identically (or are deliberately re-blessed with a changelog note) after the `split_graphemes` cluster-boundary fix and the `ex_unicode` migration.
  4. `priv/support_matrix.json` contains `explicit_deferral` rows for Arabic, Hebrew/RTL, Devanagari, and Thai with named reasons, and README/guide script-support claims align with those rows — no overclaim.

**Plans**: 5 plans

Plans:
**Wave 1**

- [x] 83-01-PLAN.md — Behaviour split: shaper.ex → behaviour + Shaper.Simple + Adapters.HarfBuzz, mix.exs dep flip

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 83-02-PLAN.md — Unicode migration: bidi.ex + ScriptTags helper (unicode_data → unicode)
- [x] 83-03-PLAN.md — Complex-script gate + measure.ex hard-match softening + error.ex clauses

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 83-04-PLAN.md — Cluster-boundary fix in split_graphemes + StreamData property test + re-bless event

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 83-05-PLAN.md — Support matrix rows, script_support_claims_test, API manifest regen, api_stability.md

### Phase 84: Drawn-Path Primitive & Visible Polish

**Goal**: A Phoenix engineer can author deterministic vector graphics via a declarative `%Rendro.Path{}` element, tables can opt in to borders and rules, and the Certificate recipe gains a decorative border frame — so the gallery shows visually compelling output.
**Depends on**: Nothing (parallel to 83; gallery depends on both 84 and 85)
**Requirements**: PATH-01, PATH-02, PATH-03, PATH-04
**Success Criteria** (what must be TRUE):

  1. A caller can declare `%Rendro.Path{ops: [{:rect, x, y, w, h}], stroke: %{color: {0, 0, 0}, width: 1.0}}` in a document and the rendered PDF contains the corresponding visible rectangle — verified by the raster lane's golden-PNG harness.
  2. Passing `borders: :all` (or equivalent) to a table renders visible cell rules in the PDF; omitting the option produces output byte-identical to today's borderless rendering.
  3. The Certificate recipe accepts a `border: true` (or `border: frame_opts`) option and renders a decorative frame at both A4 and US Letter sizes, with all coordinates derived from page geometry — zero hardcoded A4 numerics.
  4. The path surface has terminal `priv/support_matrix.json` rows and byte-determinism golden tests; transforms, clipping, and gradients are listed as explicit deferrals.

**Plans**: 5 plans
**UI hint**: yes

Plans:
**Wave 1**

- [x] 84-01-PLAN.md — Rendro.Color helper + %Rendro.Path{} struct + Wave 0 test stubs (RED state)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 84-02-PLAN.md — Path pipeline dispatch: measure clause + writer render_block + Rendro.path/2 builder + D-03 Text color retrofit

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 84-03-PLAN.md — Table borders: borders/border_style/header_fill fields + table_decoration draw-once collapse
- [x] 84-04-PLAN.md — Certificate border frame: validate_border! + :frame anchored region + sections + document

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 84-05-PLAN.md — Manifests: support_matrix path_primitive rows + public_api regen + ROADMAP D-05 correction

### Phase 85: Deterministic Raster Lane

**Goal**: `Rendro.Adapters.Pdfium` can rasterize PDFs to PNG and the project has a golden-PNG snapshot harness in CI that is advisory (never gates the four required engine lanes) and uses honest `pdfium-render` evidence vocabulary that cannot be conflated with GUI-viewer proof.
**Depends on**: Nothing (parallel to 83 and 84; Phase 86 depends on this)
**Requirements**: RAST-01, RAST-02, RAST-03
**Success Criteria** (what must be TRUE):

  1. `Rendro.Adapters.Pdfium.render/2` accepts a PDF binary and options (dpi, page range) and returns `{:ok, [png_binary]}` — with pdfium-cli pinned by version + sha256 in the project configuration.
  2. `mix test` includes a golden-PNG snapshot harness that compares rendered PNGs against committed ref hashes; the harness uses a hash-equality fast path and a pinned-CI-only bless command — refs generated only in the containerized environment, never on dev laptops.
  3. The raster advisory CI lane (`needs: []`, graph-disconnected) runs in CI but never gates the four required engine lanes (`signing-live-proof`, `long-lived-live-proof`, `release-proof`, `test`); a pdfium-cli download failure cannot block engine merges.
  4. `priv/support_matrix.json` and evidence files use `viewer_kind: "pdfium-render"` for raster evidence; a docs-contract guard prevents raster evidence from upgrading GUI-viewer claims (Adobe/Preview rows remain structural proxies).

**Plans**: 4 plans

Plans:
**Wave 1**

- [x] 85-01-PLAN.md — Wave 0 test scaffolding: pdfium_raster_snapshot_test.exs stubs, raster_claims_test.exs stubs, pdfium_pin.json, raster_refs/.gitkeep

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 85-02-PLAN.md — render/2 implementation in pdfium.ex + pdfium_test.exs render unit tests
- [x] 85-03-PLAN.md — Atomic dual-schema sync (viewer_kind enum + @viewer_kinds) + support_matrix.json raster section

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 85-04-PLAN.md — Advisory CI lane (raster-advisory) + guardrails registration + verify_docs.exs lane entry

### Phase 86: Self-Proving Launch Artifacts

**Goal**: Any evaluating engineer visiting the repo or HexDocs sees all five recipes as rendered images in the README and docs — images that are CI-hash-checked so they cannot drift; plus a `manual.pdf` generated by Rendro itself with its SHA-256 machine-published and CI-verified; all presentation conforming to the Rendro brand book.
**Depends on**: Phase 84 (path primitive needed for gallery polish), Phase 85 (raster lane needed to generate PNGs)
**Requirements**: GAL-01, GAL-02, GAL-03
**Success Criteria** (what must be TRUE):

  1. An evaluating engineer sees rendered recipe images for all five recipes (Invoice, BrandedInvoice, Statement, Receipt/Report, Certificate) in the README and HexDocs — not placeholder text or ASCII art.
  2. A docs-contract CI lane fails if the committed gallery images do not match hashes regenerated from the current engine — the gallery cannot silently drift.
  3. A `manual.pdf` generated by Rendro itself (exercising recipes, the path primitive, and page numbering) is committed or CI-fetchable; its SHA-256 is machine-published in the README/guide and CI-verified on every engine change so the hash cannot go stale.
  4. Gallery images and docs presentation conform to the Rendro brand book (`prompts/Rendro Brand Book.txt`) — typography, palette, and layout consistent with the brand before public launch.

**Plans**: TBD
**UI hint**: yes

### Phase 87: Comparison Page & Livebook

**Goal**: HexDocs contains a reproducible "PDFs in Elixir without Chrome" comparison guide whose every claim is bounded to checked-in benchmark results, and a Livebook tutorial that is executed in CI so it cannot rot — giving evaluating engineers honest signal and a zero-friction try path.
**Depends on**: Phase 83 (comparison claims must be based on accurate dependency facts — "pure Elixir core" must be true before the guide ships)
**Requirements**: CMP-01, CMP-02, CMP-03
**Success Criteria** (what must be TRUE):

  1. A checked-in benchmark harness (`bench/` scripts + committed results) measures cold start, memory, container image size, and dependency count vs ChromicPDF, pdf_generator, and Typst-CLI — with pinned versions, published hardware, and honest acknowledgment of where HTML→PDF wins.
  2. The HexDocs comparison guide has every claim bounded to committed benchmark results by a docs-contract test — a false claim or an unbounded claim fails CI.
  3. A `.livemd` Livebook tutorial (invoice data → render → inline Kino preview → download) runs in an advisory CI lane; the tutorial has "Run in Livebook" badges in HexDocs and the README; the advisory lane is graph-disconnected and never gates the four required engine lanes.

**Plans**: TBD

### Phase 88: Launch Execution & Demand Instrumentation

**Goal**: Rendro is visible to the Elixir community — the coordinated ecosystem launch is executed, existing demand threads are answered genuinely, mobile viewer evidence is published as a content beat, and the conditional v2.7 text-shaping demand gate is concrete, measurable, and recorded in an ADOPTION.md ledger.
**Depends on**: Phase 83 (claim accuracy must be true before announcing), Phase 84 (output must be visually polished), Phase 85 (raster evidence vocabulary in place), Phase 86 (launch artifacts exist), Phase 87 (comparison guide + Livebook exist)
**Requirements**: LNCH-01, LNCH-02, LNCH-03
**Success Criteria** (what must be TRUE):

  1. An ElixirForum #announcing thread, an ElixirStatus post, an awesome-elixir PR, and genuine replies in the two existing "PDF without Chromium" demand threads are published — only after all HYG/GAL/CMP requirements are shipped.
  2. 2-4 mobile viewer-evidence rows (iOS Files/Mail preview, Android default viewer x forms/signed surfaces) are recorded via the existing evidence recipe, published in `priv/support_matrix.json`, and referenced in launch content.
  3. An ADOPTION.md ledger exists with concrete, numeric signal thresholds for the v2.7 text-shaping demand gate (e.g., N non-self GitHub issues/asks, a downloads floor, first external contributor), and GitHub Discussions / issue templates route adopter needs to the ledger.

**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 78. Public API Surface Definition & Cleanup | v2.5 | 5/5 | Complete | 2026-05-30 |
| 79. Public API Contract Enforcement Lane | v2.5 | 3/3 | Complete | 2026-05-30 |
| 80. Stability Contract & Migration Docs | v2.5 | 4/4 | Complete | 2026-05-30 |
| 81. Release Hardening | v2.5 | 1/1 | Complete | 2026-06-05 |
| 82. 1.0.0 Consolidation & Publish | v2.5 | 3/3 | Complete | 2026-06-05 |
| 83. Claim-Accuracy & Shaping Hygiene | v2.6 | 5/5 | Complete    | 2026-06-10 |
| 84. Drawn-Path Primitive & Visible Polish | v2.6 | 5/5 | Complete   | 2026-06-10 |
| 85. Deterministic Raster Lane | v2.6 | 4/4 | Gaps Found | 2026-06-10 |
| 86. Self-Proving Launch Artifacts | v2.6 | 0/? | Not started | - |
| 87. Comparison Page & Livebook | v2.6 | 0/? | Not started | - |
| 88. Launch Execution & Demand Instrumentation | v2.6 | 0/? | Not started | - |

---
*v2.5 archived 2026-06-05 on milestone completion (Phases 78-82, 13 plans, 16/16 requirements, audit `passed`). v2.6 roadmap created 2026-06-10 (Phases 83-88, 21 requirements).*

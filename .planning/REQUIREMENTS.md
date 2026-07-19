# Requirements — v2.10 Realistic Business-Document Examples & Anatomy

**Milestone:** v2.10 (hex `1.1.0`, additive minor) · Milestone A of the Happy-Path Home Runs program (retargets `SEED-002`).
**Goal:** Close the toy→production gap for Rendro's business documents — a realistic example corpus, an additive Invoice anatomy upgrade, two new families (Payslip, Ticket), and a durable reader-quality rubric — without widening the deterministic core or the family-not-industry boundary.
**Research:** `.planning/research/milestone-a/SUMMARY.md` (+ `R1..R5-*.md`).
**Phases:** 114–118 (global numbering continues from C1's 113).

Legend: `[ ]` in scope for this milestone.

---

## Example-Data Library (EXL)

- [x] **EXL-01**: A shared realistic example-data library exists under `priv/examples/<domain>/<business>/<family>.json`, encoding the A0 domain language with real-shaped (fictional) businesses, addresses, terms, tax, and Decimal-safe money as strings (never JSON floats).
- [x] **EXL-02**: A `Rendro.Examples` loader (`lib/rendro/examples.ex`, `@moduledoc false`) reads fixtures for tests, the bench harness, guides, and Livebook, works for shipped consumers via `app_dir`, and is asserted **absent** from `priv/public_api.json` (stays out of the public tier).
- [x] **EXL-03**: A repo-only `priv/schemas/examples.schema.json` validates every fixture, enforced by a docs-contract lane folded into the required `test` job.
- [x] **EXL-04**: The single realistic invoice fixture is de-quarantined from `bench/comparison/fixtures/invoice_data.json` into the example library and the bench harness is repointed to it, with `mix rendro.comparison.check` staying green (the move is a provable no-op, money-string normalization committed separately).
- [x] **EXL-05**: `priv/examples/` ships in the Hex tarball as **text-only** (`.json`/`.md`/`.svg`), added to the `mix.exs` package allowlist + exact-allowlist tarball audit, with a raster-ban test mirroring `brand/`.
- [x] **EXL-06** *(seam S4)*: Each fixture's business is modeled with an **optional** `brand`/`logo` sub-object (empty/absent in this milestone) so Milestone C can add brand data without re-keying `priv/examples/`.

## Domain Research & Reader-Quality Rubric (RUB)

- [x] **RUB-01**: Each document domain has a co-located `DOMAIN.md` capturing its domain language (nouns/verbs/events), personas + JTBD (who reads it, in what context, and the ONE fact they need first), reading context, and layout/typographic conventions.
- [x] **RUB-02**: A reader-quality rubric is defined with 6 core 1–5 dimensions (information architecture; content hierarchy; domain-fit/least-surprise; reader affordances; typographic craft; restraint/cohesion) plus 2 pass/fail gates (reading-order, print-safety), each with concrete 1/3/4/5 anchors a non-designer can apply.
- [x] **RUB-03** *(seam S5)*: Rubric scores are recorded in a schema-backed, **appendable** manifest (`priv/quality/rubric_scores.json` + schema) with a docs-contract lane that enforces structure and the threshold arithmetic (hierarchy = 5, core ≥ 4, gates pass) — not the subjective score — so Milestone C's quality-ratchet only appends.

## Invoice Anatomy & Format (INV)

- [x] **INV-01**: `Rendro.Recipes.Invoice` accepts additive optional `:issuer`, `:customer`, `:due_date`, `:terms`, and `:totals`, rendering each only when present; the pre-upgrade toy call (`%{id:, date:, items:}`) renders byte-identically to before.
- [x] **INV-02**: Invoice money uses `%Decimal{}` routed through `Rendro.Format.money/1` (bare-number `price` still renders `"$#{price}"`); new money fields are Decimal-only and reject Floats instructively.
- [x] **INV-03**: A totals block renders only when `:totals` is supplied, is validated as a caller assertion via `Decimal.equal?/2` (mirroring Statement/Receipt), and is kept with the last table rows across a page break via `Recipes.Pagination`.
- [x] **INV-04**: `Rendro.Format` is promoted from `@moduledoc false` to the public **adapter** tier with a minimal surface (`money/1`, `date/1`, `label/1`), `@spec`s, a `public_api.json` entry, a migration note, and documentation that its formatted output may evolve; the public-API contract lane (incl. Phase-79 hidden set) passes.
- [x] **INV-05**: An additive `cell_align: :right` option on table cells/columns right-aligns tabular money; existing tables (no `cell_align`) render byte-identically.
- [x] **INV-06**: `Rendro.Recipes.Invoice.validate_data!/1` raises an instructive `ArgumentError` on malformed input instead of leaking `BadMapError`/`FunctionClauseError`, and never rejects a valid toy call.
- [x] **INV-07** *(seam S1)*: Invoice sections read colors through a private `palette(opts)` keyed on Milestone-B's locked color roles (`ink`/`muted`/`accent`/`on_accent`/`background`/`surface`/`rule`), defaulting to today's literals; no section inlines `{0,0,0}`. The `page_template/1` opts leak is closed via a `Keyword.take` whitelist while the top-level `opts` stays open for B's future `theme:`.

## New Families: Payslip & Ticket (FAM)

- [x] **FAM-01**: `Rendro.Recipes.Payslip` renders a production-grade payslip on the 3-rung pattern (`document/2` / `page_template/1` / `sections/2`) with net pay as the visual anchor, side-by-side earnings/deductions, and YTD totals; jurisdiction differences (e.g. PAYE/NI vs FICA/401k) are label **data**, not engine logic.
- [x] **FAM-02**: `Rendro.Recipes.Ticket` renders a fixed-box ticket/boarding-pass on the 3-rung pattern with seat/gate/section as the anchor, a boxed code-area + human-readable reference + perforation line, and an optional caller-supplied PNG code image; content overflow raises a typed error.
- [x] **FAM-03**: Both new recipes validate input as errors-as-product (instructive `ArgumentError`), read colors via the `palette(opts)` seam (S1), and are registered in `priv/public_api.json` (adapter tier) and `priv/support_matrix.json`.

## Edge-Case Stress Matrix (EDGE)

- [x] **EDGE-01**: Each family × stress dimension (text length/wrapping, line-item counts 0/1/few/page-boundary/60+, missing optional fields, numeric edges $0.00/negatives-as-parens/$1M+/cents-rounding/zero-qty, USD vs GBP/EUR + VAT vs sales-tax labels, pagination boundaries, A4 vs US Letter, odd/even running content) renders a deterministic golden artifact verified by SHA-256, with matching pdfium raster refs where applicable.
- [x] **EDGE-02**: Overflow (`:content_overflow`), a single row taller than the body, and RTL input each raise an instructive typed `Rendro.Error`/`ArgumentError` — never silent truncation or a leaked internal error.
- [ ] **EDGE-03**: Stress fixtures are exempt from the rubric beauty gate (they prove robustness, not aesthetics) and this exemption is explicit in the rubric manifest/tests.

## Demonstration Set, Gallery & Docs Closure (SHOW)

- [ ] **SHOW-01**: The family × domain demonstration matrix (Invoice/Statement/Receipt/Certificate/Payslip/Ticket across the named fictional businesses) is rendered via recipes + the escape hatch, each demo citing its `DOMAIN.md` and passing the rubric (hierarchy = 5, core ≥ 4, gates pass), with scores recorded in the rubric manifest.
- [ ] **SHOW-02**: `guides/recipes.md`, `guides/branding.md`, `guides/livebook/first_invoice.livemd`, and `examples/phoenix_example` are updated to demonstrate the upgraded Invoice + new families against the realistic example library, with docs-contract claims bounded to evidence.
- [ ] **SHOW-03**: `assets/rendro/gallery/` and `assets/rendro/artifacts.json` are regenerated via `mix rendro.launch_artifacts.gen` to realistic renders with matching SHA-256 hashes; `artifacts.json` gains optional `theme`/`mode`/`preset` tags (seam S6) so Milestone C's grid needs no re-keying.
- [ ] **SHOW-04**: `priv/support_matrix.json` and README are reconciled so every new family/claim is proof-backed and the milestone makes no tagged-PDF/PDF-UA accessibility claim ("production-grade" wording guarded).

---

## Future Requirements (deferred — later milestones of the program)

- **Milestone B (`SEED-003`)** — `Rendro.Theme` design-token system: semantic color roles, type-scale, light/dark, unbranded default; `theme:` threaded through the `palette(opts)` seam this milestone leaves open.
- **Milestone C (`SEED-004`)** — style-genre presets (`%Theme{}` values), curated `priv/fonts/`, the public example catalog as a standing quality-ratchet (reuses the S4 brand slot + S5 rubric manifest + S6 artifact tags), and the static client-side configurator + `mix rendro.gen.theme` codegen.
- **Milestone D (`SEED-005`, optional)** — Rendro Studio, an optional dev-only mountable LiveView theme playground.
- Additional data-flavor documents (quote/estimate, credit note, packing slip, remittance advice) remain **data flavors of existing families**, not new recipes.

## Out of Scope (explicit exclusions with reasoning)

- **Industry-vertical recipe modules** — industries are DATA + thin escape-hatch compositions; only family *anatomy* (an invoice having addresses/tax/totals) is a legit `lib/` change. A brand is never a module.
- **Making the engine locale-aware** — `Rendro.Format` and the core stay locale-free by construction; VAT-vs-sales-tax and payslip-jurisdiction differences are caller-supplied label/data, not core logic.
- **Tagged-PDF / PDF-UA / accessibility conformance claims** — Rendro does not emit a tagged reading-order tree; "production-grade" refers to information design, and no accessibility-conformance claim is made.
- **A live barcode/QR primitive** — Ticket uses a boxed code-area + human-readable reference + optional caller-supplied PNG; generating scannable codes is out of scope.
- **The theming/token system, presets, public catalog, configurator, and Studio** — deferred to Milestones B/C/D; this milestone only leaves clean forward-compat seams (S1/S4/S5/S6).
- **Real personal data** — all fixtures use fictional businesses/people; no real PII (Payslip especially).
- **Non-`Format` public-API expansion** — no new Tier-1 Stable surface; new recipes and `Format` land at the adapter/Evolving tier.

## Traceability

Every REQ-ID maps to exactly one phase. Coverage: **26/26 mapped**, no orphans, no duplicates.

| Requirement | Phase | Status |
|-------------|-------|--------|
| EXL-01 | Phase 114 | Complete |
| EXL-02 | Phase 114 | Complete |
| EXL-03 | Phase 114 | Complete |
| EXL-04 | Phase 114 | Complete |
| EXL-05 | Phase 114 | Complete |
| EXL-06 | Phase 114 | Complete |
| RUB-01 | Phase 114 | Complete |
| RUB-02 | Phase 114 | Complete |
| RUB-03 | Phase 114 | Complete |
| INV-01 | Phase 115 | Complete |
| INV-02 | Phase 115 | Complete |
| INV-03 | Phase 115 | Complete |
| INV-04 | Phase 115 | Complete |
| INV-05 | Phase 115 | Complete |
| INV-06 | Phase 115 | Complete |
| INV-07 | Phase 115 | Complete |
| FAM-01 | Phase 116 | Complete |
| FAM-02 | Phase 116 | Complete |
| FAM-03 | Phase 116 | Complete |
| EDGE-01 | Phase 117 | Complete |
| EDGE-02 | Phase 117 | Complete |
| EDGE-03 | Phase 117 | Pending |
| SHOW-01 | Phase 118 | Pending |
| SHOW-02 | Phase 118 | Pending |
| SHOW-03 | Phase 118 | Pending |
| SHOW-04 | Phase 118 | Pending |

**Coverage by phase:** 114 → 9 reqs (EXL-01..06, RUB-01..03) · 115 → 7 reqs (INV-01..07) · 116 → 3 reqs (FAM-01..03) · 117 → 3 reqs (EDGE-01..03) · 118 → 4 reqs (SHOW-01..04).

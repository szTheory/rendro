# Roadmap: Rendro

**Phase numbering:** sequential and continuous across milestones (never restarts at 01). v2.3 closed at phase 72; v2.4 continues from phase 73.

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
- ✅ **v2.3 Viewer Proof & Interop Closure** — Phases 68-72 (shipped 2026-05-29)
- 📋 **v2.4 Batteries-Included Workflow & Adoption Closure** — Phases 73-77 (active)

## Phases

<details>
<summary>✅ v2.3 Viewer Proof & Interop Closure (Phases 68-72) — SHIPPED 2026-05-29</summary>

- [x] Phase 68: Viewer Evidence Schema, Mix Task, and Docs-Contract Lane (3/3 plans) — completed 2026-05-28
- [x] Phase 69: Operator Recipe + First Cell End-to-End (3/3 plans) — completed 2026-05-28
- [x] Phase 70: Consolidate Already-Validated Surfaces (3/3 plans) — completed 2026-05-29
- [x] Phase 71: Record New Trust-Sensitive Surfaces and Explicit Deferrals (3/3 plans) — completed 2026-05-29
- [x] Phase 72: Closure — Audit, Polish, and Ship (3/3 plans) — completed 2026-05-29

**Outcome:** All 26 (surface × viewer) cells terminal — 17 supported (each with a resolvable `evidence:` pointer), 9 explicit_deferral (each named), 0 silently unverified. Operator-grade recipe (`guides/viewer_evidence.md`), schema validator, `mix rendro.viewer_evidence` task, and the 8th docs-contract lane shipped and wired into the required `test` job. Engine-level trust spine verified unchanged via live branch-protection audit. Shipped at v0.3.1.

Full detail: `.planning/milestones/v2.3-ROADMAP.md` · Requirements: `.planning/milestones/v2.3-REQUIREMENTS.md` · Audit: `.planning/milestones/v2.3-MILESTONE-AUDIT.md`

</details>

<details>
<summary>✅ v1.0 – v2.2 (Phases 1-67) — SHIPPED</summary>

Earlier milestones are archived individually under `.planning/milestones/v[X.Y]-ROADMAP.md` with matching `-REQUIREMENTS.md` and (where present) `-MILESTONE-AUDIT.md`. See `.planning/MILESTONES.md` for the per-milestone accomplishment ledger.

</details>

### 📋 v2.4 Batteries-Included Workflow & Adoption Closure (Phases 73-77)

- [x] **Phase 73: Page-Numbering / Running-Region Primitive** - Foundational: fix body_capacity, ship single-pass page-number token substitution, determinism proof (completed 2026-05-29)
- [x] **Phase 74: Statement Recipe** - First end-to-end exercise of PAGE primitive; carried-forward totals in data assembly; three-rung escape hatch (completed 2026-05-29)
- [x] **Phase 75: Receipt/Report and Certificate Recipes + Support Contract** - Batched lower-complexity recipes; support-matrix rows for all new surfaces (completed 2026-05-29)
- [x] **Phase 76: Reference Phoenix App, CI, and Documentation Closure** - Isolated CI job; all recipes demonstrated; HexDocs guides; docs-contract tests (completed 2026-05-29)
- [x] **Phase 77: v2.4 Closure — Format Gate, Nyquist Drafts, Recipe Input-Validation Polish** - Audit-discovered cleanup: green the `mix ci` format gate, fill Nyquist VALIDATION drafts (73/74/75), structured `ArgumentError` validation across recipes (added 2026-05-29) (completed 2026-05-30)

## Phase Details

### Phase 73: Page-Numbering / Running-Region Primitive

**Goal**: Running header/footer regions with deterministic "Page X of Y" substitution are a proven, tested engine capability — body content never overlaps footers, and the layout-fix prerequisite is closed
**Depends on**: Nothing (first phase of v2.4)
**Requirements**: PAGE-01, PAGE-02, PAGE-03, PAGE-04
**Success Criteria** (what must be TRUE):

  1. A document with a running footer containing `{{page_number}}` and `{{total_pages}}` renders the correct page number and real total on every page in a single pipeline pass
  2. A running footer with non-zero height does not overlap the last body lines on any page — `body_capacity` subtracts all non-body region heights
  3. Running region content can be authored as a named helper (`Rendro.page_number/1`-style) or a raw `fn {page, total} -> ... end`, and can be suppressed on specific pages (e.g. first page)
  4. Rendering the same document twice with `deterministic: true` produces byte-identical output — no non-determinism introduced by running-region substitution

**Plans**: 5 plans

**Wave 1**

- [x] 73-01-PLAN.md — Wave 0 test scaffolding: all failing stubs for PAGE-01..04 (RED state)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 73-02-PLAN.md — body_capacity fix: measure.ex primary site + paginate.ex flow_layout fallback (PAGE-03)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 73-03-PLAN.md — replace_page_numbers/3 extension + total threading single-pass (PAGE-01)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 73-04-PLAN.md — fn primitive + suppress_on selector + page_number/1 helper (PAGE-02)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 73-05-PLAN.md — D-11 four-property determinism assertions; full suite green (PAGE-04)

---

### Phase 74: Statement Recipe

**Goal**: A caller with account transaction data can generate a multi-page billing statement with correct "Page X of Y" footers and carried-forward / brought-forward balances — all via `Rendro.Recipes.Statement`
**Depends on**: Phase 73
**Requirements**: STMT-01, STMT-02, STMT-03, STMT-04
**Success Criteria** (what must be TRUE):

  1. `Rendro.Recipes.Statement.document/2` accepts a data map (period, opening/closing balance, transaction lines) and returns a renderable document — runnable from data alone, no template authoring required
  2. A statement spanning multiple pages shows a correct carried-forward balance at the bottom of each page and a brought-forward balance at the top of the next page, pre-computed in `sections/2` (not in the engine)
  3. The three-rung escape hatch (`document/2`, `page_template/1`, `sections/2`) is available and consistent with `Rendro.Recipes.Invoice` — callers can override at any rung without touching the rungs above
  4. "Page X of Y" appears in the running footer using the Phase 73 PAGE primitive, and the page count is correct on every page including the last

**Plans**: 4 plans

**Wave 1** *(parallel — no file overlap)*

- [x] 74-01-PLAN.md — Engine enablers: declare `:decimal` core dep (D-04) + read-only `Rendro.measure_rows/4` measurement helper (D-09)
- [x] 74-02-PLAN.md — Pure deterministic `Rendro.Format` — money/date/labels, no CLDR/locale (D-11)

**Wave 2** *(blocked on Wave 1)*

- [x] 74-03-PLAN.md — Statement recipe core: three-rung skeleton, `validate_data!/1`, Decimal balance fold, non-zero footer with PAGE primitive (STMT-01/03/04, D-03/D-05..D-08)

**Wave 3** *(blocked on Wave 2)*

- [x] 74-04-PLAN.md — Recipe-owned per-page chunking + carried/brought-forward rows + full V1..V10 / determinism / overflow test suite (STMT-02, D-01/D-02/D-09/D-10)

---

### Phase 75: Receipt/Report and Certificate Recipes + Support Contract

**Goal**: Callers can generate payment receipts, tabular operational reports, and completion certificates from data; every new public surface (PAGE primitive, Statement, Receipt, Report, Certificate) has a terminal support-matrix row — either recorded proof or a named explicit_deferral
**Depends on**: Phase 73 (for RCPT running footers); Phase 74 (for Recipes.Base extraction)
**Requirements**: RCPT-01, RCPT-02, RCPT-03, CERT-01, CERT-02, CERT-03, CONTRACT-01
**Success Criteria** (what must be TRUE):

  1. `Rendro.Recipes.Receipt.document/2` (or equivalent) accepts a data map (header summary, line items, totals) and returns a renderable receipt or tabular report; table column headers repeat across pages and "Page X of Y" appears in the running footer on multi-page reports
  2. `Rendro.Recipes.Certificate.document/2` accepts a data map (title, recipient, body statement, issue date, signature/seal line) and returns a renderable certificate with all element coordinates derived from template geometry — not hardcoded A4 numerics; the recipe renders correctly at both A4 and US Letter (verified by a multi-size test)
  3. Certificate supports branded output (registered fonts/images) consistent with `Rendro.Recipes.BrandedInvoice`
  4. Receipt/Report and Certificate each support the three-rung escape hatch consistent with `Rendro.Recipes.Invoice`
  5. Every new public surface (running-header, running-footer, Statement, Receipt/Report, Certificate) has a `priv/support_matrix.json` row in terminal state — `supported` with a resolvable evidence pointer, or `explicit_deferral` with a named viewer-behavior reason; no surface ships as silent `unverified`

**Plans**: 4 plans

**Wave 1**

- [x] 75-01-PLAN.md — D-04 shared pagination helper (Rendro.Recipes.Pagination) + D-07 page-size helper (Rendro.PageSize) + Statement refactor + regression gate (51 tests)

**Wave 2** *(parallel — no file overlap; blocked on Wave 1)*

- [x] 75-02-PLAN.md — Receipt recipe: three-rung, validate_data!/1, body chunking via Pagination helper, totals, "Page X of Y" footer (RCPT-01/02/03)
- [x] 75-03-PLAN.md — Certificate recipe: geometry-derived layout, landscape default, optional branding, multi-size test (CERT-01/02/03)

**Wave 3** *(blocked on Wave 2)*

- [x] 75-04-PLAN.md — Support-matrix rows for all 5 surfaces (page_numbering, statement backfill, receipt_report, certificate) + mix.exs Canonical Recipes group + full suite gate (CONTRACT-01)

---

### Phase 76: Reference Phoenix App, CI, and Documentation Closure

**Goal**: A Phoenix engineer arriving at the repository can run the reference app locally, read a guide for each recipe in HexDocs, and see CI prove the example is exercised — all without touching engine-critical proof lanes
**Depends on**: Phase 75
**Requirements**: REF-01, REF-02, REF-03, CONTRACT-02
**Success Criteria** (what must be TRUE):

  1. `examples/phoenix_example` is `mix`-runnable (`mix deps.get && mix phx.server`) with a README documenting setup, each recipe demonstrated via `Rendro.Adapters.Phoenix`, and non-stale dependency constraints (Phoenix `~> 1.8`, Jason `~> 1.4`, Elixir `~> 1.19`)
  2. The reference app demonstrates all five shipped recipes (Invoice, BrandedInvoice, Statement, Receipt/Report, Certificate) via `Rendro.Adapters.Phoenix`
  3. An isolated `example-phoenix` CI job runs `mix test` against the reference app; its success or failure is visible independently and it is NOT a required branch-protection check — a Phoenix-dependency failure never blocks `signing-live-proof`, `long-lived-live-proof`, `release-proof`, or `test`
  4. Each new public surface (PAGE primitive and each recipe) has a guide wired into HexDocs extras, and docs-contract tests reject any guide language that claims beyond what `priv/support_matrix.json` and proof lanes cover

**Plans**: 4 plans

**Wave 1** *(parallel — disjoint file sets)*

- [x] 76-01-PLAN.md — App modernization: dep floors (Phoenix ~>1.8 / plug ~>1.18 / jason ~>1.4 / elixir ~>1.19), ErrorJSON load-bearing fix, README (REF-01)
- [x] 76-03-PLAN.md — CI isolation: graph-disconnected advisory `example-phoenix` job, remove redundant test step, guardrail manifest + contract test (advisory `Enum.find`, lane count 8→10) (REF-03)
- [x] 76-04-PLAN.md — Guides + docs-contract: `guides/page_primitive.md` + `guides/recipes.md`, ExDoc wiring, 3 docs-contract tests, 2 verify_docs lanes (CONTRACT-02)

**Wave 2** *(blocked on 76-01 — shares example-app boot)*

- [x] 76-02-PLAN.md — Recipe demonstration surface: 3 fixtures + 6 actions + 6 routes + chooser links + per-recipe ConnCase/structural tests (Certificate single-region) (REF-02)

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 73. Page-Numbering / Running-Region Primitive | 5/5 | Complete    | 2026-05-29 |
| 74. Statement Recipe | 4/4 | Complete    | 2026-05-29 |
| 75. Receipt/Report and Certificate Recipes + Support Contract | 4/4 | Complete    | 2026-05-29 |
| 76. Reference Phoenix App, CI, and Documentation Closure | 4/4 | Complete    | 2026-05-29 |
| 77. v2.4 Closure — Format Gate, Nyquist Drafts, Input-Validation Polish | 4/4 | Complete   | 2026-05-30 |

### Phase 77: v2.4 Closure — Format Gate, Nyquist Drafts, Recipe Input-Validation Polish

**Goal:** The v2.4 milestone is shippable with no outstanding hygiene blockers — the required `test` CI lane is green (no `mix ci` format failures), the audit-discovered working-tree changes are resolved, Phases 73/74/75 carry completed Nyquist VALIDATION records, and the new recipes raise structured `ArgumentError`s on malformed input instead of raw `BadMapError`/`FunctionClauseError`.
**Depends on:** Phase 76
**Requirements**: None new (closure phase — addresses v2.4-MILESTONE-AUDIT.md tech debt; no new REQ-IDs)
**Source:** `.planning/v2.4-MILESTONE-AUDIT.md` (audited 2026-05-29)
**Success Criteria** (what must be TRUE):

  1. `mix ci` passes from a clean tree — `mix format --check-formatted` reports no unformatted files (currently fails on `test/docs_contract/recipes_claims_test.exs` and `test/guardrails/required_checks_contract_test.exs`), so the required `test` branch-protection lane is green
  2. The audit-flagged uncommitted working-tree changes (`paginate.ex`, `deterministic_test.exs`, `statement_test.exs`, `guides/recipes.md`, untracked `guides/user_flows_and_jtbd.md`) are reviewed and either committed with intent or reverted — no stray milestone drift remains
  3. Phases 73, 74, and 75 have `nyquist_compliant: true` VALIDATION.md records (currently unfilled drafts); run `/gsd-validate-phase` for each rather than hand-editing
  4. Statement, Receipt, and Certificate raise structured `ArgumentError` (not `BadMapError`/`FunctionClauseError`) for malformed `:account`/`:customer`, non-`%Date{}` `:date`, and non-binary `:body` (closes 74 WARNINGs + 75 WR-01..06); cosmetic dead bindings and misleading comments cleaned up

**Plans:** 4/4 plans complete
Plans:
**Wave 1**

- [x] 77-01-PLAN.md — Recipe input-validation (structured ArgumentError for Statement :account, Receipt :customer/:date, Certificate :date/:body) + D-09 cosmetic cleanup + negative-path tests (D-05..D-09)
- [x] 77-02-PLAN.md — Wire untracked JTBD guide into ExDoc extras/groups_for_extras, keep within support matrix (D-02/D-03)
- [x] 77-03-PLAN.md — Fill 73/74/75 Nyquist VALIDATION drafts via top-level /gsd-validate-phase runs (autonomous: false) (D-04)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 77-04-PLAN.md — Terminal gate: format offenders + final mix format + full suite + commit working-tree changes with intent + prove clean-tree mix ci format gate green (D-01/D-02/D-10)

---
*v2.3 archived 2026-05-29 on milestone completion. v2.4 roadmap created 2026-05-29. Phase numbering: 73-77 (Phase 77 added 2026-05-29 from v2.4 milestone audit).*

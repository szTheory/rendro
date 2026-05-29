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
- 📋 **v2.4 Batteries-Included Workflow & Adoption Closure** — Phases 73-76 (active)

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

### 📋 v2.4 Batteries-Included Workflow & Adoption Closure (Phases 73-76)

- [ ] **Phase 73: Page-Numbering / Running-Region Primitive** - Foundational: fix body_capacity, ship single-pass page-number token substitution, determinism proof
- [ ] **Phase 74: Statement Recipe** - First end-to-end exercise of PAGE primitive; carried-forward totals in data assembly; three-rung escape hatch
- [ ] **Phase 75: Receipt/Report and Certificate Recipes + Support Contract** - Batched lower-complexity recipes; support-matrix rows for all new surfaces
- [ ] **Phase 76: Reference Phoenix App, CI, and Documentation Closure** - Isolated CI job; all recipes demonstrated; HexDocs guides; docs-contract tests

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

**Plans**: 5 plansPlans:
**Wave 1**

- [x] 73-01-PLAN.md — Wave 0 test scaffolding: all failing stubs for PAGE-01..04 (RED state)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 73-02-PLAN.md — body_capacity fix: measure.ex primary site + paginate.ex flow_layout fallback (PAGE-03)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 73-03-PLAN.md — replace_page_numbers/3 extension + total threading single-pass (PAGE-01)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 73-04-PLAN.md — fn primitive + suppress_on selector + page_number/1 helper (PAGE-02)

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 73-05-PLAN.md — D-11 four-property determinism assertions; full suite green (PAGE-04)

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

**Plans**: TBD

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

**Plans**: TBD
**UI hint**: yes

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

**Plans**: TBD

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 73. Page-Numbering / Running-Region Primitive | 4/5 | In Progress|  |
| 74. Statement Recipe | 0/? | Not started | - |
| 75. Receipt/Report and Certificate Recipes + Support Contract | 0/? | Not started | - |
| 76. Reference Phoenix App, CI, and Documentation Closure | 0/? | Not started | - |

---
*v2.3 archived 2026-05-29 on milestone completion. v2.4 roadmap created 2026-05-29. Phase numbering: 73-76.*

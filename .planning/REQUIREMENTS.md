# Requirements: Rendro — v2.4 Batteries-Included Workflow & Adoption Closure

**Defined:** 2026-05-29
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

> Scope confirmed 2026-05-29. Backed by `.planning/research/SUMMARY.md` (HIGH confidence, code-grounded). All features implementable with **zero new runtime Hex dependencies**. Build order: page-numbering primitive (foundational) → recipes → reference app. New surfaces inherit the v2.3 viewer-evidence discipline.

## v1 Requirements

Requirements for the v2.4 milestone. Each maps to exactly one roadmap phase.

### Page Numbering & Running Regions (PAGE)

The foundational primitive. Must ship before any multi-page recipe depends on it.

- [x] **PAGE-01**: User can place a deterministic "Page X of Y" in a running region of any flow document, where Y resolves to the real total page count (single-pass; no second render).
- [x] **PAGE-02**: User can define running header/footer region content as a function of `{page_number, total_pages}` — with a named helper (`Rendro.page_number/1`-style) for the common case and acceptance of a raw `fn {page, total} -> ... end`, enabling per-page variation (e.g. suppress on first page).
- [x] **PAGE-03**: Running header/footer regions reserve their height so body content never overlaps them — `body_capacity` subtracts header/footer region heights in flow layout (prerequisite bug fix).
- [x] **PAGE-04**: Running-region and page-number output is deterministic and test-covered — identical inputs produce byte-identical output, with no layout-convergence loop.

### Statement Recipe (STMT)

- [x] **STMT-01**: User can generate an account/billing statement from a data map via `Rendro.Recipes.Statement.document/2` (statement period, opening/closing balance, transaction lines, summary).
- [x] **STMT-02**: Statement paginates across multiple pages with carried-forward / brought-forward running balance computed in data-assembly (`sections/2`), deterministic and correct across page breaks.
- [x] **STMT-03**: Statement supports the three-rung escape hatch (`document/2`, `page_template/1`, `sections/2`) consistent with `Rendro.Recipes.Invoice`.
- [x] **STMT-04**: Statement uses the PAGE primitive for "Page X of Y" running footers.

### Receipt / Report Recipe (RCPT)

- [x] **RCPT-01**: User can generate a payment receipt / tabular operational report from a data map via a `Rendro.Recipes.*` recipe (header summary, line items, totals).
- [x] **RCPT-02**: Receipt/Report supports the three-rung escape hatch consistent with `Rendro.Recipes.Invoice`.
- [x] **RCPT-03**: Receipt/Report exercises table continuation with running footers across multiple pages, deterministically.

### Certificate Recipe (CERT)

- [x] **CERT-01**: User can generate a completion/compliance certificate from a data map via `Rendro.Recipes.Certificate.document/2` (title, recipient, body statement, issue date, signature/seal line).
- [x] **CERT-02**: Certificate derives all element coordinates from template geometry — page size is a parameter (with a sensible default), no hardcoded A4 — and renders correctly at multiple page sizes (multi-size test is an exit criterion).
- [x] **CERT-03**: Certificate supports branded output (registered fonts/images) consistent with `Rendro.Recipes.BrandedInvoice`.

### Reference Phoenix App & CI (REF)

- [x] **REF-01**: The reference Phoenix app (`examples/phoenix_example`) is `mix`-runnable with a README documenting setup and each demonstrated recipe, on current, non-stale dependency constraints.
- [ ] **REF-02**: The reference app demonstrates the shipped recipes (Invoice, BrandedInvoice, Statement, Receipt/Report, Certificate) through `Rendro.Adapters.Phoenix`.
- [x] **REF-03**: The reference app is exercised in CI via an **isolated** `example-phoenix` job running `mix test` — kept off the required branch-protection checks so Phoenix-dependency failures never block the engine-critical lanes (`signing-live-proof`, `long-lived-live-proof`, `release-proof`, `test`).

### Support Contract & Documentation Honesty (CONTRACT)

Cross-cutting; closes out alongside the surfaces it covers.

- [x] **CONTRACT-01**: Each new public surface (PAGE primitive and each recipe) has a `priv/support_matrix.json` row; any unproven viewer behavior is recorded as `explicit_deferral` with a named reason — never silent `unverified` (inherits the v2.3 discipline).
- [x] **CONTRACT-02**: The PAGE primitive and each new recipe are documented in guides wired into HexDocs, and docs-contract tests reject claims beyond what proof and the support matrix cover.

## v2 Requirements

Deferred to future release. Tracked but not in the current roadmap.

### 1.0 Capstone (POST-v2.4)

- **REL-01**: Cut the 1.0 release — SemVer/API-stability commitment plus a migration note — as the capstone after v2.4 adoption closure.

### Globalization (conditional v2.5)

- **GLOBAL-01**: Global text shaping, RTL support, and broader complex-script coverage — only if demand justifies the core investment.

## Out of Scope

Explicitly excluded for v2.4. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Engine-level stateful running-total accumulator / `on_page_break` callbacks | Would make the engine stateful and threaten determinism; carried totals belong in recipe data-assembly |
| Reserved-width `{{total_pages}}` placeholder / `max_pages:` hint | Substitution is post-layout; width is already frozen, so no convergence risk to mitigate |
| Table of contents / forward-reference cross-paging | Multi-pass forward-reference problem; out of the narrow-surface bias |
| Magic-string substitution inside arbitrary text blocks | Only curated running-region tokens are supported; arbitrary substitution widens surface and breaks determinism guarantees |
| WYSIWYG / theme gallery / config-soup recipe options | Violates Rendro's narrow-surface design; recipes stay composition-first like BrandedInvoice |
| New viewer/mobile proof, signing adapters, stricter staleness cadence | Proof axis is at diminishing returns; do not re-deepen without pulled adopter demand |
| Multi-signature workflows, HSM orchestration, global text shaping | Adjacent scope; must not leak into adoption work |
| Making the reference-app CI job a required branch-protection check | Would couple Phoenix-dependency failures to engine-critical merge gates |

## Traceability

Which phases cover which requirements. Updated on roadmap creation 2026-05-29.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PAGE-01 | Phase 73 | Complete |
| PAGE-02 | Phase 73 | Complete |
| PAGE-03 | Phase 73 | Complete |
| PAGE-04 | Phase 73 | Complete |
| STMT-01 | Phase 74 | Complete |
| STMT-02 | Phase 74 | Complete |
| STMT-03 | Phase 74 | Complete |
| STMT-04 | Phase 74 | Complete |
| RCPT-01 | Phase 75 | Complete |
| RCPT-02 | Phase 75 | Complete |
| RCPT-03 | Phase 75 | Complete |
| CERT-01 | Phase 75 | Complete |
| CERT-02 | Phase 75 | Complete |
| CERT-03 | Phase 75 | Complete |
| CONTRACT-01 | Phase 75 | Complete |
| REF-01 | Phase 76 | Complete |
| REF-02 | Phase 76 | Pending |
| REF-03 | Phase 76 | Complete |
| CONTRACT-02 | Phase 76 | Complete |

**Coverage:**
- v1 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-29*
*Last updated: 2026-05-29 — traceability populated on roadmap creation for milestone v2.4*

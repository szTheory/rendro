# Requirements: Rendro — v2.8 Done-Enough Stewardship & Adoption Signal Loop

**Defined:** 2026-06-13
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

This is a stewardship milestone. The goal is to reduce maintainer/adopter friction and keep the public posture truthful while demand accumulates, **without widening product scope**. Requirements are scoped to cleanup, proof-depth parity, DX closure, metadata reconciliation, and a pull-based adoption review — not new capability families.

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase.

### Warning & Debt Hygiene

- [x] **HYG-01**: A maintainer building the docs sees a clean ExDoc warning posture — known hidden-internal (`@moduledoc false` / `@doc false`) reference warnings are eliminated, or each remaining warning is deliberately documented with a reason in a maintainer-visible note.
- [x] **HYG-02**: Stale viewer-evidence warning noise is resolved or explicitly documented so routine `mix` / verification output no longer emits unexplained viewer-evidence warnings.

### Header Duplex Proof Depth

- [x] **PROOF-01**: A direct end-to-end test renders header-specific `only_on: :odd | :even` running content and asserts the header appears only on the correct physical pages, bringing header odd/even proof depth to parity with the footer coverage shipped in v2.7.

### Recipes Facade DX

- [x] **DX-01**: `Rendro.Recipes` exposes Statement, Receipt/Report, and Certificate through the same facade that already delegates Invoice and BrandedInvoice, so callers can reach every shipped recipe from one module.
- [x] **DX-02**: A test asserts each shipped recipe (Invoice, BrandedInvoice, Statement, Receipt/Report, Certificate) is reachable and renders through the `Rendro.Recipes` facade, preventing future facade/recipe drift.

### Validation Metadata Cleanup

- [x] **META-01**: Stale v2.6/v2.7 phase validation-history / Nyquist metadata is reconciled so recorded phase metadata matches the already-passed milestone audit status, with no false-incomplete or false-pending markers remaining.

### Adoption Signal Review

- [ ] **SIGNAL-01**: A lightweight, dated adoption-signal review records whether `ADOPTION.md` shows qualifying text-shaping demand, download/version movement, or contributor signal, and produces an explicit recommendation on whether any large demand-gated capability is now justified.

### Maintainer Posture & Docs

- [ ] **STEW-01**: Maintainer-facing docs/state record that Rendro is near-done for its current product scope and that proof/viewer work should not deepen by default, so future planning cycles inherit the done-enough posture and its named non-goals.

## v2 Requirements

Deferred to future milestones. Tracked, not in this roadmap. All remain demand-gated.

### Demand-Gated Capabilities

- **SHAPE-01**: Global text shaping & script support (HarfBuzz-backed shaping, RTL/bidi, script-specific support rows) — only after the `ADOPTION.md` gate triggers.
- **NAV-01**: Larger report navigation (TOC, PDF outlines, anchors, cross-references) — only after concrete long-report adopter pressure.
- **MOBILE-01**: Mobile GUI viewer proof — only with a real adopter need and a feasible automated device-level evidence lane.

## Out of Scope

Explicitly excluded for v2.8. Documented to prevent scope creep during a stewardship cycle.

| Feature | Reason |
|---------|--------|
| Global text shaping implementation | Multi-quarter core investment; `ADOPTION.md` records zero qualifying demand signals — stewardship milestones must not open it. |
| TOC / outlines / anchors / cross-references | No concrete long-report adopter pressure; needs an anchor registry and no-fixpoint design, not stewardship work. |
| Charts (`%Rendro.Chart{}`) | Separate authoring/proof surface; not adopter-blocking. |
| Existing-PDF editing / HTML/CSS rendering | Out of the deterministic authored-document product identity. |
| Mobile GUI viewer promotion | Mobile rows are terminal `explicit_deferral`; no automated device evidence lane exists. |
| release-please / publish automation | BEAM norm is manual/semi-manual; adds credential risk for little gain absent concrete release friction. |
| Proactive launch/outreach obligations | Public posture stays quiet and pull-based unless the maintainer explicitly opts in. |

## Traceability

Which phases cover which requirements.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DX-01 | Phase 93 | Complete |
| DX-02 | Phase 93 | Complete |
| HYG-01 | Phase 94 | Complete |
| HYG-02 | Phase 94 | Complete |
| PROOF-01 | Phase 95 | Complete |
| META-01 | Phase 95 | Complete |
| SIGNAL-01 | Phase 96 | Pending |
| STEW-01 | Phase 96 | Pending |

**Coverage:**
- v1 requirements: 8 total
- Mapped to phases: 8 ✓
- Unmapped: 0

---
*Requirements defined: 2026-06-13*
*Last updated: 2026-06-13 after v2.8 roadmap creation (Phases 93-96)*

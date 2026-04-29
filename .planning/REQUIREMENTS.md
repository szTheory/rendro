# Requirements: Rendro v1.1 Layout Authoring Maturity

**Defined:** 2026-04-28
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## v1 Requirements

### Text and Flow Semantics

- [x] **LAY-06**: Engineer can author wrapped text inside width-constrained flow regions with deterministic line-breaking behavior.
- [x] **LAY-07**: Engineer can define flow documents against explicit page templates with configurable geometry and anchored header/footer regions.
- [x] **LAY-08**: Engineer can compose reusable sections or bounded layout regions without dropping down to raw page coordinates for every document.
- [x] **LAY-09**: Engineer can control pagination through explicit keep/break directives such as `keep_together`, `keep_with_next`, and break-before/after rules.

### Table Layout

- [ ] **LAY-10**: Engineer can render multi-page tables with deterministic column sizing, repeated headers, and explicit row-split behavior suited to invoices and reports.

### Diagnostics and Verification

- [x] **LAY-11**: Engineer receives truthful fit validation when authored fixed-position or flow-region content cannot fit the declared page/layout bounds.
- [ ] **OBS-05**: Operator can inspect structured diagnostics that explain why content moved, split, or overflowed during pagination.
- [ ] **QUAL-06**: Maintainer can verify pagination invariants and deterministic break decisions with committed regression fixtures and docs-contract proof.

### Recipes and Authoring Ergonomics

- [ ] **LAY-12**: Engineer can use canonical recipes/examples that demonstrate serious invoice/report layouts through supported authoring primitives instead of ad hoc pagination glue.

## v2 Requirements

### Typography and Assets

- **FONT-01**: Engineer can register and embed custom fonts deterministically.
- **FONT-02**: Engineer can configure fallback font chains and receive missing-glyph diagnostics.
- **ASSET-01**: Engineer can embed image and logo assets with clear sizing and placement constraints.
- **I18N-01**: Maintainer can document truthful Unicode/script support boundaries backed by executable proof.

### Async Delivery

- **ASYNC-01**: Operator can receive a stable render manifest with artifact metadata after async document generation.
- **ASYNC-02**: Maintainer can route rendered artifacts through pluggable persistence sinks without hard-coupling storage into core.
- **ASYNC-03**: Operator can reason about retry, cancellation, and persisted-failure semantics for queued document workflows.

## Out of Scope

| Feature | Reason |
|---------|--------|
| HTML/CSS parity or browser-style layout model | Conflicts with Rendro's deterministic pure-core scope |
| WYSIWYG editor or hosted template service | Product expansion before engine contract maturity |
| Custom fonts and fallback chains | Planned for v1.2 after layout semantics stabilize |
| Image/logo embedding and remote asset handling | Planned for v1.2 after page-region contracts exist |
| Render manifests and persistence sinks | Planned for v1.3 after post-pagination structure is stable |
| Blanket compliance/signature claims | Planned for later trust milestone with validator-backed proof |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| LAY-06 | Phase 19 | Completed |
| LAY-07 | Phase 18 | Completed |
| LAY-08 | Phase 18 | Completed |
| LAY-09 | Phase 19 | Completed |
| LAY-10 | Phase 20 | Pending |
| LAY-11 | Phase 18 | Completed |
| OBS-05 | Phase 21 | Pending |
| QUAL-06 | Phase 21 | Pending |
| LAY-12 | Phase 22 | Pending |

**Coverage:**
- v1 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-28*
*Last updated: 2026-04-29 after Phase 19 Plan 03 execution*

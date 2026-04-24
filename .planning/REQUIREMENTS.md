# Requirements: Rendro

**Defined:** 2026-04-24
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Core Engine

- [x] **CORE-01**: Engineer can define a PDF document from Elixir data/components using a pure core API.
- [x] **CORE-02**: Engineer can render PDFs without requiring Chrome/Chromium runtime in core.
- [ ] **CORE-03**: Engineer can use a fixed-position API for exact-placement document use cases.
- [ ] **CORE-04**: Engineer can use a flow API for report/document use cases.
- [x] **CORE-05**: Engineer can run deterministic mode that produces repeatable artifacts for identical inputs.

### Layout and Primitives

- [ ] **LAY-01**: Engineer can compose document primitives including pages, blocks, tables, headers/footers, and metadata.
- [ ] **LAY-02**: Engineer can render flowing content with automatic page breaks.
- [ ] **LAY-03**: Engineer can render large tables across pages with repeating table headers.
- [ ] **LAY-04**: Engineer can configure headers/footers with page numbers and predictable placement.
- [ ] **LAY-05**: Engineer receives overflow diagnostics that identify where layout failed and what to try next.

### Integrations and Adapters

- [ ] **ADPT-01**: Phoenix engineer can serve rendered PDFs through download-friendly adapter helpers.
- [ ] **ADPT-02**: Phoenix engineer can preview rendered output through Phoenix-friendly integration helpers.
- [ ] **ADPT-03**: Maintainer can enable optional adapters without introducing hard compile/runtime dependencies in core.
- [ ] **ADPT-04**: Maintainer can use an optional job-processing adapter pattern for bounded asynchronous rendering.
- [ ] **ADPT-05**: Maintainer can provide do-now integration recipes for `threadline`, `mailglass`, and `accrue` without hard coupling.

### Observability and Safety

- [x] **OBS-01**: Operator can observe telemetry events for build, compose, measure, paginate, render, and validate lifecycle steps.
- [ ] **OBS-02**: Operator can correlate render operations with artifact metrics (duration, page count, byte size, status).
- [x] **OBS-03**: Operator receives structured errors that explain what happened, where it failed, why, and suggested next actions.
- [ ] **OBS-04**: Operator can enforce policy bounds for max pages, max output bytes, and render timeouts.

### Quality and Release

- [ ] **QUAL-01**: Maintainer can run a canonical merge-blocking verification lane (`mix ci`) including format, compile, tests, docs, and package build.
- [ ] **QUAL-02**: Maintainer can validate public docs/quickstart claims with docs-contract checks in CI.
- [ ] **QUAL-03**: Maintainer can run a CI-verified Phoenix example app as executable adoption proof.
- [ ] **QUAL-04**: Maintainer can run release preflight checks for version/tag parity and publish dry-run workflows.
- [ ] **QUAL-05**: Maintainer can separate deterministic required lanes from advisory/provider-dependent lanes in verification output.

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Compliance and Signing

- **COMP-01**: Maintainer can claim PDF/A support only after validator-backed conformance checks are automated.
- **COMP-02**: Maintainer can claim PDF/UA support only after validator-backed accessibility conformance checks are automated.
- **COMP-03**: Engineer can apply and verify digital signatures through an explicitly tested signing implementation.

### Strategic Integrations

- **INT-01**: Maintainer can provide a `rulestead` rollout/feature-flag integration recipe for renderer behavior control.
- **INT-02**: Maintainer can provide `sigra` admin auth/MFA integration patterns for operator-facing surfaces.
- **INT-03**: Maintainer can provide `lattice_stripe` billing/payment document recipes.
- **INT-04**: Maintainer can evaluate and stage `lockspire`, `scrypath`, and `kiln` integrations based on validated demand.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Full HTML/CSS renderer compatibility in core | Outside native-layout thesis; introduces browser-engine scope and coupling |
| Arbitrary PDF editing/parsing product scope | Early focus is generation reliability, not generalized manipulation |
| Broad compliance claims before validator-backed proof | Trust and release integrity require evidence-backed capability claims |
| "Complete" digital-signature support in v1 | High complexity and verification burden; deferred until explicit implementation |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CORE-01 | Phase 1 | Done |
| CORE-02 | Phase 1 | Done |
| CORE-03 | Phase 2 | Pending |
| CORE-04 | Phase 2 | Pending |
| CORE-05 | Phase 1 | Done |
| LAY-01 | Phase 2 | Pending |
| LAY-02 | Phase 2 | Pending |
| LAY-03 | Phase 2 | Pending |
| LAY-04 | Phase 2 | Pending |
| LAY-05 | Phase 2 | Pending |
| ADPT-01 | Phase 3 | Pending |
| ADPT-02 | Phase 3 | Pending |
| ADPT-03 | Phase 3 | Pending |
| ADPT-04 | Phase 3 | Pending |
| ADPT-05 | Phase 5 | Pending |
| OBS-01 | Phase 1 | Done |
| OBS-02 | Phase 3 | Pending |
| OBS-03 | Phase 1 | Done |
| OBS-04 | Phase 3 | Pending |
| QUAL-01 | Phase 4 | Pending |
| QUAL-02 | Phase 4 | Pending |
| QUAL-03 | Phase 4 | Pending |
| QUAL-04 | Phase 4 | Pending |
| QUAL-05 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 24 total
- Mapped to phases: 24
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-24*
*Last updated: 2026-04-24 after roadmap creation*

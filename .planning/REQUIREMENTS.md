# Requirements: Rendro

**Defined:** 2026-04-24
**Core Value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Core Engine

- [ ] **CORE-01**: Engineer can define a PDF document from Elixir data/components using a pure core API.
- [ ] **CORE-02**: Engineer can render PDFs without requiring Chrome/Chromium runtime in core.
- [ ] **CORE-03**: Engineer can use a fixed-position API for exact-placement document use cases.
- [ ] **CORE-04**: Engineer can use a flow API for report/document use cases.
- [ ] **CORE-05**: Engineer can run deterministic mode that produces repeatable artifacts for identical inputs.

### Layout and Primitives

- [ ] **LAY-01**: Engineer can compose document primitives including pages, blocks, tables, headers/footers, and metadata.
- [ ] **LAY-02**: Engineer can render flowing content with automatic page breaks.
- [ ] **LAY-03**: Engineer can render large tables across pages with repeating table headers.
- [ ] **LAY-04**: Engineer can configure headers/footers with page numbers and predictable placement.
- [ ] **LAY-05**: Engineer receives overflow diagnostics that identify where layout failed and what to try next.

### Integrations and Adapters

- [x] **ADPT-01**: Phoenix engineer can serve rendered PDFs through download-friendly adapter helpers.
- [x] **ADPT-02**: Phoenix engineer can preview rendered output through Phoenix-friendly integration helpers.
- [x] **ADPT-03**: Maintainer can enable optional adapters without introducing hard compile/runtime dependencies in core.
- [ ] **ADPT-04**: Maintainer can use an optional job-processing adapter pattern for bounded asynchronous rendering.
- [x] **ADPT-05**: Maintainer can provide do-now integration recipes for `threadline`, `mailglass`, and `accrue` without hard coupling.

### Observability and Safety

- [ ] **OBS-01**: Operator can observe telemetry events for build, compose, measure, paginate, render, and validate lifecycle steps.
- [ ] **OBS-02**: Operator can correlate render operations with artifact metrics (duration, page count, byte size, status).
- [ ] **OBS-03**: Operator receives structured errors that explain what happened, where it failed, why, and suggested next actions.
- [ ] **OBS-04**: Operator can enforce policy bounds for max pages, max output bytes, and render timeouts.

### Quality and Release

- [x] **QUAL-01**: Maintainer can run a canonical merge-blocking verification lane (`mix ci`) including format, compile, tests, docs, and package build.
- [x] **QUAL-02**: Maintainer can validate public docs/quickstart claims with docs-contract checks in CI.
- [x] **QUAL-03**: Maintainer can run a CI-verified Phoenix example app as executable adoption proof.
- [x] **QUAL-04**: Maintainer can run release preflight checks for version/tag parity and publish dry-run workflows.
- [x] **QUAL-05**: Maintainer can separate deterministic required lanes from advisory/provider-dependent lanes in verification output.

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

Each row lists the original implementation phase and the gap-closure phase that will produce verified evidence. Status reflects formal GSD verification (not code presence). 2026-04-26 audit (`.planning/v1.0-MILESTONE-AUDIT.md`) reset 23 of 24 to Pending because Phases 1-4 lack PLAN/SUMMARY/VERIFICATION artifacts.

| Requirement | Original Phase | Gap-Closure Phase | Status |
|-------------|----------------|-------------------|--------|
| CORE-01 | Phase 1 | Phase 6 (validate stage) + Phase 11 (verify) | Done |
| CORE-02 | Phase 1 | Phase 11 (verify) | Done |
| CORE-03 | Phase 2 | Phase 11 (verify) | Done |
| CORE-04 | Phase 2 | Phase 11 (verify) | Done |
| CORE-05 | Phase 1 | Phase 11 (verify) | Done |
| LAY-01 | Phase 2 | Phase 11 (verify) | Done |
| LAY-02 | Phase 2 | Phase 11 (verify) | Done |
| LAY-03 | Phase 2 | Phase 11 (verify) | Done |
| LAY-04 | Phase 2 | Phase 11 (verify) | Done |
| LAY-05 | Phase 2 | Phase 11 (verify) | Done |
| ADPT-01 | Phase 3 | Phase 7 (fix) + Phase 11 (verify) + Phase 14 (artifact backfill) | Done |
| ADPT-02 | Phase 3 | Phase 7 (fix) + Phase 11 (verify) + Phase 14 (artifact backfill) | Done |
| ADPT-03 | Phase 3 | Phase 7 (fix) + Phase 11 (verify) + Phase 14 (artifact backfill) | Done |
| ADPT-04 | Phase 3 | Phase 8 (fix) + Phase 11 (verify) + Phase 14 (artifact backfill) | Partial |
| ADPT-05 | Phase 5 | Phase 8 (timeout) + Phase 10 (recipe + traceability) + Phase 14 (artifact backfill) | Partial |
| OBS-01 | Phase 1 | Phase 6 (telemetry contract) + Phase 11 (verify) | Done |
| OBS-02 | Phase 3 | Phase 6 (metrics) + Phase 8 (timeout) + Phase 11 (verify) | Done |
| OBS-03 | Phase 1 | Phase 7 (envelope) + Phase 11 (verify) + Phase 14 (artifact backfill) | Partial |
| OBS-04 | Phase 3 | Phase 8 (Oban policy) + Phase 11 (verify) | Partial |
| QUAL-01 | Phase 4 | Phase 9 (CI + alias) + Phase 11 (verify) + Phase 12 (verification chain) + Phase 14 (artifact backfill) | Done |
| QUAL-02 | Phase 4 | Phase 9 (verify_docs) + Phase 11 (verify) + Phase 13 (docs closure) + Phase 14 (artifact backfill) | Done |
| QUAL-03 | Phase 4 | Phase 7 (example app) + Phase 9 (CI) + Phase 11 (verify) + Phase 12 (verification chain) + Phase 14 (artifact backfill) | Done |
| QUAL-04 | Phase 4 | Phase 9 (preflight) + Phase 10 (traceability) + Phase 11 (verify) + Phase 13 (release closure) + Phase 14 (artifact backfill) | Done |
| QUAL-05 | Phase 4 | Phase 9 (verify lanes) + Phase 11 (verify) + Phase 12 (verification chain) + Phase 14 (artifact backfill) | Done |

**Coverage:**
- v1 requirements: 24 total
- Mapped to phases: 24
- Unmapped: 0 ✓
- Verified (Done): 20
- Pending verification: 0
- Partial verification: 4
- Blocked verification: 0

---
*Requirements defined: 2026-04-24*
*Last updated: 2026-04-28 after Phase 14 Plan 04 final traceability synchronization*

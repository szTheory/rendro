# Roadmap: Rendro

## Overview

Rendro will be delivered through five coarse phases that move from non-negotiable core guarantees (pure deterministic rendering) to production viability (pagination, observability, Phoenix integration, release quality) and finally to early ecosystem recipes. This ordering prioritizes reliability and truthful scope before breadth.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Core Deterministic Foundation** - Establish pure core boundaries, deterministic rendering contract, and lifecycle event/error schema.
- [x] **Phase 2: Layout and Pagination Engine** - Deliver practical document primitives, robust pagination, and table/header behavior for real invoice/report workloads.
- [x] **Phase 3: Adapter and Ops Integration** - Add optional Phoenix/job adapter patterns with bounded execution and operational metrics.
- [x] **Phase 4: Quality and Release Hardening** - Implement CI verification contracts, docs truthfulness checks, and release safety gates.
- [ ] **Phase 5: Early Ecosystem Recipes** - Ship do-now integration recipes without violating core boundary constraints.

## Phase Details

### Phase 1: Core Deterministic Foundation
**Goal**: Deliver a pure Elixir core document/render pipeline with deterministic mode and actionable observability/error foundations.
**Depends on**: Nothing (first phase)
**Requirements**: [CORE-01, CORE-02, CORE-05, OBS-01, OBS-03]
**Success Criteria** (what must be TRUE):
  1. Engineer can render a valid PDF from Elixir data using core APIs only.
  2. The same deterministic input produces repeatable artifacts in CI fixtures.
  3. Lifecycle telemetry events are emitted for core pipeline stages.
  4. Render failures return structured diagnostics with what/where/why/next guidance.
**Plans**: 2 plans

Plans:
- [x] 01-01: Build pure core document model and rendering skeleton
- [x] 01-02: Implement deterministic mode plus telemetry and structured error schema

### Phase 2: Layout and Pagination Engine
**Goal**: Make invoice/report generation viable with robust flow layout, multi-page tables, and predictable page-level composition.
**Depends on**: Phase 1
**Requirements**: [CORE-03, CORE-04, LAY-01, LAY-02, LAY-03, LAY-04, LAY-05]
**Success Criteria** (what must be TRUE):
  1. Engineer can choose fixed-position or flow API over the same rendering engine.
  2. Multi-page content paginates automatically with stable break behavior.
  3. Tables repeat headers correctly across page breaks.
  4. Headers/footers and page numbers render in predictable positions.
  5. Overflow diagnostics identify failing block path and remediation options.
**Plans**: 3 plans

Plans:
- [x] 02-01: Implement dual API surface and shared document primitives
- [x] 02-02: Build pagination/table engine with repeat-header and overflow handling
- [x] 02-03: Add header/footer placement and metadata behavior with deterministic fixtures

### Phase 3: Adapter and Ops Integration
**Goal**: Enable production adoption through optional adapters, operational metrics, and bounded rendering policies.
**Depends on**: Phase 2
**Requirements**: [ADPT-01, ADPT-02, ADPT-03, ADPT-04, OBS-02, OBS-04]
**Success Criteria** (what must be TRUE):
  1. Phoenix teams can download and preview rendered PDFs through optional adapters.
  2. Optional adapters can be enabled/disabled without breaking core compilation.
  3. Background render pattern is available via optional job adapter integration.
  4. Operators can enforce max pages/bytes/timeouts on render execution.
  5. Render artifact metrics are correlated and observable for operations workflows.
**Plans**: 2 plans

Plans:
- [x] 03-01: Implement optional Phoenix adapter helpers for download/preview workflows
- [x] 03-02: Add optional job adapter pattern, policy bounds, and artifact metric correlation

### Phase 4: Quality and Release Hardening
**Goal**: Guarantee truthful, reproducible delivery through canonical verification and release safety automation.
**Depends on**: Phase 3
**Requirements**: [QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05]
**Success Criteria** (what must be TRUE):
  1. `mix ci` enforces merge-blocking format/compile/test/docs/package checks.
  2. Docs-contract checks fail on unsupported or drifting public claims.
  3. Phoenix example host app executes in CI as adoption proof.
  4. Release preflight catches version/tag mismatch and publish issues before release.
  5. Verification output clearly separates deterministic required lanes from advisory lanes.
**Plans**: 2 plans

Plans:
- [x] 04-01: Build canonical verify lanes and deterministic/advisory verification contract
- [x] 04-02: Add docs-contract checks, example app CI, and release preflight parity automation

### Phase 5: Early Ecosystem Recipes
**Goal**: Provide validated do-now integration recipes for high-value ecosystem workflows while preserving architecture boundaries.
**Depends on**: Phase 4
**Requirements**: [ADPT-05]
**Success Criteria** (what must be TRUE):
  1. Maintainers can follow tested recipes for `threadline`, `mailglass`, and `accrue`.
  2. Recipes remain optional and do not introduce hard dependencies into core.
  3. Integration documentation includes verification guidance and failure diagnostics.
**Plans**: 4 plans (05-01 executed; 05-02..05-04 added by gap closure 2026-04-26)

Plans:
- [x] 05-01: Implement and validate threadline/mailglass/accrue recipe integrations (verification: 4/7 must-haves; gaps closed below)
- [ ] 05-02-PLAN.md — Implement optional Accrue billing-document recipe with contract mock (closes Gap 1)
- [ ] 05-03-PLAN.md — Fix Mailglass attach_pdf/3 contract violations CR-01, CR-02, WR-03 with negative-path tests (closes Gap 3)
- [ ] 05-04-PLAN.md — Author integration guide and wire into ExDoc + README (closes Gap 2)

## Progress

**Execution Order:**
Phases execute in numeric order: 2 -> 2.1 -> 2.2 -> 3 -> 3.1 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Deterministic Foundation | 0/2 | Not started | - |
| 2. Layout and Pagination Engine | 0/3 | Not started | - |
| 3. Adapter and Ops Integration | 0/2 | Not started | - |
| 4. Quality and Release Hardening | 0/2 | Not started | - |
| 5. Early Ecosystem Recipes | 0/1 | Not started | - |

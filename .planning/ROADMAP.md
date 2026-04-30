# Roadmap: Rendro

## Overview

Rendro is progressing through iterative, verified milestones. `v1.0` proved the core rendering and trust contract. `v1.1` now focuses on layout authoring maturity: making page composition, text flow, table behavior, and break diagnostics strong enough that later fonts/assets and async artifact workflows can build on stable layout semantics instead of ad hoc engine shortcuts.

## Milestones

- <details><summary><b>Milestone v1.0</b> (Shipped 2026-04-28)</summary>
  MVP delivered. Core pure rendering, layout primitives, Phoenix adapters, rigorous CI verification.
  See [.planning/milestones/v1.0-ROADMAP.md](/Users/jon/projects/rendro/.planning/milestones/v1.0-ROADMAP.md) for full phase details.
  </details>
- <details open><summary><b>Milestone v1.1</b> (Active) — Layout Authoring Maturity</summary>
  Strengthen authoring semantics and pagination determinism so Rendro becomes a serious document-layout base, not just a reliable PDF engine.
  </details>

## Phases

- [x] **Phase 18: Layout Contract and Page Template Model** - Introduce explicit flow page templates, sections, regions, and fixed-position fit validation as the foundational document layout contract.
- [x] **Phase 19: Deterministic Text Flow and Break Semantics** - Add width-aware text measurement plus explicit keep/break directives so pagination decisions reflect authored intent.
- [ ] **Phase 20: Table Layout Maturity** - Replace demo-grade table sizing and split logic with deterministic multi-page table behavior fit for invoices and reports.
- [ ] **Phase 21: Break Diagnostics and Pagination Proofs** - Make break/overflow causes observable and lock down pagination invariants with deterministic regression evidence.
- [ ] **Phase 22: Authoring Ergonomics and Canonical Recipes** - Lift the new layout surface into recipes/examples/docs so downstream Phoenix teams can use it without ad hoc glue.

### Phase 18: Layout Contract and Page Template Model
**Goal**: Establish the document-level layout structures that v1.1 and later milestones depend on.
**Depends on**: Phase 17
**Requirements**: [LAY-07, LAY-08, LAY-11]
**Success Criteria** (what must be TRUE):
  1. Engineers can define flow documents against explicit page templates rather than an implicit default `%Rendro.Page{}`.
  2. Sections or bounded layout regions exist as first-class authoring data, not hidden `options` conventions.
  3. Headers and footers are modeled as real page regions with predictable anchoring semantics.
  4. Fixed-position pages fail truthfully when authored content exceeds page bounds.
**Plans**: 3 plans

### Phase 19: Deterministic Text Flow and Break Semantics
**Goal**: Make flow layout expressive enough for real reports by teaching the engine authored intent.
**Depends on**: Phase 18
**Requirements**: [LAY-06, LAY-09]
**Success Criteria** (what must be TRUE):
  1. Width-constrained text wraps deterministically with stable line breaks for identical input.
  2. Flow blocks can express `keep_together`, `keep_with_next`, and explicit break-before/after semantics.
  3. Pagination decisions remain deterministic and testable even when content can wrap across multiple lines.
  4. Public flow APIs/examples expose these semantics clearly without leaking internal pipeline details.
**Plans**: 3 plans
Plans:
- [x] 19-01-PLAN.md — Add wrapped-text and block break-intent contracts plus deterministic measurement.
- [x] 19-02-PLAN.md — Enforce keep/break pagination semantics with typed failure diagnostics.
- [x] 19-03-PLAN.md — Render measured wrapped lines and publish truthful public examples.

### Phase 20: Table Layout Maturity
**Goal**: Turn the current table primitive into a reliable business-document layout capability.
**Depends on**: Phase 19
**Requirements**: [LAY-10]
**Success Criteria** (what must be TRUE):
  1. Table column sizing is deterministic and based on real measured content or explicit column rules.
  2. Multi-page tables preserve row integrity according to explicit split policy.
  3. Repeated headers and region-aware table continuation behave predictably across page breaks.
  4. Public table surface no longer implies unsupported width/border behavior.
**Plans**: 2 plans

### Phase 21: Break Diagnostics and Pagination Proofs
**Goal**: Make pagination behavior explainable and durable under future milestone expansion.
**Depends on**: Phase 20
**Requirements**: [OBS-05, QUAL-06]
**Success Criteria** (what must be TRUE):
  1. Operators can inspect structured diagnostics explaining why content moved, split, or overflowed.
  2. Telemetry/error surfaces preserve enough break context to debug production layout failures.
  3. Deterministic regression fixtures prove page assignment and break behavior, not just PDF validity.
  4. Public docs make support boundaries and failure modes truthful.
**Plans**: 2 plans
Plans:
- [x] 21-01-PLAN.md — Structural Diagnostics in Document Model & Pipeline Accumulators
- [x] 21-02-PLAN.md — ASCII Layout Tree Inspector & ExUnit Snapshots

### Phase 22: Authoring Ergonomics and Canonical Recipes
**Goal**: Convert the stronger engine surface into an adoption-ready authoring experience.
**Depends on**: Phase 21
**Requirements**: [LAY-12]
**Success Criteria** (what must be TRUE):
  1. Canonical invoice/report recipes use the new layout primitives rather than ad hoc block stacking.
  2. README and guides show how to compose serious business documents with the supported authoring surface.
  3. Example documents reduce the amount of pagination glue Phoenix adopters need to write themselves.
**Plans**: 3 plans
Plans:
- [x] 22-01-PLAN.md — Add Pipeline Builder API to Rendro.Document
- [x] 22-02-PLAN.md — Create Tiered Composition Invoice and Refactor Accrue Recipe
- [ ] 22-03-PLAN.md — Update Phoenix Example Controller and README.md

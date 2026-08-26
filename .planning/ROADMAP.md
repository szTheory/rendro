# ROADMAP — Rendro

## Milestones

- 📋 **v2.14 Quality & Maintainability** — Phases 132-137 (planned)
- ✅ **v2.13 Quality Ratchet & Adoption Readiness** — Phases 130-131 (shipped 2026-08-26; [roadmap archive](milestones/v2.13-ROADMAP.md), [requirements](milestones/v2.13-REQUIREMENTS.md), [audit](milestones/v2.13-MILESTONE-AUDIT.md))
- ✅ **v2.12 Style-Genre Presets, Public Catalog & Static Configurator** — Phases 125-129 (shipped 2026-08-19; [roadmap archive](milestones/v2.12-ROADMAP.md), [requirements](milestones/v2.12-REQUIREMENTS.md), [audit](milestones/v2.12-MILESTONE-AUDIT.md))
- ✅ **v2.11 Document Theming & Design-Token System** — Phases 119-124 (shipped 2026-07-28; [roadmap archive](milestones/v2.11-ROADMAP.md))
- ✅ **v2.10 Realistic Business-Document Examples & Anatomy** — Phases 114-118 (shipped 2026-07-19; [roadmap archive](milestones/v2.10-ROADMAP.md))
- ✅ **C1 CI/CD Performance & Reliability** — Phases 108-113 (shipped 2026-07-11; [roadmap archive](milestones/C1-ROADMAP.md))
- ✅ **B1 Brand System & Identity Lab** — Phases 101-107 (shipped 2026-06-14; [roadmap archive](milestones/B1-ROADMAP.md))
- ✅ **v2.9 TOC & Document Navigation** — Phases 97-100 (shipped 2026-06-14; [roadmap archive](milestones/v2.9-ROADMAP.md))

## Phases

### 📋 v2.14 Quality & Maintainability (Phases 132-137)

**Milestone Goal:** Raise Rendro's engineering, repository, CI/CD, test, documentation, and targeted catalog quality without changing supported capability scope, public contracts, or unrelated rendered bytes.

- [x] **Phase 132: Quality Baseline & Triage** — Establish the durable evidence ledger, compatibility contract, and risk-ranked finding set that governs all later work. (completed 2026-08-26)
- [ ] **Phase 133: Repository & Evidence Hygiene** — Remove active-product coupling to archived planning and make repository, package, and evidence boundaries durable.
- [ ] **Phase 134: Core Architecture & Readability** — Resolve accepted high-value internal design, dead-code, specification, documentation, and comment findings conservatively.
- [ ] **Phase 135: Test & CI/CD Simplification** — Preserve behavioral and authority coverage while consolidating brittle tests and milestone-specific workflow machinery.
- [ ] **Phase 136: Catalog Visual Quality** — Repair and re-review only the six scored catalog cells with actual visual gaps through the generic exact-SHA evidence lane.
- [ ] **Phase 137: Closure & Handoff** — Re-run full evidence, close the ledger, and leave a ranked, durable next-milestone posture.

## Phase Details

### Phase 132: Quality Baseline & Triage

**Goal**: Maintainers have a dated, reproducible quality baseline and one durable ledger that distinguishes actionable risk from low-value cleanup signals.
**Depends on**: Nothing (first phase of v2.14; builds on the shipped v2.13 baseline and v2.14 research)
**Requirements**: AUDIT-01, AUDIT-02, AUDIT-03, AUDIT-04
**Success Criteria** (what must be TRUE):

  1. A maintainer can reproduce the recorded architecture, dependency, test, CI/CD, documentation, packaging, release-evidence, and catalog baseline using documented repository commands.
  2. Every discovered finding appears once in the durable ledger with evidence, impact, confidence, compatibility risk, disposition, owner phase, verification method, and status.
  3. Every high-risk finding is assigned for repair or rejected with evidence; medium-risk work is bounded or deferred with a trigger; low-value observations do not create standalone churn.
  4. The ledger freezes the public API and unrelated rendered-byte compatibility contract that every later phase must verify.

**Plans**: 2/2 plans executed

Plans:

- [x] 132-01-PLAN.md — Establish the schema-backed ledger/evidence tracer and complete governance contract.
- [x] 132-02-PLAN.md — Capture the full dated baseline and triage every signal into the durable ledger.

### Phase 133: Repository & Evidence Hygiene

**Goal**: Current product, release, test, package, and workflow behavior depends only on current durable inputs while historical planning remains safely archived.
**Depends on**: Phase 132
**Requirements**: HYGIENE-01, HYGIENE-02, HYGIENE-03, HYGIENE-04
**Success Criteria** (what must be TRUE):

  1. Product code, release verification, current regression tests, and operational workflows run without reading archived planning artifacts; explicit GSD-planning tests remain clearly identified as tooling checks.
  2. A versioned, schema-validated durable source supplies every v1.3.4 release and newcomer-journey fact currently consumed from Phase 131 evidence.
  3. Maintainers can inspect the phase archive and find no unexplained loose tracked phase files or ownerless tracked helper scripts.
  4. Package and hygiene checks prove internal evidence, local debris, and misplaced planning files cannot enter the published artifact unnoticed.

**Plans**: 2/13 plans executed

Plans:
**Wave 1**

- [x] 133-01-PLAN.md — Trace manifest to validated prerequisite through the inert shared loader.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 133-02-PLAN.md — Add core release identity, validation, and journey-index roles.
- [ ] 133-08-PLAN.md — Archive loose Phase 5 history under v1.0.
- [ ] 133-09-PLAN.md — Archive the seven-file Phase 45 set under v1.8.
- [ ] 133-10-PLAN.md — Inventory retained helpers and remove three ownerless scripts.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 133-03-PLAN.md — Preserve journey attempts 001-004 with the strict attempt schema.
- [ ] 133-11-PLAN.md — Implement the isolated hygiene policy, command, expected manifest, and focused tests.

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 133-04-PLAN.md — Preserve journey attempts 005-009 and seal complete capsule cardinality.

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 133-05-PLAN.md — Atomically switch every active consumer to the complete capsule.

**Wave 6** *(blocked on Wave 5 completion)*

- [ ] 133-06-PLAN.md — Remove redundant legacy journey source batch A after cutover.
- [ ] 133-07-PLAN.md — Remove redundant legacy journey source batch B after cutover.

**Wave 7** *(blocked on Wave 6 completion)*

- [ ] 133-12-PLAN.md — Apply exact package cleanup, PDF.js fixture relocation, and Mix/CI/release wiring.

**Wave 8** *(blocked on Wave 7 completion)*

- [ ] 133-13-PLAN.md — Run terminal gates and close QL-002 only with its predeclared evidence.

### Phase 134: Core Architecture & Readability

**Goal**: Accepted high-value internal quality findings are closed with cohesive, self-documenting code and evidence that supported contracts remain stable.
**Depends on**: Phase 133
**Requirements**: ARCH-01, ARCH-02, ARCH-03, ARCH-04
**Success Criteria** (what must be TRUE):

  1. Every accepted high-impact architecture, dead-code, dependency, duplication, and readability finding is repaired or rejected with evidence, and medium findings follow their recorded disposition.
  2. Each extraction has a cohesive responsibility, a documented maintenance benefit, and characterization coverage; no change exists solely to reduce a size metric.
  3. Public and boundary specifications, module documentation, and explanatory comments match current behavior and explain only non-obvious intent or constraints.
  4. The public API manifest and rendered bytes outside explicitly approved catalog targets remain identical after the cleanup.

**Plans**: TBD

### Phase 135: Test & CI/CD Simplification

**Goal**: Rendro's tests and automation are easier to understand and maintain without weakening behavior coverage, trust boundaries, or the authoritative CI contract.
**Depends on**: Phase 134
**Requirements**: TEST-01, TEST-02, CI-01, CI-02, CI-03, CI-04, CI-05
**Success Criteria** (what must be TRUE):

  1. Maintainers can trace each consolidated test group to an inventory of preserved behaviors and failure modes, including mutation-style proof that replacement tests detect broken contracts.
  2. One purpose-named read-only workflow generates review or canonical catalog evidence for an explicit verified candidate SHA with the pinned renderer and bounded artifacts.
  3. Recorded parity proves the generic workflow preserves the outputs and authority checks of the Phase 126, 127, and 130 routes before those milestone-specific branches disappear.
  4. Ordinary CI still separates deterministic, proof, and advisory evidence and preserves the authoritative `ci-success` status while caches, permissions, secrets, and action pins obey documented trust rules.
  5. A maintainer can reproduce each supported local and remote path from current documentation without consulting completed phase plans.

**Plans**: TBD

### Phase 136: Catalog Visual Quality

**Goal**: The six scored cells with current visual gaps meet the frozen rubric through exact, reviewable evidence without expanding catalog scope or dark-mode claims.
**Depends on**: Phase 135
**Requirements**: CATALOG-10, CATALOG-11, CATALOG-12, CATALOG-13
**Success Criteria** (what must be TRUE):

  1. The only visually changed cells are Corporate Classic Invoice dark, Minimal Mono Statement dark, Swiss Payslip light and dark, and Brutalist Ticket light and dark.
  2. Exact-SHA pinned-renderer evidence and human review give each target hierarchy 5 and every other scored visual dimension at least 4; any miss remains truthfully unpromoted.
  3. The catalog still contains exactly 32 cells with 20 explicitly unscored entries, and every dark record remains screen-oriented with `print_safety: false`.
  4. Every changed record is traceable through source SHA, renderer identity, artifact hashes, human review, and canonical publication provenance.

**Plans**: TBD

### Phase 137: Closure & Handoff

**Goal**: v2.14 closes with fresh evidence, no ownerless accepted risk, and enough current context for the next maintainer to choose high-signal work immediately.
**Depends on**: Phase 136
**Requirements**: HANDOFF-01, HANDOFF-02, HANDOFF-03
**Success Criteria** (what must be TRUE):

  1. Fresh deterministic, proof, advisory, documentation, package, and catalog checks are recorded beside the v2.14 baseline with any unavailable advisory evidence stated explicitly.
  2. Every high-risk ledger item is closed or rejected with evidence, and every remaining medium item has an owner, disposition, and revisit trigger.
  3. The quality ledger and current planning documents agree on delivered work, preserved boundaries, deferred opportunities, and ranked next-milestone options.
  4. A fresh session can identify the current project posture and next recommended GSD action without reconstructing completed phase history.

**Plans**: TBD

## Progress

**Execution Order:** 132 → 133 → 134 → 135 → 136 → 137

| Phase | Requirements | Plans Complete | Status | Completed |
|-------|--------------|----------------|--------|-----------|
| 132. Quality Baseline & Triage | 4 | 4/4 | Complete    | 2026-08-26 |
| 133. Repository & Evidence Hygiene | 4 | 2/13 | In Progress|  |
| 134. Core Architecture & Readability | 4 | 0/TBD | Not started | — |
| 135. Test & CI/CD Simplification | 7 | 0/TBD | Not started | — |
| 136. Catalog Visual Quality | 4 | 0/TBD | Not started | — |
| 137. Closure & Handoff | 3 | 0/TBD | Not started | — |

**Coverage:** 26/26 active requirements mapped exactly once.

---
*Roadmap created: 2026-08-26*

# Requirements — Rendro v2.14 Quality & Maintainability

**Defined:** 2026-08-26
**Status:** Active
**Milestone Goal:** Raise Rendro's engineering, repository, CI/CD, test, documentation, and targeted catalog quality without changing supported capability scope, public contracts, or unrelated rendered bytes.

## Audit & Triage

- [ ] **AUDIT-01:** Maintainers can reproduce a dated baseline of the repository's architecture, dependencies, tests, CI/CD, documentation, packaging, release evidence, and catalog posture using existing project tooling.
- [ ] **AUDIT-02:** Maintainers have one durable current quality ledger that records the baseline, accepted findings, rejected signals, deferred work, and closure evidence without requiring completed phase artifacts to remain active.
- [ ] **AUDIT-03:** Every ledger finding records its evidence, impact, confidence, compatibility risk, disposition, owner phase, verification method, status, and revisit trigger where applicable.
- [ ] **AUDIT-04:** Every high-risk finding is assigned for repair or rejected with evidence; bounded medium-risk findings are repaired or explicitly deferred; low-value observations do not create standalone churn.

## Repository & Evidence Hygiene

- [ ] **HYGIENE-01:** Product code, release verification, current regression tests, and operational workflows no longer require archived planning artifacts; tooling whose purpose is to validate GSD planning may retain an explicit, documented planning dependency.
- [ ] **HYGIENE-02:** A versioned, schema-validated durable evidence source contains every release and newcomer-journey fact currently asserted from Phase 131 artifacts, and all current consumers use that source.
- [ ] **HYGIENE-03:** Loose tracked phase files are moved to the correct historical archive, and obsolete tracked helper scripts are either removed with evidence or retained with an explicit current owner and purpose.
- [ ] **HYGIENE-04:** Published packages exclude internal evidence and repository debris, and automated hygiene checks detect future regressions in package contents and tracked planning placement.

## Core Architecture & Readability

- [ ] **ARCH-01:** The supported public API manifest and rendered bytes outside explicitly approved catalog targets remain unchanged throughout internal cleanup.
- [ ] **ARCH-02:** Every accepted high-impact architecture, dead-code, dependency, duplication, and readability finding is repaired or rejected with evidence; bounded medium-impact findings follow the ledger disposition rules.
- [ ] **ARCH-03:** A module or function is extracted only when the change creates a cohesive responsibility or measurable maintenance benefit, with characterization coverage; size alone is not sufficient justification.
- [ ] **ARCH-04:** Public and boundary specs, module documentation, and explanatory comments accurately describe current behavior; stale narration and misleading private specifications are removed or corrected with documentation and Dialyzer proof.

## Tests & CI/CD

- [x] **TEST-01:** Before overlapping tests are consolidated, maintainers inventory the distinct behaviors and failure modes they protect and demonstrate that replacement tests fail when those contracts are broken.
- [x] **TEST-02:** Planning-coupled, implementation-coupled, or duplicative brittle tests are consolidated without losing behavior, failure-mode, public-contract, or deterministic-output protection.
- [x] **CI-01:** One purpose-named catalog evidence workflow accepts an explicit candidate SHA and review/canonical mode, checks out and verifies that exact SHA, uses the pinned renderer, has read-only repository permission, and uploads artifacts without mutating the repository.
- [ ] **CI-02:** The generic catalog evidence workflow proves output and authority parity with the Phase 126, 127, and 130 routes before those milestone-specific routes are removed.
- [x] **CI-03:** Ordinary CI preserves the deterministic, proof, and advisory lane separation and retains the existing authoritative `ci-success` contract while redundant workflow structure is simplified.
- [x] **CI-04:** CI caches are treated as untrusted inputs, remain read-only in lower-trust contexts, do not expose secrets, and retain immutable action pins and least-privilege permissions.
- [x] **CI-05:** Maintainer documentation states the supported local and remote reproduction commands, workflow inputs, authority checks, artifact identities, and failure boundaries for the simplified CI/CD paths.

## Catalog Visual Quality

- [ ] **CATALOG-10:** Visual work is limited to the six scored catalog cells with current sub-threshold dimensions: Corporate Classic Invoice dark, Minimal Mono Statement dark, Swiss Payslip light and dark, and Brutalist Ticket light and dark.
- [ ] **CATALOG-11:** Current exact-SHA pinned-renderer evidence and human review score hierarchy at 5 and every other scored visual dimension at 4 or higher for each of the six target cells; a miss remains truthfully recorded rather than promoted.
- [ ] **CATALOG-12:** The catalog remains fixed at 32 cells with 20 explicitly unscored cells, and dark output remains screen-oriented with `print_safety: false` and no new print, accessibility, or viewer-support claim.
- [ ] **CATALOG-13:** Each changed catalog record is bound to its exact source SHA, pinned renderer identity, artifact hashes, human review, and canonical publication provenance.

## Closure & Handoff

- [ ] **HANDOFF-01:** Maintainers can run fresh full deterministic, proof, advisory, documentation, package, and catalog checks and compare final results with the dated v2.14 baseline.
- [ ] **HANDOFF-02:** Every high-risk ledger finding is closed or rejected with evidence, every accepted medium-risk finding has a recorded disposition, and no unresolved item lacks an owner or revisit trigger.
- [ ] **HANDOFF-03:** The quality ledger, PROJECT, STATE, and ROADMAP leave a concise current posture, deferred-work triggers, and ranked next-milestone options for a fresh maintainer session.

## Future Requirements

- **FUTURE-01:** Add a live server-rendered theme playground only when the existing Studio demand gate is met.
- **FUTURE-02:** Add global text shaping, RTL/bidi, or broader OpenType support only when the refreshed conjunctive adoption gate supports that capability expansion.
- **FUTURE-03:** Add charting or other new document capability families only through a separately scoped, demand-backed milestone.
- **FUTURE-04:** Score or expand the twenty currently unscored catalog cells only through a future explicitly approved catalog milestone.

## Out of Scope

| Item | Reason |
|------|--------|
| New runtime features, document capability families, recipes, presets, or catalog cells | v2.14 is a quality ratchet, not a scope expansion |
| Public API redesigns or intentional broad PDF-byte changes | Cleanup must preserve supported contracts and isolate the six approved visual targets |
| Arbitrary coverage, module-size, dependency-count, or comment-count quotas | Metrics are investigation signals, not substitutes for behavioral evidence and cohesion judgment |
| Global text shaping, Studio, charts, analytics, outreach, or reviewer product work | Existing demand gates remain authoritative |
| Promoting dark output to print-safe | Dark catalog output remains intentionally screen-oriented |
| Deleting ignored local artifacts | Untracked developer-local files are outside the milestone unless they become tracked or packaged |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUDIT-01 | Phase 132 | Complete |
| AUDIT-02 | Phase 132 | Complete |
| AUDIT-03 | Phase 132 | Complete |
| AUDIT-04 | Phase 132 | Complete |
| HYGIENE-01 | Phase 133 | Complete |
| HYGIENE-02 | Phase 133 | Complete |
| HYGIENE-03 | Phase 133 | Complete |
| HYGIENE-04 | Phase 133 | Complete |
| ARCH-01 | Phase 134 | Complete |
| ARCH-02 | Phase 134 | Complete |
| ARCH-03 | Phase 134 | Complete |
| ARCH-04 | Phase 134 | Complete |
| TEST-01 | Phase 135 | Complete |
| TEST-02 | Phase 135 | Complete |
| CI-01 | Phase 135 | Complete |
| CI-02 | Phase 135 | Complete |
| CI-03 | Phase 135 | Complete |
| CI-04 | Phase 135 | Complete |
| CI-05 | Phase 135 | Complete |
| CATALOG-10 | Phase 136 | Complete |
| CATALOG-11 | Phase 136 | Complete |
| CATALOG-12 | Phase 136 | Complete |
| CATALOG-13 | Phase 136 | Pending |
| HANDOFF-01 | Phase 137 | Pending |
| HANDOFF-02 | Phase 137 | Pending |
| HANDOFF-03 | Phase 137 | Pending |

**Coverage:** 26/26 active requirements mapped exactly once.

---
*Requirements defined: 2026-08-26*
*Last updated: 2026-08-26 after v2.14 roadmap creation*

---
gsd_state_version: 1.0
milestone: v2.14
milestone_name: Quality & Maintainability
current_phase: 133
current_phase_name: Repository & Evidence Hygiene
status: planning
stopped_at: Phase 133 context gathered
last_updated: "2026-08-26T20:42:41.931Z"
last_activity: 2026-08-26
last_activity_desc: Phase 132 complete, transitioned to Phase 133
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 4
  completed_plans: 4
  percent: 17
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-26)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Phase 133 — Repository & Evidence Hygiene

## Current Position

Phase: 133 — Repository & Evidence Hygiene
Plan: Not started
Status: Ready to plan
Last activity: 2026-08-26 — Phase 132 complete, transitioned to Phase 133

## Roadmap Snapshot (v2.14, Phases 132-137)

```text
[#######.................................] 17% — 1/6 phases complete
Phase 132 Quality Baseline & Triage ....................... Complete
Phase 133 Repository & Evidence Hygiene ................... Pending
Phase 134 Core Architecture & Readability ................. Pending
Phase 135 Test & CI/CD Simplification ..................... Pending
Phase 136 Catalog Visual Quality .......................... Pending
Phase 137 Closure & Handoff ............................... Pending
```

**Locked sequencing:** baseline and triage → durable evidence hygiene → conservative core cleanup → behavior-preserving test/CI simplification → six-cell catalog repair → measured closure and handoff.

## Accumulated Context

### Decisions

- v2.14 is a quality and maintainability milestone; it adds no runtime features, capability families, recipes, presets, or catalog cells.
- Public APIs and unrelated rendered bytes are compatibility contracts; only the six named catalog cells may change visually.
- Findings are risk-ranked using evidence, impact, confidence, compatibility risk, and verification; metrics are diagnostic signals, not quotas.
- High-risk findings must be repaired or rejected with evidence, bounded medium findings must be repaired or explicitly deferred, and low-value observations do not justify standalone churn.
- Comments explain non-obvious intent and constraints; stale narration and misleading specifications are removed or corrected.
- Product, release, and current regression behavior must not depend on archived planning; GSD-planning tooling checks may retain an explicit exception.
- Catalog CI converges on one generic read-only exact-SHA evidence workflow before Phase 126, 127, and 130 routes are removed.
- Catalog scope remains 32 cells with 20 explicitly unscored; dark output remains screen-oriented and `print_safety: false`.
- Catalog quality work is limited to Corporate Classic Invoice dark, Minimal Mono Statement dark, Swiss Payslip light/dark, and Brutalist Ticket light/dark.
- [Phase 132]: QUALITY.md is human-first; normalized JSV evidence is companion-only and excluded from ordinary tests and `ci.fast`.
- [Phase 132]: QL-001 records xref topology as a `reject_signal` until concrete harm meets its reopening trigger.
- [Phase 132]: The source-bound initial snapshot is immutable; later evidence requires a new dated snapshot.
- [Phase 132]: Archive evidence authority routes to 133, generic catalog parity to 135, and only six named visual cells to 136.
- [Phase 132]: Objective completion uses deterministic evidence, advisory feedback, or explicit deferral; no blocking human UAT state is permitted in active phase artifacts.

### Pending Todos

None outside the roadmap.

### Blockers/Concerns

- Remote pinned-renderer parity and visual review remain advisory evidence during Phases 135-136; unavailable evidence must remain explicitly unavailable and non-blocking.
- Exact architecture extractions remain intentionally undecided until Phase 134 demonstrates impact and compatibility-safe verification.
- v1.3.0-v1.3.3 and failed Phase 131 release/control attempts are immutable historical evidence and must not be retried or rewritten.

## Deferred Items

| Category | Item | Status | Revisit Trigger |
|----------|------|--------|-----------------|
| Studio | Live server-rendered theme playground | Demand-gated | Existing Studio demand gate is met |
| Typography | Global text shaping, RTL/bidi, broader OpenType | Demand-gated | Refreshed conjunctive adoption gate supports expansion |
| Capabilities | Charts and other new document families | Deferred | Separately approved demand-backed milestone |
| Catalog | New recipes, presets, cells, or scoring the twenty unscored cells | Deferred | Explicit future catalog milestone |

## Session Continuity

Last session: 2026-08-26T20:42:41.922Z
Stopped at: Phase 133 context gathered
Resume file: .planning/phases/133-repository-evidence-hygiene/133-CONTEXT.md

## Next Steps

1. Run `$gsd-discuss-phase 133` for repository and evidence hygiene.
2. Plan Phase 133 from QL-002 and the ledger's exact archive-consumer evidence.
3. Preserve the no-feature, public-contract, deterministic/advisory/explicit-deferral, and immutable-history boundaries.

## Operator Next Steps

- Start with `$gsd-discuss-phase 133`.

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 132-quality-baseline-triage P01 | 7m | 3 tasks | 6 files |
| Phase 132-quality-baseline-triage P02 | 31min | 2 tasks | 3 files |
| Phase 132-quality-baseline-triage P03 | 34min | 2 tasks | 10 files |
| Phase 132-quality-baseline-triage P04 | 29min | 2 tasks | 9 files |

---
gsd_state_version: 1.0
milestone: v2.12
milestone_name: Style-Genre Presets, Public Catalog & Static Configurator
current_phase: 125
current_phase_name: Foundation — Curated fonts, style-genre presets & brand fixtures
status: executing
stopped_at: Completed 125-07-PLAN.md
last_updated: "2026-08-17T00:40:03.156Z"
last_activity: 2026-08-16
last_activity_desc: Phase 125 execution started
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 10
  completed_plans: 2
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-28)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Phase 125 — Foundation — Curated fonts, style-genre presets & brand fixtures

## Current Position

Phase: 125 (Foundation — Curated fonts, style-genre presets & brand fixtures) — EXECUTING
Plan: 3 of 10
Status: Ready to execute
Last activity: 2026-08-16 — Phase 125 execution started

## Roadmap Snapshot (v2.12, Phases 125-129) — IN PLANNING

```text
[                                        ] 0% — 0/5 phases complete
Phase 125 Foundation — fonts, presets & brand fixtures .... Not started
Phase 126 Carryover polish — dark/hierarchy/golden depth .. Not started
Phase 127 Public example catalog & quality ratchet ........ Not started
Phase 128 Static configurator, codegen & Livebook .......... Not started
Phase 129 Docs & manifest closure .......................... Not started
```

**Locked sequencing:** 125 (foundation) → 126 (polish, needs presets for POLISH-04) → 127 (catalog, needs polish landed first for honest dark cells) → 128 (configurator, needs catalog as data source) → 129 (docs closure, deliberately last).

## Accumulated Context

v2.11 shipped and archived (Phases 119-124, 2026-07-28). Full decision log lives in `PROJECT.md` Key Decisions; the milestone archive is under `milestones/v2.11-*`.

### Carryover resolved into Milestone C roadmap

- **WINDOWS ids 1-3 (deferred v2.11 polish)** → mapped to Phase 126 (POLISH-01/02/03): invoice_dark table-body cells inherit default ink → illegible on dark bg (id 1); Ticket/ticket_dark themed uniform type scale inverts intended display/title hierarchy — locked Phase-122 outcome, honestly `passed:false` (id 2); payslip themed numeric cells wrap mid-number at 10.5pt/1.35 leading (id 3).
- **Coverage depth (non-blocking)** → mapped to Phase 126 (POLISH-04/05): no dedicated `from_brand`/preset accent-op byte golden; dedicated `*_typography_test.exs` for only 3 of 7 recipes (other 4 on byte-identity + smoke).
- **Tooling gap (unresolved, environment-only):** pdfium-cli v0.11.0 not on PATH → `mix rendro.launch_artifacts.check` advisory lane fails locally (not a code defect; does not block roadmap phases).

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Studio | Live server-rendered theme playground | Deferred to Milestone D (`SEED-005`) | v2.11 scoping |
| Typography | Tabular figures / small-caps / OpenType features | Demand-gated (need new engine primitives) | v2.11 scoping |

## Session Continuity

Last session: 2026-08-17T00:40:03.150Z
Stopped at: Completed 125-07-PLAN.md
Resume file: None

## Next Steps

1. `/gsd-plan-phase 125` — plan Phase 125 (Foundation — curated fonts, style-genre presets & brand fixtures).
2. Continue in locked sequence: 125 → 126 → 127 → 128 → 129.

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 121 P01 | 25min | 2 tasks | 4 files |
| Phase 121 P04 | 3min | 2 tasks | 3 files |
| Phase 121 P02 | 12min | 2 tasks | 3 files |
| Phase 121 P03 | 20min | 2 tasks | 7 files |
| Phase 122 P01 | 18min | 2 tasks | 4 files |
| Phase 122 P02 | 32min | 3 tasks | 7 files |
| Phase 122 P03 | 9min | 3 tasks | 8 files |
| Phase 122 P04 | 4min | 2 tasks | 1 files |
| Phase 122 P05 | 14min | 3 tasks | 5 files |
| Phase 123 P01 | 2min | 2 tasks | 1 files |
| Phase 123 P02 | 30min | 2 tasks | 7 files |
| Phase 123 P03 | 26min | 3 tasks | 18 files |
| Phase 123 P04 | 14min | 3 tasks | 6 files |
| Phase 123 P05 | 6min | 2 tasks | 6 files |
| Phase 124 P01 | 6min | 3 tasks | 9 files |
| Phase 125 P01 | 2m | 1 tasks | 6 files |
| Phase 125-foundation-curated-fonts-style-genre-presets-brand-fixtures P07 | 9min | 2 tasks | 11 files |

## Operator Next Steps

- Plan Phase 125 with `/gsd-plan-phase 125`

## Decisions

- [Phase ?]: Theme.preset/2 delegates to private Presets; font registration stays explicit and document-owned.
- [Phase ?]: Generic brand tuples use a complete metadata branch while legacy fixtures retain explicit logo:null compatibility.
- [Phase ?]: Northline and Cedar use byte-identical local SVG marks across Invoice and Payslip for auditable identity reuse.

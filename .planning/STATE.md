---
gsd_state_version: 1.0
milestone: v2.6
milestone_name: Public Launch & Adoption Bootstrap
status: verified
last_updated: "2026-06-11T18:38:54.947Z"
last_activity: 2026-06-11
progress:
  total_phases: 6
  completed_phases: 4
  total_plans: 21
  completed_plans: 21
  percent: 67
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-10 — v2.6 milestone started)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Phase 86 — Self-Proving Launch Artifacts

## Current Position

Phase: 86 (Self-Proving Launch Artifacts) — VERIFIED
Plan: 5 of 5
Status: Verified
Last activity: 2026-06-11

Progress: [██████████] 100%

## Milestone Snapshot

- Shipped milestone: `v2.5 1.0 Release Capstone` — phases 78-82, 16 requirements, audit `passed`. Archived in `milestones/v2.5-ROADMAP.md`.
- Active milestone: `v2.6 Public Launch & Adoption Bootstrap` — phases 83-88, 21 requirements (HYG-01..05, PATH-01..04, RAST-01..03, GAL-01..03, CMP-01..03, LNCH-01..03).

## v2.6 Phase Map

| Phase | Name | Requirements | Depends on |
|-------|------|--------------|-----------|
| 83 | Claim-Accuracy & Shaping Hygiene | HYG-01..05 | — (must merge before 88) |
| 84 | Drawn-Path Primitive & Visible Polish | PATH-01..04 | — (parallel to 83) |
| 85 | Deterministic Raster Lane | RAST-01..03 | — (parallel to 83/84) |
| 86 | Self-Proving Launch Artifacts | GAL-01..03 | 84, 85 |
| 87 | Comparison Page & Livebook | CMP-01..03 | 83 |
| 88 | Launch Execution & Demand Instrumentation | LNCH-01..03 | 83, 84, 85, 86, 87 |

## Accumulated Context

### Decisions

Full decision log in PROJECT.md Key Decisions table. v2.6 scoping decisions (locked 2026-06-10):

- v2.6 is a launch/adoption milestone, not a feature milestone — Rendro has 1.0-grade depth at ~856 self/CI downloads, 0 stars, never announced.
- Fix "pure Elixir core" claim before launch — `harfbuzz_ex` is currently a hard NIF dep; Phase 83 must merge before Phase 88 executes.
- Path primitive is declarative (`%Rendro.Path{}`), not imperative canvas; all coordinates route through `format_num` for byte-determinism.
- Raster lane is always advisory — `pdfium-render` evidence vocabulary stays distinct from GUI-viewer proof; a pdfium download failure must never block the four required engine lanes.
- Benchmark guide is honest about ChromicPDF's strengths; unfair benchmarks poison the launch.
- Demand gate thresholds (LNCH-03) must be concrete and numeric — "adopter demand" failed as a gate before.
- [Phase ?]: Used @tag :skip for RED Wave 0 test stubs — :pending not in ExUnit exclude list; :skip ensures mix test exits 0 during Wave 0 scaffolding
- [Phase ?]: render_args/3 separate private function
- [Phase 85]: `pdfium-render` is reserved for top-level raster evidence; GUI-viewer promotion rows stay limited to manual, pdfium-cli, and pdfjs-dist.
- [Phase 85]: `Pdfium.render/2` validates `pages:` as a strict numeric page range before executable lookup or command execution.

### Pending Todos

None.

### Blockers/Concerns

None.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| globalization | v2.7 Global Text Shaping & Script Support | conditional — pursue only when LNCH-03 gate triggers |
| automation | release-please / publish automation | deferred — BEAM norm is manual/semi-manual; `git_ops` is the cheap future alternative |
| packaging | Split into separate `rendro` / `rendro_adapters` hex packages | deferred |
| layout | Even/odd header content variants (duplex) | post-v2.6 |
| layout | Section-local page number restart | post-v2.6 |
| layout | TOC primitive (no-fixpoint reserve-space design) | post-v2.6 |
| layout | Charts (`%Rendro.Chart{}` lowering to Path+Text) | post-v2.6 |
| viewer_proof | PDF.js render lane (Node-based `pdfjs-dist` adapter) | post-v2.6 |
| viewer_proof | Annual/semi-annual re-verification cadence enforcement | advisory |
| workflows | Multi-signature workflows and signer orchestration | deferred |
| path | Transforms, clipping, gradients (explicit matrix deferrals) | post-v2.6 |

## Session Continuity

Last session: 2026-06-11T18:38:54.943Z
Stopped at: Verified Phase 86; next action /gsd-discuss-phase 87
Resume file: None

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 85-deterministic-raster-lane P01 | 4 | 2 tasks | 6 files |
| Phase 85 P02 | 2 | 2 tasks | 3 files |
| Phase 85-deterministic-raster-lane P04 | 3min | 2 tasks | 5 files |
| Phase 85 P06 | 9 min | 3 tasks | 5 files |
| Phase 85 P05 | 8 min | 3 tasks | 4 files |
| Phase 86 P01 | 2min | 2 tasks | 2 files |
| Phase 86 P02 | 5min | 2 tasks | 2 files |
| Phase 86 P03 | 3min | 2 tasks | 2 files |
| Phase 86 P04 | 3min | 3 tasks | 4 files |
| Phase 86 P05 | 16min | 3 tasks | 19 files |

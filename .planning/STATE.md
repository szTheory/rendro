---
gsd_state_version: 1.0
milestone: v2.6
milestone_name: Public Launch & Adoption Bootstrap
status: Awaiting next milestone
last_updated: "2026-06-13T01:07:12.533Z"
last_activity: 2026-06-13 — Milestone v2.6 completed and archived
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 32
  completed_plans: 32
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-13 — v2.6 milestone completed)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Planning next milestone

## Current Position

Phase: Milestone v2.6 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-06-13 — Milestone v2.6 completed and archived

## Milestone Snapshot

- Shipped milestone: `v2.6 Public Launch & Adoption Bootstrap` — phases 83-88, 21 requirements, audit `passed`. Archived in `milestones/v2.6-ROADMAP.md`, `milestones/v2.6-REQUIREMENTS.md`, `milestones/v2.6-MILESTONE-AUDIT.md`, and `milestones/v2.6-phases/`.
- Previous shipped milestone: `v2.5 1.0 Release Capstone` — phases 78-82, 16 requirements, audit `passed`. Archived in `milestones/v2.5-ROADMAP.md`.
- Next milestone: not selected. Start with `/gsd-new-milestone`.

## v2.6 Phase Map (Archived)

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

Full decision log in PROJECT.md Key Decisions table. v2.6 decisions shipped and archived:

- v2.6 was a launch/adoption milestone, not a feature milestone — Rendro had 1.0-grade depth but needed truthful public proof surfaces and intake.
- Fix "pure Elixir core" claim before launch — `harfbuzz_ex` is optional behind a behaviour; `Shaper.Simple` is the default pure-Elixir path.
- Path primitive is declarative (`%Rendro.Path{}`), not imperative canvas; all coordinates route through `format_num` for byte-determinism.
- Raster lane is always advisory — `pdfium-render` evidence vocabulary stays distinct from GUI-viewer proof; a pdfium download failure must never block the four required engine lanes.
- Benchmark guide is honest about ChromicPDF's strengths; unfair benchmarks poison the launch.
- Demand gate thresholds (LNCH-03) must be concrete and numeric — "adopter demand" failed as a gate before.
- Phase 88 quiet public posture: keep README, HexDocs, ADOPTION.md, and issue templates available for people who find Rendro, but do not require announcements, listings, demand-thread replies, or other proactive outreach. External promotion is deferred unless the maintainer explicitly opts in later.
- [Phase ?]: Used @tag :skip for RED Wave 0 test stubs — :pending not in ExUnit exclude list; :skip ensures mix test exits 0 during Wave 0 scaffolding
- [Phase ?]: render_args/3 separate private function
- [Phase 85]: `pdfium-render` is reserved for top-level raster evidence; GUI-viewer promotion rows stay limited to manual, pdfium-cli, and pdfjs-dist.
- [Phase 85]: `Pdfium.render/2` validates `pages:` as a strict numeric page range before executable lookup or command execution.
- [Phase 88]: Prefer issue-only OSS intake over GitHub Discussions; Issues are the lightweight dumping ground that can be scanned and triaged efficiently with `gh` and LLM workflows.
- [Phase 88]: Zero-human UAT governs mobile viewer evidence; iOS Files/Preview and Android Drive mobile GUI rows remain `explicit_deferral` until automated device-level CI evidence exists, and anecdotal local opening does not promote support rows.

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

Last session: 2026-06-13T01:07:12Z
Stopped at: v2.6 milestone archived; awaiting next milestone selection
Resume file: None

## Quick Tasks Completed

| Date | Task | Summary |
|------|------|---------|
| 2026-06-12 | Automate HexDocs publish and public URL verification on main | `.github/workflows/hexdocs.yml` publishes docs-only with `HEX_API_KEY` after main pushes and runs `scripts/verify_public_launch_urls.sh`. |
| 2026-06-12 | Update Phase 88 to quiet public posture | Removed proactive announcement obligations; Rendro stays quietly public with low-maintenance issue-only intake. |

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
| Phase 87 P01 | 23 min | 2 tasks | 8 files |
| Phase 87 P02 | 58 min | 3 tasks | 21 files |
| Phase 87 P04 | 15 min | 3 tasks | 6 files |
| Phase 87 P03 | 14 min | 3 tasks | 4 files |
| Phase 87 P05 | 6 min | 3 tasks | 6 files |
| Phase 87 P06 | 12 min | 3 tasks | 5 production files plus planning |
| Phase 88 P01 | 12 min | 2 tasks | 7 files |
| Phase 88 P02 | 11 min | 2 tasks | 4 files |
| Phase 88 P03 | 9 min | 2 tasks | 4 files |
| Phase 88 P04 | 28 min | 2 tasks | 8 files |

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone

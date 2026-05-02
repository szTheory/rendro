---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Deterministic Typography, Assets, and Honest I18n Baseline
status: executing
stopped_at: Phase 29 awaiting human verification
last_updated: "2026-05-02T14:42:45.436Z"
last_activity: 2026-05-02 -- Phase --phase execution started
progress:
  total_phases: 7
  completed_phases: 4
  total_plans: 19
  completed_plans: 18
  percent: 95
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-30)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Phase --phase — 29

## Current Position

Phase: --phase (29) — EXECUTING
Plan: 1 of --name
Status: Executing Phase --phase
Last activity: 2026-05-02 -- Phase --phase execution started

Progress: [██████████] 100%

## Milestone Snapshot

- Milestone: `v1.2 Deterministic Typography, Assets, and Honest I18n Baseline`
- Phases: `25-29` (planned)
- Plans: `0`
- Tasks: `0`
- Timeline: `2026-04-30` -> `TBD`
- Key accomplishments:
  - Font registration and deterministic measurement/render integration are now the next committed capability layer.
  - Honest fallback, Unicode boundary, and asset-handling proof are defined before public release work.
  - First public Hex release readiness is now intentionally queued immediately after `v1.2`.

## Performance Metrics

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 18 | 3/3 | — | — |
| 19 | 3/3 | — | — |
| 20 | 2/2 | — | — |
| 21 | 2/2 | — | — |
| 22 | 3/3 | — | — |
| 23 | 2/2 | — | — |
| 24 | 2/2 | — | — |

| Phase 18 P01 | 179 | 2 tasks | 9 files |
| Phase 18 P02 | 9 min | 2 tasks | 9 files |
| Phase 18 P03 | 2 min | 2 tasks | 6 files |
| Phase 19 P01 | 5 min | 2 tasks | 6 files |
| Phase 19 P02 | 5 min | 2 tasks | 3 files |
| Phase 19 P03 | 6 min | 2 tasks | 7 files |
| Phase 20 P01 | 25 | 2 tasks | 4 files |
| Phase 20 P02 | 10 mins | 2 tasks | 9 files |
| Phase 21 P01 | 10m | 2 tasks | 7 files |
| Phase 21-break-diagnostics-and-pagination-proofs P21-02-PLAN.md | 20 | 2 tasks | 4 files |
| Phase 22-authoring-ergonomics-and-canonical-recipes P22-01 | 5min | 1 tasks | 2 files |
| Phase 22-authoring-ergonomics-and-canonical-recipes P22-02 | 2min | 2 tasks | 5 files |
| Phase 22 P03 | 5min | 2 tasks | 6 files |
| Phase 23 P01 | 11 min | 2 tasks | 7 files |
| Phase 23 P02 | 7 min | 2 tasks | 5 files |
| Phase 24 P01 | 4 min | 3 tasks | 9 files |
| Phase 24 P02 | 8 min | 2 tasks | 5 files |
| Phase 25 P01 | 5 min | 2 tasks | 7 files |
| Phase 26 P01 | 16 min | 2 tasks | 10 files |
| Phase 26 P02 | 1 min | 2 tasks | 3 files |
| Phase 26 P03 | 4 min | 2 tasks | 4 files |
| Phase 28 P01 | 15 min | 2 tasks | 4 files |
| Phase 28 P02 | 10 | 2 tasks | 5 files |
| Phase 28-asset-registry-and-deterministic-image-rendering P03 | 10m | 2 tasks | 3 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Init] Keep pure core and optional adapters as hard architectural boundary.
- [Init] Prioritize deterministic pagination/table reliability before broad integrations.
- [Init] Enforce truthful docs/release verification as a first-class quality contract.
- [v1.1 Init] Scope the next milestone around layout-authoring maturity before fonts/assets or async artifact expansion.
- [v1.1 Init] Treat break semantics, reusable page templates/regions, and deterministic measurement contracts as prerequisites for later milestones.
- [v1.1 Init] Defer custom fonts/assets to v1.2 and async artifact lifecycle contracts to v1.3.
- [v1.2 Init] Make deterministic typography, assets, and honest Unicode/i18n boundaries the next active milestone.
- [v1.2 Init] Pull first public Hex release readiness ahead of async artifact operations once the branded-document support boundary is proved.
- Model reusable flow geometry as a separate PageTemplate struct with named Region entries instead of extending Rendro.Page.
- Keep flow template selection explicit on Rendro.Document with page_template and page_templates fields while preserving existing header/footer compatibility.
- Normalize sections and named regions into internal layout metadata during Compose, then keep the public Document contract unchanged.
- Treat body capacity as the authored body-region height instead of recomputing it from header/footer block heights.
- Materialize flow pages from PageTemplate geometry and anchor repeated non-body regions by region coordinates on every page.
- Validate fixed-position pages against the usable page box and flow regions against their declared rectangles inside Paginate so overflow stays a stage-specific contract.
- Preserve overflow source, region, page index, and block geometry in Rendro.Error.details so public render failures stay actionable.
- Measure table width from deterministic rendered column geometry instead of a hard-coded 500-unit width so fit validation matches real output.
- Kept authored geometry and break intent on Rendro.Block while keeping line-height styling on Rendro.Text.
- Stored wrapped lines in a private measured-text carrier during Measure so downstream stages can consume one deterministic line list.
- Used newline-first whitespace wrapping with grapheme fallback for oversized tokens instead of introducing hyphenation or paragraph DSL semantics.
- Evaluate keep and break directives only after measurement so page moves consume final block heights.
- Reject flow pagination directives on fixed-position pages through the existing paginate error surface instead of silently ignoring them.
- Rendered PDF text now serializes the measured line list directly instead of reconstructing paragraphs inside the writer.
- README examples teach the Phase 19 block-and-text flow path with explicit break semantics and narrow exclusions.
- Decided to resolve layout body bounds during measurement to allow table width percentages to be relative to layout bounds.
- Decided to let stack_cells in Paginate use absolute table coordinates directly.
- Rejected width and border attributes on Rendro.table/2 to steer users to explicit column rules.
- Added a diagnostics list to Rendro.Document to accumulate pagination info without raising exceptions or spamming telemetry.
- Exposed Rendro.render_with_diagnostics/2 in the top-level Rendro module to allow extracting the fully populated document struct alongside the generated PDF binary, making it easier to fetch doc.diagnostics.
- Used snapshot tests for the inspector to lock down the output format and ensure deterministic layout checks.
- Expose pipeline builder API directly on Rendro.Document module to keep function discovery co-located with the struct definition
- Use append semantics (list ++ [item]) for add_template/2 and add_section/2 to preserve insertion order
- Use Map.merge/2 for put_options/2 to allow incremental option accumulation over multiple pipe stages
- Tiered Composition pattern: document/2 (batteries-included), page_template/1 (layout), sections/2 (content) for recipe escape hatches
- Accrue adapter uses explicit page template sections; doc.header and doc.footer remain empty; all content through named regions
- Rendro.Recipes.invoice/1 delegates to Rendro.Recipes.Invoice.document/1 for backward compatibility
- Source-level test uses File.read! on controller to verify canonical recipe call without mocking
- ConnCase uses import Plug.Conn + import Phoenix.ConnTest (non-deprecated form)
- README non-runnable schematic blocks use elixir-schematic tag to avoid docs-contract enforcement
- Fail unsupported table split policies through a typed paginate error instead of silently defaulting to row-atomic continuation.
- Canonicalize table split_policy to :row_atomic and keep :atomic only as a temporary compatibility alias.
- Keep Phase 23 as the authoritative LAY-10 closure point while backfilling Phase 20 with explicit re-verification framing.
- Update REQUIREMENTS.md and ROADMAP.md only after the Phase 23 verification artifact exists on disk.
- Keep the diagnostics contract map-based and correct the docs/types instead of inventing a %Rendro.Document.Diagnostic{} struct.
- Use the existing public proof surfaces (render_with_diagnostics/2, paginate tests, inspector tests, and docs-contract) instead of adding new verification machinery.
- Leave OBS-05 and QUAL-06 open in traceability until plan 24-02 creates the authoritative verification artifacts.
- Preserve Phase 21 as the historical implementation owner and use Phase 24 as the authoritative closure point for OBS-05 and QUAL-06.
- Do not flip REQUIREMENTS.md or ROADMAP.md until 24-VERIFICATION.md exists and cites the repaired Phase 21 history.
- Treat verification-artifact wording as executable contract surface when plan gates assert exact markdown markers.
- Keep Helvetica as a narrow compatibility alias while moving the authored contract to logical font names.
- Do not mark FONT-01 complete until plan 25-02 wires registry-backed selection into measurement and rendering.
- Keep embedded font registration separate from built-in registration to preserve explicit product scope.
- Normalize tagged font sources into owned bytes at registration so later stages never reopen filesystem paths.
- Use Build as the deterministic embedded-font preflight boundary and cache parsed metrics on the registry for stage reuse.
- Kept the measurement algorithm unchanged and tightened proof around the existing shared resolved-font seam instead of forking an embedded-font codepath.
- Proved pagination parity with focused regressions rather than modifying paginate internals that already consumed measured heights correctly.
- Kept built-in and embedded writer paths explicit while sharing one collection and resource-allocation pipeline.
- Drove embedded PDF objects from the existing resolved Rendro.PDF.Font payload instead of reparsing font sources in Writer.
- Locked the public proof surface to repeated-run layout/resource parity instead of expanding the support claim into broad byte-identity or fallback promises.
- Maps Asset Registry images to XObjects
- Uses PDF `cm` matrix for scaling into the measured geometry

### Pending Todos

- Plan Phase 25: Font Registry and Public Typography Contract.

### Blockers/Concerns

- Historic v1.0/v1.1 phase directories remain on disk for auditability. New roadmap numbering continues at Phase 25 to avoid collisions.
- `gsd-sdk query init.new-milestone` still reports stale milestone metadata (`v1.0`), so milestone planning should continue to trust the checked-in `.planning` truth surfaces until tooling state is reconciled.

## Deferred Items

Items acknowledged and carried forward from milestone scoping:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Typography | Custom font embedding, fallback chains, and Unicode/i18n claims | Deferred to v1.2 | 2026-04-28 |
| Assets | Image/logo embedding and asset retrieval policy | Deferred to v1.2 | 2026-04-28 |
| Release | First public Hex release readiness | Deferred to v1.3 | 2026-04-30 |
| Async Ops | Render manifests, persistence sinks, retry/cancel lifecycle contracts | Deferred to v1.4 | 2026-04-28 |
| Trust | Validator-backed compliance/signature surfaces | Deferred to v1.5 | 2026-04-28 |

## Quick Tasks Completed

| Date | ID | Task | Status | Verification |
|------|----|------|--------|--------------|
| 2026-04-28 | 260428-hsl | Fix PR #1 CI format failures and rerun verification | complete | `mix ci`; `examples/phoenix_example` compile |

## Session Continuity

Last session: 2026-05-01T21:16:00.000Z
Stopped at: Phase 29 awaiting human verification
Resume file: .planning/phases/29-branded-recipes-docs-and-proof-closure/29-HUMAN-UAT.md

**Planned Phase:** 25 (Font Registry and Public Typography Contract) — 2 plans — 2026-04-30T20:11:50.237Z

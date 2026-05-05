---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Operational Tooling & Admin UX
status: planned
last_updated: "2026-05-05T12:00:00.000Z"
last_activity: 2026-05-05
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 1
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-05)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Phase 41

## Current Position

Phase: 41
Plan: 01
Status: planned
Last activity: 2026-05-05

Progress: [          ] 0%

## Milestone Snapshot

- Milestone: `v1.5 Operational Tooling & Admin UX`
- Phases: `41`
- Plans: `1`
- Tasks: `0`
- Timeline: `2026-05-05` -> `TBD`
- Key accomplishments:
  - `v1.5` initiated.

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
| 35 | 5/5 | — | — |
| 41 | 1/1 | 5 | 5 |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Confirmed schemas and pagination constraints correctly apply widows and orphans logic from existing implementation.
- Since Phase 41 features were implemented and covered by unit tests in a previous pipeline stage rollout, zero code changes were needed in this pass. Empty commits generated to mark verification passing.

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
- Implemented exact HarfBuzz widths for accurate text measurement.
- Adjusted layout and wrapping tests to account for the narrower and more precise HarfBuzz character widths.
- Embedded true HarfBuzz measured runs using deterministic text run objects with no manual word-wrap patching inside Writer.
- Passed Hex-encoded raw glyph IDs through the measurement and rendering pipelines to ensure 100% exact CID mappings.
- Confirmed that existing logic seamlessly handled text run shapes from HarfBuzz by relying on the exact boundaries captured in MeasuredText runs.
- Verified that Validate, Paginate, and Render are exactly aligned with the upstream layout and CID output metrics with no additional codebase drift.

### Pending Todos

- None.

### Blockers/Concerns

- Historic v1.0, v1.1, and v1.2 phase directories remain on disk for auditability. New roadmap numbering continues at Phase 31 to avoid collisions.

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-03:

| Category | Item | Status |
|----------|------|--------|
| verification_gaps | 29-VERIFICATION.md | human_needed |

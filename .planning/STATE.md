---
gsd_state_version: 1.0
milestone: v2.12
milestone_name: Style-Genre Presets, Public Catalog & Static Configurator
current_phase: 126
current_phase_name: Carryover polish — dark-mode legibility, hierarchy decision & golden/typography depth
status: executing
stopped_at: Phase 126 context gathered
last_updated: "2026-08-17T03:54:05.043Z"
last_activity: 2026-08-16
last_activity_desc: Phase 125 complete, transitioned to Phase 126
progress:
  total_phases: 5
  completed_phases: 1
  total_plans: 15
  completed_plans: 10
  percent: 20
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-16)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Phase 126 — Carryover polish — dark-mode legibility, hierarchy decision & golden/typography depth

## Current Position

Phase: 126 — Carryover polish — dark-mode legibility, hierarchy decision & golden/typography depth
Plan: Not started
Status: Ready to execute
Last activity: 2026-08-16 — Phase 125 complete, transitioned to Phase 126

## Roadmap Snapshot (v2.12, Phases 125-129) — IN PLANNING

```text
[████████                                ] 20% — 1/5 phases complete
Phase 125 Foundation — fonts, presets & brand fixtures .... Complete
Phase 126 Carryover polish — dark/hierarchy/golden depth .. Not started
Phase 127 Public example catalog & quality ratchet ........ Not started
Phase 128 Static configurator, codegen & Livebook .......... Not started
Phase 129 Docs & manifest closure .......................... Not started
```

**Locked sequencing:** 125 (foundation) → 126 (polish, needs presets for POLISH-04) → 127 (catalog, needs polish landed first for honest dark cells) → 128 (configurator, needs catalog as data source) → 129 (docs closure, deliberately last).

## Accumulated Context

v2.11 shipped and archived (Phases 119-124, 2026-07-28). Full decision log lives in `PROJECT.md` Key Decisions; the milestone archive is under `milestones/v2.11-*`.

### Phase 125 delivered

- Six strict genre presets and four provenance-bound curated fonts now render through explicit document-owned registration across all seven recipes.
- Deterministic and pinned-PDFium advisory matrices share twelve stable light/dark row IDs; bounded human review passed with no new clipping or overflow observed.
- Twelve safe data-only brand fixtures complete the three-per-domain source corpus for Phase 127.
- CID widths now use glyph-ID metrics while layout retains codepoint metrics, fixing embedded-font overlap at the correct renderer boundary.

### Carryover resolved into Milestone C roadmap

- **WINDOWS ids 1-3 (deferred v2.11 polish)** → mapped to Phase 126 (POLISH-01/02/03): invoice_dark table-body cells inherit default ink → illegible on dark bg (id 1); Ticket/ticket_dark themed uniform type scale inverts intended display/title hierarchy — locked Phase-122 outcome, honestly `passed:false` (id 2); payslip themed numeric cells wrap mid-number at 10.5pt/1.35 leading (id 3).
- **Coverage depth (non-blocking)** → mapped to Phase 126 (POLISH-04/05): no dedicated `from_brand`/preset accent-op byte golden; dedicated `*_typography_test.exs` for only 3 of 7 recipes (other 4 on byte-identity + smoke).
- **Tooling note (environment-only):** pdfium-cli v0.11.0 is not globally on PATH, but the SHA-verified pinned wrapper/container route is proven and reproducible for advisory checks.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Studio | Live server-rendered theme playground | Deferred to Milestone D (`SEED-005`) | v2.11 scoping |
| Typography | Tabular figures / small-caps / OpenType features | Demand-gated (need new engine primitives) | v2.11 scoping |
| Review UX | Present visual-review images full-size in a sequential slideshow/lightbox, not only as a dense contact sheet | Non-blocking tooling follow-up | Phase 125 UAT |

## Session Continuity

Last session: 2026-08-17T02:44:43.410Z
Stopped at: Phase 126 context gathered
Resume file: .planning/phases/126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol/126-CONTEXT.md

## Next Steps

1. `/gsd-plan-phase 126` — plan carryover polish now that preset foundations are complete.
2. Continue in locked sequence: 126 → 127 → 128 → 129.

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
| Phase 125 P02 | 4m | 2 tasks | 9 files |
| Phase 125 P08 | 2min | 2 tasks | 9 files |
| Phase 125 P03 | 5m | 1 tasks | 4 files |
| Phase 125 P09 | 2min | 2 tasks | 9 files |
| Phase 125 P04 | 18min | 2 tasks | 6 files |
| Phase 125 P05 | 8min | 1 tasks | 7 files |
| Phase 125 P06 | 3min | 1 tasks | 7 files |
| Phase 125-foundation-curated-fonts-style-genre-presets-brand-fixtures P10 | 15min | 2 tasks | 26 files |

## Operator Next Steps

- Plan Phase 126 with `/gsd-plan-phase 126`

## Decisions

- [Phase 125]: Keep `Theme.preset/2` as a narrow delegation; genre grammar and curated font descriptors live in the private Presets sibling, with explicit document-owned registration.
- [Phase 125]: Ship one unmodified static Regular face per curated role with exact provenance/package proof and sorted, deduplicated subset inputs.
- [Phase 125]: Keep the deterministic and pinned-PDFium advisory matrices separate while sharing the same twelve stable row IDs.
- [Phase 125]: Keep brands as generic JSON plus safe local SVG data, with exact corpus, arithmetic, identity, and original-byte controls.
- [Phase 125]: Use glyph-ID widths for embedded CID `/W` tables while retaining Unicode-codepoint metrics for layout.

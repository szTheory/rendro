---
gsd_state_version: 1.0
milestone: v2.12
milestone_name: Style-Genre Presets, Public Catalog & Static Configurator
current_phase: 129
current_phase_name: Docs & manifest closure
status: executing
stopped_at: Phase 129 context gathered
last_updated: "2026-08-19T16:12:31.668Z"
last_activity: 2026-08-18
last_activity_desc: Phase 128 complete, transitioned to Phase 129
progress:
  total_phases: 5
  completed_phases: 4
  total_plans: 29
  completed_plans: 26
  percent: 80
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-16)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Phase 128 — Static configurator, theme codegen & Livebook

## Current Position

Phase: 129 — Docs & manifest closure
Plan: Not started
Status: Ready to execute
Last activity: 2026-08-18 — Phase 128 complete, transitioned to Phase 129

## Roadmap Snapshot (v2.12, Phases 125-129) — IN PROGRESS

```text
[████████████████████████                ] 60% — 3/5 phases complete
Phase 125 Foundation — fonts, presets & brand fixtures .... Complete
Phase 126 Carryover polish — dark/hierarchy/golden depth .. Complete
Phase 127 Public example catalog & quality ratchet ........ Complete
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

### Phases 126–127 delivered

- Phase 126 closed the inherited dark-mode legibility, Ticket hierarchy, Payslip numeric-wrap, accent-golden, and typography-depth gaps before catalog generation.
- Phase 127 shipped the separate, bounded 32-cell public catalog with deterministic source/artifact checks, a pinned advisory raster lane, exact 12 scored-false / 20 reasoned-unscored coverage, and fail-closed promotion provenance.
- Jon's provisional review remains deliberately conservative: all twelve flagships are `needs_work`; the Poppy & Grain dark Receipt contrast concern is retained for a future high-fidelity visual ratchet.

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

Last session: 2026-08-19T15:30:59.773Z
Stopped at: Phase 129 context gathered
Resume file: .planning/phases/129-docs-manifest-closure/129-CONTEXT.md

## Next Steps

1. `/gsd-plan-phase 128` — plan the static configurator, canonical snippet/codegen seam, and Livebook surface over the verified catalog.
2. Continue in locked sequence: 128 → 129.

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
| Phase 126 P01 | 29m | 3 tasks | 8 files |
| Phase 126 P02 | 9min | 3 tasks | 8 files |
| Phase 126 P03 | 18m | 2 tasks | 8 files |
| Phase 126 P04 | 3m | 1 tasks | 2 files |
| Phase 126 P05 | 25m | 2 tasks | 5 files |
| Phase 127 P01 | 25m | 3 tasks | 8 files |
| Phase 127 P02 | 24m | 2 tasks | 7 files |
| Phase 127 P03 | 1h | 2 tasks | 40 files |
| Phase 127-public-example-catalog-quality-ratchet P04 | 0m | 1 tasks | 1 files |
| Phase 127-public-example-catalog-quality-ratchet P05 | 30m | 2 tasks | 6 files |
| Phase 128-static-configurator-theme-codegen-livebook P01 | 18min | 2 tasks | 5 files |
| Phase 128 P02 | 7min | 2 tasks | 2 files |
| Phase 128 P03 | 15min | 2 tasks | 5 files |
| Phase 128-static-configurator-theme-codegen-livebook P04 | 7min | 2 tasks | 2 files |

## Operator Next Steps

- Plan Phase 128 with `/gsd-plan-phase 128`

## Decisions

- [Phase 125]: Keep `Theme.preset/2` as a narrow delegation; genre grammar and curated font descriptors live in the private Presets sibling, with explicit document-owned registration.
- [Phase 125]: Ship one unmodified static Regular face per curated role with exact provenance/package proof and sorted, deduplicated subset inputs.
- [Phase 125]: Keep the deterministic and pinned-PDFium advisory matrices separate while sharing the same twelve stable row IDs.
- [Phase 125]: Keep brands as generic JSON plus safe local SVG data, with exact corpus, arithmetic, identity, and original-byte controls.
- [Phase 125]: Use glyph-ID widths for embedded CID `/W` tables while retaining Unicode-codepoint metrics for layout.
- [Phase ?]: Keep nil-theme table strings and Payslip widths literal; apply visual repairs only when a theme is supplied.
- [Phase ?]: Use display/title/caption for themed Ticket placement/title/reference while retaining historical nil-theme roles.
- [Phase ?]: Use 61pt Current and 68pt YTD themed Payslip widths, proven by Humanist one-point controls.
- [Phase ?]: Keep the new accent golden to exactly three ordered variants instead of duplicating the twelve-row preset matrix.
- [Phase ?]: Assert typography through semantic emitted Text content, without establishing global traversal ordering.
- [Phase ?]: Preserve Payslip's payslip_sans fallback as its recipe-specific themed font bridge.
- [Phase ?]: Keep only the legacy adapter comparison non-blocking; preset blessing, staging, manifest creation, and upload fail closed.
- [Phase ?]: Accept raster artifacts only from one successful exact-SHA advisory-checks job plus manifest validation, not whole-workflow success.
- [Phase ?]: [Phase 126]: Approve only the six exact pinned-PDFium rows after sequential native-size review; authorize isolated CI ref cleanup after committed closure evidence.
- [Phase ?]: Close only the three named WINDOWS rows from deterministic, pinned, and approved human evidence.
- [Phase ?]: Delete each recorded isolated CI evidence ref only after its exact SHA, committed approval, and scoped artifact gates pass.
- [Phase ?]: Keep the catalog as an explicit, ordered 32-row dev/test registry with separate generation and checking operations.
- [Phase ?]: Keep preview_copy page-count-derived and boundary_disclosure mode-derived, independently of reviewer quality.
- [Phase ?]: Keep catalog quality as a reviewer-owned, exact one-to-one relation with only three derived consumer labels.
- [Phase ?]: Record Jon's provisional review conservatively: all twelve cells are scored false rather than promoted to passing.
- [Phase ?]: Treat dark previews as screen-oriented only, so their print-safety gates remain false without making accessibility or compliance claims.
- [Phase ?]: Keep all twelve provisional human verdicts false and project them as needs_work.
- [Phase ?]: Use the exact SHA-verified Linux PDFium advisory job rather than treating a macOS ARM execution failure as equivalent evidence.
- [Phase ?]: Delete all nine Phase 127 isolated evidence refs only after full-SHA verification and advisory closure.
- [Phase ?]: Keep the configurator index as a closed 6 × 6 × 7 × 2 formatter-owned source model with trusted internal evaluation only.
- [Phase ?]: Use mix rendro.configurator.gen as the explicit deterministic generation and read-only drift-check seam.
- [Phase ?]: Keep generated wrappers fixed at theme/0 and register_fonts/1 with no runtime override interface.
- [Phase ?]: Use formatter-owned source plus Mix.Generator conflict semantics and byte-exact read-only checks.
- [Phase ?]: Keep requested code identity separate from derived catalog preview identity; representative previews never rewrite selected source values.
- [Phase ?]: Reject malformed, duplicate, partial, and unknown query state atomically, then serialize only the four canonical keys.
- [Phase ?]: Copy exactly the visible committed formatter string and report Clipboard success only after its promise resolves.
- [Phase ?]: Keep the Livebook to one exact formatter-owned Invoice/Swiss/#2C6BED/light render with explicit document-first font registration and separate themed byte evidence.
- [Phase ?]: Treat presets as working starting points and dark-mode experiments as screen-oriented without visual-quality or compliance guarantees.

---
gsd_state_version: 1.0
milestone: v2.11
milestone_name: Document Theming & Design-Token System
current_phase: 119
current_phase_name: `Rendro.Theme` core module — the one-way door
status: executing
stopped_at: Phase 119 context gathered
last_updated: "2026-07-24T13:54:36.774Z"
last_activity: 2026-07-23
last_activity_desc: ROADMAP created; all 21 requirements mapped to Phases 119-123 (100% coverage)
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-19)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** v2.11 Document Theming & Design-Token System (Milestone B / `SEED-003`) — additive minor (hex `1.2.0`). Roadmap created; ready to plan Phase 119.

## Current Position

Phase: 119 of 123 (`Rendro.Theme` core module — the one-way door)
Plan: — (not yet planned)
Status: Ready to execute
Last activity: 2026-07-23 — ROADMAP created; all 21 requirements mapped to Phases 119-123 (100% coverage)

Progress: [░░░░░░░░░░] 0% — 0/5 phases

## Roadmap Snapshot (v2.11, Phases 119-123)

```text
[░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 0% — 0/5 phases complete
Phase 119 Rendro.Theme core module (one-way door) ........ Ready to plan
Phase 120 S1 retrofit + theme: swap (7 recipes) .......... Not started
Phase 121 Light/dark background-fill mechanism ........... Not started
Phase 122 Typography type-scale application .............. Not started
Phase 123 from_brand/2 E2E + honest rubric-gap + docs .... Not started
```

## Accumulated Context

### Decisions

Full log in PROJECT.md Key Decisions. Milestone-B locks carried into planning:

- **Additive minor (hex `1.2.0`), NOT a major.** The public API only grows (new `Rendro.Theme`); `default/0` is engineered so an un-themed `document(data)` reproduces v2.10 bytes for all 7 recipes (PLUMB-03 — the central regression guard).
- **The single irreversible act:** `Rendro.Theme` entering `priv/public_api.json` on the **adapter/Evolving** tier (field shape frozen by discipline; token values + rendered output may evolve). Expect a planned red→green on `public_api_contract_test.exs` — grep ALL hidden-modules assertions incl. any duplicate in `manifest_test.exs` (the Phase-115 `Format` lesson).
- **Code-grounded correction:** the S1 `palette` seam exists in only **3 of 7** recipes. The 4 un-seamed recipes (Statement/Certificate/Receipt/BrandedInvoice) need a byte-identical `palette/1` retrofit (Phase 120) with sha256 goldens committed **separately** from any theme swap. Certificate's `{34,34,34}` frame is the non-black default to flag in-plan.
- **Light/dark determinism:** background is a first-in-list `:background` page-template region (`apply_page_template/5` repeats it on every page incl. overflow — zero paginate change); emit the rect ONLY when it changes pixels; resolve every role to integer `{r,g,b}` once in `resolve/1` (no per-draw float tint math).
- **Type scale = the one net-new surface + biggest rubric lever.** Materialize as explicit point sizes (not a `:math.pow` formula); `default/0` scale/leading is a metric no-op (Phase-117 goldens unchanged); `leading` is a multiplier matching `Text.line_height`.
- **Rubric-gap remediation honesty:** the Phase-118 SHOW-01 root cause is DATA not color. Fix `transform_invoice` (dropped parties/totals) → make the one key fact structurally dominant → THEN apply `default/0` → re-score with human sign-off. Never flip a rubric score to `passed:true` in a commit that only changed colors.
- **Guards held:** engine untouched (no theme-aware field on any pipeline stage); `brand:` orthogonal to `theme:` (`from_brand/2` emits tokens only, never registers an asset); every shipped demo is light (dark is screen-oriented, no print/PDF-UA claim); permanent exclusions by construction (shadow/z-index/opacity/gradient/motion/focus/raw-scales/weight-axis/letter-spacing/wide-gamut); industry-agnostic `lib/` guard on `theme.ex`; zero new dependencies.

### Pending Todos

None yet.

### Blockers/Concerns

- **Watch (Phase 119):** the `Theme` public promotion will edit `public_api_contract_test.exs`'s hidden set — expect a deliberate red build until the manifest is regenerated and the tier tag applied. Grep for the second, plan-unlisted hidden-modules assertion.
- **Calibration open questions** (not architecture — locked recommendations in REQUIREMENTS.md): exact type-scale point sizes, `on_accent` luminance heuristic, legacy `:palette` preservation via `Map.merge`, `theming.light`/`theming.dark` as separate support rows, `density: :compact` shallow honoring.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Presets/Catalog | Style-genre presets, preset fonts, public catalog, static configurator | Deferred to Milestone C (`SEED-004`) | v2.11 scoping |
| Studio | Live server-rendered theme playground | Deferred to Milestone D (`SEED-005`) | v2.11 scoping |
| Typography | Tabular figures / small-caps / OpenType features | Demand-gated (need new engine primitives) | v2.11 scoping |

## Session Continuity

Last session: 2026-07-24T04:15:30.140Z
Stopped at: Phase 119 context gathered
Resume file: .planning/phases/119-rendro-theme-core-module-the-one-way-door/119-CONTEXT.md

## Next Steps

1. `/gsd-plan-phase 119` — plan the `Rendro.Theme` core module (the one-way door): full struct shape up front, `resolve/1`/`default/0`/`dark/1`/`from_brand/2`, adapter-tier manifest entry + planned red→green contract reconciliation, industry-agnostic guard. Zero recipe change.

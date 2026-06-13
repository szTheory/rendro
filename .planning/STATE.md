---
gsd_state_version: 1.0
milestone: v2.8
milestone_name: Done-Enough Stewardship & Adoption Signal Loop
status: ready_to_plan
last_updated: 2026-06-13T19:14:27.655Z
last_activity: 2026-06-13
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 7
  completed_plans: 7
  percent: 75
stopped_at: Phase 95 complete (2/2) — ready to discuss Phase 96
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-13 — v2.8 Done-Enough Stewardship & Adoption Signal Loop started)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Phase 96 — adoption signal review & stewardship posture

## Current Position

Phase: 96
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-13

Progress: [██████████] 100%

## v2.8 Phase Map

| Phase | Name | Requirements | Depends on |
|-------|------|--------------|-----------|
| 93 | Recipes Facade DX Closure | DX-01, DX-02 | v2.4 recipes, v2.5 API contract |
| 94 | Docs & Warning Hygiene | HYG-01, HYG-02 | 93 |
| 95 | Header Duplex Proof & Metadata Reconcile | PROOF-01, META-01 | 94 |
| 96 | Adoption Signal Review & Stewardship Posture | SIGNAL-01, STEW-01 | 95 |

## Milestone Snapshot

- Active milestone: `v2.8 Done-Enough Stewardship & Adoption Signal Loop` — Phases 93-96, 8 requirements, stewardship-only scope.
- Completed milestone: `v2.7 Page Context & Browser Proof Hardening` — Phases 89-92, audit `passed`. Archived under `milestones/v2.7-*`.
- Done-enough estimate: 90-93% for Rendro's stated scope; remaining work is important-but-narrow.
- Global text shaping: still demand-gated by `ADOPTION.md`; not v2.8 scope.

## Accumulated Context

### Decisions

Full decision log in PROJECT.md Key Decisions table. Locked v2.8 research recommendations:

- DX facade: hand-written `@spec`'d arity-1 + arity-2 wrapper pairs (Ecto-thin-index model), fix the `invoice/1` opts-drop, regenerate `priv/public_api.json` via `mix rendro.api.gen`. No validation in the facade.
- HYG-01: `skip_code_autolink_to:` for prose refs + real `@moduledoc` on `Rendro.PDF.Font`; enforce `docs --warnings-as-errors` in the `ci` alias.
- HYG-02: viewer-evidence staleness is latent (fires ~late Nov 2026) — make it self-explaining, do NOT silence/raise/pre-record.
- PROOF-01: mirror footer proofs at render + paginate layers; reject Poppler-per-page and golden-bytes.
- SIGNAL-01: append a dated HOLD review to `ADOPTION.md` `## Review Log` — no new mix task.
- STEW-01: two locations (MILESTONE-ARC internal posture section + `guides/api_stability.md` public status section); signal "stable & cared-for," never "abandoned."
- [Phase 95]: PROOF-01: header only_on proven at render + paginate layers via additive tests over the shipped region-agnostic engine; no lib/ or public-API change
- [Phase 95]: META-01 v2.7 reconcile: flipped 90/92 false-pending task cells and 91 stale Planned header to passed; frontmatter status: untouched (D-07); 88 left as consistent draft (D-06)

### Pending Todos

None.

### Blockers/Concerns

None.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| globalization | Global Text Shaping & Script Support | conditional — pursue only when the `ADOPTION.md` demand gate triggers |
| layout | TOC, PDF outlines, anchors, cross-references | deferred — no concrete long-report adopter pressure |
| layout | Charts (`%Rendro.Chart{}`) | deferred — separate authoring/proof surface |
| viewer_proof | Mobile GUI viewer promotion | deferred — terminal `explicit_deferral`; no automated device evidence lane |
| automation | release-please / publish automation | deferred — BEAM norm is manual/semi-manual |
| outreach | Proactive launch/outreach obligations | deferred — quiet pull-based posture unless maintainer opts in |

## Session Continuity

Last session: 2026-06-13T19:05:54.014Z
Stopped at: Phase 95 context gathered
Resume file: None

## Operator Next Steps

- Plan the first phase with `/gsd:plan-phase 93`.

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 95 P01 | 2min | 3 tasks | 2 files |
| Phase 95 P02 | 2min | 3 tasks | 3 files |

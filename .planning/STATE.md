---
gsd_state_version: 1.0
milestone: v2.4
milestone_name: Batteries-Included Workflow & Adoption Closure
status: planning
last_updated: "2026-05-29T17:00:22.863Z"
last_activity: 2026-05-29
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 5
  completed_plans: 5
  percent: 25
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-29 after v2.3 milestone shipped)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Phase 74 — statement recipe

## Current Position

Phase: 74
Plan: Not started
Status: Ready to plan
Last activity: 2026-05-29

Progress: [██████████] 100%

## Milestone Snapshot

- Milestone: `v2.4 Batteries-Included Workflow & Adoption Closure` (active; roadmap created 2026-05-29; phases 73-76)
- Previous shipped milestone: `v2.3 Viewer Proof & Interop Closure` (shipped and archived on 2026-05-29 at tag `v0.3.1`; see `milestones/v2.3-MILESTONE-AUDIT.md`). All 26 (surface × viewer) cells terminal — 17 supported, 9 explicit_deferral, 0 silently unverified.
- Strategic next-up after v2.4: conditional `v2.5 Global Text Shaping & Script Support` only if demand justifies the core investment; then 1.0 release capstone.

## Phase Map

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 73 | Page-Numbering / Running-Region Primitive | PAGE-01, PAGE-02, PAGE-03, PAGE-04 | Not started |
| 74 | Statement Recipe | STMT-01, STMT-02, STMT-03, STMT-04 | Not started |
| 75 | Receipt/Report and Certificate Recipes + Support Contract | RCPT-01, RCPT-02, RCPT-03, CERT-01, CERT-02, CERT-03, CONTRACT-01 | Not started |
| 76 | Reference Phoenix App, CI, and Documentation Closure | REF-01, REF-02, REF-03, CONTRACT-02 | Not started |

## Performance Metrics

Per-phase metrics for shipped milestones live in their archives under `.planning/milestones/v[X.Y]-ROADMAP.md` and per-plan SUMMARY frontmatter.

## Accumulated Context

### Decisions

Full per-milestone decision log lives in `.planning/PROJECT.md` (Key Decisions table) and per-milestone archives. Carried forward into v2.4:

- [v2.3]: Support rows use a three-state vocabulary — `supported` (with evidence) / `explicit_deferral` (with a named reason) / `unverified` (un-attempted); silent `unverified` for a known-unsupportable cell is a recording-discipline failure.
- [v2.3]: Public-contract data files (`priv/support_matrix.json`) evolve strictly additively under a wired-in JSON-Schema validator in the required `test` job; viewer gaps are recorded as `explicit_deferral`, never patched into the writer.
- [v2.3]: Viewer evidence is text-only Markdown under `priv/viewer_evidence/`, fixtures by repo-path or content hash, with a durable operator recipe (`guides/viewer_evidence.md`) future surfaces inherit.
- [carried]: Lock the public contract before any first-party adapter ships; operationally enforce live proof as a required `main` status check; publish trust-sensitive support as distinct posture signals, not one binary "supported" row.
- [v2.4 roadmap]: Recipe base extraction (`Rendro.Recipes.Base`, `@moduledoc false`) is enabling work for the Statement phase (Phase 74), not a standalone requirement. It is folded into Phase 74's plan scope at coarse granularity.
- [v2.4 roadmap]: CONTRACT-01 (support-matrix rows for all new surfaces) is the exit criterion for Phase 75 — the last recipe phase, when all new surfaces exist. CONTRACT-02 (HexDocs guides + docs-contract tests) is the exit criterion for Phase 76 — the documentation/adoption closure phase.
- [v2.4 roadmap]: The `example-phoenix` CI job must be isolated (separate from `test`, not a required branch-protection check) before it is upgraded from `mix compile` to `mix test`. This prevents Phoenix flakiness from blocking `signing-live-proof`, `long-lived-live-proof`, `release-proof`, and `test`.
- [v2.4 73-02]: D-04 body_capacity geometric overlap check — in `measure.ex body_capacity/1`, subtract footer height only when `body_y + body_h >= footer_y`; subtract header height only when `body_y < header_y + header_h`. Simple formula `body_h - header_h - footer_h` is correct for `paginate.ex flow_layout/1` (body spans full column) but breaks templates where body is explicitly positioned between header and footer regions.
- [Phase ?]: 73-04: region_suppress_on map in compose.ex layout — threaded to paginate stage for per-region suppression
- [Phase ?]: 73-04: Raising fn in evaluate_fn_blocks/3 re-raised as Rendro.Error for consistent pipeline error propagation

### Roadmap Evolution

- `v2.0` closed 2026-05-07 — unsigned signature authoring, deterministic unsigned widget serialization, artifact-first signing preparation.
- `v2.1` closed 2026-05-07 — cryptographic signing and signed-artifact proof with enforced `signing-live-proof` gate.
- `v2.2` closed 2026-05-08 — long-lived signatures and compliance evidence; phases 64–67; `long-lived-live-proof` required on `main`.
- `v2.3` closed 2026-05-29 at tag `v0.3.1` — viewer proof and interop closure; phases 68–72; all 19 requirements satisfied; all 26 (surface × viewer) cells terminal.
- `v2.4` active — Batteries-Included Workflow & Adoption Closure; phases 73–76; roadmap created 2026-05-29.

### Pending Todos

- Run `/gsd-plan-phase 73` to begin Phase 73: Page-Numbering / Running-Region Primitive.
- Confirm `body_capacity` fix location (paginate vs. compose stage) in Phase 73 planning before implementation starts.
- Resolve page-number authoring API shape (named helper vs. raw function vs. both) before Phase 73 API surface is finalized.
- Carry the viewer-evidence recording discipline forward to all new surfaces — every new `priv/support_matrix.json` row must be `supported` (with evidence) or `explicit_deferral` (with a named reason).

### Assessment (2026-05-29)

Roadmap created with 4 phases covering all 19 v1 requirements. Build order is:

1. Phase 73: Engine primitive (prerequisite for multi-page recipes)
2. Phase 74: Statement recipe (first full exercise of PAGE primitive, includes recipe-base extraction)
3. Phase 75: Receipt/Report + Certificate recipes + support-matrix closure for all new surfaces
4. Phase 76: Reference Phoenix app + isolated CI + HexDocs documentation closure

The `body_capacity` prerequisite bug (footer/header region heights not subtracted from body capacity in `flow_layout/1`) is a hard exit criterion for Phase 73. No multi-page recipe with a real-height running footer can ship until it is fixed.

### Blockers/Concerns

- Phase 73: `body_capacity` fix location must be confirmed (paginate vs. compose stage) before implementation. Running-token substitution test with `maybe_validate_region_fit` and non-zero footer height is a required coverage point.
- Phase 75: Certificate coordinates must be geometry-derived, not hardcoded A4 numerics. Multi-size test (A4 + US Letter) is a non-negotiable exit criterion.
- Phase 76: `example-phoenix` CI isolation must happen before upgrading the step from `mix compile` to `mix test`. Do not add this as a required branch-protection check.
- Keep all new surfaces under the v2.3 viewer-evidence recording discipline — no new surface ships as a silent `unverified`.

## Deferred Items

Items intentionally held outside v2.4 scope (carried from v2.3 + v2.4 planning):

| Category | Item | Status |
|----------|------|--------|
| adoption | Optional first-party `Rendro.Adapters.Pdfium` / `Rendro.Adapters.PdfJs` automatable observer adapters | deferred (v2.3 shipped manual-only recording) |
| automation | Headless-browser PDF.js / PDFium rendering CI lanes | deferred to a dedicated automation milestone if at all |
| viewer_proof | Mobile viewer evidence (iOS Files, Android default viewer) | deferred |
| viewer_proof | Annual/semi-annual re-verification cadence enforcement | advisory; possibly blocking later |
| adoption | Additional signing or long-lived adapters beyond the first proof-backed path | deferred until demand and proof justify them |
| workflows | Multi-signature workflows and signer orchestration | deferred beyond v2.3 |
| globalization | Global text shaping, RTL support, and broader script coverage | conditional v2.5, only if demand justifies the core investment |
| layout | Even/odd header content variants (book-style duplex) | post-v2.4 |
| layout | Section-local page number restart | post-v2.4 |
| recipes | Decorative border frame on Certificate (depends on drawn-path primitive) | post-v2.4 |
| recipes | Chart/graph rendering in Report body (major new rendering surface) | post-v2.4 |
| recipes | Table of contents with page numbers (forward-reference, multi-pass concern) | post-v2.4 |
| release | 1.0 release capstone (SemVer/API-stability commitment) | after v2.4 ships |
| Phase 73-page-numbering-running-region-primitive P01 | 9m | 2 tasks | 5 files |
| Phase 73-page-numbering-running-region-primitive P02 | 12m | 2 tasks | 3 files |
| Phase 73 P03 | 8min | 1 tasks | 2 files |
| Phase 73 P04 | 3min | 2 tasks | 7 files |
| Phase 73 P05 | 4min | 2 tasks | 1 files |

## Operator Next Steps

- Run `/gsd-plan-phase 73` to plan Phase 73: Page-Numbering / Running-Region Primitive.

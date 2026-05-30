---
gsd_state_version: 1.0
milestone: v2.5
milestone_name: 1.0 Release Capstone
status: planning
last_updated: "2026-05-30T12:35:48.911Z"
last_activity: 2026-05-30
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-30 after v2.4 milestone shipped)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** v2.5 1.0 Release Capstone — formal SemVer/API-stability commitment + first 1.x public hex release (`1.0.0`), consolidating unreleased v2.3 + v2.4 work (then conditional v2.6 global text shaping). Defining requirements → roadmap.

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-05-30 — Milestone v2.5 started

## Milestone Snapshot

- Shipped milestone: `v2.4 Batteries-Included Workflow & Adoption Closure` — phases 73-77, 21 plans, 19/19 requirements, milestone audit `passed`. Archived in `milestones/v2.4-ROADMAP.md` / `milestones/v2.4-REQUIREMENTS.md` / `milestones/v2.4-MILESTONE-AUDIT.md`.
- Previous shipped milestone: `v2.3 Viewer Proof & Interop Closure` (shipped 2026-05-29 at tag `v0.3.1`).
- Active milestone: **v2.5 1.0 Release Capstone** (phases 78–82) — formal SemVer/API-stability commitment + first 1.x public hex release (`1.0.0`), single consolidation of unreleased v2.3 + v2.4. Then conditional `v2.6 Global Text Shaping & Script Support` only if adopter demand justifies the core investment.

## Performance Metrics

Per-phase metrics for shipped milestones live in their archives under `.planning/milestones/v[X.Y]-ROADMAP.md` and per-plan SUMMARY frontmatter.

## Accumulated Context

### Decisions

Full per-milestone decision log lives in `.planning/PROJECT.md` (Key Decisions table) and per-milestone archives. v2.4 decisions (page primitive built foundational-first; stateless engine / stateful-data totals; shared `Rendro.Recipes.Pagination`+`PageSize`; pure locale-free `Rendro.Format`; geometry-derived Certificate; advisory-isolated example CI; structured `ArgumentError` recipe validation) are recorded in PROJECT.md.

### Roadmap Evolution

- `v2.3` closed 2026-05-29 at tag `v0.3.1` — viewer proof and interop closure; phases 68–72.
- `v2.4` closed 2026-05-30 — batteries-included workflow and adoption closure; phases 73–77; all 19 requirements satisfied; audit `passed`.

### Resolved Threads

- `v24-adoption-scoping` — **resolved 2026-05-30** at v2.4 close. All findings shipped (page primitive → 73, recipes → 74/75, reference app → 76); open questions answered. See `.planning/threads/v24-adoption-scoping.md`.

### Open Blockers

None.

### Deferred Items

Items intentionally held outside shipped scope, carried forward for future milestones:

| Category | Item | Status |
|----------|------|--------|
| release | 1.0 release capstone (SemVer/API-stability commitment + migration note) | next up — after v2.4 |
| globalization | Global text shaping, RTL support, broader script coverage | conditional v2.5, only if demand justifies the core investment |
| adoption | Optional first-party `Rendro.Adapters.Pdfium` / `Rendro.Adapters.PdfJs` automatable observer adapters | deferred |
| automation | Headless-browser PDF.js / PDFium rendering CI lanes | deferred to a dedicated automation milestone if at all |
| viewer_proof | Mobile viewer evidence (iOS Files, Android default viewer) | deferred |
| viewer_proof | Annual/semi-annual re-verification cadence enforcement | advisory; possibly blocking later |
| workflows | Multi-signature workflows and signer orchestration | deferred |
| layout | Even/odd header content variants (book-style duplex) | post-v2.4 |
| layout | Section-local page number restart | post-v2.4 |
| recipes | Decorative border frame on Certificate (depends on drawn-path primitive) | post-v2.4 |
| recipes | Chart/graph rendering in Report body (major new rendering surface) | post-v2.4 |
| recipes | Table of contents with page numbers (forward-reference, multi-pass concern) | post-v2.4 |

## Operator Next Steps

- `/clear` then `/gsd-new-milestone` to scope the 1.0 release capstone (or the next milestone).

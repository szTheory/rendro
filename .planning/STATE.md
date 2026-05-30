---
gsd_state_version: 1.0
milestone: v2.5
milestone_name: 1.0 Release Capstone
status: executing
last_updated: "2026-05-30T19:17:13.143Z"
last_activity: 2026-05-30
progress:
  total_phases: 5
  completed_phases: 2
  total_plans: 12
  completed_plans: 9
  percent: 40
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-30 after v2.4 milestone shipped)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Phase 80 — stability-contract-migration-docs

## Current Position

Phase: 80 (stability-contract-migration-docs) — EXECUTING
Plan: 2 of 4
Status: Ready to execute
Last activity: 2026-05-30
Resume file: None

## Milestone Snapshot

- Shipped milestone: `v2.4 Batteries-Included Workflow & Adoption Closure` — phases 73-77, 21 plans, 19/19 requirements, milestone audit `passed`. Archived in `milestones/v2.4-ROADMAP.md` / `milestones/v2.4-REQUIREMENTS.md` / `milestones/v2.4-MILESTONE-AUDIT.md`.
- Previous shipped milestone: `v2.3 Viewer Proof & Interop Closure` (shipped 2026-05-29 at tag `v0.3.1`).
- Active milestone: **v2.5 1.0 Release Capstone** (phases 78–82, 16 requirements API-01..05 / STAB-01..05 / REL-01..06) — formal SemVer/API-stability commitment + first 1.x public hex release (`1.0.0`), single consolidation of unreleased v2.3 + v2.4. Phase 82 is the irreversible 1.0.0 publish. Then conditional `v2.6 Global Text Shaping & Script Support` only if adopter demand justifies the core investment.

## v2.5 Phase Map

| Phase | Name | Requirements | Depends on |
|-------|------|--------------|-----------|
| 78 | Public API Surface Definition & Cleanup | API-01, API-02, API-03, API-05 | — |
| 79 | Public API Contract Enforcement Lane | API-04 | 78 |
| 80 | Stability Contract & Migration Docs | STAB-01..05 | 78 |
| 81 | Release Hardening | REL-01, REL-02, REL-03, REL-05 | 78, 79, 80 |
| 82 | 1.0.0 Consolidation & Publish (IRREVERSIBLE) | REL-04, REL-06 | 81 (all required CI lanes green) |

## Performance Metrics

Per-phase metrics for shipped milestones live in their archives under `.planning/milestones/v[X.Y]-ROADMAP.md` and per-plan SUMMARY frontmatter.

## Accumulated Context

### Decisions

Full per-milestone decision log lives in `.planning/PROJECT.md` (Key Decisions table) and per-milestone archives. v2.5 scoping decisions (locked 2026-05-30): single consolidated `1.0.0` publish (last published is `0.3.0`, v2.3+v2.4 unreleased); cleanup-first (no intermediate `0.4.0`, audit found ~zero real breaking changes); "public ≡ what ExDoc renders"; two user-facing tiers (Tier-1 Stable strict SemVer / Tier-2 Evolving adapters + diagnostics, additive-only); soft-deprecation-first (since `mix ci` compiles `--warnings-as-errors`); release-please deferred (AUTO-01); one new dev dep `:mix_audit`, no new runtime deps. Build order: define+clean surface → enforce → stability docs → release hardening → publish.

- [Phase ?]: D-01 executed: two-tier contract leads api_stability.md; per-surface blocks relocated byte-identical (D-02 zero test churn confirmed)
- [Phase ?]: D-09 reconcile: Rendro.Inspector removed from Tier-1; :diagnostics map common keys (:level, :type) are the stable contract
- [Phase ?]: D-05 lockstep applied: guide + protection_claims_test.exs updated atomically; no CI red window

### Roadmap Evolution

- `v2.3` closed 2026-05-29 at tag `v0.3.1` — viewer proof and interop closure; phases 68–72.
- `v2.4` closed 2026-05-30 — batteries-included workflow and adoption closure; phases 73–77; all 19 requirements satisfied; audit `passed`.
- `v2.5` roadmap created 2026-05-30 — 1.0 Release Capstone; phases 78–82; 16 requirements (API/STAB/REL); structure adopted verbatim from the approved deep-research + audit phase decomposition.

### Resolved Threads

- `v24-adoption-scoping` — **resolved 2026-05-30** at v2.4 close. All findings shipped (page primitive → 73, recipes → 74/75, reference app → 76); open questions answered. See `.planning/threads/v24-adoption-scoping.md`.

### Open Blockers

None.

### Deferred Items

Items intentionally held outside shipped scope, carried forward for future milestones:

| Category | Item | Status |
|----------|------|--------|
| globalization | Global text shaping, RTL support, broader script coverage | conditional v2.6, only if demand justifies the core investment |
| automation | release-please (conventional-commit changelog + tag) for the 1.x train | deferred post-1.0 (AUTO-01) — avoids churn on the irreversible cut + legacy-tag collisions |
| packaging | Split into separate `rendro` / `rendro_adapters` hex packages | deferred — tier differentiation via documented tiers, not package surgery |
| stability | Retrofitting `@doc since:` across the 0.x surface | deferred — adopt going-forward only |
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
| Phase 79 P01 | 74 | 1 tasks | 1 files |
| Phase 80 P01 | 8 | 1 tasks | 2 files |

## Operator Next Steps

- `/gsd-plan-phase 78` to decompose the first phase (Public API Surface Definition & Cleanup) into executable plans.

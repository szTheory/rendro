# ROADMAP — Rendro

## Milestones

- ✅ **C1 CI/CD Performance & Reliability** — Phases 108-113 (shipped 2026-07-11; non-version infra milestone, no Hex release)
- ✅ **v2.9 TOC & Document Navigation** — Phases 97-100 (shipped 2026-06-14)
- ✅ **B1 Brand System & Identity Lab** — Phases 101-107 (shipped 2026-06-14)

## Phases

<details>
<summary>✅ C1 CI/CD Performance & Reliability (Phases 108-113) — SHIPPED 2026-07-11</summary>

- [x] **Phase 108: Baseline & Audit Report** — measured current CI topology, critical path, test/check classes, and P0-P3 recommendations. (completed 2026-06-14)
- [x] **Phase 109: Caching & setup-beam Foundation** — added keyed deps, `_build`, and PLT caching with unified SHA-pinned setup-beam. (completed 2026-06-15)
- [x] **Phase 110: Test Concurrency, Determinism & Cleanup** — improved test concurrency, documented non-async reasons, and quarantined/fixed nondeterministic paths. (completed 2026-06-16)
- [x] **Phase 111: Workflow Topology, Triggers & Matrix** — rationalized CI jobs, triggers, matrix policy, PR cancellation, and the stable `ci-success` required gate. (completed 2026-06-16)
- [x] **Phase 112: Security, Supply-chain & Release Hardening** — pinned actions, configured Dependabot, separated advisory audits, and hardened release preflight behavior. (completed 2026-06-16)
- [x] **Phase 113: DX, Local Reproducibility & Validation** — added scoped local CI aliases, contributor docs, README badge, final metrics, and remote validation evidence. (completed 2026-07-10)

**Archive:** `milestones/C1-ROADMAP.md`, `milestones/C1-REQUIREMENTS.md`, `milestones/C1-MILESTONE-AUDIT.md`

**Validation:** passed. 30/30 requirements, 18/18 plans, 6/6 phases, three green remote `ci.yml` runs, `mix ci.fast` green locally with 1219 tests, 12 doctests, 4 properties, 0 failures.

</details>

<details>
<summary>✅ v2.9 TOC & Document Navigation (Phases 97-100) — SHIPPED 2026-06-14</summary>

- [x] **Phase 97: Location Tracking & Primitives** — established exact X/Y physical locations and bounds as a foundational engine primitive. (completed 2026-06-13)
- [x] **Phase 98: Document Outlines (Bookmarks)** — introduced native, declarative doubly-linked PDF outline serialization. (completed 2026-06-14)
- [x] **Phase 99: Cross-References & Validation** — added validated internal document links that point to explicit physical destinations. (completed 2026-06-14)
- [x] **Phase 100: Printable Table of Contents Primitive** — provided safe post-layout substitution tokens for visual Tables of Contents. (completed 2026-06-14)

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 108. Baseline & Audit Report | C1 | 3/3 | Complete | 2026-06-14 |
| 109. Caching & setup-beam Foundation | C1 | 2/2 | Complete | 2026-06-15 |
| 110. Test Concurrency, Determinism & Cleanup | C1 | 3/3 | Complete | 2026-06-16 |
| 111. Workflow Topology, Triggers & Matrix | C1 | 3/3 | Complete | 2026-06-16 |
| 112. Security, Supply-chain & Release Hardening | C1 | 4/4 | Complete | 2026-06-16 |
| 113. DX, Local Reproducibility & Validation | C1 | 3/3 | Complete | 2026-07-10 |

## Current Focus

No active milestone. Start the next milestone with `$gsd-new-milestone` when ready.

## Planned Next — "Happy-Path Home Runs" program (dormant seeds)

A sequenced 4-milestone program to make rendro's business-document happy paths shine: realistic,
award-quality example documents; a full document theming/design-token system; style-genre presets + a
public example catalog; and an optional interactive theme studio. Details live in dormant seeds under
`.planning/seeds/`. See all seeds: `/gsd-capture --list-seeds`. Scope one into a milestone:
`$gsd-new-milestone`. Full program plan: `~/.claude/plans/btw-what-is-rendro-spicy-giraffe.md`.

| # | Milestone | Seed |
|---|-----------|------|
| A | Realistic Business-Document Examples & Anatomy (domain research + rubric, realistic fixtures, Invoice anatomy upgrade, Payslip + Ticket families) | `SEED-002` |
| B | Document Theming & Design-Token System (`Rendro.Theme`, light/dark, unbranded default) | `SEED-003` |
| C | Style-Genre Presets, Public Catalog & Static Configurator | `SEED-004` |
| D | Rendro Studio: optional mountable theme playground (LiveView) | `SEED-005` *(optional)* |

Dependency order: A → B → C → D. Each is a right-sized milestone; D is optional/deferrable.

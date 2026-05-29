# Roadmap: Rendro

**Phase numbering:** sequential and continuous across milestones (never restarts at 01). v2.3 closed at phase 72; the next milestone continues from phase 73.

## Milestones

- ✅ **v1.0 MVP** — deterministic core rendering (shipped)
- ✅ **v1.1 Layout Authoring** — templates/regions, pagination semantics (shipped)
- ✅ **v1.2 Typography & Assets** — deterministic typography, honest Unicode boundaries (shipped)
- ✅ **v1.3 Hex Release Readiness** — first public package boundary (shipped 2026-05-03)
- ✅ **v1.4 Async Delivery & Artifact Ops** — queued lifecycle, artifact metadata, integrations (shipped 2026-05-05)
- ✅ **v1.5 Validation & Trust Surfaces** — Poppler structural validation, support matrix (shipped 2026-05-05)
- ✅ **v1.8 Interactive PDF Forms** — Phases 45-47 (shipped 2026-05-05)
- ✅ **v1.9 Embedded Artifact Surfaces** — Phases 48-50 (shipped 2026-05-06)
- ✅ **v1.10 Protected Delivery Hooks** — Phases 51-54 (shipped 2026-05-06)
- ✅ **v2.0 Signature Fields & Signing Prep** — Phases 55-59 (shipped 2026-05-07)
- ✅ **v2.1 Cryptographic Signing** — Phases 60-63 (shipped 2026-05-07)
- ✅ **v2.2 Long-Lived Signatures** — Phases 64-67 (shipped 2026-05-08)
- ✅ **v2.3 Viewer Proof & Interop Closure** — Phases 68-72 (shipped 2026-05-29)
- 📋 **v2.4 Batteries-Included Workflow & Adoption Closure** — planned (next, from phase 73)

## Phases

<details>
<summary>✅ v2.3 Viewer Proof & Interop Closure (Phases 68-72) — SHIPPED 2026-05-29</summary>

- [x] Phase 68: Viewer Evidence Schema, Mix Task, and Docs-Contract Lane (3/3 plans) — completed 2026-05-28
- [x] Phase 69: Operator Recipe + First Cell End-to-End (3/3 plans) — completed 2026-05-28
- [x] Phase 70: Consolidate Already-Validated Surfaces (3/3 plans) — completed 2026-05-29
- [x] Phase 71: Record New Trust-Sensitive Surfaces and Explicit Deferrals (3/3 plans) — completed 2026-05-29
- [x] Phase 72: Closure — Audit, Polish, and Ship (3/3 plans) — completed 2026-05-29

**Outcome:** All 26 (surface × viewer) cells terminal — 17 supported (each with a resolvable `evidence:` pointer), 9 explicit_deferral (each named), 0 silently unverified. Operator-grade recipe (`guides/viewer_evidence.md`), schema validator, `mix rendro.viewer_evidence` task, and the 8th docs-contract lane shipped and wired into the required `test` job. Engine-level trust spine verified unchanged via live branch-protection audit. Shipped at v0.3.1.

Full detail: `.planning/milestones/v2.3-ROADMAP.md` · Requirements: `.planning/milestones/v2.3-REQUIREMENTS.md` · Audit: `.planning/milestones/v2.3-MILESTONE-AUDIT.md`

</details>

<details>
<summary>✅ v1.0 – v2.2 (Phases 1-67) — SHIPPED</summary>

Earlier milestones are archived individually under `.planning/milestones/v[X.Y]-ROADMAP.md` with matching `-REQUIREMENTS.md` and (where present) `-MILESTONE-AUDIT.md`. See `.planning/MILESTONES.md` for the per-milestone accomplishment ledger.

</details>

### 📋 v2.4 Batteries-Included Workflow & Adoption Closure (Next)

Not yet planned. Run `/gsd-new-milestone` to define requirements and roadmap (phase numbering continues from 73). Per `MILESTONE-ARC.md`, v2.4 follows viewer/interop closure in the active "production-ready trust and adoption" arc; conditional v2.5 (Global Text Shaping & Script Support) follows only if demand justifies the core investment.

## Progress

| Milestone | Phases | Status | Shipped |
|-----------|--------|--------|---------|
| v1.0 – v2.2 | 1-67 | Complete | through 2026-05-08 |
| v2.3 Viewer Proof & Interop Closure | 68-72 | Complete | 2026-05-29 |
| v2.4 Batteries-Included Workflow & Adoption Closure | 73+ | Not started | - |

---
*v2.3 archived 2026-05-29 on milestone completion. Working roadmap collapsed to the milestone index; per-milestone detail lives in `.planning/milestones/`.*

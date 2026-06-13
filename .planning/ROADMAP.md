# Roadmap: Rendro

**Phase numbering:** sequential and continuous across milestones (never restarts at 01). v2.6 closed at phase 88; the next milestone starts at phase 89.

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
- ✅ **v2.3 Viewer Proof & Interop Closure** — Phases 68-72 (shipped 2026-05-29, tag v0.3.1)
- ✅ **v2.4 Batteries-Included Workflow & Adoption Closure** — Phases 73-77 (shipped 2026-05-30)
- ✅ **v2.5 1.0 Release Capstone** — Phases 78-82 (shipped 2026-06-05, hex tag 1.0.0)
- ✅ **v2.6 Public Launch & Adoption Bootstrap** — Phases 83-88 (shipped 2026-06-13)
- 💤 **v2.7 Global Text Shaping & Script Support** — conditional, only if the v2.6 demand gate triggers

## Phases

<details>
<summary>✅ v1.0 – v2.5 (Phases 1-82) — SHIPPED</summary>

Earlier milestones are archived individually under `.planning/milestones/v[X.Y]-ROADMAP.md` with matching `-REQUIREMENTS.md` and, where present, `-MILESTONE-AUDIT.md`. See `.planning/MILESTONES.md` for the per-milestone accomplishment ledger.

</details>

<details>
<summary>✅ v2.6 Public Launch & Adoption Bootstrap (Phases 83-88) — SHIPPED 2026-06-13</summary>

Archived:

- `.planning/milestones/v2.6-ROADMAP.md`
- `.planning/milestones/v2.6-REQUIREMENTS.md`
- `.planning/milestones/v2.6-MILESTONE-AUDIT.md`
- `.planning/milestones/v2.6-phases/`

Completed phases:

- [x] Phase 83: Claim-Accuracy & Shaping Hygiene (5/5 plans) — completed 2026-06-10
- [x] Phase 84: Drawn-Path Primitive & Visible Polish (5/5 plans) — completed 2026-06-10
- [x] Phase 85: Deterministic Raster Lane (6/6 plans) — completed 2026-06-11
- [x] Phase 86: Self-Proving Launch Artifacts (5/5 plans) — completed 2026-06-11
- [x] Phase 87: Comparison Page & Livebook (6/6 plans) — completed 2026-06-11
- [x] Phase 88: Launch Execution & Demand Instrumentation (5/5 plans) — completed 2026-06-12

Summary: v2.6 made Rendro truthfully and quietly discoverable. It restored the pure-Elixir core claim by making HarfBuzz optional, added deterministic path/table/certificate visible polish, shipped the advisory pdfium raster lane, published hash-checked gallery/manual/comparison/Livebook proof artifacts, and recorded low-maintenance adoption instrumentation plus a measurable conditional v2.7 shaping gate.

</details>

### 💤 v2.7 Global Text Shaping & Script Support (Conditional)

No active phase is planned yet. Start the next milestone with `$gsd-new-milestone` when the ADOPTION.md demand gate triggers or when a different next milestone is selected.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 83. Claim-Accuracy & Shaping Hygiene | v2.6 | 5/5 | Complete | 2026-06-10 |
| 84. Drawn-Path Primitive & Visible Polish | v2.6 | 5/5 | Complete | 2026-06-10 |
| 85. Deterministic Raster Lane | v2.6 | 6/6 | Complete | 2026-06-11 |
| 86. Self-Proving Launch Artifacts | v2.6 | 5/5 | Complete | 2026-06-11 |
| 87. Comparison Page & Livebook | v2.6 | 6/6 | Complete | 2026-06-11 |
| 88. Launch Execution & Demand Instrumentation | v2.6 | 5/5 | Complete | 2026-06-12 |

---
*v2.6 archived 2026-06-13 on milestone completion (Phases 83-88, 32 plans, 21/21 requirements, audit `passed`). Fresh requirements for the next milestone should be created with `$gsd-new-milestone`.*

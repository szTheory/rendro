# Roadmap: Rendro

**Phase numbering:** sequential and continuous across milestones (never restarts at 01). v2.4 closed at phase 77.

**Status:** No milestone active — v2.4 shipped 2026-05-30. Next up: **1.0 release capstone** (then conditional v2.5).

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
- 📋 **1.0 Release Capstone** — SemVer/API-stability commitment + migration note (planned, next)
- 💤 **v2.5 Global Text Shaping & Script Support** — conditional, only if adopter demand justifies the core investment

## Phases

<details>
<summary>✅ v2.4 Batteries-Included Workflow & Adoption Closure (Phases 73-77) — SHIPPED 2026-05-30</summary>

- [x] Phase 73: Page-Numbering / Running-Region Primitive (5/5 plans) — completed 2026-05-29
- [x] Phase 74: Statement Recipe (4/4 plans) — completed 2026-05-29
- [x] Phase 75: Receipt/Report and Certificate Recipes + Support Contract (4/4 plans) — completed 2026-05-29
- [x] Phase 76: Reference Phoenix App, CI, and Documentation Closure (4/4 plans) — completed 2026-05-29
- [x] Phase 77: v2.4 Closure — Format Gate, Nyquist Drafts, Recipe Input-Validation Polish (4/4 plans) — completed 2026-05-30

**Outcome:** Closed the adoption gap. Shipped a deterministic page-numbering / running-region primitive (PAGE-01..04), three data-driven recipes on the three-rung escape hatch — Statement (STMT-01..04), Receipt/Report (RCPT-01..03), Certificate (CERT-01..03) — terminal support-matrix rows for every new surface (CONTRACT-01), an executable reference Phoenix app in an isolated non-required CI lane (REF-01..03), and HexDocs guides bounded by docs-contract tests (CONTRACT-02). All 19 requirements satisfied; milestone audit `passed` (5/5 phases, 6/6 E2E flows, integration PASS); 925-test suite green.

Full detail: `milestones/v2.4-ROADMAP.md` · Requirements: `milestones/v2.4-REQUIREMENTS.md` · Audit: `milestones/v2.4-MILESTONE-AUDIT.md`

</details>

<details>
<summary>✅ v2.3 Viewer Proof & Interop Closure (Phases 68-72) — SHIPPED 2026-05-29</summary>

All 26 (surface × viewer) cells terminal — 17 supported (each with a resolvable `evidence:` pointer), 9 explicit_deferral (each named), 0 silently unverified. Shipped at tag v0.3.1.

Full detail: `milestones/v2.3-ROADMAP.md` · Requirements: `milestones/v2.3-REQUIREMENTS.md` · Audit: `milestones/v2.3-MILESTONE-AUDIT.md`

</details>

<details>
<summary>✅ v1.0 – v2.2 (Phases 1-67) — SHIPPED</summary>

Earlier milestones are archived individually under `.planning/milestones/v[X.Y]-ROADMAP.md` with matching `-REQUIREMENTS.md` and (where present) `-MILESTONE-AUDIT.md`. See `.planning/MILESTONES.md` for the per-milestone accomplishment ledger.

</details>

### 📋 Next: 1.0 Release Capstone (planned)

- [ ] Cut the 1.0 release — SemVer/API-stability commitment, migration note, capstone after v2.4 adoption closure. Engine is 1.0-grade; `guides/api_stability.md` already exists.

### 💤 Conditional: v2.5 Global Text Shaping & Script Support

- [ ] Global text shaping, RTL support, broader complex-script coverage — only if adopter demand justifies the core investment.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 73. Page-Numbering / Running-Region Primitive | v2.4 | 5/5 | Complete | 2026-05-29 |
| 74. Statement Recipe | v2.4 | 4/4 | Complete | 2026-05-29 |
| 75. Receipt/Report and Certificate Recipes + Support Contract | v2.4 | 4/4 | Complete | 2026-05-29 |
| 76. Reference Phoenix App, CI, and Documentation Closure | v2.4 | 4/4 | Complete | 2026-05-29 |
| 77. v2.4 Closure — Format Gate, Nyquist Drafts, Input-Validation Polish | v2.4 | 4/4 | Complete | 2026-05-30 |

---
*v2.4 archived 2026-05-30 on milestone completion (Phases 73-77, 21 plans, 19/19 requirements, audit `passed`). Next: 1.0 release capstone — run `/gsd-new-milestone`.*

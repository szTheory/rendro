# Roadmap: Rendro

**Phase numbering:** sequential and continuous across milestones (never restarts at 01). v2.6 closed at phase 88; v2.7 starts at phase 89.

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
- 🔄 **v2.7 Page Context & Browser Proof Hardening** — Phases 89-92 (active)
- 💤 **Global Text Shaping & Script Support** — conditional; only if the v2.6 `ADOPTION.md` demand gate triggers

## Phases

<details>
<summary>✅ v1.0 - v2.6 (Phases 1-88) — SHIPPED</summary>

Earlier milestones are archived individually under `.planning/milestones/v[X.Y]-ROADMAP.md` with matching `-REQUIREMENTS.md` and, where present, `-MILESTONE-AUDIT.md`. See `.planning/MILESTONES.md` for the per-milestone accomplishment ledger.

v2.6 archives:

- `.planning/milestones/v2.6-ROADMAP.md`
- `.planning/milestones/v2.6-REQUIREMENTS.md`
- `.planning/milestones/v2.6-MILESTONE-AUDIT.md`
- `.planning/milestones/v2.6-phases/`

</details>

### 🔄 v2.7 Page Context & Browser Proof Hardening

Milestone intent: make the existing PAGE/running-region primitive substantially better for long reports and duplex output while preserving deterministic rendering, then add a narrow browser-family advisory proof lane without upgrading public viewer claims.

#### Phase 89: Page Context Primitive

**Requirements:** CTX-01, CTX-02, CTX-03
**Depends on:** v2.4 PAGE primitive, v2.6 claim discipline

Deliverables:
- Extend `Rendro.section/1` with `page_numbering: [restart: true]` for body sections.
- Force a restarting section to begin on a new physical page.
- Compute internal page context after pagination: physical page number, total pages, section-local page number, and section total pages.
- Extend page-number token substitution with `{{section_page_number}}` and `{{section_total_pages}}`.
- Preserve existing `{{page_number}}`, `{{total_pages}}`, `suppress_on`, and `RunningContent` callback behavior.

Exit criteria:
- Section-local numbering is decimal-only and deterministic.
- Existing PAGE tests still pass unchanged.
- Backward compatibility is covered by focused regression tests.

#### Phase 90: Duplex Running Content

**Requirements:** DUP-01, DUP-02, DUP-03
**Depends on:** Phase 89

Deliverables:
- Extend `Rendro.section/1` with `only_on: :odd | :even` for header/footer/running-region sections.
- Evaluate `only_on` against physical page parity.
- Compose odd/even filtering with `suppress_on` and section-local page-number tokens.
- Add instructive validation failures for malformed `only_on` and `page_numbering` options.

Exit criteria:
- Odd/even content works for headers and footers without changing fixed-position body rendering.
- Duplex content uses physical parity even after section restarts.
- Invalid options fail before rendering misleading output.

#### Phase 91: PDF.js Advisory Proof Lane

**Requirements:** PDFJS-01, PDFJS-02, PDFJS-03
**Depends on:** v2.6 raster/evidence vocabulary

Deliverables:
- Add a pinned Node/pdfjs-dist advisory observer script or mix task that records PDF.js version, Node version, page count, page dimensions, warnings, and optional first-page PNG hash.
- Add committed observation fixtures for a small, representative PDF set.
- Wire CI as advisory and graph-disconnected from required engine lanes.
- Add guardrails/docs-contract checks so wording remains "pinned PDF.js advisory observations" and cannot imply GUI-viewer support.

Exit criteria:
- No Node/npm package is a core runtime dependency, required CI dependency, or Hex dependency.
- PDF.js observations are useful to maintainers and impossible to confuse with support-matrix promotion.

#### Phase 92: Docs, Claims, Release Hygiene

**Requirements:** DOC-01, DOC-02, DOC-03
**Depends on:** Phases 89-91

Deliverables:
- Add/update guides for page context, section-local numbering, and duplex running content.
- Update public support matrix and docs-contract tests for page context, duplex content, and PDF.js advisory wording.
- Harden release/HexDocs workflow wording and CI permissions where practical.
- Keep global text shaping explicitly demand-gated in `ADOPTION.md` and public roadmap language.

Exit criteria:
- Every v2.7 public claim is backed by tests, support rows, evidence fixtures, or explicit deferrals.
- TOC/outlines/anchors/cross-references, charts, global text shaping, and full release automation are named deferrals, not implied near-term promises.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 83. Claim-Accuracy & Shaping Hygiene | v2.6 | 5/5 | Complete | 2026-06-10 |
| 84. Drawn-Path Primitive & Visible Polish | v2.6 | 5/5 | Complete | 2026-06-10 |
| 85. Deterministic Raster Lane | v2.6 | 6/6 | Complete | 2026-06-11 |
| 86. Self-Proving Launch Artifacts | v2.6 | 5/5 | Complete | 2026-06-11 |
| 87. Comparison Page & Livebook | v2.6 | 6/6 | Complete | 2026-06-11 |
| 88. Launch Execution & Demand Instrumentation | v2.6 | 5/5 | Complete | 2026-06-12 |
| 89. Page Context Primitive | v2.7 | 1/1 | Complete   | 2026-06-13 |
| 90. Duplex Running Content | v2.7 | 0/? | Not started | — |
| 91. PDF.js Advisory Proof Lane | v2.7 | 0/? | Not started | — |
| 92. Docs, Claims, Release Hygiene | v2.7 | 0/? | Not started | — |

---
*v2.7 started 2026-06-13 as Page Context & Browser Proof Hardening. Global text shaping remains demand-gated by ADOPTION.md.*

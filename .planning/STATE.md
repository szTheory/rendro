---
gsd_state_version: 1.0
milestone: v2.3
milestone_name: Viewer Proof & Interop Closure
status: Awaiting next milestone
last_updated: "2026-05-29T13:57:59.501Z"
last_activity: 2026-05-29 — Milestone v2.3 completed and archived
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 15
  completed_plans: 15
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-29 after v2.3 milestone shipped)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Between milestones — plan v2.4 Batteries-Included Workflow & Adoption Closure with `/gsd-new-milestone` (phase numbering continues from 73).

## Current Position

Phase: Milestone v2.3 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-05-29 — Milestone v2.3 completed and archived

## Milestone Snapshot

- Milestone: `v2.3 Viewer Proof & Interop Closure` (shipped and archived on 2026-05-29 at tag `v0.3.1`; see `milestones/v2.3-MILESTONE-AUDIT.md`). All 26 (surface × viewer) cells terminal — 17 supported, 9 explicit_deferral, 0 silently unverified.
- Previous shipped milestone: `v2.2 Long-Lived Signatures & Compliance Evidence` (shipped and archived on 2026-05-08; see `milestones/v2.2-MILESTONE-AUDIT.md`).
- Strategic next-up: `v2.4 Batteries-Included Workflow & Adoption Closure`, then conditional `v2.5 Global Text Shaping & Script Support`.

## Performance Metrics

Per-phase metrics for shipped milestones live in their archives under `.planning/milestones/v[X.Y]-ROADMAP.md` and per-plan SUMMARY frontmatter.

## Accumulated Context

### Decisions

Full per-milestone decision log lives in `.planning/PROJECT.md` (Key Decisions table) and per-milestone archives. Carried forward into v2.4 planning:

- [v2.3]: Support rows use a three-state vocabulary — `supported` (with evidence) / `explicit_deferral` (with a named reason) / `unverified` (un-attempted); silent `unverified` for a known-unsupportable cell is a recording-discipline failure.
- [v2.3]: Public-contract data files (`priv/support_matrix.json`) evolve strictly additively under a wired-in JSON-Schema validator in the required `test` job; viewer gaps are recorded as `explicit_deferral`, never patched into the writer.
- [v2.3]: Viewer evidence is text-only Markdown under `priv/viewer_evidence/`, fixtures by repo-path or content hash, with a durable operator recipe (`guides/viewer_evidence.md`) future surfaces inherit.
- [carried]: Lock the public contract before any first-party adapter ships; operationally enforce live proof as a required `main` status check; publish trust-sensitive support as distinct posture signals, not one binary "supported" row.

### Roadmap Evolution

- `v2.0` closed 2026-05-07 — unsigned signature authoring, deterministic unsigned widget serialization, artifact-first signing preparation.
- `v2.1` closed 2026-05-07 — cryptographic signing and signed-artifact proof with enforced `signing-live-proof` gate.
- `v2.2` closed 2026-05-08 — long-lived signatures and compliance evidence; phases 64–67; `long-lived-live-proof` required on `main`.
- `v2.3` closed 2026-05-29 at tag `v0.3.1` — viewer proof and interop closure; phases 68–72; all 19 requirements satisfied; all 26 (surface × viewer) cells terminal.
- `v2.4` next — Batteries-Included Workflow & Adoption Closure (not yet planned; continues from phase 73).

### Pending Todos

- Plan v2.4 with `/gsd-new-milestone`: define batteries-included adoption-closure requirements; carry the viewer-evidence recording discipline forward to any new surfaces.
- Preserve the strategic arc (v2.4 adoption closure → conditional v2.5 global text shaping) so planning continues from an explicit game plan.

### Blockers/Concerns

- Keep viewer claims narrower than blanket "works in every viewer" marketing, blanket compliance narratives, and signer identity trust unless a separate milestone proves them.
- New surfaces must inherit the v2.3 viewer-evidence discipline (recorded proof or named `explicit_deferral`); do not regress to silent `unverified`.
- Multi-signature workflows, HSM orchestration, and global text-shaping remain tempting adjacent problems; they should not leak into v2.4 without a deliberate re-scope.

## Deferred Items

Items intentionally held outside scope as of 2026-05-29 (v2.3 close):

| Category | Item | Status |
|----------|------|--------|
| adoption | Optional first-party `Rendro.Adapters.Pdfium` / `Rendro.Adapters.PdfJs` automatable observer adapters | deferred (v2.3 shipped manual-only recording) |
| automation | Headless-browser PDF.js / PDFium rendering CI lanes | deferred to a dedicated automation milestone if at all |
| viewer_proof | Mobile viewer evidence (iOS Files, Android default viewer) | deferred — likely v2.4 adoption work |
| viewer_proof | Annual/semi-annual re-verification cadence enforcement | advisory in v2.3 (`validate --strict`); possibly blocking later |
| adoption | Additional signing or long-lived adapters beyond the first proof-backed path | deferred until demand and proof justify them |
| workflows | Multi-signature workflows and signer orchestration | deferred beyond v2.3 |
| globalization | Global text shaping, RTL support, and broader script coverage | conditional v2.5, only if demand justifies the core investment |

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone

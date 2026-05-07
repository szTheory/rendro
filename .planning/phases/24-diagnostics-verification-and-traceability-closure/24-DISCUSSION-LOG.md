# Phase 24: Diagnostics Verification and Traceability Closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `24-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-30
**Phase:** 24-diagnostics-verification-and-traceability-closure
**Areas discussed:** verification framing, diagnostics contract, proof depth, validation strictness, workflow posture

---

## Verification framing

| Option | Description | Selected |
|--------|-------------|----------|
| Authoritative closure phase only | Treat Phase 24 as the sole closure point and keep history lightweight | |
| Pure Phase 21 backfill | Attach full closure directly to the historical implementation phase | |
| Hybrid historical + authoritative model | Backfill Phase 21 truthfully, but keep authoritative requirement closure in Phase 24 | ✓ |

**Notes:** This matches the successful `20`/`23` closure pattern. It preserves history, avoids rewriting what Phase 21 did or did not close at the time, and keeps final roadmap/requirements state tied to authoritative proof rather than intent.

## Diagnostics contract

| Option | Description | Selected |
|--------|-------------|----------|
| Raw maps only | Keep diagnostics as informal maps with minimal contract language | |
| Typed struct | Introduce `%Rendro.Document.Diagnostic{}` as the public diagnostics surface | |
| Hybrid documented common-fields map contract | Keep maps, but document stable common keys plus optional event-specific fields | ✓ |

**Notes:** This is the least-surprise fit for shipped code and idiomatic Elixir library ergonomics. The real bug is README drift, not the absence of a struct.

## Proof depth

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow unit-test closure | Close the phase with existing focused test slices only | |
| Milestone-level integration/traceability closure | Prove the public diagnostics surfaces, docs-contract lane, and traceability artifacts together | ✓ |
| Exhaustive broad-suite closure | Expand into a larger snapshot/property/approval style proof wall | |

**Notes:** The goal is decisive milestone proof with good reviewability, not ceremony. Rendro already has the right proof seams; Phase 24 should connect them into one authoritative closure artifact.

## Validation strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal backfill | Add only the minimum missing artifacts for Phase 21 | |
| Full structured validation/verification metadata backfill | Normalize Phase 21 and adjacent partial artifacts to the repo’s existing structured convention | ✓ |
| New lighter convention | Invent a slimmer validation metadata standard for this repair | |

**Notes:** A second convention would create more ambiguity, not less. The stronger move is to use the existing structured pattern consistently so GSD and audits stop treating these phases as special cases.

## Workflow posture

| Option | Description | Selected |
|--------|-------------|----------|
| Broad option menus by default | User chooses from many equivalent paths interactively | |
| Recommendation-first by default | Research-backed cohesive recommendation unless a decision is truly high-impact | ✓ |

**Notes:** This preference is already partly aligned with `.planning/config.json` via `research_before_questions: true` and `vendor_philosophy: opinionated`. No dedicated config flag exists today for “recommendation-first unless high-impact,” so the preference should be carried in context/planning artifacts and followed operationally.

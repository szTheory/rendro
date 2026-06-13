# Phase 94: Docs & Warning Hygiene - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 94-Docs & Warning Hygiene
**Areas discussed:** None (discussion skipped — fully spec-locked phase)

---

## Discuss vs skip

| Option | Description | Selected |
|--------|-------------|----------|
| Skip → write CONTEXT.md | Capture locked decisions, canonical refs, and code context straight from the ROADMAP success criteria; no questions. | ✓ |
| Discuss micro-choices | Walk the discretionary points (real-@moduledoc-vs-keep-Font-hidden, exact `skip_code_autolink_to` entries, lifecycle section placement). | |

**User's choice:** Skip → write CONTEXT.md
**Notes:** Phase 94's four ROADMAP success criteria are prescriptive — they fix the implementation mechanisms (`skip_code_autolink_to:`, real `@moduledoc` on `Rendro.PDF.Font`, `docs --warnings-as-errors` in `ci`, self-explaining staleness line + lifecycle guide), not just outcomes. Codebase scout confirmed the touchpoints and that no gray area rose to "VERY impactful." Calibration tier `minimal_decisive` (vendor_philosophy: opinionated) plus the user's standing research-first / ask-only-on-high-impact preference → no manufactured questions.

---

## Claude's Discretion
- Exact `skip_code_autolink_to:` entries (enumerate empirically via `mix docs`).
- Exact `@moduledoc` text on `Rendro.PDF.Font`, augmented staleness message string, and lifecycle section heading/placement in `guides/viewer_evidence.md`.

## Deferred Ideas
None — discussion stayed within phase scope.

# Phase 23: Table Split Policy Runtime Wiring - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `23-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-30
**Phase:** 23-table-split-policy-runtime-wiring
**Areas discussed:** split policy semantics, whole-table cohesion, verification/traceability closure, workflow posture

---

## Split policy semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Keep `:atomic` as the permanent public name | Reuse existing atom for row-atomic continuation | |
| Rename to explicit `:row_atomic` with temporary `:atomic` alias | Truthful public name for split-between-rows semantics | ✓ |
| Add multiple new split modes now | `:row_atomic`, `:whole_table`, `:avoid_split_if_possible`, etc. | |

**Notes:** Research across ReportLab, iText, QuestPDF, MigraDoc, and pdfmake converged on a clean separation between row continuation and whole-element keep semantics. The main footgun is overloading one vague table knob to mean both.

## Whole-table cohesion

| Option | Description | Selected |
|--------|-------------|----------|
| Table-local whole-table mode | `split_policy` controls “move entire table to next page if possible” | |
| Advisory anti-split mode | Whole table moves when convenient but may still split | |
| Block-level keep semantics | Whole-table cohesion stays on the containing block via `keep_together` | ✓ |

**Notes:** Whole-table keep is useful for short summary tables, but duplicating it inside `split_policy` would overlap with existing block-level keep behavior and weaken the principle of least surprise.

## Verification and traceability closure

| Option | Description | Selected |
|--------|-------------|----------|
| Backfill Phase 20 as the primary closure point | Treat missing artifact as the main problem | |
| Re-home closure entirely to Phase 23 | Leave Phase 20 incomplete history behind | |
| Hybrid closure | Backfill Phase 20 history, but keep authoritative completion in Phase 23 | ✓ |

**Notes:** Phase 23 closes a real runtime gap, not just paperwork debt. Historical auditability improves if Phase 20 gets a truthful backfill artifact, but requirement completion should not flip until Phase 23 verification exists.

## Workflow posture

| Option | Description | Selected |
|--------|-------------|----------|
| Broad option menus by default | User chooses from many equivalent paths | |
| Recommendation-first by default | Research-backed cohesive recommendation unless a truly high-impact semantic choice exists | ✓ |

**Notes:** User preference is to shift recommendation-first synthesis left within GSD. Research-before-questions is preferred where supported, with escalation reserved for genuinely high-impact semantic decisions.

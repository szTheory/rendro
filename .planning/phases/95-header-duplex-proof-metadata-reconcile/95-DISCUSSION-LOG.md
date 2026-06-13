# Phase 95: Header Duplex Proof & Metadata Reconcile - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 95-Header Duplex Proof & Metadata Reconcile
**Areas discussed:** META-01 reconcile method (the single genuine fork)

---

## Assessment

Advisor mode (`minimal_decisive`, `vendor_philosophy: opinionated`). Like Phases 93 and 94, the ROADMAP success criteria for Phase 95 are fully prescriptive (exact test files, exact content-stream assertions, exact edge cases), and STATE.md already locks the PROOF-01 proof architecture ("mirror footer proofs at render + paginate layers; reject Poppler-per-page and golden-bytes"). A codebase scout grounded every PROOF-01 decision against the shipped footer test (`flow_test.exs:268`), the `apply_only_on/3` engine (`paginate.ex:729`), and the `region_entries` map (`compose.ex:117`). No Q&A round was needed for PROOF-01 — decisions were locked from criteria + prior research + scout.

The only genuine judgment call was META-01's edit method, because it touches *archived historical* milestone records.

---

## META-01 reconcile method

| Option | Description | Selected |
|--------|-------------|----------|
| Edit cells in place | Flip the stale `pending`/`Planned` status markers directly in the archived v2.6/v2.7 VALIDATION.md files so recorded status is self-consistent with frontmatter + passed audits. Git-reversible. | ✓ |
| Append dated erratum note | Leave the original `pending` rows verbatim and add a dated reconciliation note per file. Preserves literal text but leaves the false markers visibly present. | |

**User's choice:** Edit cells in place.
**Notes:** Reconcile target is bounded to v2.6/v2.7 archives. Scout found the defect is an intra-file contradiction (e.g. `90-VALIDATION.md` declares `status: approved` / `nyquist_compliant: true` while its own Per-Task table reads `pending` on all rows). Terminal token to reconcile to is `passed` (existing convention in `87-VALIDATION.md`). Frontmatter `status: draft` is research-gated, not a blind flip — it is the un-advanced GSD default and also appears on the current done Phases 93/94, so flipping only v2.6/v2.7 risks creating new cross-archive inconsistency.

---

## Claude's Discretion

- PROOF-01: exact page geometry to force a ≥4-physical-page document; shared-helper-vs-inline for the header test; exact test names.
- META-01: precise frontmatter `status` resolution after the milestone-wide-convention check (D-07); terminal token if scout's `passed` is not dominant.

## Deferred Ideas

- None in scope. Out-of-scope observation recorded in CONTEXT.md: current-milestone Phases 93/94 also carry `status: draft` (systemic default) — explicitly not META-01's concern (bounded to v2.6/v2.7 archives).

# Phase 134: Core Architecture & Readability - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-26
**Phase:** 134-core-architecture-readability
**Mode:** `--auto`
**Areas discussed:** Finding intake authority, candidate prioritization, extraction discipline, specs/docs/comments

---

## Finding Intake Authority

| Question | Option | Selected |
|---|---|---|
| How should Phase 134 proceed when the canonical ledger contains no accepted Phase 134 finding? | Validate explicit evidence and record a ledger disposition before repair | ✓ |
| | Treat roadmap categories as blanket repair authority | |
| | Skip the phase without reconciling its requirements | |
| What happens when a candidate shows no concrete maintenance or contract harm? | Reject it as a signal or defer it with a concrete trigger | ✓ |
| | Repair it opportunistically | |
| | Use size/count improvement as closure | |

**Auto-selected choice:** Ledger before repair; unsupported candidates become rejected signals or trigger-backed deferrals.
**Notes:** `.planning/QUALITY.md` has no accepted Phase 134 finding, and `QL-001` explicitly rejects xref topology as repair authority. The workflow therefore selected the only option consistent with the locked Phase 132 governance.

---

## Candidate Prioritization

| Question | Option | Selected |
|---|---|---|
| Which existing evidence should Phase 134 validate first? | Proven dead code, then still-current evidenced drift surfaces | ✓ |
| | Largest files first | |
| | Broad repository cleanup | |
| Should `Rendro.PDF.Writer` or `Rendro.Pipeline.Paginate` be split because they are large? | Require concrete responsibility or maintenance harm | ✓ |
| | Split by line count | |
| | Split by function count | |

**Auto-selected choice:** Validate `Rendro.I18n.Analyzer` first, then the historical palette/shaping-hint duplication candidates only if current evidence supports them.
**Notes:** Current source search finds the analyzer referenced only by its isolated tests. Historical Phase 83 evidence names it as dead. Large core modules remain diagnostic signals, not automatic targets.

---

## Extraction Discipline

| Question | Option | Selected |
|---|---|---|
| What proof is required before an internal extraction or deduplication lands? | Characterize, make one cohesive change, then prove API and byte identity | ✓ |
| | Refactor first and add tests afterward | |
| | Rely on the full suite only | |
| How broad may cleanup diffs become? | Surgical, concern-scoped diffs | ✓ |
| | Repository-wide cleanup | |
| | Bundle Phase 135 test/CI work | |

**Auto-selected choice:** Characterization-first, one responsibility per change, with exact public-manifest and unaffected-render byte proof.
**Notes:** No alternate render path, broad rename/format sweep, dependency change, test consolidation, CI topology work, or visual catalog change is permitted in this phase.

---

## Specs, Docs, and Comments

| Question | Option | Selected |
|---|---|---|
| What should remain documented or specified after cleanup? | Accurate boundary-value documentation and specs | ✓ |
| | Specify every private function | |
| | Remove all private specs | |
| How should historical phase-number narration in runtime source be handled? | Rewrite stale mechanics into current intent; preserve meaningful provenance | ✓ |
| | Delete every historical reference | |
| | Leave all historical narration | |

**Auto-selected choice:** Preserve truthful boundary contracts and non-obvious intent; remove or rewrite stale mechanics and misleading private specifications with docs/Dialyzer proof.
**Notes:** Provenance-bearing references in viewer evidence and immutable-history seams remain when provenance itself is operationally meaningful.

---

## the agent's Discretion

- Choose exact internal helper names and plan slicing after research.
- Decide whether a validated duplication candidate merits extraction or documented rejection; prefer no change when benefit is not demonstrable.

## Deferred Ideas

- Behavior-changing custom-typography geometry work requires a new ledger finding and separately authorized rendered-byte scope.
- Test fixture and suite consolidation belongs to Phase 135.
- Catalog visual work and renderer-backed human review belong to Phase 136.

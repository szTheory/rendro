---
phase: 126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol
plan: 05
subsystem: phase-closure
tags: [quality, validation, ci-provenance, ref-cleanup]
requires:
  - phase: 126-03
    provides: exact-SHA pinned-PDFium evidence and retained-ref provenance
  - phase: 126-04
    provides: approved full-size review and cleanup authorization
provides:
  - evidence-backed closure of WINDOWS ids 1-3
  - complete Nyquist validation and exact remote-ref cleanup provenance
affects: [phase-127-quality-baseline]
tech-stack:
  added: []
  patterns: [deterministic-advisory separation, per-ref fail-closed cleanup]
key-files:
  modified:
    - .planning/WINDOWS.md
    - priv/quality/SIGN-OFF.md
    - priv/quality/rubric_scores.json
    - .planning/phases/126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol/126-VALIDATION.md
  created:
    - .planning/phases/126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol/126-05-SUMMARY.md
decisions:
  - Close only the three named WINDOWS rows from deterministic, pinned, and approved human evidence.
  - Delete each recorded isolated CI evidence ref only after its exact SHA, committed approval, and scoped artifact gates pass.
metrics:
  completed: 2026-08-17
  tasks_completed: 2
  focused_tests: 183
  full_tests: 1761
status: complete
---

# Phase 126 Plan 05: Evidence Closure and Final Gate Summary

**Phase 126 closes its three deferred polish findings with bounded evidence, green deterministic gates, and auditable removal of both temporary CI evidence refs.**

## Accomplishments

- Marked WINDOWS ids 1–3 fixed only after focused recipe tests, deterministic matrix/accent evidence, accepted pinned-PDFium rows, and the approved full-size review.
- Updated only the Invoice, Ticket, and Payslip sign-off/rubric records. The findings remain fixture-bounded and explicitly make no WCAG, PDF/UA, print-safety, or universal-preset claim.
- Completed all eleven Validation rows and set `nyquist_compliant: true` after the final deterministic evidence passed.

## Deterministic Verification

- Focused Invoice, Ticket, Payslip, seven typography, accent-golden, and preset-matrix suite: **183 tests, 0 failures**.
- `mix test`: **12 doctests, 8 properties, 1761 tests, 0 failures (27 excluded)**.
- `mix ci.fast`: **passed**.
- The previously observed `PresetFontsPackageContractTest` Hex archive race did not recur in this full run.
- Advisory raster evidence was cited as a separate pinned-PDFium lane and was not run inside the deterministic commands.

## CI Evidence and Multi-Ref Cleanup

Plan 04's committed `visual_review: approved` and `cleanup_authorized: true` fields were verified at HEAD before cleanup. The Plan 03 summary was read from HEAD, yielded exactly two distinct well-formed retained refs, and each remote SHA matched its recorded identity before deletion.

### Failed provenance retained in record

- Failed run: [31996940001](https://github.com/szTheory/rendro/actions/runs/31996940001), ref `gsd/phase-126-raster-bless-242f2c304b1f`, SHA `242f2c304b1fd714ed6ca09c6879170856ac8132`.
- Its whole run failed because the compare-only legacy adapter lookup found absent out-of-scope references; no preset artifacts were imported.

### Accepted provenance retained in record

- Accepted artifact run: [31997957937](https://github.com/szTheory/rendro/actions/runs/31997957937), ref `gsd/phase-126-raster-bless-a00f1b054060`, SHA `a00f1b0540602b8ba8937ce1b7e55ba0cba48b13`.
- The exact `advisory-checks` job succeeded with pinned PDFium `v0.11.0`, imported exactly six preset hashes and six review PNGs. Its whole-run failure remains disclosed as unrelated to the accepted artifact predicate.

### Per-ref deletion and absence evidence

| Ref | Recorded SHA matched before delete | `git push origin --delete` | `git ls-remote --exit-code --heads` after delete |
|---|---|---|---|
| `gsd/phase-126-raster-bless-242f2c304b1f` | `242f2c304b1fd714ed6ca09c6879170856ac8132` | success | non-zero / absent |
| `gsd/phase-126-raster-bless-a00f1b054060` | `a00f1b0540602b8ba8937ce1b7e55ba0cba48b13` | success | non-zero / absent |

## Scope Audit

- POLISH-01–05, D-01–D-16, every Source Coverage Audit row, and all ten specless probe rows are covered by Plans 01–05 or an explicit flagged assumption in `126-05-PLAN.md`.
- Kept prohibitions remain flagged: no new public API, dependency, Phase 127 catalog, Phase 128 configurator/codegen, Phase 129 public-claims artifact, or compliance claim was introduced.
- The preset-reference change remains exactly the six accepted CI hash paths; unrelated quality and ledger records remain unchanged.

## Deviations from Plan

None - the planned closure, verification, and fail-closed multi-ref cleanup executed as written.

## Known Stubs

None.

## Self-Check: PASSED

- `126-03-SUMMARY.md` and `126-04-SUMMARY.md` are committed and contain the required provenance/approval fields.
- Both recorded refs were verified absent from `origin` after exact-SHA deletion.
- All 11 Validation rows are green and `nyquist_compliant: true` is present.

# Phase 108: Baseline & Audit Report - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 108-baseline-audit-report
**Areas discussed:** Metric sourcing & rigor, Job-summary instrumentation pattern, Audit report location & shape, A–E classification evidence depth
**Mode:** Advisor (calibration `minimal_decisive`); user requested a second DEEP research pass (ecosystem idioms, lessons/footguns from comparable libs, DX, `prompts/` DNA, coherence) → one-shot locked recommendations.

---

## Metric sourcing & rigor (BASE-01, BASE-02)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Hybrid: gh-API real-runner timings + local `mix` profiling for the inner split + honest "n=3" p95 label | Trustworthy per source; zero paid runs; n=3 gap is the headline finding | ✓ |
| B — gh-API only | Cannot reveal the opaque inner `mix ci` split BASE-01 needs | |
| C — Trigger N fresh green runs to manufacture a p95 | Burns discouraged minutes to baseline the pipeline 109–112 will invalidate | |

**User's choice:** Locked A.
**Notes:** Deep pass found local box = 18 schedulers vs `ubuntu-latest` = 4 → inner split is an ordinal LOCAL PROXY, not absolute seconds. Of 37 ci.yml runs: 19 failure / 15 cancelled / 3 success; the 3 green runs collapse `mix ci` into one 372s/386s/222s "Run CI" step. Siblings get per-stage timing by decomposing the monolith (not via paid runs).

---

## Job-summary instrumentation pattern & scope (BASE-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Inline `$GITHUB_STEP_SUMMARY` brace-group, `test` job only | szTheory house style (mailglass/scrypath); no new convention; dodges composite bug | ✓ |
| Shared composite action `.github/actions/ci-summary` | Multi-write collapse bug (runner#2020 / #32566); 0/9 siblings use one; new surprising convention | |
| `mix` task emitting the summary | Couples CI presentation into lib Mix namespace; no precedent | |
| Scope: all 10 jobs / `test`+advisory | Advisory & proof jobs hold no baseline signal; pure noise | |

**User's choice:** Locked inline, `test` only.
**Notes:** `if: always()` + `continue-on-error: true` enforces observability-only. Cache row ships as `cold / none` placeholder → one-line edit to go live in Phase 109. Slowest-tests via `tee` + grep, no re-run.

---

## Audit report location & shape (BASE-01..04 deliverable)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Single `.planning/milestones/C1-AUDIT.md`, anchored sections | Matches universal sibling convention; cross-references resolve locally; one citable path | ✓ |
| B — Split into 4 files per BASE-0N | No sibling precedent; fragments the most-cited chain; invents a sub-convention | |
| C — Repo-visible `docs/ci-audit.md` | Pre-empts Phase 113 VAL-02/DX-02 ownership; wrong audience/lifecycle | |

**User's choice:** Locked A.
**Notes:** Named `C1-AUDIT.md` (not `-MILESTONE-AUDIT.md` — that slot is the milestone-CLOSE verdict; this is the milestone-START forward audit). ExDoc extras = `guides/` only, so `.planning/` is correctly internal/unpublished.

---

## A–E classification evidence depth (BASE-03)

| Option | Description | Selected |
|--------|-------------|----------|
| 1 — Light static reasoning only | Violates brief's "value not vibes"; starves Phase 110 | |
| 2 — Measured-but-bounded (`--slowest 20` + read 34 async:false + bounded flake sweep + per-category citations) | Defensible + produces exactly what 110 consumes; bounded so it can't do 110's job | ✓ |
| 3 — Exhaustive proof pass | Does Phase 110's job inside 108; breaks measure-only boundary | |

**User's choice:** Locked 2.
**Notes:** threadline CONTRIBUTING is the convention oracle (documented async reasons incl. "telemetry handlers are process-global" → Rendro's `telemetry_test.exs`; no-blind-retry; nightly `mix verify.flake`). Rendro has no Ecto sandbox — non-async reasons resolve to app-env / named-ETS / registry / port / tmpfs / time / randomness / process-global telemetry-Logger. Deferred to 110: flake-absence proof, full slow tail, partitions, actual flips/deletions.

---

## Claude's Discretion

- Table column set / section ordering within `C1-AUDIT.md` (follow brief §10).
- Exact flake-sweep seed count/targeting within the bounded floor (≥3 seeds, ~25 repeats).
- Exact echo lines / formatting of the `test`-job summary panel.

## Deferred Ideas

- Decompose the `mix ci` monolith into parallel named jobs/steps — recommend in BASE-04, implement in 109/111.
- Real green-run p95 / before-after metrics — Phase 113 (VAL-01).
- `mix verify.flake` nightly deep flake-proof lane — Phase 110/111.
- Actual `async: true` flips, quarantine, deletions, `--partitions N` — Phase 110.
- Contributor-facing target-pipeline writeup + CONTRIBUTING.md — Phase 113 (VAL-02/DX-02).

---
phase: 108-baseline-audit-report
verified: 2026-06-14T23:55:00Z
status: passed
score: 5/5
overrides_applied: 0
---

# Phase 108: Baseline Audit Report Verification

**Phase Goal:** Establish the measured source-of-truth that drives every downstream phase — what the pipeline does today, how long it takes, where the bottlenecks are, which checks are worth keeping, and what to change in priority order — WITHOUT touching gate logic or removing any test. MEASURE-ONLY.
**Verified:** 2026-06-14T23:55:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | CI job summaries surface resolved OTP/Elixir versions, scheduler count, cache state, and slowest tests | VERIFIED | `ci.yml` lines 40–65: CI Baseline Summary step emits OTP/Elixir via env-passed outputs, `System.schedulers_online()`, cache placeholders, and slowest-test grep |
| 2 | The `test` job's exit code is not changed — a failing `mix ci` still fails the job | VERIFIED | `shell: bash` sets `-eo pipefail` by default (line 34 comment confirms); `mix ci 2>&1 | tee /tmp/mix-ci-output.log` passes exit code through |
| 3 | The summary step runs even when `mix ci` fails (`if: always()`) and cannot itself fail the job (`continue-on-error: true`) | VERIFIED | Line 41: `if: always()`, line 42: `continue-on-error: true` on CI Baseline Summary step |
| 4 | No gate logic, cache keys, async flips, or test removals are introduced | VERIFIED | `git diff f1e0bbf..HEAD --name-only -- lib/ test/ mix.exs` returns empty; only `.github/workflows/ci.yml` and planning files changed |
| 5 | A current-state baseline table covers all 3 workflows (ci.yml / hexdocs.yml / release.yml) and all 10 ci.yml jobs with the required columns | VERIFIED | C1-AUDIT.md lines 27–53: three workflow tables covering all 10 jobs with required columns |
| 6 | The critical path is documented: START → test (~6.5min) → release-proof (~9-10min) = ~16-17min total, with duplicated setup-beam/deps.get/recompile enumerated | VERIFIED | BASE-02 lines 76–135: ASCII topology diagram, duplicated-work table (setup-beam×9, deps.get×8, full recompile×9 Elixir jobs) |
| 7 | Every test/check category has an A–E classification with cited evidence; all 34 async:false modules have a concrete reason or Phase 110 candidate flag | VERIFIED | BASE-03 lines 155–346: 34 modules classified by axis A–F with cited evidence; 4 residue modules with verdicts; no E candidates with named-artifact rationale |
| 8 | A prioritized P0–P3 recommendation report exists with the flagship monolith-decompose rec as the first item; each rec carries issue/change/impact/risk/rollback/phase | VERIFIED | BASE-04 lines 350–489: P0 is "Decompose the mix ci monolith" (first item); all 7 recs carry Category/Issue/Proposed change/Expected impact/Risk/Rollback/Target phase |
| 9 | p95 is written as the literal phrase "insufficient green-run data (n=3)" | VERIFIED | Appears 16 times in C1-AUDIT.md; 3 times in 108-EVIDENCE.md — all p95 cells use exact phrase |
| 10 | BASE-05 is gate-neutral: `RequiredChecksContractTest` passes at HEAD | VERIFIED | `mix test test/guardrails/required_checks_contract_test.exs` → 21 tests, 0 failures |

**Score:** 5/5 requirements verified (BASE-01 through BASE-05)

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.planning/milestones/C1-AUDIT.md` | Consolidated baseline audit — source-of-truth for phases 109–113 | VERIFIED | Exists at 489 lines; YAML frontmatter: `milestone: C1`, `status: in-progress`, `phases: [109, 110, 111, 112, 113]` |
| `.github/workflows/ci.yml` | BASE-05 job-summary instrumentation in the test job | VERIFIED | `id: setup-beam` at line 23; CI Baseline Summary step at lines 40–65; `GITHUB_STEP_SUMMARY` appears exactly once |
| `.planning/phases/108-baseline-audit-report/108-EVIDENCE.md` | All raw measurement evidence for Plan 03 | VERIFIED | All 8 required sections present: Real-Runner Timing, Critical Path Summary, Duplicated Work, Local Profiling, p95 Note, RecipesFacadeDriftTest Characterization, Bounded Flake Sweep Results, Residue async:false Module Read |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `.github/workflows/ci.yml` Run CI step | exit code propagation | `shell: bash` (`-eo pipefail` default) | WIRED | Line 34 comment confirms pipefail; `mix ci 2>&1 | tee` preserves exit code |
| `.github/workflows/ci.yml` CI Baseline Summary step | `$GITHUB_STEP_SUMMARY` | single brace-group `{ … } >> "$GITHUB_STEP_SUMMARY"` | WIRED | Line 65: single redirect; `grep -c GITHUB_STEP_SUMMARY` returns 1 |
| `steps.setup-beam.outputs.*` | CI Baseline Summary env vars | `env: OTP_VERSION / ELIXIR_VERSION` | WIRED | Lines 47–48: env-passed outputs; shell uses `${OTP_VERSION:-n/a}` |
| `108-EVIDENCE.md` timing tables | `C1-AUDIT.md` BASE-01 | direct synthesis | WIRED | All run #3/#34/#35 timing numbers appear in BASE-01 with matching values |
| `108-EVIDENCE.md` flake sweep | `C1-AUDIT.md` BASE-03 Category 5 | synthesis | WIRED | Seeds 0/1/2 results documented verbatim in BASE-03 |

---

## Data-Flow Trace (Level 4)

Not applicable — phase deliverables are planning documents and a CI YAML, not components rendering dynamic data. The CI Baseline Summary step emits real data (setup-beam action outputs + grep of /tmp/mix-ci-output.log), which are live values populated at runner time, not hardcoded.

The `cold / none` cache rows are intentional stubs with `# TODO(109)` annotation — documented in SUMMARY.md and accepted as Phase 109 seam. The stub flag in the debt-marker gate section explains why this is not a BLOCKER.

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Guardrails contract test passes at HEAD (BASE-05 gate-neutral) | `mix test test/guardrails/required_checks_contract_test.exs` | 21 tests, 0 failures | PASS |
| `id: setup-beam` present in test job | `grep -n "id: setup-beam" .github/workflows/ci.yml` | Line 23: 1 match | PASS |
| Single `GITHUB_STEP_SUMMARY` write | `grep -c "GITHUB_STEP_SUMMARY" .github/workflows/ci.yml` | `1` | PASS |
| All 4 stable H2 anchors in C1-AUDIT.md | grep for BASE-01 through BASE-04 headings | Lines 21, 72, 155, 350 | PASS |
| p95 literal phrase in C1-AUDIT.md | `grep -c "insufficient green-run data (n=3)" .planning/milestones/C1-AUDIT.md` | 16 occurrences | PASS |
| Measure-only fidelity | `git diff f1e0bbf..HEAD --name-only -- lib/ test/ mix.exs` | Empty (no output) | PASS |

---

## Probe Execution

No `probe-*.sh` scripts declared in PLAN.md or SUMMARY.md for this phase. The guardrails contract test above serves as the functional probe for BASE-05 gate-neutrality.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| BASE-01 | 108-02, 108-03 | Baseline table covering every workflow/job | SATISFIED | C1-AUDIT.md `## BASE-01 — Baseline Table` lines 21–70: all 3 workflows, all 10 ci.yml jobs with required columns |
| BASE-02 | 108-02, 108-03 | Critical path documented for PR / push-to-main / release | SATISFIED | C1-AUDIT.md `## BASE-02 — Critical Path` lines 72–152: topology diagram, release path, duplicated-work table |
| BASE-03 | 108-02, 108-03 | A–E classification with evidence per category | SATISFIED | C1-AUDIT.md `## BASE-03 — A–E Classification` lines 155–347: test gate (34 async:false by axis), 4 advisory (C), 4 live-proof (B/C), flake sweep (0 candidates), no E candidates |
| BASE-04 | 108-03 | Prioritized P0–P3 recommendation report | SATISFIED | C1-AUDIT.md `## BASE-04 — P0–P3 Recommendation Report` lines 350–489: 7 recs P0–P3, all with 7 fields, all mapped to phases 109–113 |
| BASE-05 | 108-01 | CI job summaries with OTP/Elixir/schedulers/cache/slowest tests | SATISFIED | `ci.yml` `test` job: `id: setup-beam`, `shell: bash` + tee, CI Baseline Summary step with `if: always()` + `continue-on-error: true` + single brace-group write |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.github/workflows/ci.yml` | 58 | `# TODO(109): replace 'cold / none'...` | Info | Intentional Phase 109 seam — cache rows are placeholders by design, marked with a phase-referenced TODO. Not an unresolved debt marker: the issue is `TODO(109)` referencing a formal follow-up phase (the gsd framework's equivalent of a tracked work item). Disposition: acceptable. |

No `TBD`, `FIXME`, or `XXX` markers found in any modified file.

The `cold / none` cache rows in the CI Baseline Summary step are intentional stubs documented in 108-01-SUMMARY.md "Known Stubs" table and explicitly accepted as the Phase 109 seam. The `# TODO(109)` comment references Phase 109 as the tracked follow-up. Per debt-marker gate rules: unreferenced markers are blockers; this marker references `109` which is a formal downstream phase — acceptable.

---

## Measure-Only Fidelity

**Hard checks per phase-specific verification instructions:**

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| No lib/test/mix.exs changes since pre-phase commit f1e0bbf | `git diff f1e0bbf..HEAD --name-only -- lib/ test/ mix.exs` | Empty (no output) | PASS |
| Guardrails contract test passes at HEAD | `mix test test/guardrails/required_checks_contract_test.exs` | 21 tests, 0 failures | PASS |

**Pre-existing failures (noted, not charged to Phase 108):** Two `mix ci` test failures exist on main and reproduce identically at the pre-phase commit `f1e0bbf`:
1. `Rendro.PublicApiTest` — `Mix.Tasks.Brand.Gen` missing `@moduledoc` tag (pre-existing code gap)
2. `RecipesFacadeDriftTest` — seed-0 module-loading ordering artifact (pre-existing test design issue)

Both are documented as baseline findings in C1-AUDIT.md BASE-03 Category 4. Phase 108 changed zero lib/test code.

---

## BASE-05 Specific Verification

The phase-specific instructions require verifying against the `test` job's exact implementation:

| Criterion | Specification | Actual | Status |
|-----------|--------------|--------|--------|
| `id: setup-beam` on Setup Beam step | `id: setup-beam` | Line 23: `id: setup-beam` | PASS |
| Run CI step: `shell: bash` | `shell: bash` | Line 33: `shell: bash` | PASS |
| Run CI step: `mix ci 2>&1 | tee` | `mix ci 2>&1 | tee` | Line 38: `run: mix ci 2>&1 | tee /tmp/mix-ci-output.log` | PASS |
| Summary step name | `name: CI Baseline Summary` | Line 40: `- name: CI Baseline Summary` | PASS |
| Summary step condition | `if: always()` | Line 41: `if: always()` | PASS |
| Summary step error isolation | `continue-on-error: true` | Line 42: `continue-on-error: true` | PASS |
| Outputs via env vars not inline expressions | `env: OTP_VERSION: ${{ steps.setup-beam.outputs.otp-version }}` | Lines 47–48: env-passed | PASS |
| Single brace-group write | `{ … } >> "$GITHUB_STEP_SUMMARY"` | Line 65; `grep -c GITHUB_STEP_SUMMARY ci.yml` = 1 | PASS |
| Phase 109 seam comment | `# TODO(109)` | Line 58 | PASS |

**Notable implementation choice:** The plan specified `set -o pipefail` as an explicit first line of the `run:` block. The implementation instead uses `shell: bash` which invokes bash with `-eo pipefail` by default (GitHub Actions behavior: `bash --noprofile --norc -eo pipefail {0}`). This is functionally equivalent and is documented with an inline comment at line 34. The acceptance criteria grep for `pipefail|PIPESTATUS` returns a match at line 34 (the comment). The guardrails test passes confirming gate-neutrality. This is a valid implementation choice, not a deviation.

---

## BASE-01 Specific Verification

The p95 literal phrase "insufficient green-run data (n=3)" appears in the table for every job (ci.yml: 10 jobs, hexdocs.yml: 2 jobs, release.yml: 1 job) — 16 total occurrences verified by `grep -c`. The phrase is also the exact aggregate p95 entry in the Key Aggregate Findings table.

BASE-01 covers:
- All 3 workflows: ci.yml, hexdocs.yml, release.yml — VERIFIED
- All 10 ci.yml jobs — VERIFIED (test, example-phoenix, raster-advisory, comparison-advisory, livebook-advisory, pdfjs-advisory, signing-live-proof, long-lived-live-proof, viewer-evidence-live-proof, release-proof)
- Required columns — VERIFIED (Workflow, Trigger, Job, Runner, Command, Avg Duration, p95 Duration, Required-for-merge, Cache, Quality Signal, Likely Bottleneck, Notes)

---

## BASE-03 Specific Verification

The phase-specific instruction requires: "classifies the test gate + 4 advisory + 4 live-proof lanes and the 34 async:false modules with cited evidence; E requires a named artifact."

| Required element | Status | Evidence |
|-----------------|--------|----------|
| test gate classification | VERIFIED | Category 1: 89 async:true (A), 34 async:false by axis A–F with cited evidence, 4 residue modules with verdicts |
| 4 advisory lanes classified | VERIFIED | Category 2: raster-advisory, comparison-advisory, livebook-advisory, pdfjs-advisory — all C |
| 4 live-proof lanes classified | VERIFIED | Category 3: release-proof (B), signing-live-proof/long-lived/viewer-evidence (C) |
| 34 async:false modules with cited evidence | VERIFIED | Category 1b: each module mapped to its axis with the specific function/reason cited |
| E requires named artifact | VERIFIED | Category 6: "Per D-04: Classification E requires a named artifact... No E candidates identified" |

---

## Human Verification Required

None. All deliverables are verifiable programmatically (file existence, content patterns, grep assertions, test execution). No UI rendering, real-time behavior, or external service integration is involved in this phase.

---

## Gaps Summary

No gaps. All 5 requirements (BASE-01 through BASE-05) are fully satisfied.

The one notable implementation choice (using `shell: bash` for implicit pipefail instead of an explicit `set -o pipefail` first line) achieves the same functional result and is accepted: the guardrails test passes, the plan's acceptance-criteria grep matches, and the comment at line 34 documents the behavior explicitly.

---

_Verified: 2026-06-14T23:55:00Z_
_Verifier: Claude (gsd-verifier)_

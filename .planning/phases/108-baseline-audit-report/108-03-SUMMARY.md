---
phase: 108-baseline-audit-report
plan: "03"
subsystem: planning-docs
tags: [baseline, audit, ci-cd, measure-only]
dependency_graph:
  requires: [108-02]
  provides: [C1-AUDIT.md]
  affects: [109, 110, 111, 112, 113]
tech_stack:
  added: []
  patterns: [milestone-audit-doc, stable-H2-anchors, P0-P3-recommendation-report]
key_files:
  created:
    - .planning/milestones/C1-AUDIT.md
  modified: []
decisions:
  - D-03 honored: one consolidated file at C1-AUDIT.md; stable H2 anchors locked mid-milestone
  - D-04 honored: measured-but-bounded A-E classification; E requires named artifact; no E candidates
  - p95 written as exact literal phrase "insufficient green-run data (n=3)" per D-01 mandate
  - Local proxy numbers carry "local proxy (18 schedulers; not runner-absolute)" tag throughout
  - Flagship P0 recommendation: "decompose the mix ci monolith into parallel named jobs/steps"
metrics:
  duration: 35min
  completed: "2026-06-14"
  tasks_completed: 2
  files_created: 1
  files_modified: 0
---

# Phase 108 Plan 03: C1 Baseline Audit Document Summary

## One-Liner

Authored `C1-AUDIT.md` — the Phase 108 measure-only baseline audit with all four stable H2 anchors (BASE-01 through BASE-04) populated from `108-EVIDENCE.md` evidence, covering all 10 ci.yml jobs, the 16–17 min critical path, A–E classification of all 127 test modules, and a 7-recommendation P0–P3 report with `mix ci` monolith decomposition as the flagship P0.

## What Was Built

**`.planning/milestones/C1-AUDIT.md`** — the consolidated planning-internal baseline audit document for milestone C1, with YAML frontmatter (`milestone: C1`, `status: in-progress`, `phases: [109, 110, 111, 112, 113]`) and four stable H2 sections:

### BASE-01 — Baseline Table

Covers all 3 workflows (ci.yml, hexdocs.yml, release.yml) and all 10 ci.yml jobs. Columns: Workflow | Trigger | Job | Runner | Command | Avg Duration | p95 Duration | Required-for-merge | Cache (deps) | Cache (_build) | Quality Signal | Likely Bottleneck | Notes.

Key findings documented:
- `test` job: `mix ci` avg 327s (local proxy — 18 schedulers; not runner-absolute); job total avg ~345s; p95 = **"insufficient green-run data (n=3)"**
- `release-proof`: avg ~599s — critical path bottleneck
- Zero caching anywhere (deps, `_build`, PLTs)
- `pdfjs-advisory`: timing (11s) from single failed run 37 with hot npm cache — noted as approximate
- `release.yml publish`: re-runs `mix ci` (412s) despite tag being built from CI-green SHA
- setup-beam `@v1` floating in ci.yml and release.yml vs SHA-pinned in hexdocs.yml — inconsistent supply-chain posture flagged for SEC-01/Phase 112

### BASE-02 — Critical Path

Documented the full Tier 1/Tier 2 topology with ASCII diagram. Critical path: START → `test` (~6.5 min) → `release-proof` (~9–10 min) = **16–17 min total**. `release-proof` is the wall-clock bottleneck because it must wait for `test` then runs its own cold compile.

Duplicated work inventory: setup-beam (9/10 jobs), `mix deps.get` (8+ jobs), full `_build` cold recompile (all 9 Elixir jobs), `mix ci` full run (both ci.yml `test` job and release.yml `publish` job).

xref stats: 5 compile edges, 0 cycles — bottleneck is cold-cache, not structural compile-chain.

### BASE-03 — A–E Classification

All 127 test modules classified:
- 89 `async: true` modules: bulk **A**
- 34 explicit `async: false` modules: all **A** with concrete cited non-async reason by axis (A=`Application.put_env`, B=`:telemetry.attach`, C=global BEAM recompile, D=`System.tmp_dir` fixed path, E=`System.cmd` overlap with A, F=`mix hex.build` invocation)
- 4 residue modules (human-read from 108-EVIDENCE.md): BrandingContractTest (**A**, Phase 110 async:true candidate), IntegrationsContractTest (**A**, named ETS table, borderline candidate), RecipesContractTest (**A**, Phase 110 candidate), ManifestTest (**A**, global BEAM recompile confirmed required)
- 4 modules with no explicit `async:` setting: noted for Phase 110 assessment
- 4 advisory jobs: **C** (correctly tiered as soft-fail)
- `release-proof`: **B** (high value, critical path bottleneck, Phase 111 to rationalize)
- 3 live-proof gates: **C** (correctly post-`test`-gated)
- Flake sweep: **0 candidates** (3 seeds × 25 repeats; D-04 ceiling — deep proof deferred to Phase 110)
- **No E candidates** identified — D-04 evidence floor requires named artifact; none found
- 2 pre-existing baseline red-state failures documented (PublicApiTest: missing `@moduledoc`; RecipesFacadeDriftTest: seed-0 module-loading ordering artifact)

### BASE-04 — P0–P3 Recommendation Report

7 recommendations, all mapped to phases 109–113:

| Priority | Title | Target Phase | Req ID |
|----------|-------|-------------|--------|
| P0 | Decompose the `mix ci` monolith into parallel named jobs/steps | 109 + 111 | FLOW-01, DX-01, DX-03 |
| P1 | Add keyed `deps`/`_build`/PLT caching (zero caching currently) | 109 | CACHE-01 through CACHE-05 |
| P1 | SHA-pin `erlef/setup-beam` in ci.yml and release.yml | 112 | SEC-01, CACHE-04 |
| P2 | Rationalize `release-proof` job's presence on every PR | 111 | FLOW-01, FLOW-03 |
| P2 | Convert safe async:false modules to async:true | 110 | TEST-01, TEST-03 |
| P3 | Add PR-level concurrency cancellation | 111 | FLOW-02 |
| P3 | Dependency/security audit lane (`mix hex.audit`) | 112 | SEC-04 |

Each recommendation carries all 7 required fields: Category, Issue, Proposed change, Expected impact, Risk, Rollback, Target phase.

## Commits

| Hash | Message |
|------|---------|
| `885637d` | feat(108-03): author C1-AUDIT.md baseline audit document |

## Deviations from Plan

None — plan executed exactly as written. The file was authored in a single Write operation covering both tasks (Tasks 1 and 2 both modify the same file `.planning/milestones/C1-AUDIT.md`). Evidence was sourced exclusively from `108-EVIDENCE.md` as required. No source files, test files, workflow YAMLs, or other planning files were modified.

**Baseline findings documented (per critical constraints — findings only, not fixes):**

1. `RequiredChecksContractTest` guardrail asserted the literal `run: mix ci` lane; BASE-05 tee instrumentation used a single-line `run: mix ci 2>&1 | tee` under `shell: bash` (pipefail-by-default) to remain gate-neutral. Documented in BASE-03 as a structural constraint that any future `mix ci` decomposition (P0/P1) must update in lockstep.

2. Two pre-existing `mix ci` failures on main documented in BASE-03: `Rendro.PublicApiTest` (Mix.Tasks.Brand.Gen missing `@moduledoc`) and `RecipesFacadeDriftTest` (seed-0 ordering artifact — `Rendro.Recipes` not VM-loaded in isolation). Both reproduce identically at the pre-phase commit; both are Phase 110 (TEST) candidates.

## Known Stubs

None — `C1-AUDIT.md` is a planning document, not UI-rendering code. All data is sourced from `108-EVIDENCE.md` measured evidence. No placeholder numbers or "coming soon" content.

## Threat Flags

None — `C1-AUDIT.md` introduces no new network endpoints, auth paths, file access patterns, or schema changes. It is a planning-internal document excluded from Hex package and ExDoc extras.

## Self-Check: PASSED

- [x] `.planning/milestones/C1-AUDIT.md` exists
- [x] Commit `885637d` exists in git log
- [x] All 4 stable H2 anchors present (verified by grep)
- [x] p95 phrase "insufficient green-run data (n=3)" present 16 times in file
- [x] "local proxy (18 schedulers; not runner-absolute)" tag present 3+ times
- [x] Flagship P0 "Decompose the `mix ci` monolith" present as first BASE-04 item
- [x] All phases 109–113 referenced in target-phase fields
- [x] No source files modified (git diff --name-only shows only C1-AUDIT.md)
- [x] YAML frontmatter: `milestone: C1`, `status: in-progress`, `phases: [109, 110, 111, 112, 113]`

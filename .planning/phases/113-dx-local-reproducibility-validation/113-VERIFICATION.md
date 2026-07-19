---
phase: 113-dx-local-reproducibility-validation
verified: 2026-07-11T01:30:00Z
status: passed
score: 5/5 verification checks passed
remote_metrics_status: complete
overrides_applied: 0
---

# Phase 113: DX, Local Reproducibility & Validation Verification Report

**Phase Goal:** Make the C1 pipeline reproducible for contributors, keep failures actionable, document the required gate, and record before/after validation evidence truthfully.
**Verified:** 2026-07-11T01:30:00Z
**Status:** passed for local, structural, and remote validation evidence.

---

## Goal Achievement

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Scoped Mix aliases exist for deterministic fast checks, proof checks, and advisory checks. | VERIFIED | `mix.exs` defines `ci.fast`, `ci.proofs`, `ci.advisory`, and root `ci`. |
| 2 | The CI fast lane is split into actionable named steps while preserving the local `ci.fast` command sequence. | VERIFIED | `.github/workflows/ci.yml` has Format, Hex Build, Compile, Test, Docs, Credo, and Dialyzer steps; `test/docs_contract/dx_local_reproducibility_claims_test.exs` checks this contract. |
| 3 | Contributor docs state the local/CI parity contract without hiding proof-tool divergence. | VERIFIED | `CONTRIBUTING.md` defines `mix ci.fast` as the deterministic local gate and explains that `mix ci` is 1:1 only when local proof tooling matches CI. |
| 4 | README badging targets the meaningful required check name. | VERIFIED | README badge uses the `ci-success` check-run name. |
| 5 | Validation evidence records local and remote data truthfully. | VERIFIED | `113-METRICS.md` records the local gate plus three green remote `ci.yml` runs, p50/p95 timing, cache restore behavior, failure/rerun rate, compile time, and slowest-test evidence. |

---

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| DX-01 | SATISFIED | `mix ci.fast` reproduces the deterministic `test` job locally; documented divergence states that full `mix ci` proof parity requires locally installed proof tools and otherwise GitHub Actions is authoritative for `integration-proofs`. |
| DX-02 | SATISFIED | `CONTRIBUTING.md` documents required checks, scoped local commands, and seeded ExUnit reproduction. |
| DX-03 | SATISFIED | CI workflow exposes named steps, slowest-test summaries, and separate proof/advisory jobs so failures map to a concrete command or environment. |
| DX-04 | SATISFIED | README badge targets `ci-success`. |
| VAL-01 | SATISFIED | `113-METRICS.md` records before/after wall-clock, cache, failure/rerun, compile, and slowest-test evidence from three green remote `ci.yml` runs. |
| VAL-02 | SATISFIED | `113-METRICS.md` includes the steady-state PR/main/nightly/release/docs pipeline design. |

`VAL-01` is now closed by post-push GitHub Actions evidence from runs `29133061301`, `29133777702`, and `29134266708`.

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Scoped alias/docs contract remains wired | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs test/mix/tasks/ci_alias_contract_test.exs` | 8 tests, 0 failures | PASS |
| Alias structure remains wired | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs test/mix/tasks/ci_alias_contract_test.exs` | 8 tests, 0 failures | PASS |
| Full deterministic local fast gate | `mix ci.fast` | Passed: 1219 tests, 12 doctests, 4 properties, 0 failures, 20 excluded; Credo clean; Dialyzer 0 errors | PASS |
| Remote required gate sample | `gh run view 29133061301`, `gh run view 29133777702`, `gh run view 29134266708` | Three workflow-level successes; `ci-success` p50 783s and nearest-rank p95 1013s; primary test jobs restored caches | PASS |

---

## Remote Evidence Closure

Remote Actions metrics are closed for C1:

- three green `ci.yml` runs for the C1 validation branch
- required-gate wall-clock p50 783s and nearest-rank p95 1013s
- deps exact hit 3/3; `_build` restored 3/3 with exact hit 2/3; PLT exact hit 3/3
- failure/rerun rate 0/3 workflow failures, no reruns
- compile step 1s in all sampled primary test jobs
- slowest-test summaries recorded in GitHub logs

The advisory `security-audit` job remains non-required maintenance signal for known dependency advisories and does not block the deterministic C1 required gate.

---
phase: 113-dx-local-reproducibility-validation
verified: 2026-07-10T23:57:26Z
status: passed
score: 5/5 local verification checks passed
remote_metrics_status: pending_post_push
overrides_applied: 0
---

# Phase 113: DX, Local Reproducibility & Validation Verification Report

**Phase Goal:** Make the C1 pipeline reproducible for contributors, keep failures actionable, document the required gate, and record before/after validation evidence truthfully.
**Verified:** 2026-07-10T23:57:26Z
**Status:** passed for local/structural verification; remote post-push metrics remain pending for milestone-level VAL-01 closure.

---

## Goal Achievement

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Scoped Mix aliases exist for deterministic fast checks, proof checks, and advisory checks. | VERIFIED | `mix.exs` defines `ci.fast`, `ci.proofs`, `ci.advisory`, and root `ci`. |
| 2 | The CI fast lane is split into actionable named steps while preserving the local `ci.fast` command sequence. | VERIFIED | `.github/workflows/ci.yml` has Format, Hex Build, Compile, Test, Docs, Credo, and Dialyzer steps; `test/docs_contract/dx_local_reproducibility_claims_test.exs` checks this contract. |
| 3 | Contributor docs state the local/CI parity contract without hiding proof-tool divergence. | VERIFIED | `CONTRIBUTING.md` defines `mix ci.fast` as the deterministic local gate and explains that `mix ci` is 1:1 only when local proof tooling matches CI. |
| 4 | README badging targets the meaningful required check name. | VERIFIED | README badge uses the `ci-success` check-run name. |
| 5 | Validation evidence does not claim unavailable remote data. | VERIFIED | `113-METRICS.md` records the local gate and marks post-push GitHub p50/p95 and cache-hit rates pending. |

---

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| DX-01 | SATISFIED | `mix ci.fast` reproduces the deterministic `test` job locally; documented divergence states that full `mix ci` proof parity requires locally installed proof tools and otherwise GitHub Actions is authoritative for `integration-proofs`. |
| DX-02 | SATISFIED | `CONTRIBUTING.md` documents required checks, scoped local commands, and seeded ExUnit reproduction. |
| DX-03 | SATISFIED | CI workflow exposes named steps, slowest-test summaries, and separate proof/advisory jobs so failures map to a concrete command or environment. |
| DX-04 | SATISFIED | README badge targets `ci-success`. |
| VAL-02 | SATISFIED | `113-METRICS.md` includes the steady-state PR/main/nightly/release/docs pipeline design. |

`VAL-01` is intentionally treated as milestone-level remote evidence rather than a local phase verification claim: current GitHub Actions history predates the 105 local C1 commits, so post-push p50/p95 and cache-hit statistics cannot be verified from this checkout alone.

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Scoped alias/docs contract remains wired | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs test/mix/tasks/ci_alias_contract_test.exs` | 8 tests, 0 failures | PASS |
| Alias structure remains wired | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs test/mix/tasks/ci_alias_contract_test.exs` | 8 tests, 0 failures | PASS |
| Full deterministic local fast gate | `mix ci.fast` | Passed: 1216 tests, 12 doctests, 4 properties, 0 failures, 20 excluded; Credo clean; Dialyzer 0 errors | PASS |

---

## Remote Evidence Boundary

Remote Actions metrics are not closed by this file. `VAL-01` still requires post-push GitHub Actions evidence from the C1 workflow state:

- at least three green `ci.yml` runs for the C1 commits
- wall-clock p50/p95
- cache hit rates for deps, `_build`, and PLT
- failure/rerun rate
- compile time and slowest-test evidence

This report closes the missing Phase 113 verification artifact and the local DX proof, but the milestone audit should remain blocked until the remote metrics are collected or explicitly deferred.

# Phase 113 C1 Validation Metrics

**Generated:** 2026-07-10  
**Scope:** C1 CI/CD Performance & Reliability validation for the current local branch.

## Evidence Status

This report records the final C1 validation state available from the current checkout. GitHub Actions history was queried with:

```sh
gh run list --workflow=ci.yml --limit 10 --json databaseId,displayTitle,headBranch,status,conclusion,createdAt,updatedAt,event,url
gh run view 27512247437 --json databaseId,displayTitle,createdAt,updatedAt,conclusion,jobs,url
gh run view 27443757934 --json databaseId,displayTitle,createdAt,updatedAt,conclusion,jobs,url
gh run view 27441368861 --json databaseId,displayTitle,createdAt,updatedAt,conclusion,jobs,url
```

The most recent remote `ci.yml` runs predate the local C1 phase-113 commits and therefore cannot be used as post-merge GitHub timing proof for this branch. The post-push p50/p95 and cache-hit rates are intentionally marked pending rather than inferred.

## Phase 108 Baseline vs Current State

| Metric | Phase 108 Baseline | Current C1 State | Evidence |
|--------|--------------------|------------------|----------|
| Required local command | `mix ci` monolith | `mix ci` = `ci.fast` + `ci.proofs`; scoped `ci.fast`, `ci.proofs`, `ci.advisory` aliases available | `mix.exs`, `mix help ci.fast` |
| Fast local required lane | `mix ci` inner step avg 327s, local proxy from 3 green runs | `mix ci.fast` green locally in 12s with warm PLTs on 2026-07-10 | `mix ci.fast` exit 0, `ci.fast_seconds=12` |
| Default test lane | Included inside opaque `Run CI` step | Split CI `Test` step and local `mix test --exclude quarantine --slowest 10` | `.github/workflows/ci.yml`, `mix ci.fast` output |
| Default test result | Baseline had pre-existing failures documented in Phase 108 | 1211 tests, 12 doctests, 4 properties, 0 failures, 20 excluded | `mix ci.fast` output, seed 869542 |
| Strict static checks | Opaque inside `Run CI` | `mix credo --strict` found no issues; `mix dialyzer` found 0 errors | `mix ci.fast` output |
| Full CI wall-clock | 966s and 1039s for the last two green baseline runs; p95 insufficient (n=3) | Pending post-push GitHub run for this branch | `gh run view 27441368861`, `gh run view 27443757934` |
| Cache coverage | No deps, `_build`, or PLT cache in `ci.yml` | `test` job restores deps, `_build`, and PLT caches; PLT save runs even after failures | `.github/workflows/ci.yml` |
| Cache hit rate | 0% by configuration: no caches existed | Pending post-push GitHub summaries; local run uses local filesystem/PLTs, not Actions cache | `CI Baseline Summary` step emits hit/miss values |
| Workflow topology | 10 jobs with separate advisory and live-proof lanes; `release-proof` dominated critical path | 6 jobs: `test`, `example-phoenix`, `advisory-checks`, `integration-proofs`, `security-audit`, `ci-success` | `.github/workflows/ci.yml` |
| Required check name | Multiple unstable required contexts possible | Stable `ci-success` summary job and README badge target | `.github/workflows/ci.yml`, `README.md` |

## Latest Remote Run Snapshot

| Run | Date | Conclusion | Wall Clock | Notes |
|-----|------|------------|------------|-------|
| `27512247437` | 2026-06-14 | failure | ~304s total | Latest remote run; failed quickly in old `Run CI` step before current local C1 fixes. |
| `27443757934` | 2026-06-12 | success | 1039s | Baseline-style green run; `test` job 389s, `Run CI` step 372s, `release-proof` 645s. |
| `27441368861` | 2026-06-12 | success | 966s | Baseline-style green run; `test` job 401s, `Run CI` step 386s, `release-proof` 553s. |

## Local Final Gate

The current local fast gate passes:

```text
mix ci.fast
ci.fast_exit=0
ci.fast_seconds=12
```

Observed gate details from the successful local run:

| Gate | Result |
|------|--------|
| `mix format --check-formatted` | Passed |
| `mix hex.build` | Passed |
| `mix compile --warnings-as-errors` | Passed |
| `mix test --exclude quarantine --slowest 10` | Passed: 1211 tests, 12 doctests, 4 properties, 0 failures, 20 excluded |
| `mix docs --warnings-as-errors` | Passed |
| `mix credo --strict` | Passed: no issues |
| `mix dialyzer` | Passed: 0 errors |

## Steady-State Pipeline Design

### Pull Request / Main Fast Path

- The `test` job is the primary deterministic fast lane.
- The primary OTP/Elixir matrix entry runs named steps: Format, Hex Build, Compile, Test, Docs, Credo, Dialyzer.
- The secondary matrix entry runs only the default ExUnit lane to preserve minimum-supported runtime coverage without duplicating static checks.
- `ci-success` is the single required check name for branch protection and README badging.

### Proof and Advisory Lanes

- `integration-proofs` runs after `test` and contains viewer evidence, signing, long-lived signing, and release preflight proofing in one bounded job.
- `advisory-checks` is graph-disconnected and soft-fail. It covers raster snapshots, launch artifacts, comparison evidence, Livebook, and PDF.js observation checks.
- `security-audit` is soft-fail in CI for immediate signal; the strict maintenance posture remains a scheduled or release concern.

### Observability

- CI summaries report OTP, Elixir, scheduler count, deps cache hit, `_build` cache hit, PLT cache hit, and slowest tests.
- The Test step tees output to `/tmp/mix-test-output.log`, so summaries no longer depend on a monolithic `mix ci` log.
- `erlef/setup-beam` remains the problem-matcher source for Elixir tooling annotations.

## Validation Conclusion

C1 has achieved the structural and local reproducibility goals in this checkout: the fast local gate is green, scoped Mix aliases map to the CI lanes, logs are split into actionable GitHub steps, the required status is represented by `ci-success`, and the pipeline has cache restore/save points for the major BEAM costs.

The remaining empirical gap is remote Actions measurement after these local commits are pushed. Post-push validation should record p50/p95 wall-clock and cache hit rates from at least three green `ci.yml` runs before treating remote runtime improvement as statistically proven.

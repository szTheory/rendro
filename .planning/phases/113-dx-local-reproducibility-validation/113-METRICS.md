# Phase 113 C1 Validation Metrics

**Generated:** 2026-07-11
**Scope:** C1 CI/CD Performance & Reliability validation for the current PR branch.

## Evidence Status

This report records the final C1 validation state collected from local verification and GitHub Actions runs on `gsd/c1-remote-validation`.

Remote evidence was queried with:

```sh
gh run view 29133061301 --json databaseId,status,conclusion,createdAt,updatedAt,url,headSha,jobs
gh run view 29133777702 --json databaseId,status,conclusion,createdAt,updatedAt,url,headSha,jobs
gh run view 29134266708 --json databaseId,status,conclusion,createdAt,updatedAt,url,headSha,jobs
gh run view <run> --job <primary-test-job> --log
```

The final validation sample has three green `ci.yml` workflow runs. The first green run was also the corrective run that proved the required gate after release-proof determinism was fixed; the following two runs include the later deterministic release-proof speedup. For p95 over the three-run sample, this document uses nearest-rank p95, which is the maximum value when `n=3`.

## Phase 108 Baseline vs Current State

| Metric | Phase 108 Baseline | Current C1 State | Evidence |
|--------|--------------------|------------------|----------|
| Required local command | `mix ci` monolith | `mix ci` = `ci.fast` + `ci.proofs`; scoped `ci.fast`, `ci.proofs`, `ci.advisory` aliases available | `mix.exs`, `mix help ci.fast` |
| Fast local required lane | `mix ci` inner step avg 327s, local proxy from 3 green runs | `mix ci.fast` green locally in 12s with warm PLTs on 2026-07-10 | `mix ci.fast` exit 0, `ci.fast_seconds=12` |
| Default test lane | Included inside opaque `Run CI` step | Split CI `Test` step and local `mix test --exclude quarantine --slowest 10` | `.github/workflows/ci.yml`, GitHub run logs |
| Default test result | Baseline had pre-existing failures documented in Phase 108 | 1219 tests, 12 doctests, 4 properties, 0 failures, 20 excluded | Local `mix ci.fast`; GitHub runs `29133777702`, `29134266708` |
| Strict static checks | Opaque inside `Run CI` | `mix credo --strict` found no issues; `mix dialyzer` found 0 errors | `mix ci.fast`; GitHub primary `test` job |
| Full CI / required gate wall-clock | 966s and 1039s for the last two green baseline runs | Three-run sample: p50 783s, nearest-rank p95 1013s; optimized steady-state observed 774s-783s | `ci-success` completion in runs below |
| Cache coverage | No deps, `_build`, or PLT cache in `ci.yml` | Primary `test` job restores deps, `_build`, and PLT caches; PLT save skips on exact hit | GitHub test job logs |
| Cache hit / restore rate | 0% by configuration: no caches existed | deps exact hit 3/3; `_build` restored 3/3 and exact hit 2/3 after one key transition; PLT exact hit 3/3 | Actions/cache logs for primary `test` job |
| Workflow topology | 10 jobs with separate advisory and live-proof lanes; `release-proof` dominated critical path | 6 logical lanes: `test`, `example-phoenix`, `advisory-checks`, `integration-proofs`, `security-audit`, `ci-success` | `.github/workflows/ci.yml` |
| Required check name | Multiple unstable required contexts possible | Stable `ci-success` summary job and README badge target | `.github/workflows/ci.yml`, `README.md` |

## Remote Validation Runs

| Run | Commit | Date (UTC) | Workflow | Required gate (`ci-success`) | Primary `test` job | Integration proofs | Release proof step | Compile step | Result |
|-----|--------|------------|----------|-------------------------------|--------------------|--------------------|--------------------|--------------|--------|
| [`29133061301`](https://github.com/szTheory/rendro/actions/runs/29133061301) | `be7dd9a` | 2026-07-11 | 1014s | 1013s | 50s | 956s | 666s | 1s | success |
| [`29133777702`](https://github.com/szTheory/rendro/actions/runs/29133777702) | `74b86cd` | 2026-07-11 | 784s | 783s | 53s | 718s | 423s | 1s | success |
| [`29134266708`](https://github.com/szTheory/rendro/actions/runs/29134266708) | `467fb46` | 2026-07-11 | 774s | 774s | 52s | 714s | 428s | 1s | success |

Aggregate over the three green runs:

| Metric | p50 | p95 (nearest-rank, n=3) | Notes |
|--------|-----|--------------------------|-------|
| Required gate wall-clock | 783s | 1013s | `createdAt` to `ci-success.completedAt` |
| Workflow wall-clock | 784s | 1014s | `createdAt` to `updatedAt` |
| Primary `test` job | 52s | 53s | Includes setup, caches, format, build, compile, tests, docs, Credo, Dialyzer |
| `integration-proofs` job | 718s | 956s | First run predates the `--skip-ci` proof speedup |
| Release proof step | 428s | 666s | Optimized steady-state runs observed 423s and 428s |
| Compile step | 1s | 1s | Warm `_build` cache |
| Test step | 16s | 17s | Default ExUnit lane with quarantined/live tests excluded |

Failure/rerun rate for the final validation sample: 0/3 workflow failures and no reruns required.

`security-audit` failed inside each sampled workflow because current dev/test dependencies have known advisories. That job is intentionally advisory/non-required in C1; the required `ci-success` gate depends on `test` and `integration-proofs`, both green. The failure remains useful signal for dependency maintenance but is not a C1 archive blocker.

## Cache Evidence

The primary `test` job restored all major BEAM caches in the three-run sample:

| Cache | Run 29133061301 | Run 29133777702 | Run 29134266708 | Final sample result |
|-------|-----------------|-----------------|-----------------|---------------------|
| deps | exact primary hit | exact primary hit | exact primary hit | 3/3 exact hits |
| `_build` | restored via compatible key, then saved exact key | exact primary hit | exact primary hit | 3/3 restored, 2/3 exact hits |
| PLT | exact primary hit; save skipped | exact primary hit; save skipped | exact primary hit; save skipped | 3/3 exact hits |

Representative log evidence:

- `29133061301`: deps cache restored from `Linux-deps-v1-OTP-28.5.0.3-v1.19.5-otp-28-test-...`; `_build` restored from a compatible build key and saved the exact key used by later runs; PLT exact hit.
- `29133777702`: deps, `_build`, and PLT exact primary hits; post-cache steps reported "not saving cache."
- `29134266708`: deps, `_build`, and PLT exact primary hits; post-cache steps reported "not saving cache."

## Test and Slowest-Test Evidence

The final optimized runs report:

- `29133777702`: `12 doctests, 4 properties, 1219 tests, 0 failures (20 excluded)`; test step 16s; top 10 slowest total 4.2s.
- `29134266708`: `12 doctests, 4 properties, 1219 tests, 0 failures (20 excluded)`; test step 17s; top 10 slowest total 3.9s.

Top slowest-test families were stable and expected: docs-contract package/evidence checks, public API manifest regeneration, conditional-adapter recompilation checks, telemetry render-id checks, and README compile/eval fences. No new flaky or low-signal class appeared in the remote sample.

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
| `mix test --exclude quarantine --slowest 10` | Passed: 1219 tests, 12 doctests, 4 properties, 0 failures, 20 excluded |
| `mix docs --warnings-as-errors` | Passed |
| `mix credo --strict` | Passed: no issues |
| `mix dialyzer` | Passed: 0 errors |

## Steady-State Pipeline Design

### Pull Request / Main Fast Path

- The `test` job is the primary deterministic fast lane.
- The primary OTP/Elixir matrix entry runs named steps: Format, Hex Build, Compile, Test, Docs, Credo, Dialyzer.
- The secondary matrix entry runs only the default ExUnit lane outside pull request events to preserve minimum-supported runtime coverage without duplicating static checks on PRs.
- `ci-success` is the single required check name for branch protection and README badging.

### Proof and Advisory Lanes

- `integration-proofs` runs after `test` and contains viewer evidence, signing, long-lived signing, and deterministic release preflight proofing in one bounded job.
- `advisory-checks` is graph-disconnected and soft-fail. It covers raster snapshots, launch artifacts, comparison evidence, Livebook, and PDF.js observation checks.
- `security-audit` is soft-fail in CI for immediate signal; the strict maintenance posture remains a scheduled or release concern.

### Observability

- CI summaries report OTP, Elixir, scheduler count, deps cache hit, `_build` cache hit, PLT cache hit, and slowest tests.
- The Test step tees output to `/tmp/mix-test-output.log`, so summaries no longer depend on a monolithic `mix ci` log.
- `erlef/setup-beam` remains the problem-matcher source for Elixir tooling annotations.

## Validation Conclusion

C1 has achieved the structural, local reproducibility, and remote validation goals: the fast local gate is green, scoped Mix aliases map to the CI lanes, logs are split into actionable GitHub steps, the required status is represented by `ci-success`, cache restore points are empirically warm on the primary job, and three remote `ci.yml` runs completed with the required gate green.

The only known red signal is the intentionally advisory `security-audit` job for current dependency advisories. That is tracked as maintenance signal outside the required deterministic merge gate.

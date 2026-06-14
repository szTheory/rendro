# C1 Audit Brief — CI/CD Performance & Reliability

> **Source brief for milestone C1.** This is the verbatim companion prompt the user authored to scope a
> comprehensive CI/CD pipeline audit of Rendro. It is the canonical scope/checklist for the milestone:
> every phase researcher, planner, and verifier should cite the relevant section(s) below. The original
> human prompt (taste/context) is preserved first, followed by the inflated multi-expert companion prompt.
>
> Phases map to this brief as: 108 → §3/§4/§10/§11 (baseline + audit report); 109 → §6.5/§6.6 (caching);
> 110 → §4/§5 (test quality/concurrency/determinism); 111 → §6.1–§6.4/§6.8 (topology/triggers/matrix);
> 112 → §7 (security/supply-chain/release); 113 → §8/§9 (DX + validation).

---

## Original human prompt (high-priority taste/context)

audit our ci/cd pipeline make sure it's as efficient as possible, great DX also important and efficient so like not wasting our time or CI runner time

but yeah we want to keep the high value tests just dropping the lowest quality ones, poorest quality least value. i think it's nice to be able to boil the ocean especially with AI/LLM help nowadays i'm just saying i want to identify bottlenecks and clean them up, make sure things aren't flaky, that they're reliable deterministic as possible gates, consider the hat/lens of someone who is trying to optimize for all this all the things they might come up with be very comprehensive we want to address each of them systematically

also making sure we're using all of the cpus/cores on our github runners max efficiently while keeping it simple (at least, not overcomplicating it), speedy feedback for developer great DX efficient runtime reliable avoiding pitfalls with caching (caching is fine but do it right), we like fast/deterministic/reliable/bulletproof specs... high quality maintainable

---

## Inflated companion prompt (multi-expert audit spec)

You are acting as a combined principal Elixir maintainer, OSS library maintainer, GitHub Actions expert, SRE/DevOps engineer, test architect, DX-focused staff engineer, release engineer, security/supply-chain reviewer, and practical software economist.

We are auditing the CI/CD pipeline for one or more OSS Elixir libraries/apps. The goal is not "make CI look fancy." The goal is to make the pipeline fast, deterministic, trustworthy, resource-efficient, maintainable, and pleasant for contributors, while preserving or increasing the actual quality signal.

The original human prompt is high-priority taste/context. Preserve its intent:
- fast feedback for developers
- reliable deterministic gates
- no wasting maintainer time or CI runner time
- keep high-value tests
- remove or demote low-signal / redundant / flaky / poorly scoped checks
- use all available runner CPU/core resources intelligently without overcomplicating things
- do not "optimize" by hiding risk
- prefer boring, idiomatic, least-surprise CI
- optimize for OSS contributor DX and maintainer sanity

Do not give generic CI advice. Make concrete, repo-specific recommendations.

### 0. OPERATING MODE

Work as if this is a serious one-shot architecture/research pass.

Use subagents if available. If actual subagents are not available, simulate separate expert passes and clearly merge their findings.

Minimum expert passes / lenses:

1. GitHub Actions topology + critical-path analyst
2. Elixir/Mix/ExUnit performance specialist
3. Phoenix/Plug/Ecto ecosystem specialist, where applicable
4. Test quality / flakiness / determinism specialist
5. CI caching and artifact strategy specialist
6. OSS maintainer DX and contributor onboarding specialist
7. Security / supply-chain / secrets / release engineer
8. "Lessons from successful libraries" researcher
9. Simplicity reviewer whose job is to delete cleverness
10. Final integrator whose job is to make all recommendations coherent with each other

Use current, high-quality sources:
- official GitHub Actions docs
- official Elixir/Mix/ExUnit docs
- official Ecto/Phoenix/Plug docs when relevant
- setup-beam docs
- Dialyxir, Credo, Sobelow, ExCoveralls/cover tooling docs when relevant
- current workflows from respected Elixir OSS projects such as Phoenix, Ecto, Plug, Broadway, Nx, Oban, Livebook, Ash, Tesla, Finch, etc., where comparable
- lessons from other ecosystems only when the pattern transfers cleanly: Rust/cargo-nextest, Go test caching, Rails parallel tests, pytest-xdist, Node package CI, etc.

When citing examples from other projects, explain:
- what they do
- why it likely works for them
- whether it applies here
- what not to copy blindly

If you cannot inspect a file, say so and state the assumption. Do not hallucinate repo contents.

### 1. INPUTS TO READ BEFORE RECOMMENDING

Inspect all relevant repo files before making recommendations:

Core CI:
- `.github/workflows/*`
- `.github/actions/*`
- `.github/dependabot.yml`
- `.github/codeql/*`
- any reusable workflow files
- branch protection / required checks if visible
- recent workflow run history, job timings, failures, reruns, cache hit/miss logs if available

Elixir project:
- `mix.exs`
- `mix.lock`
- `.tool-versions`, `.mise.toml`, `.asdfrc`, `elixir_ls` config, Dockerfiles, devcontainer files
- `.formatter.exs`
- `.credo.exs`
- `dialyzer` config in `mix.exs`
- `config/test.exs`
- `test/test_helper.exs`
- `test/support/*`
- `Makefile`, `justfile`, `Taskfile`, `bin/*`, `scripts/*`
- umbrella `apps/*/mix.exs` if this is an umbrella
- `assets/package.json`, lockfiles, esbuild/tailwind config if Phoenix/UI/assets are involved

Project knowledge:
- `README*`
- `CONTRIBUTING*`
- `CHANGELOG*`
- release docs
- Hex package metadata
- docs generation config
- anything in `prompts/` or prompt/research subdirectories
- brandbook/design docs only if user-facing app/UI/docs presentation is relevant
- existing TODOs/issues mentioning CI, slow tests, flaky tests, release, coverage, Dialyzer, GitHub Actions

Historical data:
- recent 20–50 CI runs if accessible
- PR vs main vs release timings
- cold-cache vs warm-cache timings
- most common failure modes
- flaky reruns
- average and p95 wall-clock time
- queue time vs execution time
- per-step duration
- cache size and hit rate
- dependency install time
- compile time
- test time
- slowest tests
- DB/container startup time
- asset build time if applicable

### 2. NORTH STAR

Optimize for this hierarchy:

1. Correctness and trustworthiness of release/merge gates
2. Deterministic, non-flaky developer feedback
3. Fast PR feedback on the most likely regressions
4. Efficient use of GitHub-hosted runners and caches
5. Maintainability and simplicity of workflow YAML
6. Contributor friendliness
7. Security and OSS supply-chain posture
8. Nice presentation/logging/reporting

Do not recommend changes that make CI faster but less trustworthy unless explicitly labeled as a tradeoff and moved to an optional tier.

Do not recommend "just retry flaky tests" as a fix. Retries may be a temporary quarantine tool, not the root solution.

Do not recommend deleting slow tests solely because they are slow. First classify whether they are high-value, redundant, flaky, over-scoped, mis-layered, or just expensive but necessary.

Do not create a Rube Goldberg CI system. Prefer simple, legible workflows with comments explaining non-obvious choices.

### 3. BASELINE FIRST: MEASURE BEFORE OPTIMIZING

Before recommendations, create a current-state baseline.

Produce a table:

- workflow name
- trigger
- job name
- runner
- matrix dimensions
- services/containers
- command(s)
- average duration
- p95 duration if available
- failure/rerun rate if available
- cache usage
- whether it is required for merge
- quality signal
- likely bottleneck
- notes

Compute or infer the critical path:
- which jobs gate merge?
- which jobs run in parallel?
- which job determines wall-clock feedback?
- which steps dominate each job?
- what work is duplicated across jobs?

Distinguish:
- PR fast path
- push-to-main path
- scheduled/nightly path
- release/tag publishing path
- docs path
- security/dependency path

When data is unavailable, recommend commands or GitHub UI/API steps to obtain it.

Suggested local/CI diagnostics where applicable:

- `mix test --slowest 20`
- `mix test --profile-require`
- `MIX_ENV=test mix compile --profile time`
- `mix xref graph --label compile-connected`
- `mix xref graph --format cycles --label compile-connected`
- `mix deps.unlock --check-unused`
- `mix deps.get --check-locked`
- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `mix hex.audit`
- `mix deps.audit` if `mix_audit` is already used or clearly worth adding
- `mix dialyzer` if Dialyzer is already present or worth adding
- `mix credo --strict` only if Credo is already part of the project or clearly valuable
- `mix sobelow` only for Phoenix/web apps where it applies
- `elixir -e "IO.inspect(System.schedulers_online(), label: :schedulers_online)"`
- print cache hit/miss state in CI summaries
- collect top slow tests and top slow compile modules

### 4. TEST VALUE CLASSIFICATION

Classify tests and checks by value, not vibes.

For every major test/check category, answer:

- What bug class does this catch?
- How often does it fail usefully?
- Is it deterministic?
- Is it fast enough for PR?
- Is it redundant with another check?
- Is it testing behavior or implementation trivia?
- Is it overly broad integration coverage for a unit-level concern?
- Does it require network/time/random/global state?
- Could it be moved to nightly without meaningfully increasing merge risk?
- Could it be split/sharded/partitioned?
- Could it become async-safe?
- Could fixture/setup cost be reduced?
- Is the failure output actionable?

Use this classification:

A. Must remain in PR gate
- catches likely regressions
- fast enough or high enough signal to justify cost
- deterministic
- actionable failure output

B. Keep in PR but optimize
- valuable but slow due to setup, lack of async, bad fixture strategy, duplicated compile/deps, inefficient services

C. Move to scheduled/main/release gate
- valuable but too slow/broad for every PR
- catches lower-probability compatibility issues
- exhaustive matrix, broad adapter matrix, old-version matrix, coverage reports, security scans with network dependency, docs publishing dry runs, etc.

D. Quarantine/fix before trusting
- flaky, timing-sensitive, global state leaks, relies on external services, nondeterministic ordering

E. Delete or rewrite
- low-signal snapshots
- tests that only assert implementation detail
- duplicated test paths
- tests that never fail except during unrelated refactors
- brittle over-mocking
- coverage-only tests with no meaningful assertion

Be conservative about deletion. Recommend deletion only with evidence.

### 5. ELIXIR-SPECIFIC AUDIT POINTS

Audit these Elixir/Mix/ExUnit areas deeply.

5.1 ExUnit concurrency
- Identify which test modules can safely use `async: true`.
- Identify why non-async modules are non-async: DB sandbox, global app env, ETS named tables, registered processes, filesystem paths, ports, time, randomness, process dictionary, Mox global mode, Bypass/global HTTP server, Application env mutation, Logger capture, telemetry handlers, etc.
- Recommend converting safe modules to `async: true`.
- Do not mark tests async if they mutate global state.
- Remember tests within a module are still serialized; splitting huge modules can improve concurrency.
- Check `ExUnit.configure(max_cases: ...)` only after measuring. Do not blindly set it above runner CPU capacity.
- Compare `System.schedulers_online()` with runner CPU count and observed bottlenecks.

5.2 Test partitioning / sharding
- Consider `mix test --partitions N` and `MIX_TEST_PARTITION` when suite time is dominated by non-async modules or integration tests.
- Explain overhead: duplicated setup, duplicated compile unless cached, service contention, coverage merge complexity.
- For DB tests, ensure each partition gets isolated DB/schema/database names.
- For coverage with partitions, ensure coverage data is exported and merged correctly.
- Recommend partition count based on evidence, not "more is better."
- Avoid oversubscribing a small runner with too many partitions plus DB services.

5.3 Ecto/Phoenix/Plug specifics
Where applicable:
- Verify Ecto SQL Sandbox config is correct for concurrent transactional tests.
- Check `config/test.exs` pool sizes relative to async tests/partitions.
- Ensure tests using shared sandbox mode are not incorrectly async.
- For Phoenix channel/LiveView/endpoint tests, verify sandbox allowances and process ownership.
- For Plug/Cowboy/Bandit tests, watch port conflicts and registered process conflicts.
- For adapter integration tests, separate unit tests from DB/service/container integration tests.
- For Phoenix assets, avoid rebuilding assets unnecessarily in pure Elixir test jobs.
- Cache Node package manager data correctly if assets are tested.
- Use deterministic service readiness checks rather than sleeps.

5.4 Mocks and external services
- Prefer behaviour-based mocks/contracts such as Mox when idiomatic.
- Keep mocks private/async-safe where possible.
- Avoid global mocks for async tests.
- Replace real network calls with local fakes, Bypass, Mox behaviours, or contract tests.
- If integration with real services is essential, move to scheduled/release workflow and clearly label it.

5.5 Compile performance
- Check if compile time is a major contributor.
- Use `mix compile --profile time` and `mix xref`.
- Look for compile-connected dependency chains and macro-heavy modules that cause recompilation.
- Consider CI guardrails for compile-time cycles only if the project has a real problem and the threshold is pragmatic.
- Avoid overly strict xref gates that create churn without measurable benefit.

5.6 Dialyzer
- If Dialyzer exists, ensure PLTs are cached with keys including OS, OTP, Elixir, lockfile, and relevant Dialyzer config.
- Consider split restore/save so a failed Dialyzer run does not prevent PLT cache persistence.
- Decide whether Dialyzer belongs in PR, main, or scheduled based on runtime and value.
- Ensure output format is useful in GitHub Actions logs/annotations.
- Avoid adding Dialyzer as a mandatory PR gate to a library with poor specs unless the remediation plan is realistic.

5.7 Formatting, lockfile, dependencies
- `mix format --check-formatted` should be fast and PR-gated.
- `mix deps.get --check-locked` is valuable for reproducibility.
- `mix deps.unlock --check-unused` is useful for library hygiene.
- `mix compile --warnings-as-errors` should run where it provides signal without duplicating across every matrix entry.
- Consider `mix hex.audit` and `mix_audit`/`mix deps.audit` based on security posture and dependency profile.

### 6. GITHUB ACTIONS AUDIT POINTS

6.1 Workflow triggers
Evaluate:
- `pull_request`
- `push` to default branch
- `merge_group` if GitHub merge queue is used
- `workflow_dispatch`
- `schedule`
- tags/releases
- docs-only changes
- path filters

Watch for footguns:
- path-filtered workflows that are required checks can leave PRs blocked/pending.
- commit-message skip directives may block required checks.
- `pull_request_target` is dangerous with untrusted fork code; avoid unless necessary and hardened.
- scheduled workflows should not be the only place correctness-critical tests run.

Recommend a trigger model:
- PR: fast representative gate
- main: same or slightly broader
- nightly/scheduled: broad compatibility matrix, slow integration, security, coverage, exhaustive tests
- tags/releases: full verification before publishing

6.2 Concurrency
Use concurrency intentionally:
- cancel outdated PR runs on the same branch/PR
- avoid canceling main/release workflows that should complete
- use workflow-specific group names to avoid cross-workflow cancellation
- deployment/release jobs should serialize rather than cancel unless explicitly desired

6.3 Runner selection
Evaluate:
- explicit Ubuntu version vs `ubuntu-latest`
- public vs private runner CPU/memory differences
- whether `ubuntu-slim` is inappropriate for heavyweight CI
- larger runners only if the cost/speed tradeoff is justified
- service container overhead and disk limits
- whether macOS/Windows/ARM matrices are actually needed for this library

For standard Linux runners, detect actual CPUs in logs and tune accordingly rather than guessing.

6.4 Matrix strategy
Avoid accidental matrix explosion.

For Elixir OSS libraries, consider:
- latest supported Elixir/OTP as the primary lint/test job
- minimum supported Elixir/OTP to protect compatibility
- one or two representative intermediate versions only if needed
- broad version matrix on scheduled/main rather than every PR
- lint/static checks only on one matrix entry unless version-specific
- integration adapter matrix separated from unit test matrix
- `fail-fast: false` for compatibility matrix where full failure information is useful
- `fail-fast: true` or default for homogeneous shards where one failure is enough

For each matrix dimension, justify:
- What compatibility promise does this protect?
- Is it required on every PR?
- Does it catch real bugs historically?
- Can it be scheduled instead?

6.5 setup-beam and versions
- Prefer `erlef/setup-beam`.
- Use exact versions or a clear version policy.
- Align CI versions with `mix.exs` minimum supported Elixir version.
- Avoid unsupported OTP/Elixir combinations.
- Use `.tool-versions`/mise if the repo already standardizes on it, but ensure CI is explicit enough to be reproducible.
- Capture resolved versions in logs/job summary.

6.6 Caching
Treat caching as a correctness-sensitive optimization, not magic.

Audit current cache:
- paths cached
- key specificity
- restore key breadth
- cache hit rate
- stale cache failure modes
- cache size/eviction risk
- whether dependencies/build outputs are safe to reuse across matrix entries
- whether cache misses still run install/compile steps correctly

Good cache-key dimensions often include:
- runner OS
- architecture if relevant
- OTP version
- Elixir version
- MIX_ENV
- lockfile hash
- cache version/buster
- relevant tool config hash for Dialyzer/PLT/assets if needed

Be careful with broad restore keys:
- do not restore `_build` across incompatible OTP/Elixir/MIX_ENV combinations
- do not skip `mix deps.get` merely because a partial cache restored
- do not cache generated artifacts that can mask warnings or stale compilation issues
- separate dependency cache from PLT cache when appropriate
- use restore/save split for PLTs if failure prevents cache save
- document how to bust cache

Decide whether to cache:
- `deps`
- `_build`
- Dialyzer PLTs
- `~/.cache/rebar3` if relevant
- package manager cache for assets
- downloaded tools
- not build artifacts that are cheaper/safer to recreate

6.7 Artifacts
Use artifacts when they improve DX or enable downstream jobs:
- JUnit/XML test reports if available
- coverage reports
- logs for flaky failures
- compiled docs preview only if useful
- release tarballs/packages only from trusted workflows

Avoid artifacts that slow CI without clear value.

6.8 Required checks
Recommend a clean required-check strategy:
- stable names
- avoid requiring every matrix child unless intentional
- consider a final summary/required job that depends on matrix jobs
- ensure skipped jobs report success if required
- avoid branch/path filter pending check traps
- document required checks in CONTRIBUTING

### 7. SECURITY / SUPPLY CHAIN / RELEASE AUDIT

Review:
- top-level `permissions`
- per-job permissions
- use of `GITHUB_TOKEN`
- third-party actions
- action pinning policy
- Dependabot/Renovate for actions and dependencies
- secrets exposure to forks
- `pull_request_target`
- shell injection from untrusted PR metadata
- release/tag workflows
- Hex publishing
- docs publishing
- package provenance/signing if applicable
- OIDC vs long-lived cloud credentials if deployments exist

Recommend:
- `permissions: contents: read` by default
- write permissions only in jobs that need them
- pin third-party actions to immutable SHAs for higher-security OSS posture, or explicitly justify tag pinning with Dependabot automation
- avoid long-lived cloud credentials where OIDC is practical
- release/publish only on trusted refs/tags after tests pass
- dry-run package publishing where useful
- do not run untrusted fork code with secrets
- do not use random third-party actions for trivial shell commands

For Hex package release:
- verify package metadata
- verify docs build
- verify changelog/version/tag semantics
- verify `mix hex.publish --dry-run` if appropriate
- use scoped API keys/secrets
- ensure release job depends on full verification

### 8. DX / MAINTAINER EXPERIENCE

A good CI pipeline should make failure obvious and local reproduction easy.

Audit:
- Is there a single local command equivalent to CI, e.g. `mix ci`, `make ci`, or `just ci`?
- Are CI commands documented in CONTRIBUTING?
- Are failure logs readable?
- Are long logs grouped?
- Are warnings surfaced as GitHub annotations where reasonable?
- Are slowest tests reported?
- Are flaky tests labeled with reproduction seed?
- Are service/container failures distinguishable from test failures?
- Are caches observable?
- Are matrix failures named clearly?
- Does the README badge reflect meaningful required checks?
- Can a new contributor run the same checks locally without guessing?

Recommend:
- a `mix ci` alias or documented command set:
  - deps check
  - format
  - compile warnings-as-errors
  - unused deps
  - tests
  - optional lint/dialyzer/security checks
- job summaries with:
  - versions
  - cache hits
  - test timing summary
  - slowest tests
  - coverage link if generated
- clearer job names:
  - `test / elixir 1.19 / otp 28`
  - `lint / latest`
  - `integration / postgres`
  - `compat / min-supported`
- minimal but useful comments in YAML explaining non-obvious decisions

Do not optimize only for CI maintainers. Optimize for external OSS contributors who hit a red check and need to understand what to do.

### 9. LESSONS FROM OTHER LIBS / ECOSYSTEMS

Research comparable successful projects and summarize transferable lessons.

For Elixir, inspect respected libraries/apps:
- Phoenix
- Ecto
- Plug
- Broadway
- Livebook
- Nx/Axon
- Finch/Tesla/Req
- Oban if accessible
- Ash ecosystem if applicable
- other libraries in the same domain as this project

Look for:
- matrix shape
- min/latest version policy
- where lint runs
- cache strategy
- test partitioning
- integration test isolation
- release workflow
- action pinning
- docs publishing
- coverage policy
- security checks
- contributor docs

For other ecosystems, only transfer patterns with clear applicability:
- Rust: `cargo nextest`, deterministic test sharding, lockfile/toolchain pinning
- Go: built-in test caching and small fast package-level tests
- Rails: DB test parallelization and schema-per-worker tradeoffs
- pytest: xdist, flaky test quarantine, JUnit reporting
- Node: package-manager cache vs `node_modules` cache tradeoffs
- Java: test reports and expensive integration tests separated from unit tests

For each lesson:
- what they do right
- what footguns they avoid
- what does not apply here
- how this repo should adapt it

### 10. RECOMMENDATION FORMAT

Produce the final answer in this structure:

1. Executive summary — top 5 recommended changes; expected impact; risk level; first PR to make
2. Current pipeline map — workflows/jobs/triggers/matrix/required checks/services/cache
3. Baseline metrics — table of durations and bottlenecks; critical path; cold vs warm cache notes; flaky/failure history if available
4. Findings by category — correctness; performance; determinism/flakiness; caching; matrix/version policy; test suite quality; security; release; DX/docs
5. Prioritized recommendations — for each: Title, Priority (P0/P1/P2/P3), Category, Current issue, Proposed change, Why idiomatic, Pros, Cons/tradeoffs, Expected speed/reliability impact, Risk, How to implement, How to verify, Rollback plan
6. Proposed target pipeline — PR / main / scheduled-nightly / release-tag / optional docs / optional security workflows
7. Concrete patches — minimal coherent YAML/Mix/config patches; prefer stepwise PRs (observability → cache/version → concurrency/partitioning → matrix/trigger → release/security)
8. Test cleanup plan — keep / optimize / fix-quarantine / delete-rewrite / move-to-nightly
9. Validation plan — before/after CI wall-clock; p95 PR runtime; cache hit rate; failure/rerun rate; top slow tests; compile time; mean time to actionable failure; contributor reproduction instructions
10. Final recommended `mix ci` / local dev command
11. Open questions / assumptions — only those that genuinely affect decisions

### 11. PRIORITIZATION RUBRIC

Score each recommendation 1–5 on: Runtime impact, Reliability/determinism impact, Quality-signal impact, Maintainer complexity, Security impact, Contributor DX impact, Reversibility.

Prefer recommendations with: high runtime/reliability/DX impact; low complexity; easy rollback; strong idiomatic fit.

Be skeptical of recommendations with: high cleverness; small speedup; hard-to-debug behavior; hidden correctness risk; fragile cache assumptions; hard contributor reproduction.

### 12. SPECIFIC DARK CORNERS TO CHECK

- required checks stuck pending because workflow is skipped by path/branch/commit-message filtering
- matrix explosion from OS × OTP × Elixir × DB adapter × partition
- lint running redundantly across every matrix entry
- `ubuntu-latest` moving under the project unexpectedly
- using `ubuntu-slim` for heavyweight builds
- restoring `_build` across incompatible OTP/Elixir/MIX_ENV
- broad restore keys causing stale compiled dependencies
- skipping `mix deps.get` after partial cache restore
- Dialyzer PLT cache not saved when Dialyzer fails
- PLT key missing OTP/Elixir/mix.lock dimensions
- tests marked async while mutating Application env/global state
- Mox global mode preventing async
- DB sandbox ownership issues across processes
- test partitions sharing the same DB
- fixed ports in async tests
- `Process.sleep` as readiness or race-condition masking
- real network calls in PR tests
- random data without reproducible seed
- huge test modules limiting ExUnit concurrency
- coverage slowing every PR without meaningful gate value
- doctests that compile too much or depend on unstable docs
- integration containers dominating PR runtime
- dependency/security scans that hit network and flake
- action versions not maintained
- overprivileged `GITHUB_TOKEN`
- secrets exposed to untrusted PR contexts
- release workflows not depending on CI
- package publishing without dry-run/metadata/docs checks
- branch protection requiring unstable matrix job names
- local commands diverging from CI
- opaque logs with no actionable failure guidance

### 13. IDEAL SHAPE TO CONSIDER, NOT BLINDLY COPY

A good final state for a typical OSS Elixir library often looks like this, but adapt to the repo:

PR workflow: checkout; setup exact Elixir/OTP via setup-beam; restore deps/_build cache with precise key; `mix deps.get --check-locked`; fast lint/static checks on latest version only (format, unused deps, compile warnings-as-errors); tests on latest supported pair; tests on minimum supported pair if compatibility promise matters; optional partitions only if test suite is actually long enough; no broad integration matrix unless necessary.

Main workflow: same as PR; maybe broader compatibility matrix; upload coverage or docs artifact if useful.

Nightly/scheduled: full OTP/Elixir compatibility matrix; slow integration/service adapter tests; security/dependency audit; Dialyzer if too slow for PR; exhaustive property/long-running tests; coverage report if not PR-gated.

Release/tag workflow: depends on full verification; docs build; package dry-run; publish to Hex only from trusted tag/ref; minimal required permissions; secrets only in publish job.

Docs/UI workflow: only if relevant; never block code PRs unless docs are part of the quality contract; keep statuses understandable.

### 14. OUTPUT TONE

Be opinionated but evidence-based. Be direct ("Do this." / "Do not do this." / "This is not worth it." / "This is worth it despite cost because..."). Surface tradeoffs honestly. Avoid generic advice like "use caching" without exact keys/paths and failure modes. Avoid vague "consider optimizing tests." Name concrete test categories, files, or patterns. Make the final recommendations cohesive — one integrated CI/CD design, not a pile of unrelated tips.

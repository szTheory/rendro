# Requirements: Rendro — Milestone C1 (CI/CD Performance & Reliability)

**Defined:** 2026-06-14
**Core Value:** A fast, deterministic, trustworthy, resource-efficient CI/CD pipeline with great contributor DX — keep the high-value quality signal, drop low-signal/flaky checks, fix caching and parallelism, all measured before/after.

> Non-version infra milestone (like B1). Touches `.github/`, `mix.exs` aliases, tests, and contributor docs only — **no library/`lib/` behavior changes, no Hex release.** Derived from `milestones/C1-AUDIT-BRIEF.md`; section refs below point into that brief. "User" = maintainer / OSS contributor.

## v1 Requirements

### Baseline & Observability (BASE) — brief §1, §3, §4, §9, §10, §11

- [x] **BASE-01**: Maintainer can read a current-state baseline table covering every workflow/job (trigger, runner, command, avg/p95 duration, required-for-merge, cache usage, likely bottleneck).
- [x] **BASE-02**: The critical path is documented for PR / push-to-main / release paths (which jobs gate merge, which run in parallel, which determines wall-clock, what work is duplicated across jobs).
- [x] **BASE-03**: Every test/check category is classified A–E (keep-in-PR / keep-but-optimize / move-to-scheduled / quarantine-fix / delete-rewrite) with evidence per category.
- [x] **BASE-04**: A prioritized P0–P3 recommendation report exists — each item with issue, proposed change, expected impact, risk, and rollback — informed by comparable Elixir OSS pipelines, and drives phases 109–113.
- [x] **BASE-05**: CI job summaries surface resolved OTP/Elixir versions, `System.schedulers_online()`, cache hit/miss state, and slowest tests (observability instrumentation, no behavior change).

### Caching (CACHE) — brief §6.5, §6.6, §12

- [x] **CACHE-01**: Hex deps are cached on a precise key (OS + OTP + Elixir + MIX_ENV + `mix.lock` hash + cache-buster); `mix deps.get` still runs on cache miss.
- [x] **CACHE-02**: `_build` is cached with the same precise key and is never restored across incompatible OTP / Elixir / MIX_ENV combinations.
- [x] **CACHE-03**: Dialyzer PLTs are cached with OTP/Elixir/lockfile-scoped keys using a restore/save split, so a failing Dialyzer run still persists the PLT.
- [x] **CACHE-04**: `erlef/setup-beam` is SHA-pinned and consistent across all jobs; the cache-bust procedure is documented.
- [x] **CACHE-05**: Cache hit/miss is observable in CI and verified not to mask compiler warnings or stale compilation.

### Test Concurrency, Determinism & Cleanup (TEST) — brief §4, §5, §12

- [x] **TEST-01**: Every safely-isolatable test module runs `async: true`; each module kept non-async carries a documented reason (global app env, named ETS, registered process, ports, time, randomness, etc.).
- [ ] **TEST-02**: A measured decision on `mix test --partitions N` is made and applied only where evidence shows net benefit (no oversubscription, isolation preserved).
- [ ] **TEST-03**: Flaky / nondeterministic tests (Process.sleep readiness, unseeded randomness, order dependence, real network) are fixed or explicitly quarantined with tracked remediation — not papered over with blind retries.
- [ ] **TEST-04**: Low-signal tests (implementation-trivia, duplicated paths, assertion-free coverage filler) are removed or rewritten *with evidence*; high-value tests are retained.
- [ ] **TEST-05**: Slowest tests are reported, and the live-proof / advisory suites are correctly layered (PR fast path vs scheduled) without losing real coverage.

### Workflow Topology, Triggers & Matrix (FLOW) — brief §1, §6.1–§6.4, §6.7, §6.8

- [ ] **FLOW-01**: The critical path is minimized — duplicated `deps.get`/compile across jobs reduced and the advisory + live-proof jobs rationalized (kept / merged / re-tiered) without weakening any gate.
- [ ] **FLOW-02**: Concurrency cancels superseded PR runs (per-PR group) while never canceling in-flight main or release runs.
- [ ] **FLOW-03**: Triggers follow a clear model: PR fast gate, push-to-main, scheduled/nightly (broad matrix + slow integration), release/tag full verification.
- [ ] **FLOW-04**: A version matrix policy (latest + minimum-supported Elixir/OTP) protects compatibility, with the broad matrix on scheduled not every PR, and lint/static checks running once rather than per matrix entry.
- [ ] **FLOW-05**: A stable required-check summary job gates merge so branch protection references one stable name; no path/branch/skip-directive pending-check traps.

### Security, Supply-chain & Release (SEC) — brief §7, §12

- [ ] **SEC-01**: All third-party actions are pinned to immutable SHAs, with Dependabot configured to update actions and deps.
- [ ] **SEC-02**: `permissions` is least-privilege (read by default, write only where needed); no secrets are exposed to untrusted fork contexts.
- [ ] **SEC-03**: The release/tag workflow depends on full verification and publishes to Hex only from trusted tags, with `mix hex.publish --dry-run` + metadata/docs checks (building on the existing `mix release.preflight`).
- [ ] **SEC-04**: A dependency/security audit (`mix hex.audit` / `mix deps.audit`) runs in an appropriate lane without coupling the PR fast path to flaky network calls.

### DX & Local Reproducibility (DX) — brief §8, §6.7

- [ ] **DX-01**: `mix ci` reproduces the CI merge gate locally with 1:1 parity; any divergence is eliminated or explicitly documented.
- [ ] **DX-02**: CONTRIBUTING documents the required checks, how to run them locally, and how to reproduce a flaky failure (seed).
- [ ] **DX-03**: CI failures are actionable — grouped logs, GitHub annotations for warnings, clear job names, and service/container failures distinguishable from test failures (test reports/artifacts where they add value).
- [ ] **DX-04**: README status badge reflects the meaningful required check(s).

### Validation (VAL) — brief §9 (validation), §10

- [ ] **VAL-01**: Before/after metrics are recorded — PR wall-clock (p50/p95), cache hit rate, failure/rerun rate, compile time, slowest tests — demonstrating improvement vs the Phase 108 baseline with no quality-signal regression.
- [ ] **VAL-02**: A final integrated target-pipeline description (PR / main / nightly / release / docs) documents the steady-state design as one coherent system.

## v2 Requirements (deferred)

- **COV-01**: Introduce coverage tooling (ExCoveralls) with a meaningful gate — only if Phase 108 evidence shows it adds signal worth the PR cost.
- **MQ-01**: Adopt GitHub merge queue (`merge_group`) — defer until contributor volume justifies it.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Cutting a new Hex release | C1 is a non-version infra milestone; no library behavior changes ship. |
| Rewriting the whole pipeline from scratch | Prefer minimal, stepwise, idiomatic changes; avoid a Rube Goldberg redesign (brief §2). |
| macOS / Windows / ARM CI matrices | Pure-Elixir library; no evidence these protect a real compatibility promise. |
| "Just retry flaky tests" as the fix | Retries are at most temporary quarantine, never the root remediation (brief §2). |
| Deleting tests solely for being slow | Slow ≠ low-value; deletion requires the A–E classification + evidence (brief §4). |
| Self-hosted / larger paid runners | Keep it simple on GitHub-hosted `ubuntu` unless a clear cost/speed case emerges. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| BASE-01 | Phase 108 | Complete |
| BASE-02 | Phase 108 | Complete |
| BASE-03 | Phase 108 | Complete |
| BASE-04 | Phase 108 | Complete |
| BASE-05 | Phase 108 | Complete |
| CACHE-01 | Phase 109 | Complete |
| CACHE-02 | Phase 109 | Complete |
| CACHE-03 | Phase 109 | Complete |
| CACHE-04 | Phase 109 | Complete |
| CACHE-05 | Phase 109 | Complete |
| TEST-01 | Phase 110 | Complete |
| TEST-02 | Phase 110 | Pending |
| TEST-03 | Phase 110 | Pending |
| TEST-04 | Phase 110 | Pending |
| TEST-05 | Phase 110 | Pending |
| FLOW-01 | Phase 111 | Pending |
| FLOW-02 | Phase 111 | Pending |
| FLOW-03 | Phase 111 | Pending |
| FLOW-04 | Phase 111 | Pending |
| FLOW-05 | Phase 111 | Pending |
| SEC-01 | Phase 112 | Pending |
| SEC-02 | Phase 112 | Pending |
| SEC-03 | Phase 112 | Pending |
| SEC-04 | Phase 112 | Pending |
| DX-01 | Phase 113 | Pending |
| DX-02 | Phase 113 | Pending |
| DX-03 | Phase 113 | Pending |
| DX-04 | Phase 113 | Pending |
| VAL-01 | Phase 113 | Pending |
| VAL-02 | Phase 113 | Pending |

**Coverage:**
- v1 requirements: 30 total
- Mapped to phases: 30
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-14*
*Last updated: 2026-06-14 after C1 milestone start*

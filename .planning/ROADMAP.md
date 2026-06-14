# ROADMAP — C1 CI/CD Performance & Reliability

> Non-version infra milestone (like B1). Pipeline / tooling / contributor-docs work only — **no library/`lib/` behavior changes, no Hex release.**
> Phases continue the repo's global sequential numbering (108–113) even though the milestone label is `C1`. (B1 ended at 107; v2.9 was phases 97–100.)
> Arc: **measure first (108, analysis-only) → implement (109–112) → validate vs baseline (113).**
> Source brief: `milestones/C1-AUDIT-BRIEF.md` (each phase cites the relevant §). "User" = maintainer / OSS contributor.

## Milestones

- 🚧 **C1 CI/CD Performance & Reliability** — Phases 108–113 (active)
- ✅ **v2.9 TOC & Document Navigation** — Phases 97–100 (shipped 2026-06-14)
- ✅ **B1 Brand System & Identity Lab** — Phases 101–107 (shipped 2026-06-14)

## Phases

- [ ] **Phase 108: Baseline & Audit Report** — Measure the current pipeline (per-job duration/critical-path table), classify every test/check A–E with evidence, emit a prioritized P0–P3 recommendation report, and add CI observability job summaries. Analysis + instrumentation only; no gate-logic or test changes.
- [ ] **Phase 109: Caching & setup-beam Foundation** — Add keyed `deps`/`_build`/PLT caching (the pipeline currently has ZERO caching), SHA-pin and unify `setup-beam`, and document cache-busting. Biggest expected runtime win.
- [ ] **Phase 110: Test Concurrency, Determinism & Cleanup** — Convert safely-isolatable modules to `async: true`, make an evidence-based partitioning decision, fix/quarantine flaky tests (no blind retries), remove low-signal tests with evidence, and layer slow suites PR-vs-scheduled correctly.
- [ ] **Phase 111: Workflow Topology, Triggers & Matrix** — Cut the critical path and duplicated work, rationalize advisory + live-proof jobs, add per-PR concurrency cancellation, define the PR/main/nightly/release trigger model + version-matrix policy, and gate merge on one stable required-check summary.
- [ ] **Phase 112: Security, Supply-chain & Release Hardening** — Pin all actions to SHAs + add Dependabot, apply least-privilege per-job permissions, and gate Hex publish on full verification from trusted tags with `hex.publish --dry-run` (building on `mix release.preflight`).
- [ ] **Phase 113: DX, Local Reproducibility & Validation** — Achieve `mix ci` local/CI parity, add CONTRIBUTING + actionable-failure ergonomics + README badge, and record final before/after metrics vs the Phase 108 baseline plus an integrated target-pipeline description. Closes the milestone.

## Phase Details

### Phase 108: Baseline & Audit Report
**Goal**: Establish the measured source-of-truth that drives every downstream phase — what the pipeline does today, how long it takes, where the bottlenecks are, which checks are worth keeping, and what to change in priority order — without touching gate logic or removing any test.
**Depends on**: Nothing (source of truth for phases 109–113)
**Requirements**: BASE-01, BASE-02, BASE-03, BASE-04, BASE-05
**Success Criteria** (what must be TRUE):
  1. A current-state baseline table covers every workflow/job across `ci.yml` / `hexdocs.yml` / `release.yml` (trigger, runner, command, avg + p95 duration, required-for-merge, cache usage, likely bottleneck) — BASE-01.
  2. The critical path is documented for PR / push-to-main / release paths, naming which jobs gate merge, which run in parallel, which sets wall-clock, and what work (e.g. repeated `mix deps.get` / compile) is duplicated across the 10 jobs — BASE-02.
  3. Every test/check category is classified A–E (keep-in-PR / keep-but-optimize / move-to-scheduled / quarantine-fix / delete-rewrite) with cited evidence per category, covering the `test` gate, the 4 advisory soft-fail jobs, and the 4 live-proof gates — BASE-03.
  4. A prioritized P0–P3 recommendation report exists where each item carries issue, proposed change, expected impact, risk, and rollback — informed by comparable Elixir OSS pipelines — and explicitly maps to phases 109–113 — BASE-04.
  5. CI job summaries surface resolved OTP/Elixir versions, `System.schedulers_online()`, cache hit/miss state, and slowest tests, with no change to behavior or gate outcomes — BASE-05.
**Artifacts**: `.github/` workflow job-summary instrumentation (observability only); a milestone baseline + A–E classification + P0–P3 audit report document
**Constraint**: This phase is measure-only. No cache keys, no `async` flips, no removed tests, no gate-logic edits land here.

### Phase 109: Caching & setup-beam Foundation
**Goal**: Eliminate the pipeline's biggest avoidable cost — zero caching anywhere — by adding correct, precisely-keyed `deps`/`_build`/PLT caching and a SHA-pinned, consistent `setup-beam`, so warm runs skip redundant dependency fetch and compile without ever masking warnings or restoring across incompatible toolchains.
**Depends on**: Phase 108 (baseline quantifies the cold-cache cost and confirms zero existing caching)
**Requirements**: CACHE-01, CACHE-02, CACHE-03, CACHE-04, CACHE-05
**Success Criteria** (what must be TRUE):
  1. Hex deps are cached on a precise key (OS + OTP + Elixir + MIX_ENV + `mix.lock` hash + cache-buster) and `mix deps.get` still runs on a cache miss — CACHE-01.
  2. `_build` is cached on the same precise key and is provably never restored across incompatible OTP / Elixir / MIX_ENV combinations — CACHE-02.
  3. Dialyzer PLTs are cached with OTP/Elixir/lockfile-scoped keys using a restore/save split, so a failing Dialyzer run still persists the PLT — CACHE-03.
  4. `erlef/setup-beam` is SHA-pinned and identical across all jobs (reconciling the existing `hexdocs.yml` SHA pin vs looser refs elsewhere), and the cache-bust procedure is documented — CACHE-04.
  5. Cache hit/miss is observable in CI (via the Phase 108 summaries) and verified not to mask compiler warnings or stale compilation — CACHE-05.
**Artifacts**: `.github/workflows/*.yml` (cache restore/save steps, unified pinned `setup-beam`); cache-bust documentation

### Phase 110: Test Concurrency, Determinism & Cleanup
**Goal**: Make the test suite faster and more trustworthy by safely raising concurrency, making an evidence-based partitioning call, rooting out nondeterminism instead of papering over it, and removing genuinely low-signal tests — while preserving every bit of real coverage.
**Depends on**: Phase 108 (consumes its A–E classification and slowest-test evidence)
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, TEST-05
**Success Criteria** (what must be TRUE):
  1. Every safely-isolatable test module runs `async: true`, and each module kept non-async (from the current 35 `async: false` of 127 test files) carries a documented reason (global app env, named ETS, registered process, ports, time, randomness, etc.) — TEST-01.
  2. A measured decision on `mix test --partitions N` is recorded and applied only where evidence shows net benefit, with no oversubscription and isolation preserved — TEST-02.
  3. Flaky / nondeterministic tests (Process.sleep readiness, unseeded randomness, order dependence, real network) are fixed or explicitly quarantined with tracked remediation — never papered over with blind retries — TEST-03.
  4. Low-signal tests (implementation-trivia, duplicated paths, assertion-free filler) are removed or rewritten with cited evidence while high-value tests are retained — TEST-04.
  5. Slowest tests are reported and the live-proof / advisory suites (tags `:live_pdf_tools` / `:live_signing` / `:raster_snapshot`, excluded by default) are correctly layered PR-fast-path vs scheduled without losing real coverage — TEST-05.
**Artifacts**: test files (`async:` conversions, flaky fixes/quarantine, deletions/rewrites); `config/test.exs` / `test/test_helper.exs` if needed; partitioning decision record

### Phase 111: Workflow Topology, Triggers & Matrix
**Goal**: Reshape the workflow graph into a coherent fast-PR / main / nightly / release model — minimizing the critical path and duplicated setup, rationalizing the advisory and live-proof jobs, cancelling superseded PR runs, defining a version-matrix policy, and exposing one stable required-check name to branch protection — without weakening any gate.
**Depends on**: Phase 108 (critical-path + topology evidence), Phase 109 (caching makes split/merge job decisions safe)
**Requirements**: FLOW-01, FLOW-02, FLOW-03, FLOW-04, FLOW-05
**Success Criteria** (what must be TRUE):
  1. The critical path is minimized — duplicated `deps.get`/compile across jobs is reduced and the 4 advisory soft-fail jobs (raster/comparison/livebook/pdfjs) + 4 live-proof gates (viewer-evidence/signing/long-lived/release-proof) are rationalized (kept / merged / re-tiered) without weakening any gate — FLOW-01.
  2. Concurrency cancels superseded PR runs via a per-PR group while never cancelling in-flight main or release runs — FLOW-02.
  3. Triggers follow a clear model: PR fast gate, push-to-main, scheduled/nightly (broad matrix + slow integration), and release/tag full verification — FLOW-03.
  4. A version-matrix policy (latest + minimum-supported Elixir/OTP, currently a single OTP 28 / Elixir 1.19.5 target) protects compatibility, with the broad matrix on scheduled (not every PR) and lint/static checks running once rather than per matrix entry — FLOW-04.
  5. A stable required-check summary job gates merge so branch protection references one stable name, with no path/branch/skip-directive pending-check traps — FLOW-05.
**Artifacts**: `.github/workflows/*.yml` (restructured jobs, `concurrency:`, triggers, matrix, summary gate job); branch-protection / required-check notes

### Phase 112: Security, Supply-chain & Release Hardening
**Goal**: Raise the supply-chain and release posture to a high-trust OSS baseline — immutable action pins with automated updates, least-privilege per-job permissions, and a release path that only publishes to Hex from trusted tags after full verification — building on the existing top-level `permissions: contents: read` default and `mix release.preflight`.
**Depends on**: Phase 111 (release gate hangs off the rationalized verification topology and summary gate)
**Requirements**: SEC-01, SEC-02, SEC-03, SEC-04
**Success Criteria** (what must be TRUE):
  1. All third-party actions are pinned to immutable SHAs, with Dependabot configured to update both actions and deps — SEC-01.
  2. `permissions` is least-privilege (read by default, write only where a job needs it) and no secrets are exposed to untrusted fork contexts — SEC-02.
  3. The release/tag workflow depends on full verification and publishes to Hex only from trusted tags, running `mix hex.publish --dry-run` + metadata/docs checks on top of the existing `mix release.preflight` (which already does `hex.build --unpack` + `hex.publish --dry-run` + audits) — SEC-03.
  4. A dependency/security audit (`mix hex.audit` / `mix deps.audit`) runs in an appropriate lane without coupling the PR fast path to flaky network calls — SEC-04.
**Artifacts**: `.github/dependabot.yml`; `.github/workflows/*.yml` (SHA pins, per-job `permissions`, hardened `release.yml`, audit lane placement)

### Phase 113: DX, Local Reproducibility & Validation
**Goal**: Close the milestone by making the pipeline pleasant and reproducible for contributors — `mix ci` matches the merge gate 1:1, failures are actionable, CONTRIBUTING + the README badge are accurate — and by proving the whole effort worked: record before/after metrics vs the Phase 108 baseline and document the steady-state target pipeline as one coherent system.
**Depends on**: Phase 109, Phase 110, Phase 111, Phase 112 (validates the integrated result of all implementation phases)
**Requirements**: DX-01, DX-02, DX-03, DX-04, VAL-01, VAL-02
**Success Criteria** (what must be TRUE):
  1. `mix ci` reproduces the CI merge gate locally with 1:1 parity (vs the current `format --check-formatted` / `hex.build` / `compile --warnings-as-errors` / `test` / `docs --warnings-as-errors` / `credo --strict` / `dialyzer` alias), with any divergence eliminated or explicitly documented — DX-01.
  2. CONTRIBUTING documents the required checks, how to run them locally, and how to reproduce a flaky failure (seed); the README status badge reflects the meaningful required check(s) — DX-02, DX-04.
  3. CI failures are actionable — grouped logs, GitHub annotations for warnings, clear job names, and service/container failures distinguishable from test failures (with test reports/artifacts where they add value) — DX-03.
  4. Before/after metrics are recorded — PR wall-clock (p50/p95), cache hit rate, failure/rerun rate, compile time, slowest tests — demonstrating improvement vs the Phase 108 baseline with no quality-signal regression — VAL-01.
  5. A final integrated target-pipeline description (PR / main / nightly / release / docs) documents the steady-state design as one coherent system — VAL-02.
**Artifacts**: `mix.exs` (`ci` alias parity); `CONTRIBUTING.md`; `README.md` (badge); `.github/workflows/*.yml` (annotations/log grouping/job names); before/after validation report + target-pipeline description

## Progress

| Phase | Requirements Complete | Status | Completed |
|-------|-----------------------|--------|-----------|
| 108. Baseline & Audit Report | 0/5 | Not started | - |
| 109. Caching & setup-beam Foundation | 0/5 | Not started | - |
| 110. Test Concurrency, Determinism & Cleanup | 0/5 | Not started | - |
| 111. Workflow Topology, Triggers & Matrix | 0/5 | Not started | - |
| 112. Security, Supply-chain & Release Hardening | 0/4 | Not started | - |
| 113. DX, Local Reproducibility & Validation | 0/6 | Not started | - |

**Coverage:** 30/30 C1 requirements mapped across phases 108–113 — no orphans, no duplicates.

## Completed Milestones

<details>
<summary>✅ v2.9 TOC & Document Navigation (Phases 97–100) — SHIPPED 2026-06-14</summary>

- [x] **Phase 97: Location Tracking & Primitives** - Establish exact X/Y physical locations and bounds as a foundational engine primitive. (completed 2026-06-13)
- [x] **Phase 98: Document Outlines (Bookmarks)** - Introduce native, declarative doubly-linked PDF outline serialization. (completed 2026-06-14)
- [x] **Phase 99: Cross-References & Validation** - Add validated internal document links that point to explicit physical destinations. (completed 2026-06-14)
- [x] **Phase 100: Printable Table of Contents Primitive** - Provide safe post-layout substitution tokens for visual Tables of Contents. (completed 2026-06-14)

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 97. Location Tracking & Primitives | v2.9 | 2/2 | Complete | 2026-06-13 |
| 98. Document Outlines (Bookmarks) | v2.9 | 3/3 | Complete | 2026-06-14 |
| 99. Cross-References & Validation | v2.9 | 2/2 | Complete | 2026-06-14 |
| 100. Printable Table of Contents Primitive | v2.9 | 2/2 | Complete | 2026-06-14 |

</details>

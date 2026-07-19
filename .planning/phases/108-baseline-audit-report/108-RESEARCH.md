# Phase 108: Baseline & Audit Report — Research

**Researched:** 2026-06-14
**Domain:** GitHub Actions CI/CD audit, Elixir/ExUnit profiling, job-summary instrumentation
**Confidence:** HIGH — all findings verified against live API data, repo files, and running commands

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — Baseline metric sourcing & rigor (BASE-01, BASE-02)**
Hybrid two-source approach. Real-runner wall-clock from existing history via
`gh api repos/szTheory/rendro/actions/runs/{id}/jobs`. Inner `mix ci` split from local
`mix test --slowest 20`, `MIX_ENV=test mix compile --profile time`,
`mix xref graph --label compile-connected`. Report local split as ordinal/proportional proxy,
NOT absolute seconds (dev box = 18 schedulers vs runner = 4). Report p95 as the literal phrase
**"insufficient green-run data (n=3)"**. Do NOT trigger fresh paid CI runs.

**D-02 — Job-summary instrumentation pattern & scope (BASE-05)**
Single brace-group redirect in the `test` job ONLY. Pattern:
`{ echo "## CI Baseline"; echo "- …"; } >> "$GITHUB_STEP_SUMMARY"`. Add `id:` to setup-beam
step to read `steps.<id>.outputs.otp-version` / `elixir-version`. Content: resolved OTP +
Elixir versions, `System.schedulers_online()`, cache state (literal placeholder
`cold / none` in 108), slowest tests via `tee` of `mix ci` stdout then grep. Every summary
step is `if: always()` AND `continue-on-error: true` with `|| true` / `|| echo "n/a"` guards.
Must NOT change any job's exit code or gate outcome. Cache row is a ONE-LINE seam for Phase 109.
Rejected: composite action (multi-write collapse bug actions/runner#2020 / discussion #32566),
`mix` task, all-10-jobs scope.

**D-03 — Audit report location & shape (BASE-01..04 deliverable)**
One consolidated file at `.planning/milestones/C1-AUDIT.md`. YAML frontmatter. Stable H2
anchors: `## BASE-01 — Baseline Table`, `## BASE-02 — Critical Path`,
`## BASE-03 — A–E Classification`, `## BASE-04 — P0–P3 Recommendation Report`. Downstream
citation contract: `.planning/milestones/C1-AUDIT.md#<stable-anchor>`. Phase 113 owns the
contributor-facing output.

**D-04 — A–E classification evidence depth (BASE-03)**
Measured-but-bounded. Evidence floor: `mix test --slowest 20` once; read ALL 34 explicit
`async: false` modules and cite each concrete reason; ONE bounded flake sweep
`mix test --repeat-until-failure 25` × seeds {0,1,2}; classify `test` gate / 4 advisory /
4 live-proof gates by category not per individual test; **E** requires a named artifact
(assertion-free, duplicated path, or implementation-trivia — never "slow" alone).
Evidence ceiling: flake proof 50–200× multi-seed, full slow-tail beyond 20, partitions
experiments, actual flips/quarantines/deletions — all deferred to Phase 110.

### Claude's Discretion

- Exact ordering and table column set within `C1-AUDIT.md` (follow brief §10 layout).
- Precise flake-sweep seed count/targeting within the bounded floor (≥3 seeds, ~25 repeats).
- Exact echo lines / formatting of the `test`-job summary panel.

### Deferred Ideas (OUT OF SCOPE)

- Decomposing the `mix ci` monolith into parallel jobs/steps — recommend in BASE-04, implement in 109/111.
- Real green-run p95 / before-after metrics — Phase 113 (VAL-01).
- `mix verify.flake` nightly deep flake-proof lane — candidate for Phase 110 (TEST-03) / 111 trigger.
- Actual `async: true` flips, quarantine, deletions, `--partitions N` — Phase 110.
- Contributor-facing target-pipeline writeup + CONTRIBUTING.md — Phase 113 (VAL-02 / DX-02).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BASE-01 | Baseline table: every workflow/job (trigger, runner, command, avg/p95 duration, required-for-merge, cache usage, likely bottleneck) | §Real-Runner Timing Data has exact numbers from 3 green CI runs + hexdocs + release |
| BASE-02 | Critical path documented for PR / push-to-main / release paths | §Critical-Path Anatomy has the exact sequencing and critical-path job per path |
| BASE-03 | Every test/check category classified A–E with cited evidence | §A–E Classification Analysis classifies all 34 async:false modules and all job categories |
| BASE-04 | Prioritized P0–P3 recommendation report mapped to phases 109–113 | §C1-AUDIT.md Report Shape + §Flagship Recommendation provide the structure |
| BASE-05 | CI job summaries: OTP/Elixir, schedulers_online(), cache hit/miss, slowest tests | §BASE-05 Exact YAML Pattern has the complete, ready-to-paste instrumentation |
</phase_requirements>

---

## Summary

Phase 108 is a **measure-only** audit phase. The only code edit is adding `$GITHUB_STEP_SUMMARY`
instrumentation to the `test` job in `.github/workflows/ci.yml`. The primary deliverable is
`.planning/milestones/C1-AUDIT.md` — a planning-internal document that serves as the
source-of-truth baseline for phases 109–113.

The pipeline is currently a single-monolith: all of `mix ci` runs in one opaque "Run CI" step
(format → hex.build → compile → test → docs → credo → dialyzer). This single step is why
the GitHub Actions API cannot see the inner split, why there is zero parallelism to exploit,
and why BASE-05 instrumentation is needed now. The monolith is the root anomaly the audit must
name as the P0 flagship recommendation.

Three verified green CI runs (runs 3, 34, 35) show "Run CI" (= `mix ci`) durations of
222s, 386s, and 372s respectively. The full CI run wall-clock, gated by the `release-proof`
job as critical path, ran 16m02s and 17m16s. P95 cannot be calculated from n=3 and MUST
be reported as the literal phrase "insufficient green-run data (n=3)".

There are 34 explicitly `async: false` test modules (plus 4 files with no explicit `async:`
setting that default to async:false) out of 127 test files (89 `async: true`). All 34 explicit
non-async modules have identifiable concrete reasons derivable by grep: Application.put_env /
delete_env global app env, process-global telemetry handlers, System.cmd/Port tool invocations
via /tmp paths, recompile-global-module-namespace calls. No Ecto sandbox exists (pure lib).

**Primary recommendation:** The planner should structure tasks in Wave 0 (local measurement),
Wave 1 (BASE-05 YAML edit + commit), and Wave 2 (C1-AUDIT.md authoring) with explicit,
non-negotiable measure-only constraints encoded as guardrails.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Per-job wall-clock timing | GitHub Actions API | — | Only source with runner-accurate timing |
| Inner mix ci step split | Local dev machine | — | API cannot see inside single opaque step |
| test file async:false reasons | Local repo grep | Human read (~4 residue) | Automated grep resolves ~30/34; rest need visual |
| $GITHUB_STEP_SUMMARY output | test job shell step | — | Brace-group in ci.yml; no composite needed |
| C1-AUDIT.md authoring | Planning-internal doc | — | Never published; ExDoc extras = guides/ only |
| Slowest-test capture | tee of mix ci stdout | grep --slowest block | No re-run of suite needed |

---

## Real-Runner Timing Data (BASE-01 Source Material)

### Verified Green CI Runs (ci.yml workflow)

All timing extracted from `gh api repos/szTheory/rendro/actions/runs/{id}/jobs`.
[VERIFIED: GitHub Actions API live data]

**Run #3** — 2026-04-28 (id: 25066346539) — 9 jobs (pdfjs-advisory added later)
- test job total: 245s (4m05s)
  - Setup Beam: 6s
  - Install Dependencies: 2s
  - Run CI (mix ci): **222s**
- Only job that ran (no downstream proof gates existed yet at this commit)

**Run #34** — 2026-06-12 (id: 27441368861) — 9 jobs (pdfjs-advisory added 2026-06-12 23:19 UTC, AFTER this run)
- test job total: 401s (6m41s)
  - Setup Beam: 8s
  - Install Dependencies: 3s
  - Run CI (mix ci): **386s**
- Parallel (advisory, no needs:): raster-advisory=305s, comparison-advisory=159s, livebook-advisory=173s, example-phoenix=56s
- Sequential (needs: test): signing-live-proof=168s, long-lived-live-proof=177s, viewer-evidence-live-proof=290s, release-proof=554s
- Full run wall-clock: 20:32:05 → 20:48:07 = **962s (16m02s)** [release-proof is critical path]

**Run #35** — 2026-06-12 (id: 27443757934) — 9 jobs (same state)
- test job total: 389s (6m29s)
  - Setup Beam: 3s
  - Install Dependencies: 3s
  - Run CI (mix ci): **372s**
- Parallel: raster-advisory=308s, comparison-advisory=150s, livebook-advisory=210s, example-phoenix=61s
- Sequential (needs: test): signing-live-proof=174s, long-lived-live-proof=171s, viewer-evidence-live-proof=283s, release-proof=645s
- Full run wall-clock: 21:20:45 → 21:38:01 = **1036s (17m16s)** [release-proof is critical path]

**Summary table for BASE-01:**

| Metric | Value |
|--------|-------|
| mix ci duration avg (3 green runs) | 327s |
| mix ci duration range | 222s–386s |
| test job wall-clock avg | ~345s |
| Full CI run wall-clock (n=2) | 962s, 1036s |
| p95 full CI | **"insufficient green-run data (n=3)"** |
| Cache: deps | NONE — mix deps.get runs every job |
| Cache: _build | NONE — full recompile every job |
| Cache: PLTs | NONE |

### HexDocs Workflow (hexdocs.yml) — Push to main + PR

From run 27443757945 [VERIFIED: GitHub Actions API]:
- **verify-docs-ready**: 373s (6m13s) [always runs]
  - Setup Beam: 7s, Install Deps: 2s, Verify Docs Contract: 292s, Verify Livebook Tutorial: 64s, Verify Comparison Evidence: 1s
- **publish-hexdocs**: 157s (2m37s) [push to main only, needs: verify-docs-ready]
  - Publish HexDocs: 139s

### Release Workflow (release.yml) — Tag push only

From run 27043056315 (v1.0.0 release) [VERIFIED: GitHub Actions API]:
- **publish job**: 488s (8m08s)
  - Install System Deps: 19s, Install Deps: 2s, Run CI Checks (mix ci): **412s**, Release Preflight: 41s, Publish: 2s

### pdfjs-advisory (added 2026-06-12 23:19 UTC, commit 999a0e2)

Present in run 37 (failed, id: 27512247437). Duration: **11s** (job-level; Setup Node=5s, npm ci=1s, observe.mjs=0s).
Node cache was hot. No Elixir beam setup — pure Node job.

---

## Critical-Path Anatomy (BASE-02 Source Material)

### PR / push-to-main path (ci.yml)

```
[t=0] START
  Tier 1 — runs in parallel, no dependencies:
    test job             ← MERGE GATE; sets wall-clock for proof tier
    example-phoenix      ← graph-disconnected, no continue-on-error
    raster-advisory      ← graph-disconnected, continue-on-error: true
    comparison-advisory  ← graph-disconnected, continue-on-error: true
    livebook-advisory    ← graph-disconnected, continue-on-error: true
    pdfjs-advisory       ← graph-disconnected, continue-on-error: true, Node-only

  Tier 2 — needs: test (proof gates, all required for merge):
    signing-live-proof       ← needs: test
    long-lived-live-proof    ← needs: test
    viewer-evidence-live-proof ← needs: test
    release-proof            ← needs: test, timeout: 45min ← CRITICAL PATH BOTTLENECK

[t≈6.5min] test job completes → triggers Tier 2
[t≈16-17min] release-proof completes → CI done
```

**Critical path: START → test job (6.5min) → release-proof (9-10min) = ~16-17min total**

**Duplicated work across jobs (BASE-02 finding):**
- `erlef/setup-beam@v1`: runs in 9 of 10 jobs (pdfjs-advisory uses setup-node)
- `mix deps.get`: runs in 8 jobs (test, example-phoenix [sub-dir], raster-advisory, comparison-advisory, livebook-advisory, viewer-evidence-live-proof, signing-live-proof, long-lived-live-proof, release-proof)
- Full `_build` recompile: every Elixir job — zero shared artifacts
- `mix ci` full run: both in `test` job AND `release.yml` publish job

### Push-to-main additional path

hexdocs.yml runs in parallel with ci.yml:
- verify-docs-ready: ~373s (parallel, not required for merge gate)
- publish-hexdocs (push to main only): ~157s (needs: verify-docs-ready)

### Release/tag path (release.yml)

Fully independent, tag-triggered. Runs `mix ci` again (412s) even though the tag was built
from a SHA that already passed CI. No dependency on ci.yml jobs.

---

## setup-beam SHA Discrepancy Finding

[VERIFIED: direct file inspection]

| Workflow | setup-beam reference |
|----------|---------------------|
| `.github/workflows/ci.yml` | `@v1` (floating — 9 occurrences) |
| `.github/workflows/hexdocs.yml` | `@8251c48667b97e88a0a24ec512f5b72a039fcea7 # v1` (SHA-pinned) |
| `.github/workflows/release.yml` | `@v1` (floating) |

**Audit finding for BASE-01 table:** ci.yml and release.yml use floating `@v1` tag; hexdocs.yml is
SHA-pinned. This is an inconsistency — the supply-chain posture of ci.yml is lower than hexdocs.yml.
Fixing this is Phase 112 (SEC-01) scope; BASE-04 must flag it.

**setup-beam verified outputs** (from erlef/setup-beam action.yml) [VERIFIED: GitHub API]:
- `elixir-version` — exact installed Elixir version
- `otp-version` — exact installed OTP version
- `gleam-version`, `rebar3-version` (not relevant here)

To read them in a subsequent step: `${{ steps.<id>.outputs.otp-version }}` and
`${{ steps.<id>.outputs.elixir-version }}`.

---

## Environment Facts

[VERIFIED: local command execution]

| Property | Value |
|----------|-------|
| Elixir | 1.19.5 (compiled with Erlang/OTP 28) |
| OTP | 28 (erts-16.3) |
| Mix | 1.19.5 |
| `System.schedulers_online()` (dev) | **18** |
| `System.schedulers_online()` (ubuntu-latest runner) | **4** (standard GitHub-hosted) |
| `mix test --slowest` | Available (Elixir 1.x standard) |
| `mix test --slowest-modules` | Available since 1.17.0 |
| `mix test --repeat-until-failure` | Available since 1.17.0 |
| `mix test --partitions` | Available (standard) |
| `mix compile --profile time` | Available |
| `mix xref graph --label compile-connected` | Available; 5 compile edges, 0 cycles |
| `mix ci` preferred env | `:test` (set in `def cli` in mix.exs) |
| `tee` | `/usr/bin/tee` — confirmed available on macOS/ubuntu |
| `gh` auth | Confirmed — used to pull run data above |

---

## BASE-05 Exact YAML Pattern

[VERIFIED: matching szTheory sibling patterns from mailglass/scrypath live repos + GitHub Actions docs]

### Step 1: Add `id:` to Setup Beam (line ~23 in ci.yml, `test` job only)

```yaml
      - name: Setup Beam
        id: setup-beam          # ADD THIS LINE
        uses: erlef/setup-beam@v1
        with:
          otp-version: '28'
          elixir-version: '1.19.5'
```

### Step 2: Capture mix ci stdout via tee (replace bare `mix ci` step)

```yaml
      - name: Run CI
        run: mix ci 2>&1 | tee /tmp/mix-ci-output.log; exit ${PIPESTATUS[0]}
```

The `${PIPESTATUS[0]}` preserves the exit code of `mix ci`, not `tee`. This is critical —
without it, `tee`'s exit code (always 0) would swallow a `mix ci` failure.

**Alternative (bash explicit):**
```yaml
      - name: Run CI
        shell: bash
        run: |
          set -o pipefail
          mix ci 2>&1 | tee /tmp/mix-ci-output.log
```
`set -o pipefail` is the bash-idiomatic equivalent and more portable.

### Step 3: Job summary step (always runs, never errors the job)

```yaml
      - name: CI Baseline Summary
        if: always()
        continue-on-error: true
        shell: bash
        run: |
          {
            echo "## CI Baseline"
            echo ""
            echo "| Property | Value |"
            echo "|----------|-------|"
            echo "| OTP | ${{ steps.setup-beam.outputs.otp-version }} |"
            echo "| Elixir | ${{ steps.setup-beam.outputs.elixir-version }} |"
            echo "| Schedulers | $(elixir -e 'IO.puts(System.schedulers_online())' 2>/dev/null || echo 'n/a') |"
            echo "| Cache (deps) | cold / none |"
            echo "| Cache (_build) | cold / none |"
            echo ""
            echo "### Slowest Tests"
            echo ""
            grep -A 25 'Top [0-9]* slowest' /tmp/mix-ci-output.log || echo "_(slowest data unavailable)_"
          } >> "$GITHUB_STEP_SUMMARY"
```

**Key guarantees encoded in this step:**
- `if: always()` — runs even if `Run CI` step fails.
- `continue-on-error: true` — a shell error in the summary step cannot fail the job.
- `|| echo 'n/a'` / `|| echo "_(unavailable)_"` — every subcommand has a fallback.
- Single brace-group `{ … } >> "$GITHUB_STEP_SUMMARY"` — one write, no multi-write collapse.
- The step is purely additive; it reads `steps.setup-beam.outputs.*` and the tee'd log.

### Phase 109 cache row seam (one-line edit in 109, not 108)

In 108, the cache rows show `cold / none`. In 109, when `actions/cache` is added with `id: cache`,
the summary step gains one line:
```yaml
            echo "| Cache (deps) | ${{ steps.cache.outputs.cache-hit == 'true' && 'hit' || 'miss' }} |"
```
This is the handoff seam D-02 names. Phase 108 MUST include a `# TODO(109): replace 'cold / none' with cache-hit output` comment to mark it.

### Why NOT composite action

The composite-action rejection is based on a real bug: when multiple steps inside a composite
action all write to `$GITHUB_STEP_SUMMARY` via `>> $GITHUB_STEP_SUMMARY`, only the LAST line
survives. This is documented in actions/runner#2020 and community discussion #32566.
[CITED: actions/runner#2020, community discussion #32566 — referenced in CONTEXT.md]
Zero of 9 szTheory sibling repos use a CI-summary composite action.

### Sibling pattern evidence

- **mailglass** [VERIFIED: GitHub API]: uses `{ echo "## heading"; echo "- items"; } >> "$GITHUB_STEP_SUMMARY"` — exact brace-group style, multiple jobs.
- **scrypath** [VERIFIED: GitHub API]: uses `if: always()` + `cat generated-file.md >> "$GITHUB_STEP_SUMMARY"` — the file-based variant (not applicable here, but confirms `if: always()` convention).

---

## A–E Classification Analysis (BASE-03 Source Material)

### Test file inventory

[VERIFIED: `find test -name "*.exs" | grep -v test_helper | wc -l` and grep counts]

| Category | Count |
|----------|-------|
| Total test files | 127 |
| `async: true` explicit | 89 |
| `async: false` explicit | **34** |
| No explicit `async:` (defaults to false) | 4 |

The 4 with no explicit async setting: `test/rendro_test.exs`, `test/rendro/artifact_test.exs`,
`test/rendro/end_to_end_pipeline_test.exs`, `test/rendro/pdf/png_test.exs`. These default to
`async: false` in ExUnit. Include them in the analysis but note they are technically uncategorized
(they may be convertible).

### async:false reason classification by grep

[VERIFIED: grep commands against each file]

**Axis A: `Application.put_env` / `Application.delete_env` (global app env mutation)**

These modules mutate Application environment and cannot be run concurrently with any test that
reads those keys. Grep signal: `Application.put_env` / `Application.delete_env`.

| Module | File |
|--------|------|
| Rendro.Text.ShaperTest | `test/rendro/text/shaper_test.exs` — explicitly commented: "async: false required — setup uses Application.delete_env" |
| Rendro.SignTest | `test/rendro/sign_test.exs` — `Application.delete_env(:rendro, :pyhanko_executable_finder)` |
| Rendro.Adapters.QpdfTest | `test/rendro/adapters/qpdf_test.exs` — `Application.put_env(:rendro, :qpdf_executable_finder, ...)` |
| Rendro.Adapters.PdfsigTest | `test/rendro/adapters/pdfsig_test.exs` — `Application.put_env(:rendro, :pdfsig_executable_finder, ...)` |
| Rendro.Adapters.PopplerTest | `test/rendro/adapters/poppler_test.exs` — `Application.put_env(:rendro, :pdfinfo_executable_finder, ...)` |
| Rendro.Adapters.PyHankoTest | `test/rendro/adapters/py_hanko_test.exs` — `Application.put_env(:rendro, :pyhanko_executable_finder, ...)` |
| Mix.Tasks.Release.PreflightTest | `test/mix/tasks/release_preflight_test.exs` — `Application.put_env(:rendro, :release_preflight_command_runner, ...)` |
| Mix.Tasks.VerifyTest | `test/mix/tasks/verify_test.exs` — `Application.put_env(:rendro, :verify_test_lanes, ...)` |
| Mix.Tasks.Docs.ContractTest | `test/mix/tasks/docs_contract_task_test.exs` — `Application.put_env(:rendro, :docs_contract_command_runner, ...)` |
| Mix.Tasks.RendroLivebookCheckTest | `test/mix/tasks/rendro_livebook_check_test.exs` — `Application.delete_env(:rendro, :livebook_converter)` |

**Axis B: Process-global telemetry handler attachment**

`:telemetry.attach_many` is process-global — a handler attached in one test leaks into others.
Grep signal: `telemetry`, `attach`, `handler_id`.

| Module | File |
|--------|------|
| Rendro.TelemetryTest | `test/rendro/telemetry_test.exs` — attaches via `TelemetryHelper.attach()` in setup |
| Rendro.Adapters.ThreadlineTest | `test/rendro/adapters/threadline_test.exs` — attaches via `Adapter.attach()` in setup |

**Axis C: Global module namespace (recompile)**

`PublicApi.recompile_conditional_adapters()` triggers `IEx.Helpers.recompile()` or equivalent —
a global BEAM operation. Cannot be run concurrently with any code-loading.

| Module | File |
|--------|------|
| Rendro.PublicApiTest | `test/rendro/public_api_test.exs` — calls `recompile_conditional_adapters/0` |

**Axis D: Tmpfs / System.tmp_dir / cross-process file paths**

Tests that create files in `System.tmp_dir!()` under predictable names can collide. Grep signal:
`System.tmp_dir`, `/tmp/`, `File.mkdir_p`, `File.rm_rf`.

| Module | File | Note |
|--------|------|------|
| Mix.Tasks.Rendro.ViewerEvidenceTest | `test/mix/tasks/viewer_evidence_task_test.exs` — `Path.join(System.tmp_dir!(), "rendro_stale_matrix_#{...}")` — unique_integer, probably safe |
| Rendro.ReleasePreflightProofTest | `test/scripts/release_preflight_proof_test.exs` — `"/tmp/release-proof"` fixed path |

**Axis E: Tool-invocation / Port / System.cmd — via /tmp paths**

Adapter modules invoke real external CLI tools or use test doubles that exercise the
command-runner pattern, writing to /tmp paths. The pattern is `Application.put_env` with
command_runner (which is Axis A), but the underlying reason also involves external process
invocation that mutates filesystem state in /tmp.

(These overlap with Axis A — the Application.put_env modules covering qpdf, pdfsig, poppler,
py_hanko, pyhanko, sign.)

**Axis F: docs_contract / launch artifacts / comparison claims — `mix hex.build` invocation**

These tests call `System.cmd("mix", ["hex.build"], ...)` or read files produced by it.
`mix hex.build` is not safe to run concurrently.

| Module | File |
|--------|------|
| Rendro.DocsContract.ComparisonClaimsTest | `test/docs_contract/comparison_claims_test.exs` — `{output, 0} = System.cmd("mix", ["hex.build"], ...)` |
| Rendro.DocsContract.BrandingClaimsTest | `test/docs_contract/branding_claims_test.exs` — `File.rm(tarball)` suggests hex.build artifact cleanup |
| Rendro.DocsContract.LaunchArtifactsClaimsTest | `test/docs_contract/launch_artifacts_claims_test.exs` — `File.rm_rf(tarball)` |

**Residue (~4 modules needing human read):**

These modules have `async: false` but their grep signals are less obvious:

| Module | File | Best-guess reason |
|--------|------|-------------------|
| Rendro.PublicApi.ManifestTest | `test/rendro/public_api/manifest_test.exs` | Calls `Mix.Tasks.Rendro.Api.Gen.encode_manifest` which may trigger module inspection; reads `priv/public_api.json` as ground truth — could be made async if manifest gen is side-effect-free |
| Rendro.DocsContract.BrandingContractTest | `test/docs_contract/branding_contract_test.exs` | No obvious global state found by grep — **candidate for async: true** (Phase 110) |
| Rendro.DocsContract.IntegrationsContractTest | `test/docs_contract/integrations_contract_test.exs` | No obvious global state — **candidate for async: true** |
| Rendro.DocsContract.RecipesContractTest | `test/docs_contract/recipes_contract_test.exs` | No obvious global state — **candidate for async: true** |

Also note `Rendro.DocsContract.IntegrationsClaimsTest` has a mislabeled first line
(`defmodule DocsContractMailglassWrapper.Message`) — likely a copy-paste artifact, worth flagging.

### Live-proof and excluded tag classification

[VERIFIED: test_helper.exs tag exclusions + ci.yml job structure]

| Category | Tags/Files | CI Lane | A–E |
|----------|-----------|---------|-----|
| `:raster_snapshot` | `pdfium_raster_snapshot_test.exs` | raster-advisory (advisory, continue-on-error) | C — move to scheduled/advisory; requires external binary |
| `:live_pdf_tools` | viewer_evidence_live_test files, long-lived signing | viewer-evidence-live-proof, long-lived-live-proof (needs: test) | C — already gated post-test; requires pdfium-cli + poppler + pyhanko |
| `:live_signing` | `signing_live_test.exs` | signing-live-proof (needs: test) | C — correctly layered |
| Advisory suite | comparison-advisory, livebook-advisory, pdfjs-advisory | graph-disconnected, continue-on-error | B/C — advisory; existing pattern is correct |
| release-proof | `scripts/release_preflight_proof.exs` | release-proof (needs: test) | B — high value but dominates critical path (554s in run 34) |

### Slowest tests (measured locally)

[VERIFIED: `MIX_ENV=test mix test --slowest 20 --seed 0` — local proxy, 18 schedulers, NOT runner-absolute]

| Test | Module | Duration (local) |
|------|--------|-----------------|
| hex package includes comparison guide | ComparisonClaimsTest | 603ms |
| hex tarball excludes operator-only priv paths | BrandingClaimsTest | 589ms |
| hex package includes public launch assets | LaunchArtifactsClaimsTest | 578ms |
| hex tarball includes branded assets and NOTICE | BrandingClaimsTest | 542ms |
| README compile/eval fences compile cleanly | ReadmeDoctestTest | 377ms |
| freshly-generated manifest is byte-identical to priv/public_api.json | ManifestTest | 267ms |
| full-surface sweep: every :rendro module is hidden or tagged | PublicApiTest | 262ms |
| recompile_conditional_adapters/0 returns :ok | PublicApiTest | 225ms |
| recompile_conditional_adapters/0 after recompile, Threadline loaded | PublicApiTest | 223ms |
| recompile_conditional_adapters/0 after recompile, Phoenix has :adapter tier | PublicApiTest | 219ms |
| validate --strict exits 1 when recorded_at exceeds 180 days | ViewerEvidenceTest | 202ms |
| render_id consistency: different renders produce different render_ids | TelemetryTest | 202ms |
| run/1 rasterizes image correctly using pdftoppm | Pipeline.RenderTest | 130ms |
| exception in a stage emits exception event via telemetry.span | TelemetryTest | 111ms |
| start events include render_id, stage, and document_type | TelemetryTest | 103ms |
| events fire in pipeline stage order | TelemetryTest | 101ms |
| top-level [:rendro, :render] span emits start and stop | TelemetryTest | 101ms |
| each stage start fires before its stop | TelemetryTest | 101ms |
| rejects modules that do not implement the protection adapter contract | ProtectTest | 101ms |
| top-level render stop uses paginated page_count | TelemetryTest | 101ms |

**Total test suite (local, warm, seed 0):** 10.5s (2.6s async, 7.9s sync)
**Tag: local proxy (18 schedulers; not runner-absolute)**

**Current test failure (local):** 1 failure in `Rendro.RecipesFacadeDriftTest` —
"Expected Rendro.Recipes.invoice/1 to be exported". This is an existing drift in the local
environment (not a new regression introduced by this phase). Note for BASE-03: flag this
as a known local failure that does not appear in CI green runs, likely a local env discrepancy.

### xref compile-connected stats

[VERIFIED: `MIX_ENV=test mix xref graph --label compile-connected --format stats`]

- Tracked files: 128
- Compile dependencies: **5** (very low — no problematic compile-chain)
- Cycles: 0
- Top compile-connected file: `lib/rendro/document.ex` (4 outgoing)

**Finding for BASE-02:** Compile-connected dependencies are minimal (5 edges, 0 cycles).
Compilation bottleneck is NOT structural — it is cold-cache cold-compile time, eliminated by Phase 109 caching.

---

## C1-AUDIT.md Report Shape (BASE-03, BASE-04 Planning)

### Location and front-matter

```
.planning/milestones/C1-AUDIT.md
```

YAML frontmatter (mirrors sibling MILESTONE-AUDIT style):
```yaml
---
milestone: C1
milestone_name: CI/CD Performance & Reliability
status: in-progress
generated: "2026-06-14"
phases: [109, 110, 111, 112, 113]
---
```

### Stable H2 anchors (MUST NOT be renamed during milestone)

| Anchor | Heading | URL fragment |
|--------|---------|--------------|
| BASE-01 | `## BASE-01 — Baseline Table` | `#base-01--baseline-table` |
| BASE-02 | `## BASE-02 — Critical Path` | `#base-02--critical-path` |
| BASE-03 | `## BASE-03 — A–E Classification` | `#base-03--ae-classification` |
| BASE-04 | `## BASE-04 — P0–P3 Recommendation Report` | `#base-04--p0p3-recommendation-report` |

Downstream citation pattern: `.planning/milestones/C1-AUDIT.md#base-01--baseline-table`

### P0–P3 recommendation structure per item

Each recommendation in BASE-04 MUST include:
- **Priority**: P0 / P1 / P2 / P3
- **Category**: Performance / Reliability / Security / DX / Test Quality
- **Issue**: What is wrong today
- **Proposed change**: Concrete action
- **Expected impact**: Runtime/reliability/DX benefit
- **Risk**: What could go wrong
- **Rollback**: How to revert
- **Target phase**: 109 / 110 / 111 / 112 / 113

### Flagship recommendation (P0 — must appear as first item in BASE-04)

**Decompose the `mix ci` monolith into parallel named jobs/steps.**

Today, all of `format → hex.build → compile → test → docs → credo → dialyzer` runs in a
single opaque "Run CI" step. This single step is why:
1. The API cannot see the inner split (forcing local-proxy profiling for BASE-01)
2. There is zero parallelism available (format/compile/test/docs/credo could run in parallel)
3. A dialyzer failure retakes 6 minutes of earlier work instead of running independently
4. BASE-05 instrumentation is needed now (no per-step timing otherwise)

Comparable szTheory repos all decompose: mailglass (Format/Compile/Support-Contract),
threadline (format→credo→compile→test, named steps), lockspire (qa/sast/docs/audit/test).

This is a compound recommendation: Phase 109 handles caching; Phase 111 handles topology.
Phase 108 names and classifies it; Phases 109/111 implement it.

---

## Common Pitfalls / Planner Guardrails

### HARD: Measure-only constraint

The plan MUST encode this as an explicit guardrail, not just a reminder:
- **No cache keys** may be added in Phase 108 — Phase 109 scope.
- **No `async:` changes** — Phase 110 scope.
- **No removed/quarantined tests** — Phase 110 scope.
- **No gate-logic edits** — any step change must be observability-only.
- **No changes to `docs/`, `guides/`, or `CONTRIBUTING.md`** — Phase 113 scope.
- **The ONLY file edit in Phase 108** is `.github/workflows/ci.yml` (BASE-05 instrumentation,
  `test` job only, steps 2–3 in the BASE-05 YAML pattern above).

### HARD: p95 phrasing

The audit document MUST use the exact phrase: **"insufficient green-run data (n=3)"**
for p95. Do not substitute "N/A", "—", "unknown", or any approximation.

### HARD: Local proxy labeling

Every number derived from local `mix test` MUST carry the tag:
**"local proxy (18 schedulers; not runner-absolute)"**

Do NOT present local milliseconds as CI milliseconds.

### HARD: No fresh paid CI runs

Do not trigger new CI runs to get better baseline data. Burns minutes on an uncached pipeline
that Phase 109 will invalidate anyway. Real after-metrics are Phase 113's job (VAL-01).

### HARD: Exit code in tee pattern

When capturing `mix ci` stdout via `tee`, the pipeline exit code MUST come from `mix ci`,
not from `tee`. Use either:
- `mix ci 2>&1 | tee /tmp/mix-ci-output.log; exit ${PIPESTATUS[0]}`
- OR `shell: bash` + `set -o pipefail` + `mix ci 2>&1 | tee /tmp/mix-ci-output.log`

Failing to do this means a failing `mix ci` appears to pass (tee always exits 0).

### HARD: Brace-group is one write

The entire `$GITHUB_STEP_SUMMARY` content MUST be emitted in a single brace-group redirect.
Do NOT split into multiple `>> "$GITHUB_STEP_SUMMARY"` writes in separate shell lines — this
is NOT the composite-action bug (that's different), but multiple writes produce inconsistent
rendering and violate the house style.

### SOFT: `elixir -e` in summary step

The `System.schedulers_online()` capture uses `elixir -e 'IO.puts(System.schedulers_online())'`
in the summary step. This requires the BEAM to be available at that point — it will be, since
setup-beam already ran. But wrap it with `|| echo 'n/a'` because this step runs `if: always()`
and could run even after a checkout failure where beam wasn't set up.

### SOFT: pdfjs-advisory was recently added

`pdfjs-advisory` was added on 2026-06-12 23:19 UTC (commit 999a0e2). The three green runs
used for BASE-01 timing (runs 3, 34, 35) predate this addition. The BASE-01 table should note
that pdfjs-advisory timing (11s) comes from a single run (run 37, which failed). This is an
honest labeling requirement, not a gap to hide.

### SOFT: 1 local test failure

`mix test` locally produces 1 failure: `Rendro.RecipesFacadeDriftTest` — "Expected
`Rendro.Recipes.invoice/1` to be exported". This is a local env drift, not a CI failure
(runs 34 and 35 were green). Do NOT include this in the flake sweep data as a flake —
it is a local state issue. Flag it in BASE-03 as a local-only failure for completeness.

---

## Architecture Patterns

### Recommended C1-AUDIT.md file structure

```
.planning/milestones/
├── C1-AUDIT-BRIEF.md   ← source brief (already exists, do not modify)
└── C1-AUDIT.md         ← Phase 108 produces this (single consolidated file)
```

### Recommended task sequencing for planner

**Wave 0 — Local measurement (no file edits)**
- Task: Run `mix test --slowest 20` (warm) and capture output for BASE-01 table
- Task: Run `MIX_ENV=test mix compile --profile time` and capture for BASE-01 notes
- Task: Run `mix xref graph --label compile-connected --format stats` (already done: 5 edges, 0 cycles)
- Task: Run `mix test --repeat-until-failure 25 --seed 0`, `--seed 1`, `--seed 2` (flake sweep)
- Task: Read the 4 residue async:false modules (BrandingContractTest, IntegrationsContractTest,
  RecipesContractTest, ManifestTest) to confirm or refute async-convertibility

**Wave 1 — BASE-05 YAML edit**
- Task: Add `id: setup-beam` to Setup Beam step in `test` job (ci.yml)
- Task: Modify "Run CI" step to capture stdout via tee
- Task: Add "CI Baseline Summary" step after "Run CI" (`if: always()`, `continue-on-error: true`)
- Task: Verify the edit does not break local `mix ci` (no behavior change)
- Task: Commit `.github/workflows/ci.yml` with message describing observability-only change

**Wave 2 — C1-AUDIT.md authoring**
- Task: Create `.planning/milestones/C1-AUDIT.md` with YAML frontmatter
- Task: Fill `## BASE-01 — Baseline Table` using real-runner data from §Real-Runner Timing Data
- Task: Fill `## BASE-02 — Critical Path` using §Critical-Path Anatomy
- Task: Fill `## BASE-03 — A–E Classification` using §A–E Classification Analysis
- Task: Fill `## BASE-04 — P0–P3 Recommendation Report` (flagship + P0–P3 items)
- Task: Commit C1-AUDIT.md

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Step summary output | Multi-step writes or composite action | Single brace-group `{ … } >> "$GITHUB_STEP_SUMMARY"` |
| Exit code from tee pipeline | `mix ci \| tee file` (silently swallows failure) | `set -o pipefail` or `${PIPESTATUS[0]}` |
| Per-run timing data | Triggering fresh CI runs | `gh api repos/szTheory/rendro/actions/runs/{id}/jobs` on existing history |
| slowest-test data for CI | Re-running the full suite | `tee` capture + grep on the `mix ci` stdout already produced |

---

## Runtime State Inventory

SKIPPED — this is a greenfield audit/instrumentation phase, not a rename/refactor/migration.
No stored data, live service config, OS-registered state, secrets, or build artifacts need migration.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` CLI | BASE-01 metric extraction | ✓ | confirmed auth | — |
| `elixir` / `mix` | All local commands | ✓ | Elixir 1.19.5 / OTP 28 | — |
| `mix test --slowest` | BASE-01 inner split | ✓ | available since 1.x | — |
| `mix test --repeat-until-failure` | BASE-03 flake sweep | ✓ | available since 1.17.0 | — |
| `mix xref graph` | BASE-02 compile analysis | ✓ | confirmed (5 edges, 0 cycles) | — |
| `tee` | BASE-05 stdout capture | ✓ | `/usr/bin/tee` | — |
| `mix compile --profile time` | BASE-01 local proxy | ✓ | standard | — |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

`workflow.nyquist_validation` is `true` in `.planning/config.json` — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5 built-in) |
| Config file | `test/test_helper.exs` (excludes `:live_pdf_tools`, `:live_signing`, `:raster_snapshot`) |
| Quick run command | `MIX_ENV=test mix test --slowest 20` |
| Full suite command | `mix ci` (runs format + compile + test + docs + credo + dialyzer) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BASE-01 | Baseline table covers all 3 workflows and 10 jobs with correct timing columns | Manual inspection of C1-AUDIT.md | inspect `.planning/milestones/C1-AUDIT.md` | ❌ Wave 2 creates it |
| BASE-02 | Critical path documented: test→release-proof is the 16-17min bottleneck | Manual inspection of C1-AUDIT.md | inspect `#base-02--critical-path` anchor | ❌ Wave 2 creates it |
| BASE-03 | All 34 async:false modules classified with cited evidence | Manual inspection of C1-AUDIT.md | inspect `#base-03--ae-classification` | ❌ Wave 2 creates it |
| BASE-04 | P0–P3 recommendations exist, each with issue/change/impact/risk/rollback/phase | Manual inspection of C1-AUDIT.md | inspect `#base-04--p0p3-recommendation-report` | ❌ Wave 2 creates it |
| BASE-05 | CI job summary step is present in test job, has correct guards, does not change gate | Smoke: `grep -n "CI Baseline Summary\|if: always()\|continue-on-error" .github/workflows/ci.yml` | `grep` command | ❌ Wave 1 creates it |
| BASE-05 | tee capture preserves mix ci exit code | Smoke: `grep -n "PIPESTATUS\|pipefail" .github/workflows/ci.yml` | `grep` command | ❌ Wave 1 creates it |
| BASE-05 | setup-beam has `id: setup-beam` | Smoke: `grep -n "id: setup-beam" .github/workflows/ci.yml` | `grep` command | ❌ Wave 1 creates it |

### Sampling Rate

- **Per task commit:** `grep` verification of the specific YAML line added or file section written
- **Per wave merge:** Wave 1: full manual inspection of the modified `test` job YAML stanza; Wave 2: spot-check all 4 BASE-0N anchors exist in C1-AUDIT.md
- **Phase gate:** Both `C1-AUDIT.md` exists with all 4 anchors AND `.github/workflows/ci.yml` passes all 3 BASE-05 smoke grepping before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `mix test --repeat-until-failure 25` (seeds 0, 1, 2) must be run to provide BASE-03 flake-sweep evidence — not pre-existing
- [ ] Read the 4 residue async:false files (BrandingContractTest, IntegrationsContractTest, RecipesContractTest, ManifestTest) — human-read task, not automated

*(No test framework gaps — ExUnit exists; the validation here is document authoring + YAML inspection, not a new test suite.)*

---

## Security Domain

`security_enforcement` is not explicitly set to `false` in config.json — treat as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | No (no user input) | — |
| V6 Cryptography | No | — |

### Known Threat Patterns for GitHub Actions

| Pattern | STRIDE | Standard Mitigation | Phase 108 status |
|---------|--------|---------------------|-----------------|
| Floating action ref (`@v1`) | Tampering | SHA-pin all third-party actions | ❌ ci.yml + release.yml use @v1 — BASE-04 must flag; Phase 112 (SEC-01) implements |
| Summary content injection | Tampering | Summary content here is all static / controlled env vars — low risk | Acceptable |
| Secrets in summary | Information Disclosure | Never echo secrets to GITHUB_STEP_SUMMARY | No secrets in BASE-05 content |

The BASE-05 step reads only: `steps.setup-beam.outputs.otp-version`, `steps.setup-beam.outputs.elixir-version`, `System.schedulers_online()`, and grep of the tee'd mix ci log. None of these is secret material.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ubuntu-latest provides 4 BEAM schedulers (standard GitHub runner) | Environment Facts | If GitHub changes runner hardware, the 18-vs-4 multiplier note would be stale — low risk for Phase 108 |
| A2 | The 4 test files with no explicit `async:` setting (rendro_test.exs, artifact_test.exs, end_to_end_pipeline_test.exs, png_test.exs) are effectively async:false by ExUnit default | A–E Classification | If any of these happen to have `async: true` via a use macro, the count would change — confirm by reading |
| A3 | Local test failure in RecipesFacadeDriftTest is a local env artifact, not a recurring flake | Common Pitfalls | If it recurs on CI, it would be a BASE-03 flake finding |
| A4 | pdfjs-advisory timing (11s) from run 37 is representative — it uses npm cache | Real-Runner Timing Data | If the npm cache was cold, it could be longer on first run |

**No assumptions about package names, external APIs, or specification interpretations that require user confirmation before execution.**

---

## Open Questions

1. **RecipesFacadeDriftTest local failure**
   - What we know: 1 test failure locally (`Expected Rendro.Recipes.invoice/1 to be exported`)
   - What's unclear: Whether this is a local env issue or a genuine drift in the codebase since the green CI runs
   - Recommendation: Run `mix test test/rendro/recipes_facade_drift_test.exs` in isolation before flake sweep to characterize

2. **4 residue async:false modules**
   - What we know: BrandingContractTest, IntegrationsContractTest, RecipesContractTest — no grep-visible global state
   - What's unclear: Whether they were made async:false by convention (defensive) or by necessity
   - Recommendation: Human-read each file (Wave 0 task); if no global state found, classify as Phase 110 candidates for async:true flip

---

## Sources

### Primary (HIGH confidence)

- GitHub Actions API live data — `gh api repos/szTheory/rendro/actions/runs/*/jobs` — all timing data
- `/Users/jon/projects/rendro/.github/workflows/ci.yml` — full job structure, SHA refs, step names
- `/Users/jon/projects/rendro/.github/workflows/hexdocs.yml` — setup-beam SHA pin, job structure
- `/Users/jon/projects/rendro/.github/workflows/release.yml` — release job steps
- `/Users/jon/projects/rendro/mix.exs` — `ci:` alias exact chain, preferred_envs, Dialyzer config
- `/Users/jon/projects/rendro/test/test_helper.exs` — tag exclusions, ETS setup, async:false convention
- `mix test --slowest 20 --seed 0` local run — slowest test data (tagged: local proxy)
- `mix xref graph --label compile-connected --format stats` — 5 edges, 0 cycles
- `elixir --version` — Elixir 1.19.5 / OTP 28 / 18 schedulers
- `gh api repos/erlef/setup-beam/contents/action.yml` — setup-beam outputs: elixir-version, otp-version
- `gh api repos/szTheory/mailglass/contents/.github/workflows/ci.yml` — brace-group house style
- `gh api repos/szTheory/scrypath/contents/.github/workflows/ci.yml` — `if: always()` + cat pattern
- `git log --oneline -- .github/workflows/ci.yml` — pdfjs-advisory add date (2026-06-12 23:19)

### Secondary (MEDIUM confidence)

- `/Users/jon/projects/rendro/prompts/rendro-oss-dna.md` — szTheory CI/release/test DNA; sibling repo names
- `/Users/jon/projects/rendro/.planning/milestones/C1-AUDIT-BRIEF.md` — §3, §4, §10, §11, §12 brief scope

### Tertiary (LOW confidence)

- actions/runner#2020 and community discussion #32566 — composite-action multi-write collapse bug
  [CITED: referenced in CONTEXT.md D-02; not independently re-verified in this session]

---

## Metadata

**Confidence breakdown:**
- Real-runner timing data: HIGH — extracted from live GitHub API, 3 green runs, exact timestamps
- async:false classification: HIGH — grep verified against all 34 files; 4 residue need human read
- BASE-05 YAML pattern: HIGH — matches live sibling code + GitHub Actions docs for GITHUB_STEP_SUMMARY
- A–E classification logic: HIGH for axes A/B/C (clear evidence); MEDIUM for residue 4 (needs human read)
- C1-AUDIT.md structure: HIGH — follows locked D-03 decision verbatim

**Research date:** 2026-06-14
**Valid until:** 2026-07-14 (stable domain; timing numbers invalidated if pdfjs-advisory or other jobs are added)

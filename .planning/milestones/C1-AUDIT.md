---
milestone: C1
milestone_name: CI/CD Performance & Reliability
status: in-progress
generated: "2026-06-14"
phases: [109, 110, 111, 112, 113]
---

# C1 Baseline Audit

This document is the Phase 108 measure-only baseline for milestone C1 (CI/CD Performance & Reliability). All numbers reflect the pre-optimization state of the pipeline; no source files, tests, or workflow YAMLs were modified to produce these measurements. Phases 109–113 implement the recommendations in BASE-04, and Phase 113 closes this milestone by comparing after-metrics against this baseline.

> **Citation contract (stable; do not rename anchors mid-milestone):**
> - `.planning/milestones/C1-AUDIT.md#base-01--baseline-table`
> - `.planning/milestones/C1-AUDIT.md#base-02--critical-path`
> - `.planning/milestones/C1-AUDIT.md#base-03--ae-classification`
> - `.planning/milestones/C1-AUDIT.md#base-04--p0p3-recommendation-report`

---

## BASE-01 — Baseline Table

**Evidence source:** `108-EVIDENCE.md` — Real-Runner Timing, Summary Table, Duplicated Work.
**Runner timing source:** `gh api repos/szTheory/rendro/actions/runs/{id}/jobs` — live GitHub Actions API data from runs #3, #34, #35 (ci.yml) and equivalent for hexdocs.yml and release.yml. No fresh CI runs were triggered.
**p95 note:** Only 3 green runs of 37 total — see "insufficient green-run data (n=3)" entries below.

### ci.yml — Trigger: `push`, `pull_request`

| Job | Runner | Command | Avg Duration | p95 Duration | Required-for-merge | Cache (deps) | Cache (_build) | Quality Signal | Likely Bottleneck | Notes |
|-----|--------|---------|-------------|-------------|-------------------|--------------|----------------|----------------|-------------------|-------|
| `test` | ubuntu-latest | `mix ci` (format → hex.build → compile → test → docs → credo → dialyzer) | ~345s job total; `mix ci` inner step avg 327s (local proxy — 18 schedulers; not runner-absolute) | insufficient green-run data (n=3) | Yes | none — `mix deps.get` runs cold every job | none — full recompile every run | Gate: format, compile warnings-as-errors, full test suite, docs, credo, dialyzer | Full cold recompile + zero deps caching; entire `mix ci` chain opaque in single step |  Two pre-existing failures on main (see BASE-03): `Rendro.PublicApiTest` (Mix.Tasks.Brand.Gen missing `@moduledoc`) and `RecipesFacadeDriftTest` (seed-0 ordering artifact). Both reproduce identically at pre-phase commit. |
| `example-phoenix` | ubuntu-latest | `mix deps.get && mix compile` (sub-dir phoenix example) | ~60s (run 34: 59s, run 35: 61s) | insufficient green-run data (n=3) | Yes (no `continue-on-error`) | none | none | Validates Phoenix integration compiles cleanly | Cold deps.get + recompile in phoenix example subdir | Graph-disconnected (no `needs:`); no `continue-on-error`; required-for-merge by absence of soft-fail flag |
| `raster-advisory` | ubuntu-latest | `mix test --only raster_snapshot` (requires pdfium-cli external binary) | ~306s (run 34: 304s, run 35: 308s) | insufficient green-run data (n=3) | No (`continue-on-error: true`) | none | none | Advisory: raster snapshot diffing via pdfium-cli | External binary dependency (pdfium-cli); cold compile | Graph-disconnected (no `needs:`); advisory lane; correctly soft-fail |
| `comparison-advisory` | ubuntu-latest | Comparison evidence generation (poppler-based) | ~155s (run 34: 160s, run 35: 150s) | insufficient green-run data (n=3) | No (`continue-on-error: true`) | none | none | Advisory: comparison evidence generation | External binary (poppler); cold compile | Graph-disconnected; advisory lane |
| `livebook-advisory` | ubuntu-latest | Livebook tutorial verification | ~193s (run 34: 175s, run 35: 210s) | insufficient green-run data (n=3) | No (`continue-on-error: true`) | none | none | Advisory: Livebook notebook evaluability | Cold compile; notebook eval overhead | Graph-disconnected; advisory lane |
| `pdfjs-advisory` | ubuntu-latest | `npm ci && node observe.mjs` | ~11s (single run — run 37, which failed; npm cache was hot) | insufficient green-run data (n=3) | No (`continue-on-error: true`) | N/A (Node job) | N/A (Node job) | Advisory: PDF.js viewer artifact presence check | npm install (mitigated by cache in run 37) | Added 2026-06-12 (commit 999a0e2); timing (11s) from single failed run 37 — npm cache was hot; treat as approximate. Absent from runs 34 and 35. |
| `signing-live-proof` | ubuntu-latest | Live signing end-to-end proof (pyhanko) | ~172s (run 34: 170s, run 35: 174s) | insufficient green-run data (n=3) | Yes (`needs: test`) | none | none | Live-proof: digital signature generation via pyhanko | External tool (pyhanko) + cold compile | Proof gate; requires real pyhanko binary; correctly post-`test`-gated |
| `long-lived-live-proof` | ubuntu-latest | Long-lived signing proof | ~174s (run 34: 177s, run 35: 171s) | insufficient green-run data (n=3) | Yes (`needs: test`) | none | none | Live-proof: long-lived certificate signing scenario | External tool (pyhanko) + cold compile | Proof gate; correctly post-`test`-gated |
| `viewer-evidence-live-proof` | ubuntu-latest | Viewer evidence generation (pdfium-cli + poppler) | ~288s (run 34: 292s, run 35: 283s) | insufficient green-run data (n=3) | Yes (`needs: test`) | none | none | Live-proof: viewer evidence artifact generation | External binaries (pdfium-cli, poppler); cold compile | Proof gate; correctly post-`test`-gated |
| `release-proof` | ubuntu-latest | `mix release.preflight` (hex.build --unpack + hex.publish --dry-run in git worktree) | ~599s avg (run 34: 553s, run 35: 645s) | insufficient green-run data (n=3) | Yes (`needs: test`) | none | none | Release gate: validates the Hex package is publishable | **CRITICAL PATH BOTTLENECK** — full cold compile + hex.build + hex.publish --dry-run in isolated git worktree | Has `timeout: 45min`; dominates PR wall-clock; see BASE-02 |

### hexdocs.yml — Trigger: `push` (all branches), `pull_request`

| Job | Runner | Command | Avg Duration | p95 Duration | Required-for-merge | Cache | Quality Signal | Likely Bottleneck | Notes |
|-----|--------|---------|-------------|-------------|-------------------|-------|----------------|-------------------|-------|
| `verify-docs-ready` | ubuntu-latest | Docs contract + Livebook + comparison evidence verification | ~373s (single measured run: 27443757945) | insufficient green-run data (n=3) | No (separate workflow; not in branch protection required checks) | none | Advisory: docs are contract-valid, fences evaluable | Cold compile + docs contract + Livebook eval + comparison checks | setup-beam uses SHA-pinned ref (`@8251c48...`) — consistent supply-chain posture; ci.yml uses floating `@v1` — inconsistent supply-chain posture (→ SEC-01, Phase 112) |
| `publish-hexdocs` | ubuntu-latest | `mix docs && hex publish docs` | ~157s (single measured run: 27443757945) | insufficient green-run data (n=3) | No | none | Docs publishing to HexDocs.pm | HexDocs publish API round-trip | `needs: verify-docs-ready`; push-to-main only (not on PR); not a merge gate |

### release.yml — Trigger: tag push (`v*`)

| Job | Runner | Command | Avg Duration | p95 Duration | Required-for-merge | Cache | Quality Signal | Likely Bottleneck | Notes |
|-----|--------|---------|-------------|-------------|-------------------|-------|----------------|-------------------|-------|
| `publish` | ubuntu-latest | `mix ci` (412s) + `mix release.preflight` (41s) + `mix hex.publish` (2s) | ~488s total (single measured run: v1.0.0 release, id: 27043056315) | insufficient green-run data (n=3) | N/A (release path, not PR gate) | none | Full CI verification + release publishing | `mix ci` re-run (412s) — pure duplicated verification | Runs `mix ci` again even though tag was built from a SHA that already passed CI — duplicated full verification. ci.yml uses floating `erlef/setup-beam@v1`; hexdocs.yml is SHA-pinned — inconsistent supply-chain posture (→ SEC-01, Phase 112) |

### Key Aggregate Findings

| Metric | Value | Source |
|--------|-------|--------|
| `mix ci` duration avg (n=3 green runs) | 327s | 108-EVIDENCE.md — (222+386+372)/3 |
| `mix ci` duration range | 222s–386s | 108-EVIDENCE.md runs #3, #34, #35 |
| test job wall-clock avg | ~345s | 108-EVIDENCE.md — (245+401+389)/3 |
| Full CI wall-clock (run 34) | 966s (16m06s) | 108-EVIDENCE.md — gh api run-level timestamps |
| Full CI wall-clock (run 35) | 1039s (17m19s) | 108-EVIDENCE.md — gh api run-level timestamps |
| p95 full CI run wall-clock | **insufficient green-run data (n=3)** | 108-EVIDENCE.md — only 3 green of 37 total runs |
| Cache: deps | NONE | 108-EVIDENCE.md — ci.yml inspection |
| Cache: \_build | NONE | 108-EVIDENCE.md — ci.yml inspection |
| Cache: Dialyzer PLTs | NONE | 108-EVIDENCE.md — ci.yml inspection |
| Critical path bottleneck | `release-proof`: 553s (run 34), 645s (run 35) | 108-EVIDENCE.md — gh api |

---

## BASE-02 — Critical Path

**Evidence source:** `108-EVIDENCE.md` — Critical Path Summary, Duplicated Work, xref Compile-Connected Stats.

### PR / Push-to-Main Critical Path (ci.yml)

```
[t=0] START — all Tier 1 jobs launch in parallel:
  ┌─ test                        (merge gate, ~395s avg)        ← sets release-proof clock
  ├─ example-phoenix             (no continue-on-error, ~60s)
  ├─ raster-advisory             (continue-on-error: true, ~306s)
  ├─ comparison-advisory         (continue-on-error: true, ~155s)
  ├─ livebook-advisory           (continue-on-error: true, ~193s)
  └─ pdfjs-advisory              (continue-on-error: true, ~11s — Node only)

[t≈6.5min] test job completes → triggers Tier 2 (needs: test):
  ├─ signing-live-proof          (needs: test, ~172s)
  ├─ long-lived-live-proof       (needs: test, ~174s)
  ├─ viewer-evidence-live-proof  (needs: test, ~288s)
  └─ release-proof               (needs: test, ~599s avg)  ← CRITICAL PATH BOTTLENECK

[t≈16-17min] release-proof completes → CI done
```

**Critical path:** START → `test` (~6.5 min) → `release-proof` (~9–10 min) = **~16–17 min total wall-clock**

`release-proof` is the critical-path bottleneck because:
- It `needs: test`, so it cannot start until ~6.5 min into the run.
- It then takes another ~9–10 min (553s run 34, 645s run 35, avg ~599s).
- It runs `mix deps.get` + full `mix release.preflight` (compile + release assemble) in a git worktree — same cold-compile cost as the `test` job on top of the 6.5-min `test` gate lead time.

### Push-to-Main Additional Path (hexdocs.yml)

hexdocs.yml runs in parallel with ci.yml on every push and PR:
- `verify-docs-ready` (~373s) — always runs; not required for merge
- `publish-hexdocs` (~157s, `needs: verify-docs-ready`) — push-to-main only; not required for merge

Total hexdocs path: ~530s (not on the merge critical path, but adds parallel runner usage).

### Release / Tag Path (release.yml)

Triggered independently on tag push (`v*`). Fully independent of ci.yml.

```
[t=0] Install System Deps (19s)
→ Install Deps (mix deps.get, 2s)
→ Run CI Checks (mix ci, 412s)   ← full re-run despite tag being built from CI-green SHA
→ Release Preflight (mix release.preflight, 41s)
→ Publish (mix hex.publish, 2s)
= 488s total (8m08s)
```

**Key finding:** `release.yml` re-runs `mix ci` (412s) even though the tag was created from a commit that already passed ci.yml. This is pure duplicated verification — the same compilation and test suite runs twice for the same code.

### Duplicated Work Inventory

| Work Item | Jobs Affected | Count | Cost |
|-----------|--------------|-------|------|
| `erlef/setup-beam@v1` (OTP + Elixir install) | test, example-phoenix, raster-advisory, comparison-advisory, livebook-advisory, signing-live-proof, long-lived-live-proof, viewer-evidence-live-proof, release-proof | 9 of 10 jobs (pdfjs-advisory uses setup-node) | Setup-beam: ~7–8s × 9 = ~63–72s per run; multiplied by every PR push |
| `mix deps.get` (dependency fetch from scratch) | test, example-phoenix (sub-dir), raster-advisory, comparison-advisory, livebook-advisory, signing-live-proof, long-lived-live-proof, viewer-evidence-live-proof, release-proof | 8+ jobs | ~2–3s per fetch × 8+ = ~16–24s; all packages re-downloaded every run |
| Full `_build` cold recompile | Every Elixir job (test, example-phoenix, raster-advisory, comparison-advisory, livebook-advisory, signing-live-proof, long-lived-live-proof, viewer-evidence-live-proof, release-proof) | All 9 Elixir jobs | ~300s per job × 9 = ~45 min of compile time per full CI run |
| `mix ci` full run (format → hex.build → compile → test → docs → credo → dialyzer) | `test` job in ci.yml AND `publish` job in release.yml | 2 separate workflow runs per release tag | ~327s (ci.yml) + ~412s (release.yml) = ~739s of duplicated full verification |

**Zero caching anywhere:** Every job starts cold. Every job pays the full cold-compile cost. This is the primary driver of the 16–17 min PR wall-clock and the P1 caching recommendation in BASE-04.

### Compile-Chain Analysis

**Source:** `MIX_ENV=test mix xref graph --label compile-connected --format stats` — local proxy (18 schedulers; not runner-absolute)

| Property | Value |
|----------|-------|
| Tracked files | 128 |
| Compile dependencies | **5** (very low) |
| Exports dependencies | 142 |
| Runtime dependencies | 218 |
| Cycles | **0** |
| Top compile-connected file | `lib/rendro/document.ex` (4 outgoing — `writer.ex`, `paginate.ex`, `measure.ex`, `launch_artifacts.ex`) |
| Second | `lib/rendro/page_template.ex` (1 outgoing) |

**Finding:** Compile-connected dependencies are minimal (5 edges, 0 cycles). The compilation bottleneck is NOT structural — it is cold-cache cold-compile time. Phase 109 caching will eliminate the repeated cold-compile cost. No xref guardrail is needed for compile cycles.

---

## BASE-03 — A–E Classification

**Evidence source:** `108-EVIDENCE.md` — Bounded Flake Sweep Results, Residue async:false Module Read, Local Profiling (slowest 20 tests). **Classification definitions from C1-AUDIT-BRIEF.md §4.**

**Classification key:**
- **A** — Must remain in PR gate (catches regressions, fast enough, deterministic, actionable)
- **B** — Keep in PR but optimize (valuable but slow due to setup/lack of async/bad fixture strategy)
- **C** — Move to scheduled/main/release gate (valuable but too slow/broad for every PR)
- **D** — Quarantine/fix before trusting (flaky, timing-sensitive, global-state leaks)
- **E** — Delete or rewrite (assertion-free filler, duplicated path, implementation trivia — evidence required per D-04)

### Category 1: test gate (`mix ci` serial run)

**Trigger:** ci.yml `test` job; runs `mix ci` which executes the full ExUnit suite (format → hex.build → compile → test → docs → credo → dialyzer) serially in one opaque step.

#### 1a. Explicit `async: true` modules (89 modules)

**Classification: A** — All 89 `async: true` modules run concurrently, use no global state by definition (ExUnit enforces this contract), and produce deterministic results. No individual review needed at Phase 108's evidence ceiling (D-04). Bulk-classified as keep-in-PR.

#### 1b. Explicit `async: false` modules (34 modules) — classified by global-state axis

The following table maps each module to the concrete non-async reason (per D-04 evidence floor: grep-verified against each file, with 4 residue modules human-read). No module is classified async:false without a cited concrete reason.

**Axis A — `Application.put_env` / `Application.delete_env` (global application environment mutation)**

These modules mutate the Application environment. Any concurrent test that reads those keys would see inconsistent state.

| Module | File | Specific Reason | Classification |
|--------|------|----------------|----------------|
| Rendro.Text.ShaperTest | `test/rendro/text/shaper_test.exs` | `Application.delete_env(:rendro, ...)` — explicitly commented in file: "async: false required — setup uses Application.delete_env" | **A** |
| Rendro.SignTest | `test/rendro/sign_test.exs` | `Application.delete_env(:rendro, :pyhanko_executable_finder)` | **A** |
| Rendro.Adapters.QpdfTest | `test/rendro/adapters/qpdf_test.exs` | `Application.put_env(:rendro, :qpdf_executable_finder, ...)` | **A** |
| Rendro.Adapters.PdfsigTest | `test/rendro/adapters/pdfsig_test.exs` | `Application.put_env(:rendro, :pdfsig_executable_finder, ...)` | **A** |
| Rendro.Adapters.PopplerTest | `test/rendro/adapters/poppler_test.exs` | `Application.put_env(:rendro, :pdfinfo_executable_finder, ...)` | **A** |
| Rendro.Adapters.PyHankoTest | `test/rendro/adapters/py_hanko_test.exs` | `Application.put_env(:rendro, :pyhanko_executable_finder, ...)` | **A** |
| Mix.Tasks.Release.PreflightTest | `test/mix/tasks/release_preflight_test.exs` | `Application.put_env(:rendro, :release_preflight_command_runner, ...)` | **A** |
| Mix.Tasks.VerifyTest | `test/mix/tasks/verify_test.exs` | `Application.put_env(:rendro, :verify_test_lanes, ...)` | **A** |
| Mix.Tasks.Docs.ContractTest | `test/mix/tasks/docs_contract_task_test.exs` | `Application.put_env(:rendro, :docs_contract_command_runner, ...)` | **A** |
| Mix.Tasks.RendroLivebookCheckTest | `test/mix/tasks/rendro_livebook_check_test.exs` | `Application.delete_env(:rendro, :livebook_converter)` | **A** |

**Axis B — Process-global telemetry handler attachment**

`:telemetry.attach_many` attaches handlers to a globally shared process. A handler registered in one test leaks into concurrent tests.

| Module | File | Specific Reason | Classification |
|--------|------|----------------|----------------|
| Rendro.TelemetryTest | `test/rendro/telemetry_test.exs` | Attaches process-global telemetry handlers via `TelemetryHelper.attach()` in `setup` | **A** |
| Rendro.Adapters.ThreadlineTest | `test/rendro/adapters/threadline_test.exs` | Attaches process-global telemetry handler via `Adapter.attach()` in `setup` | **A** |

**Axis C — Global BEAM module namespace (recompile)**

`PublicApi.recompile_conditional_adapters()` triggers global BEAM module recompilation — equivalent to `IEx.Helpers.recompile()`. Cannot be run concurrently with any code-loading or compile operation.

| Module | File | Specific Reason | Classification |
|--------|------|----------------|----------------|
| Rendro.PublicApiTest | `test/rendro/public_api_test.exs` | `PublicApi.recompile_conditional_adapters()` — global BEAM module recompilation | **A** |

**Axis D — tmpfs / `System.tmp_dir!()` cross-process file paths**

Tests creating files under predictable names in the system temp directory risk collision with concurrent tests.

| Module | File | Specific Reason | Classification |
|--------|------|----------------|----------------|
| Mix.Tasks.Rendro.ViewerEvidenceTest | `test/mix/tasks/viewer_evidence_task_test.exs` | `Path.join(System.tmp_dir!(), "rendro_stale_matrix_#{unique_integer}")` — uses unique_integer, likely safe; async:false is defensive | **A** |
| Rendro.ReleasePreflightProofTest | `test/scripts/release_preflight_proof_test.exs` | `"/tmp/release-proof"` — fixed path; cannot run concurrently with anything that touches this path | **A** |

**Axis E (overlaps with A) — Tool-invocation / Port / `System.cmd` with `/tmp` paths**

These modules invoke external CLI tools (qpdf, pdfsig, poppler, pyhanko) via `Application.put_env` command_runner pattern. The same 6 modules from Axis A cover this (the `Application.put_env` for the command_runner is the primary reason; external tool invocation is the secondary reason). Already classified above.

**Axis F — `mix hex.build` invocation (concurrent-unsafe)**

`mix hex.build` writes to the project directory and is not safe to run concurrently.

| Module | File | Specific Reason | Classification |
|--------|------|----------------|----------------|
| Rendro.DocsContract.ComparisonClaimsTest | `test/docs_contract/comparison_claims_test.exs` | `System.cmd("mix", ["hex.build"], ...)` — hex.build is not concurrency-safe | **A** |
| Rendro.DocsContract.BrandingClaimsTest | `test/docs_contract/branding_claims_test.exs` | `File.rm(tarball)` cleanup implies hex.build artifact — hex.build invocation | **A** |
| Rendro.DocsContract.LaunchArtifactsClaimsTest | `test/docs_contract/launch_artifacts_claims_test.exs` | `File.rm_rf(tarball)` — hex.build artifact cleanup | **A** |

#### 1c. Residue modules (4 modules, human-read) — from 108-EVIDENCE.md

These 4 modules had no obvious global state by grep; each was human-read and concluded per 108-EVIDENCE.md.

| Module | File | Global State Found? | Phase 108 Conclusion | Classification |
|--------|------|--------------------|-----------------------|----------------|
| Rendro.DocsContract.BrandingContractTest | `test/docs_contract/branding_contract_test.exs` | No `Application.put_env`, no `:telemetry.attach`, no named ETS, no registered process, no `System.cmd`, no `/tmp/` fixed path, no recompile | No direct global state found. `DocsContract.evaluate!/2` compiles/evaluates Elixir code snippets — may involve `Code.eval_string/2`; Phase 110 must verify the evaluator is async-safe before flipping | **A** (current) — Phase 110 `async: true` candidate pending evaluator safety verification |
| Rendro.DocsContract.IntegrationsContractTest | `test/docs_contract/integrations_contract_test.exs` | Named ETS table `:rendro_threadline_calls` accessed via `Mocks.reset_threadline()` in `setup`; operations are PID-keyed but the table itself is a global named resource | `async: false` is justified by the named global ETS table. Borderline case: PID-keying means concurrent ops are safe in practice, but the named table IS global state. Phase 110 may verify full async-safety | **A** — named global ETS table; borderline Phase 110 candidate (requires analysis of PID-key isolation guarantees) |
| Rendro.DocsContract.RecipesContractTest | `test/docs_contract/recipes_contract_test.exs` | No `Application.put_env`, no `:telemetry.attach`, no named ETS, no registered process, no `System.cmd`, no `/tmp/` fixed path, no recompile; module-level `for` comprehension is compile-time only | No observable global state mutation. Same `DocsContract.evaluate!/2` caveat as BrandingContractTest | **A** (current) — Phase 110 `async: true` candidate pending evaluator safety verification |
| Rendro.PublicApi.ManifestTest | `test/rendro/public_api/manifest_test.exs` | `PublicApi.recompile_conditional_adapters()` in both `setup_all` and the test body — global BEAM module recompilation | `async: false` confirmed required. NOT a Phase 110 `async: true` candidate without fundamental redesign of how conditional adapters are probed. Reads `priv/public_api.json` as ground truth; `Mix.Tasks.Rendro.Api.Gen` invocation warrants ongoing review | **A** — `async: false` confirmed required (global BEAM recompile) |

#### 1d. Modules with no explicit `async:` setting (4 modules, default async:false)

These 4 modules omit the `async:` key entirely, defaulting to `async: false` in ExUnit. They are technically uncategorized for Phase 108; Phase 110 should assess each.

| Module | File | Phase 108 Status |
|--------|------|-----------------|
| (root Rendro module test) | `test/rendro_test.exs` | Default async:false; Phase 110 should assess |
| Rendro.ArtifactTest | `test/rendro/artifact_test.exs` | Default async:false; Phase 110 should assess |
| Rendro.EndToEndPipelineTest | `test/rendro/end_to_end_pipeline_test.exs` | Default async:false; Phase 110 should assess |
| Rendro.PDF.PngTest | `test/rendro/pdf/png_test.exs` | Default async:false; Phase 110 should assess |

#### 1e. Slowest tests sub-section

**Source:** `MIX_ENV=test mix test --slowest 20 --seed 0` — local proxy (18 schedulers; not runner-absolute).

| Rank | Test | Module | Duration (local ms) | Phase 108 Classification |
|------|------|--------|---------------------|--------------------------|
| 1 | hex tarball contents built tarball excludes operator-only priv paths | BrandingClaimsTest | 501 | **B** — keep in PR; slowness is `mix hex.build` invocation cost, not test logic (local proxy — 18 schedulers; not runner-absolute) |
| 2 | hex package includes public launch assets | LaunchArtifactsClaimsTest | 440 | **B** — keep in PR; slowness is `mix hex.build` invocation cost (local proxy — 18 schedulers; not runner-absolute) |
| 3 | hex tarball contents built tarball includes branded assets and NOTICE | BrandingClaimsTest | 440 | **B** — keep in PR; slowness is `mix hex.build` invocation cost (local proxy — 18 schedulers; not runner-absolute) |
| 4 | hex package includes comparison guide, notebook, manifest, and raw artifacts | ComparisonClaimsTest | 434 | **B** — keep in PR; slowness is `mix hex.build` invocation cost (local proxy — 18 schedulers; not runner-absolute) |
| 5 | README compile/eval fences are explicit and compile cleanly | ReadmeDoctestTest | 307 | **A** — README doctest compile; necessary correctness gate |
| 6 | full-surface sweep: every :rendro application module is hidden or tagged | PublicApiTest | 214 | **A** — full module sweep; necessary API contract gate |
| 7 | recompile_conditional_adapters/0 after recompile, Rendro.Adapters.Threadline loaded | PublicApiTest | 204 | **A** — adapter recompile proof; necessary for conditional adapter contract |
| 8 | render_id consistency different renders produce different render_ids | TelemetryTest | 202 | **A** — telemetry contract; keep in PR |
| 9 | freshly-generated manifest is byte-identical to priv/public_api.json | ManifestTest | 202 | **A** — API manifest contract; necessary gate |
| 10 | recompile_conditional_adapters/0 returns :ok without error | PublicApiTest | 181 | **A** — adapter recompile proof |
| 11 | recompile_conditional_adapters/0 after recompile, Phoenix has :adapter tier | PublicApiTest | 180 | **A** — adapter recompile proof |
| 12 | validate --strict exits 1 when supported row recorded_at exceeds 180 days | ViewerEvidenceTest | 153 | **A** — viewer evidence contract gate |
| 13 | exception in a stage emits exception event via telemetry.span | TelemetryTest | 111 | **A** — telemetry contract |
| 14 | events fire in pipeline stage order | TelemetryTest | 101 | **A** — telemetry contract |
| 15 | rejects modules that do not implement the protection adapter contract | ProtectTest | 101 | **A** — adapter contract gate |
| 16 | deterministic: true when option set | TelemetryTest | 101 | **A** — telemetry contract |
| 17 | :render stop event fires after :validate stop | TelemetryTest | 101 | **A** — telemetry contract |
| 18 | error in build stage emits stop with status: :error | TelemetryTest | 101 | **A** — telemetry contract |
| 19 | stop event: page_count matches document pages on render stop | TelemetryTest | 101 | **A** — telemetry contract |
| 20 | top-level render stop includes page_count and byte_size | TelemetryTest | 101 | **A** — telemetry contract |

**All local proxy (18 schedulers; not runner-absolute).** On CI (4 schedulers), async tests compress less and sync tests are more representative. The Phase 109 `--slowest` capture via BASE-05 tee will provide runner-accurate numbers.

**Top 5 (DocsContract hex.build tests) classified B:** These are `BrandingClaimsTest`, `LaunchArtifactsClaimsTest`, and `ComparisonClaimsTest`. Slowness is `mix hex.build` invocation cost — not test logic. Phase 109 caching (`deps` + `_build`) will reduce hex.build cost indirectly. Phase 110 (TEST-05) should evaluate whether these can share a hex.build invocation in `setup_all`.

### Category 2: 4 advisory soft-fail jobs

**Jobs:** `raster-advisory`, `comparison-advisory`, `livebook-advisory`, `pdfjs-advisory`

**Classification: C** (all four) — correctly tiered as `continue-on-error: true` advisory jobs. Each requires external binaries (pdfium-cli for raster snapshots, poppler for comparison evidence, Node/npm for pdfjs viewer). These checks are valuable but appropriately do not block PR merge. The current advisory lane is the correct pattern.

- `raster-advisory` (~306s): Requires pdfium-cli; pure snapshot diffing advisory. C — correct as advisory.
- `comparison-advisory` (~155s): Requires poppler; comparison evidence generation. C — correct as advisory.
- `livebook-advisory` (~193s): Livebook notebook evaluation. C — correct as advisory; evaluation can be environment-sensitive.
- `pdfjs-advisory` (~11s, single-run estimate): Added 2026-06-12 (commit 999a0e2); Node-only job (`setup-node`, no `setup-beam`). Timing (11s) from single failed run 37 with hot npm cache — treat as approximate. C — correct as advisory.

**Note:** All four advisory jobs are graph-disconnected (no `needs:`) and run in parallel with `test` from t=0. Their `continue-on-error: true` flag means they never block merge. Phase 111 (FLOW-03) will evaluate whether any of these should move to a nightly/scheduled lane.

### Category 3: 4 live-proof gates

**Jobs:** `signing-live-proof`, `long-lived-live-proof`, `viewer-evidence-live-proof`, `release-proof`

All four `need: test` and are required for merge (no `continue-on-error`).

- **`release-proof` (~599s avg):** **B** — High value (full release-preflight: hex.build --unpack + hex.publish --dry-run); correctly required for merge to catch publishability regressions. However, at ~600s it dominates the PR critical path and makes the wall-clock 16–17 min. Phase 111 topology work (FLOW-01) should rationalize whether release-preflight must gate every PR commit, or only pushes to main / release-candidate branches.

- **`signing-live-proof` (~172s), `long-lived-live-proof` (~174s), `viewer-evidence-live-proof` (~288s):** **C** — Correctly post-`test`-gated (they `need: test`). They require real external tools (pyhanko, pdfium-cli, poppler) and validate live-proof scenarios that are costly to simulate. The current pattern of gating these on `test` completion is correct. Phase 111 (FLOW-01) should evaluate whether all three must gate every PR or whether they could move to a push-to-main gate without meaningfully increasing merge risk.

### Category 4: Pre-existing baseline red-state failures (not flaky — deterministic)

**Source:** `108-EVIDENCE.md` — Bounded Flake Sweep Results, pre-sweep baseline section.

Two pre-existing `mix ci` test failures exist on main at the pre-phase 108 commit. These are NOT introduced by Phase 108 and are NOT flakes:

1. **`Rendro.PublicApiTest` — "full-surface sweep: every :rendro application module is hidden or tagged"** (`test/rendro/public_api_test.exs:106`): `Mix.Tasks.Brand.Gen` is missing a `@moduledoc` tag annotation. Deterministic code gap — fails reproducibly at pre-phase commit. **Phase 110 (TEST-01/04) candidate.**

2. **`RecipesFacadeDriftTest` — "each recipe is reachable as name/1 and name/2 on Rendro.Recipes"** (`test/rendro/recipes_facade_drift_test.exs:16`): Test is `async: true` and calls `function_exported?(Rendro.Recipes, name, 1)`. When seed 0 places this test before any test that loads `Rendro.Recipes` into the BEAM, `function_exported?` returns false. This is a **test ordering / module-loading dependency** — `Rendro.Recipes` is not guaranteed to be loaded before this test runs with certain seeds. CI green runs 34 and 35 use random (non-zero) seeds; other tests load `Rendro.Recipes` first in random order, making CI pass. **Phase 110 (TEST-03) candidate** — fix: add `Code.ensure_loaded!(Rendro.Recipes)` in `setup`, or convert to `async: false` for guaranteed load order.

**Structural guardrail finding (Plan 108-01 tee instrumentation):** `RequiredChecksContractTest` asserts the literal `run: mix ci` lane in ci.yml. The BASE-05 tee instrumentation was kept gate-neutral by using a single-line `run: mix ci 2>&1 | tee` under `shell: bash` (pipefail-by-default). This existing guardrail test means any future `mix ci` decomposition (P0 / P1 in BASE-04) must update `RequiredChecksContractTest` in lockstep. This is a structural constraint on Phase 109 and Phase 111 changes to the `test` job's `Run CI` step.

These two pre-existing failures explain why only 3 of 37 runs are green (the "insufficient green-run data (n=3)" headline) and are Phase 110 (TEST) candidates. They contribute to BASE-03's A classification (both are correctly asserting real contracts; the contract is broken or test design has a gap — not the tests themselves).

### Category 5: Flake-candidacy sweep results

**Source:** `108-EVIDENCE.md` — Bounded Flake Sweep Results.
**Scope:** `mix test --repeat-until-failure 25` × seeds {0, 1, 2}. D-04 ceiling: these results constitute flaky **candidacy** evidence only. They do NOT prove absence of flakiness. Deep proof (50–200× multi-seed) is Phase 110 (TEST-03).

**Seed 0:** 3 deterministic failures on iteration 1 — the 2 pre-existing deterministic failures above + RecipesFacadeDriftTest (seed-0 ordering artifact). `--repeat-until-failure` terminated immediately. No non-deterministic across-iteration failures observed.

**Seed 1:** 2 deterministic failures (the 2 pre-existing failures). RecipesFacadeDriftTest did NOT appear — seed 1 ordering places it after modules are loaded. `--repeat-until-failure` terminated immediately.

**Seed 2:** 2 deterministic failures (the 2 pre-existing failures). Same as seed 1.

**Flaky candidates identified:** NONE — no test exhibited non-deterministic pass/fail behavior across multiple iterations at the same seed. All failures across all three seeds were deterministic and attributable to the known pre-existing gaps.

**Candidacy statement (D-04):** No flaky candidates identified in seeds {0, 1, 2} × 25 repeats. This does NOT constitute proof of absence of flakiness. Deep 50–200× multi-seed proof is deferred to Phase 110 (TEST-03). `RecipesFacadeDriftTest` is not a local env artifact — it reproduces on any machine with seed 0 and is a test design issue (module-loading assumption). Classified separately from flakes above.

### Category 6: E (delete/rewrite) candidates

**Per D-04:** Classification E requires a named artifact — assertion-free filler, a duplicated test path, or implementation-trivia. E is NEVER assigned for being slow alone.

**Copy-paste artifact noted (naming bug, NOT an E candidate):** RESEARCH.md noted a mislabeled `defmodule DocsContractMailglassWrapper.Message` in IntegrationsContractTest. Human-read of `test/docs_contract/integrations_contract_test.exs` found the module correctly named `Rendro.DocsContract.IntegrationsContractTest` — no mislabeled defmodule found in the current file. The artifact may refer to `test/docs_contract/integrations_claims_test.exs` (a different file). Phase 110 should verify this against `integrations_claims_test.exs`. This is a naming bug worth correcting, not a test-quality issue warranting E classification.

**No E (delete/rewrite) candidates identified** — the D-04 evidence floor requires a named artifact (assertion-free filler, duplicated path, or implementation-trivia). No such artifact was identified in this bounded pass. High-signal tests dominate the slow tail (hex.build invocations, manifest generation, telemetry contract verification). The DocsContract tests call real code paths with real assertions. Deep pass deferred to Phase 110 (TEST-04).

---

## BASE-04 — P0–P3 Recommendation Report

**Evidence source:** `108-EVIDENCE.md` + `108-RESEARCH.md`. Each recommendation maps to a requirement ID in `REQUIREMENTS.md` and a target phase in 109–113. Per D-04, no recommendations are implemented in Phase 108 — this is measure-only.

### P0 — Decompose the `mix ci` monolith into parallel named jobs/steps

**Category:** Performance / DX

**Issue:** All of `format → hex.build → compile → test → docs → credo → dialyzer` runs in a single opaque "Run CI" step. This single step is the root anomaly because:
1. The GitHub Actions API cannot see the inner split (forcing local-proxy profiling for BASE-01 — the 327s avg is a local proxy, not a runner-accurate per-step breakdown).
2. Zero parallelism is possible: `format`, `compile`, `test`, `docs`, `credo`, and `dialyzer` could run in parallel groups, but the monolith enforces strict serialization.
3. A `dialyzer` failure retakes 6+ minutes of earlier `format → compile → test` work instead of running independently.
4. BASE-05 job-summary instrumentation (Plan 108-01) is needed NOW because without per-step names there is no per-step timing in the API.

Comparable szTheory sibling repos all decompose: **mailglass** (Format/Compile/Support-Contract jobs), **threadline** (format → credo → compile → test, named steps), **lockspire** (qa/sast/docs/audit/test named jobs). Rendro is the outlier.

**Proposed change:** Split `mix ci` into named steps or jobs. Phase 109 adds `deps`/`_build`/PLT caching as a prerequisite (caching must land first, because named steps sharing a cached `_build` is the efficient pattern). Phase 111 restructures the job topology (named steps within the `test` job, then evaluation of parallel jobs for lint vs. test vs. dialyzer). The decomposition unlocks: (a) per-step timing visible in GitHub Actions API and BASE-05 job summary; (b) foundation for parallelism between lint and test; (c) faster feedback on which stage failed.

**Expected impact:** Per-step timing immediately visible; lint failures (format, credo) caught in ~30s instead of waiting for a full `mix ci` run; foundation for parallelism that could reduce PR feedback time significantly.

**Risk:** Low — decomposition is additive. The monolith can still serialize steps if needed; any step can depend on a prior step. The main risk is the `RequiredChecksContractTest` guardrail (see BASE-03, Category 4) which asserts the literal `run: mix ci` step — this MUST be updated in lockstep with any decomposition.

**Rollback:** Revert the job-topology YAML back to the current single-step `run: mix ci`; revert `RequiredChecksContractTest` assertion.

**Target phase:** 109 (caching prerequisites) + 111 (topology implementation). Maps to: FLOW-01, DX-01, DX-03.

---

### P1 — Add keyed `deps` / `_build` / PLT caching (zero caching currently)

**Category:** Performance

**Issue:** Every job runs `mix deps.get` from scratch and recompiles `_build` fully. No `deps`, `_build`, or Dialyzer PLT cache exists anywhere in the pipeline. The cold-compile cost is replicated across all 9 Elixir jobs per run. Estimated waste: 9 jobs × ~300s compile = ~45 minutes of CI compile time per full run, of which caching could eliminate ~60–70% on warm runs. The `release.yml` also re-runs `mix ci` cold (412s) despite the tag being built from a CI-green SHA.

**Proposed change:** Add `actions/cache` restore/save steps with precise keys (OS + OTP + Elixir + MIX_ENV + `mix.lock` hash + cache-buster). Restore keys allow partial hits. Dialyzer PLT uses a split restore/save pattern so a failing Dialyzer run still persists the PLT (not losing hours of PLT build time on a type-error). `mix deps.get` still runs on cache miss to ensure reproducibility. `_build` is never restored across incompatible OTP/Elixir/MIX_ENV combinations. Cache-bust procedure documented in CONTRIBUTING.

**Expected impact:** Warm-run PR wall-clock for the `test` job estimated to drop by 60–70% (cold compile ~300s → warm compile ~10–20s). Release wall-clock drops similarly. Eliminates the largest single source of CI runner waste.

**Risk:** Stale cache can mask compiler warnings or stale compilation — mitigated by strict key dimensions and always running `mix deps.get` on cache miss. `_build` must never be restored across incompatible OTP/Elixir/MIX_ENV. Broad restore keys (without strict OTP/Elixir dims) are a footgun; the key must include all dimensions listed above.

**Rollback:** Remove `actions/cache` steps; revert to cold-compile. Immediate effect.

**Target phase:** 109. Maps to: CACHE-01, CACHE-02, CACHE-03, CACHE-04, CACHE-05.

---

### P1 — SHA-pin `erlef/setup-beam` in ci.yml and release.yml (inconsistent supply-chain posture)

**Category:** Security

**Issue:** ci.yml and release.yml use floating `erlef/setup-beam@v1`; hexdocs.yml is already SHA-pinned (`erlef/setup-beam@8251c48667b97e88a0a24ec512f5b72a039fcea7 # v1`). A compromised `@v1` tag could inject arbitrary code into all CI runs and all release publishing runs. The inconsistency means the repo has already adopted SHA pinning in one workflow but not the other two — the fix is a one-line change per workflow, not a new practice.

**Proposed change:** Pin ci.yml and release.yml to the same immutable SHA as hexdocs.yml (`8251c48667b97e88a0a24ec512f5b72a039fcea7`). Add Dependabot configuration to auto-update action pins so the SHA stays current without manual tracking.

**Expected impact:** Eliminates supply-chain tampering risk via floating tag for all CI and release runs. Achieves consistent supply-chain posture across all three workflows. Low friction — one-line change per affected workflow.

**Risk:** Very low. SHA pins are standard OSS security posture. Dependabot prevents pin staleness.

**Rollback:** Revert to `@v1` (one-line change per workflow file).

**Target phase:** 112. Maps to: SEC-01, CACHE-04.

---

### P2 — Rationalize `release-proof` job's presence on every PR (critical-path bottleneck)

**Category:** Performance / Reliability

**Issue:** `release-proof` runs on every PR (`needs: test`, no trigger filter) and averages ~599s (~10 min), making it the single biggest contributor to PR wall-clock. It runs `mix release.preflight` (hex.build --unpack + hex.publish --dry-run) in a fresh git worktree — correct for a release check but expensive on every PR commit, including draft PRs, docs-only changes, and WIP pushes.

**Proposed change:** Phase 111 topology audit should evaluate: (1) whether `release-proof` could move to push-to-main only (every merge, not every PR commit), (2) whether it could be triggered only when `mix.exs` or relevant source changes (path filter), (3) whether it can be sped up via caching (Phase 109 caching lands first). Phase 111 makes the final call — the intent of this recommendation is to prompt that evaluation with evidence.

**Expected impact:** If moved to main-only, PR wall-clock drops by ~10 min; critical path becomes START → `test` (~6.5 min) → Tier 2 without `release-proof`. The critical path bottleneck would shift to `viewer-evidence-live-proof` (~288s ≈ 4.8 min), giving a much better PR feedback time.

**Risk:** Medium — must verify the `test` gate alone is sufficient for PR merge confidence and that `release-proof` catches bugs not caught by `test`. Moving it to main-only means a failed release-preflight is caught after merge (though before the release tag). Path filtering is an alternative that preserves PR coverage for source changes while skipping for docs-only.

**Rollback:** Move `release-proof` back to `needs: test` on all PR triggers (one-line trigger change).

**Target phase:** 111. Maps to: FLOW-01, FLOW-03.

---

### P2 — Convert safe `async: false` modules to `async: true` (Phase 110 scope)

**Category:** Performance / Test Quality

**Issue:** 34 explicit `async: false` modules (+ 4 with no explicit `async:` setting). At least 2 residue modules (BrandingContractTest, RecipesContractTest) show no global-state mutation on human read (per BASE-03, Category 1c) and are Phase 110 async:true candidates pending `DocsContract.evaluate!/2` safety verification. IntegrationsContractTest is a borderline candidate (PID-keyed ETS). The 4 modules with no explicit `async:` setting are unreviewed. Keeping safe modules as async:false unnecessarily serializes test execution and wastes the ExUnit concurrent runner.

**Proposed change:** For each module, confirm the async:false reason (cited in BASE-03, Category 1b); flip modules with no real global-state mutation to `async: true` with a documented reason change; document remaining modules per D-04 evidence floor. Phase 110 (TEST-01) owns the full flip pass including the bounded flake sweep (TEST-03) to catch any missed global state.

**Expected impact:** Estimated 3–5% wall-clock reduction on the test suite by increasing ExUnit concurrency. Primarily a test-quality improvement (documented async-reason per module) with a secondary performance benefit.

**Risk:** Low if evidence-based per module. High if flipped blindly — global-state leaks cause intermittent failures. The Phase 108 bounded flake sweep (n=0 candidates) provides a baseline; Phase 110 TEST-03 provides deeper proof.

**Rollback:** Revert `async: true` to `async: false` per module (one-line change per file).

**Target phase:** 110. Maps to: TEST-01, TEST-03.

---

### P3 — Add PR-level concurrency cancellation (superseded-run waste)

**Category:** Performance / DX

**Issue:** No `concurrency:` group is defined in ci.yml. Pushing a second commit to a PR triggers a new full CI run while the previous run is still in progress — burning runner minutes (16–17 min of work × number of concurrent pushes) and producing a stale red/green signal from the superseded run. This is a common waste pattern in active development branches.

**Proposed change:** Add `concurrency` block at the workflow level:
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
```
Ensure push-to-main and release/tag runs are excluded from cancellation by scoping the group to `pull_request.number` (which is null for non-PR events, falling back to `github.ref`). Push to `main` and tag pushes are thus in their own unique groups and are not cancelled.

**Expected impact:** Eliminates wasted runner minutes on superseded PR commits. Reduces GitHub Actions queue buildup. Provides faster signal by surfacing only the latest commit's result, not stale mid-flight runs.

**Risk:** Low. Well-understood GitHub Actions pattern. Must not cancel main or release runs — the group scoping above prevents this. Must verify with the `release-proof` timeout-45min job that long-running jobs are not accidentally cancelled on main.

**Rollback:** Remove the `concurrency:` block.

**Target phase:** 111. Maps to: FLOW-02.

---

### P3 — Dependency / security audit lane (`mix hex.audit` / `mix deps.audit`)

**Category:** Security / DX

**Issue:** No dependency audit runs in CI. Known-vulnerable Hex dependencies would not be flagged automatically. `mix hex.audit` and `mix deps.audit` (via `mix_audit`) are the idiomatic Elixir tools for this. Running them in the PR fast path is wrong — they make network calls and can flake on transient registry issues.

**Proposed change:** Add a `scheduled` workflow (nightly or weekly) that runs `mix hex.audit` and optionally `mix deps.audit`. This decouples CVE detection from the PR fast path, avoiding false reds caused by network flakiness. The nightly lane is the correct tier for network-dependent security scans (consistent with §6.1 recommended trigger model in C1-AUDIT-BRIEF.md).

**Expected impact:** Automated CVE detection for Hex dependencies. Nightly notification of newly-published advisories for pinned dependencies.

**Risk:** Low. Network-dependent — correct to schedule, not PR-gate. `mix hex.audit` is read-only and safe.

**Rollback:** Remove the audit step from the scheduled workflow.

**Target phase:** 112. Maps to: SEC-04.

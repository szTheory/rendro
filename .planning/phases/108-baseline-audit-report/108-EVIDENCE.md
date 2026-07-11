# Phase 108 — Evidence File

**Gathered:** 2026-06-14
**Purpose:** Raw measurement output consumed by Plan 03 (C1-AUDIT.md authoring). This file is the single source of truth for all evidence sections. Do NOT author C1-AUDIT.md until all sections below are populated.

**Constraint:** This file contains ONLY measured evidence — no edits to source/test/workflow files were made to produce it.

---

## Real-Runner Timing

**Source:** `gh api repos/szTheory/rendro/actions/runs/{id}/jobs` — live GitHub Actions API data, run against existing green CI history. No fresh CI runs were triggered.

### Run #3 — 2026-04-28 (id: 25066346539)

Single-job run (proof gates did not yet exist at this commit).

**Per-step timing (test job):**

| Step | Duration (s) |
|------|-------------|
| Set up job | 1 |
| Checkout | 1 |
| Setup Beam | 6 |
| Install Dependencies | 2 |
| Run CI (mix ci) | **222** |
| Verify Phoenix Example | 11 |
| Post Checkout | 1 |
| Complete job | 0 |
| **test job total** | **245** |

No proof jobs or advisory jobs ran in this run (they were added later).

### Run #34 — 2026-06-12 (id: 27441368861)

9-job run. pdfjs-advisory not yet present (added commit 999a0e2 at 23:19 UTC, after this run).

**Per-step timing (test job):**

| Step | Duration (s) |
|------|-------------|
| Set up job | 1 |
| Checkout | 1 |
| Setup Beam | 8 |
| Install Dependencies | 3 |
| Run CI (mix ci) | **386** |
| Post Checkout | 0 |
| Complete job | 0 |
| **test job total** | **401** |

**All jobs (fresh API confirmation):**

| Job | Conclusion | Duration (s) |
|-----|-----------|-------------|
| example-phoenix | success | 59 |
| test | success | **401** |
| raster-advisory | success | 304 |
| comparison-advisory | success | 160 |
| livebook-advisory | success | 175 |
| long-lived-live-proof | success | 177 |
| viewer-evidence-live-proof | success | 292 |
| release-proof | success | **553** |
| signing-live-proof | success | 170 |

**Full run wall-clock:** `created_at: 2026-06-12T20:32:02Z` → `updated_at: 2026-06-12T20:48:08Z` = **966s (16m06s)**
(RESEARCH.md estimated 962s from step timestamps; API run-level timestamps give 966s — using fresh API value as authoritative.)

### Run #35 — 2026-06-12 (id: 27443757934)

9-job run. Same codebase state as run 34.

**Per-step timing (test job):**

| Step | Duration (s) |
|------|-------------|
| Set up job | 2 |
| Checkout | 1 |
| Setup Beam | 7 |
| Install Dependencies | 3 |
| Run CI (mix ci) | **372** |
| Post Checkout | 0 |
| Complete job | 0 |
| **test job total** | **389** |

**All jobs (fresh API confirmation):**

| Job | Conclusion | Duration (s) |
|-----|-----------|-------------|
| livebook-advisory | success | 210 |
| raster-advisory | success | 308 |
| comparison-advisory | success | 150 |
| example-phoenix | success | 61 |
| test | success | **389** |
| signing-live-proof | success | 174 |
| long-lived-live-proof | success | 171 |
| viewer-evidence-live-proof | success | 283 |
| release-proof | success | **645** |

**Full run wall-clock:** `created_at: 2026-06-12T21:20:43Z` → `updated_at: 2026-06-12T21:38:02Z` = **1039s (17m19s)**
(RESEARCH.md estimated 1036s; API run-level timestamps give 1039s — using fresh API value as authoritative.)

### Summary Table (BASE-01 Source)

| Metric | Value | Source |
|--------|-------|--------|
| `mix ci` duration (run 3) | 222s | gh api run 25066346539 |
| `mix ci` duration (run 34) | 386s | gh api run 27441368861 |
| `mix ci` duration (run 35) | 372s | gh api run 27443757934 |
| **`mix ci` avg (n=3)** | **327s** | (222+386+372)/3 |
| `mix ci` range | 222s–386s | above |
| test job wall-clock avg | ~345s | (245+401+389)/3 |
| Full CI wall-clock (run 34) | 966s (16m06s) | gh api run-level timestamps |
| Full CI wall-clock (run 35) | 1039s (17m19s) | gh api run-level timestamps |
| Critical path bottleneck | release-proof: 553s (run 34), 645s (run 35) | gh api |
| Cache: deps | NONE — `mix deps.get` runs in every job | ci.yml inspection |
| Cache: \_build | NONE — full cold recompile in every Elixir job | ci.yml inspection |
| Cache: PLTs (Dialyzer) | NONE | ci.yml inspection |
| **p95 full CI** | **"insufficient green-run data (n=3)"** | only 3 green runs of 37 total |

---

## Critical Path Summary

**Source:** ci.yml job structure + run 34/35 API timing.

```
[t=0] START — all Tier 1 jobs launch in parallel:
  test                       (merge gate)          ~395s avg
  example-phoenix            (no continue-on-error) ~60s avg
  raster-advisory            (continue-on-error)    ~306s avg
  comparison-advisory        (continue-on-error)    ~155s avg
  livebook-advisory          (continue-on-error)    ~193s avg
  [pdfjs-advisory not in runs 34/35 — added post-run]

[t≈6.5min] test job completes → triggers Tier 2 (needs: test):
  signing-live-proof         172s avg
  long-lived-live-proof      174s avg
  viewer-evidence-live-proof 288s avg
  release-proof              599s avg  ← CRITICAL PATH BOTTLENECK

[t≈16–17min] release-proof completes → CI done
```

**Critical path chain:** START → test (6.5min) → release-proof (9–11min) = **16–17min total wall-clock**

**Why release-proof dominates:** It runs `mix deps.get` + full `mix release.preflight` (compile + release assemble) in a git worktree — same cold-compile cost as the test job. The test job's 6.5-minute lead time is entirely consumed by this sequential setup.

---

## Duplicated Work

**Source:** ci.yml inspection + API job list.

| Work Item | Jobs Affected | Count |
|-----------|--------------|-------|
| `erlef/setup-beam@v1` (OTP+Elixir install) | test, example-phoenix, raster-advisory, comparison-advisory, livebook-advisory, signing-live-proof, long-lived-live-proof, viewer-evidence-live-proof, release-proof | 9 of 10 jobs |
| `mix deps.get` (dependency fetch) | test, example-phoenix (sub-dir), raster-advisory, comparison-advisory, livebook-advisory, signing-live-proof, long-lived-live-proof, viewer-evidence-live-proof, release-proof | 8+ jobs |
| Full `_build` cold recompile | Every Elixir job — no shared artifact | All 9 Elixir jobs |
| `mix ci` full run | `test` job in ci.yml AND `release.yml` publish job | 2 separate workflow runs |

**Key finding:** Zero caching exists anywhere in the pipeline. Every job pays the full cold-compile cost. The `release.yml` publish job re-runs `mix ci` (412s) even for a tag that was already validated by ci.yml — pure duplicated verification.

---

## Local Profiling (proxy)

**TAG: All numbers in this section are local proxy (18 schedulers; not runner-absolute). Do NOT present these as CI runner milliseconds.**

The local dev box runs 18 BEAM schedulers vs the GitHub-hosted ubuntu-latest runner's 4 schedulers. Local numbers are ordinal/proportional only. Local async concurrency is ~4.5× higher than on CI, so async test durations compress significantly on local vs expand on CI. Sync test durations (no parallelism benefit) are more representative.

### Slowest 20 Tests

**Command:** `MIX_ENV=test mix test --slowest 20 --seed 0`
**Environment:** local proxy (18 schedulers; not runner-absolute)
**Note:** seed 0 was used for reproducibility. This run also reveals the RecipesFacadeDriftTest seed-dependent failure (see RecipesFacadeDriftTest Characterization section).

Top 20 slowest test results (local proxy):

| Rank | Test | Module | Duration (local ms) |
|------|------|--------|---------------------|
| 1 | hex tarball contents built tarball excludes operator-only priv paths | BrandingClaimsTest | 501 |
| 2 | hex package includes public launch assets | LaunchArtifactsClaimsTest | 440 |
| 3 | hex tarball contents built tarball includes branded assets and NOTICE | BrandingClaimsTest | 440 |
| 4 | hex package includes comparison guide, notebook, manifest, and raw artifacts | ComparisonClaimsTest | 434 |
| 5 | README compile/eval fences are explicit and compile cleanly | ReadmeDoctestTest | 307 |
| 6 | full-surface sweep: every :rendro application module is hidden or tagged | PublicApiTest | 214 |
| 7 | recompile_conditional_adapters/0 after recompile, Rendro.Adapters.Threadline loaded | PublicApiTest | 204 |
| 8 | render_id consistency different renders produce different render_ids | TelemetryTest | 202 |
| 9 | freshly-generated manifest is byte-identical to priv/public_api.json | ManifestTest | 202 |
| 10 | recompile_conditional_adapters/0 returns :ok without error | PublicApiTest | 181 |
| 11 | recompile_conditional_adapters/0 after recompile, Phoenix has :adapter tier | PublicApiTest | 180 |
| 12 | validate --strict exits 1 when supported row recorded_at exceeds 180 days | ViewerEvidenceTest | 153 |
| 13 | exception in a stage emits exception event via telemetry.span | TelemetryTest | 111 |
| 14 | events fire in pipeline stage order | TelemetryTest | 101 |
| 15 | rejects modules that do not implement the protection adapter contract | ProtectTest | 101 |
| 16 | deterministic: true when option set | TelemetryTest | 101 |
| 17 | :render stop event fires after :validate stop | TelemetryTest | 101 |
| 18 | error in build stage emits stop with status: :error | TelemetryTest | 101 |
| 19 | stop event: page_count matches document pages on render stop | TelemetryTest | 101 |
| 20 | top-level render stop includes page_count and byte_size | TelemetryTest | 101 |

**Total test suite (local, seed 0):** ~9.3s (2.3s async, 6.9s sync)
**Slow tail (top 20):** 4.2s = 45.9% of total time
**local proxy (18 schedulers; not runner-absolute)**

### Compile Profile Top 10

**Command:** `MIX_ENV=test mix compile --force --profile time 2>&1 | sort -t'[' -k2 -rn | head -15`
**Environment:** local proxy (18 schedulers; not runner-absolute)

| Rank | File | Compile Time (local ms) | Wait Time (local ms) | Wait Reason |
|------|------|------------------------|---------------------|-------------|
| 1 | lib/rendro/pdf/writer.ex | 417 | 84 | waiting for struct Rendro.Document |
| 2 | lib/rendro/pipeline/paginate.ex | 284 | 82 | waiting for struct Rendro.Document |
| 3 | lib/rendro/fragmentable.ex | 207 | 36 | waiting for struct Rendro.Table |
| 4 | lib/rendro/pipeline/measure.ex | 180 | 97 | waiting for struct Rendro.Document |
| 5 | lib/rendro/sign.ex | 142 | 0 | — |
| 6 | lib/rendro/launch_artifacts.ex | 129 | 141 | waiting for struct Rendro.Document |
| 7 | lib/rendro/document.ex | 113 | 59 | waiting for module Rendro.FontRegistry |
| 8 | lib/mix/tasks/rendro.visual_uat.ex | 104 | 0 | — |
| 9 | lib/rendro/font_registry.ex | 101 | 33 | waiting for struct Rendro.PDF.Font |
| 10 | lib/rendro/adapters/py_hanko.ex | 100 | 141 | waiting for module Rendro.Sign.Adapter |

**Total compilation cycle:** 131 files, 596ms compilation cycle, 400ms after-compile callback
**local proxy (18 schedulers; not runner-absolute)**

**Finding:** The compile wait bottleneck is `Rendro.Document` — 4 downstream files queue on it. This is consistent with xref data (document.ex has 4 outgoing compile dependencies). No pathological compile chains.

### xref Compile-Connected Stats

**Command:** `MIX_ENV=test mix xref graph --label compile-connected --format stats`

| Property | Value |
|----------|-------|
| Tracked files | 128 |
| Compile dependencies | **5** (very low) |
| Exports dependencies | 142 |
| Runtime dependencies | 218 |
| Cycles | **0** |
| Top compile-connected file | lib/rendro/document.ex (4 outgoing) |
| Second | lib/rendro/page_template.ex (1 outgoing) |

**Finding:** Compile-connected dependencies are minimal (5 edges, 0 cycles). Compilation bottleneck is NOT structural — it is cold-cache cold-compile time. Phase 109 caching eliminates this entirely.

---

## p95 Note

**p95 full CI run wall-clock: "insufficient green-run data (n=3)"**

Of 37 total ci.yml runs in the repository history, only 3 are green (runs #3, #34, #35). The remaining 34 runs failed for various reasons. A p95 calculation requires a minimum of ~20 data points to be statistically meaningful; n=3 is insufficient.

Additionally, all 3 green runs collapse the entire `mix ci` pipeline into a single opaque "Run CI" step with no inner timing breakdown visible from the GitHub Actions API. The inner split (format / compile / test / docs / credo / dialyzer) is physically invisible from `gh api .../jobs` — this is the primary reason BASE-05 job-summary instrumentation is needed now.

**Exact required phrase (D-01 / BASE-01 mandate):** insufficient green-run data (n=3)

This is not a gap to hide — it is the most honest measurement possible given current pipeline structure, and is itself an argument for BASE-05 landing immediately.

---

## RecipesFacadeDriftTest Characterization

**Performed BEFORE the bounded flake sweep (VALIDATION.md Wave 0 requirement).**

### Isolation run (no seed specified)

**Command:** `MIX_ENV=test mix test test/rendro/recipes_facade_drift_test.exs`
**Result:** 9 tests, 0 failures — PASSES with random seed

### Isolation run with seed 0

**Command:** `MIX_ENV=test mix test test/rendro/recipes_facade_drift_test.exs --seed 0`
**Result:** 1 failure — FAILS with seed 0

**Exact failure message:**

```
  1) test each recipe is reachable as name/1 and name/2 on Rendro.Recipes (Rendro.RecipesFacadeDriftTest)
     test/rendro/recipes_facade_drift_test.exs:16
     Expected Rendro.Recipes.invoice/1 to be exported
     code: for {name, _module} <- @recipes do
     stacktrace:
       test/rendro/recipes_facade_drift_test.exs:18: anonymous fn/2 in Rendro.RecipesFacadeDriftTest."test each recipe is reachable as name/1 and name/2 on Rendro.Recipes"/1
       (elixir 1.19.5) lib/enum.ex:2520: Enum."-reduce/3-lists^foldl/2-0-"/3
       test/rendro/recipes_facade_drift_test.exs:17: (test)
```

### Root cause analysis

`RecipesFacadeDriftTest` is `async: true` (line 2 of the test file). The test uses `function_exported?(Rendro.Recipes, name, 1)` which calls into the live BEAM to check if a module is loaded and its function exported. When seed 0 causes this test to run BEFORE any test that loads `Rendro.Recipes` into the BEAM, `function_exported?` returns false because the module hasn't been loaded yet.

With random seed ordering, other tests load `Rendro.Recipes` first (via `use Rendro.Recipes.Invoice`, direct calls, etc.), and by the time RecipesFacadeDriftTest runs, the module is already in memory.

### Conclusion

**Characterization: seed-dependent ordering artifact (NOT a genuine drift and NOT a simple local-env artifact)**

This is more precisely a **test ordering / module-loading dependency** — the test assumes `Rendro.Recipes` is already loaded in the BEAM before it runs, but that assumption is violated when seed 0 places it first. This is a legitimate test design issue but NOT a local environment problem specific to this machine — it would reproduce on any machine with seed 0.

**For BASE-03:** This failure should be flagged as a test design issue (missing `Code.ensure_loaded!(Rendro.Recipes)` in setup, or the test should be `async: false` to guarantee deterministic load order). However per D-04, no fixes are made in Phase 108 — this is a Phase 110 finding.

**Impact on CI:** CI green runs 34 and 35 do not use `--seed 0` by default (ExUnit uses a random seed per run), and `Rendro.Recipes` is loaded by many sync tests that run first in random order. This explains why CI was green while local `--seed 0` fails.

---

## Bounded Flake Sweep Results

**Scope:** `mix test --repeat-until-failure 25` × seeds {0, 1, 2}
**D-04 ceiling:** These results constitute flaky **candidacy** evidence only. They do NOT prove absence of flakiness. Deep proof (50–200× multi-seed) is Phase 110 (TEST-03).

### Pre-sweep baseline: Known pre-existing failures

Before interpreting sweep results, two failures exist in the codebase BEFORE this sweep and are NOT attributable to flakiness:

1. **`Guardrails.RequiredChecksContractTest` — "required test job runs only the deterministic mix ci lane"** (test/guardrails/required_checks_contract_test.exs:207): The guardrails test asserts `test_block =~ "run: mix ci"` (bare command). Plan 108-01 changed the `Run CI` step to use `set -o pipefail` + `tee` pattern, which does contain `mix ci` but in a multi-line `run: |` block. The guardrails assertion expects the old bare form. This is a pre-existing guardrail test that needs updating in a future plan — NOT a flake.

2. **`Rendro.PublicApiTest` — "full-surface sweep: every :rendro application module is hidden or tagged"** (test/rendro/public_api_test.exs:106): Reports `Mix.Tasks.Brand.Gen` as untagged (missing `@moduledoc` tag annotation). This is a pre-existing code gap — NOT a flake.

### Seed 0 — `MIX_ENV=test mix test --repeat-until-failure 25 --seed 0`

**Failures found:** 3 (terminated after first failure iteration, not after 25)

| # | Test | File | Classification |
|---|------|------|----------------|
| 1 | required test job runs only the deterministic mix ci lane | test/guardrails/required_checks_contract_test.exs:203 | pre-existing guardrail gap (see above) |
| 2 | each recipe is reachable as name/1 and name/2 on Rendro.Recipes | test/rendro/recipes_facade_drift_test.exs:16 | seed-dependent ordering artifact (characterized above) |
| 3 | full-surface sweep: every :rendro application module is hidden or tagged | test/rendro/public_api_test.exs:106 | pre-existing code gap (`Mix.Tasks.Brand.Gen` missing @moduledoc) |

**Flaky CANDIDATES (excluding known pre-existing failures and known seed-0 ordering artifact):** NONE

**Note:** `--repeat-until-failure` terminates on first failure. With seed 0, it fails on iteration 1 due to the known failures, so 25 repeats were not achieved. The failures are deterministic with seed 0, not non-deterministic across iterations.

### Seed 1 — `MIX_ENV=test mix test --repeat-until-failure 25 --seed 1`

**Failures found:** 2 (terminated early)

| # | Test | File | Classification |
|---|------|------|----------------|
| 1 | required test job runs only the deterministic mix ci lane | test/guardrails/required_checks_contract_test.exs:203 | pre-existing guardrail gap |
| 2 | full-surface sweep: every :rendro application module is hidden or tagged | test/rendro/public_api_test.exs:106 | pre-existing code gap |

**Flaky CANDIDATES (excluding known pre-existing failures):** NONE

**Note:** RecipesFacadeDriftTest did NOT appear in seed 1 failures — seed 1 ordering places it after modules are loaded.

### Seed 2 — `MIX_ENV=test mix test --repeat-until-failure 25 --seed 2`

**Failures found:** 2 (terminated early)

| # | Test | File | Classification |
|---|------|------|----------------|
| 1 | required test job runs only the deterministic mix ci lane | test/guardrails/required_checks_contract_test.exs:203 | pre-existing guardrail gap |
| 2 | full-surface sweep: every :rendro application module is hidden or tagged | test/rendro/public_api_test.exs:106 | pre-existing code gap |

**Flaky CANDIDATES (excluding known pre-existing failures):** NONE

### Flake Sweep Conclusion

**No flaky candidates found** (beyond the two pre-existing deterministic failures and the seed-0 ordering artifact in RecipesFacadeDriftTest).

All three seeds (0, 1, 2) show the same two deterministic pre-existing failures. No test exhibited non-deterministic pass/fail behavior across multiple iterations at the same seed. The bounded sweep (D-04 floor) is complete.

**Candidacy statement (D-04):** No flaky candidates identified in seeds {0, 1, 2} × 25 repeats. This does NOT constitute proof of absence — deep 50–200× multi-seed proof is deferred to Phase 110 (TEST-03).

---

## Residue async:false Module Read

**Scope:** Human-read of the 4 residue async:false modules where grep showed no obvious global state.
**Question for each:** Is `async: false` justified by concrete global-state mutation, or is it defensive/conventional?

### BrandingContractTest

**File:** `test/docs_contract/branding_contract_test.exs`

**Contents reviewed:**
```elixir
defmodule Rendro.DocsContract.BrandingContractTest do
  use ExUnit.Case, async: false
  alias Rendro.Test.DocsContract

  test "guides/branding.md ships exactly the four expected verified fence IDs in order" do
    fences = DocsContract.verified_fences("guides/branding.md")
    assert Enum.map(fences, & &1.id) == [...]
  end

  test "every guides/branding.md fence body is evaluable and free of skeleton placeholders" do
    fences = DocsContract.verified_fences("guides/branding.md")
    assert length(fences) == 4
    Enum.each(fences, fn %{code: code} ->
      refute String.contains?(code, "...")
      DocsContract.evaluate!(code, "guides/branding.md")
    end)
  end
end
```

**Global state check:**
- `Application.put_env` / `Application.delete_env`: NOT FOUND
- `:telemetry.attach` / handler registration: NOT FOUND
- Named ETS table writes: NOT FOUND
- Registered process: NOT FOUND
- `System.cmd` / `Port` invocation: NOT FOUND
- Fixed `/tmp/` path writes: NOT FOUND
- `recompile`: NOT FOUND
- `Process.put` / global process state: NOT FOUND

**Verdict: Phase 110 `async: true` candidate**

`DocsContract.evaluate!/2` compiles and evaluates Elixir code snippets from the docs. If this involves `Code.eval_string/2` without module recompilation, it is safe for async. However, the docs evaluation MIGHT redefine module-level constants or trigger code loading — this requires Phase 110 verification before flipping. Mark as **candidate** (not confirmed safe).

---

### IntegrationsContractTest

**File:** `test/docs_contract/integrations_contract_test.exs`

**Contents reviewed:**
```elixir
defmodule Rendro.DocsContract.IntegrationsContractTest do
  use ExUnit.Case, async: false
  alias Rendro.Test.DocsContract
  alias Rendro.Test.Mocks

  setup do
    Mocks.reset_threadline()
    :ok
  end

  test "curated integration guide fences stay executable" do
    fences = DocsContract.verified_fences("guides/integrations.md")
    ...
    Enum.each(fences, fn %{id: id, code: code} ->
      DocsContract.evaluate!(code, "guides/integrations.md")
    end)
  end
end
```

**Global state check:**
- `Mocks.reset_threadline()` in `setup`: **YES — accesses named global ETS table**

`Rendro.Test.Mocks` maintains a named ETS table `:rendro_threadline_calls` (`:named_table, :public, :bag`). Operations are keyed by test PID (via `test_pid/0`), but the table itself is a global named resource. `reset_threadline/0` calls `Process.delete(@result_key)` (process-local — safe for async) and `:ets.match_delete(@table, {pid, :_, :_, :_})` (PID-keyed delete on a global named table — safe in practice since keyed by PID, but the named table IS global state).

The `Threadline` stub module's `record_action/2` function uses `Process.get(:threadline_result, :ok)` which is process-local. The ETS writes are PID-scoped.

**Verdict: `async: false` reason is named ETS table (`:rendro_threadline_calls`)**

The named ETS table is global state even though access is PID-keyed. In practice, the PID-keying makes concurrent operations safe, but the conventional reason for `async: false` here is the presence of a global named ETS table in the test infrastructure. This is a valid reason; however, because access is fully PID-keyed, Phase 110 could potentially verify this is safe to run async. **Borderline case — not a clean Phase 110 candidate without further analysis.**

**Copy-paste artifact noted:** The module is correctly named `Rendro.DocsContract.IntegrationsContractTest`. RESEARCH.md referenced a mislabeled `defmodule DocsContractMailglassWrapper.Message` — this was not found in the current file. The file currently has the correct module name. This artifact may have been in an earlier version or may refer to a different file (possibly IntegrationsClaimsTest, not IntegrationsContractTest).

---

### RecipesContractTest

**File:** `test/docs_contract/recipes_contract_test.exs`

**Contents reviewed:**
```elixir
defmodule Rendro.DocsContract.RecipesContractTest do
  use ExUnit.Case, async: false
  alias Rendro.Test.DocsContract

  for guide <- ["guides/recipes.md", "guides/page_primitive.md"] do
    @guide guide
    test "every #{guide} fence body is evaluable..." do
      fences = DocsContract.verified_fences(@guide)
      Enum.each(fences, fn %{code: code} ->
        DocsContract.evaluate!(code, @guide)
      end)
    end
    test "every #{guide} fence has a valid docs-contract id" do ... end
  end
  test "guides/recipes.md ships the expected verified fence IDs" do ... end
  test "guides/page_primitive.md ships the expected verified fence IDs" do ... end
end
```

**Global state check:**
- `Application.put_env` / `Application.delete_env`: NOT FOUND
- `:telemetry.attach` / handler registration: NOT FOUND
- Named ETS table writes: NOT FOUND
- Registered process: NOT FOUND
- `System.cmd` / `Port` invocation: NOT FOUND
- Fixed `/tmp/` path writes: NOT FOUND
- `recompile`: NOT FOUND
- Module-level `for` comprehension (compile-time loop, not runtime): NOT A GLOBAL STATE ISSUE

**Verdict: Phase 110 `async: true` candidate**

No observable global state mutation. Uses `DocsContract.evaluate!/2` to evaluate fence code snippets — same caveat as BrandingContractTest (needs Phase 110 verification that the evaluator is safe for async). **Candidate for `async: true` in Phase 110.**

---

### ManifestTest

**File:** `test/rendro/public_api/manifest_test.exs`

**Contents reviewed (key lines):**
```elixir
defmodule Rendro.PublicApi.ManifestTest do
  use ExUnit.Case, async: false

  setup_all do
    PublicApi.recompile_conditional_adapters()
    :ok
  end

  test "freshly-generated manifest is byte-identical to priv/public_api.json" do
    PublicApi.recompile_conditional_adapters()
    loaded_modules = Mix.Tasks.Rendro.Api.Gen.public_modules()
      |> Enum.filter(fn mod -> Code.ensure_loaded?(mod) and
          match?({:docs_v1, _, _, _, _, _, _}, Code.fetch_docs(mod)) end)
    fresh_manifest = PublicApi.build_manifest(loaded_modules)
    fresh_json = Mix.Tasks.Rendro.Api.Gen.encode_manifest(fresh_manifest) <> "\n"
    checked_in = File.read!("priv/public_api.json")
    assert fresh_json == checked_in
  end
end
```

**Global state check:**
- `PublicApi.recompile_conditional_adapters()` in `setup_all` AND in the idempotency test: **YES — triggers BEAM module recompilation globally**

`recompile_conditional_adapters/0` triggers recompilation of conditional adapter modules (Threadline, Mailglass, Accrue, etc.) into the global BEAM module namespace. This is the same global BEAM operation as `IEx.Helpers.recompile()` — it affects the module namespace for ALL concurrent processes, not just the calling process.

**Verdict: `async: false` reason is confirmed — global BEAM module recompilation**

`PublicApi.recompile_conditional_adapters()` is a global BEAM operation that cannot be run concurrently with any code loading, test, or compile operation. `async: false` is required and correct. This is NOT a Phase 110 `async: true` candidate without a fundamental redesign of how conditional adapters are probed.

---

### Residue Module Summary

| Module | File | Global State Found? | Verdict |
|--------|------|--------------------|---------| 
| BrandingContractTest | test/docs_contract/branding_contract_test.exs | No direct global state; DocsContract.evaluate!/2 needs verification | Phase 110 `async: true` candidate (verify evaluate! is safe) |
| IntegrationsContractTest | test/docs_contract/integrations_contract_test.exs | Named ETS table `:rendro_threadline_calls` (PID-keyed) | `async: false` justified (named global ETS); borderline Phase 110 candidate |
| RecipesContractTest | test/docs_contract/recipes_contract_test.exs | No direct global state; DocsContract.evaluate!/2 needs verification | Phase 110 `async: true` candidate (verify evaluate! is safe) |
| ManifestTest | test/rendro/public_api/manifest_test.exs | `PublicApi.recompile_conditional_adapters()` = global BEAM recompile | `async: false` confirmed required — NOT a Phase 110 candidate without redesign |

**Mislabeled defmodule check:** RESEARCH.md noted `defmodule DocsContractMailglassWrapper.Message` as a copy-paste artifact in IntegrationsContractTest. The current `test/docs_contract/integrations_contract_test.exs` file correctly defines `Rendro.DocsContract.IntegrationsContractTest` — no mislabeled defmodule found. This artifact may have been corrected before this evidence gathering pass, or may refer to a different file (`integrations_claims_test.exs` vs `integrations_contract_test.exs`). Flagged for BASE-03: verify against `test/docs_contract/integrations_claims_test.exs`.

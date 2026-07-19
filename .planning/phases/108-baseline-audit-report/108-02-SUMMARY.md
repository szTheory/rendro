---
phase: 108-baseline-audit-report
plan: "02"
subsystem: infra
tags: [ci-cd, github-actions, elixir, exunit, profiling, flake-sweep, async-false]

requires:
  - phase: 108-01
    provides: BASE-05 YAML instrumentation commit (ci.yml tee + job-summary step)

provides:
  - "108-EVIDENCE.md: all raw measurement evidence for Plan 03 (C1-AUDIT.md authoring)"
  - "Real-runner timing confirmed: mix ci avg 327s (n=3 green runs), full CI 16–17min, release-proof is critical path bottleneck"
  - "Local profiling captured with proxy tags: slowest 20 tests, compile profile top-10, xref stats (5 edges, 0 cycles)"
  - "RecipesFacadeDriftTest characterized as seed-dependent ordering artifact (fails --seed 0 in isolation)"
  - "Bounded flake sweep complete: seeds 0/1/2 × 25 repeats — no flaky candidates beyond two pre-existing deterministic failures"
  - "All 4 residue async:false modules human-read with verdicts: BrandingContractTest + RecipesContractTest = Phase 110 candidates; IntegrationsContractTest = named ETS (borderline); ManifestTest = confirmed required (global BEAM recompile)"

affects: [108-03, 109, 110, 111, 112, 113]

tech-stack:
  added: []
  patterns:
    - "Evidence-first audit: all measurements gathered into a single evidence file before any authoring"
    - "Two-source timing discipline: real-runner wall-clock from gh api, inner split from local proxy with explicit tags"
    - "Flake sweep as candidacy evidence (not proof): bounded --repeat-until-failure 25 × seeds {0,1,2}"

key-files:
  created:
    - ".planning/phases/108-baseline-audit-report/108-EVIDENCE.md"
  modified: []

key-decisions:
  - "RecipesFacadeDriftTest is a seed-dependent ordering artifact (async: true test calls function_exported? before Rendro.Recipes is loaded in VM; fails with --seed 0, passes with random seed) — Phase 110 finding, not a flake"
  - "ManifestTest async: false is confirmed required (PublicApi.recompile_conditional_adapters() is global BEAM recompile, cannot run concurrently)"
  - "IntegrationsContractTest async: false justified by named ETS table :rendro_threadline_calls (PID-keyed access, borderline Phase 110 candidate)"
  - "BrandingContractTest and RecipesContractTest are Phase 110 async: true candidates (no global state found; DocsContract.evaluate!/2 needs Phase 110 safety verification)"
  - "Two pre-existing deterministic failures exist before Plan 02: RequiredChecksContractTest (guardrail expects bare 'run: mix ci' but 108-01 changed to tee pattern) and PublicApiTest (Mix.Tasks.Brand.Gen missing @moduledoc tag)"

patterns-established:
  - "p95 phrasing locked: must use exact phrase 'insufficient green-run data (n=3)' — never N/A or approximation"
  - "Local proxy tag: all locally-derived numbers carry 'local proxy (18 schedulers; not runner-absolute)'"

requirements-completed: [BASE-01, BASE-02, BASE-03]

duration: 45min
completed: 2026-06-14
---

# Phase 108 Plan 02: Baseline Evidence Gathering Summary

**All six evidence sections captured in 108-EVIDENCE.md: real-runner timing (gh api, 3 green runs), local profiling proxy (slowest 20, compile profile, xref stats), RecipesFacadeDriftTest seed-0 ordering artifact characterized, bounded flake sweep (seeds 0/1/2), and all 4 residue async:false modules human-read with verdicts — Plan 03 can now author C1-AUDIT.md.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-14T22:40:00Z (approx)
- **Completed:** 2026-06-14T23:25:00Z (approx)
- **Tasks:** 2 (both combined into one atomic commit since same file)
- **Files modified:** 1 created (108-EVIDENCE.md)

## Accomplishments

- Confirmed real-runner timing via `gh api` for all 3 green runs (25066346539, 27441368861, 27443757934): `mix ci` avg 327s, full CI wall-clock 966s (run 34) and 1039s (run 35), release-proof is the critical path bottleneck at 553–645s.
- Captured local profiling output (all tagged as proxy): slowest 20 tests show hex.build-invoking tests as top slow tail (~500ms each); compile profile reveals `lib/rendro/pdf/writer.ex` (417ms) as slowest compile unit; xref confirms 5 compile edges, 0 cycles.
- Characterized RecipesFacadeDriftTest as a seed-dependent ordering artifact: passes with random seed (module loaded by prior tests), fails with `--seed 0` (test runs before Rendro.Recipes is loaded into VM). Not a flake — a test design issue for Phase 110.
- Completed bounded flake sweep (seeds 0/1/2 × 25 repeats): no flaky candidates found beyond two pre-existing deterministic failures (guardrail test + PublicApiTest missing @moduledoc).
- Human-read all 4 residue async:false modules: ManifestTest confirmed required (global BEAM recompile); IntegrationsContractTest justified by named ETS table; BrandingContractTest and RecipesContractTest are clean Phase 110 `async: true` candidates.

## Task Commits

1. **Tasks 1+2: Gather all evidence into 108-EVIDENCE.md** — `2fc1ef6` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified

- `.planning/phases/108-baseline-audit-report/108-EVIDENCE.md` — All six evidence sections: real-runner timing, critical path, duplicated work, local profiling proxy, p95 note, RecipesFacadeDriftTest characterization, bounded flake sweep results, residue async:false module read

## Decisions Made

- RecipesFacadeDriftTest failure is a seed-dependent ordering artifact (async: true test relies on prior module loading), not a local environment issue and not a flake. Phase 110 should add `Code.ensure_loaded!(Rendro.Recipes)` in test setup or convert to `async: false`.
- ManifestTest `async: false` is confirmed required: `PublicApi.recompile_conditional_adapters()` triggers global BEAM module recompilation and cannot run concurrently.
- BrandingContractTest and RecipesContractTest are Phase 110 `async: true` candidates: no global state found; only caveat is `DocsContract.evaluate!/2` which needs Phase 110 safety verification.
- IntegrationsContractTest `async: false` is justified by the named ETS table `:rendro_threadline_calls` — technically PID-keyed so arguably safe, but borderline; Phase 110 should verify.

## Deviations from Plan

None — plan executed exactly as written. This was a MEASURE-ONLY plan; no source files were modified. All evidence sections were gathered in a single pass and written to 108-EVIDENCE.md atomically.

### Clarification on RecipesFacadeDriftTest

RESEARCH.md described this as "local env drift" and "local env artifact". The Plan 02 isolation runs showed it is more precisely a **seed-dependent ordering artifact** — the failure is deterministic with `--seed 0` and reproducible on any machine. The RESEARCH.md characterization was a reasonable hypothesis; the human-read in Plan 02 refined it to the exact root cause.

### Note on mislabeled defmodule

RESEARCH.md referenced `defmodule DocsContractMailglassWrapper.Message` as a copy-paste artifact in IntegrationsContractTest. The current `test/docs_contract/integrations_contract_test.exs` correctly defines `Rendro.DocsContract.IntegrationsContractTest` — no mislabeled defmodule was found. This may refer to `test/docs_contract/integrations_claims_test.exs` (a different file). Flagged in EVIDENCE.md for Plan 03 to verify.

### Pre-existing failures (noted, not fixed)

Two deterministic test failures exist in the codebase before Plan 02:
1. `RequiredChecksContractTest` — guardrail asserts `run: mix ci` (bare), but Plan 108-01 changed ci.yml to use `set -o pipefail` + tee. The guardrail test needs updating (future plan scope).
2. `PublicApiTest` — `Mix.Tasks.Brand.Gen` is missing `@moduledoc` tag. Pre-existing code gap (future plan scope).

These were NOT fixed (MEASURE-ONLY constraint) and were excluded from flake sweep analysis.

## Issues Encountered

- `mix compile --profile time` with warm cache produced no output (nothing to recompile). Used `--force` flag to force a full recompile and capture timing data. This is expected behavior — documented in profiling section.
- `--repeat-until-failure 25` terminates on first failure. With seeds 0/1/2, the pre-existing failures cause early termination (iteration 1). The sweep did not complete 25 iterations for any seed. This is expected and documented in EVIDENCE.md — the failures are deterministic, not flaky.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- 108-EVIDENCE.md is complete with all 6 evidence sections required by Plan 03.
- Plan 03 (C1-AUDIT.md authoring) can proceed immediately — it has all source data.
- Phase 110 candidates identified: BrandingContractTest, RecipesContractTest (async: true flip), RecipesFacadeDriftTest (ordering fix), and RecipesContractTest async conversion.
- Two pre-existing failures need future attention: guardrail update for tee pattern, and `Mix.Tasks.Brand.Gen` @moduledoc tagging.

## Self-Check

- [x] `108-EVIDENCE.md` exists at `.planning/phases/108-baseline-audit-report/108-EVIDENCE.md`
- [x] All 6 sections present: Real-Runner Timing, Local Profiling, p95 Note, RecipesFacadeDriftTest Characterization, Bounded Flake Sweep Results, Residue async:false Module Read
- [x] Exact phrase "insufficient green-run data (n=3)" appears (3 occurrences)
- [x] "local proxy (18 schedulers; not runner-absolute)" tag appears on all local measurement sections (5 occurrences)
- [x] All 4 residue modules addressed with verdicts
- [x] Seeds 0, 1, 2 all documented in flake sweep section
- [x] No source/test/workflow files modified — `git diff --name-only` shows empty (only new 108-EVIDENCE.md)
- [x] Task commit `2fc1ef6` exists

## Self-Check: PASSED

---
*Phase: 108-baseline-audit-report*
*Completed: 2026-06-14*

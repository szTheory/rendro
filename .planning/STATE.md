---
gsd_state_version: 1.0
milestone: C1
milestone_name: CI/CD Performance & Reliability
status: planning
last_updated: "2026-06-15T21:40:31.309Z"
last_activity: 2026-06-15
progress:
  total_phases: 10
  completed_phases: 2
  total_plans: 5
  completed_plans: 5
  percent: 20
---

# Project State

## Reference

**Project**: Rendro — milestone **C1 CI/CD Performance & Reliability** (non-version infra milestone; pipeline/tooling work, no library/Hex changes)
**Core Value**: A fast, deterministic, trustworthy, resource-efficient CI/CD pipeline with great contributor DX — keep the high-value quality signal, drop low-signal/flaky checks, fix caching and parallelism, all measured before/after.
**Current Focus**: Discuss phase 109 complete. Next: Phase 109 planning.

## Current Position

Phase: 110
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-15

## Progress

```text
[........................................] 16% — 1/6 phases complete
Phase 108 Baseline & Audit Report ........ Complete
Phase 109 Caching & setup-beam ........... Discussed
Phase 110 Test Concurrency & Determinism . Pending
Phase 111 Workflow Topology & Matrix ..... Pending
Phase 112 Security & Release Hardening .... Pending
Phase 113 DX & Validation ................. Pending
```

## Accumulated Context

### Decisions

- Framed as non-version `C1` infra milestone (phases 108–113); no Hex release; touches `.github/`, `mix.exs` aliases, tests, CONTRIBUTING only.
- Full arc: measure baseline first (Phase 108, analysis only) → implement (109–112) → validate vs baseline (113). "Boil the ocean systematically; keep high-value tests, drop lowest-signal."
- North Star priority order: trustworthy gates > deterministic feedback > fast PR feedback > runner efficiency > YAML simplicity > contributor DX > security > reporting.
- Source brief preserved verbatim at `milestones/C1-AUDIT-BRIEF.md` — canonical scope/checklist cited by every phase.
- 108-01: Used `set -o pipefail` (bash-idiomatic) for tee exit-code preservation; single brace-group `{ … } >> "$GITHUB_STEP_SUMMARY"` per house style; `# TODO(109)` seam retained for cache rows.
- 108-02: RecipesFacadeDriftTest is a seed-dependent ordering artifact (async:true test calls function_exported? before Rendro.Recipes is VM-loaded with --seed 0) — Phase 110 finding, not a flake.
- 108-02: ManifestTest async:false confirmed required — PublicApi.recompile_conditional_adapters() triggers global BEAM module recompilation (cannot run concurrently).
- 108-02: BrandingContractTest and RecipesContractTest are Phase 110 async:true candidates (no global state found; DocsContract.evaluate!/2 needs Phase 110 safety verification).
- 108-02: Two pre-existing deterministic failures noted but NOT fixed (MEASURE-ONLY): RequiredChecksContractTest (guardrail expects bare mix ci, but 108-01 used tee) and PublicApiTest (Mix.Tasks.Brand.Gen missing @moduledoc).
- 108-03: C1-AUDIT.md authored as consolidated measure-only baseline; BASE-01/02/03/04 populated from 108-EVIDENCE.md; P0: decompose mix ci monolith (Phase 109+111); p95=insufficient green-run data (n=3); 0 flaky candidates; 2 pre-existing baseline failures noted
- 109-DISCUSS: `CACHE_BUSTER` will use an `env:` var in CI YAMLs for PR visibility and ease of bursting.
- 109-DISCUSS: Dialyzer PLT will be isolated to `priv/plts` using `plt_core_path` in `mix.exs`, enabling a separate `restore/save` cache split so the PLT is saved unconditionally even if Dialyzer fails, without polluting `_build`.
- 109-DISCUSS: `mix ci` decomposition is deferred to Phase 111 to avoid tangling cache implementation with `test/guardrails/required_checks_contract_test.exs` rewrites. `erlef/setup-beam` will be uniformly SHA-pinned.
- 109-01: Unify erlef/setup-beam pinning to SHA 8251c48667b97e88a0a24ec512f5b72a039fcea7 across all workflow configurations.
- 109-01: Set plt_core_path and plt_local_path to priv/plts in mix.exs to store Dialyzer PLT files outside the default _build directory, preparing for caching.
- 109-02: Split PLT cache into restore and save actions to ensure generation is saved even on job failure or subsequent step failures, maintaining pipeline isolation.
- 109-02: Expose cache hits to the job summary through strictly mapped env variables to prevent expression injection.

### Blockers / Open Questions

- None. Phase 109 discussion is complete and the architectural decisions are recorded.

## Next Steps

1. `/gsd:plan-phase 109` — create execution plans for Phase 109.
2. Implement caching (109), test concurrency/determinism (110), topology/matrix (111), security/release (112), DX + validation (113).

## Last Session

**Last updated**: 2026-06-16
**Stopped at**: Completed 109-01-PLAN.md
**Blockers**: None

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 108 P01 | 5 | 1 tasks | 1 files |
| Phase 108 P02 | 45min | 2 tasks | 1 files |
| Phase 108 P03 | 35min | 2 tasks | 1 files |
| Phase 109 P01 | 15m | 2 tasks | 4 files |

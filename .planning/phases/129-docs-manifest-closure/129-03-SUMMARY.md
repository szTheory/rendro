---
phase: 129-docs-manifest-closure
plan: "03"
subsystem: docs-manifest-ci-guardrails
tags: [elixir, mix, exunit, public-api, ci, documentation]
requires:
  - phase: 129-02
    provides: public preset guide, package, and ExDoc closure
provides:
  - Generator-fresh adapter-tier Rendro.Theme.preset/2 public API inventory
  - Exactly 27 deterministic docs-contract lanes with one preset public-claims lane
  - Required-check registry and status-manifest accounting synchronized without new CI contexts
affects: [DOCS-01, deterministic CI, documentation claim contracts]
tech-stack:
  added: []
  patterns: [generator-only manifest reconciliation, exact docs-lane registry guardrail]
key-files:
  created: [.planning/phases/129-docs-manifest-closure/129-03-SUMMARY.md]
  modified: [priv/public_api.json, scripts/verify_docs.exs, test/guardrails/required_checks_contract_test.exs, priv/guardrails/required_status_checks.json]
key-decisions:
  - "Keep the generated public API manifest byte-identical when regeneration reveals no API drift; record the generator proof rather than hand-editing it."
  - "Make preset public claims the 27th deterministic docs-contract lane while keeping ci-success as the sole required context and advisory evidence disconnected."
metrics:
  duration: 5min
  completed: 2026-08-19
  tasks: 2
  files: 4
status: complete
---

# Phase 129 Plan 03: Manifest and Guardrail Closure Summary

**The generated Theme.preset/2 API inventory and deterministic documentation contract now close together through a 27-lane required CI path.**

## Accomplishments

- Regenerated `priv/public_api.json` exclusively with `mix rendro.api.gen`; it was byte-identical and retains `Rendro.Theme.preset/2` exactly once in the adapter tier.
- Added one `Preset public-claims lane` for the existing cross-surface claims contract, bringing the explicit deterministic registry to 27 lanes.
- Locked the exact lane count and tuple in the required-check guardrail and reconciled the deterministic test-context notes to 27 without changing `ci-success`, `mix ci`, workflow topology, or advisory/browser/raster treatment.

## Task Commits

1. **Task 1: Regenerate and prove the public API manifest** — `6e3aa9d` (generator reconciliation; byte-identical manifest)
2. **Task 2: Commit the 27-lane registry and guardrail closure as one transaction** — `b50384a` (registry, guardrail test, and status manifest)

## Files Created/Modified

- `priv/public_api.json` — generator-fresh, unchanged adapter-tier public API manifest.
- `scripts/verify_docs.exs` — adds the sole preset public-claims tuple as lane 27.
- `test/guardrails/required_checks_contract_test.exs` — asserts exactly 27 lanes and the exact preset tuple.
- `priv/guardrails/required_status_checks.json` — truthfully documents 27 docs-contract lanes while retaining `ci-success` as the only required context.

## Decisions Made

- Treated byte-identical generator output as positive reconciliation evidence, with no hand-authored manifest diff.
- Kept public-claim validation in the established deterministic test context; no CI status, required check, or advisory boundary changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Isolated cached Hex package archives from concurrent builds**
- **Found during:** Post-wave full-suite integration gate
- **Issue:** Package-content tests shared the repository-root `rendro-1.0.0.tar`; concurrent `mix hex.build` invocations could replace it while another test was reading `contents.tar.gz`.
- **Fix:** The shared test cache now creates one unique temporary archive per test VM and every package-content contract reads that immutable path.
- **Files modified:** `test/support/hex_build_cache.ex` and all seven archive-content consumers.
- **Verification:** Three consecutive affected-pair runs passed; the full package-contract cluster passed (52 tests); `mix ci.fast` passed.
- **Commit:** `01a75da`

**Total deviations:** 1 auto-fixed (Rule 1).

**Impact:** Assertions remain unchanged; only the mutable archive transport path is isolated.

## Known Stubs

None.

## Verification

- `mix rendro.api.gen && mix test test/docs_contract/public_api_contract_test.exs --max-failures 1 && git diff --exit-code -- priv/public_api.json` — passed; 6 tests, 0 failures; no manifest diff.
- `mix test test/docs_contract/presets_claims_test.exs --max-failures 1` — passed; 11 tests, 0 failures.
- `mix test test/guardrails/required_checks_contract_test.exs --max-failures 1` — passed; 18 tests, 0 failures.
- Focused four-file contract command — passed; 48 tests, 0 failures.
- `mix run scripts/verify_docs.exs` — passed all 27 explicit docs-contract lanes.
- `mix ci.fast` — passed package build, format, compile warnings gate, deterministic tests, ExDoc warnings gate, Credo, and Dialyzer.
- Post-wave archive-race regression: affected pair passed three consecutive combined runs; full package-contract cluster passed (52 tests); `mix ci.fast` passed again.

## Self-Check: PASSED

- Confirmed the four delivery files exist and task commits `6e3aa9d` and `b50384a` exist in git history.
- Confirmed Task 2 contains exactly the three required accounting files; the registry has 27 tuples with one preset lane, and `required_contexts` remains `ci-success`.
- Stub-pattern scan found no placeholders, TODO/FIXME markers, or empty rendering values in the plan-owned delivery files.

---
*Phase: 129-docs-manifest-closure*
*Completed: 2026-08-19*

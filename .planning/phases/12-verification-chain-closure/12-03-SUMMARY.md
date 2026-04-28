---
phase: 12-verification-chain-closure
plan: 03
subsystem: testing
tags: [elixir, mix, ci, verify, docs, hex, tdd]
requires:
  - phase: 12-02
    provides: aggregated verification lane reporting and the current `mix verify` command structure
provides:
  - canonical `mix ci` coverage for format, compile, tests, docs, and package build
  - public `Mix.Tasks.Verify.run/1` regression coverage via a minimal test-only lane seam
affects: [quality, verification, ci, docs, packaging]
tech-stack:
  added: []
  patterns: [canonical mix alias contracts, test-only Mix task lane injection]
key-files:
  created:
    - .planning/phases/12-verification-chain-closure/deferred-items.md
    - .planning/phases/12-verification-chain-closure/12-03-SUMMARY.md
    - test/mix/tasks/ci_alias_contract_test.exs
  modified:
    - mix.exs
    - lib/mix/tasks/verify.ex
    - test/mix/tasks/verify_test.exs
key-decisions:
  - "Keep `mix ci` in `MIX_ENV=test` and widen `ex_doc` to `[:dev, :test]` instead of changing the alias environment, so hosted CI stays truthful to the documented command surface."
  - "Allow lane injection for `Mix.Tasks.Verify.run/1` only through a test-only application env seam, preserving the production verification path while making the public shutdown boundary deterministic to test."
patterns-established:
  - "Canonical merge-blocking requirements should be encoded directly in `mix.exs` aliases instead of being split across workflow YAML and docs."
  - "Public Mix task command-boundary tests can use a test-only env seam when internal helpers alone are insufficient to prove exit behavior."
requirements-completed: [QUAL-01, QUAL-05]
duration: 6min
completed: 2026-04-28
---

# Phase 12 Plan 03: Verification Chain Closure Summary

**Canonical `mix ci` now encodes the full QUAL-01 lane, and `Mix.Tasks.Verify.run/1` is regression-tested at the public shutdown boundary without invoking real CI commands in tests**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-28T13:43:00Z
- **Completed:** 2026-04-28T13:48:43Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Expanded the canonical `mix ci` alias to include format checking, docs generation, and package build verification while keeping the existing strict gates and `MIX_ENV=test`.
- Made `ex_doc` available in `:test` so the `docs` step is executable inside the real CI lane that hosted GitHub Actions already runs.
- Added public-entrypoint regression coverage for `Mix.Tasks.Verify.run/1` with a minimal test-only seam so shutdown ordering is pinned without spawning the real verification suite.

## Task Commits

Each task was committed atomically:

1. **Task 1: Expand the canonical `mix ci` alias to the full QUAL-01 contract**
   `04485df` (`test`) RED: add failing CI contract regression
   `e70518a` (`feat`) GREEN: expand the canonical CI verification lane
2. **Task 2: Pin the public `Mix.Tasks.Verify.run/1` shutdown boundary after summary output**
   `bbcdd95` (`test`) RED: add failing `Verify.run/1` boundary regression
   `09d02ef` (`feat`) GREEN: add the minimal test-only lane seam

## Files Created/Modified

- `mix.exs` - widens `ex_doc` to `[:dev, :test]` and makes `mix ci` the truthful QUAL-01 lane.
- `test/mix/tasks/ci_alias_contract_test.exs` - proves the canonical alias contents and `ex_doc` test availability.
- `lib/mix/tasks/verify.ex` - adds a test-only default-lane seam for the public `run/1` entrypoint.
- `test/mix/tasks/verify_test.exs` - exercises `catch_exit(Verify.run([]))` and pins summary-before-shutdown behavior.
- `.planning/phases/12-verification-chain-closure/deferred-items.md` - records out-of-scope formatting debt surfaced by the corrected CI lane.

## Decisions Made

- Kept the workflow delegation unchanged: the truth fix belongs in `mix ci`, not in `.github/workflows/ci.yml`.
- Chose application-env lane injection only for `Mix.env() == :test` so the command-boundary regression stays deterministic without weakening production behavior.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix ci` now fails immediately on pre-existing formatting drift in unrelated files. That failure is expected after restoring the full QUAL-01 contract and was logged in `.planning/phases/12-verification-chain-closure/deferred-items.md` instead of being fixed in this narrow-scope plan.
- Running `mix verify` still mutates Phoenix example build artifacts under `examples/phoenix_example/`; those generated files were restored after verification so commits stayed scoped to the planned source files.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 12’s remaining blocker is closed at the source: hosted CI still runs `mix ci`, and `mix ci` now truthfully covers the documented verification contract.
- The repo still carries out-of-scope formatting debt that will keep the restored `mix ci` lane red until cleaned up in a later plan.

## Self-Check

PASSED

- Found `.planning/phases/12-verification-chain-closure/12-03-SUMMARY.md`
- Found task commits `04485df`, `e70518a`, `bbcdd95`, and `09d02ef` in `git log`

---
*Phase: 12-verification-chain-closure*
*Completed: 2026-04-28*

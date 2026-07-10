---
phase: 113-dx-local-reproducibility-validation
plan: 01
subsystem: infra
tags: [ci, github-actions, mix, guardrails]

# Dependency graph
requires:
  - phase: 111-workflow-topology-triggers-matrix
    provides: "Stable ci-success gate and rationalized CI topology"
provides:
  - "Scoped Mix CI aliases for fast, proofs, and advisory lanes"
  - "Guardrail coverage for split CI alias and workflow step structure"
  - "GitHub Actions fast lane split into named steps with test output summaries"
affects: [ci, contributor-dx, validation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Split-step GitHub Actions fast lane backed by local Mix alias parity"

key-files:
  created: []
  modified:
    - "mix.exs"
    - "test/guardrails/required_checks_contract_test.exs"
    - ".github/workflows/ci.yml"

key-decisions:
  - "Keep the local root mix ci alias as ci.fast followed by ci.proofs."
  - "Expose fast-lane CI commands as individual GitHub Actions steps for grouped logs and step timings."
  - "Use /tmp/mix-test-output.log as the source for slowest-test step summary output."

patterns-established:
  - "CI parity guardrail: validate local Mix aliases and workflow run steps together."
  - "Step-summary source files should follow the specific command that emits the parsed output."

requirements-completed: [DX-01]

# Metrics
duration: recovered
completed: 2026-07-10
status: complete
---

# Phase 113 Plan 01: Split CI Alias and Workflow Fast Lane Summary

**Scoped Mix aliases and split GitHub Actions steps now give contributors local parity while preserving actionable CI log grouping.**

## Performance

- **Duration:** recovered from a partial prior execution
- **Started:** before current session
- **Completed:** 2026-07-10T22:19:15Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Decomposed `mix ci` into `ci.fast`, `ci.proofs`, and `ci.advisory`, with the root alias running the required gate lanes.
- Updated the required-checks guardrail to validate `ci.fast` and split workflow run steps instead of a monolithic `run: mix ci`.
- Replaced the primary CI job's single `Run CI` step with named Format, Hex Build, Compile, Test, Docs, Credo, and Dialyzer steps.
- Routed slowest-test summary parsing to `/tmp/mix-test-output.log`, produced by the Test step.

## Task Commits

Each task was committed atomically:

1. **Task 1: Decompose mix ci aliases** - `01a800d` (feat)
2. **Task 2: Update guardrail contracts for split CI alias** - `7401006` (test)
3. **Task 3: Split steps in GitHub Actions** - `3634de2` (feat)

## Files Created/Modified

- `mix.exs` - Defines `ci`, `ci.fast`, `ci.proofs`, and `ci.advisory` aliases.
- `test/guardrails/required_checks_contract_test.exs` - Enforces local alias and CI workflow split-step structure.
- `.github/workflows/ci.yml` - Runs the primary fast lane as separate named steps and writes test output for summaries.

## Decisions Made

- None beyond the locked phase decisions; implementation followed the plan.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Safe-resume detected prior production commits for `113-01` without a corresponding `113-01-SUMMARY.md`. The partial state was reconciled by inspecting the existing commits, validating the remaining uncommitted workflow change, committing Task 3, and creating this summary instead of re-running completed tasks.

## Verification

- `mix help ci.fast`
- `mix format mix.exs test/guardrails/required_checks_contract_test.exs`
- `mix test test/guardrails/required_checks_contract_test.exs`
- `grep -q "run: mix format --check-formatted" .github/workflows/ci.yml`
- `grep -q "/tmp/mix-test-output.log" .github/workflows/ci.yml`

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The local CI aliases and CI workflow structure are ready for Plan 02 contributor documentation and README badging.

---
*Phase: 113-dx-local-reproducibility-validation*
*Completed: 2026-07-10*

---
phase: 68-viewer-evidence-schema-mix-task-and-docs-contract-lane
plan: 02
subsystem: testing
tags: [mix-task, viewer-evidence, support-matrix, json-output, exit-codes]

requires:
  - phase: 68-01
    provides: Rendro.ViewerEvidence.Matrix and Validator modules, priv/viewer_evidence scaffolding
provides:
  - Mix.Tasks.Rendro.ViewerEvidence with list/validate/missing subcommands
  - Human table + --json output contract
  - D-22 exit codes against production matrix (26/5/21/0)
  - Integration tests for operator tooling
affects:
  - 68-03 (docs-contract eighth lane)
  - Phase 69 viewer evidence guide and first promotions

tech-stack:
  added: []
  patterns:
    - "Operator Mix task delegates validate to Validator.run_full/3 only"
    - "Advisory vs fatal warning partition for legacy/staleness vs evidence/orphan failures"
    - "JSON stdout-only contract with stderr errors"

key-files:
  created:
    - lib/mix/tasks/rendro/viewer_evidence.ex
    - test/mix/tasks/viewer_evidence_task_test.exs
  modified: []

key-decisions:
  - "validate exit 0 on production matrix with 5 Tier-B legacy warnings only"
  - "missing exit 1 with 21 unverified cells; not registered in mix ci alias"

patterns-established:
  - "Mix.Tasks.Rendro.ViewerEvidence: argv subcommands + optional --json, VisualUat-style exit({:shutdown, 1})"
  - "capture_shell_messages test helper mirrors docs.contract task tests"

requirements-completed: [RECIPE-02]

duration: 15min
completed: 2026-05-28
---

# Phase 68 Plan 02: Viewer Evidence Mix Task Summary

**Operator audit task `mix rendro.viewer_evidence` with list/validate/missing subcommands, --json contract, and D-22 exit codes against the unchanged 26-cell production matrix.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-28T18:23:00Z
- **Completed:** 2026-05-28T18:38:17Z
- **Tasks:** 2 completed
- **Files modified:** 2 created

## Accomplishments

- Shipped `Mix.Tasks.Rendro.ViewerEvidence` at `lib/mix/tasks/rendro/viewer_evidence.ex` with `list`, `validate`, and `missing` subcommands plus optional `--json`.
- Human output: summary counts + fixed-width table (`surface`, `viewer`, `status`, `notes`); legacy supported rows note `legacy: missing evidence pointer`.
- Exit semantics verified on production matrix: `list` → 0, `missing` → 1 (21 unverified), `validate` → 0 (5 legacy warnings to stderr).
- `@moduledoc` documents three states, 65_536-byte budget, `mix docs.contract` CI lane, and forward link to `guides/viewer_evidence.md`.
- Task deliberately omitted from `mix.exs` `:ci` alias per D-24.

## Task Commits

Each task was committed atomically:

1. **Task 1: Mix task subcommands and output formatting** - `37316ee` (feat)
2. **Task 2: Mix task integration tests** - `bb06cab` (test)

## Files Created/Modified

- `lib/mix/tasks/rendro/viewer_evidence.ex` - Operator Mix task with list/validate/missing, table printer, JSON emitter, warning partition for validate
- `test/mix/tasks/viewer_evidence_task_test.exs` - Exit code, --json, moduledoc, and mix ci negative assertions

## Decisions Made

None beyond plan — followed D-19–D-24 and Validator.run_full/3 single entry point for validate.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## Verification

```bash
mix test test/mix/tasks/viewer_evidence_task_test.exs
# 7 tests, 0 failures

mix rendro.viewer_evidence list
# 26 cells (supported=5, unverified=21, explicit_deferral=0)

mix rendro.viewer_evidence missing; echo $?
# 1

mix rendro.viewer_evidence validate; echo $?
# 0 (5 legacy warnings on stderr)
```

## Self-Check: PASSED

- All acceptance criteria verified via ExUnit and manual smoke
- `priv/support_matrix.json` unchanged
- `mix.exs` `:ci` alias unchanged

## Next Phase Readiness

Ready for 68-03 (docs-contract eighth lane wiring). Operator tooling available locally via `mix rendro.viewer_evidence`.

---
*Phase: 68-viewer-evidence-schema-mix-task-and-docs-contract-lane*
*Completed: 2026-05-28*

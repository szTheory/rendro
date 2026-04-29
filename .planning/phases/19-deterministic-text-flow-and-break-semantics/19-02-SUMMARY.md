---
phase: 19-deterministic-text-flow-and-break-semantics
plan: 02
subsystem: pipeline
tags: [elixir, pagination, keep-rules, flow-layout, error-contract]
requires:
  - phase: 19
    provides: deterministic wrapped-text measurement and block-level break intent from plan 01
provides:
  - deterministic flow pagination for keep/break directives on measured blocks
  - typed keep-rule overflow details for impossible grouped layouts
  - typed fixed-page rejection for flow-only pagination directives
affects: [phase-19, phase-20, phase-21, pagination-contract, diagnostics]
tech-stack:
  added: []
  patterns: [directive-aware flow grouping, typed paginate boundary errors]
key-files:
  created: []
  modified:
    - lib/rendro/pipeline/paginate.ex
    - lib/rendro/error.ex
    - test/rendro/pipeline/paginate_test.exs
key-decisions:
  - "Evaluate keep and break directives only after measurement so page moves consume final block heights."
  - "Reject flow pagination directives on fixed-position pages through the existing paginate error surface instead of silently ignoring them."
patterns-established:
  - "Flow pagination now groups contiguous keep_with_next chains and places them as hard units."
  - "Impossible keep groups fail through :content_overflow with keep-specific details instead of best-effort relaxation."
requirements-completed: [LAY-09]
duration: 5 min
completed: 2026-04-29
---

# Phase 19 Plan 02: Deterministic Keep/Break Pagination Summary

**Measured flow blocks now paginate through deterministic keep/break grouping, with typed failures for impossible keep layouts and fixed-page directive misuse.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-29T19:39:00Z
- **Completed:** 2026-04-29T19:44:05Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Taught `Rendro.Pipeline.Paginate` to honor `break_before`, `break_after`, `keep_together`, and chained `keep_with_next` after measurement.
- Preserved non-kept table splitting while making kept blocks and kept chains hard pagination units.
- Extended the typed paginate error surface with keep-rule details and `:invalid_flow_directive` guidance for fixed-position misuse.

## Task Commits

Each task was committed atomically:

1. **Task 1: Paginate measured blocks with deterministic keep and break groups** - `7861f34` (feat)
2. **Task 2: Return typed diagnostics for impossible keep rules and fixed-page directive misuse** - `abd3848` (fix)

## Files Created/Modified

- `lib/rendro/pipeline/paginate.ex` - adds directive-aware flow grouping, hard keep placement, keep-rule overflow details, and fixed-page directive validation.
- `lib/rendro/error.ex` - adds stable next-step guidance for `:invalid_flow_directive`.
- `test/rendro/pipeline/paginate_test.exs` - proves keep-chain movement, forced page boundaries, keep-rule failure details, and fixed-page directive rejection.

## Decisions Made

- Keep and break directives stay inside `Paginate`, after `Measure`, so authored page intent is resolved from final measured heights rather than guessed earlier in the pipeline.
- Fixed-position pages do not get a second pagination model; any flow-only directive on that surface now fails through the existing typed paginate contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected helper argument ordering in the new pagination pipeline**
- **Found during:** Task 1 (Paginate measured blocks with deterministic keep and break groups)
- **Issue:** The first helper pass piped page state into block-group arguments, causing `KeyError` crashes before the new flow logic could run.
- **Fix:** Reordered the helper call sites and added a wrapper so the directive-aware pagination pipeline receives `pages` and `group` in the correct positions.
- **Files modified:** `lib/rendro/pipeline/paginate.ex`
- **Verification:** `mix test test/rendro/pipeline/paginate_test.exs`
- **Committed in:** `7861f34`

**2. [Rule 1 - Bug] Updated paginate tests to match measured text blocks**
- **Found during:** Task 1 (Paginate measured blocks with deterministic keep and break groups)
- **Issue:** An existing pagination assertion still matched raw `%Rendro.Text{}` content even though plan 01 now stores measured flow text inside `%Rendro.Pipeline.MeasuredText{}`.
- **Fix:** Extended the test matchers to accept measured-text carriers while preserving the original page-geometry assertions.
- **Files modified:** `test/rendro/pipeline/paginate_test.exs`
- **Verification:** `mix test test/rendro/pipeline/paginate_test.exs`
- **Committed in:** `7861f34`

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both fixes were direct fallout from the new pagination implementation. No scope creep, and the final contract matches the plan.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 19 Plan 03 can render measured wrapped lines and document the new keep/break behavior against a stable pagination contract.
- Phase 20 can build richer table semantics on top of deterministic flow grouping without weakening keep-rule truthfulness.

## Self-Check: PASSED

- Found `.planning/phases/19-deterministic-text-flow-and-break-semantics/19-02-SUMMARY.md`
- Found commit `7861f34`
- Found commit `abd3848`

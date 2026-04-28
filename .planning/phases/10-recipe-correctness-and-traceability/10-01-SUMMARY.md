---
phase: 10-recipe-correctness-and-traceability
plan: 01
subsystem: adapters
tags: [mailglass, accrue, docs, tests]
requires: []
provides:
  - "Mailglass now re-wraps admitted custom wrapper structs through their own module"
  - "Accrue returns typed invalid_line_item tuples and normalizes issued_at to YYYY-MM-DD"
  - "Integration guide now states exact adapter shapes and failure tuples"
affects: [adapters, integrations, requirements-traceability]
tech-stack:
  added: []
  patterns: ["typed adapter boundary validation", "truthful integration contract docs"]
key-files:
  created: []
  modified:
    - lib/rendro/adapters/mailglass.ex
    - test/rendro/adapters/mailglass_test.exs
    - lib/rendro/adapters/accrue.ex
    - test/rendro/adapters/accrue_test.exs
    - guides/integrations.md
key-decisions:
  - "Kept Mailglass custom-wrapper support narrow and explicit instead of silently downgrading unsupported wrappers."
  - "Failed Accrue recipes at the adapter boundary on the first invalid nested line item."
patterns-established:
  - "Optional adapters should return typed tuples for boundary misuse instead of raising."
  - "User-facing adapter output should use normalized date formatting, not Elixir inspect syntax."
requirements_completed: [ADPT-05]
duration: 20min
completed: 2026-04-28
---

# Phase 10: recipe-correctness-and-traceability Summary

**Mailglass now preserves supported wrapper structs, Accrue fails deterministically on bad nested data, and the integration guide matches the implemented contracts.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-04-28T08:45:00Z
- **Completed:** 2026-04-28T09:05:05Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Fixed `put_swoosh/2` to dispatch through the input wrapper module and return a typed error for unsupported wrapper shapes.
- Added regression coverage for Mailglass custom-wrapper success, invalid nested Accrue line items, and normalized `issued_at` rendering.
- Updated `guides/integrations.md` to document the exact Mailglass wrapper contract and Accrue date/error behavior.

## Task Commits

No plan-specific commit was created. The worktree already contained unrelated in-progress changes, including prior edits in `lib/rendro/adapters/mailglass.ex`, so this plan was left uncommitted to avoid bundling unrelated work.

## Files Created/Modified

- `lib/rendro/adapters/mailglass.ex` - Re-wraps through `message.__struct__` and rejects unsupported wrappers with `{:unrecognized_message_shape, mod}`.
- `test/rendro/adapters/mailglass_test.exs` - Covers custom wrapper re-wrap success and admitted-wrapper error behavior.
- `lib/rendro/adapters/accrue.ex` - Validates nested line items and formats `issued_at` as `YYYY-MM-DD`.
- `test/rendro/adapters/accrue_test.exs` - Covers invalid nested line items and normalized date rendering.
- `guides/integrations.md` - States the exact Mailglass wrapper shape and Accrue failure/date contract.

## Decisions Made

- Kept the Mailglass contract intentionally narrow: `.Message` suffix, `update_swoosh/2`, and a `%Swoosh.Email{}` in `:swoosh` or `:email`.
- Omitted the `Issued:` line when `issued_at` is `nil` rather than rendering inspect output or a placeholder.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The repo had a dirty worktree, including pre-existing edits to `lib/rendro/adapters/mailglass.ex`. The fix was applied on top of those changes without reverting or committing unrelated work.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Wave 2 can now update Phase 5 verification artifacts and `REQUIREMENTS.md` using concrete code, test, and docs evidence from this summary.
- No functional blockers remain for the Phase 10 traceability sync.

---
*Phase: 10-recipe-correctness-and-traceability*
*Completed: 2026-04-28*

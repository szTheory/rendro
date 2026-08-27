---
phase: 133-repository-evidence-hygiene
plan: "07"
subsystem: repository evidence
tags: [elixir, release-evidence, phoenix, advisory, hygiene]
requires:
  - phase: 133-repository-evidence-hygiene
    provides: validated v1.3.4 evidence capsule and zero-consumer cutover
provides:
  - Legacy journey batch B is removed after digest-bound capsule preservation was re-proven.
affects: [release-evidence, clean-room-proof, repository-hygiene]
tech-stack:
  added: []
  patterns: ["Immutable release capsule facts preserve advisory journey provenance after redundant sources are removed."]
key-files:
  created: []
  modified:
    - priv/journey_evidence/phoenix_clean_room_1.3.4_fourth_failed_attempt.json
    - priv/journey_evidence/phoenix_clean_room_1.3.4_fourth_failed_attempt.md
    - priv/journey_evidence/phoenix_clean_room_1.3.4_fifth_failed_attempt.json
    - priv/journey_evidence/phoenix_clean_room_1.3.4_fifth_failed_attempt.md
    - priv/journey_evidence/phoenix_clean_room_1.3.4_sixth_failed_attempt.json
    - priv/journey_evidence/phoenix_clean_room_1.3.4_sixth_failed_attempt.md
    - priv/journey_evidence/phoenix_clean_room_1.3.4_seventh_failed_attempt.json
    - priv/journey_evidence/phoenix_clean_room_1.3.4_seventh_failed_attempt.md
    - priv/journey_evidence/phoenix_clean_room_1.3.4_pre_schema_success.json
key-decisions:
  - "Deleted batch B only after re-proving the nine-attempt, eight-sidecar capsule cardinality and the absent pre-schema narrative."
  - "Retained source-path strings remain provenance assertions, not active consumers of deleted legacy files."
requirements-completed: [HYGIENE-01, HYGIENE-02]
metrics:
  duration: 1m
  completed: 2026-08-26
  tasks: 1
  files: 9
status: complete
---

# Phase 133 Plan 07: Legacy Journey Batch B Removal Summary

**Removed the final nine redundant batch-B journey sources while preserving all nine ordered, digest-bound v1.3.4 capsule attempts, including the sidecar-less pre-schema record.**

## Performance

- **Duration:** 1 min
- **Completed:** 2026-08-26T22:35:45Z
- **Tasks:** 1/1
- **Files modified:** 9 deleted

## Accomplishments

- Re-proved the Plan 05 zero-consumer cutover and capsule provenance before deletion.
- Verified the capsule retains nine ordered attempts, eight explanatory sidecars, and the explicit absent narrative for attempt 007.
- Removed exactly the fourth-through-seventh failed-attempt source pairs plus the pre-schema success JSON; `priv/journey_evidence` now has no tracked files.

## Task Commits

1. **Task 1: Delete legacy journey batch B** — `084b7af` (feat)

## Verification

- `mix test test/scripts/repository_evidence_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs` — passed (10 tests, 0 failures).
- Confirmed all nine exact legacy paths are absent and `git ls-files priv/journey_evidence` is empty after the task commit.
- Confirmed `evidence/releases/v1.3.4` is unchanged from the batch-A baseline (`10126f1`).
- `git diff --check` passed.

## Decisions Made

- Kept source path/digest fields in the capsule and its tests as immutable provenance assertions; they do not read the removed files.
- Preserved the pre-schema record as facts with an explicit absent narrative rather than inventing a Markdown sidecar.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used the Mix-compatible focused test command**
- **Found during:** Task 1 verification.
- **Issue:** Mix 1.19 rejects the plan's `-x` option.
- **Fix:** Ran the equivalent focused test command without `-x`.
- **Files modified:** None.
- **Verification:** 10 focused tests passed after deletion.
- **Commit:** `084b7af`

**Total deviations:** 1 auto-fixed (Rule 3: 1). **Impact:** Verification coverage is unchanged; only the unsupported command-line option was removed.

## Known Stubs

None.

## Threat Flags

None. This removal narrows redundant repository evidence and creates no new endpoint, authentication, schema, or filesystem trust boundary.

## Next Phase Readiness

The legacy journey directory is fully retired; active evidence consumers remain bound to the validated v1.3.4 capsule.

## Self-Check: PASSED

- Task commit `084b7af` exists in Git history.
- All nine declared legacy source paths are absent.
- The focused capsule/newcomer contract suite passed after deletion.

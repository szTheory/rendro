---
phase: 72-closure-audit-polish-and-ship
plan: 02
subsystem: testing
tags: [viewer-evidence, guardrails, verification, staleness, mix-task]

requires:
  - phase: 72-01
    provides: priv/guardrails/required_status_checks.json, audit script, contract test
provides:
  - validate --strict operator/release staleness gate
  - Phase 72 verification ledger with machine JSON export
  - Phase 69 and 71 VERIFICATION backfill stubs
affects:
  - 72-03-guide-polish-and-ship
  - GUARDRAIL-02

tech-stack:
  added: []
  patterns:
    - "Strict staleness reclassifies only is-older-than warnings; not in mix ci"
    - "Machine list --json ledger + trust-sensitive spot-check sampling"

key-files:
  created:
    - .planning/phases/72-closure-audit-polish-and-ship/72-VERIFICATION.md
    - .planning/phases/69-operator-recipe-and-first-cell-end-to-end/69-VERIFICATION.md
    - .planning/phases/71-record-new-trust-sensitive-surfaces-and-explicit-deferrals/71-VERIFICATION.md
  modified:
    - lib/mix/tasks/rendro/viewer_evidence.ex
    - test/mix/tasks/viewer_evidence_task_test.exs
    - test/rendro/viewer_evidence/validator_test.exs

key-decisions:
  - "--strict is operator/release only; default validate keeps advisory staleness per D-17"
  - "Live GitHub audit gap documented when GITHUB_TOKEN unset (D-06)"

patterns-established:
  - "B+C hybrid verification ledger: machine JSON export + ≤12-row trust-sensitive spot-check"

requirements-completed: [GUARDRAIL-02]

duration: 25min
completed: 2026-05-29
---

# Phase 72 Plan 02: Strict Staleness Gate & Verification Ledger Summary

**Operator-only `validate --strict` staleness gate with automated tests and Phase 72 closure ledger using machine matrix export, GUARDRAIL-02 offline proof, and 69/71 verification backfill.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-29T17:35:00Z
- **Completed:** 2026-05-29T18:00:00Z
- **Tasks:** 4 completed
- **Files modified:** 6

## Accomplishments

- Added `mix rendro.viewer_evidence validate --strict` — reclassifies `is older than` warnings as fatal; default validate unchanged.
- Covered strict/advisory exit paths and `staleness_warnings/1` with 41 passing tests across task and validator suites.
- Drafted `72-VERIFICATION.md` with full `list --json` export, CLI captures, 8-row trust-sensitive spot-check, and GUARDRAIL-02 mapping.
- Backfilled lightweight PASS stubs for phases 69 and 71 to unblock milestone audit (D-21).

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement validate --strict on Mix task** - `ab8042b` (feat)
2. **Task 2: Add --strict exit-code tests** - `7adeae7` (test)
3. **Task 3: Draft 72-VERIFICATION.md** - `603108e` (docs)
4. **Task 4: Backfill 69 and 71 VERIFICATION stubs** - `9fc9abf` (docs)

**Plan metadata:** pending (this commit)

## Files Created/Modified

- `lib/mix/tasks/rendro/viewer_evidence.ex` — `pop_strict_flag/1`, `partition_warnings/2` strict mode, moduledoc
- `test/mix/tasks/viewer_evidence_task_test.exs` — strict pass/fail and advisory tests
- `test/rendro/viewer_evidence/validator_test.exs` — `staleness_warnings/1` unit tests
- `.planning/phases/72-closure-audit-polish-and-ship/72-VERIFICATION.md` — closure ledger
- `.planning/phases/69-operator-recipe-and-first-cell-end-to-end/69-VERIFICATION.md` — PASS backfill
- `.planning/phases/71-record-new-trust-sensitive-surfaces-and-explicit-deferrals/71-VERIFICATION.md` — PASS backfill

## Decisions Made

- Used spawned-process monitor for strict exit-1 test because `catch_exit` does not trap `exit({:shutdown, 1})` reliably inside `File.cd!` in ExUnit (observed in mix run vs test harness).
- Set `72-VERIFICATION.md` status to `gaps_found` with explicit `GITHUB_TOKEN` gap per D-06 acceptance criteria.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ExUnit catch_exit could not observe strict validation exit**

- **Found during:** Task 2 (strict failure test)
- **Issue:** `catch_exit(fn -> File.cd!(tmp, fn -> ViewerEvidence.run(["validate", "--strict"]) end) end)` returned `:ok` despite mix run confirming exit 1
- **Fix:** Spawn linked process under `File.cd!`, assert `{:DOWN, _, _, _, {:shutdown, 1}}` via monitor
- **Files modified:** `test/mix/tasks/viewer_evidence_task_test.exs`
- **Verification:** `mix test test/mix/tasks/viewer_evidence_task_test.exs` — 41 tests, 0 failures
- **Committed in:** `7adeae7`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Test harness adjustment only; production `--strict` behavior verified via mix run and passing suite.

## Issues Encountered

- `GITHUB_TOKEN` unset in verification environment — live branch-protection audit documented as pending in `72-VERIFICATION.md` Gaps section.

## User Setup Required

None - operator must export `GITHUB_TOKEN` before tag to complete live audit snapshot.

## Next Phase Readiness

- Ready for 72-03 (guide polish and ship)
- Operator action: run `mix run scripts/audit_branch_protection.exs` before v2.3 tag

## Self-Check: PASSED

- `mix rendro.viewer_evidence validate --strict` — exit 0
- `mix test test/mix/tasks/viewer_evidence_task_test.exs test/rendro/viewer_evidence/validator_test.exs` — 41 tests, 0 failures
- `72-VERIFICATION.md`, `69-VERIFICATION.md`, `71-VERIFICATION.md` exist

---
*Phase: 72-closure-audit-polish-and-ship*
*Completed: 2026-05-29*

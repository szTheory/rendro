---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "11"
subsystem: adoption-evidence
tags: [elixir, concurrency, atomic-publication, docs-contract]
requires:
  - phase: 131-01
    provides: dated bounded adoption snapshot and ledger contract
provides:
  - exclusive no-replace publication for adoption snapshots
  - deterministic parallel-writer cleanup regression
  - truthful contributor empty-state ledger wording
affects: [adoption evidence, phase-131 verification]
tech-stack:
  added: []
  patterns: [synced exclusive temporary file followed by hard-link publication, docs contracts for dated evidence states]
key-files:
  created: []
  modified:
    - scripts/adoption_snapshot.exs
    - test/docs_contract/adoption_evidence_contract_test.exs
    - ADOPTION.md
key-decisions:
  - "The no-replace hard link is the snapshot publication authority; no preflight existence check is used."
  - "Contributor tables state dated empty evidence directly rather than carrying TBD debt markers."
patterns-established:
  - "Concurrent local writers publish through an exclusive link and always remove their unique temporary file."
requirements-completed: [SIGNAL-02, SIGNAL-03, SIGNAL-04, SIGNAL-05]
coverage:
  - id: D1
    description: "One concurrent adoption snapshot writer establishes the complete authoritative target while all losing temporary files are cleaned."
    requirement: SIGNAL-02
    verification:
      - kind: unit
        ref: test/docs_contract/adoption_evidence_contract_test.exs#parallel writers produce one complete authoritative target
        status: pass
    human_judgment: false
  - id: D2
    description: "The dated adoption ledger expresses contributor empty states without unreferenced debt markers."
    requirement: SIGNAL-03
    verification:
      - kind: unit
        ref: test/docs_contract/adoption_evidence_contract_test.exs#adoption ledger uses truthful contributor empty states without debt markers
        status: pass
    human_judgment: false
duration: 10m
completed: 2026-08-25
status: complete
---

# Phase 131 Plan 11: Adoption Snapshot Race Repair Summary

**Race-safe, no-overwrite adoption snapshot publication with deterministic cleanup proof and truthful contributor empty-state ledger copy.**

## Performance

- **Duration:** 10m
- **Started:** 2026-08-25T14:06:46Z
- **Completed:** 2026-08-25T14:16:46Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Replaced the check-then-act snapshot preflight with an exclusive hard-link publication point, normalizing every loser to `{:error, :target_exists}`.
- Added synchronized four-writer coverage that proves one complete winner and no target-specific temporary artifacts.
- Replaced contributor-table `TBD` cells with dated, evidence-consistent empty states without changing the 2026-08-21 adoption decision or sidecar.

## Task Commits

1. **Task 1: Prove and repair one-winner adoption snapshot publication**
   - `817972a` — `test(131-11): add concurrent snapshot publication regression`
   - `73a0f57` — `fix(131-11): publish adoption snapshots without overwrite races`
2. **Task 2: Replace contributor debt markers with truthful empty states**
   - `ab6957b` — `test(131-11): cover truthful contributor empty states`
   - `4e9369f` — `docs(131-11): state contributor empty evidence explicitly`

## Files Created/Modified

- `scripts/adoption_snapshot.exs` — publishes through a no-replace hard link and cleans temporary files on all post-write paths.
- `test/docs_contract/adoption_evidence_contract_test.exs` — synchronizes writers and guards the contributor empty-state copy.
- `ADOPTION.md` — records that the dated contributor review has no alternate accounts or rejected candidates.

## Decisions Made

- The exclusive hard link, not a separate existence observation, establishes the authoritative dated snapshot.
- Empty contributor records remain explicit and dated; no accounts, PRs, or missing-work markers were fabricated.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The new synchronized regression failed during RED as expected by exposing three leaked loser temporary files, then passed twice after the repair.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The adoption snapshot and ledger verification gaps are closed. Plans 131-12 and 131-13 remain unimplemented and own the independent HexDocs-binding and public-verifier publication gaps.

## Self-Check: PASSED

- Confirmed all modified files exist and all four task commits are present in git history.
- Re-ran the focused adoption contracts twice and the adoption claims contract once: 17 tests pass; `ADOPTION.md` has no `TBD` token.

---

*Phase: 131-adoption-snapshot-phoenix-newcomer-proof*
*Completed: 2026-08-25*

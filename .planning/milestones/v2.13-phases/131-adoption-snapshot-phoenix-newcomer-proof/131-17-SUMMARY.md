---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "17"
subsystem: testing
tags: [phoenix, hexdocs, provenance, clean-room, advisory-evidence]
requires:
  - phase: 131-18
    provides: Current verifier-authenticated HexDocs dispatch prerequisite and durable binding
  - phase: 131-16
    provides: Clean-room consumer prerequisite compatibility contract
provides:
  - Fresh bounded public-Phoenix journey evidence authenticated to current provenance
  - Green focused, cleanup-root, and deterministic CI validation records
affects: [phase-131-security-verification, phase-131-goal-verification]
tech-stack:
  added: []
  patterns: [Current prerequisite before advisory clean-room run, deterministic contracts separate from live observations]
key-files:
  created: [.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-17-SUMMARY.md]
  modified:
    - priv/journey_evidence/phoenix_clean_room_1.3.4.json
    - priv/journey_evidence/phoenix_clean_room_1.3.4.md
    - .planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-VALIDATION.md
key-decisions:
  - "Use the harness public main/1 entrypoint when mix run has an ExUnit server, preserving the existing disposable-run implementation."
  - "Keep live Phoenix/package facts advisory while recording deterministic focused and ci.fast contracts separately."
patterns-established:
  - "Journey evidence must bind prerequisite SHA, durable HexDocs run/control identity, matching ConnCase and loopback response facts, and cleanup."
requirements-completed: [JOURNEY-01, JOURNEY-02, JOURNEY-03, JOURNEY-04]
coverage:
  - id: D1
    description: Fresh isolated Phoenix consumer resolves public Rendro 1.3.4 and records matching dual HTTP PDF facts.
    requirement: JOURNEY-01
    verification:
      - kind: e2e
        ref: scripts/phoenix_clean_room_proof.exs public main/1 run plus phoenix_clean_room_proof_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Current evidence authenticates to the verifier-grade prerequisite and preserves advisory/deterministic separation.
    requirement: JOURNEY-04
    verification:
      - kind: integration
        ref: public_release_verifier_test.exs + phoenix_newcomer_contract_test.exs + mix ci.fast
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-25
status: complete
---

# Phase 131 Plan 17: Phoenix Clean-Room Evidence Refresh Summary

**Fresh isolated Phoenix evidence now resolves public Rendro 1.3.4 from the current HexDocs workflow-dispatch prerequisite and proves the canonical Swiss/light Invoice through ConnCase and loopback PDF responses.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-08-25T21:22:00Z
- **Completed:** 2026-08-25T21:30:00Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Ran a new disposable Phoenix consumer proof using the current canonical prerequisite; generated state and payload were removed after bounded projection.
- Replaced journey JSON and transcript with the current prerequisite SHA, HexDocs run/control/binding identities, exact resolved versions, and matching 200 PDF facts.
- Passed the 94-test focused cross-contract suite, the targeted cleanup-root regression, and `mix ci.fast`; recorded those outcomes in validation.

## Task Commits

1. **Task 1: Reprove the exact public Swiss/light Invoice through both HTTP paths** — `8831df7` (feat)
2. **Task 2: Close focused, full-suite, and validation contracts** — `17e1d6d` (docs)

## Files Created/Modified

- `priv/journey_evidence/phoenix_clean_room_1.3.4.json` — refreshed bounded advisory run projection.
- `priv/journey_evidence/phoenix_clean_room_1.3.4.md` — transcript with provenance identities, stages, outcome, cleanup, and failure guidance.
- `.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-VALIDATION.md` — current validations and green Nyquist closure.

## Decisions Made

- Invoked `Rendro.PhoenixCleanRoomProof.main/1` explicitly because the script's auto-run guard sees Mix's ExUnit server; this exercises the existing public harness without changing it.
- Classified package resolution and loopback observations as advisory evidence, while tests and `mix ci.fast` remain deterministic contracts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Explicitly invoked the harness entrypoint during the live proof.**
- **Found during:** Task 1
- **Issue:** `mix run scripts/phoenix_clean_room_proof.exs` loaded the script without executing its guarded auto-run branch.
- **Fix:** Used the existing public `Rendro.PhoenixCleanRoomProof.main/1` entrypoint with the planned arguments.
- **Verification:** Fresh JSON carries the current prerequisite SHA, success result, and cleanup `removed`; focused contracts passed.
- **Committed in:** `8831df7`

**Total deviations:** 1 auto-fixed (Rule 1).

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all three evidence/validation files exist.
- Confirmed task commits `8831df7` and `17e1d6d` exist in git history.

## Next Phase Readiness

The implementation and evidence contracts are ready for fresh independent GSD security and goal verification. No public mutation, tag/package change, or workflow dispatch occurred during this plan.

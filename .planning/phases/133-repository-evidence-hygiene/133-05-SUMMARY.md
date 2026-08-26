---
phase: 133-repository-evidence-hygiene
plan: "05"
subsystem: repository evidence
tags: [elixir, release-evidence, github-actions, phoenix, advisory]
requires:
  - phase: 133-repository-evidence-hygiene
    provides: complete validated v1.3.4 evidence capsule and shared loader
provides:
  - Every active v1.3.4 clean-room and public-release consumer reads capsule facts through one loader.
  - A v1.3.4-bounded advisory release workflow with no planning-archive prerequisite.
affects: [133-06, 133-07, release-evidence, clean-room-proof]
tech-stack:
  added: []
  patterns: ["Operational release evidence is loaded only through Rendro.RepositoryEvidence; retained journey facts remain advisory."]
key-files:
  created: []
  modified:
    - scripts/phoenix_clean_room_proof.exs
    - scripts/verify_public_release.exs
    - .github/workflows/release.yml
    - test/scripts/phoenix_clean_room_proof_test.exs
    - test/scripts/public_release_verifier_test.exs
    - test/docs_contract/phoenix_newcomer_contract_test.exs
    - test/guardrails/required_checks_contract_test.exs
key-decisions:
  - "Clean-room and public-release defaults obtain v1.3.4 facts through the validated capsule loader, never planning files."
  - "The fresh clean-room workflow remains advisory and is explicitly limited to v1.3.4."
requirements-completed: [HYGIENE-01, HYGIENE-02]
coverage:
  - id: D1
    description: "All declared active consumers use the validated release capsule and have no archive dependency."
    requirement: HYGIENE-01
    verification:
      - kind: integration
        ref: "mix test test/scripts/repository_evidence_test.exs test/scripts/phoenix_clean_room_proof_test.exs test/scripts/public_release_verifier_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs test/guardrails/required_checks_contract_test.exs"
        status: pass
      - kind: other
        ref: "zero-consumer scan over declared scripts, workflow, and tests"
        status: pass
    human_judgment: false
  - id: D2
    description: "The release advisory proof remains non-blocking and v1.3.4-bounded."
    requirement: HYGIENE-02
    verification:
      - kind: unit
        ref: "test/guardrails/required_checks_contract_test.exs"
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-08-26
status: complete
---

# Phase 133 Plan 05: Atomic Consumer Cutover Summary

**All active v1.3.4 release and clean-room consumers now read validated capsule roles through one loader, while the retained proof workflow stays advisory and version-bounded.**

## Performance

- **Duration:** 25 min
- **Completed:** 2026-08-26T22:25:50Z
- **Tasks:** 1/1
- **Files modified:** 7

## Accomplishments

- Replaced archive-derived clean-room and public-release defaults with `Rendro.RepositoryEvidence` role lookups.
- Removed the release workflow's Phase 131 prerequisite path and restricted its advisory job to the fixed `v1.3.4` tag.
- Migrated clean-room, public-release, newcomer, and workflow guardrail contracts to the capsule; the declared D-25 scan found zero operational archive consumers.

## Task Commits

1. **Task 1: Switch all active consumers in one commit** - `dda731e` (feat)

## Verification

- `mix format --check-formatted` passed for all seven modified paths.
- Focused migrated suite passed: 84 tests, 0 failures.
- The focused D-25 scan found no Phase 131 or legacy journey consumer in the declared consumer surfaces.
- `git diff --check` passed.

## Decisions Made

- Kept the clean-room proof's fresh external run advisory and bound only to `v1.3.4`; it does not turn historical facts into a future-release policy.
- Removed arbitrary prerequisite and candidate-record inputs from active consumer defaults so the shared loader remains the sole authority seam.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used the Mix-compatible focused test command**
- **Found during:** Task 1 verification.
- **Issue:** Mix 1.19 rejects the plan's `-x` option.
- **Fix:** Ran the equivalent focused test command without `-x`.
- **Files modified:** None.
- **Verification:** 84 tests passed.

**Total deviations:** 1 auto-fixed (Rule 3: 1).

## Known Stubs

None.

## Threat Flags

None. This cutover adds no endpoint, authentication, schema, or filesystem trust boundary; it narrows existing evidence authority.

## Next Phase Readiness

Plans 06 and 07 can remove the preserved legacy journey copies after reusing this plan's zero-consumer proof and capsule digest checks.

## Self-Check: PASSED

- All seven declared consumer paths exist and are included in `dda731e`.
- Task commit `dda731e` exists in Git history.

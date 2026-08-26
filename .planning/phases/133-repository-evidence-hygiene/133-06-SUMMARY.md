---
phase: 133-repository-evidence-hygiene
plan: "06"
subsystem: repository evidence
tags: [elixir, release-evidence, provenance, digest, advisory]
requires:
  - phase: 133-repository-evidence-hygiene
    provides: complete validated v1.3.4 evidence capsule and zero-consumer cutover proof
provides:
  - Legacy journey batch A is removed after capsule-only provenance verification.
  - Journey evidence contracts validate fixed preserved facts and metadata without reading legacy files at runtime.
affects: [133-07, release-evidence, clean-room-proof]
tech-stack:
  added: []
  patterns: ["Deleted evidence remains represented by fixed provenance, fact, and sidecar digest assertions against the sealed capsule."]
key-files:
  created: []
  modified:
    - test/scripts/repository_evidence_test.exs
    - priv/journey_evidence/phoenix_clean_room_1.3.4.json (deleted)
    - priv/journey_evidence/phoenix_clean_room_1.3.4.md (deleted)
    - priv/journey_evidence/phoenix_clean_room_1.3.4_failed_attempt.json (deleted)
    - priv/journey_evidence/phoenix_clean_room_1.3.4_failed_attempt.md (deleted)
    - priv/journey_evidence/phoenix_clean_room_1.3.4_second_failed_attempt.json (deleted)
    - priv/journey_evidence/phoenix_clean_room_1.3.4_second_failed_attempt.md (deleted)
    - priv/journey_evidence/phoenix_clean_room_1.3.4_third_failed_attempt.json (deleted)
    - priv/journey_evidence/phoenix_clean_room_1.3.4_third_failed_attempt.md (deleted)
key-decisions:
  - "Journey provenance contracts retain source path, source digest, source commit, facts digest, and sidecar digest as capsule assertions rather than reading deleted legacy files."
requirements-completed: [HYGIENE-01, HYGIENE-02]
coverage:
  - id: D1
    description: "Legacy journey batch A is absent while all preserved capsule records remain schema- and digest-valid."
    requirement: HYGIENE-02
    verification:
      - kind: integration
        ref: "mix test test/scripts/repository_evidence_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs"
        status: pass
      - kind: other
        ref: "runtime source-read and operational-consumer scans"
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-26
status: complete
---

# Phase 133 Plan 06: Delete Legacy Journey Batch A Summary

**Legacy batch A is deleted after capsule-only verification preserves every journey record's provenance, facts, and sidecar digests.**

## Performance

- **Duration:** 8 min
- **Completed:** 2026-08-26T22:32:48Z
- **Tasks:** 1/1
- **Files modified:** 9

## Accomplishments

- Removed exactly the first four redundant clean-room JSON/Markdown source pairs from `priv/journey_evidence`.
- Replaced runtime reads of legacy source JSON and Markdown with fixed provenance, fact, and sidecar digest contracts over the validated v1.3.4 capsule.
- Confirmed the capsule/newcomer focused suite and the runtime source-read scan remain green after deletion.

## Task Commits

1. **Task 1: Delete legacy journey batch A** - `5c12ecc` (feat)

## Verification

- `mix test test/scripts/repository_evidence_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs` passed: 10 tests, 0 failures.
- `mix format --check-formatted test/scripts/repository_evidence_test.exs` passed.
- `git diff --check` passed.
- Operational-consumer scan found no consumers outside the revised evidence contract; the capsule retains provenance records by design.
- Runtime source-read scan found no `File.read!` path from capsule provenance to a legacy source file.

## Decisions Made

- Preserved source metadata and historical fact/sidecar digests as fixed test contracts so legacy copies can be removed without weakening evidence integrity.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Removed obsolete legacy source reads from the provenance test**
- **Found during:** Task 1
- **Issue:** The evidence test read `attempt.source.path` and the derived Markdown source path at runtime, so deleting batch A would break the required capsule verification.
- **Fix:** Replaced those reads with fixed source metadata, facts digests, and sidecar digests, each verified against capsule records and bytes.
- **Files modified:** `test/scripts/repository_evidence_test.exs`
- **Verification:** Focused suite passed with all eight deleted paths absent.
- **Commit:** `5c12ecc`

**Total deviations:** 1 auto-fixed (Rule 2: 1).

## Issues Encountered

- The initial shell verification used zsh's special `path` variable and halted before deletion; rerunning with a non-special variable completed the same read-only proof and exact deletion.

## Known Stubs

None.

## Threat Flags

None. This narrows the deletion boundary after digest-proven preservation and introduces no new network, authentication, schema, or filesystem trust surface.

## Next Phase Readiness

Plan 07 can remove batch B using the same capsule-only provenance pattern and zero-consumer proof.

## Self-Check: PASSED

- All eight specified legacy batch A paths are absent.
- `test/scripts/repository_evidence_test.exs` exists and task commit `5c12ecc` exists in Git history.

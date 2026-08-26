---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "08"
subsystem: release-controls
tags: [hex, release-preflight, candidate, phoenix, audit]
requires:
  - phase: 131-07
    provides: Exact v1.3.4 release, verifier, workflow, package, and incident surfaces.
provides:
  - One exact private v1.3.4 candidate with detached no-tag proof.
  - A fresh pending blocking-human approval packet with no inherited approval.
affects: [131-09, 131-10, release]
tech-stack:
  added: []
  patterns: [detached exact-SHA candidate proof, control-only post-candidate delta]
key-files:
  created: [131-08-SUMMARY.md]
  modified:
    - .planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-RELEASE-CANDIDATE.md
    - .planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-RELEASE-APPROVAL-PACKET.md
    - test/scripts/public_release_verifier_test.exs
key-decisions:
  - "f03c78bab54efe1cd1596d51cf3f28193232e2a3 is the sole private v1.3.4 candidate."
  - "Approval remains pending_blocking_human; no v1.3.3 approval transfers."
requirements-completed: [JOURNEY-01, JOURNEY-02, JOURNEY-04]
coverage:
  - id: D1
    description: Exact private v1.3.4 candidate with complete detached proof.
    requirement: JOURNEY-01
    verification:
      - kind: integration
        ref: mix run scripts/release_preflight_proof.exs --candidate-sha f03c78bab54efe1cd1596d51cf3f28193232e2a3 --worktree <isolated-temp-dir>
        status: pass
    human_judgment: false
  - id: D2
    description: Pending exact-candidate approval packet with immutable incident history.
    requirement: JOURNEY-04
    verification:
      - kind: unit
        ref: test/scripts/public_release_verifier_test.exs
        status: pass
    human_judgment: false
duration: 24min
completed: 2026-08-22
status: complete
---

# Phase 131 Plan 08: Exact v1.3.4 Candidate Summary

**Sealed private candidate `f03c78bab54efe1cd1596d51cf3f28193232e2a3` with complete detached no-tag proof, immutable incident retention, and a fresh pending human-approval packet.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-08-22T21:09:00Z
- **Completed:** 2026-08-22T21:32:46Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Proved exact SHA `f03c78b...` in a fresh detached worktree after confirming `bbe75d2...` ancestry, no local/remote `v1.3.4` tag, and Hex/HexDocs 404 absence.
- Passed focused release/verifier/workflow/tutorial/FIFO contracts (61 tests), `mix ci.fast`, docs, tutorial, package checksum/inventory/unpack checks, both audits, and complete credential-free nested candidate preflight.
- Recorded archive SHA-256 `7c886783fa1f73b2b154b4840295e6092b3f26e7bf568203476d204b0c0c369a`; local/remote tag snapshot hashes stayed byte-identical (`8ac725...b7996`, `646bbb...8fdf9`).
- Rebound the candidate and approval packet only after the fresh proof. `candidate..HEAD` contains only the two Phase-131 control records.

## Task Commits

1. **Task 1: Prove exact committed SHA without a tag** — `a8615a5`, `40379d2`, `5927ca5` (docs)
2. **Task 2: Seal candidate and create non-approving packet** — `fe7c72b`, `c7c7a6b` (docs)
3. **Rule 1 correction: assert sealed lifecycle state** — `f03c78b` (fix)

## Files Created/Modified

- `.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-RELEASE-CANDIDATE.md` — exact candidate, proof, ref/public absence, and all four incidents.
- `.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-RELEASE-APPROVAL-PACKET.md` — same exact evidence with `pending_blocking_human` only.
- `test/scripts/public_release_verifier_test.exs` — lifecycle contract follows candidate capture rather than stale pre-capture state.

## Decisions Made

- Exact `f03c78bab54efe1cd1596d51cf3f28193232e2a3` is the sole private candidate; Plan 10 clean-room work remains deferred until Plan 09's public prerequisite.
- The post-candidate control delta is limited to candidate and approval records. No tag, package, HexDocs dispatch, live verifier, or approval was produced.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated stale candidate-lifecycle verifier contract**
- **Found during:** Task 2
- **Issue:** The contract asserted the consumed pre-capture v1.3.3 record after Task 2 correctly sealed v1.3.4, and the record initially omitted two immutable run identifiers required by that contract.
- **Fix:** Made the test assert the sealed v1.3.4 state and retained the complete v1.3.2/v1.3.3 incident identities. The source/test change invalidated `ed68ff8...`; a full new exact-SHA proof was run and controls were rebound to `f03c78b...`.
- **Files modified:** `test/scripts/public_release_verifier_test.exs`, candidate and approval controls.
- **Verification:** 18 focused verifier/proof tests passed; fresh focused/FIFO, CI, package/audit, and nested preflight evidence all passed at `f03c78b...`.
- **Committed in:** `40379d2`, `f03c78b`, `5927ca5`, `c7c7a6b`

**Total deviations:** 1 auto-fixed (Rule 1)

## Issues Encountered

- An initial overlapping `mix ci.fast` run was terminated before acceptance. Its evidence was discarded; only the later sequential f03 proof is recorded.

## Next Phase Readiness

Plan 09 may request a fresh blocking-human approval naming `f03c78b...`; it must not inherit v1.3.3 approval. Until then, v1.3.4 remains absent locally/remotely/publicly and all mutations remain prohibited.

## Self-Check: PASSED

- Candidate and approval controls exist and commits `5927ca5` and `c7c7a6b` exist.
- Candidate SHA is an ancestor-bound 40-character identity and its post-candidate delta is control-only.

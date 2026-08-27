---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "13"
subsystem: release-controls
tags: [elixir, verifier, concurrency, atomic-publication, fsync]
requires:
  - phase: 131-10
    provides: A bounded public prerequisite consumed by the clean-room Phoenix journey.
provides:
  - Race-safe, no-replace publication of the VERIFIED public prerequisite.
  - Deterministic competing-writer regression coverage and retained read-only revalidation coverage.
affects: [journey, release-evidence, public-prerequisite]
tech-stack:
  added: []
  patterns: [exclusive temporary output, synced file publication, hard-link no-replace commit point]
key-files:
  created: []
  modified:
    - scripts/verify_public_release.exs
    - test/scripts/public_release_verifier_test.exs
key-decisions:
  - "Use a filesystem hard link as the exclusive no-replace publication authority after the completed temporary file has been synced."
  - "Keep --check-existing read-only: it compares fresh bounded facts against existing bytes instead of invoking publication."
metrics:
  tasks_completed: 1
  files_modified: 2
status: complete
---

# Phase 131 Plan 13: Race-Safe Public Prerequisite Summary

**The public release verifier now publishes exactly one synced, bounded VERIFIED prerequisite under competing writers without replacing an authoritative target.**

## Accomplishments

- Replaced the check-then-rename writer with exclusive temporary-file creation, write, close, sync, and hard-link publication.
- Maps a pre-existing destination to the established `output must not already exist` error and removes the temporary file on every outcome.
- Added a synchronized competing-writer test proving one winner, one refusal, a complete bounded target, and no target-specific temporary artifacts.
- Preserved sequential overwrite refusal plus byte- and mtime-preserving `--check-existing` revalidation.

## Verification

- `mix test test/scripts/public_release_verifier_test.exs --max-failures 1` — pass (18 tests, 0 failures).
- Repeated `mix test test/scripts/public_release_verifier_test.exs:231 --trace` — pass twice; each run proved one competing writer wins and one is refused.
- `git diff --quiet HEAD -- .planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-PUBLIC-PREREQUISITE.json` — pass; the committed prerequisite is untouched.
- `mix test test/docs_contract/adoption_evidence_contract_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs test/scripts/phoenix_clean_room_proof_test.exs test/scripts/public_release_verifier_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` — pass (76 tests, 0 failures).

## Task Commits

1. **RED: competing-writer regression** — `c88c804` (test)
2. **GREEN: synced exclusive no-replace publication** — `ab9844a` (fix)

## Decisions Made

- A hard link is the final no-replace authority because the destination creation either succeeds once or returns `:eexist`; `File.rename/2` cannot provide that contract on the target platform.
- The existing matching-record path remains a validation-only path and never touches file bytes or metadata.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed the Mix build-lock false concurrency harness**
- **Found during:** Task 1 GREEN verification.
- **Issue:** Two `mix run` subprocesses serialize on Mix's build directory lock, so they could both exit successfully without actually racing the verifier writer.
- **Fix:** Used two barrier-synchronized task processes that independently call the verifier's public writer, exercising the actual file-publication race without a build-tool lock.
- **Files modified:** `test/scripts/public_release_verifier_test.exs`.
- **Verification:** The focused regression passes repeatedly with exactly one `:ok` and one no-replace error.
- **Commit:** `ab9844a`.

## Known Stubs

None.

## Self-Check: PASSED

- Modified verifier and test files exist.
- Task commits `c88c804` and `ab9844a` exist in git history.
- No public prerequisite JSON, generated artifact, or temporary file is tracked by this plan.

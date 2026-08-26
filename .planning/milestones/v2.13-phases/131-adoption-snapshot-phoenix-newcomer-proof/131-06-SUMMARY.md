---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "06"
subsystem: release
tags: [release, hex, hexdocs, incident]
requires: [131-05]
provides: [immutable-v1.3.3-release-incident]
affects: [131-07]
key-files:
  modified:
    - .planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-RELEASE-APPROVAL-PACKET.md
    - .planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-VALIDATION.md
key-decisions:
  - "v1.3.3 failure is immutable: no retry, ref mutation, alternate publisher, or HexDocs dispatch."
requirements-completed: []
status: blocked
---

# Phase 131 Plan 06: Protected v1.3.3 Release Stop Summary

The approved exact tag reached the protected release workflow, whose unauthenticated Hex dry run failed before publication; Hex and HexDocs remain absent.

## Accomplishments

- Revalidated and recorded the exact private candidate before the blocking-human approval.
- Recorded the literal approval, created exactly one annotated `v1.3.3` tag, and pushed only that tag.
- Preserved the failed protected run as immutable evidence and stopped before HexDocs dispatch.

## Release Incident

- Tag object: `c96bf205d7216cdcf4846a0f24a312f9c1c75b0f`
- Peeled candidate: `cfc58a81865e060351ce33d98f5e52de8cd198d9`
- Release run: `32596108284` (`push`, exact head, failed)
- Validation job: `97087204354`; version match, CI, and release preflight passed.
- Failing step: `Publish to Hex (Dry Run)` exited 1 because no Hex user was authenticated; its prompt was intentionally not answered.
- Publish job: `97088652899` (skipped)
- Public checks: Hex 1.3.3 `404`; HexDocs 1.3.3 `404`; no candidate-bound HexDocs dispatch exists.
- Verifier verdict: not run and no `VERIFIED` prerequisite written, because protected release/public Hex success is required first.

## Verification

- `mix test test/scripts/public_release_verifier_test.exs test/guardrails/required_checks_contract_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs --max-failures 1` — 32 tests, 0 failures.
- The Plan 06 public-prerequisite assertion was intentionally not run to success: the protected release failed before the verifier precondition, and no prerequisite file exists. This is the required fail-closed outcome, not a skipped release check.

## Task Commits

1. Task 1 proof packet — `8814a21`
2. Literal blocking-human approval — `0f84277`
3. Incident controls — pending this summary commit

## Deviations from Plan

None. The prescribed protected dry run failed and the plan-required fail-closed path was followed without a retry or alternate publication.

## Next Phase Readiness

Blocked. Treat the v1.3.3 tag/run as immutable incident history. A future explicitly planned recovery must diagnose the protected Hex authentication configuration, select a new version/candidate, obtain a new exact-SHA approval, and repeat all release proof; it must not retry or modify v1.3.3.

## Self-Check: PASSED

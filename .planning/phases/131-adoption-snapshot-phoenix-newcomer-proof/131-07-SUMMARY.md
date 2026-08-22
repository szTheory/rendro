---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "07"
subsystem: release
tags: [release, hex, hexdocs, verifier, workflow]
requires:
  - phase: 131-06
    provides: Immutable v1.3.3 failure facts and the bbe75d2 least-privilege recovery boundary.
provides:
  - Exact 1.3.4 package, ExDoc, and protected HexDocs dispatch identities.
  - Atomic public-release verification with all four immutable failed-release incidents.
affects: [131-08, 131-09, 131-10]
tech-stack:
  added: []
  patterns: [Exact recovery target plus fail-closed immutable incident validation]
key-files:
  created: []
  modified:
    - mix.exs
    - CHANGELOG.md
    - .github/workflows/hexdocs.yml
    - scripts/verify_public_release.exs
    - test/docs_contract/launch_execution_claims_test.exs
    - test/scripts/public_release_verifier_test.exs
key-decisions:
  - "Exact 1.3.4 is the sole recovery target; v1.3.0 through v1.3.3 remain immutable failed history."
  - "Complete credential-free preflight remains validation; HEX_API_KEY is limited to actual protected publication."
  - "Plan 10 exclusively owns the clean-room harness, tests, and evidence after the Plan 09 public prerequisite."
requirements-completed: [JOURNEY-01, JOURNEY-02, JOURNEY-04]
coverage:
  - id: D1
    description: Exact 1.3.4 project, protected HexDocs, and least-privilege release contracts.
    requirement: JOURNEY-01
    verification:
      - kind: unit
        ref: mix test test/guardrails/required_checks_contract_test.exs test/docs_contract/launch_execution_claims_test.exs --max-failures 1
        status: pass
    human_judgment: false
  - id: D2
    description: Atomic v1.3.4 public verifier requiring v1.3.0-v1.3.3 immutable incidents.
    requirement: JOURNEY-04
    verification:
      - kind: unit
        ref: mix test test/scripts/public_release_verifier_test.exs --max-failures 1
        status: pass
    human_judgment: false
duration: 20min
completed: 2026-08-22
status: complete
---

# Phase 131 Plan 07: Exact v1.3.4 Release Surface Summary

**Exact 1.3.4 package, protected HexDocs, and fail-closed public verification contracts preserve all four failed-release incidents without releasing anything.**

## Performance

- **Duration:** 20 min
- **Completed:** 2026-08-22T21:07:12Z
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Retargeted project, ExDoc source identity, changelog, and protected HexDocs dispatch to exact `1.3.4`, while the public README remains `{:rendro, "~> 1.3"}`.
- Kept `bbe75d2` in ancestry and preserved the credential-free `Run Release Preflight` boundary with `HEX_API_KEY` limited to the protected actual-publish path.
- Made `v1.3.4` the verifier's only success target and require exact v1.3.0-v1.3.3 tag/run/job/absence facts before an atomic `VERIFIED` record can be written.
- Deferred the absent clean-room harness, its tests, and journey evidence to Plan 10, after Plan 09 creates the public prerequisite.

## Verification

- `mix test test/guardrails/required_checks_contract_test.exs test/docs_contract/launch_execution_claims_test.exs test/scripts/public_release_verifier_test.exs --max-failures 1` — pass (40 tests, 0 failures).
- `git merge-base --is-ancestor bbe75d2 HEAD` — pass.
- `mix run -e 'IO.write(Mix.Project.config()[:version])'` — `1.3.4`.
- `mix ci.fast` — pass.
- Confirmed no prerequisite output and no clean-room harness files were written; no candidate capture, tag, publish, dispatch, or live verifier ran.

## Task Commits

1. **Task 1: Exact project/docs/workflow contracts** — `593a14b` (test), `33067a6` (feat)
2. **Task 2: Exact public verifier and four immutable incidents** — `ceec64e` (test), `3cb2152` (feat)

## Files Created/Modified

- `mix.exs` — project and ExDoc source identity at 1.3.4.
- `CHANGELOG.md` — recovery entry for the new exact version.
- `.github/workflows/hexdocs.yml` — candidate-bound `v1.3.4` dispatch parity.
- `scripts/verify_public_release.exs` — atomic four-incident verifier.
- `test/docs_contract/launch_execution_claims_test.exs` — protected/public version boundary contract.
- `test/scripts/public_release_verifier_test.exs` — exact v1.3.4 and v1.3.3 incident fixtures.

## Decisions Made

- The failed v1.3.3 tag/run remains evidence only; it cannot be retried or used as a verifier target.
- Clean-room source ownership is deliberately deferred to Plan 10, preventing a pre-verifier journey implementation.

## Deviations from Plan

None - the amended plan executed exactly as written.

## Next Phase Readiness

Plan 08 can capture and prove a fresh exact 1.3.4 candidate on the completed source tree. Plan 09 remains the only future owner of approval, protected publication, HexDocs dispatch, and the live verifier; Plan 10 owns the post-verifier clean-room proof.

## Self-Check: PASSED

- Required exact-version and verifier files exist in their recorded task commits.
- Task commits `593a14b`, `33067a6`, `ceec64e`, and `3cb2152` exist in git history.

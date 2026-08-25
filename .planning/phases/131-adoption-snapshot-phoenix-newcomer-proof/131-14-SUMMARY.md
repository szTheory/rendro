---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "14"
subsystem: release-controls
tags: [hexdocs, protected-main, approval, provenance, release]
requires:
  - phase: 131-12
    provides: Immutable candidate-bound HexDocs workflow control.
  - phase: 131-13
    provides: Race-safe public prerequisite publication control.
provides:
  - Literal, dated approval bounded to the exact protected-main control and HexDocs dispatch identities.
  - Explicit Plan 131-15-only authority for the one-way external action.
affects: [hexdocs, protected-main, public-prerequisite, phoenix-journey]
tech-stack:
  added: []
  patterns: [hash-bound human approval, explicit external-mutation scope, fail-closed handoff]
key-files:
  created:
    - .planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-HEXDOCS-CONTROL-APPROVAL.md
  modified: []
key-decisions:
  - "The literal approve-exact-control-and-docs response authorizes only the packet-bound Plan 131-15 protected-main fast-forward and one candidate-bound HexDocs dispatch."
metrics:
  tasks_completed: 2
  files_modified: 1
  duration: "~6 minutes (continuation)"
  completed_date: 2026-08-25
status: complete
---

# Phase 131 Plan 14: HexDocs Control Authorization Summary

**A fresh literal approval now binds the one-way protected-main and HexDocs action to control SHA `881b97ffc10551f77e7c6f416bc91df2e1289025`, candidate `f03c78bab54efe1cd1596d51cf3f28193232e2a3`, and `v1.3.4`.**

## Accomplishments

- Sealed the control-plane approval packet with the local control SHA, protected remote base, candidate/tag identities, workflow/test hashes, and no-mutation stop conditions.
- Recorded the literal unqualified response `approve-exact-control-and-docs` at `2026-08-25T17:12:57Z`, with no reviewer identity supplied.
- Limited authorization to Plan 131-15: fast-forward protected `origin/main` to the packet control SHA, dispatch `HexDocs` from protected `main` exactly once for the sealed v1.3.4 candidate, and retain its binding artifact.
- Explicitly excluded any external mutation from this plan, including protected-main writes, workflow dispatch, tag/package mutation, and HexDocs publication.

## Verification

- `MIX_ENV=test mix test test/docs_contract/launch_execution_claims_test.exs test/scripts/public_release_verifier_test.exs --max-failures 1` — pass (29 tests, 0 failures).
- `git merge-base --is-ancestor origin/main HEAD` — pass.
- `test "$(git rev-parse 'v1.3.4^{}')" = f03c78bab54efe1cd1596d51cf3f28193232e2a3` — pass.
- Packet decision, literal response, candidate SHA, release ref, and workflow-name checks — pass.

## Task Commits

1. **Seal protected-main control-plane approval packet** — `22a20b9` (docs)
2. **Record exact HexDocs control approval** — `626bf8d` (docs)

## Decisions Made

- The exact approval transfers no authority from earlier v1.3.4 package release actions.
- Plan 131-15 owns every approved external action and must revalidate the packet’s fail-closed conditions before proceeding.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. This plan records authority only and adds no endpoint, authentication path, file-access boundary, or schema change.

## Self-Check: PASSED

- Approval packet and summary files exist.
- Task commits `22a20b9` and `626bf8d` exist in git history.
- No stub, TODO, or placeholder pattern was introduced by this plan.

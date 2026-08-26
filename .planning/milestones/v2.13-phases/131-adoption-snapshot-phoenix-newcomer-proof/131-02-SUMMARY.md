---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "02"
subsystem: release-workflow-guardrails
tags: [github-actions, release, hexdocs, regression, guardrails]
requires:
  - phase: 131-01
    provides: adoption snapshot and recovery context
provides:
  - Exact-one top-level `@version` extraction in both protected release workflows
  - Deterministic regression coverage for the failed v1.3.0 multiline extraction
affects: [131-03, 131-04, protected-release, hexdocs]
tech-stack:
  added: []
  patterns:
    - Fail closed before workflow version parity checks when declaration count is not exactly one
key-files:
  created:
    - .planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-02-SUMMARY.md
  modified:
    - .github/workflows/release.yml
    - .github/workflows/hexdocs.yml
    - test/guardrails/required_checks_contract_test.exs
key-decisions:
  - "Both protected consumers share an anchored top-level declaration parser and reject zero or multiple matches before parity checks."
  - "Run 32513353551 remains failed v1.3.0 regression evidence; this plan performed no release, tag, dispatch, or publication action."
metrics:
  tasks_completed: 1
  files_modified: 3
  tests: 22
status: complete
---

# Phase 131 Plan 02: Protected Workflow Version Parser Repair Summary

Both protected workflows now extract exactly one top-level `@version` value, preventing the declaration-plus-`source_ref` multiline failure that stopped the v1.3.0 release before publication.

## Tasks Completed

1. Repaired and regression-tested both protected workflow parsers.
   - Added the red regression contract for the failed `@version "1.3.0"` plus `source_ref: "v#{@version}"` input.
   - Updated `release.yml` and `hexdocs.yml` to use the same anchored declaration extraction, explicit count, diagnostic, and nonzero exit before existing parity checks.
   - Covered one declaration, zero declarations, and duplicate declarations independently for each workflow consumer.

## Verification

- `mix test test/guardrails/required_checks_contract_test.exs --max-failures 1` — passed (22 tests, 0 failures).
- Re-ran the tracer verification after the implementation commit — passed.
- `bash -n` verified both edited workflow shell blocks.
- `git diff --check` — passed.

## TDD Gate Compliance

- RED: `85d84af` added the regression coverage; it failed against the old broad workflow parser.
- GREEN: `980c11f` implemented the exact-one extraction and returned the focused suite to green.
- REFACTOR: formatting only; included with the GREEN commit.

## Deviations from Plan

None - plan executed exactly as written.

## Security and Release Boundary

The workflow trust-boundary mitigation now fails closed when `mix.exs` has zero or multiple top-level version declarations. No release target, candidate, tag, workflow dispatch, Hex publication, HexDocs publication, or external state was changed. Protected run `32513353551` remains the failed v1.3.0 incident fixture.

## Known Stubs

None.

## Self-Check: PASSED

- Required workflow and guardrail test files exist.
- Task commits `85d84af` and `980c11f` exist.

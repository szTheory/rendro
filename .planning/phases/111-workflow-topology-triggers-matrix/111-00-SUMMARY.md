# Phase 111 Plan 00: Update Guardrails Baseline and Tests Summary

**Phase:** 111
**Plan:** 00
**Subsystem:** CI/CD Guardrails
**Tags:** test, json, guardrails

## Dependency Graph
- **Requires:** Phase 110 completion
- **Provides:** Updated guardrail test contracts and JSON baseline expecting `ci-success` topology
- **Affects:** CI Guardrail tests, GitHub required status checks baseline

## Tech Stack
- **Added:** N/A
- **Patterns:** TDD (RED state) for pipeline tests before modifying the pipeline itself

## Key Files
- **Modified:**
  - `priv/guardrails/required_status_checks.json`
  - `test/guardrails/required_checks_contract_test.exs`

## Decisions Made
- Allowed the contract tests to intentionally fail against the current `ci.yml`. The test suite is currently in a TDD RED state, fulfilling the plan's explicit objective: "so they are ready when `ci.yml` is updated in subsequent waves."
- Grouped the advisory contexts into a single `advisory-checks` pipeline context.
- Grouped the live-proofs into a single `integration-proofs` context.
- Set `ci-success` as the sole required context for main branch protection.

## Deviations from Plan
None - plan executed exactly as written.

## Known Stubs
None

## Threat Flags
None

## Metrics
- **Duration:** 5m
- **Completed:** 2026-06-16

## Self-Check: PASSED
- `required_status_checks.json` correctly configured.
- `required_checks_contract_test.exs` assertions updated.
- Both files committed successfully.

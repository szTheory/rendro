---
phase: 88-launch-execution-demand-instrumentation
plan: 02
subsystem: adoption-ledger
tags: [adoption, text-shaping-gate, docs-contract, public-docs]

requires:
  - phase: 88-01
    provides: First-wave adoption docs-contract lane
provides:
  - Root public ADOPTION.md ledger
  - Concrete v2.7 global text-shaping demand thresholds
  - README and comparison-guide routing to the adoption ledger
affects: [adoption, text-shaping, launch, public-docs, github-intake]

tech-stack:
  added: []
  patterns:
    - Public demand gates stay in root Markdown, not private analytics or project tooling
    - Adoption docs-contract tests enforce threshold copy, ledger schema, empty states, and public links

key-files:
  created:
    - ADOPTION.md
  modified:
    - README.md
    - guides/comparison.md
    - test/docs_contract/adoption_claims_test.exs

key-decisions:
  - "Used root ADOPTION.md as the public source of truth for conditional v2.7 demand, with no custom analytics or GitHub Projects tracker."
  - "Kept download growth as explicit Hex API snapshots recorded by maintainers, not runtime telemetry."
  - "Kept contributor counting manual and reviewable, excluding typos, bots, Dependabot, and maintainer alternate accounts."

patterns-established:
  - "Adoption gate table: Demand, Downloads, and Contributor thresholds must all pass before v2.7 is eligible."
  - "Public docs route concrete unsupported document jobs to ADOPTION.md rather than vague social counters."

requirements-completed: [LNCH-03]

duration: 11 min
completed: 2026-06-12
---

# Phase 88 Plan 02: Adoption Ledger Summary

**Root adoption ledger with concrete v2.7 shaping thresholds and public routing from README/comparison docs**

## Performance

- **Duration:** 11 min
- **Started:** 2026-06-12T14:15:00Z
- **Completed:** 2026-06-12T14:25:53Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Created root `ADOPTION.md` with the required section order, threshold table, launch snapshot, signal ledger, download snapshots, external contributor section, and review log.
- Documented exact demand, download, and contributor thresholds for the conditional v2.7 global text-shaping gate.
- Added review workflow commands for Hex downloads, adoption/text-shaping issues, and merged contributor PRs.
- Linked `ADOPTION.md` from README's Guides section and from the comparison guide's complex-script limitation block.
- Activated all adoption docs-contract assertions; no adoption tests remain skipped after this plan.

## Task Commits

1. **Task 1: Create root ADOPTION.md with exact gate thresholds and ledger schema** - `3f5b5c3` (docs)
2. **Task 2: Link ADOPTION.md from README and comparison limitations** - `67d20dd` (docs)

**Plan metadata:** pending in this commit

## Verification

- `mix test test/docs_contract/adoption_claims_test.exs` - passed, 7 tests, 0 failures.
- `mix docs.contract` - passed all 20 explicit docs-contract lanes.
- `grep -F "Typos, bots, Dependabot, and maintainer alternate accounts do not count" ADOPTION.md` - matched the contributor threshold.
- `grep -F "curl -fsSL https://hex.pm/api/packages/rendro | jq '.downloads'" ADOPTION.md` - matched the documented Hex snapshot command.

## Files Created/Modified

- `ADOPTION.md` - Public adoption signal ledger and v2.7 shaping demand gate.
- `README.md` - Guides list now links to Adoption Signals.
- `guides/comparison.md` - Complex-script limitation block routes concrete unsupported jobs to the ledger.
- `test/docs_contract/adoption_claims_test.exs` - All ADOPTION.md and public-link assertions are active.

## Decisions Made

- The ledger explicitly rejects reactions, stars, forks, `+1`, generic i18n wishes, social posts, duplicate requester/org/use cases, and unreviewed private reports as counted shaping signals.
- The download threshold remains based on recorded Hex API snapshots, with launch date `L` as the baseline.
- Public docs link to the root ledger without adding benchmark victory language or a new marketing surface.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The initial first-wave adoption test stub expected older empty-state wording and treated the required "generic i18n wishes" exclusion as forbidden. Updated the test to match the locked UI/plan copy before committing Task 1.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 88-03: GitHub issue and discussion intake can now route concrete blocked-document signals to `ADOPTION.md`.

---
*Phase: 88-launch-execution-demand-instrumentation*
*Completed: 2026-06-12*

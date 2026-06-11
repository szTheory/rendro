---
phase: 87-comparison-page-livebook
plan: 01
subsystem: docs-contract
tags: [comparison, benchmark-manifest, docs-contract, static-proof]

requires: []
provides:
  - Static comparison manifest contract and raw-artifact hash validation
  - Required docs-contract lane for comparison claim binding
  - Generated comparison block helper surface for later guide work
affects: [comparison-guide, benchmark-harness, livebook, docs-contract]

tech-stack:
  added: []
  patterns:
    - Manifest-backed static contract with committed raw artifact hashes
    - Required docs-contract lane registration for public comparison claims

key-files:
  created:
    - lib/rendro/comparison.ex
    - bench/results/comparison.json
    - bench/results/raw/.gitkeep
    - bench/results/raw/plan01-static-fixture.json
    - test/rendro/comparison_test.exs
    - test/docs_contract/comparison_claims_test.exs
  modified:
    - scripts/verify_docs.exs
    - test/guardrails/required_checks_contract_test.exs

key-decisions:
  - "Comparison proof starts with committed static manifest validation before any public benchmark guide is expanded."
  - "Plan 01 scaffold data is non-public and hash-checked; Plan 02 replaces it with real benchmark evidence."

patterns-established:
  - "Rendro.Comparison owns manifest paths, generated block markers, static contract errors, and citation-bearing block helpers."
  - "Comparison docs-contract checks run without Chrome, wkhtmltopdf, Typst, Livebook, Kino, Docker, network access, or benchmark reruns."

requirements-completed: [CMP-01, CMP-02]

duration: 23 min
completed: 2026-06-11
---

# Phase 87 Plan 01: Static Comparison Proof Scaffold Summary

**Static comparison manifest contract with raw-artifact SHA-256 validation and a required docs-contract lane for claim binding**

## Performance

- **Duration:** 23 min
- **Started:** 2026-06-11T20:19:00Z
- **Completed:** 2026-06-11T20:42:02Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `Rendro.Comparison` with manifest/guide paths, generated block markers, static contract checks, raw artifact hash validation, and citation-aware block helpers.
- Created the initial non-public comparison manifest scaffold plus committed raw fixture under `bench/results/raw`.
- Added required unit and docs-contract coverage, registered the Comparison claims lane, and updated the exact docs-lane guardrail count.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the comparison manifest module and static contract helpers** - `39de9c6` (feat)
2. **Task 2: Add unit and docs-contract tests for static comparison proof** - `c49c8fc` (test)

**Plan metadata:** pending in this commit

## Files Created/Modified

- `lib/rendro/comparison.ex` - Static manifest contract, generated block helpers, and raw artifact hash checks.
- `bench/results/comparison.json` - Initial non-public comparison manifest scaffold.
- `bench/results/raw/plan01-static-fixture.json` - Tiny committed raw fixture with SHA-256 binding.
- `test/rendro/comparison_test.exs` - Unit coverage for manifest validation, drift detection, and block helpers.
- `test/docs_contract/comparison_claims_test.exs` - Required docs-contract lane for comparison static proof and citation binding.
- `scripts/verify_docs.exs` - Registered the Comparison claims lane.
- `test/guardrails/required_checks_contract_test.exs` - Updated exact lane-count contract to 17 lanes.

## Decisions Made

- Used a non-public static scaffold manifest for Plan 01 so required checks can validate shape and hashes before Plan 02 generates real benchmark evidence.
- Kept comparison validation pure/static: no shelling out, no external benchmark/runtime tools, and no network dependencies in the required lane.

## Deviations from Plan

None - plan executed exactly as written. The guardrail lane-count update was the planned conditional adjustment required by the existing exact-count assertion.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** None.

## Issues Encountered

- Initial compilation failed because `add_error_unless/3` was missing from `Rendro.Comparison`; fixed before the task commits.
- The first source guard test was too broad for legitimate comparator/fit language; narrowed it to prohibited calls and network client references.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/rendro/comparison_test.exs` - passed, 12 tests.
- `mix test test/docs_contract/comparison_claims_test.exs` - passed, 5 tests.
- `mix test test/guardrails/required_checks_contract_test.exs` - passed, 14 tests.
- `mix run scripts/verify_docs.exs` - passed all 17 docs-contract lanes, including Comparison claims lane.

## Next Phase Readiness

Plan 02 can replace the non-public scaffold metrics with real committed benchmark harness results while preserving the manifest contract and required raw-artifact hash checks.

## Self-Check: PASSED

- Static contract returns `[]` against the committed scaffold manifest.
- Required comparator IDs include `rendro`, `chromic_pdf`, `chromic_pdf_warm_pool`, `pdf_generator`, and `typst_cli`.
- The new docs-contract lane is registered and passes without external tools.
- Production task commits exist for `87-01`.

---
*Phase: 87-comparison-page-livebook*
*Completed: 2026-06-11*

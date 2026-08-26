---
phase: 133-repository-evidence-hygiene
plan: "11"
subsystem: repository hygiene
tags: [package-boundary, repository-hygiene, mix-task, deterministic-policy]
requires:
  - phase: 133-10
    provides: caller-backed scripts inventory and narrow gsd_tooling boundary
provides:
  - Isolated repository hygiene policy with exact package-member diffing
  - NUL-safe tracked-placement, archive-consumer, and script-inventory checks
  - Canonical `Mix.Tasks.Quality.Hygiene` command ready for Plan 12 wiring
affects: [133-12, ci.fast, release-clean-checkout, package-boundary]
tech-stack:
  added: []
  patterns:
    - Build and unpack Hex packages in unique private temporary roots with guaranteed cleanup.
    - Return sorted, actionable policy diagnostics from pure repository-control helpers.
key-files:
  created:
    - dev/rendro/repository_hygiene.ex
    - dev/mix/tasks/quality/hygiene.ex
    - priv/quality/package-members-v1.json
    - test/quality/repository_hygiene_test.exs
  modified: []
key-decisions:
  - "The package manifest encodes the resolved Plan 12 package boundary now, while wiring/removal remains deliberately deferred."
  - "Only scripts/quality_governance.cjs may inspect planning as gsd_tooling; product and evidence consumers are rejected."
patterns-established:
  - "Hygiene checks use injectable build subjects for mutation and concurrency tests, while production runs build under a private root."
requirements-completed: [HYGIENE-01, HYGIENE-03, HYGIENE-04]
coverage:
  - id: D1
    description: "Repository hygiene policy rejects exact package membership drift, forbidden package classes, malformed planning placement, archive consumers, and unowned scripts."
    requirement: HYGIENE-01
    verification:
      - kind: unit
        ref: "mix test test/quality/repository_hygiene_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Each hygiene execution uses a unique temporary root, cleans failures, and never changes the authoritative package-members manifest."
    requirement: HYGIENE-04
    verification:
      - kind: unit
        ref: "test/quality/repository_hygiene_test.exs#private runs use distinct temp roots"
        status: pass
    human_judgment: false
duration: 20min
completed: 2026-08-26
status: complete
---

# Phase 133 Plan 11: Repository Hygiene Policy Summary

**A deterministic, isolated Mix hygiene policy now diffs unpacked package members and protects planning, evidence, script ownership, and temporary-build boundaries.**

## Performance

- **Duration:** 20min
- **Completed:** 2026-08-26
- **Tasks:** 1/1
- **Files modified:** 4

## Accomplishments

- Added pure, stable policy helpers for exact package-membership diffs, forbidden package material, NUL-delimited tracked planning placement, operational archive consumers, and scripts inventory coverage.
- Added `mix quality.hygiene`, which builds and unpacks only under a unique temporary root and cleans the root even after a failed check.
- Added the reviewed v1 expected-members manifest for the six public comparison JSON assets and explicit owner-bearing D-07 adoption exception.
- Proved member mutations, NUL paths, archive/tooling separation, missing inventory rows, and concurrent failure cleanup through focused tests.

## Task Commits

1. **Task 1 RED: Add failing repository hygiene contract** - `427a672` (test)
2. **Task 1 GREEN: Implement repository hygiene policy** - `71b5743` (feat)

## Files Created/Modified

- `dev/rendro/repository_hygiene.ex` - deterministic package, placement, consumer, inventory, and isolated-build policy.
- `dev/mix/tasks/quality/hygiene.ex` - single maintainer-facing Mix command.
- `priv/quality/package-members-v1.json` - exact reviewed expected package contract for the resolved boundary.
- `test/quality/repository_hygiene_test.exs` - focused mutation and isolation contract suite.

## Decisions Made

- Establish the resolved Plan 12 package boundary in a versioned manifest before changing package inputs, so integration must prove the intended final artifact rather than ratifying the old one.
- Keep the `gsd_tooling` exception named and isolated to `scripts/quality_governance.cjs`; it cannot confer product, release, package, or ordinary regression authority.

## Verification

- `mix test test/quality/repository_hygiene_test.exs` — passed (6 tests, 0 failures).
- `git diff --check` — passed.
- Created artifacts and both TDD commits were confirmed present.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Verification compatibility] Replaced unsupported `mix test -x` invocation**
- **Found during:** Task 1 verification
- **Issue:** Elixir 1.19's `mix test` does not support the plan's `-x` option.
- **Fix:** Ran the equivalent focused command without `-x`.
- **Files modified:** None
- **Verification:** `mix test test/quality/repository_hygiene_test.exs` passed.
- **Committed in:** N/A

---

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** No scope change; the focused suite remains deterministic and passed.

## Known Stubs

None.

## Issues Encountered

- `mix quality.hygiene` intentionally reports the still-package-visible raw proof files until Plan 12 removes them and wires the gate. The isolated policy itself and focused mutation suite are complete; this is the planned integration sequence, not a certified green package result.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 12 can remove the seven resolved raw/static paths, wire this sole command into local/CI/release surfaces, and then run it against the real unpacked artifact.

## Self-Check: PASSED

- All four planned artifacts exist.
- TDD commits `427a672` and `71b5743` exist.

---
*Phase: 133-repository-evidence-hygiene*
*Completed: 2026-08-26*

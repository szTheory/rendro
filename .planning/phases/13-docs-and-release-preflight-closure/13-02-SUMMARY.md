---
phase: 13-docs-and-release-preflight-closure
plan: "02"
subsystem: infra
tags: [release-preflight, hex, git, mix-task]
requires:
  - phase: 13-docs-and-release-preflight-closure
    provides: executable docs-contract gate
provides:
  - strict two-phase release preflight task
  - package metadata sufficient for hex build unpack validation
  - regression coverage for blocker ordering and single-final-exit behavior
affects: [QUAL-04, release-automation]
tech-stack:
  added: []
  patterns: [boundary-first release gates, command-runner seams]
key-files:
  created: [test/mix/tasks/release_preflight_test.exs]
  modified: [mix.exs, lib/mix/tasks/release/preflight.ex]
key-decisions:
  - "Release preflight now treats dirty trees and exact-tag mismatch as hard phase-1 blockers."
  - "Expensive release checks run as subprocesses and aggregate into one final summary instead of relying on in-process Mix aliases."
patterns-established:
  - "Mix task regression tests use injected command runners plus Mix.Shell.Process for output-order assertions."
requirements_completed: [QUAL-04]
duration: 20 min
completed: 2026-04-28
---

# Phase 13 Plan 02: Release Preflight Summary

**Boundary-first release preflight with package metadata validation, subprocess-backed parity checks, and ordered regression coverage**

## Performance

- **Duration:** 20 min
- **Started:** 2026-04-28T15:01:40Z
- **Completed:** 2026-04-28T15:21:40Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added truthful Hex package metadata so `mix hex.build --unpack` succeeds locally.
- Rebuilt `mix release.preflight` into a strict two-phase task that stops on dirty/tag blockers before expensive checks.
- Added regression coverage proving blocker-first ordering and one final summary/exit after phase 2.

## Files Created/Modified
- `mix.exs` - Added package metadata required for Hex package verification.
- `lib/mix/tasks/release/preflight.ex` - Strict release gate with boundary-first and aggregated phases.
- `test/mix/tasks/release_preflight_test.exs` - Ordering and exit semantics coverage.

## Decisions Made
- Use `UNLICENSED` package metadata rather than inventing an unsupported open-source license claim for the Hex package surface.
- Keep release parity checks authoritative by shelling out to `mix` subprocesses instead of simulating those commands in-process.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- A synthetic Hex-availability blocker was removed because it failed under the test VM while the real `mix hex.*` subprocesses were available and already served as the authoritative proof surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `mix verify` and `mix release.preflight` can now be rewired to the same named docs gate.
- The reusable isolated proof command now exists and the exact-tag happy path is covered by the committed helper, tests, and hosted CI wiring added after this summary's original execution point.

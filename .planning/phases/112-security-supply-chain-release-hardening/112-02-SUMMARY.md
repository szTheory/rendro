---
phase: 112-security-supply-chain-release-hardening
plan: 02
subsystem: infra
tags: [github-actions, ci, security]

# Dependency graph
requires: []
provides:
  - "Advisory PR audit lane"
  - "Nightly actionable audit lane"
affects: [".github/workflows/ci.yml"]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Separated advisory PR checks vs actionable nightly workflows for security audits"]

key-files:
  created: [".github/workflows/audit.yml"]
  modified: [".github/workflows/ci.yml"]

key-decisions:
  - "Split security audits: advisory and non-blocking in PRs, strict and actionable nightly."
  - "Used `peter-evans/create-issue-from-file@fca9117...` to automatically open issues on nightly failure."

patterns-established:
  - "Advisory CI checks do not block the pipeline."
  - "Nightly strict workflows open actionable tracking issues upon failure."

requirements-completed: [D-04, D-05]

# Metrics
duration: 5m
completed: 2026-06-16
---

# Phase 112: Security Supply Chain Release Hardening Summary

**Introduced separated security audit lanes to give immediate, non-blocking feedback on PRs while maintaining a strict, actionable nightly audit for maintainers.**

## Performance

- **Duration:** 5m
- **Started:** 2026-06-16
- **Completed:** 2026-06-16
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added an advisory `security-audit` job to `.github/workflows/ci.yml` that checks `mix deps.audit` and `mix hex.audit` but is set to `continue-on-error: true`. It is added to the `needs` of `ci-success`.
- Created a separate `.github/workflows/audit.yml` nightly workflow that fails strictly.
- Configured the nightly workflow to open a tracking issue using `peter-evans/create-issue-from-file` on failure.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Advisory Audit Job to CI** - `cc95f79` (feat)
2. **Task 2: Create Nightly Audit Workflow** - `d2fcb84` (feat)

## Files Created/Modified
- `.github/workflows/ci.yml` - Modified to add the non-blocking `security-audit` job.
- `.github/workflows/audit.yml` - Created for the strict nightly audit check.

## Decisions Made
- Used a temporary `/tmp/audit-failure.md` file dynamically generated on failure in the nightly audit to populate the issue body with the run ID.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## Threat Flags
None.

## User Setup Required
None.

## Next Phase Readiness
- Security audit lanes are fully segregated and configured.

---
*Phase: 112-security-supply-chain-release-hardening*
*Completed: 2026-06-16*
---
phase: 112-security-supply-chain-release-hardening
plan: 03
subsystem: infra
tags: [github-actions, ci, security, release]

# Dependency graph
requires: []
provides:
  - "Hardened release validation and environment gate"
affects: [".github/workflows/release.yml"]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Environment-based human approval gate for releases", "Version assertion between Git tag and mix.exs"]

key-files:
  created: []
  modified: [".github/workflows/release.yml"]

key-decisions:
  - "Split release process into a validate-and-dry-run job and a publish job."
  - "Require strict version match between GITHUB_REF_NAME and mix.exs @version before allowing publish."
  - "Scope Hex API key solely to the 'Hex Publish' environment."

patterns-established:
  - "Strict environment gates and dry-run validation prior to publishing"

requirements-completed: [D-06, D-07]

# Metrics
duration: 5m
completed: 2026-06-16
---

# Phase 112: Security Supply Chain Release Hardening Summary

**Hardened the release pipeline with deterministic version matching and strict environment-based human approval.**

## Performance

- **Duration:** 5m
- **Started:** 2026-06-16
- **Completed:** 2026-06-16
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Refactored `.github/workflows/release.yml` to split the `publish` job into `validate-and-dry-run` and `publish` jobs.
- Added a shell script step to assert that the pushed Git tag exactly matches the `@version` inside `mix.exs`.
- Isolated the `HEX_API_KEY` to the `publish` job under the `Hex Publish` environment, which blocks automated access until human approval is given.
- Verified dry run functionality in the validation phase without needing the scoped secret.

## Task Commits

Each task was committed atomically:

1. **Task 1: Hardened Release Validation and Publish Gate** - `44d91f7` (feat)

## Files Created/Modified
- `.github/workflows/release.yml` - Modified to enforce environment gates and version matching

## Decisions Made
- Added a manual assertion on the tag against the `mix.exs` version to stop a build immediately if there is a mismatch, preventing botched package names.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: Mitigation | `.github/workflows/release.yml` | Prevented automated escalation to publication privileges by using an environment gate (T-112-03) and tag spoofing by verifying `mix.exs` version (T-112-04). |

## User Setup Required
- **Location**: GitHub Settings -> Environments
- **Task**: Create GitHub Environment named 'Hex Publish'
- **Task**: Require manual approval from specific maintainers on the environment
- **Task**: Scope `HEX_API_KEY` secret *only* to this environment (remove from repository secrets)

## Next Phase Readiness
- The release pipeline is now secured with version validation and environmental gates.

---
*Phase: 112-security-supply-chain-release-hardening*
*Completed: 2026-06-16*
---
phase: 80-stability-contract-migration-docs
plan: "03"
subsystem: documentation
tags: [exdoc, guides, api-stability, hexdocs, semver, upgrade-guide]

# Dependency graph
requires:
  - phase: 80-stability-contract-migration-docs (80-01)
    provides: rewritten guides/api_stability.md with Tier-1/Tier-2 headings and Per-Surface Support Boundaries section
provides:
  - "guides/upgrading_to_1.0.md: reassurance-first upgrade guide with two-tier contract summary, what's-new digest, support-matrix pointer, and generic CHANGELOG link"
  - "mix.exs ExDoc wiring: upgrading_to_1.0.md in both extras list and groups_for_extras Policies group"
affects: [80-04, 81-release-hardening, phase-82-publish]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Upgrade guide authoring: D-11 reassurance-first opening, tier summary, what's-new digest, support-matrix pointer, generic CHANGELOG link (no anchor)"
    - "ExDoc Policies group wiring: extras + groups_for_extras both updated atomically"

key-files:
  created:
    - guides/upgrading_to_1.0.md
  modified:
    - mix.exs

key-decisions:
  - "D-11 applied: guide opens with 'it's a commitment, not a rewrite' and leads with tier summary"
  - "D-12 enforced: CHANGELOG link is generic ../CHANGELOG.md with no anchor fragment (Phase 82 writes that section)"
  - "Checkpoint auto-approved (AUTO_MODE): Policies sidebar confirmed programmatically via sidebar_items JSON (api_stability, upgrading_to_1-0, viewer_evidence)"

patterns-established:
  - "Upgrade guide cross-link convention: backtick-quoted paths for file refs, named section pointer for api_stability.md"

requirements-completed:
  - STAB-03

# Metrics
duration: 1min
completed: 2026-05-30
---

# Phase 80 Plan 03: Upgrade Guide Creation and ExDoc Wiring Summary

**`guides/upgrading_to_1.0.md` created with reassurance-first D-11 content and wired into the ExDoc Policies group alongside api_stability and viewer_evidence; `mix test test/docs_contract/` 103 tests 0 failures.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-05-30T19:22:57Z
- **Completed:** 2026-05-30T19:24:00Z
- **Tasks:** 2 (+ 1 auto-approved checkpoint)
- **Files modified:** 2

## Accomplishments

- Created `guides/upgrading_to_1.0.md` with D-11 reassurance-first structure: opening sentence "1.0 is a stability commitment, not a rewrite", Tier-1/Tier-2 contract summary, what's-new digest, support-matrix pointer, and generic CHANGELOG link (no anchor fragment per D-12)
- Wired the guide into `mix.exs` in both the `extras` list and the `groups_for_extras` Policies group, positioned between `api_stability.md` and `viewer_evidence.md`
- Verified: `mix docs` exits 0; sidebar JSON confirms `['api_stability', 'upgrading_to_1-0', 'viewer_evidence']` in Policies group; `mix test test/docs_contract/` 103 tests 0 failures
- Auto-approved checkpoint: programmatically verified the guide renders under Policies (bottom-actions-button navigation confirms api_stability → upgrading → viewer_evidence sequence)

## Task Commits

1. **Task 1: Create guides/upgrading_to_1.0.md** - `c0fa22c` (docs)
2. **Task 2: Wire into mix.exs ExDoc** - `2ba17ae` (chore)

**Plan metadata:** (final commit below)

## Files Created/Modified

- `/Users/jon/projects/rendro/guides/upgrading_to_1.0.md` - New upgrade guide: reassurance-first, two-tier summary, what's-new digest, support-matrix pointer, generic CHANGELOG link
- `/Users/jon/projects/rendro/mix.exs` - Added upgrading_to_1.0.md to extras list (line 113) and Policies group (line 127)

## Decisions Made

- D-11 applied as specified: reassurance-first opening, tier summary, digest, support-matrix pointer
- D-12 enforced: `[CHANGELOG.md](../CHANGELOG.md)` with no `#` anchor fragment — the `## [1.0.0]` section is unwritten until Phase 82; the generic link is safe and won't be a broken anchor
- Checkpoint auto-approved per AUTO_MODE: used sidebar JSON introspection to confirm Policies group membership programmatically rather than blocking for human browser verification

## Deviations from Plan

None — plan executed exactly as written. The `mix docs` CHANGELOG.md warning (`documentation references file "../CHANGELOG.md" but it does not exist`) is expected: the generic link is intentional (D-12), and the warning does not prevent docs generation or cause exit non-zero.

## Issues Encountered

None.

## Threat Surface Scan

No new security-relevant surface introduced. The new guide is a static markdown document with no network endpoints, auth paths, file access patterns, or schema changes. The banned-phrase constraints (T-80-07) were verified: no "secure PDF", "PAdES is supported", or "PDF/A compliant" phrases appear.

The CHANGELOG forward-pointer (T-80-08) uses `[CHANGELOG.md](../CHANGELOG.md)` with no anchor fragment — confirmed via `grep -n "CHANGELOG.md#" guides/upgrading_to_1.0.md` returning 0 matches.

## Known Stubs

None. The guide contains no placeholder text, hardcoded empty values, or components with unwired data sources.

## Next Phase Readiness

- `guides/upgrading_to_1.0.md` exists and is ExDoc-wired: Plan 80-04 (STAB-05 claims test) can now assert `File.exists?("guides/upgrading_to_1.0.md")` without false-pass risk
- Policies sidebar group complete with all three planned guides: api_stability, upgrading_to_1.0, viewer_evidence
- No blockers for Phase 81 (Release Hardening)

## Self-Check

Checking key artifacts:
- `guides/upgrading_to_1.0.md` exists: FOUND
- Commit `c0fa22c` (Task 1): exists in git log
- Commit `2ba17ae` (Task 2): exists in git log
- `mix test test/docs_contract/` exits 0: CONFIRMED (103 tests, 0 failures)
- `grep "upgrading_to_1.0" mix.exs | wc -l` = 2: CONFIRMED
- `grep -n "CHANGELOG.md#" guides/upgrading_to_1.0.md` = 0: CONFIRMED

## Self-Check: PASSED

---
*Phase: 80-stability-contract-migration-docs*
*Completed: 2026-05-30*

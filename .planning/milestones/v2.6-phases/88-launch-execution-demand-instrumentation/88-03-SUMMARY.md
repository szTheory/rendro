---
phase: 88-launch-execution-demand-instrumentation
plan: 03
subsystem: github-intake
tags: [github, issues, adoption, triage, low-maintenance]

requires:
  - phase: 88-02
    provides: Root ADOPTION.md ledger and counting rules
provides:
  - Remote GitHub label vocabulary for triage and adoption review
  - Issue-only intake templates for bugs and blocked documents
  - Disabled Discussions surface to keep community maintenance lightweight
affects: [github-intake, adoption-ledger, launch-routing, maintainer-workflow]

tech-stack:
  added: []
  patterns:
    - Public adopter intake should default to Issues plus ADOPTION.md, not a second community surface
    - `gh` and LLM triage are preferred for OSS intake scanning and routing

key-files:
  created:
    - .github/ISSUE_TEMPLATE/01_bug.yml
    - .github/ISSUE_TEMPLATE/02_blocked_document.yml
    - .github/ISSUE_TEMPLATE/config.yml
  modified:
    - test/docs_contract/github_intake_claims_test.exs

key-decisions:
  - "Use Issues as the single OSS intake surface for Phase 88; skip GitHub Discussions because the maintainer prefers lightweight, hands-off triage that works well with `gh` and LLM review."
  - "Disable the remote Discussions feature after it was temporarily enabled during execution."
  - "Keep `adoption:counted` maintainer-applied only; blocked-document issues default to `adoption:signal`."

patterns-established:
  - "Issue-only intake: blank issues disabled, structured issue forms enabled, ADOPTION.md linked, and no discussion template committed."
  - "Labels can support triage, but the ledger remains the counting source of truth."

requirements-completed: [LNCH-03]

duration: 9 min
completed: 2026-06-12
---

# Phase 88 Plan 03: GitHub Intake Summary

**Issue-only GitHub intake with structured bug and blocked-document forms, remote labels, and no Discussions surface**

## Performance

- **Duration:** 9 min
- **Started:** 2026-06-12T14:26:00Z
- **Completed:** 2026-06-12T14:35:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Created the locked Phase 88 remote label vocabulary through `gh label create/edit`.
- Added `.github/ISSUE_TEMPLATE/01_bug.yml` for reproducible defects with `state:triage` and `kind:bug`.
- Added `.github/ISSUE_TEMPLATE/02_blocked_document.yml` for concrete unsupported document jobs with `state:triage` and `adoption:signal`.
- Added `.github/ISSUE_TEMPLATE/config.yml` with blank issues disabled and public links to `ADOPTION.md` and ElixirForum.
- Disabled GitHub Discussions remotely and removed the uncommitted discussion template path.
- Updated GitHub intake docs-contract tests to lock issue-only intake.

## Task Commits

1. **Task 1: Create labels and issue templates for bugs and blocked documents** - `13336df` (feat)
2. **Task 2: Keep intake issue-only after maintainer preference checkpoint** - `60d1f49` (docs)

**Plan metadata:** pending in this commit

## Verification

- `gh api repos/szTheory/rendro --jq '.has_discussions'` - returned `false`.
- Remote label check for all D-34 labels - passed.
- `find .github/ISSUE_TEMPLATE -maxdepth 1 -type f -name '*.yml' | sort` - listed only `01_bug.yml`, `02_blocked_document.yml`, and `config.yml`.
- `find .github/DISCUSSION_TEMPLATE -maxdepth 1 -type f` - returned no files.
- `mix test test/docs_contract/github_intake_claims_test.exs` - passed, 6 tests, 0 failures.
- `mix docs.contract` - passed after the issue-only revision.

## Files Created/Modified

- `.github/ISSUE_TEMPLATE/01_bug.yml` - Structured bug report form.
- `.github/ISSUE_TEMPLATE/02_blocked_document.yml` - Structured blocked-document/adoption-signal form.
- `.github/ISSUE_TEMPLATE/config.yml` - Blank issues disabled; public resources linked without Discussions.
- `test/docs_contract/github_intake_claims_test.exs` - Issue-only static contract.

## Decisions Made

- Skipped the planned `Use cases` Discussions category and discussion template.
- Recorded maintainer preference: keep OSS community intake lightweight and hands-off; use Issues as the intuitive dumping ground because they are efficient to scan and triage with `gh` plus LLM workflows.
- Kept remote Discussions disabled to avoid a visible second inbox that would require monitoring.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 4 - Scope Preference] Switched from Discussions + Issues to issue-only intake**

- **Found during:** Task 2 checkpoint.
- **Issue:** The original plan required a `Use cases` Discussions category, but the maintainer explicitly rejected the extra community surface as too high-maintenance.
- **Fix:** Disabled Discussions, removed the discussion template, updated issue chooser routing, and changed docs-contract tests to assert no discussion-template surface exists.
- **Files modified:** `.github/ISSUE_TEMPLATE/config.yml`, `test/docs_contract/github_intake_claims_test.exs`.
- **Verification:** `gh api repos/szTheory/rendro --jq '.has_discussions'` returned `false`; GitHub intake tests and docs-contract passed.
- **Committed in:** `60d1f49`.

---

**Total deviations:** 1 scope/preference change.
**Impact on plan:** The adoption signal path is simpler and better aligned with maintainer workflow. LNCH-03 still has concrete intake through issues and `ADOPTION.md`.

## Issues Encountered

- GitHub Discussions was briefly enabled via API while exploring the original checkpoint. It was disabled again after the issue-only decision.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 88-04: mobile viewer evidence can be recorded without relying on Discussions. Launch copy and issue templates should route concrete blocked documents to Issues and the `ADOPTION.md` ledger.

---
*Phase: 88-launch-execution-demand-instrumentation*
*Completed: 2026-06-12*

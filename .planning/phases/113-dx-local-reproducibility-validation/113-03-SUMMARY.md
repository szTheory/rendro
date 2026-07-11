---
phase: 113-dx-local-reproducibility-validation
plan: 03
subsystem: infra
tags: [validation, metrics, ci, c1]

# Dependency graph
requires:
  - phase: 108-baseline-audit-report
    provides: "Baseline CI timing and bottleneck evidence"
  - phase: 113-dx-local-reproducibility-validation
    provides: "Local CI aliases, docs, and ci-success badge"
provides:
  - "C1 validation metrics report"
  - "C1 audit closure summary"
  - "Green local ci.fast validation gate"
affects: [c1-milestone, ci-validation, release-notes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Separate local validation evidence from remote Actions evidence when local commits have not yet run on CI."

key-files:
  created:
    - ".planning/phases/113-dx-local-reproducibility-validation/113-METRICS.md"
  modified:
    - ".planning/milestones/C1-AUDIT.md"
    - "mix.exs"
    - "test/mix/tasks/ci_alias_contract_test.exs"
    - "test/docs_contract/pdfjs_advisory_claims_test.exs"
    - "lib/rendro/pipeline/paginate.ex"
    - "lib/rendro/pdf/writer.ex"
    - "test/rendro/pipeline/paginate_test.exs"

key-decisions:
  - "Do not claim post-C1 remote p50/p95 or cache-hit rates until these local commits have run on GitHub Actions."
  - "Treat local ci.fast as the available final gate for this checkout."

patterns-established:
  - "Validation reports must label evidence source and measurement gaps explicitly."

requirements-completed: [VAL-01, VAL-02]

# Metrics
duration: 35m
completed: 2026-07-10
status: complete
---

# Phase 113 Plan 03: C1 Validation Metrics Summary

**C1 now has a validation report, audit closure, and a green local `mix ci.fast` gate with remote timing gaps labeled explicitly.**

## Performance

- **Duration:** 35m
- **Started:** 2026-07-10T22:24:00Z
- **Completed:** 2026-07-10T22:59:00Z
- **Tasks:** 2
- **Files modified:** 21

## Accomplishments

- Created `113-METRICS.md` with Phase 108 baseline comparison, post-push remote run evidence, local final gate details, and steady-state pipeline design.
- Appended `## Phase 113 Validation Summary` to `C1-AUDIT.md`.
- Verified the current local fast gate with `mix ci.fast` successfully: 1219 tests, 12 doctests, 4 properties, 0 failures, Credo clean, Dialyzer 0 errors.
- Preserved truthfulness by recording remote GitHub p50/p95 and cache evidence only after collecting three green `ci.yml` runs.

## Task Commits

Each planned task was committed atomically:

1. **Task 1: Generate 113-METRICS.md validation report** - `01f44b2` (docs)
2. **Task 2: Append validation summary to C1-AUDIT.md** - `c4fbf85` (docs)

Validation blocker fixes committed during this plan:

- `6db5c72` - Format committed files that blocked `mix ci.fast`.
- `2625b21` - Add preferred environments for scoped CI aliases and update alias contracts.
- `6546226` - Refresh PDF.js advisory and Credo contracts.
- `30c34e8` - Remove dead pagination metadata fallback to clear Dialyzer warnings.

## Files Created/Modified

- `.planning/phases/113-dx-local-reproducibility-validation/113-METRICS.md` - Final C1 validation metrics and evidence report.
- `.planning/milestones/C1-AUDIT.md` - Phase 113 closure summary.
- `mix.exs` - Preferred environments for scoped CI aliases.
- `test/mix/tasks/ci_alias_contract_test.exs` - Split alias and preferred-env contract.
- `test/docs_contract/pdfjs_advisory_claims_test.exs` - Advisory contract aligned with `ci.advisory`.
- `lib/rendro/pipeline/paginate.ex` - Dialyzer-safe metadata usage.
- `lib/rendro/pdf/writer.ex` and related test files - Formatting/Credo cleanup required for strict gate.

## Decisions Made

- Remote timing improvement was claimed only after post-push GitHub runs `29133061301`, `29133777702`, and `29134266708` completed successfully.
- Local `mix ci.fast` was recorded as the final available gate for this checkout.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Committed format drift blocked `mix ci.fast`**
- **Found during:** Task 1 validation
- **Issue:** `mix format --check-formatted` failed on committed source/test files from earlier work.
- **Fix:** Ran `mix format` and committed only mechanical formatting changes.
- **Files modified:** 14 source/test files.
- **Verification:** `mix ci.fast` advanced past the format gate.
- **Committed in:** `6db5c72`

**2. [Rule 3 - Blocking] Scoped CI aliases lacked preferred test environments**
- **Found during:** Task 1 validation
- **Issue:** `mix ci.fast` reached `mix test` in `dev`, causing Mix to abort.
- **Fix:** Added preferred envs for `ci.fast`, `ci.proofs`, `ci.advisory`, `verify.flake`, and `test.all`; updated alias contracts.
- **Files modified:** `mix.exs`, `test/mix/tasks/ci_alias_contract_test.exs`.
- **Verification:** Alias/guardrail tests passed.
- **Committed in:** `2625b21`

**3. [Rule 3 - Blocking] Existing strict gates rejected the new advisory alias and stale code style**
- **Found during:** Task 1 validation
- **Issue:** PDF.js advisory contract still rejected any `pdfjs_observer` mention in `mix.exs`, and Credo strict found stale findings.
- **Fix:** Narrowed the PDF.js contract to Mix deps, asserted the advisory alias explicitly, and fixed Credo findings.
- **Files modified:** `test/docs_contract/pdfjs_advisory_claims_test.exs`, `lib/rendro/pipeline/paginate.ex`, `lib/rendro/pdf/writer.ex`, `test/rendro/pipeline/paginate_test.exs`.
- **Verification:** Focused tests and `mix credo --strict` passed.
- **Committed in:** `6546226`

**4. [Rule 3 - Blocking] Dialyzer rejected impossible nil metadata fallbacks**
- **Found during:** Task 1 validation
- **Issue:** Dialyzer flagged guard failures from `doc.metadata || %Rendro.Metadata{}` in `Rendro.Document.t()`.
- **Fix:** Used the required metadata struct directly.
- **Files modified:** `lib/rendro/pipeline/paginate.ex`.
- **Verification:** `mix dialyzer` passed, then full `mix ci.fast` passed.
- **Committed in:** `30c34e8`

---

**Total deviations:** 4 auto-fixed blockers.  
**Impact on plan:** The fixes were necessary to make the validation report truthful; no library behavior changes were introduced beyond removing dead fallback code aligned with the existing type contract.

## Issues Encountered

- Initial remote GitHub Actions runs predated the local phase 113 work, so remote p50/p95 and cache-hit metrics were not claimed until the C1 validation branch produced three green runs.

## Verification

- `gh run list --workflow=ci.yml --limit 10 --json databaseId,displayTitle,headBranch,status,conclusion,createdAt,updatedAt,event,url`
- `gh run view 27512247437 --json databaseId,displayTitle,createdAt,updatedAt,conclusion,jobs,url`
- `gh run view 27443757934 --json databaseId,displayTitle,createdAt,updatedAt,conclusion,jobs,url`
- `gh run view 27441368861 --json databaseId,displayTitle,createdAt,updatedAt,conclusion,jobs,url`
- `mix test test/mix/tasks/ci_alias_contract_test.exs test/guardrails/required_checks_contract_test.exs`
- `mix test test/docs_contract/pdfjs_advisory_claims_test.exs test/rendro/pipeline/paginate_test.exs`
- `mix credo --strict --format oneline`
- `mix dialyzer`
- `mix ci.fast`
- `grep -q "Phase 113 Validation Summary" .planning/milestones/C1-AUDIT.md`
- `gh run view 29133061301 --json databaseId,status,conclusion,createdAt,updatedAt,url,headSha,jobs`
- `gh run view 29133777702 --json databaseId,status,conclusion,createdAt,updatedAt,url,headSha,jobs`
- `gh run view 29134266708 --json databaseId,status,conclusion,createdAt,updatedAt,url,headSha,jobs`

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 113 is complete locally and remotely. Post-push GitHub p50/p95 and cache-hit data are recorded in `113-METRICS.md` and the milestone audit.

---
*Phase: 113-dx-local-reproducibility-validation*
*Completed: 2026-07-10*

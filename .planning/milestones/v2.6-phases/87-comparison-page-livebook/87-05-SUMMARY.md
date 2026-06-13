---
phase: 87-comparison-page-livebook
plan: 05
subsystem: docs-package-ci
tags: [exdoc, hex-package, readme, advisory-ci, guardrails]

requires:
  - phase: 87-03
    provides: Benchmark-bound comparison guide
  - phase: 87-04
    provides: First-invoice Livebook tutorial and static check task
provides:
  - ExDoc extras for the comparison guide and Livebook tutorial
  - Hex package inclusion for comparison docs and benchmark evidence
  - README guide links for comparison and first-invoice Livebook paths
  - Advisory CI contexts for comparison and Livebook static checks
affects: [exdoc, readme, hex-package, ci, guardrails]

tech-stack:
  added: []
  patterns:
    - Hex package contents are verified by building and inspecting the package tarball
    - Advisory CI contexts stay graph-disconnected and absent from required_contexts
    - Required test job negative assertions protect mix ci from external-tool drift

key-files:
  created: []
  modified:
    - mix.exs
    - README.md
    - .github/workflows/ci.yml
    - priv/guardrails/required_status_checks.json
    - test/docs_contract/comparison_claims_test.exs
    - test/guardrails/required_checks_contract_test.exs

key-decisions:
  - "Comparison and Livebook docs are grouped under Evaluation in ExDoc."
  - "bench/results ships in the Hex package so public comparison evidence is inspectable with the release artifact."
  - "comparison-advisory and livebook-advisory are advisory status contexts only, with continue-on-error and no needs edge."

patterns-established:
  - "Docs contracts now assert ExDoc extras, README guide links, package manifest inclusion, and raw artifact inclusion."
  - "Guardrail tests parse ci.yml as YAML and prove advisory jobs are non-blocking."
  - "Required CI contamination checks now reject comparison, Livebook, Chrome, wkhtmltopdf, Typst, Kino, and Docker fragments in the test job."

requirements-completed: [CMP-02, CMP-03]

duration: 6 min
completed: 2026-06-11
---

# Phase 87 Plan 05: Public Docs And Advisory CI Wiring Summary

**Comparison guide and Livebook tutorial are discoverable in docs/package output without contaminating required CI**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-11T21:33:00Z
- **Completed:** 2026-06-11T21:38:55Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Registered `guides/comparison.md` and `guides/livebook/first_invoice.livemd` as ExDoc extras under an Evaluation group.
- Added `bench/results` to Hex package contents so `bench/results/comparison.json` and raw benchmark artifacts ship with the release package.
- Added compact README guide links for the comparison guide and first-invoice Livebook tutorial.
- Added graph-disconnected `comparison-advisory` and `livebook-advisory` CI jobs that run only static checks.
- Extended docs-contract and guardrail tests to prove ExDoc registration, README links, Hex package inclusion, advisory context metadata, YAML parseability, non-blocking advisory jobs, and required test-job isolation.

## Task Commits

1. **Task 1-3: Docs/package/README/advisory CI wiring** - `fa73e48` (feat)

**Plan metadata:** pending in this commit

## Files Created/Modified

- `mix.exs` - ExDoc extras/group and `bench/results` package inclusion.
- `README.md` - Compact guide links for comparison and Livebook tutorial.
- `.github/workflows/ci.yml` - Advisory comparison and Livebook static-check jobs.
- `priv/guardrails/required_status_checks.json` - Advisory context definitions.
- `test/docs_contract/comparison_claims_test.exs` - ExDoc, README, and package-content assertions.
- `test/guardrails/required_checks_contract_test.exs` - Advisory context/job and required-lane isolation assertions.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- `mix docs` still emits pre-existing hidden-module and `../CHANGELOG.md` warnings, but exits 0. No new comparison/Livebook undefined-reference failures were introduced.

## User Setup Required

None.

## Verification

- `mix test test/docs_contract/comparison_claims_test.exs` - passed, 10 tests.
- `mix test test/guardrails/required_checks_contract_test.exs` - passed, 17 tests.
- `mix docs` - passed with pre-existing warnings.
- `mix hex.build` - passed; output listed comparison guide, Livebook tutorial, manifest, and raw artifacts.
- `test ! -f rendro-1.0.0.tar` - passed after removing the generated package tarball.
- `git diff --check` - passed.

## Next Phase Readiness

Plan 06 can run final regeneration, fairness review, full static/advisory verification, and phase closure. All comparison and Livebook public surfaces are now wired into docs, package output, README, and advisory CI.

## Self-Check: PASSED

- Both public docs paths are ExDoc extras and README guide links.
- Hex package inspection proves the benchmark manifest and raw result artifacts ship.
- Advisory CI contexts are present, non-blocking, and absent from required contexts.
- Required `test` job remains `mix ci` without comparison, Livebook, browser, Typst, Kino, or Docker fragments.

---
*Phase: 87-comparison-page-livebook*
*Completed: 2026-06-11*

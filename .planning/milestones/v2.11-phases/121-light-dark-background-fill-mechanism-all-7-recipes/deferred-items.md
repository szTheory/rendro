# Deferred Items — Phase 121

Out-of-scope discoveries logged during execution (SCOPE BOUNDARY: only auto-fix
issues directly caused by the current task's changes).

## Pre-existing failing tests (unrelated to Phase 121)

- `test/docs_contract/dx_local_reproducibility_claims_test.exs` — 2 failures:
  `could not read file ".planning/phases/113-dx-local-reproducibility-validation/113-METRICS.md"`
  and `...113-UAT.md` — both files are absent from the working tree
  independent of any Phase 121 change (confirmed via `git stash -u` against
  HEAD before this plan's commits). Phase 113 artifact state, not caused by
  Phase 121's Statement/Background work. Not fixed here — out of scope.

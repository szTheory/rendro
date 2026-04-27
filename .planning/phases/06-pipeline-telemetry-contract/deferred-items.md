# Phase 06 Deferred Items

Items discovered during execution that are out-of-scope for the current plan
(do NOT block merge of phase 06; address in a subsequent maintenance plan).

## Pre-existing `mix format --check-formatted` failures (not caused by Phase 06)

The following files were already unformatted before Plan 06-02 began (verified
via `git stash` to remove all Phase 06 changes — same files reported). They are
left untouched per the executor scope boundary rule:

- `lib/rendro/adapters/threadline.ex`
- `lib/rendro/adapters/mailglass.ex`
- `lib/rendro/recipes.ex`
- `lib/mix/tasks/verify.ex`
- `test/rendro/policy_test.exs`

Recommendation: a future maintenance plan can run `mix format` once across the
tree to clean these up. Phase 06's per-file format checks
(`mix format --check-formatted lib/rendro/pipeline.ex lib/rendro/pipeline/validate.ex
 test/rendro/pipeline/validate_test.exs test/rendro/telemetry_test.exs`)
all pass.

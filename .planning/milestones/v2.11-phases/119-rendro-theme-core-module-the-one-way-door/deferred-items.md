# Deferred Items — Phase 119

Out-of-scope discoveries found during execution. Logged, not fixed (scope boundary:
only auto-fix issues DIRECTLY caused by the current task's changes).

## Pre-existing, unrelated `mix test` failures (milestone-cleanup artifact)

**Found during:** Plan 02, Task 3 (full `mix test` phase gate).

Two failures in `test/docs_contract/dx_local_reproducibility_claims_test.exs` (lines 77
and 103) are **pre-existing** and **unrelated to Phase 119**:

```
1) dx_local_reproducibility_claims_test.exs:77
   (File.Error) could not read file
   ".planning/phases/113-dx-local-reproducibility-validation/113-METRICS.md"
2) dx_local_reproducibility_claims_test.exs:103
   (File.Error) could not read file
   ".planning/phases/113-dx-local-reproducibility-validation/113-UAT.md"
```

**Root cause:** commit `0de2de8 chore: clear v2.10 phase directories for milestone v2.11`
(the last commit to touch `113-METRICS.md` — it deleted it) removed the phase-113
planning artifacts as part of the v2.11 milestone reset. The docs-contract test still
`File.read!`s those now-deleted paths. The failures existed before Plan 01/02 work began.

**Why out of scope:** the test touches no `Theme`, `public_api`, or `golden` code
(`grep -nE "Theme|public_api|golden"` returns nothing). It is a stale docs-contract test
pointing at deleted milestone planning files — orthogonal to the Theme one-way-door.

**Zero-recipe-change gate is satisfied independently of these failures:**
- `git status --porcelain priv/goldens` → empty (all 62 committed `.sha256` byte-identical)
- `git status --porcelain lib/rendro/recipes` → empty (zero recipe change)
- `MIX_GOLDEN_BLESS` unset throughout; no golden re-bless.

**Suggested owner:** whoever owns the v2.11 milestone-cleanup follow-up — either update
`dx_local_reproducibility_claims_test.exs` to tolerate archived/removed phase-113 planning
files, or restore/relocate the referenced 113 artifacts. Not a Phase 119 concern.

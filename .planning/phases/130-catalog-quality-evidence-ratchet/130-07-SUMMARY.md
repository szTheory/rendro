---
phase: 130-catalog-quality-evidence-ratchet
plan: "07"
subsystem: golden-reconciliation
tags: [elixir, deterministic-pdf, golden-hashes, staging, authorization]
requires:
  - phase: 130-01
    provides: authorized downstream Statement hierarchy repair
  - phase: 130-02
    provides: authorized downstream Certificate hierarchy repair
provides:
  - Detached exact-HEAD staging worktree for the Phase 130 reconciliation batch
  - Two human-authorized staged dark golden hash transitions
affects: [130-06, launch-reconciliation, catalog-quality-evidence]
tech-stack:
  added: []
  patterns:
    - Bind a golden blessing to explicit old/new SHA-256 authorization before the write
    - Keep reconciliation writes isolated in a detached exact-HEAD worktree until the later publication batch
key-files:
  created:
    - tmp/phase130-launch-reconcile/.phase130-baseline.json
  modified:
    - tmp/phase130-launch-reconcile/priv/goldens/statement/dark.sha256
    - tmp/phase130-launch-reconcile/priv/goldens/certificate/dark.sha256
key-decisions:
  - "Authorized exact two deterministic-only golden transitions: Statement aca31620062efd25c21d74c855d9ba50e65777a35068afc86387efe415063ec9 -> a971a8a7395ebbb3e1af9c54e236483c969a90b222af1a6fdedfccead587eab6; Certificate df9703ee72be0fa78d2fab8f064ca93eb70b4699801372ff9c24513aa5c4cdb1 -> acb99d40fc68d365d1c6b158e2cf335325563307e1828c90f39bd2a95aff07d1."
metrics:
  duration: 4m
  completed: 2026-08-20
  tasks: 3
  files: 2
status: complete
---

# Phase 130 Plan 07: Exact Golden Reconciliation Summary

**An exact-HEAD detached staging boundary and two explicitly authorized, assert-only-verified dark golden transitions, with canonical launch and evidence surfaces untouched.**

## Performance

- **Duration:** 4m
- **Started:** 2026-08-20T13:03:32Z
- **Completed:** 2026-08-20T13:07:32Z
- **Tasks:** 3/3
- **Staged files:** 2

## Accomplishments

- Re-verified the reconciliation worktree and main checkout at the same exact commit: `f8ee18d3d6504b3f4db58289efe1c6a5d178c419`.
- Re-validated the old golden refs, canonical launch manifest/gallery/manual/docs fence, rubric record, and SIGN-OFF record before blessing.
- Recorded the human selection `authorize-exact-two`, strictly limited to the two approved deterministic PDF hash transitions.
- Blessed and assert-only verified the Statement and Certificate dark golden refs inside `tmp/phase130-launch-reconcile`; its tracked diff is exactly those two one-line files.
- Kept main-worktree goldens and all canonical launch/evidence/catalog surfaces unchanged. The staged refs remain uncommitted for Plan 06’s reviewed publication batch.

## Authorization Record

| Golden | Approved old SHA-256 | Approved new SHA-256 |
|---|---|---|
| Statement dark | `aca31620062efd25c21d74c855d9ba50e65777a35068afc86387efe415063ec9` | `a971a8a7395ebbb3e1af9c54e236483c969a90b222af1a6fdedfccead587eab6` |
| Certificate dark | `df9703ee72be0fa78d2fab8f064ca93eb70b4699801372ff9c24513aa5c4cdb1` | `acb99d40fc68d365d1c6b158e2cf335325563307e1828c90f39bd2a95aff07d1` |

This approval is deterministic byte-baseline authorization only. It does not authorize launch artifacts, catalog scores, SIGN-OFF records, rubric evidence, or any later checkpoint.

## Task Commits

No task commit was created. Task 1 is an intentionally ephemeral ignored worktree, Task 2 is a human decision, and Task 3 is intentionally left staged and uncommitted for Plan 06’s combined publication boundary.

## Verification

- Exact-HEAD and protected canonical/evidence baseline fence — pass.
- `MIX_GOLDEN_BLESS=true mix test test/rendro/recipes/theme_mode_background_golden_test.exs --max-failures 1` in staging — pass (7 tests).
- `mix test test/rendro/recipes/theme_mode_background_golden_test.exs --max-failures 1` in staging — pass (7 tests).
- Staging `git diff --check` — pass.
- Staging tracked diff names equal only `priv/goldens/statement/dark.sha256` and `priv/goldens/certificate/dark.sha256` — pass.
- Main checkout retains both pre-authorization golden hashes — pass.

## Deviations from Plan

None - plan executed exactly as written. The staging worktree’s untracked baseline metadata and local `_build`/`deps` directories were correctly treated as allowed local staging state, not tracked-boundary drift.

## Known Stubs

None.

## Threat Flags

None. The plan-declared authorization and staging-boundary mitigations were re-validated before the only write.

## Next Phase Readiness

Plan 06 may publish this pair only with its separately reviewed launch/evidence batch. No authority beyond these two deterministic refs was advanced.

## Self-Check: PASSED

- Reconciliation baseline and both staged golden files exist in the detached worktree.
- No staged golden commit exists by design; the final metadata commit records this plan’s authorization and boundaries only.

---

*Phase: 130-catalog-quality-evidence-ratchet*
*Completed: 2026-08-20*

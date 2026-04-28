---
phase: 13-docs-and-release-preflight-closure
plan: "03"
subsystem: infra
tags: [docs-contract, verify, release-proof, worktree]
requires:
  - phase: 13-docs-and-release-preflight-closure
    provides: strict release preflight and explicit docs lanes
provides:
  - named `mix docs.contract` gate
  - canonical verify and preflight wiring to the docs gate
  - isolated release-preflight proof helper with safety coverage
affects: [QUAL-02, QUAL-04, milestone-verification]
tech-stack:
  added: []
  patterns: [named proof surfaces, isolated worktree proof helpers]
key-files:
  created: [lib/mix/tasks/docs.contract.ex, test/mix/tasks/docs_contract_task_test.exs, scripts/release_preflight_proof.exs, test/scripts/release_preflight_proof_test.exs]
  modified: [lib/mix/tasks/verify.ex, lib/mix/tasks/release/preflight.ex, test/mix/tasks/verify_test.exs, test/mix/tasks/release_preflight_test.exs]
key-decisions:
  - "The canonical docs gate is a named Mix task that delegates to the existing script rather than duplicating docs logic."
  - "Release-proof automation refuses non-release refs and requires an explicit isolated worktree target."
patterns-established:
  - "Proof helpers load safely in tests without autorun and validate destructive inputs before mutating git state."
requirements_completed: [QUAL-02, QUAL-04]
duration: 26 min
completed: 2026-04-28
---

# Phase 13 Plan 03: Proof Surfaces Summary

**Named docs-contract and isolated release-proof command surfaces wired into verify/preflight automation**

## Performance

- **Duration:** 26 min
- **Started:** 2026-04-28T14:41:40Z
- **Completed:** 2026-04-28T15:07:28Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Added `mix docs.contract` as the stable rerunnable docs gate and rewired `mix verify` to use it.
- Repointed release preflight’s docs step to `mix docs.contract` so verification and release automation share one docs surface.
- Added an isolated preflight-proof helper and safety tests for explicit ref/worktree validation.

## Files Created/Modified
- `lib/mix/tasks/docs.contract.ex` - Named docs gate delegating to the script runner.
- `lib/mix/tasks/verify.ex` - Canonical docs gate wiring.
- `lib/mix/tasks/release/preflight.ex` - Phase-2 docs step now runs `mix docs.contract`.
- `scripts/release_preflight_proof.exs` - Isolated clean-tag proof helper.
- `test/mix/tasks/docs_contract_task_test.exs` - Named task regression coverage.
- `test/scripts/release_preflight_proof_test.exs` - Proof-helper safety coverage.

## Decisions Made
- Keep `mix docs.contract` as a thin delegator so there is one docs verification engine and one stable public command name.
- Make the proof helper fail early on ambiguous refs instead of trying to interpret branch state as release evidence.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The proof helper needed an ExUnit-aware autorun guard so tests could load the script module without executing it.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 13 now leaves both docs-contract and release-preflight surfaces rerunnable through named commands.
- The remaining manual proof is the real tagged happy-path run from a clean `vX.Y.Z` ref, which the new helper is designed to orchestrate.

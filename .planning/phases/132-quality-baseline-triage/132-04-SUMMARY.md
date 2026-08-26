---
phase: 132-quality-baseline-triage
plan: "04"
subsystem: quality-governance
tags: [ci, governance, validation, uat, nyquist]
requires:
  - phase: 132-03
    provides: "Fail-closed governance command, closed fixtures, and staged verifier handoff"
provides:
  - "Independent fail-closed quality-governance CI job in the ci-success roll-up"
  - "Terminal automated VALIDATION, UAT, summary coverage, and verifier evidence"
  - "Unexceptioned full governance validation after verifier regeneration"
affects: [133-repository-evidence-hygiene, 135-test-ci, 137-closure]
tech-stack:
  added: []
  patterns: [parsed CI topology contract, exact stale-verifier staging handoff, terminal automated evidence]
key-files:
  created: [.planning/phases/132-quality-baseline-triage/132-04-SUMMARY.md]
  modified: [.github/workflows/ci.yml, priv/guardrails/required_status_checks.json, test/guardrails/required_checks_contract_test.exs, .planning/phases/132-quality-baseline-triage/132-VALIDATION.md, .planning/phases/132-quality-baseline-triage/132-UAT.md, .planning/phases/132-quality-baseline-triage/132-02-SUMMARY.md, .planning/phases/132-quality-baseline-triage/132-VERIFICATION.md, scripts/quality_governance.cjs]
key-decisions:
  - "quality-governance is a ci-success roll-up member, never a second branch-protection context."
  - "Terminal automated evidence replaces Phase 132 completion gates while remote and visual evidence remains explicit advisory or deferral."
  - "Full governance expects the terminal phase state after verifier regeneration; staging remains limited to the exact immutable stale marker."
patterns-established:
  - "CI topology contracts parse YAML and registry JSON instead of relying on whole-file matching."
requirements-completed: [AUDIT-01, AUDIT-02, AUDIT-03, AUDIT-04]
coverage:
  - id: D1
    description: "Independent governance CI job is fail-closed through the sole ci-success context."
    requirement: AUDIT-01
    verification:
      - kind: unit
        ref: "mix test test/guardrails/required_checks_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Phase validation, UAT, coverage, and verifier results are terminal and automated."
    requirement: AUDIT-02
    verification:
      - kind: integration
        ref: "mix quality.governance"
        status: pass
      - kind: integration
        ref: "node --test scripts/quality_governance.cjs"
        status: pass
    human_judgment: false
duration: 29min
completed: 2026-08-26
status: complete
---

# Phase 132 Plan 04: Terminal Governance and Evidence Summary

**A fail-closed governance CI roll-up now backs terminal automated Phase 132 validation, UAT, and verifier evidence without changing runtime or rendered output.**

## Performance

- **Duration:** 29 min
- **Completed:** 2026-08-26T19:47:31Z
- **Tasks:** 2/2
- **Files modified:** 9

## Accomplishments

- Added a standalone pinned `quality-governance` CI job, rolled it into strict `ci-success`, and retained `ci-success` as the only required branch-protection context.
- Converted Phase 132 VALIDATION and four UAT checks to terminal automated evidence; AUDIT-04 coverage now cites executable classification, authority, and metric-mutation proof.
- Regenerated the verifier report to 12/12 terminal truths and passed full governance without stale-verifier flags.

## Task Commits

1. **Task 1: Require governance through ci-success** — `f2e2b47` (RED), `4f1da1a` (GREEN)
2. **Task 2: Terminalize VALIDATION, UAT, and summary after CI proof** — `9af2e41` (docs)
3. **Post-verifier correction** — `a892bae` (fix)

## Files Created/Modified

- `.github/workflows/ci.yml` — independent pinned governance job and strict roll-up edge.
- `priv/guardrails/required_status_checks.json` — governance as a non-advisory roll-up context while required contexts remain singular.
- `test/guardrails/required_checks_contract_test.exs` — parsed workflow/registry topology and weakening-mutation coverage.
- `132-VALIDATION.md`, `132-UAT.md`, and `132-02-SUMMARY.md` — terminal automated Phase 132 evidence.
- `132-VERIFICATION.md` — standard verifier's regenerated 12/12 terminal report.
- `scripts/quality_governance.cjs` — terminal full-mode expectation after phase closure.

## Decisions Made

- Keep CI governance independent and fail-closed, with `ci-success` as its only branch-protection surface.
- Preserve advisory and explicit-deferral authority boundaries without letting unavailable remote evidence block deterministic claims.
- Restrict the stale verifier exception to direct staging; post-regeneration full governance takes no exception.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Regression] Updated the Node full-mode test after terminal verifier regeneration.**
- **Found during:** Post-execution verification
- **Issue:** Its stale assertion expected an active backlog after all executor-owned blockers and the verifier report had become terminal.
- **Fix:** Assert that unexceptioned full mode accepts terminal phase artifacts while retaining fixture and staging-exception coverage.
- **Files modified:** `scripts/quality_governance.cjs`
- **Verification:** `node --test scripts/quality_governance.cjs`, `mix quality.governance`, and full local gates.
- **Committed in:** `a892bae`

**Total deviations:** 1 auto-fixed (Rule 1: 1). The correction aligns a phase-owned terminal-state test with the required post-verifier handoff; it adds no runtime scope.

## Verification

- `mix quality.governance` — pass
- `node --test scripts/quality_governance.cjs` — 4 passing tests
- `mix test test/guardrails/required_checks_contract_test.exs` — 28 passing tests
- `mix ci.fast`, `mix ci.proofs`, `mix format --check-formatted`, `mix credo --strict`, and `mix dialyzer` — pass
- Immutable baseline SHA-256 before and after: `f7a187ae4687cf0823e43786a0d58b8c571d94aded9fb79e540a998bd7b239be`

## Issues Encountered

The Plan 03 Node suite intentionally modeled the pre-closure backlog. Its post-verifier expectation required a narrow terminal-state correction, documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 132 closes with automated governance and terminal evidence. Later phases retain the documented advisory/explicit-deferral boundary for remote CI and renderer evidence.

## Self-Check: PASSED

- All task and correction commits (`f2e2b47`, `4f1da1a`, `9af2e41`, `a892bae`) exist.
- `132-VERIFICATION.md` is regenerated, `status: passed`, and has no `human_needed` or `human_verification` entry.
- No runtime, package, public API, rendered artifact, catalog output, dependency, or immutable baseline change occurred.

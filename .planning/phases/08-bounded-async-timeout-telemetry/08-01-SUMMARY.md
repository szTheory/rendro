---
phase: 08-bounded-async-timeout-telemetry
plan: 01
subsystem: adapters
tags: [oban, telemetry, threadline, verification]
requires:
  - phase: 06-pipeline-telemetry-contract
    provides: current telemetry-contract proof for correlated render lifecycle metadata
provides:
  - milestone-grade verification and Nyquist validation artifacts for Phase 08
  - machine-readable summary metadata aligned to Phase 08 requirement verdicts
affects: [ADPT-04, ADPT-05, OBS-02, OBS-04]
tech-stack:
  added: []
  patterns:
    - preserve mixed verdicts when later executable proof contradicts legacy execution narratives
    - use docs-contract tests as authoritative proof when they encode current public limitations
key-files:
  created:
    - .planning/phases/08-bounded-async-timeout-telemetry/08-VERIFICATION.md
    - .planning/phases/08-bounded-async-timeout-telemetry/08-VALIDATION.md
  modified:
    - .planning/phases/08-bounded-async-timeout-telemetry/08-01-SUMMARY.md
key-decisions:
  - Keep `ADPT-04` and `OBS-04` at `Partial` because the current Oban worker and timeout-audit proof surfaces do not close the original Phase 08 claim.
  - Keep `ADPT-05` at `Partial` because Phase 08 contributes Threadline-facing evidence but does not by itself close the broader recipe requirement later repaired in Phase 10.
patterns-established:
  - "Backfilled summaries use `requirements_completed` and expose only verification-backed `Done` verdicts."
requirements_completed: [OBS-02]
duration: legacy
completed: 2026-04-28
---

# Phase 08 Plan 01: Bounded Async Timeout Telemetry Summary

**Backfilled milestone verification for Phase 08 with mixed verdicts preserved from the current codebase**

## Objective

Inject render policy bounds into the Oban RenderWorker and make the Pipeline timeout path emit a telemetry exception.

## Verification-Aligned Outcome

- `OBS-02` remains explicitly closed through the current Threadline metadata-correlation suite.
- `ADPT-04` and `OBS-04` are intentionally `Partial` because the current codebase no longer proves async policy injection or timeout audit forwarding through Threadline.
- `ADPT-05` is also `Partial`: current adapter/docs proof keeps the Threadline-facing recipe story truthful, but the broader multi-adapter recipe closure belongs to later phase work.

## Original Execution Record

1. **Emit telemetry exception on render timeout**
   - The original phase intended to emit timeout telemetry and have Threadline observe timed-out renders.
2. **Inject policy bounds in Oban worker**
   - The original phase intended to merge job-arg policies into the Oban worker path and cover that behavior with a dedicated worker test.

## Current Truth Snapshot

- `test/rendro/policy_test.exs` still proves policy enforcement at the core render path.
- `test/rendro/adapters/threadline_test.exs` still proves correlated metadata for successful and failed non-timeout renders.
- `test/docs_contract/integrations_claims_test.exs` now explicitly proves timeout renders do not reach Threadline audit calls.
- `lib/rendro/adapters/oban/render_worker.ex` no longer contains the policy-injection step described by the original summary.

## Files Created/Modified

- `.planning/phases/08-bounded-async-timeout-telemetry/08-VERIFICATION.md` - canonical requirement verdicts and proof mapping.
- `.planning/phases/08-bounded-async-timeout-telemetry/08-VALIDATION.md` - Nyquist validation contract for the artifact backfill.
- `.planning/phases/08-bounded-async-timeout-telemetry/08-01-SUMMARY.md` - normalized summary metadata driven by the verification verdicts.

---
phase: 15-async-policy-injection-timeout-audit-closure
plan: 02
subsystem: observability
tags: [telemetry, timeout, threadline, docs-contract]
requires:
  - phase: 15-01
    provides: bounded async worker contract and truthful Oban guide wording
provides:
  - balanced top-level render lifecycle on timeout
  - Threadline timeout forwarding under the existing render_failed action family
  - truthful timeout-audit integration guide language
affects: [ADPT-05, OBS-04, phase-15-plan-03]
tech-stack:
  added: []
  patterns:
    - caller-owned top-level telemetry lifecycle
    - stable failed-render metadata for timeout paths
key-files:
  created: []
  modified:
    - lib/rendro/pipeline.ex
    - lib/rendro/adapters/threadline.ex
    - test/rendro/telemetry_test.exs
    - test/rendro/adapters/threadline_test.exs
    - test/docs_contract/integrations_claims_test.exs
    - guides/integrations.md
key-decisions:
  - Keep timeout on the existing top-level `[:rendro, :render, :stop]` surface.
  - Preserve timeout subtype data in nested `error.kind` metadata instead of creating a timeout-only action family.
patterns-established:
  - "Top-level telemetry owned outside killable async work prevents timeout gaps in audit handlers."
requirements_completed: []
duration: 11min
completed: 2026-04-28
---

# Phase 15 Plan 02 Summary

**Closed the timeout-to-audit seam by balancing the top-level render lifecycle on timeout, forwarding nested timeout metadata through Threadline, and updating the public guide to match.**

## Accomplishments

- Added timeout-specific telemetry, Threadline, and docs-contract proof before closing the runtime gap.
- Moved top-level render lifecycle ownership to `Rendro.Pipeline.run/1` so timeouts always emit a terminal `:stop`.
- Preserved timeout subtype visibility through Threadline under `:render_failed` and removed the old guide limitation.

## Task Commits

1. `0ff9984` — `test(15-02): add timeout lifecycle and audit proof`
2. `8c637fc` — `feat(15-02): close timeout render lifecycle`
3. `44cae00` — `feat(15-02): forward timeout metadata through Threadline`
4. `49027ae` — `fix(15-02): validate timeout policies and preserve audit failures`
5. `1457173` — `fix(15-02): report paginated page counts at top level`
6. `3d9da25` — `fix(15-02): preserve last known timeout page-count progress`

## Verification

- `mix test test/rendro/telemetry_test.exs test/rendro/adapters/threadline_test.exs test/docs_contract/integrations_claims_test.exs`
- `rg -n "Threadline|timeout|render_failed" guides/integrations.md`

## Deviations from Plan

### Auto-fixed follow-up

- Post-review hardening added typed handling for malformed document-authored timeout policies, surfaced Threadline backend failures instead of swallowing them, and preserved final or last-known page counts in top-level telemetry where available.

### Residual advisory note

- If a timeout fires before pagination completes, the top-level timeout `page_count` still remains `0` because no truthful paginated count exists yet. The final review artifact records this as an advisory warning, not a test failure.

## Self-Check

PASSED

- Found commits `0ff9984`, `8c637fc`, and `44cae00`
- Verified timeout tests and guide assertions against the updated runtime

---
*Phase: 15-async-policy-injection-timeout-audit-closure*
*Completed: 2026-04-28*

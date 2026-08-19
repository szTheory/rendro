---
phase: 128-static-configurator-theme-codegen-livebook
plan: 06
subsystem: testing
tags: [playwright, chromium, clipboard, recovery, ci]
requires:
  - phase: 128-05
    provides: pinned Chromium configurator harness and deterministic CI contract
provides:
  - Executable pinned-Chromium clipboard and preview failure/recovery evidence
  - Executable independence checks for browser chrome and selected document mode
  - Formatter-clean deterministic CI contract and truthful Plan 05 execution inventory
affects: [phase-129, static-configurator, ci]
tech-stack:
  added: []
  patterns: [pre-navigation browser controls, counted selected-asset failures, retry clears actionable state]
key-files:
  created: []
  modified: [scripts/configurator_e2e/tests/configurator.spec.mjs, assets/rendro/configurator/configurator.js, test/docs_contract/dx_local_reproducibility_claims_test.exs, .planning/phases/128-static-configurator-theme-codegen-livebook/128-05-PLAN.md]
key-decisions:
  - "Keep evidence limited to the exact pinned Chromium container; no cross-browser, AT, WCAG, or aesthetic claim is added."
  - "Clear the actionable clipboard alert only after writeText resolves, preserving the existing source, preview, and failure behavior."
patterns-established:
  - "Browser recovery tests install controls before navigation, count the intended failed operation, and remove interception before reload recovery."
requirements-completed: [CONFIG-01, CONFIG-02, CONFIG-03, CONFIG-05]
coverage:
  - id: D1
    description: Clipboard rejection/retry and selected-PNG failure/reload recovery use the shipped configurator handlers.
    requirement: CONFIG-03
    verification:
      - kind: automated_ui
        ref: scripts/configurator_e2e/tests/configurator.spec.mjs#clipboard-and-preview-recovery
        status: pass
    human_judgment: false
  - id: D2
    description: Pinned Chromium proves dark-chrome/light-document and light-chrome/dark-document combinations independently.
    requirement: CONFIG-01
    verification:
      - kind: automated_ui
        ref: scripts/configurator_e2e/tests/configurator.spec.mjs#browser-chrome-and-document-mode-remain-independent
        status: pass
    human_judgment: false
  - id: D3
    description: The deterministic docs contract is formatted and the complete fast CI lane passes.
    requirement: CONFIG-05
    verification:
      - kind: integration
        ref: mix ci.fast
        status: pass
    human_judgment: false
duration: 11m
completed: 2026-08-19
status: complete
---

# Phase 128 Plan 06: Configurator Verification Gap Closure Summary

**Pinned Chromium now proves clipboard and selected-preview recovery plus independent browser chrome/document modes, while the deterministic CI contract is formatter-clean.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-08-19T02:51:00Z
- **Completed:** 2026-08-19T03:02:40Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Added focused Chromium cases for rejected clipboard writes followed by exact-source retry, selected PNG failure followed by same-URL reload recovery, and both opposite OS-chrome/document-mode combinations.
- Repaired the test-proven stale clipboard alert only after a successful Clipboard API resolution; failure feedback remains actionable until recovery.
- Formatted the blocked docs-contract test, proved the exact fourteen-item Plan 05 inventory is its only historical-plan change, and passed the full deterministic CI lane.

## Verification

- `npm run test:container --prefix scripts/configurator_e2e` — passed: 13 pinned Chromium tests, including all new recovery and independence cases.
- `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs --max-failures 1` — passed: 3 tests.
- `mix format --check-formatted test/docs_contract/dx_local_reproducibility_claims_test.exs` — passed.
- Plan-05 exact ordered-list and normalized historical-byte-diff gate — passed before its task commit.
- `mix ci.fast` — passed.

## Task Commits

1. **Task 1: Close the pinned-Chromium matrix and deterministic CI gaps** — `2c522a5` (test), `c02f39b` (feat)

## Files Created/Modified

- `scripts/configurator_e2e/tests/configurator.spec.mjs` — executes clipboard rejection/retry, PNG failure/reload, and cross-combination chrome/document evidence.
- `assets/rendro/configurator/configurator.js` — clears the stale actionable copy alert after successful retry only.
- `test/docs_contract/dx_local_reproducibility_claims_test.exs` — formatted deterministic CI wiring contract.
- `.planning/phases/128-static-configurator-theme-codegen-livebook/128-05-PLAN.md` — corrected only the historical `files_modified` inventory.

## Decisions Made

- Preserved the exact pinned-container/no-human claim boundary: these checks establish only enumerated Chromium behavior, not Firefox/Safari, assistive-technology comprehension, WCAG certification, or aesthetic quality.
- Used reload—not a new product recovery control—for selected-image recovery.

## Deviations from Plan

None - plan executed exactly as written. The stale-alert repair was the explicitly planned conditional result of the red retry test.

## Issues Encountered

- The intentional aborted selected-PNG request emits Chromium's expected local console error; its test permits only that exact expected error while retaining the existing external-request and unexpected-error checks.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The Phase 128 browser and terminal deterministic gates are green with no human checkpoint remaining. The bounded Chromium-only evidence statement remains unchanged.

## Self-Check: PASSED

- Task commits `2c522a5` and `c02f39b` exist.
- All four modified task files and this summary exist on disk.

---
*Phase: 128-static-configurator-theme-codegen-livebook*
*Completed: 2026-08-19*

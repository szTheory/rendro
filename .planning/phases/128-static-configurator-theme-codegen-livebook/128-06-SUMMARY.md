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
  modified: [scripts/configurator_e2e/tests/configurator.spec.mjs, assets/rendro/configurator/configurator.js, test/docs_contract/dx_local_reproducibility_claims_test.exs, test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs, .planning/phases/128-static-configurator-theme-codegen-livebook/128-05-PLAN.md]
key-decisions:
  - "Keep evidence limited to the exact pinned Chromium container; no cross-browser, AT, WCAG, or aesthetic claim is added."
  - "Clear the actionable clipboard alert only after writeText resolves, preserving the existing source, preview, and failure behavior."
patterns-established:
  - "Browser recovery tests install controls before navigation, count the intended failed operation, and remove interception before reload recovery."
  - "Fresh-consumer conflict subprocesses use Mix.Shell.Process with an explicit false overwrite response and a bounded command timeout."
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
  - id: D4
    description: Fresh-consumer generator conflict execution declines overwrite without a TTY prompt while retaining the real child Mix task boundary.
    requirement: CONFIG-05
    verification:
      - kind: e2e
        ref: test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs#fresh-local-path-consumer
        status: pass
    human_judgment: false
duration: 22m
completed: 2026-08-19
status: complete
---

# Phase 128 Plan 06: Configurator Verification Gap Closure Summary

**Pinned Chromium now proves clipboard and selected-preview recovery plus independent browser chrome/document modes, while the deterministic CI contract is formatter-clean.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-08-19T02:51:00Z
- **Completed:** 2026-08-19T03:19:40Z
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments

- Added focused Chromium cases for rejected clipboard writes followed by exact-source retry, selected PNG failure followed by same-URL reload recovery, and both opposite OS-chrome/document-mode combinations.
- Repaired the test-proven stale clipboard alert only after a successful Clipboard API resolution; failure feedback remains actionable until recovery.
- Formatted the blocked docs-contract test, proved the exact fourteen-item Plan 05 inventory is its only historical-plan change, and passed the full deterministic CI lane.
- Made the real fresh-consumer conflict subprocess noninteractive under a TTY by injecting its explicit `Mix.Shell.Process` decline response and bounding every child Mix command.

## Verification

- `npm run test:container --prefix scripts/configurator_e2e` — passed: 13 pinned Chromium tests, including all new recovery and independence cases.
- `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs --max-failures 1` — passed: 3 tests.
- `mix format --check-formatted test/docs_contract/dx_local_reproducibility_claims_test.exs` — passed.
- Plan-05 exact ordered-list and normalized historical-byte-diff gate — passed before its task commit.
- `mix test test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs --max-failures 1` — passed non-TTY.
- `script -q /dev/null mix test test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs --max-failures 1` — passed through a pseudo-terminal.
- `mix ci.fast` — passed.

## Task Commits

1. **Task 1: Close the pinned-Chromium matrix and deterministic CI gaps** — `2c522a5` (test), `c02f39b` (feat)
2. **Post-completion fix: Fresh-consumer conflict subprocess** — `5ee99ed` (fix)

## Files Created/Modified

- `scripts/configurator_e2e/tests/configurator.spec.mjs` — executes clipboard rejection/retry, PNG failure/reload, and cross-combination chrome/document evidence.
- `assets/rendro/configurator/configurator.js` — clears the stale actionable copy alert after successful retry only.
- `test/docs_contract/dx_local_reproducibility_claims_test.exs` — formatted deterministic CI wiring contract.
- `test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs` — makes the child conflict prompt explicit and timeout-bounded without replacing real Mix task discovery.
- `.planning/phases/128-static-configurator-theme-codegen-livebook/128-05-PLAN.md` — corrected only the historical `files_modified` inventory.

## Decisions Made

- Preserved the exact pinned-container/no-human claim boundary: these checks establish only enumerated Chromium behavior, not Firefox/Safari, assistive-technology comprehension, WCAG certification, or aesthetic quality.
- Used reload—not a new product recovery control—for selected-image recovery.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prevented the fresh-consumer conflict case from hanging under a TTY**
- **Found during:** Post-completion verification
- **Issue:** The real child `mix rendro.gen.theme` process inherited an interactive conflict prompt without a supplied answer.
- **Fix:** Used `Mix.Shell.Process` only inside the child conflict path, queued `{:mix_shell_input, :yes?, false}`, forwarded its `Skipped ...` output, and bounded child Mix commands to 60 seconds.
- **Files modified:** `test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs`
- **Verification:** Focused non-TTY and pseudo-TTY runs passed, followed by pinned Chromium and `mix ci.fast`.

---

**Total deviations:** 1 auto-fixed (Rule 1 bug fix).
**Impact on plan:** Restores the completed fresh-consumer evidence under both local execution modes without changing the product task or claim boundary.

## Issues Encountered

- The intentional aborted selected-PNG request emits Chromium's expected local console error; its test permits only that exact expected error while retaining the existing external-request and unexpected-error checks.
- A first broad `Mix.Shell.Process` attempt also affected force writes; the final repair scopes it only to the conflict subprocess.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The Phase 128 browser and terminal deterministic gates are green with no human checkpoint remaining. The bounded Chromium-only evidence statement remains unchanged.

## Self-Check: PASSED

- Task commits `2c522a5`, `c02f39b`, and `5ee99ed` exist.
- All five modified task files and this summary exist on disk.

---
*Phase: 128-static-configurator-theme-codegen-livebook*
*Completed: 2026-08-19*

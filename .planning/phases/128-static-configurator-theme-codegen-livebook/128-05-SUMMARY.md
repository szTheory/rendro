---
phase: 128-static-configurator-theme-codegen-livebook
plan: 05
subsystem: testing
tags: [playwright, chromium, axe, visual-regression, mix, ci]
requires:
  - phase: 128-02
    provides: formatter-owned Mix theme generator
  - phase: 128-03
    provides: static configurator and committed manifests
  - phase: 128-04
    provides: no-server Livebook surface
provides:
  - Pinned Chromium static-configurator E2E gate with Linux visual baselines
  - Real fresh-consumer generator subprocess audit
  - Required graph-disconnected browser CI job
affects: [phase-129, ci, static-configurator]
tech-stack:
  added: ["@playwright/test 1.62.0", "@axe-core/playwright 4.13.0"]
  patterns: [isolated test-only Node harness, pinned-container screenshot baselines, serial local-path Mix consumer]
key-files:
  created: [scripts/configurator_e2e/tests/configurator.spec.mjs, test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs]
  modified: [.github/workflows/ci.yml, assets/rendro/configurator/configurator.js]
key-decisions:
  - "Required browser evidence is pinned Chromium-only and makes no cross-browser, AT, WCAG, or aesthetic claim."
  - "Visual baselines are generated only by the exact pinned Playwright container; CI never updates them."
requirements-completed: [CONFIG-01, CONFIG-02, CONFIG-03, CONFIG-04, CONFIG-05, CONFIG-06]
coverage:
  - id: D1
    description: Static configurator behavior and pinned-container visual matrix
    requirement: CONFIG-01
    verification:
      - kind: automated_ui
        ref: scripts/configurator_e2e/tests/configurator.spec.mjs
        status: pass
    human_judgment: false
  - id: D2
    description: Fresh local-path consumer generator write/conflict/check behavior
    requirement: CONFIG-05
    verification:
      - kind: e2e
        ref: test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs
        status: pass
    human_judgment: false
duration: 1h 05m
completed: 2026-08-19
status: complete
---

# Phase 128 Plan 05: Automated Static Configurator Final Gate Summary

**Pinned Chromium visual/accessibility evidence and a real fresh-Mix-consumer generator audit close the static configurator without a human checkpoint.**

## Accomplishments

- Preserved Task 1's committed direct-file graph, formatter-drift, Livebook, and terminal CI evidence.
- Added an isolated Node harness pinned to Playwright 1.62.0 and axe 4.13.0, with a localhost-only safe asset server, Chromium-only execution, failure artifacts, axe scans, scoped ARIA snapshot, and seven Linux screenshot baselines generated in the exact pinned container.
- Added a serial `mix new` local-path consumer E2E that compiles and invokes the generator, checks default/override/conflict/force/equal-different-missing cases, and recursively audits path/type/mtime/hash changes.
- Added required graph-disconnected `configurator-browser` CI execution and strict `ci-success` handling for failed, cancelled, and skipped jobs.

## Verification

- `npm run test:container --prefix scripts/configurator_e2e` — passed: 9 pinned Chromium tests and Linux visual baselines.
- `mix test test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs test/docs_contract/dx_local_reproducibility_claims_test.exs test/docs_contract/configurator_phase_gate_test.exs --max-failures 1` — passed.
- `mix rendro.configurator.gen --check && mix rendro.livebook.check && mix format --check-formatted` — passed.
- `mix ci.fast` — passed.

## Task Commits

1. **Task 1: Integrated static graph gate** — `de0aeff`, `6d46bca`
2. **Task 2: Automated pinned Chromium and fresh-consumer gates** — `22b1931`

## Decisions Made

- Test-only Node/Playwright is allowed only in the isolated CI harness; product runtime, build, and Hex delivery remain pure Elixir and Node-free.
- Automated evidence is intentionally limited to pinned Chromium, accessibility-tree snapshots, enumerated axe checks, and pinned-container pixels. It does not assert Firefox/Safari behavior, VoiceOver/NVDA comprehension, WCAG certification, or aesthetic quality.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored factual representative-preview disclosure**
- **Found during:** Task 2
- **Issue:** A representative catalog preview only announced its differing accent through a transient status message.
- **Fix:** Rendered the factual copied-vs-representative accent disclosure persistently.
- **Files modified:** `assets/rendro/configurator/configurator.js`
- **Verification:** Pinned Chromium representative state test passed.

**2. [Rule 1 - Accessibility] Fixed copied-status color contrast**
- **Found during:** Task 2
- **Issue:** axe reported insufficient contrast for the live copied-status feedback.
- **Fix:** Used the established primary text color for the status treatment.
- **Files modified:** `assets/rendro/configurator/configurator.css`
- **Verification:** Scoped axe scan passed in the pinned Chromium suite.

## Known Boundaries

Branch-protection API configuration cannot be inspected locally. The repository workflow makes `configurator-browser` required through `ci-success`; confirm the remote branch-protection rule separately if its settings change.

No human browser, assistive-technology, screenshot approval, generator UAT, or `gsd-verify-work` checkpoint remains. The omitted claims are deliberate, not unverified stubs.

## Self-Check: PASSED

- Task commits `de0aeff`, `6d46bca`, and `22b1931` exist.
- Browser harness, fresh-consumer E2E, container-generated Linux baselines, and CI workflow changes exist on disk.

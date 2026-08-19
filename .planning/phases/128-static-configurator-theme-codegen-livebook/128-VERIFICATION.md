---
phase: 128-static-configurator-theme-codegen-livebook
verified: 2026-08-19T03:22:21Z
status: gaps_found
score: 9/11 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 11/11
  gaps_closed: []
  gaps_remaining:
    - "Fresh-consumer conflict evidence exits successfully in both non-TTY and pseudo-TTY execution."
    - "The terminal deterministic mix ci.fast gate is green."
  regressions:
    - "Commit 5ee99ed changed the fresh-consumer conflict child process, but the real local-path consumer test now exits 1 in both execution modes."
gaps:
  - truth: "A fresh local-path consumer completes the generator default/override/conflict/force/equal/different/missing audit without a TTY dependency."
    status: failed
    reason: "Both direct and pseudo-TTY runs fail at test/rendro_gen_theme_fresh_consumer_test.exs:52 because the conflict child returns exit 1 rather than the asserted 0. The child output consists of Rendro dependency compile warnings for unavailable optional modules (YamlElixir, JSV, Jason), so the queued false overwrite response is never proven by a successful real conflict command."
    artifacts:
      - path: "test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs"
        issue: "run_conflict!/2 invokes mix run --no-start in a new consumer; its command exits 1 before the asserted skipped-conflict result."
    missing:
      - "Make the real consumer conflict subprocess compile/run successfully in the declared fresh environment, while retaining the explicit false overwrite response and bounded timeout; prove it in both non-TTY and pseudo-TTY modes."
  - truth: "The complete deterministic mix ci.fast gate passes."
    status: failed
    reason: "mix ci.fast includes the failing fresh-consumer ExUnit test, so the terminal gate is red despite formatter checks and the other focused Phase-128 regressions passing."
    artifacts:
      - path: "test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs"
        issue: "The test's conflict case fails with a MatchError on the expected {conflict, 0} result."
    missing:
      - "Close the fresh-consumer failure, then rerun mix ci.fast to a zero exit status."
---

# Phase 128: Static Configurator, Theme Codegen & Livebook — Verification Report

**Phase Goal:** Deliver a zero-server static configurator over the catalog, a safe `mix rendro.gen.theme` generator sharing canonical source, and the focused Livebook preset path; acceptance is zero-human through pinned Chromium and fresh-consumer automation.
**Verified:** 2026-08-19T03:22:21Z
**Status:** gaps_found
**Re-verification:** Yes — regression after prior pass

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | One closed formatter owns configurator, generated-module, and Livebook source. | ✓ VERIFIED | Focused snippet/index regression passed. |
| 2 | The committed index has 504 ordered, executable records with explicit font registration. | ✓ VERIFIED | Snippet/phase-gate regressions and `mix rendro.configurator.gen --check` passed. |
| 3 | The configurator remains a safe zero-server static ExDoc asset surface. | ✓ VERIFIED | Focused static/phase-gate contracts passed; no product Node/runtime surface was added. |
| 4 | URL fallback/round-trip and exact/representative/none preserve canonical source identity. | ✓ VERIFIED | Resolver contracts and the browser container suite passed. |
| 5 | Clipboard success/rejection/retry and selected-PNG failure/reload recovery retain the required semantics. | ✓ VERIFIED | Exact pinned container run: 13/13 browser tests passed. |
| 6 | Chrome/document mode cross-combinations, layout baselines, axe, ARIA, and responsive checks remain covered. | ✓ VERIFIED | Exact pinned container runs both cross-combinations and all seven Linux visual baselines. |
| 7 | Safe CLI validation, generated wrapper behavior, and read-only drift checks work. | ✓ VERIFIED | Focused generator tests passed. |
| 8 | Livebook is the focused, no-server third surface. | ✓ VERIFIED | Focused Livebook test plus `mix rendro.livebook.check` passed. |
| 9 | Fresh consumer default/override/conflict/force/equal/different/missing behavior works without TTY dependence. | ✗ FAILED | Both direct and pseudo-TTY focused runs fail at the real conflict child before `{conflict, 0}` can be asserted. |
| 10 | Strict browser CI aggregation and bounded Chromium-only claims remain wired. | ✓ VERIFIED | `.github/workflows/ci.yml` still requires graph-disconnected `configurator-browser` through `ci-success`; documented claims remain bounded. |
| 11 | Terminal deterministic CI is green. | ✗ FAILED | `mix ci.fast` is red because it includes the failing fresh-consumer conflict test. |

**Score:** 9/11 truths verified (0 present, behavior-unverified).

### Required Artifacts and Wiring

| Artifact / Link | Status | Details |
| --- | --- | --- |
| Formatter, index, configurator, generator, and Livebook source | ✓ VERIFIED | Existing substantive implementations and focused regression contracts remain wired and green. |
| Pinned Playwright harness → shipped controller | ✓ VERIFIED | `npm run test:container --prefix scripts/configurator_e2e`: 13/13 passed in the exact pinned container. |
| Fresh-consumer test → real child Mix conflict | ✗ FAILED | `run_conflict!/2` is wired to the child task, but fails with exit 1 due dependency compilation warnings instead of proving the expected skip path. |
| CI aggregate → fresh-consumer test | ✗ FAILED | Strict wiring exists, but `mix ci.fast` consequently fails. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Fresh consumer, non-TTY | `mix test test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs --max-failures 1` | 1 failure / 23.6s; conflict child returned exit 1 | ✗ FAIL |
| Fresh consumer, pseudo-TTY | `script -q /dev/null mix test test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs --max-failures 1` | 1 failure / 27.4s; same conflict child exit 1 | ✗ FAIL |
| Pinned browser/zero-human UI matrix | `npm run test:container --prefix scripts/configurator_e2e` | 13/13 passed | ✓ PASS |
| Other Phase-128 core contracts | focused 30-test ExUnit set + index drift + Livebook + format | exit 0 | ✓ PASS |
| Terminal deterministic gate | `mix ci.fast` | failed through fresh-consumer test | ✗ FAIL |

### Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| CONFIG-01 | ✓ SATISFIED | Static direct-file graph and complete pinned Chromium matrix pass. |
| CONFIG-02 | ✓ SATISFIED | Exact/representative/none and image recovery execute in pinned Chromium. |
| CONFIG-03 | ✓ SATISFIED | Canonical source and copy success/rejection/retry identity proof pass. |
| CONFIG-04 | ✓ SATISFIED | Atomic canonical URL fallback/round-trip remains exercised. |
| CONFIG-05 | ✗ BLOCKED | The claimed fresh-consumer subprocess contract and required terminal CI are currently red. |
| CONFIG-06 | ✓ SATISFIED | No-server focused Livebook proof passes. |

No Phase-128 requirement is orphaned. The claim boundary is still honest—pinned Chromium only, no cross-browser/AT/WCAG/aesthetic certification—but the zero-human gate cannot pass while its required fresh-consumer proof is red.

### Gaps Summary

Commit `5ee99ed` correctly scopes `Mix.Shell.Process` and injects a false response, but its child `mix run --no-start` command exits with dependency compilation failures before exercising the completed conflict result. This is reproducible both without a TTY and through a pseudo-TTY. The bounded timeout prevents a hang; it does not make the success claim true.

The pinning/browser surface remains green. The sole root cause is the fresh-consumer conflict command's nonzero exit, which also makes `mix ci.fast` fail. No later phase explicitly defers this proof, so it remains a blocking gap.

---

_Verified: 2026-08-19T03:22:21Z_
_Verifier: the agent (gsd-verifier)_

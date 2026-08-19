---
phase: 128-static-configurator-theme-codegen-livebook
verified: 2026-08-19T02:48:45Z
status: gaps_found
score: 9/11 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The zero-human pinned Chromium gate executes every state named by the revised 128-05 acceptance contract."
    status: failed
    reason: "The 9-test suite passes in the pinned Linux container, but its executable assertions omit required clipboard rejection/recovery, image-load failure/recovery, and independent chrome color-scheme versus document-mode combinations. It also does not assert live/alert behavior in failure paths."
    artifacts:
      - path: "scripts/configurator_e2e/tests/configurator.spec.mjs"
        issue: "Only clipboard success is exercised; no route rejects writeText, no PNG route fails, no recovery action is triggered, and all dark screenshot cases pair dark chrome with dark document mode."
    missing:
      - "Add deterministic Chromium tests for clipboard failure/retry, image failure/recovery, failure live/alert semantics, and both independent chrome/document-mode combinations."
  - truth: "The terminal deterministic CI gate is green and the strict aggregate can be relied upon."
    status: failed
    reason: "The verifier ran mix ci.fast and it failed at format --check-formatted before its test/CI stages."
    artifacts:
      - path: "test/docs_contract/dx_local_reproducibility_claims_test.exs"
        issue: "Lines 44-47 require formatter output; this file was modified by Phase-128 commit 22b1931."
    missing:
      - "Format the docs-contract test and rerun mix ci.fast successfully."
---

# Phase 128: Static Configurator, Theme Codegen & Livebook — Verification Report

**Phase Goal:** Deliver a zero-server static configurator over the catalog, a safe `mix rendro.gen.theme` generator sharing canonical source, and the focused Livebook preset path; acceptance is zero-human through pinned Chromium and fresh-consumer automation.
**Verified:** 2026-08-19T02:48:45Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | One closed Elixir formatter owns configurator, generated-module, and Livebook source. | ✓ VERIFIED | `Rendro.Theme.Snippet` owns closed values, `usage_snippet/4`, `module_source/4`, and deterministic JSON; focused snippets/tests passed. |
| 2 | The committed index has 504 ordered, parseable, executable formatter records with the explicit font bridge. | ✓ VERIFIED | `Snippet.records/0` enumerates 6×6×7×2; `configurator_phase_gate_test` checks byte equality; focused test suite passed. |
| 3 | Static shipped assets use no product server, database, Node build/runtime, or unsafe URL-to-HTML interpolation. | ✓ VERIFIED | Direct-file contract passed; `index.html` is ExDoc-copy-through assets and the controller uses `textContent`/constructed nodes. Test-only Node is isolated in `scripts/configurator_e2e/`. |
| 4 | URL fallback/round-trip and exact/representative/none resolution preserve the selected formatter source. | ✓ VERIFIED | Resolver contracts and the pinned container browser run passed; controller uses strict four-key `URLSearchParams` state and index-record lookup. |
| 5 | Copy success places the visible formatter record on the clipboard. | ✓ VERIFIED | Pinned Chromium test grants clipboard permissions, clicks copy, checks `Snippet copied`, and reads back the exact source. |
| 6 | `mix rendro.gen.theme` creates a fixed wrapper and provides safe default/override/conflict/force/equal/different/missing check behavior. | ✓ VERIFIED | Focused unit and real fresh-consumer tests passed; subprocess audit checks recursive path/type/mtime/SHA-256 trees on non-write paths. |
| 7 | Existing Livebook has exactly one executable canonical preset path with deterministic render evidence and no server/interactive expansion. | ✓ VERIFIED | `rendro_livebook_check_test` plus `mix rendro.livebook.check` passed; notebook block is byte-linked to Invoice/Swiss/#2C6BED/light. |
| 8 | Pinned Chromium covers the full revised error, recovery, accessibility, theme-independence, and responsive acceptance matrix. | ✗ FAILED | The container suite passes its 9 current tests, but required failure and independent-theme cases are absent from the test source; see Gaps Summary. |
| 9 | Seven pinned-container baselines, scoped ARIA, axe, and strict aggregate CI wiring exist. | ✓ VERIFIED | Seven `*-linux.png` baselines exist; test uses `toMatchAriaSnapshot` and scoped axe scans; workflow has graph-disconnected `configurator-browser` and `ci-success` needs it. |
| 10 | Terminal `mix ci.fast`, configurator drift check, and Livebook check pass together. | ✗ FAILED | Focused drift/Livebook checks passed, but `mix ci.fast` failed on an unformatted Phase-128 file. |
| 11 | Claims stay bounded to pinned Chromium automation, not cross-browser/AT/WCAG/aesthetic certification. | ✓ VERIFIED | Harness README and summary explicitly exclude Firefox/Safari, VoiceOver/NVDA, WCAG certification, and aesthetic claims. |

**Score:** 9/11 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/rendro/theme/snippet.ex` | Closed canonical formatter | ✓ VERIFIED | Substantive 156-line implementation, used by both generators and tests. |
| `dev/mix/tasks/rendro/configurator/gen.ex` | Read-only index drift check | ✓ VERIFIED | Delegates to `Snippet.index_json/0`; focused check passed. |
| `assets/rendro/configurator/index.json` | 504 deterministic records | ✓ VERIFIED | Byte-equal to fresh formatter output. |
| `lib/mix/tasks/rendro/gen/theme.ex` | Safe consumer generator | ✓ VERIFIED | Calls `Snippet.module_source/4`; strict input/path validation and Mix.Generator semantics. |
| `assets/rendro/configurator/index.html` / `configurator.js` / `configurator.css` | Static browser surface | ✓ VERIFIED | Committed, substantive, direct-file tested, and served only by the test harness. |
| `guides/livebook/first_invoice.livemd` | Focused third surface | ✓ VERIFIED | Exact marked canonical block, one themed PDF render, preview and download. |
| `scripts/configurator_e2e/` | Pinned browser evidence | ⚠️ INCOMPLETE | Harness, lockfile, localhost server, seven Linux baselines, and CI job are real; acceptance coverage is incomplete. |
| `test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs` | Fresh-consumer subprocess proof | ✓ VERIFIED | Real `mix new` local-path consumer; focused test passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Configurator generator | `Rendro.Theme.Snippet` | `Snippet.index_json/0` | ✓ WIRED | Direct source call and byte-equality test. |
| Consumer Mix task | `Rendro.Theme.Snippet` | `Snippet.module_source/4` | ✓ WIRED | Aliased call in generator; generated wrapper test compiles it. |
| Configurator controller | committed index/catalog JSON | `fetch` + exact record/resolver lookup | ✓ WIRED | Both local fetches and source use are present; browser/container test executes them. |
| Copy button | selected record snippet | `clipboard.writeText(visibleCodeText)` | ✓ WIRED | Success path run in pinned Chromium. |
| Livebook | formatter source/font bridge | marked block + checker | ✓ WIRED | No-server checker and focused test passed. |
| Browser job | required CI aggregate | `ci-success.needs` | ✓ WIRED | Workflow requires `configurator-browser`; remote branch-protection configuration remains outside local verification. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Configurator UI | `index.records` / `catalog.cells` | Committed `index.json` and `catalog.json` fetched locally | Formatter-owned records and existing raster manifest | ✓ FLOWING |
| Generated wrapper | generated source | `Snippet.module_source/4` | Closed formatter serialization | ✓ FLOWING |
| Livebook preset section | `document` / `themed_pdf` | Canonical snippet, recipe, deterministic renderer | `%PDF-` assertion and byte evidence | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Formatter, static resolver, generator, Livebook, fresh consumer | focused ExUnit suite + drift + Livebook + format | exit 0 | ✓ PASS |
| Pinned Chromium / seven Linux baselines | `npm run test:container --prefix scripts/configurator_e2e` | 9/9 passed | ✓ PASS |
| Terminal deterministic CI | `mix ci.fast` | format check failed on `test/docs_contract/dx_local_reproducibility_claims_test.exs` | ✗ FAIL |
| Direct local macOS browser invocation | `npm test --prefix scripts/configurator_e2e` | 7 screenshot lookups fail because only `-linux.png` baselines are intentionally committed | ℹ️ EXPECTED PLATFORM LIMIT |

### Probe Execution

No Phase-128 probe scripts were declared or found; validation is test/command based.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| --- | --- | --- | --- |
| CONFIG-01 | 03, 05 | ✗ BLOCKED | Static implementation exists, but revised zero-human browser error/accessibility coverage is incomplete. |
| CONFIG-02 | 03, 05 | ✗ BLOCKED | Exact/representative/none selection runs, but image-error/recovery and full stated UI-state automation are absent. |
| CONFIG-03 | 01, 03, 05 | ✗ BLOCKED | Exact copy success is proven; clipboard rejection/recovery is required by revised final acceptance but untested. |
| CONFIG-04 | 03, 05 | ✓ SATISFIED | Atomic URL fallback/round-trip is exercised in pinned Chromium and resolver contracts. |
| CONFIG-05 | 01, 02, 05 | ✗ BLOCKED | Fresh consumer behavior is proven, but required terminal `mix ci.fast` is currently red. |
| CONFIG-06 | 04, 05 | ✓ SATISFIED | No-server Livebook checker and focused test passed. |

No Phase-128 requirement is orphaned: all six are declared by one or more PLAN frontmatters.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/docs_contract/dx_local_reproducibility_claims_test.exs` | 44-47 | Not formatter-compliant | 🛑 BLOCKER | Makes `mix ci.fast` fail before its complete deterministic gate runs. |
| `scripts/configurator_e2e/tests/configurator.spec.mjs` | 18-88 | Broad test name masks omitted negative/recovery cases | 🛑 BLOCKER | Claimed zero-human acceptance has no executable proof for required behavior. |

No untracked product Node/runtime dependency was found: `mix.exs` references only the pre-existing PDF.js observer Node check, and the new Playwright dependencies remain under the isolated test harness.

### Gaps Summary

The phase contains substantive, wired implementations of all three product surfaces, and its focused Elixir plus pinned-container tests pass. It nevertheless does **not** meet the revised Phase-128 zero-human acceptance:

1. The Chromium suite proves only clipboard success. It does not reject `navigator.clipboard.writeText`, fail an image request, prove recovery after either failure, or verify live/alert behavior on those paths. It also never decouples the browser chrome color scheme from document mode—its dark cases use dark for both.
2. The terminal CI command is objectively red because a file changed by the Phase-128 browser/CI commit is unformatted. The strict aggregate wiring exists, but cannot be accepted while its upstream deterministic gate fails.

These are implementation/test-coverage gaps, not human-verification requests. No later roadmap phase specifically promises to close the browser acceptance or the Phase-128 CI formatter failure, so nothing is deferred.

---

_Verified: 2026-08-19T02:48:45Z_
_Verifier: the agent (gsd-verifier)_

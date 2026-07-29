---
phase: 124-address-v2-11-tech-debt-stale-113-docs-contract-test-formatt
plan: 01
subsystem: testing
tags: [dialyzer, mix-format, exunit, elixir, type-spec, tech-debt]

# Dependency graph
requires:
  - phase: 123
    provides: v2.11 Document Theming milestone (shipped), milestone audit flagging 3 non-blocking tech-debt gates
provides:
  - mix dialyzer 0 errors (Background.emit?/1 @spec widened from closed to open map type)
  - mix format --check-formatted exit 0 (7-file bounded formatting-only reformat)
  - dx_local_reproducibility_claims_test.exs reduced to 3 live cases (2 stale Phase-113 cases deleted)
  - mix ci.fast green end-to-end (all 7 steps)
affects: [milestone-archival, future-tech-debt-audits]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dialyzer closed-vs-open map @spec gotcha: %{key: type} shorthand is CLOSED (exact key set); use required(:key) => type, optional(atom()) => any() for maps that need extra keys"

key-files:
  created: []
  modified:
    - lib/rendro/recipes/background.ex
    - lib/rendro/launch_artifacts.ex
    - test/docs_contract/theme_industry_guard_test.exs
    - test/docs_contract/theming_claims_test.exs
    - test/rendro/recipes/payslip_opts_threading_test.exs
    - test/rendro/recipes/themed_render_smoke_test.exs
    - test/rendro/recipes/certificate_typography_test.exs
    - test/rendro/recipes/theme_mode_background_golden_test.exs
    - test/docs_contract/dx_local_reproducibility_claims_test.exs

key-decisions:
  - "D-03: Background.emit?/1's @spec was a closed 1-key map type, not a value-type mismatch as originally hypothesized -- widening to an open map type (required(:background) => T, optional(atom()) => any()) cleared the entire 133-error dialyzer cascade across 10 files with a single-line, single-file edit; ticket.ex needed zero changes."
  - "D-02: mix format confirmed bounded to exactly the known 7-file set; diff is formatting-only (parens, map re-wrap, blank lines, string-literal collapse), zero logic/identifier change."
  - "D-01: both stale Phase-113 docs-contract test cases deleted (not skipped or re-pointed) -- both asserted only frozen, archive-specific historical facts (GitHub Actions run IDs, a specific p50/p95 timing pair, a UAT pass count) with zero forward-looking regression value; 3 orphaned module attributes removed alongside to avoid compiler warnings."

patterns-established:
  - "Pattern: Elixir/Dialyzer map @spec shorthand %{key: type} is closed -- always add optional(atom()) => any() for functions accepting a superset-shaped map (a common options/config-map pattern), or every downstream caller with extra keys will cascade into no_return/invalid_contract errors."

requirements-completed: [D-01, D-02, D-03]

coverage:
  - id: D1
    description: "mix dialyzer reports 0 errors (was 133 across 10 files) via a single-file open-map @spec widening on Background.emit?/1"
    requirement: "D-03"
    verification:
      - kind: unit
        ref: "mix dialyzer (Total errors: 0, Skipped: 0, Unnecessary Skips: 0)"
        status: pass
      - kind: unit
        ref: "byte-identity/golden suite: 9 files, 27 tests, 0 failures (unchanged before/after)"
        status: pass
    human_judgment: false
  - id: D2
    description: "mix format --check-formatted exits 0; reformat bounded to exactly the 7 known WINDOWS-id-4 files, formatting-only"
    requirement: "D-02"
    verification:
      - kind: unit
        ref: "mix format --check-formatted (exit 0)"
        status: pass
      - kind: unit
        ref: "6 affected test files: 43 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: "dx_local_reproducibility_claims_test.exs reduced to 3 live cases (was 5 tests, 2 failures); 2 stale Phase-113-archive-specific cases + 3 orphaned attributes removed"
    requirement: "D-01"
    verification:
      - kind: unit
        ref: "mix test test/docs_contract/dx_local_reproducibility_claims_test.exs (3 tests, 0 failures, no unused-attribute warnings)"
        status: pass
    human_judgment: false
  - id: D4
    description: "mix ci.fast runs green end-to-end across all 7 steps (format, hex.build, compile, test, docs, credo, dialyzer)"
    requirement: "D-06"
    verification:
      - kind: integration
        ref: "mix ci.fast (exit 0; 12 doctests, 8 properties, 1697 tests, 0 failures; credo 3159 mods/funs no issues; dialyzer 0 errors)"
        status: pass
    human_judgment: false

# Metrics
duration: 6min
completed: 2026-07-29
status: complete
---

# Phase 124 Plan 01: Address v2.11 Tech Debt Summary

**Cleared all 3 v2.11 tech-debt gates (stale Phase-113 test, formatter drift, dialyzer cascade) so `mix ci.fast` runs green end-to-end, with zero rendered-output change and zero touch to the locked Ticket type-scale hierarchy.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-29T01:14:14Z
- **Completed:** 2026-07-29T01:20:30Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments
- `mix dialyzer` now reports 0 errors (was 133 across 10 files) via a single-line `@spec` widening on `Rendro.Recipes.Background.emit?/1` from a closed 1-key map type to an open map type -- `lib/rendro/recipes/ticket.ex` required zero changes.
- `mix format --check-formatted` now exits 0 -- resolved formatter-version drift on exactly the known 7-file set, confirmed formatting-only (no logic/identifier changes).
- `test/docs_contract/dx_local_reproducibility_claims_test.exs` reduced from 5 tests/2 failures to 3 tests/0 failures by deleting the 2 cases that guarded archived, deleted Phase-113 planning evidence (plus the 3 now-orphaned module attributes).
- `mix ci.fast` runs green end-to-end: 12 doctests, 8 properties, 1697 tests, 0 failures; credo clean (3159 mods/funs, no issues); dialyzer 0 errors.
- Byte-identity/golden regression suite (9 files, 27 tests) unchanged before and after the `background.ex` spec fix -- the milestone's central regression guard held.
- WINDOWS.md ledger ids 4, 5, 6 marked `fixed` (ids 1, 2, 3, 7 remain correctly open/deferred).

## Task Commits

Each task was committed atomically:

1. **Task 1: Widen Background.emit?/1's @spec to clear the dialyzer cascade (D-03)** - `d16ebdf` (fix)
2. **Task 2: Apply bounded mix format to clear the ci.fast step-1 formatter gate (D-02)** - `f7beecb` (style)
3. **Task 3: Delete the 2 stale Phase-113 docs-contract test cases + 3 orphaned attributes (D-01)** - `98310da` (test)

**Plan metadata:** committed separately (see final_commit step)

## Files Created/Modified
- `lib/rendro/recipes/background.ex` - `@spec emit?/1` widened to an open map type (required `:background` + `optional(atom()) => any()`); `def emit?/1` implementation byte-identical
- `lib/rendro/launch_artifacts.ex` - `mix format` whitespace-only (multi-line string-literal collapse)
- `test/docs_contract/theme_industry_guard_test.exs` - `mix format` whitespace-only (added parens)
- `test/docs_contract/theming_claims_test.exs` - `mix format` whitespace-only (blank-line insertion)
- `test/rendro/recipes/payslip_opts_threading_test.exs` - `mix format` whitespace-only (map re-wrap)
- `test/rendro/recipes/themed_render_smoke_test.exs` - `mix format` whitespace-only (map re-wrap)
- `test/rendro/recipes/certificate_typography_test.exs` - `mix format` whitespace-only (map re-wrap)
- `test/rendro/recipes/theme_mode_background_golden_test.exs` - `mix format` whitespace-only (blank-line insertion)
- `test/docs_contract/dx_local_reproducibility_claims_test.exs` - 2 stale Phase-113-archive test cases + 3 orphaned module attributes removed; 3 surviving tests byte-for-byte unmodified

## Decisions Made
- **D-03 execution:** confirmed the RESEARCH.md-verified root cause (closed-map `@spec` shorthand, not a value-type mismatch) and applied the exact single-line fix; `ticket.ex` untouched, matching the D-04 guardrail.
- **D-02 execution:** ran bare `mix format`; confirmed the changed-file set was exactly the 7 known files before committing (no formatter config/version mismatch signal).
- **D-01 execution:** deleted both stale cases (not skip/re-point) per RESEARCH.md's per-case analysis -- both assert only frozen historical facts about a one-time Phase-113 validation event with no forward-looking regression value; left a one-line comment explaining why.
- Ran `mix compile --force` under `MIX_ENV=test` before the full `mix ci.fast` chain to avoid spurious "redefining module" warnings that occur when `mix compile --warnings-as-errors` recompiles modules already loaded in the same alias-chain BEAM instance (an artifact of running the full alias in one invocation on a stale `_build/test`, not caused by any change in this plan) -- confirmed by a fresh, isolated `MIX_ENV=test mix compile --warnings-as-errors` succeeding cleanly first.

## Deviations from Plan

None - plan executed exactly as written. All 3 tasks matched RESEARCH.md's empirically-verified recommendations precisely.

## Issues Encountered
- On the first `mix ci.fast` run, `compile --warnings-as-errors` (step 3) failed with spurious "redefining module ... current version loaded from _build/test" warnings. Root-caused to `mix compile --force` having been run earlier in the session (dev env) plus stale `_build/test` state, not any change in this plan. Fixed by removing `_build/test` and running an isolated `MIX_ENV=test mix compile --warnings-as-errors` (clean, 0 warnings), then re-running the full `mix ci.fast` chain, which passed green end-to-end. No code changes were involved in this fix -- purely a local `_build` cache issue.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All 3 titled tech-debt targets (D-01/D-02/D-03) are closed; `mix ci.fast` is green end-to-end and can be used as the merge gate going forward.
- Deferred items remain explicitly out of scope, unchanged: Ticket visual-hierarchy re-mapping (WINDOWS id 2, locked Phase-122 decision), `pdfium-cli` tooling gap (WINDOWS id 7), Nyquist validation of phases 121/122/123, `from_brand/2` byte-level E2E golden, SUMMARY frontmatter `requirements_completed` backfill.
- The v2.11 milestone is ready for clean archival: all 21 requirements satisfied and WIRED (per prior audit), and now all non-blocking `ci.fast` gates are green too.

---
*Phase: 124-address-v2-11-tech-debt-stale-113-docs-contract-test-formatt*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 9 modified files confirmed present on disk; all 3 task commit hashes (`d16ebdf`, `f7beecb`, `98310da`) confirmed present in git log.

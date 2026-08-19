---
phase: 128-static-configurator-theme-codegen-livebook
plan: "02"
subsystem: theme code generation
tags: [elixir, mix, generator, theme, filesystem]
requires:
  - phase: 128-01
    provides: Canonical formatter-owned Rendro.Theme.Snippet.module_source/4 seam
provides:
  - Packaged mix rendro.gen.theme command with fixed application-owned wrappers
  - Closed-input validation and safe module/output derivation without user atom creation
  - Mix conflict semantics plus byte-exact read-only drift checks
affects: [128-03, static configurator, Livebook, generated theme modules]
tech-stack:
  added: []
  patterns: [closed CLI vocabulary, formatter-owned generated source, read-only byte drift gate]
key-files:
  created:
    - lib/mix/tasks/rendro/gen/theme.ex
    - test/mix/tasks/rendro_gen_theme_test.exs
  modified: []
key-decisions:
  - "Keep generated wrappers intentionally fixed at theme/0 and register_fonts/1, with no runtime override interface or Theme struct serialization."
  - "Delegate canonical wrapper bytes to Rendro.Theme.Snippet.module_source/4 and use Mix.Generator only for write ownership semantics."
  - "Document check/create guarantees as single-invocation behavior without claiming parallel-writer atomicity or interruption rollback."
patterns-established:
  - "Validate all user-controlled CLI strings and filesystem paths before formatting source or touching the filesystem."
requirements-completed: [CONFIG-05]
coverage:
  - id: D1
    description: Safe packaged generator creates formatter-owned fixed theme wrappers from closed CLI input.
    requirement: CONFIG-05
    verification:
      - kind: integration
        ref: test/mix/tasks/rendro_gen_theme_test.exs#generates the fixed default wrapper from closed CLI input
        status: pass
      - kind: unit
        ref: test/rendro/theme/snippet_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Generator owns create/conflict/force semantics and a byte-exact mutation-free check path.
    requirement: CONFIG-05
    verification:
      - kind: integration
        ref: test/mix/tasks/rendro_gen_theme_test.exs#uses Mix conflict handling and keeps check mode read-only
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-08-19
status: complete
---

# Phase 128 Plan 02: Safe Theme Generator Summary

Packaged Mix generator for fixed, application-owned theme wrappers with closed input validation and byte-exact read-only drift detection.

## Performance

- **Duration:** 7min
- **Started:** 2026-08-19T01:20:56Z
- **Completed:** 2026-08-19T01:27:44Z
- **Tasks:** 2/2
- **Files modified:** 2
- **Focused verification:** `mix test test/rendro/theme/snippet_test.exs test/mix/tasks/rendro_gen_theme_test.exs --max-failures 1` — 9 tests, 0 failures; `mix format --check-formatted` passed.

## Accomplishments

- Added `mix rendro.gen.theme` with strict preset, accent, mode, alias, and relative-path validation before source generation or filesystem writes.
- Generated wrappers contain a normalized rerun header, `@moduledoc false`, fixed `theme/0`, and fixed document-first `register_fonts/1`, all derived from the Plan 01 formatter.
- Added tested Mix create/conflict/force behavior and equal/missing/different byte checks that leave target bytes and mtimes untouched.

## Task Commits

1. **Task 1: Define strict CLI derivation and compile the generated wrapper** — `ae3aca2` (feat)
2. **Task 2: Enforce create, conflict, force, and read-only check semantics** — `b0adc66` (feat)
3. **Repository contract fix** — `7e0ec07` (fix)

## Files Created/Modified

- `lib/mix/tasks/rendro/gen/theme.ex` — packaged validated generator and filesystem ownership contract.
- `test/mix/tasks/rendro_gen_theme_test.exs` — disposable-project integration coverage for source, validation, conflict, force, and check behavior.

## Decisions Made

- Kept source generation private and formatter-owned; user strings never become atoms or runtime theme overrides.
- Made `--force` the sole noninteractive overwrite path, and made `--check` derive/read/compare only.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Canonicalized source trailing newline before byte comparison**
- **Found during:** Task 2
- **Issue:** `Mix.Generator` wrote one formatter newline not present in the check source, causing false drift on fresh output.
- **Fix:** Canonicalize the internally formatter-owned wrapper source with its final newline before both create and check paths.
- **Files modified:** `lib/mix/tasks/rendro/gen/theme.ex`
- **Verification:** equal-content create and `--check` test passed.

2. **[Rule 2 - Required convention] Tagged the packaged task for the public API documentation contract**
- **Found during:** Plan-level `mix test`
- **Issue:** the repository's public-module sweep requires visible modules to carry an explicit documentation tag.
- **Fix:** Added `@moduledoc tags: [:adapter]` to the packaged Mix task.
- **Files modified:** `lib/mix/tasks/rendro/gen/theme.ex`
- **Verification:** the prior public-module sweep failure no longer occurred in the next full-suite run.

## Issues Encountered

- Full `mix test` remains blocked by the unrelated `Rendro.DocsContract.PresetFontsPackageContractTest`: its expected `contents.tar.gz` is absent from the inspected Hex archive. Details are tracked in `deferred-items.md`; focused Plan 128-02 verification is green.

## Known Stubs

None.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

Plans 03–05 can invoke the packaged generator and rely on its formatter-owned, fixed-wrapper ownership and read-only drift semantics.

## Self-Check: PASSED

- Both planned artifact files and this summary exist.
- Task commits `ae3aca2`, `b0adc66`, and the required repository-contract fix `7e0ec07` exist in git history.

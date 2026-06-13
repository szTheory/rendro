---
phase: 94-docs-warning-hygiene
plan: 01
subsystem: docs
tags: [exdoc, mix, elixir, docs-hygiene, ci]

# Dependency graph
requires:
  - phase: 93-recipes-facade-dx-closure
    provides: stable codebase with public API contract enforcement lane in place
provides:
  - skip_code_autolink_to: list in mix.exs docs/0 suppressing 3 hidden-module prose references
  - real internal-marking @moduledoc on Rendro.PDF.Font resolving 4 typespec autolink warnings
  - docs --warnings-as-errors enforcement in ci: alias
  - zero ExDoc warnings emitted by mix docs
affects:
  - 94-02 (HYG-02 — staleness wording plan runs in the same wave)
  - 95-header-duplex-proof (inherits clean docs build baseline)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "skip_code_autolink_to: for global prose-autolink suppression of hidden internals in ExDoc docs/0"
    - "docs --warnings-as-errors in ci: alias as mechanical zero-warning drift gate"
    - "Real @moduledoc with internal-marking text on non-public modules whose types are referenced in specs"

key-files:
  created: []
  modified:
    - mix.exs
    - lib/rendro/pdf/font.ex

key-decisions:
  - "Use skip_code_autolink_to: (not skip_undefined_reference_warnings_on:) for prose module-ref suppression — distinct option taking module name strings, not file paths"
  - "Give Rendro.PDF.Font a real @moduledoc instead of keeping @moduledoc false — makes @type t resolvable by ExDoc; safe because generator uses explicit @public_modules allowlist"
  - "Place skip_code_autolink_to: immediately after skip_undefined_reference_warnings_on: in the same keyword list"
  - "Use standard Mix alias string format 'docs --warnings-as-errors' for CI enforcement"

patterns-established:
  - "Pattern: ExDoc skip_code_autolink_to: takes module name strings (not file paths); one entry covers all occurrences of that module across all source files"
  - "Pattern: Non-public internal modules that appear in @spec signatures should carry a real @moduledoc marking them internal rather than @moduledoc false, when their types are referenced in specs"

requirements-completed: [HYG-01]

# Metrics
duration: 5min
completed: 2026-06-13
---

# Phase 94 Plan 01: ExDoc Warning Hygiene Summary

**Zero ExDoc warnings via skip_code_autolink_to: list + Font @moduledoc fix, enforced in CI with docs --warnings-as-errors in the ci: alias**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-13T15:15:41Z
- **Completed:** 2026-06-13T15:21:34Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `skip_code_autolink_to: ["Rendro.PDF.CidFont", "Rendro.PDF.FontSubsetter", "Rendro.Format"]` to `mix.exs` `docs/0`, eliminating 5 unique Class A prose autolink warnings (appearing as 10 lines due to ExDoc's html+epub dual pass)
- Replaced `@moduledoc false` with an internal-marking `@moduledoc` on `Rendro.PDF.Font`, eliminating 4 unique Class B typespec autolink warnings for `Rendro.PDF.Font.t()` (appearing as 8 lines)
- Changed `"docs"` to `"docs --warnings-as-errors"` in the `ci:` alias, mechanically enforcing the zero-warning policy on every CI run
- `mix docs` now emits zero warnings; `mix docs --warnings-as-errors` exits 0; public API contract test (6 tests, 0 failures) remains green — Font not added to public API surface

## Task Commits

Each task was committed atomically:

1. **Task 1: Add skip_code_autolink_to: to docs/0 and replace Font @moduledoc false** - `e5f24ef` (feat)
2. **Task 2: Add --warnings-as-errors to ci: alias docs step** - `e9b44d1` (feat)

## Files Created/Modified

- `mix.exs` - Added `skip_code_autolink_to:` list in `docs/0`; changed `"docs"` to `"docs --warnings-as-errors"` in `aliases/0` `ci:` list
- `lib/rendro/pdf/font.ex` - Replaced `@moduledoc false` with internal-marking `@moduledoc` text

## Decisions Made

- Used `skip_code_autolink_to:` (not `skip_undefined_reference_warnings_on:`) — the two options have completely different semantics: the former takes module name strings and suppresses autolinking globally; the latter takes file paths and suppresses undefined-reference warnings on specific files.
- 3 entries in `skip_code_autolink_to:` suffice for all 5 Class A warnings because `Rendro.Format` appears in two source files but needs only one list entry (the option applies globally).
- `Rendro.PDF.Font` receives a real `@moduledoc` (not removal of `@moduledoc false` without replacement) so its `@type t` becomes resolvable by ExDoc without widening the public API surface. The `mix rendro.api.gen` generator uses an explicit `@public_modules` allowlist so Font is never added to `priv/public_api.json`.

## Deviations from Plan

None - plan executed exactly as written.

The plan's verification commands used `cd /Users/jon/projects/rendro` (main repo), but since execution runs in a git worktree, verification was performed from the worktree root with `MIX_DEPS_PATH` pointing to the main repo's `deps/`. Results were identical: 0 warnings, 0 failures.

## Issues Encountered

None - all edits applied cleanly, verification commands passed on first attempt.

## Known Stubs

None.

## Threat Flags

No new security-relevant surface introduced. Changes are build-time documentation configuration and a module-level doc attribute only.

## Next Phase Readiness

- HYG-01 complete: `mix docs --warnings-as-errors` exits 0; zero-warning policy mechanically enforced in CI
- Plan 94-02 (HYG-02 staleness wording) runs in parallel in the same wave — no dependency on 94-01 output
- Phase 95 (header duplex proof) inherits a clean docs build baseline with zero ExDoc warnings

## Self-Check: PASSED

- `e5f24ef` exists in git log: confirmed
- `e9b44d1` exists in git log: confirmed
- `mix.exs` contains `skip_code_autolink_to:`: confirmed (line 116)
- `lib/rendro/pdf/font.ex` has real `@moduledoc`: confirmed (line 2)
- `mix docs` warning count: 0
- `mix docs --warnings-as-errors`: exit 0
- Contract test: 6 tests, 0 failures

---
*Phase: 94-docs-warning-hygiene*
*Completed: 2026-06-13*

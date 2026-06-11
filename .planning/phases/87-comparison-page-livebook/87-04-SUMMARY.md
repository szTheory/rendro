---
phase: 87-comparison-page-livebook
plan: 04
subsystem: livebook
tags: [livebook, notebook, advisory-ci, docs]

requires:
  - phase: 87-01
    provides: Static comparison proof scaffold and docs-contract foundation
provides:
  - Canonical first-invoice Livebook tutorial
  - No-server advisory notebook execution task
  - Tests proving notebook conversion/execution stays advisory
affects: [comparison-guide, exdoc, package, ci-guardrails]

tech-stack:
  added:
    - livebook 0.19.8 as dev/test runtime:false dependency
  patterns:
    - Livebook conversion via Livebook.live_markdown_to_elixir/1 without starting a server
    - Notebook-only Kino dependency via Mix.install

key-files:
  created:
    - guides/livebook/first_invoice.livemd
    - lib/mix/tasks/rendro/livebook/check.ex
    - test/mix/tasks/rendro_livebook_check_test.exs
    - config/config.exs
  modified:
    - mix.exs
    - mix.lock

key-decisions:
  - "Livebook is dev/test runtime:false and used only for advisory conversion; Kino stays inside the notebook Mix.install list."
  - "The advisory checker executes converted notebook code with plain elixir and RENDRO_LIVEBOOK_LOCAL=1, never by starting a Livebook server."

patterns-established:
  - "Notebook local-checkout execution uses RENDRO_LIVEBOOK_PATH so temp scripts can install the repository path reliably."
  - "Mix task tests inject both converter and command runner seams to cover failure output without launching external notebook services."

requirements-completed: [CMP-03]

duration: 15 min
completed: 2026-06-11
---

# Phase 87 Plan 04: Livebook Tutorial Summary

**First-invoice Livebook tutorial with serverless advisory execution through a Mix task**

## Performance

- **Duration:** 15 min
- **Started:** 2026-06-11T20:40:00Z
- **Completed:** 2026-06-11T20:55:39Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `guides/livebook/first_invoice.livemd` with Hex and local-checkout install modes, deterministic invoice rendering, `%PDF-` validation, byte size, SHA-256, Kino preview, Kino download, schematic Phoenix handoff, and guide/manual links.
- Added `mix rendro.livebook.check`, which converts the notebook via `Livebook.live_markdown_to_elixir/1` and executes it as a plain Elixir script with `RENDRO_LIVEBOOK_LOCAL=1`.
- Added focused task tests for converter/runner injection, local checkout env, failure output, notebook content, and no Livebook server startup.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the first-invoice Livebook tutorial** - `c979afc` (feat)
2. **Task 2: Add the no-server Livebook execution task** - `1e982a4` (feat)
3. **Task 3: Add task tests and run the notebook check** - `17d827a` (test)

**Plan metadata:** pending in this commit

## Files Created/Modified

- `guides/livebook/first_invoice.livemd` - Canonical first invoice notebook with preview/download flow.
- `lib/mix/tasks/rendro/livebook/check.ex` - Advisory no-server notebook conversion and execution task.
- `test/mix/tasks/rendro_livebook_check_test.exs` - Unit coverage for the task seams and notebook content.
- `mix.exs` - Adds Livebook as dev/test runtime:false and relaxes YAML dependency range for Livebook compatibility.
- `mix.lock` - Resolves Livebook and transitive dev/test dependencies.
- `config/config.exs` - Minimal Livebook compile-time config needed for dependency compilation.

## Decisions Made

- Added `:jason`, `:jsv`, and `:yaml_elixir` to the notebook `Mix.install` list for local checkout mode because current Rendro lib modules reference those validators/encoders during path dependency compilation.
- Kept Phoenix code in an `elixir-schematic` block so conversion does not execute a Phoenix controller or make Phoenix part of the notebook runtime.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Livebook dependency required compile-time config**
- **Found during:** Task 2
- **Issue:** `livebook 0.19.8` failed to compile as a dependency without its endpoint/app compile-time config.
- **Fix:** Added minimal `config/config.exs` entries matching Livebook's package config defaults needed for compilation.
- **Files modified:** `config/config.exs`
- **Verification:** `mix compile --warnings-as-errors` passed.
- **Committed in:** `1e982a4`

**2. [Rule 3 - Blocking] Converted notebook script could not use ExUnit assert**
- **Found during:** Task 3
- **Issue:** `assert/1` is not imported in a plain converted Elixir script.
- **Fix:** Replaced the assertion with an explicit PDF header guard that raises on failure.
- **Files modified:** `guides/livebook/first_invoice.livemd`
- **Verification:** `mix rendro.livebook.check` passed.
- **Committed in:** `c979afc`

---

**Total deviations:** 2 auto-fixed (2 blocking).
**Impact on plan:** Both fixes preserve the intended advisory Livebook execution path and avoid runtime dependency leakage.

## Issues Encountered

- `mix deps.get` initially failed because Livebook pinned older transitive dev/test packages. Resolved by unlocking `yaml_elixir`, `req`, `plug_crypto`, and `ecto`, and by relaxing the direct `yaml_elixir` version range.
- The first real notebook check exposed missing JSON/YAML validator deps during local path compilation. Added those dependencies to the notebook `Mix.install` list; no project runtime dependency was added.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix deps.get` - passed after dependency unlocks.
- `mix compile --warnings-as-errors` - passed.
- `mix test test/mix/tasks/rendro_livebook_check_test.exs` - passed, 5 tests.
- `mix rendro.livebook.check` - passed and executed the converted notebook without starting a Livebook server.

## Next Phase Readiness

Plan 05 can wire the notebook into ExDoc extras, README, package contents, and advisory CI. Wave 2 still requires the `87-02` benchmark execution checkpoint before later waves can safely proceed.

## Self-Check: PASSED

- Notebook contains `RENDRO_LIVEBOOK_LOCAL`, `Rendro.Recipes.Invoice.document`, `Kino.HTML.new`, `Kino.Download.new`, and `%PDF-`.
- `mix rendro.livebook.check` converts and executes the notebook successfully.
- Livebook is dev/test runtime:false; Kino is notebook-only and absent from `mix.exs`.
- No Livebook server process is started by the task.

---
*Phase: 87-comparison-page-livebook*
*Completed: 2026-06-11*

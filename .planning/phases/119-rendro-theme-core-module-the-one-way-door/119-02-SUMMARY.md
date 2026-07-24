---
phase: 119-rendro-theme-core-module-the-one-way-door
plan: 02
subsystem: theming
tags: [elixir, public-api, manifest, adapter-tier, docs-contract, byte-equality, one-way-door]

# Dependency graph
requires:
  - phase: 119-rendro-theme-core-module-the-one-way-door
    provides: "Rendro.Theme core value module with @moduledoc tags: [:adapter] (Plan 01)"
provides:
  - "Rendro.Theme registered on the adapter/Evolving tier in priv/public_api.json (observable public contract)"
  - "CONTRACT-03 industry/brand source-grep guard on lib/rendro/theme.ex"
  - "Zero-recipe-change regression proof (62 v2.10 goldens byte-identical, no re-bless)"
affects: [120-recipe-theme-threading, 121-background-fill-dark-mode, 122-typography-application]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Adapter-tier registration = @moduledoc tag + one @public_modules line + mix rendro.api.gen (never hand-edit the manifest)"
    - "Duplicate byte-equality reconcile: both RG-1 + RG-2 fresh_json == checked_in assertions greened together (D-06)"
    - "Static File.read! + refute source =~ term tripwire for industry/brand leakage (sibling of integrations_claims_test.exs)"

key-files:
  created:
    - test/docs_contract/theme_industry_guard_test.exs
  modified:
    - lib/mix/tasks/rendro/api.gen.ex
    - priv/public_api.json

key-decisions:
  - "Placed Rendro.Theme after Rendro.Telemetry in the @public_modules adapter block (T-alphabetical, still adapter tier); position is cosmetic because encode_manifest/1 sorts output"
  - "Two pre-existing, unrelated mix test failures (dx_local_reproducibility_claims_test.exs) logged to deferred-items.md rather than fixed — out of scope, caused by the v2.11 milestone-cleanup commit 0de2de8 deleting phase-113 planning files"

requirements-completed: [CONTRACT-01, CONTRACT-03, THEME-03]

coverage:
  - id: RG
    description: "Rendro.Theme adapter entry in priv/public_api.json reconciles BOTH byte-equality assertions (RG-1 public_api_contract_test:72 + RG-2 manifest_test:98)"
    requirement: CONTRACT-01
    verification:
      - kind: contract
        ref: "test/docs_contract/public_api_contract_test.exs:72 + test/rendro/public_api/manifest_test.exs:98"
        status: pass
    human_judgment: false
  - id: G3
    description: "Industry/brand source-grep guard fails on any industry/recipe-family/named-brand or preset/catalog/configurator/genre term in lib/rendro/theme.ex"
    requirement: CONTRACT-03
    verification:
      - kind: contract
        ref: "test/docs_contract/theme_industry_guard_test.exs"
        status: pass
    human_judgment: false
  - id: TH3
    description: "Rendro.Theme ships on the adapter/Evolving tier with derivation helpers absent from the manifest functions list"
    requirement: THEME-03
    verification:
      - kind: contract
        ref: "priv/public_api.json Elixir.Rendro.Theme functions == [dark/1, default/0, from_brand/2, resolve/1]"
        status: pass
    human_judgment: false
  - id: ZRC
    description: "Zero-recipe-change gate — full mix test recipe suites green with priv/goldens + lib/rendro/recipes clean and no golden re-bless"
    verification:
      - kind: regression
        ref: "git status --porcelain priv/goldens lib/rendro/recipes (empty); recipe byte-identity suites 7 tests 0 failures"
        status: pass
    human_judgment: false

# Metrics
duration: 3min
completed: 2026-07-24
status: complete
---

# Phase 119 Plan 02: Register `Rendro.Theme` on the adapter tier + lock the guards Summary

**`Rendro.Theme` is now an observable public contract on the adapter/Evolving tier — one `@public_modules` line + a regenerated `priv/public_api.json` reconciled BOTH byte-equality manifest assertions (RG-1 + RG-2) green together, a source-grep tripwire fences `theme.ex` against industry/brand leakage, and every one of the 62 committed v2.10 goldens stayed byte-identical (zero rendered output changed).**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-07-24T22:58:39Z
- **Completed:** 2026-07-24T23:01Z
- **Tasks:** 3
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- `test/docs_contract/theme_industry_guard_test.exs`: CONTRACT-03 / D-02 static tripwire — reads `lib/rendro/theme.ex` via `File.read!` and `refute source =~ term` over the verbatim recipe-family/industry list (`invoice payslip ticket certificate statement receipt medical legal restaurant retail`) plus `preset catalog configurator genre`, and asserts the positive `default`/`from_brand` surface exists. 3 tests, all green.
- `lib/mix/tasks/rendro/api.gen.ex`: exactly one added line (`Rendro.Theme`) in the `@public_modules` adapter block (after `Rendro.Telemetry`); tier derived from Plan 01's `@moduledoc tags: [:adapter]` via `Code.fetch_docs/1`. No other diff.
- `priv/public_api.json`: regenerated via `mix rendro.api.gen` (never hand-edited). New `"Elixir.Rendro.Theme"` entry — `"tier": "adapter"`, `functions: ["dark/1","default/0","from_brand/2","resolve/1"]` (helpers `on_accent_for`/`luminance`/`contrast_ratio`/`linearize`/`hex_to_rgb`/`deep_merge`/`normalize` absent), `types` alphabetized (`colors/0 font_role/0 radius/0 rgb/0 rules/0 spacing/0 t/0 type_step/0 typography/0`).
- **Duplicate-assertion trap cleared (D-06 / Phase-115 lesson):** BOTH `fresh_json == checked_in` byte-equality assertions reconciled green together — RG-1 `public_api_contract_test.exs:72` AND RG-2 `manifest_test.exs:98`. `grep -rn "fresh_json == checked_in" test/` returns exactly 2 hits (completeness proof — no third byte-compare missed).
- **Zero-recipe-change gate proven:** recipe byte-identity suites (invoice/payslip/ticket) 7 tests / 0 failures with `MIX_GOLDEN_BLESS` unset; `git status --porcelain priv/goldens` and `git status --porcelain lib/rendro/recipes` both empty — all 62 committed `.sha256` goldens byte-identical. The new module changed zero rendered output.

## Task Commits

Each task was committed atomically:

1. **Task 1: theme.ex industry/brand source-grep guard** - `8d779a5` (test)
2. **Task 2: register Rendro.Theme + regenerate manifest (RG-1 + RG-2)** - `40b7847` (feat)
3. **Task 3: zero-recipe-change phase gate** - no source change; verification-only gate (files already committed in Task 2)

## Files Created/Modified
- `test/docs_contract/theme_industry_guard_test.exs` (created) - CONTRACT-03 tripwire.
- `lib/mix/tasks/rendro/api.gen.ex` (modified) - one adapter-block registry line.
- `priv/public_api.json` (modified) - regenerated manifest with the `Elixir.Rendro.Theme` adapter entry.

## Decisions Made
- **Registry placement:** `Rendro.Theme` inserted after `Rendro.Telemetry` (T-alphabetical) in the adapter block rather than immediately beside `Rendro.Format`. The `@public_modules` list is a plain registry — `encode_manifest/1` sorts the emitted manifest alphabetically — so source-list position is cosmetic; the tier comes entirely from the module's `@moduledoc tags: [:adapter]`. This keeps the adapter block loosely alphabetical.

## Deviations from Plan

None affecting scope — the plan executed exactly as written. One out-of-scope discovery was logged, not fixed:

### Out-of-scope discovery (logged to deferred-items.md, not fixed)

**Two pre-existing, unrelated `mix test` failures (milestone-cleanup artifact)**
- **Found during:** Task 3 (full `mix test`).
- **Issue:** `test/docs_contract/dx_local_reproducibility_claims_test.exs:77` and `:103` fail with `File.Error` reading `.planning/phases/113-dx-local-reproducibility-validation/113-METRICS.md` and `113-UAT.md`.
- **Root cause:** commit `0de2de8 chore: clear v2.10 phase directories for milestone v2.11` deleted those phase-113 planning artifacts before Phase 119 began; the stale docs-contract test still hard-reads them.
- **Why out of scope:** the test touches no `Theme`/`public_api`/`golden` code — orthogonal to this phase's one-way-door work. Per the scope boundary, logged to `deferred-items.md` and left for the v2.11 milestone-cleanup follow-up owner.
- **Independence from the gate:** the zero-recipe-change gate is satisfied regardless — `priv/goldens` and `lib/rendro/recipes` are both clean, no golden re-bless, `MIX_GOLDEN_BLESS` unset throughout.

## Issues Encountered
Only the two pre-existing unrelated failures above (documented in `deferred-items.md`). No Theme/manifest/golden issues.

## Next Phase Readiness
- `Rendro.Theme`'s field shape is now the observable public contract on the adapter tier — the milestone's one-way door is closed on the manifest side. Downstream phases (120 recipe-theme threading, 121 background-fill/dark-mode, 122 typography) can consume the frozen shape.
- The industry-agnostic guard (`theme_industry_guard_test.exs`) will trip if any future edit leaks an industry/brand/preset term into `theme.ex`.
- Every v2.10 golden stays byte-identical; the new module imported by nothing this phase changed zero rendered output.

## Self-Check: PASSED

- FOUND: test/docs_contract/theme_industry_guard_test.exs
- FOUND: lib/mix/tasks/rendro/api.gen.ex (Rendro.Theme in adapter block)
- FOUND: priv/public_api.json ("Elixir.Rendro.Theme" adapter entry, functions dark/1 default/0 from_brand/2 resolve/1)
- FOUND commit: 8d779a5 (Task 1)
- FOUND commit: 40b7847 (Task 2)
- VERIFIED: grep -rn "fresh_json == checked_in" test/ == 2 hits
- VERIFIED: git status priv/goldens + lib/rendro/recipes clean

---
*Phase: 119-rendro-theme-core-module-the-one-way-door*
*Completed: 2026-07-24*

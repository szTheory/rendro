---
phase: 83
plan: 05
subsystem: docs-contract
tags: [support-matrix, public-api, docs-contract, api-stability, explicit-deferral]
dependency_graph:
  requires:
    - 83-01 (shaper behaviour split, Shaper removed from hidden_modules in public_api_contract_test)
    - 83-04 (cluster-boundary split_graphemes)
  provides:
    - priv/support_matrix.json text_shaping section (5 entries: 1 supported + 4 explicit_deferral)
    - test/docs_contract/script_support_claims_test.exs (new docs-contract guard)
    - priv/public_api.json updated (Rendro.Text.Shaper stable, Rendro.Text.Shaper.Simple stable, Rendro.Adapters.HarfBuzz adapter)
    - guides/api_stability.md updated (Tier-1 + Tier-2 entries + deferral reasons)
  affects:
    - scripts/verify_docs.exs (lane count 12 -> 13)
    - test/guardrails/required_checks_contract_test.exs (lane count 12 -> 13)
    - test/rendro/public_api/manifest_test.exs (Rendro.Text.Shaper removed from hidden list)
    - lib/mix/tasks/rendro/api.gen.ex (added Text.Shaper, Text.Shaper.Simple, Adapters.HarfBuzz to @public_modules)
tech_stack:
  added: []
  patterns:
    - TDD RED/GREEN cycle for docs-contract test
    - Lockstep triple update (verify_docs.exs + guardrails test lane count)
    - explicit_deferral vocabulary for non-viewer matrix rows
    - Deferral reason mirror in api_stability.md (viewer_evidence_claims_test contract)
key_files:
  created:
    - test/docs_contract/script_support_claims_test.exs
  modified:
    - priv/support_matrix.json (text_shaping section added)
    - priv/public_api.json (regenerated with new stable+adapter modules)
    - guides/api_stability.md (Tier-1 + Tier-2 + deferral reasons)
    - scripts/verify_docs.exs (lane 13 added)
    - lib/mix/tasks/rendro/api.gen.ex (@public_modules updated)
    - test/guardrails/required_checks_contract_test.exs (lane count 12->13)
    - test/rendro/public_api/manifest_test.exs (Rendro.Text.Shaper removed from hidden list)
decisions:
  - "Deferral reasons for text_shaping entries must be mirrored verbatim in api_stability.md — viewer_evidence_claims_test scans ALL explicit_deferral entries in the matrix and asserts their first 40 chars appear in the guide"
  - "Lockstep triple updated: verify_docs.exs lane count, guardrails contract test count, and the new script_support_claims_test.exs are all in sync at 13 lanes"
  - "manifest_test.exs (separate from public_api_contract_test.exs) also had Rendro.Text.Shaper in hidden list — removed as Rule 2 auto-fix"
  - "Rendro.Adapters.HarfBuzz required explicit addition to @public_modules in api.gen.ex — the @adapter_files list in public_api.ex drives recompile_conditional_adapters, but @public_modules drives which modules appear in the manifest"
requirements-completed:
  - HYG-01
  - HYG-05
metrics:
  duration: "~35m"
  completed: "2026-06-10"
  tasks: 2
  files: 8
---

# Phase 83 Plan 05: Docs-Contract & Public API Manifest Finalization Summary

## One-liner

Added `text_shaping` explicit_deferral matrix rows (Arabic, Hebrew/RTL, Devanagari, Thai) with CI-enforcing docs-contract test, regenerated the public API manifest to include Rendro.Text.Shaper (stable) + Rendro.Adapters.HarfBuzz (adapter), and updated `guides/api_stability.md` tier listings.

## Tasks

### Task 1: Add text_shaping section to support_matrix.json + create script_support_claims_test.exs (TDD)

**Status:** COMPLETE

**Commits:**
- `46d6b72` — test(83-05): add failing tests for script_support_claims (RED phase)
- `2e2c95b` — feat(83-05): add text_shaping section to support_matrix.json + register lane

**Verification passed:**
- priv/support_matrix.json has `"text_shaping"` with 5 entries (latin_and_cjk supported + 4 explicit_deferral)
- All four explicit_deferral entries have evidence_deferred strings >= 40 chars
- scripts/verify_docs.exs has the Script support claims lane
- `mix test test/docs_contract/script_support_claims_test.exs` passes (2 tests, 0 failures)

### Task 2: Promote Shaper to public — remove from hidden_modules, regenerate API manifest, update api_stability.md

**Status:** COMPLETE

**Commits:**
- `f53ece9` — feat(83-05): promote Shaper to public — update manifest, api_stability.md, api.gen
- `bd44f1d` — fix(83-05): Rule 2 auto-fixes — update lockstep triple + manifest hidden modules

**Verification passed:**
- `Rendro.Text.Shaper` NOT in hidden_modules list in public_api_contract_test.exs
- priv/public_api.json contains `Rendro.Text.Shaper` (tier: stable), `Rendro.Text.Shaper.Simple` (tier: stable), `Rendro.Adapters.HarfBuzz` (tier: adapter)
- guides/api_stability.md Tier-1 lists `Rendro.Text.Shaper` and `Rendro.Text.Shaper.Simple`
- guides/api_stability.md Tier-2 Adapters lists `Rendro.Adapters.HarfBuzz`
- `mix test test/docs_contract/` passes (1 doctest + 109 tests, 0 failures)
- `mix test` passes (12 doctests + 4 properties + 1008 tests, 0 failures, 10 excluded)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] viewer_evidence_claims_test.exs asserts deferral reasons appear in api_stability.md**
- **Found during:** Task 1 (after adding text_shaping explicit_deferral entries to support_matrix.json)
- **Issue:** `viewer_evidence_claims_test.exs` line 73-85 collects ALL `explicit_deferral` entries from the matrix and asserts the first 40 chars of each `evidence_deferred` string appear verbatim in `guides/api_stability.md`. The 4 new text_shaping entries triggered this check.
- **Fix:** Added the four text_shaping deferral reason entries to the "Explicit Deferral Reasons (matrix-mirrored)" section in `guides/api_stability.md`.
- **Files modified:** `guides/api_stability.md`
- **Commit:** `f53ece9`

**2. [Rule 2 - Missing critical functionality] Lockstep triple: guardrails lane count not updated**
- **Found during:** Task 1 (adding 13th lane to verify_docs.exs triggered the count assertion)
- **Issue:** `test/guardrails/required_checks_contract_test.exs` asserts `length(lane_entries) == 12`. Adding the Script support claims lane made this 13.
- **Fix:** Updated the test description and assertion from 12 to 13.
- **Files modified:** `test/guardrails/required_checks_contract_test.exs`
- **Commit:** `bd44f1d`

**3. [Rule 2 - Missing critical functionality] manifest_test.exs still had Rendro.Text.Shaper in hidden list**
- **Found during:** Task 2 (full suite run after regenerating priv/public_api.json)
- **Issue:** `test/rendro/public_api/manifest_test.exs` line 33 had `"Elixir.Rendro.Text.Shaper"` in the `hidden_modules` list. Plan 83-01 removed it from `public_api_contract_test.exs` but not from this separate manifest test file.
- **Fix:** Removed `"Elixir.Rendro.Text.Shaper"` from the hidden_modules list in `manifest_test.exs`.
- **Files modified:** `test/rendro/public_api/manifest_test.exs`
- **Commit:** `bd44f1d`

**4. [Rule 3 - Blocking] Rendro.Adapters.HarfBuzz and Text.Shaper not in @public_modules in api.gen.ex**
- **Found during:** Task 2 (mix rendro.api.gen did not include the new modules)
- **Issue:** The `@adapter_files` list in `public_api.ex` drives `recompile_conditional_adapters/0`, but the `@public_modules` list in `lib/mix/tasks/rendro/api.gen.ex` separately defines which modules appear in the manifest. The new modules were added to `@adapter_files` in Plan 83-01 but not to `@public_modules`.
- **Fix:** Added `Rendro.Text.Shaper`, `Rendro.Text.Shaper.Simple`, and `Rendro.Adapters.HarfBuzz` to the `@public_modules` list in `api.gen.ex`.
- **Files modified:** `lib/mix/tasks/rendro/api.gen.ex`
- **Commit:** `f53ece9`

## Final Verification

All success criteria met:

```
mix test test/docs_contract/script_support_claims_test.exs  → 2 tests, 0 failures
mix test test/docs_contract/                                 → 1 doctest + 109 tests, 0 failures
mix test                                                     → 12 doctests + 4 properties + 1008 tests, 0 failures (10 excluded)

grep "text_shaping" priv/support_matrix.json                → shows text_shaping key
grep '"explicit_deferral"' priv/support_matrix.json | wc -l → 13 (>= 4 new ones for text_shaping)
grep "Rendro.Text.Shaper" priv/public_api.json              → Elixir.Rendro.Text.Shaper (stable), Elixir.Rendro.Text.Shaper.Simple (stable)
grep "Rendro.Adapters.HarfBuzz" guides/api_stability.md     → Tier-2 Adapters entry
```

## Known Stubs

None. All plan deliverables are fully wired.

## Threat Flags

None. The threat model's three mitigations (T-83-11, T-83-12, T-83-13) are all implemented:
- T-83-11: `script_support_claims_test.exs` guards the four explicit_deferral entries
- T-83-12: `public_api_contract_test.exs` shows Shaper as stable-tier public module; public claim is structurally true
- T-83-13: `public_api_contract_test.exs` byte-compares the manifest against a fresh generation run

## Self-Check: PASSED

Files exist:
- test/docs_contract/script_support_claims_test.exs ✓
- priv/support_matrix.json (text_shaping key) ✓
- priv/public_api.json (Rendro.Text.Shaper stable tier) ✓
- guides/api_stability.md (Tier-1 Shaper entries, Tier-2 HarfBuzz) ✓

Commits exist:
- 46d6b72 ✓ (test RED)
- 2e2c95b ✓ (feat GREEN)
- f53ece9 ✓ (feat Task 2)
- bd44f1d ✓ (fix auto-fixes)

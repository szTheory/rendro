---
phase: 93-recipes-facade-dx-closure
plan: "03"
subsystem: public-api-contract
tags:
  - public-api
  - recipes-facade
  - api-contract
  - docs

dependency_graph:
  requires:
    - "93-02"
  provides:
    - priv/public_api.json updated (10-entry Elixir.Rendro.Recipes.functions)
    - guides/api_stability.md D-13 note
  affects:
    - public_api_contract_test.exs (byte-compare now passes)

tech_stack:
  added: []
  patterns:
    - mix rendro.api.gen mechanical regeneration (never hand-edit priv/public_api.json)

key_files:
  created: []
  modified:
    - priv/public_api.json
    - guides/api_stability.md

decisions:
  - "Used mix rendro.api.gen exclusively — no hand-editing of priv/public_api.json per T-93-06 mitigation"
  - "Placed Recipes facade note in Tier-1 Stable section of api_stability.md; no per-function entries added (Tier-1 covers facades by module)"

metrics:
  duration: "~5 minutes"
  completed: "2026-06-13T14:33:42Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
---

# Phase 93 Plan 03: Contract Regeneration & Doc Note Summary

Contract regenerated via `mix rendro.api.gen` (additive 2→10 entries in `Elixir.Rendro.Recipes.functions`); D-13 one-line note added to `guides/api_stability.md` referencing all five recipe families in arity-1 and arity-2 forms.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Run mix rendro.api.gen and verify additive-only diff | 551e849 | priv/public_api.json |
| 2 | Add facade-expansion note to guides/api_stability.md (D-13) | 84e80ff | guides/api_stability.md |

## Verification Results

### Signal A: Facade drift test
`mix test test/rendro/recipes_facade_drift_test.exs` — 9 tests, 0 failures

### Signal B: opts-threading regression tests
Covered by Signal A (drift test includes opts-threading assertions)

### Signal C: Public API contract test
`mix test test/docs_contract/public_api_contract_test.exs` — 6 tests, 0 failures

### Signal D: Additive-only diff
`git diff priv/public_api.json`:
- 8 new `+` entries in `Elixir.Rendro.Recipes.functions`: `branded_invoice/2`, `certificate/1`, `certificate/2`, `invoice/2`, `receipt/1`, `receipt/2`, `statement/1`, `statement/2`
- 1 modified line (the `"invoice/1"` entry gained a trailing comma as it moved from last position — `invoice/1` itself remains present in the 10-entry array)
- 0 entries removed from any module
- No other module block touched

### Full test suite
`mix test` — 12 doctests, 4 properties, 1199 tests, 0 failures (11 excluded)

## Success Criteria Verified

- [x] priv/public_api.json regenerated via `mix rendro.api.gen` only (never hand-edited)
- [x] `Elixir.Rendro.Recipes.functions`: 2 entries → 10 entries (alpha-sorted: branded_invoice/1, branded_invoice/2, certificate/1, certificate/2, invoice/1, invoice/2, receipt/1, receipt/2, statement/1, statement/2)
- [x] Additive-only diff — 8 new entries, no entry removed, no other module touched
- [x] `public_api_contract_test.exs` all 6 assertions pass (byte-compare GREEN)
- [x] Full `mix test` suite green — 1199 tests, 0 failures
- [x] Phase 93 SC#1: 10 @spec'd functions on Rendro.Recipes (5 recipes × arity-1 + arity-2) — verified pre-flight (grep -c "@spec" returns 10)
- [x] Phase 93 SC#2: opts-drop footgun fixed (in base commit; drift test confirms)
- [x] Phase 93 SC#3: drift test GREEN (9 tests, 0 failures)
- [x] Phase 93 SC#4: priv/public_api.json updated, contract test passes
- [x] D-13: guides/api_stability.md one-line note added for statement/receipt/certificate plus arity-2 opts forms

## Deviations from Plan

None — plan executed exactly as written. The generator ran cleanly; the additive diff matched the expected shape; all four phase signals are green.

## Known Stubs

None.

## Threat Flags

No new security-relevant surface introduced. The regenerated `priv/public_api.json` is a deterministic output of `mix rendro.api.gen`; no network, no user input, no new trust boundaries. The byte-compare assertion (Assertion 2 in `public_api_contract_test.exs`) remains the canonical mitigation for T-93-06 (accidental hand-edit).

## Self-Check: PASSED

- [x] `priv/public_api.json` modified and committed — `git show 551e849 --name-only` confirms
- [x] `guides/api_stability.md` modified and committed — `git show 84e80ff --name-only` confirms
- [x] Commit 551e849 exists: `chore(93-03): regenerate public_api.json with 10-entry Rendro.Recipes facade`
- [x] Commit 84e80ff exists: `docs(93-03): add Rendro.Recipes facade note to api_stability.md (D-13)`
- [x] All four phase signals verified GREEN after commits

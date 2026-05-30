---
phase: 79-public-api-contract-enforcement-lane
plan: "01"
subsystem: test/docs_contract
tags: [api-contract, public-api, exunit, introspection, tdd-red]
dependency_graph:
  requires:
    - lib/rendro/public_api.ex
    - lib/rendro/public_api/loader.ex
    - lib/rendro/public_api/validator.ex
    - lib/mix/tasks/rendro/api.gen.ex
    - priv/public_api.json
  provides:
    - test/docs_contract/public_api_contract_test.exs
  affects:
    - API-04 requirement coverage (assertions 1-4 green, assertion 5 intentionally red)
tech_stack:
  added: []
  patterns:
    - ExUnit async:false contract test
    - Code.fetch_docs/1 module introspection (hidden-internals, tier-tag)
    - Code.Typespec.fetch_specs/1 for @spec coverage (not Code.fetch_docs)
    - Mix.Tasks.Rendro.Api.Gen.encode_manifest/1 <> "\n" byte-equality
    - String.to_existing_atom for manifest key → module atom conversion
    - Two-list drift diff failure message (D-03 errors-as-product pattern)
key_files:
  created:
    - test/docs_contract/public_api_contract_test.exs
  modified: []
decisions:
  - "Assertion 5 (@spec coverage) is intentionally RED at plan completion — Rendro.Component has 0 specs on 2 public functions (image/2, render_component/2); Plan 02 backfills them"
  - "Used Code.Typespec.fetch_specs/1 for @spec presence, not Code.fetch_docs/1 (specs live in abstract_code BEAM chunk, not Docs chunk)"
  - "Mirrored manifest_test.exs exactly for setup_all, BEAM-availability filter, and encode_manifest <> newline pattern"
metrics:
  duration_seconds: 74
  completed_date: "2026-05-30"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 0
---

# Phase 79 Plan 01: Public API Contract Test Summary

One-liner: ExUnit contract test with 5 API-04 assertions (schema/byte-equality/hidden-internals/tier-tag GREEN; @spec coverage RED for Rendro.Component) using Code.Typespec.fetch_specs/1 and two-list drift diff (D-03).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create public_api_contract_test.exs with all 5 API-04 assertions | 618eb90 | test/docs_contract/public_api_contract_test.exs |

## What Was Built

Created `test/docs_contract/public_api_contract_test.exs` as the 14th docs-contract lane. The file is `async: false` (required for contract tests that call `recompile_conditional_adapters/0`), mirrors `manifest_test.exs` exactly for the `setup_all` block and BEAM-availability filter, and covers all 5 API-04 sub-assertions:

1. **Schema validation (D-01):** Loads manifest via `Loader.load!/0` and asserts `Validator.validate/1 == :ok`. GREEN.
2. **Manifest surface byte-equality (D-01/D-03):** Regenerates manifest in-memory using the generator's exact codepath, encodes with `encode_manifest/1 <> "\n"` (trailing newline mandatory), byte-compares to `priv/public_api.json`. On mismatch: two-list drift diff naming modules in each direction plus `mix rendro.api.gen` instruction. GREEN.
3. **Known internals :hidden (D-05):** Asserts `Code.fetch_docs/1` returns `:hidden` module_doc for 6 engine modules; asserts `@doc false` on 5 redact helper functions in `Rendro.Sign` and `Rendro.Protect`. GREEN.
4. **Tier-tag exactly one (D-06):** For each manifest module, fetches `Code.fetch_docs/1` metadata tags, filters to `[:stable, :adapter]` tier tags, asserts `length == 1`. GREEN.
5. **@spec coverage (D-04):** For each stable-tier module, cross-references manifest `"functions"` list against `Code.Typespec.fetch_specs/1` specced set. Collects `"Elixir.Mod.fn/arity"` strings for unspecced functions. **Intentionally RED**: `Elixir.Rendro.Component.image/2` and `Elixir.Rendro.Component.render_component/2` are unspecced. Plan 02 backfills them.

## Verification Results

```
6 tests, 1 failure

  1) test stable-tier @spec coverage (D-04) every stable-tier manifested function has a @spec
     Stable-tier functions missing @spec:
       Elixir.Rendro.Component.image/2
       Elixir.Rendro.Component.render_component/2
```

Assertions 1-4 all PASS. Assertion 5 FAILS with the exact expected message naming `Rendro.Component`'s 2 unspecced functions. `mix compile --warnings-as-errors` exits 0. All content checks pass (`async: false`, `Code.Typespec.fetch_specs`, `mix rendro.api.gen`, `encode_manifest <> "\n"`, `String.to_existing_atom`).

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. The intentionally-RED assertion 5 is not a stub — it is a TDD RED state by design. Plan 02 resolves it by adding `@spec` annotations to `lib/rendro/component.ex`.

## Threat Flags

None. This plan is pure test-writing with no new runtime attack surface.

## Self-Check: PASSED

- [x] `test/docs_contract/public_api_contract_test.exs` exists
- [x] Commit `618eb90` exists in git log
- [x] File contains `async: false`
- [x] File contains `Code.Typespec.fetch_specs`
- [x] File contains `mix rendro.api.gen`
- [x] File contains `encode_manifest` with `<> "\n"`
- [x] File contains `String.to_existing_atom`
- [x] Assertions 1-4 GREEN, assertion 5 RED with correct message
- [x] `mix compile --warnings-as-errors` exits 0

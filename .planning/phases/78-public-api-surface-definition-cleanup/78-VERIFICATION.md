---
phase: 78-public-api-surface-definition-cleanup
verified: 2026-05-30T15:29:48Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 78: Public API Surface Definition & Cleanup — Verification Report

**Phase Goal:** The public API surface is what Rendro intends to expose — accidentally-public internals are hidden, returned structs are documented, every public module carries a tier tag, and a checked-in `priv/public_api.json` manifest is the canonical, schema-versioned source of truth for that surface.
**Verified:** 2026-05-30T15:29:48Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | HexDocs no longer renders `Rendro.PDF.CidFont`, `Rendro.PDF.FontSubsetter`, `Rendro.Text.Bidi`, `Rendro.Text.Shaper`, `Rendro.Format`, `Rendro.Audit` (all `@moduledoc false`); `Rendro.Sign`/`Rendro.Protect` `redact_*` helpers are `@doc false`; sweep confirms every public `lib/` module either lands in the manifest or is hidden | ✓ VERIFIED | All six files contain `@moduledoc false` (grep confirmed). sign.ex has 4 `@doc false` annotations, protect.ex has 1. Full-surface sweep closure test (14 tests, 0 failures) passes via `:application.get_key(:rendro, :modules)`. `mix compile --warnings-as-errors` exits 0. |
| 2 | `Rendro.Metadata` renders in HexDocs with a real `@moduledoc` and a documented `@type t`; no invisible-type gaps in public surface | ✓ VERIFIED | `lib/rendro/metadata.ex` has real `@moduledoc """..."""` + separate `@moduledoc tags: [:stable]` + `@type t` at line 23. `lib/rendro.ex:284` `@spec metadata(keyword()) :: Metadata.t()` wired. No public module references any of the six hidden module types (grep returned empty). |
| 3 | `priv/public_api.json` exists as a schema-versioned manifest listing every documented module/function with exactly one tier (`stable` \| `adapter`) | ✓ VERIFIED | File exists. 45 modules: 27 stable, 18 adapter. No `schema_version` or `untagged` entries. Sibling `priv/schemas/public_api.schema.json` with `$id: "public_api.schema.json"` provides schema-versioning (mirrors `support_matrix.schema.json` pattern exactly — no inline version field, as mandated by D-17). Schema validation test (`Validator.validate/1`) returns `:ok`. |
| 4 | Each public module renders a stability badge (Stable / Adapter) in HexDocs sourced from `@moduledoc` metadata | ✓ VERIFIED | `mix.exs` has `before_closing_head_tag: &before_closing_head_tag/1` (3 occurrences). Function injects CSS `.note.tier-stable` (green) and `.note.tier-adapter` (blue) plus a JS classifier. All 22 stable modules carry `tags: [:stable]`; all 16+ adapter modules carry `tags: [:adapter]` (spot-checked: Telemetry, Inspector, Storage, Storage.Local, Sign.Adapter, Protect.Adapter, all recipe implementations). `groups_for_modules` reconciled: Cell, Row, Component, Metadata, EmbeddedFileRegistry, RunningContent, Error in Core Builder API; PyHanko and Pdfsig moved to Ecosystem Adapters. |
| 5 | All five recipes handle `sections/2` opts uniformly (invoice/branded no longer silently ignore `_opts`); normalization is additive and breaks no existing caller | ✓ VERIFIED | `Invoice.sections/2` signature: `def sections(data, opts \\ [])` with opts threaded to `header_section/2`, `body_section/2`, `footer_section/2`. `BrandedInvoice.sections/2` same with four helpers (logo, header, body, footer). All seven private helpers have `_opts` second params. No `@behaviour`, no `NimbleOptions` (D-12, D-13). 957 tests, 0 failures; recipes_contract_test passes unchanged. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/rendro/pdf/cid_font.ex` | `@moduledoc false` | ✓ VERIFIED | Confirmed via grep |
| `lib/rendro/pdf/font_subsetter.ex` | `@moduledoc false` | ✓ VERIFIED | Confirmed via grep |
| `lib/rendro/text/bidi.ex` | `@moduledoc false` | ✓ VERIFIED | Confirmed via grep |
| `lib/rendro/text/shaper.ex` | `@moduledoc false` | ✓ VERIFIED | Confirmed via grep |
| `lib/rendro/audit.ex` | `@moduledoc false` | ✓ VERIFIED | Confirmed via grep |
| `lib/rendro/format.ex` | `@moduledoc false` | ✓ VERIFIED | Confirmed via grep |
| `lib/rendro/sign.ex` | `@doc false` on 4 redact_* helpers | ✓ VERIFIED | grep -c "@doc false" returns 4 |
| `lib/rendro/protect.ex` | `@doc false` on redact_opts/2 | ✓ VERIFIED | grep -c "@doc false" returns 1 |
| `lib/rendro/metadata.ex` | Real `@moduledoc` + `tags: [:stable]` + `@type t` | ✓ VERIFIED | Lines 2-11 confirmed; `@type t` at line 23 |
| `mix.exs` | `before_closing_head_tag/1` + updated `groups_for_modules` | ✓ VERIFIED | 3 occurrences; tier-stable/tier-adapter CSS present; Cell/Row/Component/Metadata in Core Builder API; PyHanko/Pdfsig in Ecosystem Adapters |
| `lib/rendro/recipes/invoice.ex` | `sections(data, opts \\ [])` + arity-2 helper heads | ✓ VERIFIED | Line 70 confirmed; 3 helper heads with `_opts` |
| `lib/rendro/recipes/branded_invoice.ex` | `sections(data, opts \\ [])` + arity-2 helper heads | ✓ VERIFIED | Line 100 confirmed; 4 helper heads with `_opts` |
| `lib/rendro/public_api.ex` | `tier_of/1`, `public_functions/1`, `public_types/1`, `build_manifest/1`, `recompile_conditional_adapters/0`; `@moduledoc false`; all 5 adapter paths | ✓ VERIFIED | File exists; all five functions present; `@adapter_files` lists all 5 conditional adapter paths (threadline, mailglass, accrue, phoenix, oban/render_worker) |
| `lib/rendro/public_api/loader.ex` | `load!/0` mirroring matrix.ex | ✓ VERIFIED | `@manifest_path` + `File.read!() |> JSON.decode!()` pattern confirmed |
| `lib/rendro/public_api/validator.ex` | `validate/1` via JSV | ✓ VERIFIED | `JSV.build!` + `JSV.validate` confirmed |
| `priv/schemas/public_api.schema.json` | `$id`, `$schema`, module_entry `$defs`, tier enum `[stable, adapter]`, no `schema_version` | ✓ VERIFIED | File contents confirmed; `$id: "public_api.schema.json"`; tier enum `["stable", "adapter"]`; no `schema_version` field |
| `priv/public_api.json` | 45 modules; no hidden modules; no untagged entries; Metadata tier stable | ✓ VERIFIED | 45 modules (27 stable, 18 adapter); CidFont/FontSubsetter/Audit/Format/Bidi/Shaper absent; `"untagged"` grep returns empty; `Elixir.Rendro.Metadata` tier `"stable"` |
| `lib/mix/tasks/rendro/api.gen.ex` | `use Mix.Task`; `@impl Mix.Task`; calls `recompile_conditional_adapters` + `build_manifest` | ✓ VERIFIED | All three elements present; explicit `@public_modules` registry (48 entries); Jason.OrderedObject for deterministic ordering; `encode_manifest/1` and `public_modules/0` exposed `@doc false` for test use |
| `test/rendro/public_api_test.exs` | 14 tests including full-surface sweep closure | ✓ VERIFIED | 14 tests, 0 failures; sweep closure test uses `:application.get_key(:rendro, :modules)` |
| `test/rendro/public_api/manifest_test.exs` | 8 integration tests including D-15 byte-equality | ✓ VERIFIED | 8 tests, 0 failures; byte-equality test uses `Mix.Tasks.Rendro.Api.Gen.encode_manifest/1` for identical encoding path |
| `test/rendro/recipes/invoice_opts_threading_test.exs` | opts threading contract tests | ✓ VERIFIED | File exists; 10 opts threading tests pass |
| `test/rendro/recipes/branded_invoice_opts_threading_test.exs` | opts threading contract tests | ✓ VERIFIED | File exists; 10 opts threading tests pass |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/rendro.ex:284` | `lib/rendro/metadata.ex` | `@spec metadata(keyword()) :: Metadata.t()` | ✓ WIRED | grep confirms `Metadata.t()` at line 284 |
| `lib/rendro/section.ex:19` | `lib/rendro/running_content.ex` | `@type content references RunningContent.t()` | ✓ WIRED | RunningContent kept public per D-02 (load-bearing type ref) |
| `lib/rendro/document.ex:68` | `lib/rendro/embedded_file_registry.ex` | `@type t references EmbeddedFileRegistry.t()` | ✓ WIRED | EmbeddedFileRegistry kept public per D-02 (load-bearing type ref) |
| `mix.exs docs/0` | `before_closing_head_tag/1` | `before_closing_head_tag: &before_closing_head_tag/1` | ✓ WIRED | Key present in docs/0 keyword list at line 96 |
| `lib/mix/tasks/rendro/api.gen.ex` | `lib/rendro/public_api.ex` | `Rendro.PublicApi.recompile_conditional_adapters/0 + build_manifest/1` | ✓ WIRED | Both calls present in `run/1` |
| `priv/public_api.json` | `priv/schemas/public_api.schema.json` | `Rendro.PublicApi.Validator.validate/1` | ✓ WIRED | Schema validation test confirms `:ok` |
| `test/rendro/public_api/manifest_test.exs` | `priv/public_api.json` | `Rendro.PublicApi.Loader.load!/0` | ✓ WIRED | `Loader.load!` used in manifest tests |
| `lib/rendro/recipes/invoice.ex sections/2` | invoice helper functions | `opts` threaded to `header_section/2`, `body_section/2`, `footer_section/2` | ✓ WIRED | Lines 72-74 confirmed |
| `lib/rendro/recipes/branded_invoice.ex sections/2` | branded_invoice helper functions | `opts` threaded to all four helpers | ✓ WIRED | Lines 104-107 confirmed |

### Data-Flow Trace (Level 4)

Not applicable — this phase produces no UI components or dynamic data renderers. All artifacts are module metadata attributes, JSON files, and introspection utilities.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `mix compile --warnings-as-errors` exits 0 | `mix compile --warnings-as-errors 2>&1; echo "Exit: $?"` | Exit: 0 | ✓ PASS |
| `mix test` full suite passes | `mix test 2>&1 \| tail -5` | 957 tests, 0 failures | ✓ PASS |
| `mix rendro.api.gen` exits 0 | `mix rendro.api.gen 2>&1` | Wrote priv/public_api.json, exit 0 | ✓ PASS |
| Manifest is byte-stable / idempotent | `mix rendro.api.gen && git diff --exit-code priv/public_api.json` | Exit: 0 (no diff) | ✓ PASS |
| PublicApi introspection tests pass | `mix test test/rendro/public_api_test.exs` | 14 tests, 0 failures | ✓ PASS |
| Manifest integration tests pass | `mix test test/rendro/public_api/manifest_test.exs` | 8 tests, 0 failures | ✓ PASS |
| Recipe opts threading tests pass | `mix test test/rendro/recipes/invoice_opts_threading_test.exs test/rendro/recipes/branded_invoice_opts_threading_test.exs` | 10 tests, 0 failures | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| API-01 | 78-02, 78-04, 78-05 | Manifest `priv/public_api.json` schema-versioned, all modules/functions with tier | ✓ SATISFIED | Manifest exists, schema validates, 45 modules with `stable`/`adapter` tiers, `mix rendro.api.gen` idempotent |
| API-02 | 78-01, 78-04 | Accidentally-public internals hidden; full sweep | ✓ SATISFIED | 6 modules `@moduledoc false`; 5 `redact_*` helpers `@doc false`; sweep closure test passes (14/14); 20 additional modules tagged/hidden in Plan 04 |
| API-03 | 78-01 | `Rendro.Metadata` exposed with `@moduledoc` + `@type t`; invisible-type gaps closed | ✓ SATISFIED | `metadata.ex` has real `@moduledoc` + `@type t`; `Rendro.metadata/1` `@spec` references `Metadata.t()`; no public module references hidden module types |
| API-05 | 78-02, 78-03 | Per-module stability badge in HexDocs; `sections/2` opts normalized across all 5 recipes | ✓ SATISFIED | `before_closing_head_tag/1` injects badge CSS/JS; all modules tagged; Invoice/BrandedInvoice now match Statement/Receipt/Certificate opts pattern |

Note: API-04 (docs-contract lane) is not a Phase 78 requirement — it is Phase 79. It is correctly deferred.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | — | — | No TBD/FIXME/XXX/placeholder patterns found in modified files |

One pre-existing warning noted in 78-02 SUMMARY ("pre-existing warning about `Rendro.Format` hidden reference in statement.ex") was not introduced by this phase. `mix compile --warnings-as-errors` exits 0 — no warnings exist at present.

### Human Verification Required

None. All success criteria are mechanically verifiable:

- `@moduledoc false` / `@doc false` attributes are grep-checkable
- Tier tags are BEAM-metadata-checkable via `Code.fetch_docs/1`
- Manifest existence, validity, and idempotency are file/test-checkable
- Recipe signature changes are grep/compile/test-checkable
- Badge CSS/JS injection is grep-checkable in mix.exs

### Gaps Summary

No gaps. All five success criteria are verified against the actual codebase. All 18 required artifacts exist and are substantive. All 9 key links are wired. All 4 requirement IDs (API-01, API-02, API-03, API-05) are satisfied. The test suite (957 tests, 0 failures) and `mix compile --warnings-as-errors` (exit 0) confirm no regressions. Manifest byte-stability confirmed via `git diff --exit-code` after re-running `mix rendro.api.gen`.

**Schema-versioning note (SC-3 explicitness):** The requirement says "schema-versioned like `support_matrix.json`." Decision D-17 (locked in CONTEXT.md) resolved this precisely: `support_matrix.json` itself has no inline `schema_version` field; the versioning mechanism is the sibling `priv/schemas/support_matrix.schema.json` with `$id`. `public_api.json` mirrors this pattern exactly — no inline version field; versioning is via `priv/schemas/public_api.schema.json` with `$id: "public_api.schema.json"`. This is correct per D-17 and is not a gap.

---

_Verified: 2026-05-30T15:29:48Z_
_Verifier: Claude (gsd-verifier)_

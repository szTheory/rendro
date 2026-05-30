# Phase 79: Public API Contract Enforcement Lane - Research

**Researched:** 2026-05-30
**Domain:** Elixir ExUnit docs-contract testing, `Code.fetch_docs/1` introspection, `@spec` coverage enforcement
**Confidence:** HIGH — all findings verified against live source files

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Reuse `Rendro.PublicApi.build_manifest/1` for in-memory regeneration — no parallel filter implementation in the contract test.
- **D-02:** Conditional-adapter footgun is handled by the shared codepath. Test runs in the normal `mix test` env (where optional deps are loaded). BEAM-availability filter is the generator's exact filter — `Code.ensure_loaded?(mod) and match?({:docs_v1, _, _, _, _, _, _}, Code.fetch_docs(mod))`.
- **D-03:** Drift surfacing = two human-readable lists ("in code but not manifested" / "manifested but not in code"), not one opaque `assert ==`. Failure message must say `mix rendro.api.gen` for intentional changes.
- **D-04:** **STRICT 100% @spec** coverage for every stable-tier public function. Failure emits the unspecced list. Scope-expanding: backfilling @specs into the stable surface is explicit in-phase work.
- **D-05:** Assert known internals are `:hidden` from `Code.fetch_docs/1` — `Rendro.PDF.CidFont`, `Rendro.PDF.FontSubsetter`, `Rendro.Text.Bidi`, `Rendro.Text.Shaper`, `Rendro.Format`, `Rendro.Audit` (modules), and `Rendro.Sign.redact_opts/1`, `redact_prepare_opts/1`, `redact_sign_opts/1`, `redact_augment_opts/1`, `Rendro.Protect.redact_opts/2` (functions). Assert against an explicit hardcoded list so re-exposure fails even if the manifest also changes.
- **D-06:** Assert every public (manifested) module carries **exactly one** tier tag (`:stable` xor `:adapter`) in `Code.fetch_docs/1` metadata — zero tags or two tags fails.
- **D-07:** Wire into `priv/guardrails/required_status_checks.json` by **bumping the `test` context's `notes`** — do NOT add a new required context. Update the guardrail contract test (`test/guardrails/required_checks_contract_test.exs`) and `scripts/verify_docs.exs` in lockstep.

### Claude's Discretion

- Exact test module name/structure (mirror `test/docs_contract/*_contract_test.exs`, `async: false`).
- Precise wording of the drift-diff failure message.
- Whether the `@spec`-coverage assertion lives in the same file or a sibling `public_api_spec_coverage_test.exs`.
- Order of spec-backfill vs. test authoring (canonical path: write test RED, backfill specs GREEN).

### Deferred Ideas (OUT OF SCOPE)

- Scrub internal milestone/phase labels from `guides/api_stability.md` — Phase 80 / STAB-04.
- Nothing else deferred from discussion.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| API-04 | A docs-contract lane (`test/docs_contract/public_api_contract_test.exs`) introspects `Code.fetch_docs/1` and asserts the documented surface exactly equals the manifest (drift fails CI with an errors-as-product diff), asserts known internals are `:hidden`, asserts Tier-1 `@spec` coverage, and asserts every public module carries exactly one tier tag — wired into `priv/guardrails/required_status_checks.json`. | All 4 sub-assertions are directly implementable via the `Rendro.PublicApi` introspection codepath + `Code.fetch_docs/1`. Spec backfill scope enumerated in §4 below. Guardrails wiring mechanics fully documented in §5. |
</phase_requirements>

---

## Summary

Phase 79 is a test-writing and spec-backfill phase. It has two concrete deliverables: (1) a new `test/docs_contract/public_api_contract_test.exs` that uses the already-built `Rendro.PublicApi` + `Mix.Tasks.Rendro.Api.Gen` introspection codepath to enforce four contract assertions (manifest equality, hidden-internals, tier-tag, @spec coverage), and (2) a `@spec` backfill across the stable-tier surface until the `@spec` coverage assertion goes green. The manifest is already generated (`priv/public_api.json`; 45 modules, 27 stable + 18 adapter), the introspection module is already built, and 13 existing docs-contract tests establish the canonical test structure to mirror.

The dominant effort is the `@spec` backfill. Audit of live source files shows that most stable-tier modules that are pure data structs (`Table`, `Block`, `Cell`, `Row`, `Region`, `Section`, `Image`, `Page`, `PageTemplate`, `RunningContent`, `Metadata`, `Link`, `FormField`) have zero public functions (only types) — those modules have zero spec-coverage gaps. The only stable modules with public functions lacking `@spec` are `Rendro.Component` (2 functions, 0 specs) and `Rendro.Protect` (1 hidden-from-manifest `redact_opts/2` has a spec, but the 3 public functions all have specs). All other stable modules with public functions (`Rendro`, `Rendro.Artifact`, `Rendro.AssetRegistry`, `Rendro.Document`, `Rendro.EmbeddedFileRegistry`, `Rendro.Error`, `Rendro.FontRegistry`, `Rendro.Protect`, `Rendro.Recipes`, `Rendro.Sign`, `Rendro.Text`) are already fully specced.

**Primary recommendation:** Write the contract test first (makes spec gaps visible with a failing test), then add the 2 missing `@spec` annotations to `Rendro.Component` to go green. The backfill is smaller than the CONTEXT.md pre-research estimate suggested — `table.ex`, `section.ex`, `region.ex`, `block.ex`, `image.ex`, `cell.ex`, `row.ex`, `page.ex`, `page_template.ex` are all zero-public-function structs and need zero specs.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Manifest equality assertion | Test (ExUnit) | `Rendro.PublicApi` + `Mix.Tasks.Rendro.Api.Gen` | Reuse Phase 78 introspection; no new code in the API/library tier |
| Hidden-internals assertion | Test (ExUnit) | `Code.fetch_docs/1` BEAM metadata | Pure test-layer introspection; no library changes needed |
| Tier-tag assertion | Test (ExUnit) | `Rendro.PublicApi.tier_of/1` | Delegates to existing introspection; no new library layer |
| @spec coverage assertion | Test (ExUnit) + `@spec` annotations | Stable-tier source modules | Test reads `Code.fetch_docs/1` typespec entries; library modules need backfilled specs |
| Guardrails wiring | Config (`priv/guardrails/`) + `scripts/verify_docs.exs` | `test/guardrails/required_checks_contract_test.exs` | Notes-bump only; no new CI job |

---

## 1. The Reusable Introspection Codepath (D-01/D-02)

All findings [VERIFIED: live source inspection]

### `Rendro.PublicApi` (`lib/rendro/public_api.ex`)

```elixir
@moduledoc false  # internal — do NOT call from application code

@spec tier_of(module()) :: :stable | :adapter | :untagged
def tier_of(module)
# Reads Code.fetch_docs/1 elem(5) metadata map for `tags:` key.
# Pattern: {:docs_v1, _, _, _, _, %{tags: tags}, _}
# Returns :stable if :stable in tags, :adapter if :adapter in tags, else :untagged
# Returns :untagged for modules where Code.fetch_docs/1 fails (no BEAM, @moduledoc false)

@spec public_functions(module()) :: [String.t()]
def public_functions(module)
# Returns sorted ["name/arity"] strings for all functions where doc != :hidden
# IMPORTANT: includes doc: :none (undocumented-but-public) functions — this is intentional
# The doc-entry tuple shape: {{:function, name, arity}, _anno, _sig, doc, _meta}

@spec public_types(module()) :: [String.t()]
def public_types(module)
# Returns sorted ["name/arity"] strings for all types where doc != :hidden
# The doc-entry tuple shape: {{:type, name, arity}, _anno, _sig, doc, _meta}

@spec build_manifest([module()]) :: map()
def build_manifest(modules)
# Returns %{"modules" => %{"Elixir.ModName" => %{"tier" => "stable"|"adapter",
#                                                   "functions" => [...sorted...],
#                                                   "types" => [...sorted...]}}}
# Keys: Atom.to_string(mod) — yields "Elixir.Rendro", NOT "Rendro" (inspect/1 gives short form)
# Entries sorted alphabetically by module key

@spec recompile_conditional_adapters() :: :ok
def recompile_conditional_adapters()
# Calls Code.compile_file/1 on the 5 conditional adapter files:
#   "lib/rendro/adapters/threadline.ex"
#   "lib/rendro/adapters/mailglass.ex"
#   "lib/rendro/adapters/accrue.ex"
#   "lib/rendro/adapters/phoenix.ex"
#   "lib/rendro/adapters/oban/render_worker.ex"
# IMPORTANT: Code.compile_file produces in-memory modules only — no BEAM on disk
# Code.fetch_docs/1 REQUIRES a BEAM file on disk — in-memory-only modules yield :untagged
# Consequence: conditional adapters without real optional deps compiled ARE excluded from
# the manifest via the BEAM-availability filter (this is correct behavior, not a bug)
```

### `Mix.Tasks.Rendro.Api.Gen` (`lib/mix/tasks/rendro/api.gen.ex`)

```elixir
# Two @doc false public functions exposed specifically for test use:

@doc false
def public_modules()
# Returns the @public_modules list (48 modules including 3 conditional)
# This is the authoritative registry the contract test must use — NOT a re-derived list

@doc false
def encode_manifest(manifest)
# Deterministic JSON encoding for byte-equality comparison.
# Uses Jason.OrderedObject to guarantee alphabetical key order (plain Elixir maps
# have non-deterministic iteration for >8 entries; Jason does not sort by default).
# Entry field order within each module: {"functions", "tier", "types"} (alphabetical)
# Encoding: Jason.encode!(ordered, pretty: true)  -- 2-space indent
# File write appends "\n" after encode_manifest result: json <> "\n"
# The contract test must encode identically: Mix.Tasks.Rendro.Api.Gen.encode_manifest(manifest) <> "\n"
```

### BEAM-Availability Filter (the exact footgun prevention)

```elixir
# Used in BOTH mix rendro.api.gen AND the existing byte-equality test in manifest_test.exs:
loaded_modules =
  Mix.Tasks.Rendro.Api.Gen.public_modules()
  |> Enum.filter(fn mod ->
    Code.ensure_loaded?(mod) and match?({:docs_v1, _, _, _, _, _, _}, Code.fetch_docs(mod))
  end)
```

The contract test in Phase 79 must use this exact filter — not `Code.ensure_loaded?` alone.

### `Rendro.PublicApi.Loader` and `Rendro.PublicApi.Validator`

```elixir
# Loader — reads the on-disk manifest
@spec load!() :: map()
def load!()
# Uses: "priv/public_api.json" |> File.read!() |> JSON.decode!()
# Returns decoded map (NOT a Jason.OrderedObject — regular Elixir map)

# Validator — validates against schema
@spec validate(map()) :: :ok | {:error, String.t()}
def validate(manifest)
# Schema path: "priv/schemas/public_api.schema.json"
# Uses: schema |> File.read!() |> JSON.decode!() |> JSV.build!()
# Then: JSV.validate(manifest, schema) — {:ok, _} or {:error, jsv_error}
```

---

## 2. The Manifest Structure (D-16)

[VERIFIED: live `priv/public_api.json` + `priv/schemas/public_api.schema.json` inspection]

### Top-Level Shape

```json
{
  "modules": {
    "Elixir.ModuleName": {
      "functions": ["name/arity", "name/arity"],
      "tier": "stable",
      "types": ["name/arity"]
    }
  }
}
```

- No `schema_version` top-level key (D-17 — schema-versioned via sibling schema, not inline).
- Module keys: `Atom.to_string(module)` → `"Elixir.Rendro"`, `"Elixir.Rendro.Document"`, etc.
- 45 modules total: 27 stable + 18 adapter.

### Per-Module Entry Fields

| Field | Type | Values | Notes |
|-------|------|--------|-------|
| `"tier"` | String | `"stable"` or `"adapter"` | Schema enforces enum — no `"untagged"` |
| `"functions"` | Array of String | `["name/arity", ...]` sorted | `doc != :hidden` filter; includes `:none`-documented |
| `"types"` | Array of String | `["name/arity", ...]` sorted | `doc != :hidden` filter |

### Schema (`priv/schemas/public_api.schema.json`)

- `$id: "public_api.schema.json"`, no inline version.
- `required: ["modules"]`, `additionalProperties: false` at top level.
- Each module entry: `required: ["tier", "functions", "types"]`, `additionalProperties: false`.
- `tier` is `enum: ["stable", "adapter"]` (string values, not atoms).
- `functions` and `types`: array of unique strings.

### Stable-Tier Modules in the Manifest

The 27 stable modules (from `priv/public_api.json`):

```
Rendro, Rendro.Artifact, Rendro.AssetRegistry, Rendro.AssetRegistry.InvalidAssetError,
Rendro.Block, Rendro.Cell, Rendro.Component, Rendro.Document, Rendro.EmbeddedFileRegistry,
Rendro.Error, Rendro.FontRegistry, Rendro.FontRegistry.EmbeddedFontFamilyError,
Rendro.FormField, Rendro.Image, Rendro.Link, Rendro.Metadata, Rendro.Page,
Rendro.PageTemplate, Rendro.Protect, Rendro.Recipes, Rendro.Region, Rendro.Row,
Rendro.RunningContent, Rendro.Section, Rendro.Sign, Rendro.Table, Rendro.Text
```

### Hidden Internals (NOT in the manifest)

Confirmed absent from `priv/public_api.json` and tagged `@moduledoc false`:
- `Rendro.PDF.CidFont`
- `Rendro.PDF.FontSubsetter`
- `Rendro.Text.Bidi`
- `Rendro.Text.Shaper`
- `Rendro.Format`
- `Rendro.Audit`

Confirmed `@doc false` functions in manifest modules:
- `Rendro.Sign`: `redact_opts/1`, `redact_prepare_opts/1`, `redact_sign_opts/1`, `redact_augment_opts/1`
- `Rendro.Protect`: `redact_opts/2`

---

## 3. Existing Docs-Contract Test Shape

[VERIFIED: live inspection of `test/docs_contract/` directory and multiple test files]

### Directory Contents (13 existing lanes)

```
test/docs_contract/
  branding_claims_test.exs
  branding_contract_test.exs
  embedded_artifact_claims_test.exs
  forms_claims_test.exs
  integrations_claims_test.exs
  integrations_contract_test.exs
  page_primitive_claims_test.exs
  protection_claims_test.exs
  readme_doctest_test.exs
  recipes_claims_test.exs
  recipes_contract_test.exs
  signing_claims_test.exs
  viewer_evidence_claims_test.exs
```

The new `public_api_contract_test.exs` will be the 14th lane.

### Canonical Test Structure

```elixir
defmodule Rendro.DocsContract.RecipesContractTest do
  use ExUnit.Case, async: false   # async: false is THE canonical setting for contract tests
  # (claims tests use async: true — contract tests are async: false)

  alias Rendro.Test.DocsContract   # helper module for fence-based tests; NOT needed for the public-api test
  # The public-api contract test does not use DocsContract fence helpers
  # It directly calls Rendro.PublicApi.* + Code.fetch_docs/1
end
```

**Key structural choices observed across the suite:**
- Claims tests (string assertions against files): `async: true`
- Contract tests (code evaluation, introspection): `async: false`
- New `public_api_contract_test.exs` must be `async: false` (introspection is stateful — recompile_conditional_adapters mutates in-memory module state)
- No `@moduledoc` in test files — ExUnit convention in this codebase
- `setup_all` used in `manifest_test.exs` to call `recompile_conditional_adapters/0` once

### Existing Analogous Test (manifest_test.exs uses the same codepath)

The existing `test/rendro/public_api/manifest_test.exs` already has the byte-equality pattern. The new contract test extends this into the docs-contract lane and adds the hidden-internals, tier-tag, and @spec-coverage assertions.

```elixir
# From manifest_test.exs — the pattern to extend/mirror:
setup_all do
  Rendro.PublicApi.recompile_conditional_adapters()
  :ok
end

# Byte-equality pattern (Test 5 in manifest_test.exs):
loaded_modules =
  Mix.Tasks.Rendro.Api.Gen.public_modules()
  |> Enum.filter(fn mod ->
    Code.ensure_loaded?(mod) and
      match?({:docs_v1, _, _, _, _, _, _}, Code.fetch_docs(mod))
  end)

fresh_manifest = Rendro.PublicApi.build_manifest(loaded_modules)
fresh_json = Mix.Tasks.Rendro.Api.Gen.encode_manifest(fresh_manifest) <> "\n"
checked_in = File.read!("priv/public_api.json")

assert fresh_json == checked_in,
       """
       The freshly-generated manifest does not byte-match priv/public_api.json.
       This means the manifest is out of date. Run: mix rendro.api.gen
       and commit the result.
       """
```

---

## 4. @Spec Coverage Audit — Per-Module Breakdown (D-04)

[VERIFIED: live source file inspection of all 27 stable-tier modules]

### Critical Insight

Most stable-tier modules are **pure data structs with zero public functions**. The manifest shows empty `"functions": []` for them. The @spec coverage assertion `"every function in a stable module's functions list has a @spec"` trivially passes for these — there's nothing to spec.

### Modules With Zero Public Functions (functions list empty in manifest)

These modules need **zero @spec backfill** — the coverage assertion passes automatically:

| Module | Status |
|--------|--------|
| `Rendro.AssetRegistry.InvalidAssetError` | 0 public fns — only exception struct |
| `Rendro.Block` | 0 public fns — struct only |
| `Rendro.Cell` | 0 public fns — struct only |
| `Rendro.FormField` | 0 public fns — struct only |
| `Rendro.FontRegistry.EmbeddedFontFamilyError` | 0 public fns — exception struct |
| `Rendro.Image` | 0 public fns — struct only |
| `Rendro.Link` | 0 public fns — struct only |
| `Rendro.Metadata` | 0 public fns — struct only |
| `Rendro.Page` | 0 public fns — struct only |
| `Rendro.PageTemplate` | 0 public fns — struct only |
| `Rendro.Region` | 0 public fns — struct only |
| `Rendro.Row` | 0 public fns — struct only |
| `Rendro.RunningContent` | 0 public fns — struct only |
| `Rendro.Section` | 0 public fns — struct only |
| `Rendro.Table` | 0 public fns — struct only |
| `Rendro.Protect.Adapter` | 0 public fns — adapter (not stable anyway) |
| `Rendro.Sign.Adapter` | 0 public fns — adapter (not stable anyway) |

### Stable Modules With Public Functions — Spec Status

[VERIFIED: counted `@spec` annotations vs. manifest `functions` lists via source inspection]

| Module | Manifest Functions | Has @spec | Missing @spec | Notes |
|--------|-------------------|-----------|---------------|-------|
| `Rendro` | 26 | 26 | **0** | All public fns fully specced |
| `Rendro.Artifact` | 2 (`new/3`, `wrap/3`) | 2 | **0** | Both specced |
| `Rendro.AssetRegistry` | 3 (`fetch/2`, `new/0`, `register_image/3`) | 3 | **0** | All specced |
| `Rendro.Component` | 2 (`image/2`, `render_component/2`) | **0** | **2** | NO @spec on either public fn |
| `Rendro.Document` | 13 | 13 | **0** | Fully specced |
| `Rendro.EmbeddedFileRegistry` | 3 (`fetch/2`, `new/0`, `register/4`) | 3 | **0** | Fully specced |
| `Rendro.Error` | 1 (`from_stage/3`) | 1 | **0** | Specced |
| `Rendro.FontRegistry` | 15 | 15 | **0** | Fully specced |
| `Rendro.Protect` | 3 (`password/2`, `render_protected/3`, `supported_permissions/0`) | 3 | **0** | All 3 public fns specced; `redact_opts/2` is `@doc false` and also specced |
| `Rendro.Recipes` | 2 (`branded_invoice/1`, `invoice/1`) | 2 | **0** | Both specced |
| `Rendro.Sign` | 6 (`augment/2`, `prepare/2`, `render_signed/3`, `sign/2`, `validate/2`, `validate_trust/2`) | 6 | **0** | All specced; redact helpers are `@doc false` and also specced |
| `Rendro.Text` | 2 (`default_font/0`, `normalize_font/1`) | 2 | **0** | Both specced |

### @Spec Backfill Required: Only `Rendro.Component`

**`lib/rendro/component.ex` — 2 public functions, 0 specs:**

```elixir
# Current (no @spec):
def render_component(module, assigns \\ []) do
  module.render(assigns)
end

def image(logical_name, opts \\ []) do
  # ... raises if no constraint, returns %Rendro.Block{}
end
```

**Specs to add:**

```elixir
@spec render_component(module(), keyword()) :: term()
def render_component(module, assigns \\ []) do

@spec image(atom(), keyword()) :: Rendro.Block.t()
def image(logical_name, opts \\ []) do
```

Note: `render_component/2` return type is `term()` because it delegates to `module.render(assigns)` — the actual return type is whatever the component module returns (typically a list of blocks, but not type-constrained here).

### Summary

| Backfill scope | Count |
|----------------|-------|
| Modules needing ANY @spec | **1** (`Rendro.Component`) |
| Total @spec annotations to add | **2** |
| Modules already fully specced | **12** (all other stable modules with public functions) |
| Modules with no public functions (trivially pass) | **15** |

**The pre-research estimate that `table.ex`, `section.ex`, `region.ex`, `block.ex`, `image.ex`, `cell.ex`, `row.ex` all needed specs was incorrect** — they have zero public functions (pure structs), so they have zero spec coverage gaps. The actual backfill is much smaller than anticipated.

---

## 5. Guardrails Wiring (D-07)

[VERIFIED: live inspection of `priv/guardrails/required_status_checks.json` and `test/guardrails/required_checks_contract_test.exs`]

### Current State of `priv/guardrails/required_status_checks.json`

```json
{
  "schema_version": 1,
  "required_contexts": ["long-lived-live-proof", "release-proof", "signing-live-proof", "test"],
  "contexts": [
    {
      "name": "test",
      "semantic_class": "deterministic",
      "ci_job": "test",
      "command": "mix ci",
      "notes": "Includes mix test (8 docs-contract lanes), format, hex.build, compile --warnings-as-errors, docs, credo, dialyzer. Viewer-evidence schema/lint folded here per Phase 68 D-18 — not a separate required context."
    }
  ]
}
```

**Current lane count in notes:** "8 docs-contract lanes" — this is **stale**. `scripts/verify_docs.exs` has 10 lanes; the guardrails contract test asserts 10 lanes. The notes are already out of date by 2 (recipes + page-primitive were added later). After Phase 79, the count becomes 11 (adding the public-api contract lane).

**Notes string to write for Phase 79:**
```
"Includes mix test (11 docs-contract lanes), format, hex.build, compile --warnings-as-errors, docs, credo, dialyzer. Viewer-evidence schema/lint folded here per Phase 68 D-18 — not a separate required context. Public-api contract lane added Phase 79 D-07."
```

### Guardrail Contract Test (`test/guardrails/required_checks_contract_test.exs`)

This is the lockstep test. It has a `describe "docs-contract lane count"` block:

```elixir
describe "docs-contract lane count" do
  test "verify_docs.exs registers exactly ten lanes including the recipes and page-primitive lanes" do
    script = File.read!(@verify_docs_path)
    lane_entries = Regex.scan(~r/\{"[^"]+", \["test", "test\/docs_contract\/[^"]+"\]\}/, script)
    assert length(lane_entries) == 10   # <-- must become 11
    # ...
  end
end
```

**This test must be updated in lockstep** when the new lane is added to `scripts/verify_docs.exs`. The test description text and the `== 10` assertion both need updating to `== 11`.

It also asserts specific content in the `test` context notes:
```elixir
test_context = Enum.find(baseline["contexts"], &(&1["name"] == "test"))
assert test_context["notes"] =~ "Phase 68 D-18"
assert test_context["notes"] =~ "Viewer-evidence"
```
These assertions still pass after the Phase 79 notes bump (the new notes string retains both substrings).

### `scripts/verify_docs.exs`

The new lane entry to add:
```elixir
{"Public API contract lane", ["test", "test/docs_contract/public_api_contract_test.exs"]},
```

Current lanes (10 total):
1. README doctest lane
2. Integration contract lane
3. Integration semantic-claims lane
4. Forms semantic-claims lane
5. Signing semantic-claims lane
6. Embedded artifact semantic-claims lane
7. Protection semantic-claims lane
8. Viewer evidence semantic-claims lane
9. Recipes semantic-claims lane
10. Page-primitive semantic-claims lane

After Phase 79: 11 lanes.

---

## 6. Hidden-Internals and Tier-Tag Assertion Mechanics (D-05/D-06)

[VERIFIED: live `Code.fetch_docs/1` return structure from source + test inspection]

### `Code.fetch_docs/1` Return Tuple

```elixir
# Full return for a documented module:
{:docs_v1, annotation, beam_lang, format, module_doc, metadata, docs}
#     [0]      [1]         [2]       [3]      [4]          [5]    [6]

# Where:
# elem(4) = module_doc: :hidden | :none | %{"en" => "..."} — the @moduledoc content
# elem(5) = metadata: map() — includes the tags: key set by @moduledoc tags: [...]
# elem(6) = docs: list of per-function/type doc entries
```

### Checking if a Module is Hidden

```elixir
case Code.fetch_docs(module) do
  {:docs_v1, _, _, _, :hidden, _, _} -> true   # @moduledoc false
  {:docs_v1, _, _, _, _module_doc, _, _} -> false
  {:error, _} -> true   # no BEAM file — treat as hidden for safety
end
```

### Reading Tier from Metadata (D-06)

```elixir
# From Rendro.PublicApi.tier_of/1 — exact pattern:
case Code.fetch_docs(module) do
  {:docs_v1, _, _, _, _, %{tags: tags}, _} ->
    cond do
      :stable in tags -> :stable
      :adapter in tags -> :adapter
      true -> :untagged  # zero tags OR unrecognized tags
    end
  _ -> :untagged
end

# For exactly-one-tag assertion (D-06):
tags_count = length(tags)
assert tags_count == 1, "Module #{inspect(module)} must carry exactly one tier tag, got: #{inspect(tags)}"
```

The `tags` value is a list of atoms: e.g. `[:stable]` or `[:adapter]`. Modules with `@moduledoc tags: [:stable]` set `metadata = %{tags: [:stable]}`. Zero tags means metadata has no `:tags` key or `tags: []`.

### Checking `@doc false` Functions

```elixir
# Per-function doc entry shape:
{{:function, name, arity}, annotation, signature, doc, function_metadata}

# doc can be:
# :hidden  — @doc false
# :none    — no @doc at all (but public)
# %{"en" => "..."} — has @doc
# nil      — (rare)

# For hidden-internals check:
{:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(Rendro.Sign)

matching_entries = Enum.filter(docs, fn
  {{:function, ^name, _arity}, _, _, _, _} -> true
  _ -> false
end)

for {{:function, fn_name, arity}, _, _, doc, _} <- matching_entries do
  assert doc == :hidden, "Expected #{fn_name}/#{arity} to be @doc false"
end
```

This exact pattern is already used in `test/rendro/public_api/manifest_test.exs` Test 7 (redact helpers test). The contract test's hidden-function assertion should mirror it.

### Checking @spec Presence (D-04)

`Code.fetch_docs/1` does NOT return `@spec` information — specs are stored in the BEAM's `abstract_code` chunk, not the `Docs` chunk. The correct approach for asserting @spec coverage is to use `Code.Typespec`:

```elixir
# Check if a function has a @spec:
specs = Code.Typespec.fetch_specs(module)
# Returns {:ok, [{name_arity, [type_ast]}]} or :error

case Code.Typespec.fetch_specs(module) do
  {:ok, specs} ->
    specced_fns = Enum.map(specs, fn {{name, arity}, _} -> "#{name}/#{arity}" end)
    # specced_fns is a list of "name/arity" strings that have @spec
  :error ->
    []  # no specs at all
end
```

**Implementation pattern for the assertion:**

```elixir
# For each stable module, cross-reference manifest functions against specs:
manifest = Rendro.PublicApi.Loader.load!()

unspecced =
  manifest["modules"]
  |> Enum.filter(fn {_key, entry} -> entry["tier"] == "stable" end)
  |> Enum.flat_map(fn {mod_key, entry} ->
    module = String.to_existing_atom(mod_key)
    specced =
      case Code.Typespec.fetch_specs(module) do
        {:ok, specs} -> Enum.map(specs, fn {{name, arity}, _} -> "#{name}/#{arity}" end)
        :error -> []
      end
    entry["functions"]
    |> Enum.reject(fn fn_str -> fn_str in specced end)
    |> Enum.map(fn fn_str -> "#{mod_key}.#{fn_str}" end)
  end)

assert unspecced == [],
       "Stable-tier functions missing @spec:\n  " <> Enum.join(unspecced, "\n  ")
```

Note: `Code.Typespec` is an Elixir standard library module. [VERIFIED: Elixir standard library — `Code.Typespec.fetch_specs/1` has been available since Elixir 1.8]

**Alternative:** `Kernel.Typespec` was renamed to `Code.Typespec` in Elixir 1.8. The project runs Elixir >= 1.14 (confirmed by CI matrix), so `Code.Typespec.fetch_specs/1` is safe to use. [ASSUMED — exact Elixir version from mix.exs not inspected in this session, but Elixir 1.14+ is effectively guaranteed by the project's modern dependencies]

---

## 7. Running the Lane (mix ci, test env, adapter loading)

[VERIFIED: live `priv/guardrails/required_status_checks.json` + mix.exs alias inspection via existing test]

### `mix ci` Alias (from `required_checks_contract_test.exs`)

```elixir
ci_steps == [
  "format --check-formatted",
  "hex.build",
  "compile --warnings-as-errors",
  "test",
  "docs",
  "credo --strict",
  "dialyzer"
]
```

The contract test runs under `mix test` (inside `mix ci`). No special tags or exclusions apply to docs-contract tests — they run in the default test suite.

### Test Environment and Adapter Loading

The 5 conditional adapters are compiled by `Rendro.PublicApi.recompile_conditional_adapters/0` in `setup_all`. In the test environment, optional deps (Phoenix, Oban, etc.) that are declared in `mix.exs` are available — so the adapters whose deps ARE present will produce BEAM files on disk and pass the `Code.fetch_docs/1` check. Those without deps will be compiled in-memory only and correctly excluded by the BEAM-availability filter.

### @spec Backfill + Dialyzer

`mix ci` runs dialyzer. Adding `@spec` annotations is dialyzer-checked for free. The 2 specs to add to `Rendro.Component` will be dialyzer-verified. No dialyzer plt needs updating for this — specs on existing functions are additive.

---

## Architecture Patterns

### System Architecture Diagram

```
Test runner (mix test)
  └─ public_api_contract_test.exs (async: false)
       │
       ├─ setup_all: Rendro.PublicApi.recompile_conditional_adapters()
       │
       ├─ [Assertion 1: Manifest equality]
       │   Mix.Tasks.Rendro.Api.Gen.public_modules()
       │   → BEAM-availability filter
       │   → Rendro.PublicApi.build_manifest/1
       │   → Mix.Tasks.Rendro.Api.Gen.encode_manifest/1 <> "\n"
       │   ↕ byte-compare
       │   File.read!("priv/public_api.json")
       │   + Rendro.PublicApi.Validator.validate/1 (JSV schema check)
       │   Failure: two-list drift diff + "run mix rendro.api.gen"
       │
       ├─ [Assertion 2: Hidden internals]
       │   Code.fetch_docs(module) → module_doc == :hidden (for 6 modules)
       │   Code.fetch_docs(Rendro.Sign/Protect) → fn doc == :hidden (for 5 helpers)
       │
       ├─ [Assertion 3: Tier-tag exactly one]
       │   Rendro.PublicApi.tier_of/1 per manifested module
       │   (reads elem(5) metadata tags from Code.fetch_docs/1)
       │   Assert length(tags) == 1 for each module
       │
       └─ [Assertion 4: @spec coverage]
           Rendro.PublicApi.Loader.load!() → stable-tier modules + their functions
           Code.Typespec.fetch_specs/1 per module → specced function set
           Cross-ref: manifest functions vs. specced functions
           Failure: list of "Module.fn/arity" strings missing @spec
```

### Recommended Project Structure

No new directories needed. All new files in existing directories:

```
test/docs_contract/
  public_api_contract_test.exs    # NEW — the contract test

lib/rendro/
  component.ex                     # MODIFIED — add 2 @spec annotations

priv/guardrails/
  required_status_checks.json     # MODIFIED — bump test context notes

scripts/
  verify_docs.exs                  # MODIFIED — add public-api contract lane entry

test/guardrails/
  required_checks_contract_test.exs  # MODIFIED — bump lane count 10 → 11
```

### Pattern: Errors-as-Product Drift Diff (D-03/D-18)

```elixir
# Generate fresh manifest and compare to on-disk:
fresh_keys = Map.keys(fresh_manifest["modules"]) |> MapSet.new()
on_disk_keys = Map.keys(on_disk_manifest["modules"]) |> MapSet.new()

in_code_not_manifested = MapSet.difference(fresh_keys, on_disk_keys) |> Enum.sort()
manifested_not_in_code = MapSet.difference(on_disk_keys, fresh_keys) |> Enum.sort()

if in_code_not_manifested != [] or manifested_not_in_code != [] do
  flunk("""
  Public API surface has drifted from priv/public_api.json.

  In code but NOT in manifest (newly public — should they be?):
  #{Enum.map_join(in_code_not_manifested, "\n", fn m -> "  + #{m}" end)}

  In manifest but NOT in code (removed or hidden — intentional?):
  #{Enum.map_join(manifested_not_in_code, "\n", fn m -> "  - #{m}" end)}

  If this change is intentional, regenerate the manifest:
    mix rendro.api.gen
  Then commit the updated priv/public_api.json.
  """)
end
```

The byte-equality assertion also catches per-function drift within a module (a function added/removed within an already-manifested module). The two-list diff above catches module-level drift; the byte-equality catches all drift together.

**Recommended approach:** Run both — byte-equality first for the fast path (passes with no diff = green), then the two-list diff in the failure message for human-readable error UX (only reached when byte-equality fails).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| @spec presence check | Custom BEAM chunk reader | `Code.Typespec.fetch_specs/1` | Standard Elixir stdlib — returns specs from BEAM abstract_code chunk |
| Manifest byte-equality encoding | Custom JSON serializer | `Mix.Tasks.Rendro.Api.Gen.encode_manifest/1` | Already built; Jason.OrderedObject guarantees deterministic key order |
| BEAM availability filter | Re-derive module list | `Mix.Tasks.Rendro.Api.Gen.public_modules/0` | Authoritative registry; re-deriving risks divergence |
| Schema validation | Custom JSON schema validator | `Rendro.PublicApi.Validator.validate/1` (JSV) | Already built; proven against the schema |
| Tier reading | Parse @moduledoc source | `Rendro.PublicApi.tier_of/1` | Already built; handles all edge cases including no-BEAM |

---

## Common Pitfalls

### Pitfall 1: Using inspect/1 Instead of Atom.to_string/1 for Module Keys

**What goes wrong:** `inspect(Rendro)` returns `"Rendro"`, but the manifest uses `"Elixir.Rendro"` (the result of `Atom.to_string(Rendro)`). Any test that constructs module string keys using `inspect/1` will produce mismatched keys.

**How to avoid:** Use `Atom.to_string(module)` when constructing keys, or `String.to_existing_atom(key)` when converting manifest keys back to modules. Never use `inspect/1` for module name string conversion.

**Warning signs:** `refute Map.has_key?(manifest["modules"], "Rendro")` passes unexpectedly.

### Pitfall 2: BEAM-Availability Filter Omitted

**What goes wrong:** Using only `Code.ensure_loaded?/1` (not also `match?({:docs_v1,...}, Code.fetch_docs(mod))`) causes in-memory-compiled conditional adapters to appear in the freshly-generated manifest with `:untagged` tier, making the byte-equality assertion fail spuriously.

**How to avoid:** Always apply the full two-condition filter: `Code.ensure_loaded?(mod) and match?({:docs_v1, _, _, _, _, _, _}, Code.fetch_docs(mod))`. This is the exact filter in `manifest_test.exs` Test 5.

### Pitfall 3: Looking for @spec in Code.fetch_docs

**What goes wrong:** `Code.fetch_docs/1` returns the `Docs` chunk — it contains `@doc` content and `@type` documentation, but NOT `@spec` annotations. Specs live in the `abstract_code` chunk, accessible via `Code.Typespec.fetch_specs/1`.

**How to avoid:** Use `Code.Typespec.fetch_specs/1` for spec presence checks. Do not pattern-match on `Code.fetch_docs/1` output looking for spec information.

### Pitfall 4: Forgetting the Trailing Newline in Byte-Equality

**What goes wrong:** `encode_manifest/1` produces JSON without a trailing newline. The generator writes `json <> "\n"` to disk. If the test encodes without appending `"\n"`, the byte-equality fails by exactly one byte.

**How to avoid:** `fresh_json = Mix.Tasks.Rendro.Api.Gen.encode_manifest(fresh_manifest) <> "\n"` — always append the newline.

### Pitfall 5: Guardrail Contract Test Not Updated in Lockstep

**What goes wrong:** Adding the lane to `scripts/verify_docs.exs` without updating `test/guardrails/required_checks_contract_test.exs` causes the lane-count assertion to fail (`== 10` when 11 are registered).

**How to avoid:** Update both files in the same commit. The lane-count assertion regex is `~r/\{"[^"]+", \["test", "test\/docs_contract\/[^"]+"\]\}/` — it counts every entry in `verify_docs.exs`.

### Pitfall 6: @spec Backfill: Forgetting That Struct Modules Have No Public Functions

**What goes wrong:** Treating all 27 stable modules as needing @spec audit wastes time. Pure struct modules (`Block`, `Cell`, `Row`, `Table`, etc.) have zero public `def` functions — only types — so there's nothing to spec.

**How to avoid:** Check the manifest `"functions"` list first. If `"functions": []`, skip that module entirely.

---

## Code Examples

### Complete @spec Assertions Pattern

```elixir
# Source: test/rendro/public_api/manifest_test.exs (Test 5) + Code.Typespec stdlib
defmodule Rendro.DocsContract.PublicApiContractTest do
  use ExUnit.Case, async: false

  alias Rendro.PublicApi
  alias Rendro.PublicApi.{Loader, Validator}

  setup_all do
    PublicApi.recompile_conditional_adapters()
    :ok
  end

  test "stable-tier @spec coverage: every documented stable function has a @spec" do
    manifest = Loader.load!()

    unspecced =
      manifest["modules"]
      |> Enum.filter(fn {_key, entry} -> entry["tier"] == "stable" end)
      |> Enum.flat_map(fn {mod_key, entry} ->
        module = String.to_existing_atom(mod_key)

        specced =
          case Code.Typespec.fetch_specs(module) do
            {:ok, specs} ->
              Enum.map(specs, fn {{name, arity}, _} -> "#{name}/#{arity}" end)

            :error ->
              []
          end

        entry["functions"]
        |> Enum.reject(fn fn_str -> fn_str in specced end)
        |> Enum.map(fn fn_str -> "#{mod_key}.#{fn_str}" end)
      end)

    assert unspecced == [],
           "Stable-tier functions missing @spec:\n  " <> Enum.join(unspecced, "\n  ")
  end
end
```

### Tier-Tag Exactly-One Pattern (D-06)

```elixir
test "every public module has exactly one tier tag: :stable xor :adapter" do
  manifest = Loader.load!()

  violations =
    manifest["modules"]
    |> Enum.flat_map(fn {mod_key, _entry} ->
      module = String.to_existing_atom(mod_key)

      tags =
        case Code.fetch_docs(module) do
          {:docs_v1, _, _, _, _, %{tags: tags}, _} -> tags
          _ -> []
        end

      tier_tags = Enum.filter(tags, &(&1 in [:stable, :adapter]))

      cond do
        length(tier_tags) == 1 -> []
        length(tier_tags) == 0 -> ["#{mod_key}: no tier tag (expected exactly one)"]
        true -> ["#{mod_key}: #{length(tier_tags)} tier tags #{inspect(tier_tags)} (expected exactly one)"]
      end
    end)

  assert violations == [],
         "Tier-tag invariant violated:\n  " <> Enum.join(violations, "\n  ")
end
```

### Hidden-Module Assertion (D-05)

```elixir
test "known internal modules are :hidden from Code.fetch_docs/1" do
  hidden_modules = [
    Rendro.PDF.CidFont,
    Rendro.PDF.FontSubsetter,
    Rendro.Text.Bidi,
    Rendro.Text.Shaper,
    Rendro.Format,
    Rendro.Audit
  ]

  for module <- hidden_modules do
    module_doc =
      case Code.fetch_docs(module) do
        {:docs_v1, _, _, _, module_doc, _, _} -> module_doc
        {:error, _} -> :hidden
      end

    assert module_doc == :hidden,
           "Expected #{inspect(module)} to have @moduledoc false (:hidden), " <>
             "but module_doc is: #{inspect(module_doc)}"
  end
end

test "known redact_* helpers have @doc false in their modules" do
  hidden_helpers = [
    {Rendro.Sign, [:redact_opts, :redact_prepare_opts, :redact_sign_opts, :redact_augment_opts]},
    {Rendro.Protect, [:redact_opts]}
  ]

  for {module, names} <- hidden_helpers do
    {:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(module)

    for name <- names do
      matching = Enum.filter(docs, fn
        {{:function, ^name, _}, _, _, _, _} -> true
        _ -> false
      end)

      assert matching != [], "Expected #{inspect(module)}.#{name}/N in docs but not found"

      for {{:function, fn_name, arity}, _, _, doc, _} <- matching do
        assert doc == :hidden,
               "Expected #{inspect(module)}.#{fn_name}/#{arity} to be @doc false, " <>
                 "got: #{inspect(doc)}"
      end
    end
  end
end
```

---

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation: true`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir) |
| Config file | `test/test_helper.exs` (standard) |
| Quick run command | `mix test test/docs_contract/public_api_contract_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| API-04 (equality) | Fresh manifest byte-matches `priv/public_api.json` | contract | `mix test test/docs_contract/public_api_contract_test.exs` | ❌ Wave 0 |
| API-04 (schema) | On-disk manifest validates against `public_api.schema.json` | contract | same | ❌ Wave 0 |
| API-04 (hidden) | Known internals are `:hidden` in BEAM docs | contract | same | ❌ Wave 0 |
| API-04 (tier-tag) | Every manifested module has exactly one tier tag | contract | same | ❌ Wave 0 |
| API-04 (@spec) | Every stable-tier manifested function has `@spec` | contract | same | ❌ Wave 0 (starts RED) |
| API-04 (guardrails) | `verify_docs.exs` has 11 lanes; lane count assertion passes | contract | `mix test test/guardrails/required_checks_contract_test.exs` | ✅ (needs update) |

### Sampling Rate

- **Per task commit:** `mix test test/docs_contract/public_api_contract_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** `mix ci` full suite green (format + compile --warnings-as-errors + test + docs + credo + dialyzer)

### Wave 0 Gaps

- [ ] `test/docs_contract/public_api_contract_test.exs` — covers all API-04 sub-assertions
- Existing test infrastructure (`test/rendro/public_api/manifest_test.exs`, `test/guardrails/required_checks_contract_test.exs`) covers preconditions; no new fixtures or conftest needed

---

## Security Domain

`security_enforcement` not explicitly set to `false` in config — enabled by default.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A — test-only code, no auth surface |
| V3 Session Management | No | N/A |
| V4 Access Control | No | N/A |
| V5 Input Validation | No | N/A — contract test reads first-party files only |
| V6 Cryptography | No | N/A |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Manifest content manipulation | Tampering | Manifest is a first-party checked-in file; test reads from project root; no external input |
| Test executing arbitrary code | Elevation of Privilege | `Module.to_string_atom` uses `String.to_existing_atom/1` — only atoms that already exist in the BEAM can be created; no injection vector |

No new security surfaces introduced. This phase is pure test-writing.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| ExUnit | Test framework | ✓ | Built into Elixir | — |
| JSV | `Rendro.PublicApi.Validator` | ✓ | Already in deps | — |
| Jason | `encode_manifest/1` | ✓ | Already in deps | — |
| `Code.Typespec` | @spec coverage assertion | ✓ | Elixir stdlib (1.8+) | — |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Elixir version is >= 1.8 (for `Code.Typespec.fetch_specs/1`) | §6 | Needs alternative approach; but project runs Elixir 1.14+ based on modern deps |
| A2 | `render_component/2` return type should be typed as `term()` | §4 | Could be `[Rendro.Block.t()] | term()` if components are constrained; dialyzer will catch if wrong |

---

## Open Questions

1. **Single test file vs. sibling spec-coverage file (Claude's Discretion)**
   - What we know: D-04 is the heaviest assertion and the one that starts RED (until backfill done); manifest equality + hidden + tier assertions start passing from day 1 if the backfill is done first
   - What's unclear: whether grouping all 4 in one file or splitting the @spec assertion into a sibling makes the TDD RED/GREEN story cleaner
   - Recommendation: Single file (`public_api_contract_test.exs`). Splitting would require adding a second lane to `verify_docs.exs` and a second entry to the lane count assertion, adding coordination cost for what is effectively one phase's work.

2. **`render_component/2` exact @spec return type**
   - What we know: the function is `module.render(assigns)` with no constraint on return type
   - What's unclear: whether the project convention specifies a narrower type (list of blocks?)
   - Recommendation: Use `term()` — dialyzer will tighten it if the call sites are typed.

---

## Sources

### Primary (HIGH confidence)

- `lib/rendro/public_api.ex` — exact function signatures, tier_of/1 pattern, public_functions/1 filter
- `lib/mix/tasks/rendro/api.gen.ex` — encode_manifest/1, public_modules/0, BEAM availability filter
- `priv/public_api.json` — exact manifest shape, 45 modules, functions lists
- `priv/schemas/public_api.schema.json` — exact schema shape
- `lib/rendro/public_api/loader.ex` — load!/0 implementation
- `lib/rendro/public_api/validator.ex` — validate/1 implementation
- `test/docs_contract/recipes_contract_test.exs` — canonical async: false contract test structure
- `test/docs_contract/signing_claims_test.exs` — async: true claims test structure
- `test/guardrails/required_checks_contract_test.exs` — lane count assertion at `== 10`; notes assertions
- `scripts/verify_docs.exs` — current 10 lanes list
- `priv/guardrails/required_status_checks.json` — test context notes (currently "8 docs-contract lanes", stale)
- All 27 stable-tier source modules — @spec coverage audit

### Secondary (MEDIUM confidence)

- `test/rendro/public_api/manifest_test.exs` — byte-equality pattern (exact) to mirror in contract test
- `test/rendro/public_api_test.exs` — Code.fetch_docs patterns for hidden check, sweep pattern

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all tools are existing project deps or Elixir stdlib
- Architecture: HIGH — verified against live source; introspection codepath is fully built
- @spec backfill scope: HIGH — verified by direct source file inspection of all 27 stable modules
- Pitfalls: HIGH — all confirmed from Phase 78 SUMMARY deviations and live test patterns
- Guardrails wiring: HIGH — exact notes string and lane-count assertion verified from source

**Research date:** 2026-05-30
**Valid until:** Stable indefinitely — all findings based on checked-in source files; no external dependencies

---

## Key Findings Summary

1. **@spec backfill is minimal:** Only `Rendro.Component` (2 functions, 0 specs) needs backfill. All other stable modules with public functions are already fully specced. The 15 pure-struct modules have zero public functions and trivially satisfy coverage. The pre-research estimate of 7+ modules needing specs was wrong.

2. **Byte-equality encoding is exact:** `Mix.Tasks.Rendro.Api.Gen.encode_manifest(manifest) <> "\n"` — the `<> "\n"` trailing newline is required. Field order within each module entry is `{functions, tier, types}` (alphabetical per `Jason.OrderedObject`).

3. **@spec presence requires `Code.Typespec`, not `Code.fetch_docs`:** `Code.fetch_docs/1` does not return spec information. Use `Code.Typespec.fetch_specs/1` (Elixir stdlib since 1.8).

4. **Guardrails notes are stale:** The current notes say "8 docs-contract lanes" but `verify_docs.exs` has 10 and the guardrail contract test asserts 10. Phase 79 must bump to 11 and update the contract test assertion in lockstep.

5. **Two lockstep files:** `scripts/verify_docs.exs` AND `test/guardrails/required_checks_contract_test.exs` must both be updated when the lane is added.

6. **Module key format:** Always `Atom.to_string(module)` → `"Elixir.Rendro"` (never `inspect/1`). Reverse: `String.to_existing_atom("Elixir.Rendro.Component")`.

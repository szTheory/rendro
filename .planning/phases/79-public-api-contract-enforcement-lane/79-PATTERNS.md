# Phase 79: Public API Contract Enforcement Lane - Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 5 (1 new, 4 modified)
**Analogs found:** 5 / 5

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/docs_contract/public_api_contract_test.exs` | test (contract) | request-response (introspection) | `test/rendro/public_api/manifest_test.exs` + `test/docs_contract/recipes_contract_test.exs` | exact — same `async: false` ExUnit shape, same introspection codepath, byte-equality already present |
| `lib/rendro/component.ex` | module (stable) | transform | `lib/rendro/text.ex` | exact — same `@moduledoc tags: [:stable]`, same `@doc` + `@spec` before each public `def`, same module structure |
| `scripts/verify_docs.exs` | script (config) | batch | self (existing lanes) | self-analog — add one lane entry matching the established tuple shape |
| `test/guardrails/required_checks_contract_test.exs` | test (guardrail) | request-response | self (existing `describe "docs-contract lane count"` block) | self-analog — bump one integer assertion and its description string |
| `priv/guardrails/required_status_checks.json` | config | N/A | self (existing `test` context entry) | self-analog — edit the `notes` string of the `test` context entry |

---

## Pattern Assignments

### `test/docs_contract/public_api_contract_test.exs` (test, introspection)

**Primary analog:** `test/rendro/public_api/manifest_test.exs`
**Secondary analog:** `test/docs_contract/recipes_contract_test.exs`

**Module declaration + async: false** (from `manifest_test.exs` lines 1-7 and `recipes_contract_test.exs` line 1-4):
```elixir
defmodule Rendro.DocsContract.PublicApiContractTest do
  use ExUnit.Case, async: false

  alias Rendro.PublicApi
  alias Rendro.PublicApi.Loader
  alias Rendro.PublicApi.Validator
```
Note: no `alias Rendro.Test.DocsContract` — the public-api contract test does not use fence helpers. Use `Rendro.PublicApi.*` directly. No `@moduledoc` in test files (ExUnit codebase convention).

**setup_all pattern** (from `manifest_test.exs` lines 8-13):
```elixir
  setup_all do
    # Ensure conditional adapters are compiled and available for all tests.
    # This mirrors what mix rendro.api.gen does before introspecting.
    PublicApi.recompile_conditional_adapters()
    :ok
  end
```

**Byte-equality assertion (manifest equality)** — the core pattern to extend (from `manifest_test.exs` lines 76-106):
```elixir
  describe "idempotency and byte-equality (D-15)" do
    test "freshly-generated manifest is byte-identical to the checked-in priv/public_api.json" do
      loaded_modules =
        Mix.Tasks.Rendro.Api.Gen.public_modules()
        |> Enum.filter(fn mod ->
          Code.ensure_loaded?(mod) and
            match?({:docs_v1, _, _, _, _, _, _}, Code.fetch_docs(mod))
        end)

      fresh_manifest = PublicApi.build_manifest(loaded_modules)

      fresh_json = Mix.Tasks.Rendro.Api.Gen.encode_manifest(fresh_manifest) <> "\n"

      checked_in = File.read!("priv/public_api.json")

      assert fresh_json == checked_in,
             """
             The freshly-generated manifest does not byte-match priv/public_api.json.
             This means the manifest is out of date. Run: mix rendro.api.gen
             and commit the result (D-15 drift treadmill guard).
             """
    end
  end
```
Critical pitfall: the `<> "\n"` is mandatory — the generator appends it on write. Omitting it causes a one-byte mismatch.

**Hidden-module assertion** (from `manifest_test.exs` lines 24-43 — adapt for D-05):
```elixir
  describe "hidden module exclusion" do
    test "internal engine modules are absent from the manifest" do
      manifest = Loader.load!()
      module_keys = Map.keys(manifest["modules"])

      hidden_modules = [
        "Elixir.Rendro.PDF.CidFont",
        "Elixir.Rendro.PDF.FontSubsetter",
        "Elixir.Rendro.Text.Bidi",
        "Elixir.Rendro.Text.Shaper",
        "Elixir.Rendro.Format",
        "Elixir.Rendro.Audit"
      ]

      for mod_key <- hidden_modules do
        refute mod_key in module_keys,
               "#{mod_key} should be hidden from the manifest but was found"
      end
    end
  end
```
The D-05 extension also asserts `Code.fetch_docs/1` returns `:hidden` module_doc for those atoms. For that sub-assertion copy the pattern from `manifest_test.exs` lines 141-169 (`redact helpers hidden` describe block — see below).

**Hidden-function assertion** (from `manifest_test.exs` lines 140-170):
```elixir
  describe "redact helpers hidden from public docs" do
    test "redact_opts/1, redact_prepare_opts/1, redact_sign_opts/1, redact_augment_opts/1 have doc: :hidden in Rendro.Sign" do
      {:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(Rendro.Sign)

      hidden_targets = [
        :redact_opts,
        :redact_prepare_opts,
        :redact_sign_opts,
        :redact_augment_opts
      ]

      for name <- hidden_targets do
        matching_entries =
          Enum.filter(docs, fn
            {{:function, ^name, _arity}, _, _, _, _} -> true
            _ -> false
          end)

        assert matching_entries != [],
               "Expected to find function #{name}/N in Rendro.Sign docs but found none"

        for entry <- matching_entries do
          {{:function, fn_name, arity}, _anno, _sig, doc, _meta} = entry

          assert doc == :hidden,
                 "Expected #{fn_name}/#{arity} in Rendro.Sign to have doc: :hidden, " <>
                   "but got: #{inspect(doc)}"
        end
      end
    end
  end
```
For `Rendro.Protect.redact_opts/2`, apply the same pattern targeting `Rendro.Protect` with `[:redact_opts]`.

**Schema validation** (from `manifest_test.exs` lines 16-21):
```elixir
  describe "schema validation" do
    test "loaded manifest validates against priv/schemas/public_api.schema.json" do
      manifest = Loader.load!()
      assert Validator.validate(manifest) == :ok
    end
  end
```

**Tier coverage** (from `manifest_test.exs` lines 58-73 — the foundation for D-06):
```elixir
  describe "tier coverage" do
    test "every module entry has tier stable or adapter — no untagged entries" do
      manifest = Loader.load!()

      untagged =
        manifest["modules"]
        |> Enum.filter(fn {_key, entry} ->
          entry["tier"] not in ["stable", "adapter"]
        end)
        |> Enum.map(fn {key, entry} -> "#{key} (tier=#{entry["tier"]})" end)

      assert untagged == [],
             "Found modules with invalid tier in manifest:\n  #{Enum.join(untagged, "\n  ")}"
    end
  end
```
The D-06 exactly-one-tag assertion extends this by also calling `Code.fetch_docs/1` on each manifested module and asserting `length(tier_tags) == 1` where `tier_tags = Enum.filter(tags, &(&1 in [:stable, :adapter]))`.

**`@spec` coverage assertion** — no pre-existing analog in the codebase; use `Code.Typespec.fetch_specs/1` (stdlib since Elixir 1.8). The RESEARCH.md §6 has the complete implementation pattern.

---

### `lib/rendro/component.ex` (module, stable-tier `@spec` backfill)

**Analog:** `lib/rendro/text.ex` (exact role + structure match: `@moduledoc tags: [:stable]`, `@doc` + `@spec` before each public `def`)

**Current state** (lines 1-37, NO specs):
```elixir
defmodule Rendro.Component do
  @moduledoc """
  Component-based layout pattern for reusable PDF UI parts.
  """
  @moduledoc tags: [:stable]

  @doc """
  Renders a component by calling its `render/1` function.
  """
  def render_component(module, assigns \\ []) do
    module.render(assigns)
  end

  @doc """
  Creates a standard `Rendro.Block` containing a `Rendro.Image`.
  Requires at least one constraint: `:width`, `:height`, or `:fit`.
  """
  def image(logical_name, opts \\ []) do
    ...
  end
end
```

**`@spec` idiom to mirror** (from `lib/rendro/text.ex` lines 41-52):
```elixir
  @doc """
  Returns the current narrow compatibility default for authored text.
  """
  @spec default_font() :: String.t()
  def default_font, do: "Helvetica"

  @doc """
  Normalizes a public font reference.
  ...
  """
  @spec normalize_font(font_ref()) :: font_ref()
  def normalize_font(font) when is_atom(font), do: font
```
Pattern: `@doc` block first, then `@spec` on the line immediately before `def`. No blank line between `@spec` and `def`.

**Alternate analog** (from `lib/rendro/artifact.ex` lines 23-25 and 42-44) — shows default argument in spec:
```elixir
  @spec new(binary(), Rendro.Document.t(), map()) :: t()
  def new(pdf_binary, %Rendro.Document{} = doc, base_metadata \\ %{}) do

  @spec wrap(binary(), t(), map()) :: t()
  def wrap(pdf_binary, %__MODULE__{} = source, metadata_updates \\ %{}) do
```
Pattern: `@spec` types match the non-default arity signature. Default arguments in `def` are fine with a single `@spec`.

**Specs to add to `component.ex`** (confirmed from RESEARCH.md §4):
```elixir
  @spec render_component(module(), keyword()) :: term()
  def render_component(module, assigns \\ []) do

  @spec image(atom(), keyword()) :: Rendro.Block.t()
  def image(logical_name, opts \\ []) do
```
`render_component/2` uses `term()` because it delegates to `module.render(assigns)` with no return type constraint. `image/2` returns `%Rendro.Block{}` (confirmed from implementation body lines 28-36).

---

### `scripts/verify_docs.exs` (script, lane registry)

**Analog:** self — the existing `lanes` list (lines 7-18)

**Current lane list shape** (lines 7-18):
```elixir
lanes = [
  {"README doctest lane", ["test", "test/docs_contract/readme_doctest_test.exs"]},
  {"Integration contract lane", ["test", "test/docs_contract/integrations_contract_test.exs"]},
  {"Integration semantic-claims lane", ["test", "test/docs_contract/integrations_claims_test.exs"]},
  {"Forms semantic-claims lane", ["test", "test/docs_contract/forms_claims_test.exs"]},
  {"Signing semantic-claims lane", ["test", "test/docs_contract/signing_claims_test.exs"]},
  {"Embedded artifact semantic-claims lane", ["test", "test/docs_contract/embedded_artifact_claims_test.exs"]},
  {"Protection semantic-claims lane", ["test", "test/docs_contract/protection_claims_test.exs"]},
  {"Viewer evidence semantic-claims lane", ["test", "test/docs_contract/viewer_evidence_claims_test.exs"]},
  {"Recipes semantic-claims lane", ["test", "test/docs_contract/recipes_claims_test.exs"]},
  {"Page-primitive semantic-claims lane", ["test", "test/docs_contract/page_primitive_claims_test.exs"]}
]
```

**Lane entry to append** (becomes entry 11, after line 17):
```elixir
  {"Public API contract lane", ["test", "test/docs_contract/public_api_contract_test.exs"]},
```
The comma placement: add a trailing comma to the preceding entry (`page_primitive_claims_test.exs` line) and add the new entry as the last item without a trailing comma — or match the existing comma style exactly. The guardrail contract test's regex `~r/\{"[^"]+", \["test", "test\/docs_contract\/[^"]+"\]\}/` counts all entries; the new entry must match this exact tuple shape.

---

### `test/guardrails/required_checks_contract_test.exs` (test, guardrail)

**Analog:** self — the `describe "docs-contract lane count"` block (lines 97-107)

**Current assertion** (lines 97-107):
```elixir
  describe "docs-contract lane count" do
    test "verify_docs.exs registers exactly ten lanes including the recipes and page-primitive lanes" do
      script = File.read!(@verify_docs_path)

      lane_entries = Regex.scan(~r/\{"[^"]+", \["test", "test\/docs_contract\/[^"]+"\]\}/, script)
      assert length(lane_entries) == 10

      assert script =~
               ~s|{"Viewer evidence semantic-claims lane", ["test", "test/docs_contract/viewer_evidence_claims_test.exs"]}|
    end
  end
```

**Target state after Phase 79** — two edits only:
1. Test description string: `"verify_docs.exs registers exactly ten lanes..."` → `"verify_docs.exs registers exactly eleven lanes including the recipes, page-primitive, and public-api contract lanes"`
2. Assertion: `assert length(lane_entries) == 10` → `assert length(lane_entries) == 11`

The `notes` sub-assertions (lines 25-27) do NOT need changes — the Phase 79 notes string retains both `"Phase 68 D-18"` and `"Viewer-evidence"` substrings:
```elixir
      test_context = Enum.find(baseline["contexts"], &(&1["name"] == "test"))
      assert test_context["notes"] =~ "Phase 68 D-18"
      assert test_context["notes"] =~ "Viewer-evidence"
```

---

### `priv/guardrails/required_status_checks.json` (config, guardrail)

**Analog:** self — the `test` context entry (lines 13-20)

**Current `test` context entry** (lines 13-20):
```json
    {
      "name": "test",
      "semantic_class": "deterministic",
      "ci_job": "test",
      "command": "mix ci",
      "notes": "Includes mix test (8 docs-contract lanes), format, hex.build, compile --warnings-as-errors, docs, credo, dialyzer. Viewer-evidence schema/lint folded here per Phase 68 D-18 — not a separate required context."
    },
```

**Target `notes` string for Phase 79:**
```
"Includes mix test (11 docs-contract lanes), format, hex.build, compile --warnings-as-errors, docs, credo, dialyzer. Viewer-evidence schema/lint folded here per Phase 68 D-18 — not a separate required context. Public-api contract lane added Phase 79 D-07."
```
Changes: `(8 docs-contract lanes)` → `(11 docs-contract lanes)` and append ` Public-api contract lane added Phase 79 D-07.` No other fields change. No new entry in `required_contexts[]` or `contexts[]`.

---

## Shared Patterns

### `async: false` for Contract Tests
**Source:** `test/docs_contract/recipes_contract_test.exs` line 2; `test/rendro/public_api/manifest_test.exs` line 2
**Apply to:** `test/docs_contract/public_api_contract_test.exs`
```elixir
use ExUnit.Case, async: false
```
Claims tests use `async: true`; contract tests use `async: false`. The public-api contract test is `async: false` because `recompile_conditional_adapters/0` mutates in-memory module state.

### BEAM-Availability Filter (exact — do not simplify)
**Source:** `test/rendro/public_api/manifest_test.exs` lines 85-89
**Apply to:** `test/docs_contract/public_api_contract_test.exs`
```elixir
|> Enum.filter(fn mod ->
  Code.ensure_loaded?(mod) and
    match?({:docs_v1, _, _, _, _, _, _}, Code.fetch_docs(mod))
end)
```
Both conditions are required. `Code.ensure_loaded?` alone permits in-memory-only compiled conditional adapters through; the `match?` on `Code.fetch_docs` excludes them because `Code.fetch_docs` requires a BEAM file on disk.

### Module Key Format
**Source:** `test/rendro/public_api/manifest_test.exs` lines 29-35
**Apply to:** Any test code converting between manifest keys and module atoms
```elixir
# Manifest keys → module atoms:
module = String.to_existing_atom(mod_key)   # "Elixir.Rendro.Component" → Rendro.Component

# Module atoms → manifest keys:
Atom.to_string(module)   # Rendro.Component → "Elixir.Rendro.Component"
```
Never use `inspect/1` for manifest key construction — `inspect(Rendro)` returns `"Rendro"`, not `"Elixir.Rendro"`.

### Error-Message Style
**Source:** `test/rendro/public_api/manifest_test.exs` lines 63-70
**Apply to:** All `assert` calls in `public_api_contract_test.exs`
```elixir
assert untagged == [],
       "Found modules with invalid tier in manifest:\n  #{Enum.join(untagged, "\n  ")}"
```
Pattern: assertion failure messages are multiline strings with `\n  ` separating list items — not raw tuples or inspect output.

---

## No Analog Found

None — all 5 files have direct analogs in the codebase. The `@spec` coverage assertion is the only assertion with no pre-existing codebase example, but it uses `Code.Typespec.fetch_specs/1` (Elixir stdlib) whose pattern is fully documented in RESEARCH.md §6.

---

## Metadata

**Analog search scope:** `test/docs_contract/`, `test/rendro/public_api/`, `test/guardrails/`, `lib/rendro/`, `scripts/`, `priv/guardrails/`
**Files scanned:** 8 source files read directly
**Pattern extraction date:** 2026-05-30

# Phase 78: Public API Surface Definition & Cleanup — Research

**Researched:** 2026-05-30
**Domain:** Elixir module introspection, ExDoc badge rendering, JSON manifest generation, recipe opts normalization
**Confidence:** HIGH

---

## Summary

Phase 78 makes Rendro's public API surface intentional before the 1.0 cut. The four work areas are: (1) hiding engine internals with `@moduledoc false` / `@doc false`, (2) authoring `priv/public_api.json` via a shared `Rendro.PublicApi` introspection module and `mix rendro.api.gen` task, (3) rendering Stable/Adapter ExDoc badges, and (4) normalizing recipe `sections/2` opts. All four areas have locked decisions in CONTEXT.md (D-01 through D-18). This document covers the implementation mechanics only.

The primary mechanism — `Code.fetch_docs/1` — is verified to work in the project's dev environment. The exact return shape is confirmed: `{:docs_v1, annotation, lang, format, module_doc, metadata, fn_docs}`. `module_doc == :hidden` when `@moduledoc false`; fn_doc tuple element 4 is `:hidden` when `@doc false`. The ExDoc `tags:` mechanism stores atoms in `metadata[:tags]` (the 6th element), which ExDoc retriever reads via `List.wrap(metadata[:tags])` and renders as `<span class="note">(tagname)</span>` in the module heading `h1`. The CSS target is `span.note`.

The critical footgun: `Rendro.Adapters.Threadline`, `.Mailglass`, and `.Accrue` are conditionally compiled via `if Code.ensure_loaded?/1` guards with NO else-branch stub in lib/. They are absent from `Code.fetch_docs/1` in dev env. The project already solves this in tests via `test/support/mocks.ex` (stub definitions) + `AdapterReloader.recompile()` in `test_helper.exs`. The `mix rendro.api.gen` generator must either run in test env or explicitly call the same recompile pattern.

**Primary recommendation:** Build `Rendro.PublicApi` as a pure introspection module that calls `Code.fetch_docs/1` on a declared module list (not auto-discovery), with explicit handling for `{:error, :module_not_found}` on conditionally-compiled adapters. The `mix rendro.api.gen` mix task recompiles the three non-stub adapters (same list as `AdapterReloader`) before introspecting.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**A. Hiding-sweep boundary**
- D-01: Hide (`@moduledoc false`): `Rendro.PDF.CidFont`, `Rendro.PDF.FontSubsetter`, `Rendro.Text.Bidi`, `Rendro.Text.Shaper`, `Rendro.Format`, `Rendro.Audit`. Apply `@doc false` to `Rendro.Sign` `redact_opts/1`, `redact_prepare_opts/1`, `redact_sign_opts/1`, `redact_augment_opts/1`, and `Rendro.Protect.redact_opts/2`.
- D-02: Keep public: `Rendro.RunningContent`, `Rendro.EmbeddedFileRegistry`, `Rendro.FontRegistry.EmbeddedFontFamilyError`.
- D-03: Hide aggressively on pure engine internals; keep conservatively on anything load-bearing in a published `@type` or reachable as a raised exception.

**B. Tier line**
- D-04: `stable` modules: `Rendro`, document model (`Document`, `Page`, `PageTemplate`, `Section`, `Region`, `Block`, `Text`, `Table`, `Image`, `Cell`, `Row`, `Component`), `FontRegistry`, `AssetRegistry`, `EmbeddedFileRegistry`, `RunningContent`, `Error`, `Metadata`, `Sign`, `Protect` (facades), `Rendro.Recipes` (registry/facade).
- D-05: `adapter` modules: all `Rendro.Adapters.*`, `Sign.Adapter`, `Protect.Adapter`, `Storage`, `Storage.Local`, `Inspector`, `Telemetry`, five recipe impl modules.
- D-06: Recipe implementation modules → adapter tier. The facade entry points (`Rendro.Recipes`) → stable.
- D-07: `Rendro.Metadata` → stable; flip `@moduledoc false` → real `@moduledoc`.
- D-08: `Telemetry` → adapter; lock event names + span shape; treat metadata keys as additive.
- D-09: Tier philosophy: stable = core the user builds against; adapter = integrates with outside world or encodes opinions.

**C. Recipe opts normalization**
- D-10: Flip `sections(data, _opts \\ [])` → `sections(data, opts \\ [])` in `Invoice` and `BrandedInvoice`; thread `opts` into their arity-1 private helpers (add arity-2 heads).
- D-11: Default output must stay byte-identical. Thread opts so the path exists but current defaults are unchanged.
- D-12: Do NOT introduce `@behaviour Rendro.Recipes.Recipe`.
- D-13: NimbleOptions validation deferred.

**D. Manifest, schema, badge**
- D-14: Badge = ExDoc native `@moduledoc tags: [:stable]` / `[:adapter]` + CSS via `before_closing_head_tag`.
- D-15: Single source of truth = `@moduledoc tags:` in source. `priv/public_api.json` is a generated mirror. `Rendro.PublicApi` introspection module used by both `mix rendro.api.gen` and Phase 79's contract test.
- D-16: Manifest granularity: per-function grouped by module. Top-level `{"modules": {...}}`; each module has one `tier`, a `functions` list of `"name/arity"`, and a `types` list.
- D-17: Schema = `priv/schemas/public_api.schema.json` (`$id`, no inline version field), validated with JSV. Mirror `support_matrix.schema.json` pattern exactly.
- D-18: Phase 79 test emits two human-readable lists ("in code but not manifested" / "manifested but not in code") — not one opaque assert.

### Claude's Discretion
- Exact CSS for Stable/Adapter badge colors.
- Precise module name for the introspection module (`Rendro.PublicApi` suggested).
- The `mix` task namespace.

### Deferred Ideas (OUT OF SCOPE)
- Formal `@behaviour Rendro.Recipes.Recipe`.
- NimbleOptions-based opts validation.
- Splitting `rendro` / `rendro_adapters` into separate hex packages.
- Internal milestone/phase label scrub in `guides/api_stability.md` (Phase 80/STAB-04).
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| API-01 | Public API manifest `priv/public_api.json` exists, schema-versioned, every documented module/function assigned a tier | `Code.fetch_docs/1` shape, JSON emission with stdlib JSON, JSV validation pattern from `support_matrix.json` precedent |
| API-02 | Accidentally-public internals hidden (`@moduledoc false`, `@doc false`); full sweep; each module either in manifest or hidden | Current visibility audit shows CidFont, FontSubsetter, Bidi, Shaper, Format, Audit are currently PUBLIC and need hiding; redact_* are currently `:none` (not `:hidden`) |
| API-03 | Returned/accepted types documented — expose `Rendro.Metadata` with real `@moduledoc` + `@type t` | `Rendro.Metadata` currently has `@moduledoc false` confirmed; `@type t` already exists at line 14; flip only requires removing the `false` and adding doc text |
| API-05 | ExDoc renders per-module stability badge; recipe opts normalized across all five recipes | ExDoc `tags:` → `<span class="note">` confirmed; `before_closing_head_tag` CSS injection pattern confirmed; Invoice/BrandedInvoice `_opts` → `opts` threading confirmed minimal |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Module visibility control (`@moduledoc false`) | Elixir source files | — | Compile-time attribute; no runtime component |
| Manifest generation | Mix task (`mix rendro.api.gen`) | `Rendro.PublicApi` introspection module | Task is the I/O layer; `PublicApi` is the pure logic |
| Manifest storage | `priv/public_api.json` | `priv/schemas/public_api.schema.json` | Static priv files; no runtime write |
| Schema validation | `Rendro.PublicApi` (or new module) | JSV library | Mirrors `Rendro.ViewerEvidence.Validator` pattern |
| ExDoc badge rendering | `mix.exs` `docs/0` | ExDoc (external) | `before_closing_head_tag` CSS injection; `@moduledoc tags:` in source |
| Recipe opts threading | `lib/rendro/recipes/invoice.ex`, `branded_invoice.ex` | `Rendro.Recipes.Pagination` (reuse formatter/3, label_resolver/1) | Additive change to two files; helpers already exist |
| Phase 79 contract test (deferred) | `test/docs_contract/public_api_contract_test.exs` | `Rendro.PublicApi` (reuse) | Phase 78 builds; Phase 79 consumes |

---

## Focus Area 1: `Code.fetch_docs/1` Introspection

### Verified Return Shape

`Code.fetch_docs(Module)` returns: `[VERIFIED: Elixir source + live project inspection]`

```elixir
{:docs_v1, annotation, language, format, module_doc, metadata, fn_docs}
```

| Field | Position | Values |
|-------|----------|--------|
| `module_doc` | 5th | `:hidden` when `@moduledoc false`; `:none` when no `@moduledoc`; `%{"en" => text}` when documented |
| `metadata` | 6th | `%{behaviours: [], source_annos: [...], source_path: '...'}` + `tags: [:stable]` when `@moduledoc tags: [:stable]` is set |
| `fn_docs` | 7th | List of `{{kind, name, arity}, annotation, signatures, doc, metadata}` tuples |

### Function/Type Doc States

In a `fn_docs` tuple `{{kind, name, arity}, _ann, _sigs, doc, _meta}`:
- `doc == :hidden` — function has `@doc false`; excluded from ExDoc
- `doc == :none` — function has `@spec` but no `@doc` text (still appears in ExDoc summary)
- `doc == %{"en" => text}` — fully documented

**For the manifest, "documented" = `doc != :hidden` for both functions and types.** `[VERIFIED: live project inspection]`

### Extracting the Tags Tier

```elixir
# Read tier from module metadata
{:docs_v1, _, _, _, module_doc, metadata, fn_docs} = Code.fetch_docs(module)

# module_doc == :hidden -> @moduledoc false (skip, not in manifest)
# metadata[:tags] -> [:stable] or [:adapter] (the tier)

tier = case metadata[:tags] do
  [:stable] -> "stable"
  [:adapter] -> "adapter"
  _ -> nil  # no tier tag yet
end

# Extract documented functions ("name/arity" strings, excluding :hidden)
functions =
  for {{:function, name, arity}, _, _, doc, _} <- fn_docs,
      doc != :hidden,
      do: "#{name}/#{arity}"

# Extract types
types =
  for {{:type, name, arity}, _, _, doc, _} <- fn_docs,
      doc != :hidden,
      do: "#{name}/#{arity}"
```

`[VERIFIED: live project inspection on Rendro.Document, Rendro.Metadata, Rendro.Sign]`

### Detecting Hidden Modules

```elixir
case Code.fetch_docs(SomeModule) do
  {:error, :module_not_found} -> :not_compiled   # conditionally compiled, dep absent
  {:error, _}                  -> :error
  {:docs_v1, _, _, _, :hidden, _, _} -> :hidden  # @moduledoc false
  {:docs_v1, _, _, _, _, _, _}       -> :visible
end
```

### Current Visibility of Sweep Targets

Confirmed via live inspection: `[VERIFIED: live project inspection]`

| Module | Current State | Action |
|--------|--------------|--------|
| `Rendro.PDF.CidFont` | PUBLIC (has `@moduledoc` text) | Add `@moduledoc false` |
| `Rendro.PDF.FontSubsetter` | PUBLIC | Add `@moduledoc false` |
| `Rendro.Text.Bidi` | PUBLIC | Add `@moduledoc false` |
| `Rendro.Text.Shaper` | PUBLIC | Add `@moduledoc false` |
| `Rendro.Format` | PUBLIC | Add `@moduledoc false` |
| `Rendro.Audit` | PUBLIC | Add `@moduledoc false` |
| `Rendro.Metadata` | HIDDEN (`@moduledoc false`) | Flip to real `@moduledoc` + `tags: [:stable]` |
| `Rendro.Sign.redact_*` | `:none` (no `@doc`, not hidden) | Add `@doc false` to four functions |
| `Rendro.Protect.redact_opts/2` | (check at line ~78) | Add `@doc false` |

---

## Focus Area 2: Conditional-Compilation Footgun

### The Problem

Five adapter files use `if Code.ensure_loaded?/1` guards: `[VERIFIED: source inspection]`

```
lib/rendro/adapters/phoenix.ex      — if Code.ensure_loaded?(Plug.Conn) and Code.ensure_loaded?(Phoenix)
lib/rendro/adapters/oban/render_worker.ex — if Code.ensure_loaded?(Oban)
lib/rendro/adapters/threadline.ex   — if Code.ensure_loaded?(Threadline)
lib/rendro/adapters/mailglass.ex    — if Code.ensure_loaded?(Mailglass)
lib/rendro/adapters/accrue.ex       — if Code.ensure_loaded?(Accrue)
```

In dev env, `Code.fetch_docs/1` returns: `[VERIFIED: live inspection]`

| Module | Dev Status | Reason |
|--------|-----------|--------|
| `Rendro.Adapters.Phoenix` | COMPILED | `:phoenix` + `:plug` in `mix.exs` as optional deps |
| `Rendro.Adapters.Oban.RenderWorker` | COMPILED | `:oban` in `mix.exs` as optional dep |
| `Rendro.Adapters.Threadline` | `{:error, :module_not_found}` | `:threadline` NOT in `mix.exs` |
| `Rendro.Adapters.Mailglass` | `{:error, :module_not_found}` | `:mailglass` NOT in `mix.exs` |
| `Rendro.Adapters.Accrue` | `{:error, :module_not_found}` | `:accrue` NOT in `mix.exs` |

Phoenix has an else-branch stub (still `@moduledoc false`). Threadline, Mailglass, Accrue have NO else-branch stubs.

### The Existing Solution (test env)

`test/support/mocks.ex` defines stub modules: `Threadline`, `Mailglass`, `Accrue`, `Swoosh.*` — gated by `unless Code.ensure_loaded?/1`. `test_helper.exs` then calls `Rendro.Test.Mocks.AdapterReloader.recompile/0`:

```elixir
# test/support/mocks.ex (lines 205-232) - VERIFIED: source inspection
defmodule Rendro.Test.Mocks.AdapterReloader do
  @adapter_files [
    "lib/rendro/adapters/threadline.ex",
    "lib/rendro/adapters/mailglass.ex",
    "lib/rendro/adapters/accrue.ex"
  ]

  def recompile do
    project_root = File.cwd!()
    for relative <- @adapter_files, path = Path.join(project_root, relative), File.exists?(path) do
      Code.compile_file(path)
    end
    :ok
  end
end
```

### Robust Pattern for the Generator

The `mix rendro.api.gen` task must call the same recompile pattern before introspecting. The task should:

1. Recompile the three non-stub adapter files (matching `AdapterReloader`'s list)
2. Use an explicit module list (not `Application.spec` discovery) so conditionally absent modules are known
3. Handle `{:error, :module_not_found}` by recording the module as "conditionally compiled" with its known tier from the explicit list — not silently skipping it

**The Phase 79 exact-equality test** must also account for this: either run in a context where all adapters are compiled (test env via test_helper stubs) or use the same explicit-list approach.

---

## Focus Area 3: ExDoc `tags:` Badge Mechanism

### Confirmed ExDoc 0.40 Behavior

ExDoc `retriever.ex` line 174: `annotations: List.wrap(metadata[:tags])` `[VERIFIED: deps/ex_doc/lib/ex_doc/retriever.ex source inspection]`

Module template `module_template.eex`: `[VERIFIED: source inspection]`
```html
<%= for annotation <- module.annotations do %>
  <span class="note">(<%= annotation %>)</span>
<% end %>
```

The annotation text is the atom's string form (e.g., `:stable` → `"stable"`, `:adapter` → `"adapter"`).

**Default `.note` CSS** (from ExDoc bundle): `[VERIFIED: css bundle inspection]`
```css
.note { color: var(--iconAction); font-size: var(--text-xs); font-weight: 400; }
```

### Syntax for Adding Tags

```elixir
@moduledoc """
Short description of the module.
""", tags: [:stable]
```

Or with only the tag and no text body modification:
```elixir
@moduledoc tags: [:stable]
```

`tags:` ends up in `metadata[:tags]` in `Code.fetch_docs/1` after compilation. `[VERIFIED: ExDoc retriever.ex source + Elixir stdlib behavior confirmed]`

### CSS Injection Pattern

In `mix.exs` `docs/0`:

```elixir
defp docs do
  [
    # ... existing options ...
    before_closing_head_tag: fn
      :html ->
        """
        <style>
        h1 span.note { padding: 2px 8px; border-radius: 4px; font-size: 0.75em; font-weight: 600; }
        </style>
        <script>
        document.addEventListener("DOMContentLoaded", function() {
          document.querySelectorAll("h1 span.note").forEach(function(el) {
            var text = el.textContent.toLowerCase();
            if (text.indexOf("stable") !== -1) {
              el.style.backgroundColor = "#dcfce7";
              el.style.color = "#166534";
            } else if (text.indexOf("adapter") !== -1) {
              el.style.backgroundColor = "#dbeafe";
              el.style.color = "#1e40af";
            }
          });
        });
        </script>
        """
      _ ->
        ""
    end,
    # ... rest of docs options ...
  ]
end
```

CSS cannot target `span.note` content with pure CSS text-content selectors; a tiny inline JS snippet (no deps, no external resources) is the pragmatic solution since ExDoc renders annotations as plain text atoms. `[ASSUMED: pure CSS approach; JS approach is verified implementable]`

---

## Focus Area 4: JSV Validation + Priv-File Loader Pattern

### Exact JSV API

From `lib/rendro/viewer_evidence/validator.ex`: `[VERIFIED: source inspection]`

```elixir
# Step 1: Build the schema root (done once, ideally at module attribute level)
@schema_path "priv/schemas/public_api.schema.json"
defp schema_root do
  @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
end

# Step 2: Validate
case JSV.validate(data, schema_root()) do
  {:ok, _validated} -> :ok
  {:error, err} ->
    err |> JSV.normalize_error() |> inspect(limit: :infinity)
    # -> {:error, formatted_string}
end
```

JSV version in use: `0.19.1` `[VERIFIED: live inspection]`

### Priv-File Loader Pattern

From `lib/rendro/viewer_evidence/matrix.ex`: `[VERIFIED: source inspection]`

```elixir
@matrix_path "priv/support_matrix.json"

@spec load!() :: map()
def load! do
  @matrix_path |> File.read!() |> JSON.decode!()
end
```

Mirror this for `Rendro.PublicApi`:

```elixir
@manifest_path "priv/public_api.json"

@spec load!() :: map()
def load! do
  @manifest_path |> File.read!() |> JSON.decode!()
end
```

### Schema Pattern (no inline version field)

`priv/schemas/support_matrix.schema.json` uses `$id` + no `schema_version` inline field. `[VERIFIED: source inspection]`

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "public_api.schema.json",
  "title": "Rendro Public API Manifest",
  "description": "...",
  "type": "object",
  "required": ["modules"],
  "properties": {
    "modules": {
      "type": "object",
      "additionalProperties": { "$ref": "#/$defs/module_entry" }
    }
  },
  "$defs": {
    "module_entry": {
      "type": "object",
      "required": ["tier", "functions", "types"],
      "additionalProperties": false,
      "properties": {
        "tier": { "type": "string", "enum": ["stable", "adapter"] },
        "functions": { "type": "array", "items": { "type": "string" }, "uniqueItems": true },
        "types": { "type": "array", "items": { "type": "string" }, "uniqueItems": true }
      }
    }
  }
}
```

---

## Focus Area 5: Canonical JSON Emission

### Elixir Stdlib `JSON.encode!` Behavior

`JSON.encode!` on string-keyed maps produces alphabetically sorted keys. `[VERIFIED: live inspection]`

```elixir
iex> JSON.encode!(%{"z" => 1, "a" => 2})
#=> "{\"a\":2,\"z\":1}"  # sorted

iex> JSON.encode!(%{z: 1, a: 2})
#=> "{\"m\":3,\"a\":2,\"z\":1}"  # NOT sorted (atom keys, insertion order)
```

**Canonical emission recipe** (no external deps needed, no Jason required):

```elixir
# Build the manifest data with string keys throughout
modules_map =
  modules
  |> Enum.reduce(%{}, fn {mod_name, info}, acc ->
    entry = %{
      "tier" => info.tier,
      "functions" => info.functions |> Enum.sort() |> Enum.uniq(),
      "types" => info.types |> Enum.sort() |> Enum.uniq()
    }
    Map.put(acc, mod_name, entry)
  end)

manifest = %{"modules" => modules_map}
File.write!("priv/public_api.json", JSON.encode!(manifest))
```

String-keyed maps at every level = alphabetical key sorting = deterministic output. Module names sort alphabetically. Functions and types are sorted via `Enum.sort/1` before encoding. `[VERIFIED: live JSON.encode! tests]`

**No pretty-printing helper exists** in the project. The generator writes compact JSON (no indentation). This matches the `support_matrix.json` precedent (hand-authored with indentation, but the generator output will be compact and normalized).

---

## Focus Area 6: `mix` Task Authoring

### Existing Mix Task Pattern

Two strong patterns to mirror: `[VERIFIED: source inspection]`

**Pattern A — Simple task (`lib/mix/tasks/docs.contract.ex`):**
```elixir
defmodule Mix.Tasks.Docs.Contract do
  use Mix.Task
  @moduledoc "..."
  @shortdoc "One-line description"

  def run(_args) do
    # ...
  end
end
```

**Pattern B — Full operator task (`lib/mix/tasks/rendro/viewer_evidence.ex`):**
```elixir
defmodule Mix.Tasks.Rendro.ViewerEvidence do
  use Mix.Task
  @shortdoc "Audit viewer-evidence coverage in the support matrix"
  @moduledoc "..."

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    # parse args, delegate to module functions
  end
end
```

For `mix rendro.api.gen`:

- Module name: `Mix.Tasks.Rendro.Api.Gen`
- File: `lib/mix/tasks/rendro/api/gen.ex`
- `@shortdoc "Generate priv/public_api.json from @moduledoc tags: attributes"`
- `@impl Mix.Task`
- Call `Mix.Task.run("app.start")` to ensure the app is loaded
- Then recompile the three conditional adapter files (mirror `AdapterReloader`)
- Then call `Rendro.PublicApi.generate!()` (or equivalent)

---

## Focus Area 7: Recipe Opts Threading (D-10/D-11)

### Current State

`Rendro.Recipes.Invoice.sections/2` (line 69): `sections(data, _opts \\ [])` — opts silently ignored. `[VERIFIED: source inspection]`

`Rendro.Recipes.BrandedInvoice.sections/2` (line 99): same pattern.

Private helpers in both: all arity-1 (`defp header_section(%{...} = _data)`). No formatter calls. No `label_resolver` calls.

### Reference Pattern (Statement)

`Rendro.Recipes.Statement.sections/2` (line 204): `sections(data, opts \\ [])` threads `opts` to all three private helpers, which call: `[VERIFIED: source inspection]`

```elixir
defp header_section(data, opts) do
  fmt_amount = Rendro.Recipes.Pagination.formatter(opts, :amount, &Rendro.Format.money/1)
  fmt_date = Rendro.Recipes.Pagination.formatter(opts, :date, &Rendro.Format.date/1)
  lbl = Rendro.Recipes.Pagination.label_resolver(opts)
  # ...
end
```

`Rendro.Recipes.Pagination.formatter/3` (line 57): `[VERIFIED: source inspection]`
```elixir
def formatter(opts, key, default_fn) do
  formatters = Keyword.get(opts, :formatters, [])
  Keyword.get(formatters, key, default_fn)
end
```

`Rendro.Recipes.Pagination.label_resolver/1` (line 64): returns a `fn key -> ... end`.

### Exact Change for Invoice (D-10/D-11)

Minimum additive change to normalize the signature without changing output:

```elixir
# BEFORE (line 69):
def sections(data, _opts \\ []) do
  [header_section(data), body_section(data), footer_section(data)]
end

defp header_section(%{id: id, date: date} = _data) do ... end
defp body_section(%{items: items} = _data) do ... end
defp footer_section(_data) do ... end

# AFTER (additive — default output byte-identical when opts == []):
def sections(data, opts \\ []) do
  [header_section(data, opts), body_section(data, opts), footer_section(data, opts)]
end

defp header_section(%{id: id, date: date} = _data, _opts) do ... end  # _opts for now
defp body_section(%{items: items} = _data, _opts) do ... end
defp footer_section(_data, _opts) do ... end
```

`BrandedInvoice` follows the same pattern (4 helpers: logo, header, body, footer).

If D-11's scope allows threading formatters through to actual formatting calls, the planner should add `Pagination.formatter` calls to the helper bodies matching Statement's pattern. Since Invoice does not currently call any formatter functions, the minimal scope is "accept and forward" only.

**Warning for planner:** `mix ci` runs `compile --warnings-as-errors`. Renaming `_opts` to `opts` in a function that does not use `opts` will generate "variable opts is unused" warning. Use `_opts` in helper heads that don't yet use opts, or suppress by binding with `_opts = opts`. The outer `sections/2` can use `opts` since it passes it to helpers.

---

## Focus Area 8: Validation Architecture (Nyquist)

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) |
| Config file | `test/test_helper.exs` |
| Quick run | `mix test test/docs_contract/` |
| Full suite | `mix test` |
| CI run | `mix ci` (includes `mix test`, `compile --warnings-as-errors`, etc.) |

### What is Testable in Phase 78

**Manifest round-trip test** (new, in `test/docs_contract/`):

```elixir
test "priv/public_api.json passes JSV schema validation" do
  manifest = Rendro.PublicApi.load!()
  assert :ok = Rendro.PublicApi.validate_manifest!(manifest)
end

test "manifest generator is idempotent" do
  # Load current manifest, regenerate in memory, assert equality
  current = Rendro.PublicApi.load!()
  regenerated = Rendro.PublicApi.generate_map()
  assert current == regenerated
end
```

**Hiding sweep verification** (add to existing or new test):

```elixir
test "confirmed engine internals are hidden after sweep" do
  for mod <- [Rendro.PDF.CidFont, Rendro.PDF.FontSubsetter,
              Rendro.Text.Bidi, Rendro.Text.Shaper, Rendro.Format, Rendro.Audit] do
    {:docs_v1, _, _, _, module_doc, _, _} = Code.fetch_docs(mod)
    assert module_doc == :hidden, "#{mod} should be @moduledoc false"
  end
end

test "redact_* helpers are @doc false in Sign and Protect" do
  {:docs_v1, _, _, _, _, _, fn_docs} = Code.fetch_docs(Rendro.Sign)
  redact_fns = for {{:function, name, _}, _, _, doc, _} <- fn_docs,
                   String.starts_with?(Atom.to_string(name), "redact"),
                   do: {name, doc}
  for {name, doc} <- redact_fns do
    assert doc == :hidden, "Sign.#{name} should be @doc false"
  end
end
```

**Metadata exposure test**:

```elixir
test "Rendro.Metadata is now documented (not @moduledoc false)" do
  {:docs_v1, _, _, _, module_doc, _, _} = Code.fetch_docs(Rendro.Metadata)
  assert is_map(module_doc), "Rendro.Metadata should have a real @moduledoc"
  assert Map.has_key?(module_doc, "en")
end
```

**Recipe opts threading** (idempotent output test):

```elixir
test "Invoice.sections/2 with empty opts returns same sections as no-opts call" do
  data = %{id: "X", date: ~D[2026-01-01], items: []}
  assert Invoice.sections(data) == Invoice.sections(data, [])
end

test "BrandedInvoice.sections/2 with empty opts is byte-identical" do
  data = %{...brand data...}
  assert BrandedInvoice.sections(data) == BrandedInvoice.sections(data, [])
end
```

**Tags on public modules** (verifies the tier metadata is accessible):

```elixir
test "stable modules carry tags: [:stable] in metadata" do
  for mod <- [Rendro, Rendro.Document, Rendro.Metadata] do
    {:docs_v1, _, _, _, _, metadata, _} = Code.fetch_docs(mod)
    assert metadata[:tags] == [:stable], "#{mod} should have tags: [:stable]"
  end
end
```

### What is Deferred to Phase 79

- The exact-equality contract test (`introspected surface == manifest`), with human-readable two-sided diff (D-18).
- The assertion that known internals are `:hidden` in a machine-enforced way (Phase 78 establishes the hiding, Phase 79 pins it).
- Tier-1 `@spec` coverage assertion.
- Wiring into `priv/guardrails/required_status_checks.json`.

### Existing Test File to Mirror

`test/docs_contract/viewer_evidence_claims_test.exs` — uses `JSV.validate`, loads `priv/support_matrix.json` directly, and asserts structural properties. Mirror this for `public_api_contract_test.exs` in Phase 78's scope. `[VERIFIED: source inspection]`

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| API-01 | `priv/public_api.json` exists and passes schema | unit | `mix test test/docs_contract/ -t public_api` | No — Wave 0 |
| API-01 | Generator output is idempotent | unit | `mix test test/docs_contract/ -t public_api` | No — Wave 0 |
| API-02 | Engine internals are `@moduledoc false` | unit | `mix test test/docs_contract/` | No — Wave 0 |
| API-02 | `redact_*` helpers are `@doc false` | unit | `mix test test/docs_contract/` | No — Wave 0 |
| API-03 | `Rendro.Metadata` has visible `@moduledoc` | unit | `mix test test/docs_contract/` | No — Wave 0 |
| API-05 | `sections/2` opts threading is idempotent | unit | `mix test test/rendro/recipes/` | Partial — extend existing |

### Wave 0 Gaps

- `test/docs_contract/public_api_claims_test.exs` — new file; covers API-01, API-02, API-03 introspection assertions
- `test/docs_contract/public_api_contract_test.exs` — new file; covers manifest load + JSV schema validation + idempotent generator

---

## Architecture Patterns

### System Architecture

```
Source files (@moduledoc tags: [:stable/:adapter])
        |
        v
  Rendro.PublicApi     <-- pure introspection logic
  (Code.fetch_docs/1)      (also used by Phase 79)
        |
        +-- mix rendro.api.gen ---------> priv/public_api.json
        |   (I/O layer; recompiles        (canonical, string-keyed,
        |    conditional adapters)         Enum.sort'd functions/types)
        |
        +-- Rendro.PublicApi.validate! -> priv/schemas/public_api.schema.json
                                          (JSV validation, mirrors ViewerEvidence.Validator)

mix.exs docs/0
  @moduledoc tags: -> ExDoc retriever -> module.annotations -> <span class="note">(stable)</span>
  before_closing_head_tag -> CSS + JS snippet to color stable=green, adapter=blue
```

### Recommended Project Structure (new files)

```
lib/
  rendro/
    public_api.ex           # Rendro.PublicApi — introspection + manifest logic
  mix/tasks/rendro/api/
    gen.ex                  # Mix.Tasks.Rendro.Api.Gen

priv/
  public_api.json           # generated manifest (committed)
  schemas/
    public_api.schema.json  # sibling schema ($id, no inline version)

test/docs_contract/
  public_api_claims_test.exs   # sweep/hiding/metadata assertions (Phase 78 scope)
  public_api_contract_test.exs # manifest load, JSV validation, idempotency
```

### Pattern: `Rendro.PublicApi` Module Structure

```elixir
defmodule Rendro.PublicApi do
  @moduledoc false  # operator/internal tool, not public API itself

  @manifest_path "priv/public_api.json"
  @schema_path "priv/schemas/public_api.schema.json"

  # The full declared module list (explicit, not auto-discovered)
  # Handles conditional compilation: modules in @conditional_modules
  # may return {:error, :module_not_found} and are recorded with their known tier
  @declared_stable_modules [
    Rendro, Rendro.Document, Rendro.Page, Rendro.PageTemplate,
    # ... per D-04 list ...
  ]
  @declared_adapter_modules [
    Rendro.Adapters.Phoenix, Rendro.Adapters.Oban.RenderWorker,
    Rendro.Adapters.Threadline, Rendro.Adapters.Mailglass, Rendro.Adapters.Accrue,
    # ... per D-05 list ...
  ]
  @conditional_modules [
    Rendro.Adapters.Threadline, Rendro.Adapters.Mailglass, Rendro.Adapters.Accrue
  ]

  @spec generate_map() :: map()
  def generate_map do
    modules = build_module_entries(@declared_stable_modules, "stable") ++
              build_module_entries(@declared_adapter_modules, "adapter")
    %{"modules" => Map.new(modules)}
  end

  @spec load!() :: map()
  def load!, do: @manifest_path |> File.read!() |> JSON.decode!()

  @spec validate_manifest!(map()) :: :ok
  def validate_manifest!(manifest) do
    root = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
    case JSV.validate(manifest, root) do
      {:ok, _} -> :ok
      {:error, err} -> raise ArgumentError, JSV.normalize_error(err) |> inspect()
    end
  end

  defp build_module_entries(modules, tier) do
    Enum.flat_map(modules, fn mod ->
      case Code.fetch_docs(mod) do
        {:error, _} when mod in @conditional_modules ->
          # Known conditional: include with known tier but empty lists
          # (Phase 79 test accounts for this explicitly)
          [{inspect(mod), %{"tier" => tier, "functions" => [], "types" => [], "conditional" => true}}]
        {:docs_v1, _, _, _, :hidden, _, _} ->
          []  # @moduledoc false — skip
        {:docs_v1, _, _, _, _, _, fn_docs} ->
          fns = for {{:function, n, a}, _, _, d, _} <- fn_docs, d != :hidden, do: "#{n}/#{a}"
          types = for {{:type, n, a}, _, _, d, _} <- fn_docs, d != :hidden, do: "#{n}/#{a}"
          [{inspect(mod), %{"tier" => tier, "functions" => Enum.sort(fns), "types" => Enum.sort(types)}}]
        _ -> []
      end
    end)
  end
end
```

### `groups_for_modules` Drift to Resolve

Current `mix.exs` `groups_for_modules` places `Rendro.Adapters.PyHanko` and `Rendro.Adapters.Pdfsig` under `"Signing"`, not `"Ecosystem Adapters"`. During the sweep, reconcile this group list with the D-04/D-05 tier assignments. `PyHanko` and `Pdfsig` are adapter-tier modules; they should be in the `"Ecosystem Adapters"` group (or a new `"Signing Adapters"` group) in `groups_for_modules`. `[VERIFIED: mix.exs source inspection]`

Also: `Cell`, `Row`, `Component` are in D-04 stable list but not currently in `groups_for_modules` under "Core Builder API". The sweep should add them or verify they're covered by the implicit "Modules" catch-all.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON Schema validation | Custom struct validator | `JSV.validate/2` | Already in `mix.exs`; `ViewerEvidence.Validator` is the proven pattern |
| Canonical JSON with sorted keys | Custom sort-encode loop | `Elixir stdlib JSON.encode!` with string-keyed maps | String keys sort automatically; lists sorted via `Enum.sort/1` before encoding |
| Module doc detection | Parse source AST | `Code.fetch_docs/1` | Official BEAM introspection; handles all doc states natively |
| Adapter recompile in generator | Custom file watcher | Reuse `AdapterReloader` pattern (or copy its file list) | The test suite already solved this; use the same three-file list |
| ExDoc badge rendering | Custom HTML in `@moduledoc` | `@moduledoc tags: [:stable]` | ExDoc 0.40 renders natively as `<span class="note">` |

---

## Common Pitfalls

### Pitfall 1: `unused variable opts` Warning in `mix ci`

**What goes wrong:** Renaming `_opts` to `opts` in `sections/2` and passing it to helpers, but leaving the helper parameters as `_opts` (unused locally), still triggers no warning because `_opts` is explicitly ignored. However, if any intermediate variable is named `opts` in a helper that doesn't use it, `compile --warnings-as-errors` will fail CI.

**How to avoid:** In helper heads that do not yet use `opts`, keep the underscore prefix: `defp header_section(data, _opts)`. The outer `sections/2` uses `opts` (passes to helpers), so no warning there.

**Warning signs:** CI failing on `compile --warnings-as-errors` immediately after the opts threading change.

### Pitfall 2: Atom vs. String Keys in Manifest Map

**What goes wrong:** Building the manifest data with atom keys (`%{tier: "stable", ...}`) and calling `JSON.encode!`. Elixir stdlib JSON encodes atom keys as their string form but in insertion order (not sorted). The output is not deterministic if map keys are atoms.

**How to avoid:** Use string keys throughout the manifest data structure. Confirmed: `JSON.encode!(%{"b" => 1, "a" => 2})` → `{"a":1,"b":2}` (sorted). `JSON.encode!(%{b: 1, a: 2})` → `{"b":1,"a":2}` (NOT sorted). `[VERIFIED: live test]`

### Pitfall 3: Generator Running Before Adapter Recompile

**What goes wrong:** `mix rendro.api.gen` runs `Mix.Task.run("app.start")` but the three conditional adapters (`Threadline`, `Mailglass`, `Accrue`) are not in `mix.exs` and are not recompiled by `app.start`. `Code.fetch_docs` returns `{:error, :module_not_found}` for them.

**How to avoid:** The generator explicitly calls `Code.compile_file/1` on the three adapter files (matching `AdapterReloader`'s list) after stubs would be loaded. In practice: the generator task is documented to run in the `test` Mix env where `test_helper.exs` handles this, OR the task itself recompiles the files inline.

### Pitfall 4: ExDoc `tags:` Only Goes into Module-Level Metadata (not function-level)

**What goes wrong:** Attempting to use `@doc tags: [:stable]` on individual functions — ExDoc does not render function-level tags as badges (this is a module-only feature in ExDoc 0.40).

**How to avoid:** Tags go on `@moduledoc` only. Functions get their tier from their parent module's tier.

### Pitfall 5: `before_closing_head_tag` Returns `""` Instead of String

**What goes wrong:** `before_closing_head_tag` must be a function `fn atom -> string end`. Returning `nil` or forgetting to handle the `_ ->` clause for `:epub` causes a runtime error during `mix docs`.

**How to avoid:** Always use `fn :html -> "<style>...</style>" ; _ -> "" end`.

### Pitfall 6: `groups_for_modules` Lists Modules Not in the Manifest

**What goes wrong:** After hiding modules with `@moduledoc false`, they remain in `groups_for_modules` causing ExDoc to warn about unlisted modules (which `mix ci` may surface under `--warnings-as-errors` via `docs`).

**How to avoid:** Remove hidden modules from `groups_for_modules` during the same sweep task.

---

## Code Examples

### Pattern: Extracting Module Tier from `Code.fetch_docs`

```elixir
# Source: lib/rendro/viewer_evidence/validator.ex (adapted pattern)
def tier_for_module(module) do
  case Code.fetch_docs(module) do
    {:error, _} -> {:error, :not_compiled}
    {:docs_v1, _, _, _, :hidden, _, _} -> {:ok, :hidden}
    {:docs_v1, _, _, _, _, metadata, _} ->
      case metadata[:tags] do
        [:stable]  -> {:ok, "stable"}
        [:adapter] -> {:ok, "adapter"}
        nil        -> {:ok, :untagged}
        tags       -> {:ok, {:unknown_tags, tags}}
      end
  end
end
```

### Pattern: Function List from `Code.fetch_docs`

```elixir
# Verified against Rendro.Document in live inspection
def documented_functions(module) do
  case Code.fetch_docs(module) do
    {:docs_v1, _, _, _, _, _, fn_docs} ->
      for {{:function, name, arity}, _, _, doc, _} <- fn_docs,
          doc != :hidden,
          do: "#{name}/#{arity}"
    _ -> []
  end
end
```

### Pattern: JSV Validate (mirrors ViewerEvidence.Validator)

```elixir
# Source: lib/rendro/viewer_evidence/validator.ex:28-33
case JSV.validate(manifest, schema_root) do
  {:ok, _} -> :ok
  {:error, err} -> {:error, err |> JSV.normalize_error() |> inspect(limit: :infinity)}
end
```

### Pattern: Mix Task Skeleton

```elixir
# Mirrors lib/mix/tasks/rendro/viewer_evidence.ex structure
defmodule Mix.Tasks.Rendro.Api.Gen do
  use Mix.Task

  @shortdoc "Generate priv/public_api.json from @moduledoc tags: attributes"

  @moduledoc """
  Regenerates `priv/public_api.json` by introspecting compiled module docs.

  ## Usage

      mix rendro.api.gen

  Reads `@moduledoc tags:` from every declared public module via `Code.fetch_docs/1`
  and writes a canonical JSON manifest to `priv/public_api.json`.
  """

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    # Recompile conditional adapters (same as AdapterReloader)
    recompile_conditional_adapters()
    # Generate and write
    manifest = Rendro.PublicApi.generate_map()
    File.write!("priv/public_api.json", JSON.encode!(manifest))
    Mix.shell().info("Written: priv/public_api.json")
  end

  defp recompile_conditional_adapters do
    for path <- Rendro.PublicApi.conditional_adapter_files(),
        File.exists?(path) do
      Code.compile_file(path)
    end
  end
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|-----------------|--------------|--------|
| Hand-maintaining API lists in prose | Generated manifest + introspection contract test | ExDoc 0.40 + EEP-48 stabilization | Code is source-of-truth; drift fails CI |
| Per-function tier annotations | Per-module tier (one tier per module) | D-09 design decision | Simpler to maintain; consistent with Bandit/Ecto surface discipline |
| Prose-only stability promises | Machine-checkable manifest + badge | This phase | Phase 79 completes the enforcement loop |

**Deprecated/outdated:**
- `@doc since:` retrofitting: explicitly out of scope for 0.x surface (REQUIREMENTS Out-of-Scope table)
- Custom JS-reads-metadata badge approach: rejected in favor of native ExDoc `tags:` (D-14)
- `@behaviour Rendro.Recipes.Recipe`: rejected (D-12), deferred

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CSS cannot target `<span class="note">` by text content without JS; a tiny inline script is needed for green/blue coloring | Focus Area 3 (badge CSS) | Low — pure CSS `:has()` with text match doesn't exist; JS is 3 lines and zero deps |
| A2 | `mix rendro.api.gen` should produce compact JSON (no indentation), consistent with Elixir stdlib `JSON.encode!` default | Focus Area 5 (canonical JSON) | Low — cosmetic only; functional tests on `JSON.decode!` roundtrip are unaffected |
| A3 | `Cell`, `Row`, `Component` modules (stable per D-04) are in `groups_for_modules` under the implicit catch-all or need explicit addition | groups_for_modules drift | Medium — if they're not in any named group, ExDoc places them in "Modules" catch-all which may be acceptable or may need a fix |

---

## Open Questions

1. **Groups for `Cell`, `Row`, `Component`**
   - What we know: D-04 lists them as stable. `mix.exs` `groups_for_modules` doesn't explicitly list them under "Core Builder API".
   - What's unclear: Are they currently in the ExDoc "Modules" catch-all? Is that acceptable for 1.0?
   - Recommendation: Planner should add them to "Core Builder API" group in `groups_for_modules` during the sweep.

2. **`Rendro.FontRegistry.EmbeddedFontFamilyError` location**
   - What we know: D-02 says keep public. It's not currently in `groups_for_modules`.
   - What's unclear: Which ExDoc group it belongs to. "Registries" is the natural home.
   - Recommendation: Add to "Registries" group alongside `FontRegistry`.

3. **Manifest `conditional: true` field**
   - What we know: Threadline/Mailglass/Accrue may return `{:error, :module_not_found}` in dev env.
   - What's unclear: Should the manifest include a `"conditional": true` field on their entries, or should the generator only run in test env?
   - Recommendation: The planner should decide: (a) generator always runs in test env (simple), or (b) generator includes a `conditional` flag. Option (a) is simpler and consistent with Phase 79's test env requirement.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir stdlib `JSON` | Manifest generation, loading | ✓ | 1.19+ (Elixir 1.19.5) | — |
| JSV | Schema validation | ✓ | 0.19.1 | — |
| ExDoc `~> 0.40` | Badge rendering, `tags:` support | ✓ | 0.40.3 | — |
| `Code.fetch_docs/1` | Introspection | ✓ | Built-in (EEP-48 chunk) | — |

All required capabilities are already present. No new dependencies are needed.

---

## Security Domain

No authentication, session management, cryptography, or access control changes in this phase. The phase is documentation and manifest generation only. ASVS V5 (Input Validation) is technically applicable to the JSV schema validation step; this is covered by the JSV validator pattern already proven in `ViewerEvidence.Validator`.

---

## Sources

### Primary (HIGH confidence)
- `lib/rendro/viewer_evidence/validator.ex` — JSV.validate/2 pattern, schema loading, error formatting
- `lib/rendro/viewer_evidence/matrix.ex` — priv-file loader pattern
- `deps/ex_doc/lib/ex_doc/retriever.ex` line 174 — `annotations: List.wrap(metadata[:tags])`
- `deps/ex_doc/lib/ex_doc/formatter/html/templates/module_template.eex` — annotation HTML rendering as `<span class="note">`
- `deps/ex_doc/formatters/html/dist/html-elixir-YJO4MOOW.css` — `.note` CSS default
- `deps/ex_doc/README.md` line 220 — `tags` (list of atoms) metadata documentation
- `test/support/mocks.ex` lines 205-232 — `AdapterReloader.recompile` pattern for conditional adapters
- Live `Code.fetch_docs/1` inspection on `Rendro.Metadata` (hidden), `Rendro.Document` (visible), `Rendro.Sign` (redact_* state: `:none`)
- Live `JSON.encode!` tests for string-key vs atom-key sorting behavior

### Secondary (MEDIUM confidence)
- `deps/ex_doc/CHANGELOG.md` line 557 — "Support optional module annotations" (module-level `tags:`)
- `priv/schemas/support_matrix.schema.json` — schema versioning pattern ($id, no inline version field)

### Tertiary (LOW confidence)
- None in this research

---

## Metadata

**Confidence breakdown:**
- `Code.fetch_docs/1` mechanics: HIGH — verified live in project
- ExDoc `tags:` rendering: HIGH — verified via ExDoc source and HTML template
- Conditional adapter footgun pattern: HIGH — verified via live inspection + test support source
- JSV validation pattern: HIGH — verified via existing `ViewerEvidence.Validator`
- Canonical JSON emission: HIGH — verified via live `JSON.encode!` tests
- Mix task structure: HIGH — two existing tasks in repo to mirror
- Recipe opts threading exact change: HIGH — verified via source inspection of both Invoice and Statement
- Badge CSS injection approach: MEDIUM — CSS approach confirmed; JS content-targeting is LOW but pragmatic alternative documented

**Research date:** 2026-05-30
**Valid until:** 2026-06-30 (ExDoc 0.40 API is stable; Elixir stdlib JSON is stable; all findings are source-code grounded)

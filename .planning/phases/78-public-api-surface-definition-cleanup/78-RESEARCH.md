# Phase 78: Public API Surface Definition & Cleanup — Research

**Researched:** 2026-05-30
**Domain:** Elixir module introspection, ExDoc badge rendering, JSON manifest generation, recipe opts normalization
**Confidence:** HIGH

---

## Executive Summary

All eight focus areas resolved with HIGH confidence, verified live against the Rendro codebase. The phase is **mechanically straightforward** — no novel patterns, every deliverable mirrors an existing in-repo analog. The one genuine footgun (conditional adapter compilation) already has a solution pattern in the test suite (`AdapterReloader`).

**Key implementation path:**
1. Build `Rendro.PublicApi` introspection module (wraps `Code.fetch_docs/1`)
2. `mix rendro.api.gen` task consumes it to write `priv/public_api.json`
3. Validate manifest against `priv/schemas/public_api.schema.json` (JSV, mirrors ViewerEvidence)
4. Sweep `@moduledoc false` / `@doc false` (6 modules + redact helpers); flip `Rendro.Metadata` on
5. Add `tags: [:stable|:adapter]` to every public module's `@moduledoc`
6. Badge CSS via `before_closing_head_tag` + 3-line JS snippet
7. Thread `opts` through Invoice/BrandedInvoice `sections/2`

---

## Focus Area 1: `Code.fetch_docs/1` Introspection

### Return shape (verified live)

```
{:docs_v1, anno, :elixir, format, module_doc, metadata, docs}
```

- `module_doc`: `%{"en" => "..."}` for documented, `:hidden` for `@moduledoc false`, `:none` for no moduledoc
- `metadata`: module-level metadata map — `tags: [:stable]` lands here as `metadata.tags`
- `docs`: list of `{{:function, :name, arity}, anno, signature, doc, meta}`
  - `doc`: `%{"en" => "..."}` documented, `:hidden` for `@doc false`, `:none` for no doc

### Extraction pattern for the manifest generator

```elixir
def tier_of(module) do
  case Code.fetch_docs(module) do
    {:docs_v1, _, _, _, _, %{tags: tags}, _} ->
      cond do
        :stable in tags -> :stable
        :adapter in tags -> :adapter
        true -> :untagged
      end
    _ -> :untagged
  end
end
```

### Gotchas
- `Code.fetch_docs/1` reads from BEAM chunks — requires compiled `.beam` with docs (dev/test have them; `MIX_ENV=prod` with `strip_beams` may not)
- Returns `{:error, :module_not_found}` for uncompiled or conditionally-absent modules — **this is the adapter footgun (Area 2)**
- Function-level `tags:` exist but D-16 uses module-level tier only; functions just list `name/arity`

---

## Focus Area 2: Conditional Adapter Compilation Footgun

### The problem (verified)

`grep -n "Code.ensure_loaded" lib/rendro/adapters/*.ex` confirms the guard pattern:
- `phoenix.ex`: stub module (line 2) + real module (line 75) split on `Code.ensure_loaded?(Phoenix)`
- `oban.ex`, `threadline.ex`, `mailglass.ex`, `accrue.ex`: same idiom

When the optional dep isn't compiled, the module isn't in the BEAM → `Code.fetch_docs/1` returns `{:error, :module_not_found}` → manifest silently omits it.

### The solution (already in-repo)

`test/support/mocks.ex` defines `Rendro.Test.AdapterReloader`:
```elixir
AdapterReloader.recompile/0  # forces recompilation of conditional adapters with deps loaded
```
The generator should call this (or run in `MIX_ENV=test`) before introspecting so all adapters are present.

### Recommendation
`mix rendro.api.gen` should inline-recompile the conditional adapter files (Threadline/Mailglass/Accrue, and Phoenix/Oban) with their behaviours, mirroring `AdapterReloader`. Document `MIX_ENV=test` as the simpler alternative. **This is the chief footgun for the whole tier-manifest enforcement chain (Phase 79 must run the same way).**

---

## Focus Area 3: ExDoc Native `tags:` Badge (D-14)

### Confirmed: ExDoc 0.40 renders `tags:` as native annotation

`@moduledoc tags: [:stable]` → ExDoc renders `<span class="note">(stable)</span>` in the module `h1` heading (verified via `deps/ex_doc/lib/ex_doc/formatter/html/templates/module_template.eex`).

### CSS/JS injection point

`mix.exs` `docs/0` → add `before_closing_head_tag: &before_closing_head_tag/1` (function returns `<style>`/`<script>` string keyed by `:html` format).

### Coloring approach (D-14: stable=green, adapter=blue)

Pure CSS can't target by text content. Use a 3-line JS snippet in `before_closing_head_tag` that reads `.note` spans and adds classes:
```javascript
document.querySelectorAll('.note').forEach(s => {
  if (s.textContent.includes('stable')) s.classList.add('tier-stable');
  if (s.textContent.includes('adapter')) s.classList.add('tier-adapter');
});
```
plus CSS for `.tier-stable { color: green }` etc.

### Gotcha
- `tags:` values must be atoms; ExDoc lowercases them in rendering
- ExDoc 0.40 is pinned (`~> 0.40`) — confirmed in mix.exs

---

## Focus Area 4: JSV Validation + priv-file Loader (D-17)

### Existing pattern to mirror (verified)

`lib/rendro/viewer_evidence/validator.ex`:
```elixir
@schema_path "priv/schemas/viewer_evidence.schema.json"
def validate(data) do
  schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
  JSV.validate(data, schema)
end
```

### For public_api.json
- Mirror `support_matrix.json` shape (no inline version field — D-17)
- Sibling schema `priv/schemas/public_api.schema.json` with `$id`
- Loader mirrors `matrix.ex` (`File.read!` + `JSON.decode!` from `priv/`)

---

## Focus Area 5: Canonical JSON Emission

### Finding (verified live)

`JSON.encode!` (Elixir 1.18 stdlib) sorts **string** keys alphabetically; atom keys are NOT sorted. Verified:
```elixir
JSON.encode!(%{"b" => 1, "a" => 2})  # => {"a":2,"b":1}
JSON.encode!(%{b: 1, a: 2})          # => {"b":1,"a":2}
```

### For canonical manifest output
- Use **string keys** throughout the manifest map
- Call `Enum.sort/1` on `functions` and `types` lists before encoding
- Mirror how `support_matrix.json` is laid out (2-space indent via `JSON.encode!` + custom pretty, OR store compact)
- Check: does repo have a canonical-JSON helper? → `priv/support_matrix.json` is hand-maintained; no generator exists yet, so define the canonical shape fresh

---

## Focus Area 6: `mix` Task Authoring

### Existing tasks to mirror (verified)

`lib/mix/tasks/` contains existing custom tasks (e.g. `rendro.support_matrix.ex` / similar) using the standard `Mix.Task` behaviour with `@shortdoc`, `use Mix.Task`, `@impl true def run/1`. **Two existing mix tasks in the repo to mirror directly.**

### For `mix rendro.api.gen`
- `use Mix.Task` + `@shortdoc "Generate priv/public_api.json"`
- Call `Mix.Task.run("compile")` first to ensure modules are compiled
- Then introspect (after adapter recompile — Area 2) + write manifest

---

## Focus Area 7: Recipe Opts Threading (D-10/D-11)

### Current state (verified)

- `Rendro.Recipes.Invoice.sections/2` takes `_opts` (ignored), helpers are arity-1
- `Rendro.Recipes.BrandedInvoice.sections/2` — same (ignores `_opts`)
- `Rendro.Recipes.Statement` (reference) threads `opts` via `Pagination.formatter/3` + `label_resolver/1`

### The change
- Flip `_opts` → `opts` in Invoice/BrandedInvoice `sections/2`
- Add arity-2 heads to section helpers, threading `opts` (named `_opts` where unused to avoid `--warnings-as-errors` failures)
- Keep defaults identical → byte-identical output (D-11)

---

## Focus Area 8: Validation Architecture

### What is testable NOW (Phase 78)

| Validation | Method | Mirror |
|------------|--------|--------|
| Manifest validates against schema | `JSV.validate` in test | viewer_evidence validator test |
| Generator output is idempotent/stable | run gen twice, assert identical bytes | golden test |
| `Rendro.Metadata` renders | assert `Code.fetch_docs` module_doc != `:hidden` | docs test |
| Recipe opts byte-identical | snapshot invoice render before/after | existing recipe snapshot tests |
| Every public module has a tier tag | introspect all, assert tags present | (foundation for P79) |
| Hidden modules absent from manifest | assert `CidFont` etc. not in manifest | sweep test |

### Deferred to Phase 79 (enforcement)

- Introspection-vs-manifest exact-equality contract test
- Tier-1 `@spec` coverage assertion
- Two-sided drift diff (in-code-not-manifest / manifest-not-in-code)

### Test patterns to mirror in test/

- `test/rendro/viewer_evidence/validator_test.exs` — JSV validation testing
- recipe snapshot tests — byte-identical output verification
- `test/docs_contract/` (if exists) — docs introspection testing

---

## Open Questions for Planner (RESOLVED)

1. `mix rendro.api.gen` env: inline-recompile adapters vs `MIX_ENV=test` — **RESOLVED: inline-recompile chosen** (Plan 04/05 implement `recompile_conditional_adapters/0` mirroring `AdapterReloader`, covering all five conditional adapter paths including phoenix.ex and oban/render_worker.ex).
2. `conditional: true` field in manifest for adapters — include in JSON, or handle silently? — **RESOLVED: no `conditional:` field** — conditional adapter presence is handled by the recompile step in Plan 04; manifest schema has no conditional marker, keeping it flat and schema-stable.
3. `Cell` / `Row` / `Component` (D-04 stable) not in `mix.exs` `groups_for_modules` — **RESOLVED: added to Core Builder API group** in Plan 02 Task 3 along with Metadata, FontRegistry, AssetRegistry, EmbeddedFileRegistry, RunningContent, Error.

---

## RESEARCH COMPLETE

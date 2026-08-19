# Phase 128: Static configurator, theme codegen & Livebook - Pattern Map

**Mapped:** 2026-08-18  
**Files analyzed:** 13  
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/theme/snippet.ex` | utility | transform | `lib/rendro/theme/presets.ex` | role-match |
| `lib/mix/tasks/rendro/gen/theme.ex` | config | request-response / file-I/O | `lib/mix/tasks/brand.gen.ex` | role-match |
| `dev/mix/tasks/rendro/configurator/gen.ex` | config | batch / file-I/O | `dev/mix/tasks/rendro/catalog/gen.ex` | exact |
| `assets/rendro/configurator/index.html` | component | request-response | `guides/recipes.md` | partial-match |
| `assets/rendro/configurator/configurator.css` | component | transform | `brand/tokens/tokens.css` | role-match |
| `assets/rendro/configurator/configurator.js` | utility | event-driven / request-response | `mix.exs` | partial-match |
| `assets/rendro/configurator/index.json` | config | batch / transform | `assets/rendro/catalog.json` | exact |
| `test/rendro/theme/snippet_test.exs` | test | transform | `test/rendro/theme/presets_test.exs` | role-match |
| `test/mix/tasks/rendro_gen_theme_test.exs` | test | file-I/O / request-response | `test/mix/tasks/rendro_livebook_check_test.exs` | role-match |
| `test/docs_contract/configurator_static_contract_test.exs` | test | request-response | `test/docs_contract/catalog_manifest_contract_test.exs` | role-match |
| `test/docs_contract/configurator_resolver_contract_test.exs` | test | transform | `test/docs_contract/catalog_manifest_contract_test.exs` | partial-match |
| `guides/livebook/first_invoice.livemd` | component | batch / transform | its existing baseline render section | exact (modify in place) |
| `test/mix/tasks/rendro_livebook_check_test.exs` | test | request-response | same file | exact (modify in place) |

`mix.exs` is intentionally **not** a Phase-128 modification: its ExDoc configuration already copies all of `assets/` (lines 153-157), and its package allowlist deliberately excludes the catalog/configurator tree (lines 128-150).

## Pattern Assignments

### `lib/rendro/theme/snippet.ex` (utility, transform)

**Analog:** `lib/rendro/theme/presets.ex`

Keep this packaged module pure and private (`@moduledoc false`), expose only formatter/index functions that consume already-validated closed values, and make all consumers compose its output. Do not add family/preset policy to `Rendro.Theme`; that public facade delegates policy to `Presets`.

**Validation and construction pattern** — `lib/rendro/theme/presets.ex:17-45`:

```elixir
@spec preset(atom(), keyword()) :: Theme.t()
def preset(genre, opts) do
  validate_genre!(genre)
  validate_options!(opts)

  accent = Keyword.fetch!(opts, :accent) |> validate_color!(:accent)
  mode = Keyword.get(opts, :mode, :light) |> validate_mode!()
  # construct from validated, canonical values only
end
```

**Closed vocabulary + explicit font bridge** — `lib/rendro/theme/presets.ex:6-7,47-54`:

```elixir
@canonical_genres [:swiss, :humanist, :editorial, :corporate_classic, :minimal_mono, :brutalist]

@spec register_fonts(Document.t(), atom()) :: Document.t()
def register_fonts(%Document{} = document, genre) do
  validate_genre!(genre)
  genre |> font_roles() |> Enum.reduce(document, &register_font(&2, &1))
end
```

Use the source formatter to serialize strict atoms, RGB tuples, and modes, then compose `usage_snippet/4` with the family recipe and `register_fonts(preset)`. The index generator, Mix module source, and Livebook block must consume these outputs instead of formatting their own Elixir.

---

### `lib/mix/tasks/rendro/gen/theme.ex` (config, request-response/file-I/O)

**Analog:** `lib/mix/tasks/brand.gen.ex`, supplemented by `lib/mix/tasks/rendro/livebook/check.ex`

Use `Mix.Task`, `@shortdoc`, a clear `@moduledoc`, explicit argument parsing, `Mix.shell()` success/error messaging, and shutdown exit on operational failure. Unlike the repo-owned brand writer, the theme task must use `Mix.Generator.create_file/3` for normal writes and must never call it in `--check` mode.

**Read-only drift check** — `lib/mix/tasks/brand.gen.ex:28-56`:

```elixir
if check? do
  drift =
    Enum.filter(outputs, fn {path, content} ->
      case File.read(path) do
        {:ok, existing} -> existing != content
        _ -> true
      end
    end)

  if drift == [], do: Mix.shell().info("... OK ..."),
  else: Mix.raise("... STALE — run `mix ...`")
else
  Enum.each(outputs, fn {path, content} -> File.write!(path, content) end)
end
```

Adapt the check branch to one derived source byte string and a single output path. In normal mode replace the final direct write with `Mix.Generator.create_file(out_path, source, format_elixir: true, force: force?)` so unchanged content is idempotent and changed content follows normal Mix conflict behavior.

**Task error boundary** — `lib/mix/tasks/rendro/livebook/check.ex:20-33`:

```elixir
case check(notebook_path) do
  {:ok, output} -> Mix.shell().info(output)
  {:error, message} ->
    Mix.shell().error(message)
    exit({:shutdown, 1})
end
```

Validate flags, extra positionals, aliases, paths, strict colors, and presets *before* source generation. Report failures as what/where/why/next messages with the normalized rerun command; do not create atoms from user strings.

---

### `dev/mix/tasks/rendro/configurator/gen.ex` (config, batch/file-I/O)

**Analog:** `dev/mix/tasks/rendro/catalog/gen.ex:1-30`

Copy the narrow dev-only task shape: start the app, delegate all generation to one module, and reject remaining/invalid flags centrally.

```elixir
use Mix.Task

@moduledoc false
@shortdoc "Generate bounded Rendro catalog artifacts"

@impl Mix.Task
def run(args) do
  Mix.Task.run("app.start")

  case Rendro.Catalog.generate(parse_opts(args)) do
    :ok -> Mix.shell().info("Generated #{Rendro.Catalog.manifest_path()}")
    {:error, reason} ->
      Mix.shell().error("Catalog generation failed: #{inspect(reason)}")
      exit({:shutdown, 1})
  end
end
```

The configurator task should call `Rendro.Theme.Snippet` to generate the committed JSON; no JavaScript-generated source and no dependency addition.

---

### `assets/rendro/configurator/index.json` (config, batch/transform)

**Analog:** `dev/rendro/catalog.ex` and `assets/rendro/catalog.json`

Match the versioned, deterministic manifest strategy but keep preview evidence out of this file.

**Schema/version and ordered record construction** — `dev/rendro/catalog.ex:4-14,84-106`:

```elixir
@schema_version 1
@generated_by "mix rendro.catalog.gen"

@spec catalog_specs() :: [map()]
def catalog_specs do
  Enum.map(@catalog_specs, fn {family, brand, preset, mode, fixture_ref, accent, preset_atom} ->
    %{id: id, family: family, preset: preset, accent: accent, mode: mode}
  end)
end
```

**Manifest envelope + stable encoding** — `dev/rendro/catalog.ex:356-370,706-707`:

```elixir
%{
  "schema_version" => @schema_version,
  "generated_by" => @generated_by,
  "cells" => cells
}

Jason.encode!(manifest, pretty: true)
```

Use an `index`/`records` payload rather than `cells` if clearer, but retain explicit schema version, generation command, deterministic ordered 504 records, and option labels/values. `assets/rendro/catalog.json` remains the sole source for PNG identity, hashes, dimensions, captions, and boundary disclosures.

---

### `assets/rendro/configurator/index.html` (component, request-response)

**Analog:** `guides/recipes.md` static asset embedding and the locked UI contract

Follow the project’s static-doc asset topology (`guides/recipes.md:19-28` links a local image with concrete `src` and `alt`) while implementing the UI-SPEC’s semantic shell: `<form>`, four labeled `<select>` elements, preview/output region, visible `<pre><code>`, native button, and live status element. Scripts populate content after manifest/index validation; never interpolate query or manifest text into markup.

---

### `assets/rendro/configurator/configurator.css` (component, transform)

**Analog:** `brand/tokens/tokens.css`

Consume existing custom properties only; preserve its OS-default plus explicit override behavior and reduced-motion override.

**Chrome theme precedence** — `brand/tokens/tokens.css:137-215`:

```css
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    /* dark semantic tokens */
  }
}

/* Explicit opt-in always wins over the OS preference. */
[data-theme="dark"] {
  /* dark semantic tokens */
}

@media (prefers-reduced-motion: reduce) {
  :root { --rendro-motion-micro: 0ms; }
}
```

Use `--rendro-grid-app-max`, `--rendro-space-*`, colors, radius, typography, focus, and motion tokens; do not duplicate raw token values. The document mode selector must not change root chrome theme.

---

### `assets/rendro/configurator/configurator.js` (utility, event-driven/request-response)

**Analog:** `mix.exs:300-304` (small, static documentation script) and `dev/rendro/catalog.ex:282-289` (safe-input boundary)

The only current browser code is inline documentation enhancement, so this is a partial match; use its plain browser API level, but do not inherit text-based `includes` behavior for untrusted values.

```javascript
document.querySelectorAll('.sidebar .tier-tag').forEach(s => {
  if (s.textContent.includes('stable')) s.classList.add('tier-stable');
  if (s.textContent.includes('adapter')) s.classList.add('tier-adapter');
});
```

**Safe path precedent** — `dev/rendro/catalog.ex:282-293`:

```elixir
defp validate_safe_path!(path, label) when is_binary(path) do
  case Path.safe_relative(path) do
    {:ok, _safe} -> :ok
    :error -> raise ArgumentError, "unsafe catalog #{label} path rejected: #{inspect(path)}"
  end
end
```

Implement browser equivalents with closed-enum checks and safe relative asset-path checks before assigning `src`, `alt`, `value`, or `textContent`. Parse all four query values atomically with `URLSearchParams.getAll`, reject duplicates/malformed/unknown values, fall back to the first selectable manifest row, then canonically serialize exactly the four values with `URLSearchParams` + `history.replaceState`. Resolver is a pure `exact | representative | none` function that scans manifest order; it never mutates requested selection or performs fuzzy matching. Construct DOM nodes and assign `textContent`/safe attributes only—never `innerHTML`.

---

### `test/rendro/theme/snippet_test.exs` (test, transform)

**Analog:** `test/rendro/theme/presets_test.exs`, supplemented by `test/rendro/catalog_test.exs`

Use one async ExUnit module and assert locked ordering/closed counts, deterministic repeated output, and boundary errors. The catalog test provides the exact exhaustive-registry style.

**Exhaustive closed-vocabulary loop** — `test/rendro/theme/presets_test.exs:121-149`:

```elixir
test "materializes every canonical genre as the D-10 literal contract" do
  Enum.each(@preset_contracts, fn {genre, expected} ->
    theme = Theme.preset(genre, accent: "#2C6BED")
    assert theme.typography.fonts == expected.fonts
  end)
end
```

**Ordered closed registry proof** — `test/rendro/catalog_test.exs:35-76`:

```elixir
specs = Catalog.catalog_specs()
assert Enum.map(specs, & &1.id) == expected_ids
assert length(specs) == 32
assert Catalog.catalog_contract_errors(specs) == []
```

For all 504 selections assert formatter string equals its committed index entry, `Code.string_to_quoted!/1` parses it, and trusted formatter output evaluates in a controlled family-data binding. Add representative renders only to prove the recipe/font transform—not as a claim that every 504 selection was visually reviewed.

---

### `test/mix/tasks/rendro_gen_theme_test.exs` (test, file-I/O/request-response)

**Analog:** `test/mix/tasks/rendro_livebook_check_test.exs`

Copy its `async: false` setup/teardown discipline for global Mix and application state, shell capture helper, and exit assertions.

**Global-state cleanup and task reset** — `test/mix/tasks/rendro_livebook_check_test.exs:1-18`:

```elixir
use ExUnit.Case, async: false

setup do
  Mix.Task.reenable("rendro.livebook.check")
  on_exit(fn -> Mix.Task.reenable("rendro.livebook.check") end)
  :ok
end
```

Exercise default/override module and path derivation, strict CLI rejection, source formatting stability, compiled generated module equivalence, conflict/force behavior, and missing/different/equal `--check` without filesystem mutation in the check cases.

---

### `test/docs_contract/configurator_static_contract_test.exs` and `test/docs_contract/configurator_resolver_contract_test.exs` (test, request-response/transform)

**Analog:** `test/docs_contract/catalog_manifest_contract_test.exs`

Keep static docs policy executable with literal fixture maps, direct source reads, and precise field/error assertions.

**Consumer-facing fixture schema** — `test/docs_contract/catalog_manifest_contract_test.exs:8-49`:

```elixir
defp cell(spec, overrides \\ %{}) do
  %{ "id" => spec.id, "family" => Atom.to_string(spec.family),
     "preset" => spec.preset, "accent" => spec.accent, "mode" => spec.mode }
  |> Map.merge(overrides)
end
```

**Truth-boundary assertion** — `test/docs_contract/catalog_manifest_contract_test.exs:82-99`:

```elixir
dark_errors = Catalog.manifest_shape_errors(manifest([cell(dark, %{"boundary_disclosure" => nil})]))
assert Enum.any?(dark_errors, &String.contains?(&1, "#{dark.id}: dark boundary_disclosure"))
```

Static tests should read HTML/CSS/JS/index source and assert static-only topology, tokens, semantic controls, no framework/build/server, no unsafe DOM APIs, and factual boundary copy. Resolver tests should use synthetic ordered catalog values to assert exact, first representative, none, cross-dimension prohibition, atomic fallback, and canonical URL behavior.

---

### `guides/livebook/first_invoice.livemd` and `test/mix/tasks/rendro_livebook_check_test.exs` (component/test, batch/transform)

**Analog:** the existing baseline render and checker tests.

Insert one `Apply a preset` section immediately after the baseline render (before existing Preview), reuse the existing document data, and keep separate themed bytes/evidence/preview/download variables so the original baseline remains intact.

**Baseline deterministic evidence shape** — `guides/livebook/first_invoice.livemd:55-70`:

```elixir
doc = Rendro.Recipes.Invoice.document(invoice)
{:ok, pdf} = Rendro.render(doc, deterministic: true)

if binary_part(pdf, 0, 5) != "%PDF-" do
  raise "expected Rendro to render a PDF"
end

sha256 = :crypto.hash(:sha256, pdf) |> Base.encode16(case: :lower)
```

**No-server execution contract** — `lib/mix/tasks/rendro/livebook/check.ex:36-42,73-96`:

```elixir
with {:ok, markdown} <- read_notebook(notebook_path),
     {:ok, elixir_source} <- convert_notebook(markdown),
     {:ok, output} <- run_script(elixir_source) do
  {:ok, String.trim("Livebook tutorial VERIFIED\n#{output}")}
end
```

Extend the existing test’s production-notebook assertions (`test/mix/tasks/rendro_livebook_check_test.exs:77-93`) to extract the canonical block and compare it byte-for-byte with `Rendro.Theme.Snippet.usage_snippet/4`; assert one themed render/evidence/preview/download and exclusions for `Kino.Input`, `Kino.JS`, catalog fetches, and server startup.

## Shared Patterns

### Closed vocabulary, explicit font registration, and no dynamic atoms

**Sources:** `lib/rendro/theme/presets.ex:6-7,17-54`; `dev/rendro/catalog.ex:309-323`  
**Apply to:** formatter, Mix task, index generator, generated module, Livebook, and browser validation.

```elixir
defp theme_for(%{preset_atom: preset, accent: accent, mode: mode}),
  do: Rendro.Theme.preset(preset, accent: accent, mode: catalog_mode!(mode))

defp recipe_module(:invoice), do: Rendro.Recipes.Invoice
defp recipe_module(:statement), do: Rendro.Recipes.Statement
```

Keep explicit finite mappings. Do not turn URL/CLI input into atoms; browser values are strings validated against index enums, while Elixir serialization maps only trusted closed values to canonical atoms.

### Deterministic generated artifacts and read-only drift gates

**Sources:** `lib/mix/tasks/brand.gen.ex:28-56`; `dev/rendro/catalog.ex:356-370,706-707`  
**Apply to:** index generator, committed index, and `mix rendro.gen.theme --check`.

Build exact bytes once from the formatter. Generation writes formatted bytes; checks only compare derived bytes with `File.read/1` and report a normalized rerun command. The task must not prompt or write in `--check` mode.

### Static docs asset and package boundary

**Sources:** `mix.exs:128-157`; `test/docs_contract/catalog_manifest_contract_test.exs:102-108`  
**Apply to:** configurator assets and docs-contract tests.

```elixir
assets: %{"assets" => "assets"}

refute "assets/rendro" in package_files
```

ExDoc already copies static assets. Do not broaden the Hex package allowlist merely to host a documentation configurator.

### Error language and operational exits

**Sources:** `lib/mix/tasks/rendro/livebook/check.ex:26-33,48-59`; `dev/mix/tasks/rendro/catalog/check.ex:9-18`  
**Apply to:** packaged and dev Mix tasks, plus static UI error state.

Return actionable messages with the failed resource and recovery command/action. Mix tasks print errors and exit non-zero; browser errors retain safe static text and disable controls/copy only when manifest/index validity is unavailable.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | — | — | There is no existing full configurator, but each new static surface has a nearest project seam above; the locked UI-SPEC and RESEARCH.md provide the behavior-specific contract. |

## Metadata

**Analog search scope:** `lib/rendro`, `lib/mix/tasks`, `dev/mix/tasks`, `dev/rendro`, `assets/rendro`, `brand/tokens`, `guides/livebook`, `test/rendro`, `test/mix/tasks`, `test/docs_contract`, `mix.exs`  
**Files scanned:** 18  
**Pattern extraction date:** 2026-08-18

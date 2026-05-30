# Phase 78: Public API Surface Definition & Cleanup — Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 14 new/modified files
**Analogs found:** 13 / 14 (1 has no in-repo analog — see No Analog Found section)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/public_api.ex` (NEW) | utility/introspection | transform | `lib/rendro/viewer_evidence/matrix.ex` | role-match |
| `lib/mix/tasks/rendro/api.gen.ex` (NEW) | mix task | transform / file-I/O | `lib/mix/tasks/rendro/viewer_evidence.ex` | exact |
| `priv/public_api.json` (NEW) | data file | — | `priv/support_matrix.json` | exact |
| `priv/schemas/public_api.schema.json` (NEW) | config/schema | — | `priv/schemas/support_matrix.schema.json` | exact |
| `lib/rendro/public_api/loader.ex` (NEW) | utility | file-I/O | `lib/rendro/viewer_evidence/matrix.ex` | exact |
| `lib/rendro/public_api/validator.ex` (NEW) | utility | transform | `lib/rendro/viewer_evidence/validator.ex` | exact |
| `lib/rendro/metadata.ex` (MODIFIED) | model | — | `lib/rendro/error.ex` | role-match |
| `mix.exs` `docs/0` (MODIFIED) | config | — | existing `docs/0` in `mix.exs` | exact |
| `lib/rendro/audit.ex` (MODIFIED — `@moduledoc false`) | behaviour | — | `lib/rendro/pdf/cid_font.ex` (same pattern) | exact |
| `lib/rendro/format.ex` (MODIFIED — `@moduledoc false`) | utility | — | same | exact |
| `lib/rendro/pdf/cid_font.ex` + `font_subsetter.ex`, `lib/rendro/text/bidi.ex` + `shaper.ex` (MODIFIED — already `@moduledoc false` or pending) | utility/engine | — | `lib/rendro/viewer_evidence/frontmatter.ex` | exact |
| `lib/rendro/sign.ex` (MODIFIED — `@doc false` sweep) | facade | request-response | existing `@doc false` usages in codebase | exact |
| `lib/rendro/protect.ex` (MODIFIED — `@doc false` sweep) | facade | request-response | same | exact |
| `lib/rendro/recipes/invoice.ex` + `branded_invoice.ex` (MODIFIED — opts threading) | service/recipe | request-response | `lib/rendro/recipes/statement.ex` | exact |

---

## Pattern Assignments

---

### `lib/rendro/public_api.ex` (NEW — utility, transform)

**Analog:** `lib/rendro/viewer_evidence/matrix.ex`

**Imports / module skeleton** (mirrors matrix.ex lines 1–5):
```elixir
defmodule Rendro.PublicApi do
  @moduledoc false
  # Internal introspection module — consumed by mix rendro.api.gen and Phase 79 contract test.
  # Do NOT call from application code.
```

**Core introspection pattern** (adapted from RESEARCH.md Focus Area 1 — no existing in-repo analog for `Code.fetch_docs/1` wrapping, but this is the exact shape to use):
```elixir
@spec tier_of(module()) :: :stable | :adapter | :untagged
def tier_of(module) do
  case Code.fetch_docs(module) do
    {:docs_v1, _, _, _, _, %{tags: tags}, _} ->
      cond do
        :stable in tags -> :stable
        :adapter in tags -> :adapter
        true -> :untagged
      end
    _ ->
      :untagged
  end
end

@spec public_functions(module()) :: [String.t()]
def public_functions(module) do
  case Code.fetch_docs(module) do
    {:docs_v1, _, _, _, _, _, docs} ->
      docs
      |> Enum.filter(fn
        {{:function, _name, _arity}, _anno, _sig, doc, _meta} ->
          doc != :hidden and doc != :none
        _ ->
          false
      end)
      |> Enum.map(fn {{:function, name, arity}, _, _, _, _} ->
        "#{name}/#{arity}"
      end)
      |> Enum.sort()
    _ ->
      []
  end
end

@spec public_types(module()) :: [String.t()]
def public_types(module) do
  case Code.fetch_docs(module) do
    {:docs_v1, _, _, _, _, _, docs} ->
      docs
      |> Enum.filter(fn
        {{:type, _name, _arity}, _anno, _sig, doc, _meta} ->
          doc != :hidden
        _ ->
          false
      end)
      |> Enum.map(fn {{:type, name, arity}, _, _, _, _} ->
        "#{name}/#{arity}"
      end)
      |> Enum.sort()
    _ ->
      []
  end
end
```

**Adapter footgun handling** — mirror `test/support/mocks.ex` `AdapterReloader.recompile/0` (lines 221–231):
```elixir
@adapter_files [
  "lib/rendro/adapters/threadline.ex",
  "lib/rendro/adapters/mailglass.ex",
  "lib/rendro/adapters/accrue.ex"
]

def recompile_conditional_adapters do
  project_root = File.cwd!()

  for relative <- @adapter_files,
      path = Path.join(project_root, relative),
      File.exists?(path) do
    Code.compile_file(path)
  end

  :ok
end
```

**Canonical JSON output** (use string keys + Enum.sort/1; from RESEARCH.md Focus Area 5):
```elixir
# Use string keys throughout — JSON.encode! sorts string keys alphabetically.
# Atom keys are NOT sorted. Always Enum.sort/1 on functions/types lists.
def build_manifest(modules) do
  module_entries =
    modules
    |> Enum.map(fn mod ->
      {inspect(mod),
       %{
         "tier" => to_string(tier_of(mod)),
         "functions" => public_functions(mod),
         "types" => public_types(mod)
       }}
    end)
    |> Enum.sort_by(fn {name, _} -> name end)
    |> Map.new()

  %{"modules" => module_entries}
end
```

---

### `lib/mix/tasks/rendro/api.gen.ex` (NEW — mix task, transform / file-I/O)

**Analog:** `lib/mix/tasks/rendro/viewer_evidence.ex`

**Module skeleton** (lines 1–10 of viewer_evidence.ex):
```elixir
defmodule Mix.Tasks.Rendro.Api.Gen do
  use Mix.Task

  @shortdoc "Generate priv/public_api.json from @moduledoc tags: in source"

  @moduledoc """
  Introspects all public Rendro modules for their `tags: [:stable|:adapter]`
  annotation and writes `priv/public_api.json`.

  ...
  """
```

**`@impl` + `run/1` entry point** (mirrors viewer_evidence.ex lines 76–99):
```elixir
  @manifest_path "priv/public_api.json"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("compile")
    Rendro.PublicApi.recompile_conditional_adapters()

    manifest = Rendro.PublicApi.build_manifest(public_modules())
    json = JSON.encode!(manifest, pretty: true)
    File.write!(@manifest_path, json)
    Mix.shell().info("Wrote #{@manifest_path}")
  end
```

**Error / exit pattern** (mirrors viewer_evidence.ex lines 408–416):
```elixir
  defp usage_error!(message) do
    Mix.shell().error(message)
    exit({:shutdown, 1})
  end
```

**Output via Mix.shell** (mirrors viewer_evidence.ex lines 118–119, 126–128):
```elixir
    Mix.shell().info("Wrote #{@manifest_path}")
    # errors:
    Mix.shell().error("Generation failed: #{inspect(reason)}")
    exit({:shutdown, 1})
```

---

### `priv/public_api.json` (NEW — data file)

**Analog:** `priv/support_matrix.json` (lines 1–10 shape):

Top-level shape — use string keys, two-space indent (match `support_matrix.json` formatting):
```json
{
  "modules": {
    "Elixir.Rendro": {
      "tier": "stable",
      "functions": ["metadata/1", "render/1", "render/2"],
      "types": []
    },
    "Elixir.Rendro.Document": {
      "tier": "stable",
      "functions": ["add_section/2", "add_template/2", "new/0", "set_template/2"],
      "types": ["t/0"]
    }
  }
}
```

Key constraints from D-16 and D-17:
- No inline `schema_version` field (D-17 — do NOT add one; `support_matrix.json` has none)
- Module keys are `inspect(Module)` strings (e.g. `"Elixir.Rendro"`)
- `"functions"` and `"types"` lists are sorted (`Enum.sort/1` before `JSON.encode!`)
- Generated file — never hand-edited after initial authoring

---

### `priv/schemas/public_api.schema.json` (NEW — JSON Schema)

**Analog:** `priv/schemas/support_matrix.schema.json` (full file)

**Required top-level shape** (mirror `$schema`, `$id`, `title`, `description` from support_matrix.schema.json lines 1–8):
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "public_api.schema.json",
  "title": "Rendro Public API Manifest",
  "description": "Structural contract for priv/public_api.json module surface entries.",
  "type": "object",
  "required": ["modules"],
  "properties": {
    "modules": {
      "type": "object",
      "additionalProperties": { "$ref": "#/$defs/module_entry" }
    }
  },
  "additionalProperties": false,
  "$defs": {
    "module_entry": {
      "type": "object",
      "required": ["tier", "functions", "types"],
      "additionalProperties": false,
      "properties": {
        "tier": {
          "type": "string",
          "enum": ["stable", "adapter"]
        },
        "functions": {
          "type": "array",
          "items": { "type": "string", "pattern": "^[a-z_][a-z0-9_?!]*/[0-9]+$" },
          "uniqueItems": true
        },
        "types": {
          "type": "array",
          "items": { "type": "string", "pattern": "^[a-z_][a-z0-9_]*/[0-9]+$" },
          "uniqueItems": true
        }
      }
    }
  }
}
```

Constraints: `$id` = `"public_api.schema.json"` (no URL prefix, mirrors support_matrix.schema.json line 3). No `schema_version` const.

---

### `lib/rendro/public_api/loader.ex` (NEW — utility, file-I/O)

**Analog:** `lib/rendro/viewer_evidence/matrix.ex` (lines 1–39)

**Pattern to copy exactly:**
```elixir
defmodule Rendro.PublicApi.Loader do
  @moduledoc false

  @manifest_path "priv/public_api.json"

  @spec load!() :: map()
  def load! do
    @manifest_path |> File.read!() |> JSON.decode!()
  end
end
```

Mirror: `matrix.ex` lines 4–5 (`@matrix_path`) and lines 37–39 (`def load!`). Keep `@moduledoc false` — this is an internal loader, not user-facing.

---

### `lib/rendro/public_api/validator.ex` (NEW — utility, transform)

**Analog:** `lib/rendro/viewer_evidence/validator.ex`

**JSV validation pattern** (validator.ex lines 18–33, 383–387):
```elixir
defmodule Rendro.PublicApi.Validator do
  @moduledoc false

  @schema_path "priv/schemas/public_api.schema.json"

  @spec validate(map()) :: :ok | {:error, String.t()}
  def validate(manifest) do
    schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()

    case JSV.validate(manifest, schema) do
      {:ok, _} -> :ok
      {:error, err} -> {:error, format_jsv_error(err)}
    end
  end

  defp format_jsv_error(err) do
    err
    |> JSV.normalize_error()
    |> inspect(limit: :infinity)
  end
end
```

Note: mirror `validator.ex` lines 383–387 exactly for `format_jsv_error/1` — do not invent a different shape.

---

### `lib/rendro/metadata.ex` (MODIFIED — flip `@moduledoc false` → real moduledoc)

**Analog:** `lib/rendro/error.ex` (lines 1–7 — real `@moduledoc` on a simple struct module)

**Before** (metadata.ex line 2, current state):
```elixir
  @moduledoc false
```

**After** — add `tags: [:stable]` and a real docstring. Pattern from `error.ex` lines 1–7:
```elixir
defmodule Rendro.Metadata do
  @moduledoc """
  Input metadata for a rendered PDF document.

  Passed to `Rendro.metadata/1` to set title, author, creator, and custom
  key-value pairs in the PDF document info dictionary. All fields are optional.

  The `custom` field accepts an open map of `atom() => term()` pairs (additive
  contract — new keys may be added by the caller without version friction).
  """
  tags: [:stable]
```

Keep the existing `@type t` (line 14) and `defstruct` (lines 4–12) unchanged.

---

### `mix.exs` `docs/0` (MODIFIED — add badge CSS/JS + reconcile `groups_for_modules`)

**Analog:** existing `docs/0` in `mix.exs` (lines 93–182)

**Add `before_closing_head_tag` key** after `main: "readme"` (line 95):
```elixir
defp docs do
  [
    main: "readme",
    before_closing_head_tag: &before_closing_head_tag/1,
    # ... rest unchanged
  ]
end

defp before_closing_head_tag(:html) do
  """
  <style>
    .note.tier-stable { background-color: #d4edda; color: #155724; border-color: #c3e6cb; }
    .note.tier-adapter { background-color: #cce5ff; color: #004085; border-color: #b8daff; }
  </style>
  <script>
    document.querySelectorAll('.note').forEach(function(s) {
      if (s.textContent.includes('stable')) s.classList.add('tier-stable');
      if (s.textContent.includes('adapter')) s.classList.add('tier-adapter');
    });
  </script>
  """
end

defp before_closing_head_tag(_), do: ""
```

**`groups_for_modules` additions** — add missing stable-tier modules to existing groups (mix.exs lines 132–180). Planner should add these to the `"Core Builder API"` group:
```elixir
"Core Builder API": [
  Rendro,
  Rendro.Document,
  Rendro.PageTemplate,
  Rendro.Section,
  Rendro.Block,
  Rendro.Region,
  Rendro.Text,
  Rendro.Table,
  Rendro.Image,
  Rendro.Page,
  # ADD (D-04 stable, currently ungrouped):
  Rendro.Cell,
  Rendro.Row,
  Rendro.Component,
  Rendro.Metadata,
  Rendro.FontRegistry,
  Rendro.AssetRegistry,
  Rendro.EmbeddedFileRegistry,
  Rendro.RunningContent,
  Rendro.Error
],
```

Reconcile `"Signing"` group: move `Rendro.Adapters.PyHanko` and `Rendro.Adapters.Pdfsig` into `"Ecosystem Adapters"` (they are adapters, not signing facades).

---

### `lib/rendro/audit.ex`, `lib/rendro/format.ex` (MODIFIED — add `@moduledoc false`)

**Analog:** Pattern already exists throughout codebase (e.g. `lib/rendro/viewer_evidence/matrix.ex` line 2, `lib/rendro/viewer_evidence/validator.ex` line 2)

**Pattern** — replace the existing real `@moduledoc """..."""` with:
```elixir
  @moduledoc false
```

Both `audit.ex` (line 2) and `format.ex` (line 2) currently have real moduledocs that must be replaced with `@moduledoc false` per D-01. No other changes to the module body.

---

### `lib/rendro/pdf/cid_font.ex`, `lib/rendro/pdf/font_subsetter.ex`, `lib/rendro/text/bidi.ex`, `lib/rendro/text/shaper.ex` (MODIFIED — confirm/add `@moduledoc false`)

**Analog:** same `@moduledoc false` pattern

Verify each file's current `@moduledoc` state before editing. All four are confirmed to exist at their canonical paths. Apply `@moduledoc false` at line 2 of each, replacing any existing moduledoc value. No other changes.

---

### `lib/rendro/sign.ex` (MODIFIED — `@doc false` on `redact_*` helpers)

**Analog:** existing `@doc false` usages in codebase (standard Elixir idiom)

**Target functions** (sign.ex, verified lines ~174–222):
- `redact_opts/1` (line ~174)
- `redact_prepare_opts/1` (line ~177)
- `redact_sign_opts/1` (line ~192)
- `redact_augment_opts/1` (line ~216)

**Pattern** — add `@doc false` immediately before each `def`:
```elixir
  @doc false
  def redact_opts(opts), do: redact_prepare_opts(opts)

  @doc false
  def redact_prepare_opts(opts) when is_list(opts) do
    # ...
  end
```

Do not touch any other `def` or `@doc` in `sign.ex`.

---

### `lib/rendro/protect.ex` (MODIFIED — `@doc false` on `redact_opts/2`)

**Analog:** same `@doc false` pattern

**Target function** (protect.ex, verified line ~78):
- `redact_opts/2`

```elixir
  @doc false
  def redact_opts(opts) when is_list(opts) do
    # ...
  end
```

---

### `lib/rendro/recipes/invoice.ex` + `branded_invoice.ex` (MODIFIED — opts threading)

**Analog:** `lib/rendro/recipes/statement.ex` (opts threading pattern) + `lib/rendro/recipes/pagination.ex` (`formatter/3`, `label_resolver/1`)

**Reference impl: statement.ex `sections/2`** (lines 203–212 — the pattern to match):
```elixir
@spec sections(map(), keyword()) :: [Rendro.Section.t()]
def sections(data, opts \\ []) do
  validate_data!(data)

  [
    header_section(data, opts),
    body_section(data, opts),
    footer_section(data, opts)
  ]
end
```

**Current invoice.ex state** (lines 68–75 — the before-state):
```elixir
@spec sections(map(), keyword()) :: [Rendro.Section.t()]
def sections(data, _opts \\ []) do
  [
    header_section(data),
    body_section(data),
    footer_section(data)
  ]
end
```

**Change for invoice.ex** — flip `_opts` → `opts`, pass to helpers:
```elixir
@spec sections(map(), keyword()) :: [Rendro.Section.t()]
def sections(data, opts \\ []) do
  [
    header_section(data, opts),
    body_section(data, opts),
    footer_section(data, opts)
  ]
end

# Helper arity-2 heads — use _opts to avoid --warnings-as-errors on unused vars:
defp header_section(data, _opts) do
  # existing body unchanged
end

defp body_section(data, _opts) do
  # existing body unchanged
end

defp footer_section(data, _opts) do
  # existing body unchanged
end
```

**Change for branded_invoice.ex** — same pattern (current state: lines 98–108 `sections/2` ignores `_opts`):
```elixir
@spec sections(map(), keyword()) :: [Rendro.Section.t()]
def sections(data, opts \\ []) do
  validate_data!(data)

  [
    logo_section(data, opts),
    header_section(data, opts),
    body_section(data, opts),
    footer_section(data, opts)
  ]
end
```

**Pagination helpers available if threading real formatter support** (`pagination.ex` lines 57–73):
```elixir
# formatter/3: extracts :formatters[key] from opts, falls back to default_fn
def formatter(opts, key, default_fn) do
  formatters = Keyword.get(opts, :formatters, [])
  Keyword.get(formatters, key, default_fn)
end

# label_resolver/1: merges :labels from opts over Rendro.Format defaults
def label_resolver(opts) do
  user_labels = Keyword.get(opts, :labels, %{})
  fn key ->
    case Map.fetch(user_labels, key) do
      {:ok, val} -> val
      :error -> Rendro.Format.label(key)
    end
  end
end
```

Per D-11: if wiring real formatter support into invoice bodies is non-trivial, scope the deliverable to "accept and forward opts to helpers only" (arity-2 heads with `_opts`). Default output must stay byte-identical.

---

### `@moduledoc tags: [...]` sweep — all public modules (MODIFIED)

**Pattern** (no existing in-repo example yet — standard ExDoc 0.40 idiom):

For stable modules (D-04), add `tags: [:stable]` to the `@moduledoc` keyword list:
```elixir
@moduledoc """
  ...existing doc text...
  """ <> ""
# Change to:
@moduledoc tags: [:stable]
# OR, when there's a real docstring:
@moduledoc """
  ...existing doc text...
  """
# Add as a separate attribute:
# ExDoc reads tags from the @moduledoc attribute options — use the keyword form:
@moduledoc "...doc...",
  tags: [:stable]
```

Correct ExDoc 0.40 syntax for a module with both prose doc and tags:
```elixir
@moduledoc """
  Structured diagnostics for render failures.
  ...
  """,
  tags: [:stable]
```

For adapter modules (D-05), same shape with `tags: [:adapter]`. Apply to every module that remains public (not `@moduledoc false`) — see D-04/D-05 for the full lists.

---

## Shared Patterns

### `@moduledoc false` (hide pattern)
**Apply to:** `Rendro.Audit`, `Rendro.Format`, `Rendro.PDF.CidFont`, `Rendro.PDF.FontSubsetter`, `Rendro.Text.Bidi`, `Rendro.Text.Shaper`
**Pattern source:** `lib/rendro/viewer_evidence/matrix.ex` line 2
```elixir
@moduledoc false
```
Replace any existing real moduledoc string with this one line.

### `@doc false` (hide individual function)
**Apply to:** `Rendro.Sign` `redact_*` helpers (4 functions), `Rendro.Protect.redact_opts/2`
**Pattern:**
```elixir
@doc false
def the_function(args) do
```
Place immediately before each target `def` line.

### JSV schema validation
**Source:** `lib/rendro/viewer_evidence/validator.ex` lines 27–33, 383–387
**Apply to:** `lib/rendro/public_api/validator.ex`
```elixir
schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()
case JSV.validate(data, schema) do
  {:ok, _} -> :ok
  {:error, err} -> {:error, format_jsv_error(err)}
end

defp format_jsv_error(err) do
  err |> JSV.normalize_error() |> inspect(limit: :infinity)
end
```

### `priv/` file loader
**Source:** `lib/rendro/viewer_evidence/matrix.ex` lines 37–39
**Apply to:** `lib/rendro/public_api/loader.ex`
```elixir
@spec load!() :: map()
def load! do
  @manifest_path |> File.read!() |> JSON.decode!()
end
```

### Mix task `@impl` + `Mix.Task.run("compile")` + `Mix.shell()`
**Source:** `lib/mix/tasks/rendro/viewer_evidence.ex` lines 76–99, 118–128
**Apply to:** `lib/mix/tasks/rendro/api.gen.ex`
```elixir
@impl Mix.Task
def run(_args) do
  Mix.Task.run("compile")
  # ... task body
  Mix.shell().info("...")
end
```

### Adapter recompile before introspection
**Source:** `test/support/mocks.ex` lines 215–231 (`AdapterReloader`)
**Apply to:** `lib/rendro/public_api.ex` and `lib/mix/tasks/rendro/api.gen.ex`
```elixir
@adapter_files [
  "lib/rendro/adapters/threadline.ex",
  "lib/rendro/adapters/mailglass.ex",
  "lib/rendro/adapters/accrue.ex"
]

def recompile do
  project_root = File.cwd!()
  for relative <- @adapter_files,
      path = Path.join(project_root, relative),
      File.exists?(path) do
    Code.compile_file(path)
  end
  :ok
end
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `@moduledoc tags: [...]` sweep | config attribute | — | No existing module in the repo uses `tags:` yet — first introduction. Use standard ExDoc 0.40 `@moduledoc "...", tags: [:stable]` keyword syntax documented in RESEARCH.md Focus Area 3. |

---

## Metadata

**Analog search scope:** `lib/rendro/`, `lib/mix/tasks/`, `priv/`, `priv/schemas/`, `test/support/`
**Files scanned:** 15
**Pattern extraction date:** 2026-05-30

# Phase 125: Foundation — Curated fonts, style-genre presets & brand fixtures - Pattern Map

**Mapped:** 2026-08-16  
**Files analyzed:** 30 logical paths/groups  
**Analogs found:** 29 / 30

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/theme/presets.ex` | service / private API | transform | `lib/rendro/theme.ex` + `lib/rendro/document.ex` | role-match |
| `lib/rendro/theme.ex` | model / public API | transform | `lib/rendro/theme.ex` | exact |
| `lib/rendro/recipes/certificate.ex` | component / recipe | request-response | `lib/rendro/recipes/certificate.ex` | exact |
| `lib/rendro/pdf/font_subsetter.ex` | service | transform | `lib/rendro/pdf/font_subsetter.ex` | exact |
| `mix.exs` | config | file-I/O | `mix.exs` package file allowlist | exact |
| `priv/fonts/{inter,source-sans-3,source-serif-4,jetbrains-mono}/*` | static asset / config | file-I/O | `priv/branded/fonts/*` registration and package pattern | partial |
| `NOTICE` (curated-font provenance blocks) | config / compliance artifact | file-I/O | root `NOTICE` + package allowlist | role-match |
| `priv/schemas/examples.schema.json` | config / schema | transform | current `brand` schema object | exact |
| `priv/examples/{invoice,payslip}/northline-logistics/*` | fixture / static asset | file-I/O | existing invoice and payslip fixture directories | exact |
| `priv/examples/{invoice,payslip}/cedar-mutual/*` | fixture / static asset | file-I/O | existing invoice and payslip fixture directories | exact |
| `priv/examples/statement/{signal-ledger,aster-research-fund}/*` | fixture / static asset | file-I/O | `priv/examples/statement/northwind-ledger-co/statement.json` | exact |
| `priv/examples/receipt/{poppy-and-grain,circuit-supply-co}/*` | fixture / static asset | file-I/O | `priv/examples/receipt/harbor-and-oak-cafe/receipt.json` | exact |
| `priv/examples/certificate/{aster-institute,meridian-arts-fellowship}/*` | fixture / static asset | file-I/O | `priv/examples/certificate/summit-training-institute/certificate.json` | exact |
| `priv/examples/ticket/{field-notes-conference,the-letterpress-hall}/*` | fixture / static asset | file-I/O | `priv/examples/ticket/aurora-live/ticket.json` | exact |
| `test/rendro/theme/presets_test.exs` | test | request-response | `test/rendro/theme_test.exs` | role-match |
| `test/rendro/theme/preset_fonts_test.exs` | test | file-I/O | `test/rendro/document_test.exs` + `test/rendro/pdf/font_subsetter_test.exs` | role-match |
| `test/rendro/pdf/font_subsetter_test.exs` | test | transform | `test/rendro/pdf/font_subsetter_test.exs` | exact |
| `test/docs_contract/examples_schema_contract_test.exs` | test | file-I/O | `test/docs_contract/examples_schema_contract_test.exs` | exact |
| `test/docs_contract/theme_industry_guard_test.exs` | test / guard | transform | `test/docs_contract/theme_industry_guard_test.exs` | exact |

`priv/examples/.../*` denotes the required JSON fixture plus one deterministic, text-only local SVG mark (and only an additional dark-safe SVG if a later consuming path actually requires it). The twelve directories are data, not Elixir modules.

## Pattern Assignments

### `lib/rendro/theme/presets.ex` (private preset resolver + explicit document bridge, transform)

**Analogs:** `lib/rendro/theme.ex`, `lib/rendro/document.ex`, and `lib/rendro/font_registry.ex`.

**Pure value construction** — copy the `from_brand/2` shape from [`lib/rendro/theme.ex`](../../../lib/rendro/theme.ex) lines 268-303: it coerces authoring colors once, derives `on_accent`, then delegates to `resolve/1`; it does not perform registry or file work.

```elixir
base_colors = Map.merge(@default_colors, provided)

on_accent =
  case Map.fetch(brand, :on_accent) do
    {:ok, override} -> override
    :error -> on_accent_for(accent, base_colors)
  end

colors = Map.put(base_colors, :on_accent, on_accent)

opts
|> Map.new()
|> Map.put(:colors, colors)
|> resolve()
```

Implement strict genre/option validation before this construction in the new module. Materialize the D-10 token maps here, call `Rendro.Theme.resolve/1`, and apply `Rendro.Theme.dark/1` last for `mode: :dark`. Do not make the new module mutate a theme or implicitly register fonts.

**Document transformation** — copy [`lib/rendro/document.ex`](../../../lib/rendro/document.ex) lines 164-171. The bridge must return a new document with its existing registry updated:

```elixir
def register_embedded_font(%__MODULE__{} = doc, logical_name, source)
    when is_atom(logical_name) do
  %__MODULE__{
    doc
    | font_registry:
        Rendro.FontRegistry.register_embedded(doc.font_registry, logical_name, source)
  }
end
```

Before calling it, use `Rendro.FontRegistry.fetch/2` ([`lib/rendro/font_registry.ex`](../../../lib/rendro/font_registry.ex) lines 154-160) to enforce the Phase-125 policy: absent registers; an identical Rendro-curated descriptor is idempotent; any other existing descriptor raises the new actionable collision error. Do not use `FontRegistry.register_embedded/4` as the collision policy itself: that function overwrites with `Map.put` (lines 102-117).

**Embedded-font descriptor and preflight semantics** — follow [`lib/rendro/font_registry.ex`](../../../lib/rendro/font_registry.ex) lines 313-344. A `{:path, path}` source is copied to owned bytes at registration, and existing `preflight/1` parses it to the PDF metric/embedding definition. The curated bridge should pass stable `{:path, Application.app_dir(:rendro, ...)}` descriptors, letting that existing pipeline remain the sole parser/renderer seam.

### `lib/rendro/theme.ex` (public API model, transform)

**Analog:** the current public pure API in [`lib/rendro/theme.ex`](../../../lib/rendro/theme.ex) lines 184-303.

Add exactly one documented/spec’d `preset/2` delegation in the same direct style as the existing constructors:

```elixir
@spec from_brand(keyword(), keyword()) :: t()
def from_brand(brand_tokens, opts \\ []) do
  # pure authoring-boundary normalization and resolve
end
```

The phase’s implementation must make `preset/2` a narrow `Rendro.Theme.Presets` delegation, leaving genre atoms, token tables, font paths, and bridge logic outside this file. Preserve the current struct shape and the `resolve/1` density behavior (`:compact` forcibly makes leading `1.1`, lines 202-223).

### `lib/rendro/recipes/certificate.ex` (registry-aware centered metrics, request-response)

**Analog:** the existing Certificate typography/measurement seam, [`lib/rendro/recipes/certificate.ex`](../../../lib/rendro/recipes/certificate.ex) lines 248-290 and 313-479.

**Composition ordering to preserve:** `document/2` currently builds `secs = sections(data, opts)` before `base_doc`, so it has no document registry when it calls centered measurement:

```elixir
template = page_template(opts)
secs = sections(data, opts)

base_doc = Rendro.Document.new()
```

**Metric coupling to preserve:** the same resolved role drives measurement and emitted text:

```elixir
font = centering_measure_font(font_role)
width = Rendro.PDF.Font.text_width(font, text, size)
x = max((region_w - width) / 2, 0)

Rendro.block(
  Rendro.text(text, font: font_role, color: colors.ink, line_height: type.leading,
    widows: type.widows, orphans: type.orphans),
  x: x,
  width: width
)
```

The present guard at lines 462-479 intentionally accepts only `:default`/`"Helvetica"` and raises instead of measuring an embedded role with Helvetica. Replace/refactor that guard with a private curated-role metric resolver that obtains metrics from the exact curated descriptor while retaining this no-theme behavior byte-for-byte. Do not add genre branches to recipes and do not change the public `Recipe.document(...) |> Presets.register_fonts(genre)` order.

### `lib/rendro/pdf/font_subsetter.ex` and `test/rendro/pdf/font_subsetter_test.exs` (deterministic transform)

**Analog:** [`lib/rendro/pdf/font_subsetter.ex`](../../../lib/rendro/pdf/font_subsetter.ex) lines 11-47 and [`test/rendro/pdf/font_subsetter_test.exs`](../../../test/rendro/pdf/font_subsetter_test.exs) lines 7-40.

Normalize precisely at the public boundary, before dependencies are traversed:

```elixir
def subset(bytes, used_glyphs) when is_binary(bytes) and is_list(used_glyphs) do
  with {:ok, version, num_tables, directory} <- parse_offset_table(bytes),
       # existing parse / validation pipeline
       {:ok, required_glyphs} <- resolve_dependencies(used_glyphs, offsets, glyf, num_glyphs) do
    # existing deterministic assembly path
  end
end
```

Introduce `normalized = used_glyphs |> Enum.uniq() |> Enum.sort()` as the value passed into that existing `with` pipeline. Extend the current `setup` + `FontParser.parse/1` assertions with each vendored face and permutations/duplicates that yield identical subset bytes. Preserve parser validation after subsetting.

### `mix.exs`, curated font binaries, and NOTICE (config/file-I/O)

**Analog:** [`mix.exs`](../../../mix.exs) lines 111-130 has the explicit Hex `files: ~w(...)` allowlist; `priv/branded` and `priv/examples` are the existing static artifact entries.

```elixir
files: ~w(
  lib
  assets/rendro
  priv/branded
  priv/examples
  # add priv/fonts here
  bench/results
  guides
  .formatter.exs
  mix.exs
  README.md
  ADOPTION.md
  LICENSE
  NOTICE
  CHANGELOG.md
)
```

Add `priv/fonts` explicitly. Store each unmodified TTF under a deterministic family directory and add the mandated delimited provenance/OFL/RFN blocks to `NOTICE`; do not introduce a new font parser or pre-subset source files.

For package proof, extend the existing Hex-tar workflow from [`test/docs_contract/examples_schema_contract_test.exs`](../../../test/docs_contract/examples_schema_contract_test.exs) lines 30-52:

```elixir
{_output, 0} = Rendro.Test.HexBuildCache.get_build_output()
list_cmd = "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"
{contents, 0} = System.cmd("sh", ["-c", list_cmd], stderr_to_stdout: true)

assert "priv/fonts/inter/Inter-Regular.ttf" in String.split(contents, "\n")
```

Assert all four specific paths and the `NOTICE` provenance blocks; checkout existence alone is insufficient.

### `priv/schemas/examples.schema.json`, twelve fixture directories, and fixture tests (config/file-I/O)

**Analogs:** current generic `brand` object at [`priv/schemas/examples.schema.json`](../../../priv/schemas/examples.schema.json) lines 10-17; one existing domain fixture per directory, for example [`priv/examples/statement/northwind-ledger-co/statement.json`](../../../priv/examples/statement/northwind-ledger-co/statement.json) lines 1-29; and [`test/docs_contract/examples_schema_contract_test.exs`](../../../test/docs_contract/examples_schema_contract_test.exs) lines 8-52.

Add generic (not recipe-specific) data-only `brand` properties for stable slug, display name, six-digit accent, recommended preset, and local logo reference. Retain `additionalProperties: true` and the per-family conditional contracts. Follow the existing fixture grammar:

```json
{
  "fixture_id": "statement_v1",
  "family": "statement",
  "paper": "us_letter",
  "currency": "USD",
  "brand": {"logo": null}
}
```

New values must preserve each recipe’s existing required data/arithmetic invariants; do not change old fixture bytes. Add the twelve specified D-22 brand directories, each with `<domain>.json` and a simple one-colour local SVG referenced by its brand block. The existing contract already scans all fixtures generically:

```elixir
for path <- Path.wildcard("priv/examples/**/*.json") do
  fixture = path |> File.read!() |> JSON.decode!()
  assert {:ok, _} = JSV.validate(fixture, schema), "#{path} failed schema validation"
end
```

Extend this test with a non-vacuous per-domain count (three total fixtures after this phase), generic brand-field/local-SVG existence checks, and the existing text-only tarball extension allowlist (`.json`, `.md`, `.svg`). The safe loader itself is already generic; copy its `Path.safe_relative/1` boundary from [`lib/rendro/examples.ex`](../../../lib/rendro/examples.ex) lines 14-51 rather than adding fixture-specific loader code.

### `test/rendro/theme/presets_test.exs` and `test/docs_contract/theme_industry_guard_test.exs` (tests/guards)

**Analogs:** [`test/rendro/theme_test.exs`](../../../test/rendro/theme_test.exs) lines 1-270 and [`test/docs_contract/theme_industry_guard_test.exs`](../../../test/docs_contract/theme_industry_guard_test.exs) lines 18-41.

Use the established `async: true`, aliases, focused `describe`, value assertions, and `assert_raise` style. Test strict atom/options/color failures, resolved light/dark token construction, distinct three-axis signatures, bridge registration/idempotence/collision/unregistered failure, all recipe paths, and byte determinism in separate focused tests.

The source guard must preserve its forbidden vocabulary and change only its assertion logic. Current pattern:

```elixir
for term <- ~w(preset catalog configurator genre), do: refute(source =~ term)

assert source =~ "def default"
assert source =~ "def from_brand"
```

Replace with a narrow positive assertion for one readable `preset/2` delegation to `Rendro.Theme.Presets`, then apply the unchanged forbidden scan to the remaining source. This prevents both preset-table leakage and a hidden/generated delegation.

## Shared Patterns

### Pure value construction

**Sources:** `lib/rendro/theme.ex` lines 202-303.  
**Apply to:** `Theme.preset/2` and preset table resolution.

`resolve/1` owns deep merge, complete color validation, fixed `:compact` leading, and struct creation. `dark/1` must run after light construction. Theme construction never touches fonts, files, or document state.

### Document-owned embedded-font registration

**Sources:** `lib/rendro/document.ex` lines 164-171; `lib/rendro/font_registry.ex` lines 102-117 and 364-403.  
**Apply to:** `Presets.register_fonts/2`, all recipe/render integration tests.

Use immutable document transformation, `{:path, path}` descriptors, explicit collision inspection, and existing registry preflight/typed unknown-font behavior. Never global-register or silently substitute Helvetica.

### Honest errors

**Sources:** `lib/rendro/recipes/certificate.ex` lines 462-479 and `lib/rendro/font_registry.ex` lines 190-200.  
**Apply to:** malformed preset input, unsupported genre/mode/density, and caller-owned role collisions.

Follow the project’s “What / Where / Why / Next” error voice where a multiline public configuration error is warranted; retain typed resolver errors for unregistered logical roles.

### Static fixture and package contracts

**Sources:** `lib/rendro/examples.ex` lines 14-51; `test/docs_contract/examples_schema_contract_test.exs` lines 14-52; `mix.exs` lines 111-130.  
**Apply to:** all font and example assets.

Assets stay in package-listed `priv/` paths, fixture loading remains safe/generic, and package claims are backed by an unpacked tarball assertion. Keep examples text-only (`.json`, `.svg`, `.md`).

### Deterministic and advisory proof separation

**Sources:** `FontSubsetter.subset/2` lines 11-47; RESEARCH.md validation architecture.  
**Apply to:** font subset tests, default-byte regressions, raster proof.

Automated tests prove normalized glyph-order bytes, parser/preflight acceptance, API behavior, package contents, and default-path byte preservation. Pinned-PDFium rasters are a separate human/advisory genre-distinctness review, never a claim of accessibility, print safety, or universal quality.

## No Analog Found

| File / Concern | Role | Data Flow | Reason / Planner Direction |
|---|---|---|---|
| Per-face immutable upstream provenance data (tag, commit, URL, SHA-256, OFL/RFN) | config | file-I/O | No existing four-font curated catalog/provenance record. Use the root `NOTICE` convention and verify the official archive/file at vendoring time. |
| Curated role-to-font map and strict preset option validator | private service | transform | No existing genre catalog by design. Keep it entirely in `Rendro.Theme.Presets` and build on the shared Theme/Document primitives above. |
| Certificate pre-document curated metric seam | private recipe helper | transform | Current code explicitly rejects the needed roles. Implement a narrow private resolver using existing parser/preflight output; prove no-theme bytes unchanged. |

## Metadata

**Analog search scope:** `lib/rendro/{theme,document,font_registry,examples,pdf,recipes}`, `priv/{examples,schemas,branded}`, `test/{rendro,docs_contract}`, `mix.exs`  
**Files scanned:** 27  
**Pattern extraction date:** 2026-08-16

# Phase 129: Docs & manifest closure - Pattern Map

**Mapped:** 2026-08-19  
**Files analyzed:** 10  
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/presets.md` | guide/documentation | request-response | `guides/theming.md` | role-match |
| `README.md` | documentation entry point | request-response | existing `## Guides` block in `README.md` | exact |
| `guides/theming.md` | guide/documentation | request-response | its existing scoped sections | exact |
| `mix.exs` | config/package metadata | transform | existing `docs/0` extras/groups and `package/0` allowlist | exact |
| `priv/support_matrix.json` | manifest/config | transform | `theming.light` / `theming.dark` rows | exact |
| `priv/public_api.json` | generated manifest | transform | `Mix.Tasks.Rendro.Api.Gen` + public API contract | exact |
| `test/docs_contract/presets_claims_test.exs` | test/semantic contract | transform | `test/docs_contract/theming_claims_test.exs` | role-match |
| `scripts/verify_docs.exs` | config/test runner | batch | existing `lanes` registry | exact |
| `test/guardrails/required_checks_contract_test.exs` | test/guardrail contract | transform | existing docs-lane count assertion | exact |
| `priv/guardrails/required_status_checks.json` | CI guardrail manifest | config | existing `test` context notes | exact |

## Pattern Assignments

### `guides/presets.md` (guide, request-response)

**Analog:** `guides/theming.md`

Use a focused Markdown guide with semantic `##` sections, ordinary language before internals, a marker-delimited executable fence, and explicit adjacent boundary prose. Do not reuse the older gallery as a second preset tutorial.

**Intro and scoped guide style** ([`guides/theming.md`](../../../guides/theming.md#L1), lines 1-18):

```markdown
# Theming

`Rendro.Theme` is a pure, inert design-token value: semantic color roles plus
typography, resolved once and threaded through every recipe's three-rung
pattern (`document/2` → `page_template/1` → `sections/2`).

## Start with an accent
```

**Canonical formatter-owned golden path** ([`lib/rendro/theme/snippet.ex`](../../../lib/rendro/theme/snippet.ex#L56), lines 56-74):

```elixir
def usage_snippet(family, preset, accent, mode) do
  {variable, recipe_module} = family_source!(family)
  preset_atom = preset_atom!(preset)
  {red, green, blue} = accent_rgb!(accent)
  mode_atom = mode_atom!(mode)

  """
  preset = :#{preset_atom}

  theme =
    Rendro.Theme.preset(preset, accent: {#{red}, #{green}, #{blue}}, mode: :#{mode_atom})

  document =
    #{variable}
    |> #{inspect(recipe_module)}.document(theme: theme)
    |> Rendro.Theme.Presets.register_fonts(preset)
  """
end
```

Copy the established Livebook fence markers exactly so the new test can extract only the source body ([`guides/livebook/first_invoice.livemd`](../../../guides/livebook/first_invoice.livemd#L81), lines 81-93):

```elixir
# rendro-theme-snippet:start
preset = :swiss
...
# rendro-theme-snippet:end
```

Keep the locked boundary immediately after the first example; retain the dark sentence verbatim when routing to dark behavior: `Screen-oriented; not a print, accessibility, PDF/UA, or WCAG claim.` The existing Livebook applies both disclosures adjacent to its first choice ([`guides/livebook/first_invoice.livemd`](../../../guides/livebook/first_invoice.livemd#L73), lines 73-80).

### `README.md` (documentation entry point, request-response)

**Analog:** existing `## Guides` discovery list in `README.md`

Insert the compact preset entry block after the feature introduction and before the launch-artifact marker, then add outcome-named routes in the existing guide list. Maintain relative Markdown paths and concise `—` outcome explanations.

**Discovery-list pattern** ([`README.md`](../../../README.md#L43), lines 43-51):

```markdown
## Guides

- [Branding](guides/branding.md) — register fonts and logo assets, then use the branded invoice recipe.
- [First Invoice Livebook](guides/livebook/first_invoice.livemd) — a zero-friction tutorial for rendering and downloading a deterministic invoice PDF.
- [API Stability and Support Boundaries](guides/api_stability.md) — the canonical support language for trust-sensitive and proof-backed surfaces.
```

### `guides/theming.md` (guide, request-response)

**Analog:** the guide's early “Start with an accent” progression

Add only an early, compact pointer to `presets.md`; retain this guide’s `from_brand/2` and manual-token focus. Preserve its exact claim/boundary formulation rather than moving it into the preset guide.

**Boundary language to preserve** ([`guides/theming.md`](../../../guides/theming.md#L33), lines 33-37):

```markdown
`on_accent` is a **sensible readable default** ... — it is **not** a
WCAG-AA/AAA or PDF-UA conformance claim. Mid-tone accents can miss 4.5:1
either way. Pass an explicit `on_accent:` to override...
```

### `mix.exs` (config/package metadata, transform)

**Analog:** `docs/0` extras/groups and `package/0` explicit allowlist

Add `guides/presets.md` beside `guides/theming.md` in both `extras` and the `Guides` group. Add only the public configurator/catalog payload and required brand tokens stylesheet as narrow package paths; do not broaden to `assets/rendro` or private `priv/` evidence.

**ExDoc registration pattern** ([`mix.exs`](../../../mix.exs#L186), lines 186-224):

```elixir
extras: [
  "README.md",
  ...,
  "guides/branding.md",
  "guides/theming.md",
  "guides/api_stability.md"
],
groups_for_extras: [
  Guides: [
    "guides/branding.md",
    "guides/theming.md",
    "guides/integrations.md"
  ]
]
```

**Narrow package allowlist pattern** ([`mix.exs`](../../../mix.exs#L134), lines 134-155):

```elixir
files: ~w(
  lib
  assets/rendro/artifacts.json
  assets/rendro/gallery
  assets/rendro/manual.pdf
  ...
  guides
  README.md
)
```

### `priv/support_matrix.json` (manifest/config, transform)

**Analog:** `theming.light` and `theming.dark`

Add `theming.presets` as a sibling row. Use string status leaves under `capabilities` and `boundaries`, so the existing recursive overclaim guard style can inspect it. Put the proof paths/content assertions in the new test; retain `unsupported` for every locked boundary.

**Sibling row shape** ([`priv/support_matrix.json`](../../../priv/support_matrix.json#L607), lines 607-632):

```json
"theming": {
  "light": {
    "status": "supported",
    "capabilities": {
      "deterministic_output": "supported"
    }
  },
  "dark": {
    "status": "supported_screen_oriented",
    "boundaries": {
      "print_recommended": "unsupported",
      "accessibility_pdf_ua_claim": "unsupported"
    }
  }
}
```

### `priv/public_api.json` (generated manifest, transform)

**Analog:** `Mix.Tasks.Rendro.Api.Gen` and `PublicApiContractTest`

Never edit this JSON by hand. Run `mix rendro.api.gen`; commit its deterministic output, which already contains `Rendro.Theme.preset/2` in the adapter-tier function list.

**Generation/error pattern** ([`lib/mix/tasks/rendro/api.gen.ex`](../../../lib/mix/tasks/rendro/api.gen.ex#L107), lines 107-132):

```elixir
Mix.Task.run("compile")
Rendro.PublicApi.recompile_conditional_adapters()
...
json = encode_manifest(manifest)
File.write!(@manifest_path, json <> "\n")
Mix.shell().info("Wrote #{@manifest_path}")
```

**Byte-drift assertion pattern** ([`test/docs_contract/public_api_contract_test.exs`](../../../test/docs_contract/public_api_contract_test.exs#L25), lines 25-78):

```elixir
fresh_json = Mix.Tasks.Rendro.Api.Gen.encode_manifest(fresh_manifest) <> "\n"
checked_in = File.read!("priv/public_api.json")
...
assert fresh_json == checked_in
```

### `test/docs_contract/presets_claims_test.exs` (test, transform)

**Analog:** `test/docs_contract/theming_claims_test.exs`; package sub-pattern from `test/docs_contract/comparison_claims_test.exs`

Follow one `async: true` semantic-contract module. Use module attributes for required capability/boundary keys and forbidden terms, JSON decoding in `setup`, exact guide/README/Livebook/configurator link and copy assertions, and synthetic maps/strings that demonstrate predicate teeth. Extract only marker-bounded guide source and compare byte-for-byte with `Rendro.Theme.Snippet.usage_snippet("invoice", "swiss", "#2C6BED", "light")`; then parse/evaluate with the realistic invoice fixture.

**Non-vacuity and mutation-teeth pattern** ([`test/docs_contract/theming_claims_test.exs`](../../../test/docs_contract/theming_claims_test.exs#L56), lines 56-90):

```elixir
refute @boundary_keys == [], "boundary-key list must not be empty (guard would be vacuous)"

overclaiming_section = %{
  "dark" => %{"boundaries" => %{"print_recommended" => "supported"}}
}

assert theming_overclaims?(overclaiming_section)
```

**Manifest proof assertions** ([`test/docs_contract/theming_claims_test.exs`](../../../test/docs_contract/theming_claims_test.exs#L93), lines 93-136):

```elixir
matrix = File.read!("priv/support_matrix.json") |> JSON.decode!()
...
assert Map.has_key?(boundaries, key)
assert boundaries[key] == "unsupported"
refute theming_overclaims?(matrix["theming"])
```

**Cached Hex tarball inspection** ([`test/docs_contract/comparison_claims_test.exs`](../../../test/docs_contract/comparison_claims_test.exs#L169), lines 169-189):

```elixir
tarball = "rendro-#{Mix.Project.config()[:version]}.tar"
{output, 0} = Rendro.Test.HexBuildCache.get_build_output()
assert output =~ tarball
{contents, 0} = System.cmd("sh", ["-c", "tar -xOf #{tarball} contents.tar.gz | tar -tzf -"], stderr_to_stdout: true)
for path <- expected_paths, do: assert(contents =~ path)
```

The package test must retain the private-negative assertions used by [`test/docs_contract/branding_claims_test.exs`](../../../test/docs_contract/branding_claims_test.exs#L62) lines 62-84.

### `scripts/verify_docs.exs` (config/test runner, batch)

**Analog:** current formatter-protected `lanes` registry

Register exactly one entry using the existing two-tuple shape, inside the formatter-off list; no new Mix alias, job, or status context.

**Lane pattern** ([`scripts/verify_docs.exs`](../../../scripts/verify_docs.exs#L7), lines 7-45):

```elixir
# formatter: off
lanes = [
  ...,
  {"Accessibility overclaim tripwire lane",
   ["test", "test/docs_contract/accessibility_overclaim_test.exs"]}
]
# formatter: on
```

### `test/guardrails/required_checks_contract_test.exs` (test, transform)

**Analog:** existing exact docs-lane count test

Update the description and numeric expectation from 26 to 27, then assert the new lane once with the same multiline regex used for existing lanes.

**Exact-count / registry assertion** ([`test/guardrails/required_checks_contract_test.exs`](../../../test/guardrails/required_checks_contract_test.exs#L120), lines 120-146):

```elixir
lane_entries = Regex.scan(
  ~r/\{"[^"]+",\s*\["test",\s*"test\/docs_contract\/[^"]+"\]\}/s,
  script
)
assert length(lane_entries) == 26
assert script =~ ~r/\{"Accessibility overclaim tripwire lane",\s*\["test",\s*"test\/docs_contract\/accessibility_overclaim_test\.exs"\]\}/s
```

### `priv/guardrails/required_status_checks.json` (CI guardrail manifest, config)

**Analog:** existing `test` deterministic context note

Update only the stale docs-lane count prose in `contexts[name=test].notes`; preserve `required_contexts: ["ci-success"]`, advisory separation, and the existing `mix ci` command.

**Required-vs-advisory pattern** ([`priv/guardrails/required_status_checks.json`](../../../priv/guardrails/required_status_checks.json#L7), lines 7-24):

```json
"required_contexts": ["ci-success"],
"contexts": [{
  "name": "test",
  "semantic_class": "deterministic",
  "command": "mix ci",
  "notes": "Includes mix test (... docs-contract lanes) ..."
}]
```

## Shared Patterns

### Canonical source, not reassembled source

**Source:** [`lib/rendro/theme/snippet.ex`](../../../lib/rendro/theme/snippet.ex#L56), lines 56-74  
**Apply to:** `guides/presets.md`, `test/docs_contract/presets_claims_test.exs`, and all links to configurator/Livebook code.

The formatter owns the chosen Elixir source; docs and browser surfaces display its output. The configurator itself makes this explicit by displaying and copying `record.snippet`, not generating a `Theme.preset` call ([`assets/rendro/configurator/configurator.js`](../../../assets/rendro/configurator/configurator.js#L89), lines 89-95).

### Explicit, layered claims boundaries

**Source:** [`test/docs_contract/theming_claims_test.exs`](../../../test/docs_contract/theming_claims_test.exs#L15), lines 15-53 and [`priv/support_matrix.json`](../../../priv/support_matrix.json#L619), lines 619-631  
**Apply to:** preset guide, README microcopy, new support row, and new claims lane.

Use positive capabilities and independently unsupported boundaries. Assert both the real matrix and a mutation that would overclaim. Keep deterministic bytes, catalog preview states, and human rubric labels as separate evidence.

### Static asset and package closure

**Source:** [`mix.exs`](../../../mix.exs#L134), lines 134-155; [`test/docs_contract/comparison_claims_test.exs`](../../../test/docs_contract/comparison_claims_test.exs#L169), lines 169-189  
**Apply to:** `mix.exs` and new preset claims test.

Use narrow package paths and `HexBuildCache` tarball inspection. The configurator’s relative dependencies include `index.json`, `../catalog.json`, and the brand stylesheet ([`assets/rendro/configurator/index.html`](../../../assets/rendro/configurator/index.html#L7), lines 7-8; [`assets/rendro/configurator/configurator.js`](../../../assets/rendro/configurator/configurator.js#L130), lines 130-137), so source-tree, Hex tarball, and generated ExDoc link checks must cover the same asset graph.

## No Analog Found

None. The phase adds a new public-claims lane, but existing theming semantic tests and package-contract tests provide the required patterns.

## Metadata

**Analog search scope:** `README.md`, `guides/`, `lib/rendro/theme/`, `lib/mix/tasks/`, `mix.exs`, `priv/`, `scripts/`, `test/docs_contract/`, `test/guardrails/`, `assets/rendro/configurator/`  
**Files scanned:** 18  
**Pattern extraction date:** 2026-08-19

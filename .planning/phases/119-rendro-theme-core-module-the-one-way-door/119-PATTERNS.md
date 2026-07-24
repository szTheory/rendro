# Phase 119: `Rendro.Theme` core module (the one-way door) - Pattern Map

**Mapped:** 2026-07-24
**Files analyzed:** 5 (2 create-lib/create-test, 1 create-guard-test, 1 modify, 1 regenerate)
**Analogs found:** 5 / 5 (every new/modified file has a concrete in-repo analog)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/theme.ex` | model (pure value struct + resolver/constructors), adapter tier | transform (resolve/deep-merge/derive) | `lib/rendro/format.ex` | exact (same tier, same shared-attr idiom); struct shape from `invoice.ex` `palette/1` map + `text.ex` defstruct |
| `test/rendro/theme_test.exs` | test (example + property unit) | request-response (pure fn assertions) | `test/support/generators.ex` (stream_data), sibling `test/rendro/*_test.exs` | role-match |
| `test/docs_contract/theme_industry_guard_test.exs` | test (static source-grep guard) | file-I/O (`File.read!` + regex refute) | `test/docs_contract/integrations_claims_test.exs:35-45`; placement per `branding_contract_test.exs` | exact |
| `lib/mix/tasks/rendro/api.gen.ex` (MODIFY ~L44-104) | config (module registry list) | batch (compile-time list) | existing `Rendro.Format` entry at `api.gen.ex:86` | exact (add one sibling line) |
| `priv/public_api.json` (REGENERATE) | generated artifact | batch (mix task output) | `Elixir.Rendro.Format` entry at `priv/public_api.json:247-255` | exact (generator writes it; do not hand-edit) |

---

## Pattern Assignments

### `lib/rendro/theme.ex` (model, adapter tier, transform)

**Primary analog:** `lib/rendro/format.ex` (adapter tier, shared module-attr defaults, all-`defp` helpers, `@spec` on every public fn). **Struct-shape analog:** `lib/rendro/recipes/invoice.ex:466` `palette/1` (the bare `{r,g,b}` role map the `colors` group must drop into) + `lib/rendro/text.ex:14-23` (defstruct-with-defaults + `@type` shape). **Validator call site:** `lib/rendro/color.ex:67`.

**Adapter-tier moduledoc header — mirror `format.ex:1-26` verbatim in shape** (add the field-shape-stable / values-may-evolve note + flat-elevation guidance required by D-06/THEME-04):
```elixir
# lib/rendro/format.ex:2-26
@moduledoc """
Pure, locale-free, deterministic formatting helpers ...
## Stability caveat
Formatted **output** may evolve across minor versions ...
"""
@moduledoc tags: [:adapter]
```
For Theme the prose MUST carry: "The field shape is stable; token values and rendered bytes may evolve across minor versions. Express elevation flatly via `surface` tint + `rule` hairline." (Planner-discretion prose; the `tags: [:adapter]` line is mandatory and load-bearing — omitting it fails `manifest_test.exs:57` "no untagged entries", Pitfall 3.)

**Shared-module-attribute defaults (no half-nil trap) — mirror `format.ex:28-34,108`:**
```elixir
# format.ex:28-34 — attr is the single source, consumed by the public fn
@labels %{
  balance: "Balance",
  brought_forward: "Brought forward",
  ...
}
# format.ex:108 — public fn reads the attr
def label(key) when is_map_key(@labels, key), do: Map.fetch!(@labels, key)
```
Theme extends this: each token GROUP is a module attr consumed by BOTH `defstruct` and `default/0`, so a bare `%Rendro.Theme{}` already equals the light default (D-01). Structure:
```elixir
@default_colors %{ink: {16, 24, 39}, muted: {91, 101, 115}, accent: {44, 107, 237},
                  on_accent: {255, 255, 255}, background: {255, 255, 255},
                  surface: {247, 243, 234}, rule: {196, 188, 169},
                  positive: {20, 122, 75}, negative: {194, 65, 50}}   # integer tuples, mined from tokens.json (D-05)
@default_typography %{fonts: %{heading: :default, body: :default, mono: :default},
                      scale: %{display: 21, title: 16.5, subtitle: 13, body: 10.5, small: 9, caption: 8},
                      leading: 1.2, widows: 2, orphans: 2}            # D-03; 1.2/2/2 are metric no-ops vs text.ex:18-22
@default_spacing %{unit: ..., tight: ..., normal: ..., loose: ..., section: ...}
@default_rules %{hairline: ..., thin: ..., thick: ...}
@default_radius %{none: ..., sm: ..., md: ...}
defstruct colors: @default_colors, typography: @default_typography, spacing: @default_spacing,
          rules: @default_rules, radius: @default_radius, density: :comfortable, mode: :light
@enforce_keys []   # explicit empty (D-01) — every field always defaulted → non-breaking additions
```

**Defstruct-with-defaults + per-group `@type` — mirror `text.ex:14-37` shape** (Text uses `@enforce_keys [:content]` + defaulted fields + `@type t :: %__MODULE__{...}`; Theme uses `@enforce_keys []` and adds one `@type` per group per D-01/THEME-03):
```elixir
@type rgb :: {0..255, 0..255, 0..255}
@type colors :: %{required(:ink) => rgb, required(:muted) => rgb, ... , required(:negative) => rgb}
@type font_role :: atom()
@type type_step :: number()
@type typography :: %{...}
@type spacing :: %{...}
@type rules :: %{...}
@type radius :: %{...}
@type t :: %__MODULE__{colors: colors, typography: typography, spacing: spacing,
                       rules: rules, radius: radius, density: :comfortable | :compact,
                       mode: :light | :dark}
```
Recommendation (RESEARCH Open Q1): use closed `%{required(k) => v}` map types so the frozen shape is machine-checkable; verify the manifest emits them cleanly after first gen.

**`@spec` on every public fn — mirror `format.ex:61,83,100`:** every public function gets a `@spec` immediately above it (`money/1`, `date/1`, `label/1` in Format). Theme's four public fns each get one:
```elixir
@spec default() :: t()
@spec resolve(t() | map() | keyword()) :: t()
@spec dark(t()) :: t()
@spec from_brand(keyword(), keyword()) :: t()   # or from_brand/2 signature the planner locks
```

**Color-validation call site — reuse `Rendro.Color.validate/1` (`color.ex:67`), raise on error** (do NOT build a new validator; the message is already instructive — What/Where/Why/Next, hex footgun, `color.ex:83-133`):
```elixir
# resolve/1 validates EVERY color role (THEME-02, errors-as-product)
for {_role, value} <- colors do
  case Rendro.Color.validate(value) do   # :ok | {:error, String.t()} — color.ex:67
    :ok -> :ok
    {:error, reason} -> raise ArgumentError, reason   # reuse the built message verbatim
  end
end
```

**hex→`{r,g,b}` authoring boundary — `Base.decode16!` + binary match (stdlib, all `defp`/`@doc false`):**
```elixir
defp hex_to_rgb("#" <> hex), do: hex_to_rgb(hex)
defp hex_to_rgb(hex) do
  <<r, g, b>> = Base.decode16!(hex, case: :mixed)
  {r, g, b}
end
```
Note: this is an *authoring convenience* only — the shipped `@default_colors` attr must hold already-resolved **integer tuples** (D-05, Pitfall 2). No float ever enters the stored value; the `/255` conversion happens downstream in `Color.rg/1` at draw time (`color.ex:14-15,136`).

**Branch-only float derivation (`on_accent`, D-04) — all `defp`:** compute WCAG relative luminance of `accent`, compare to threshold `0.179`; the float chooses WHICH of the theme's own integer tuples (`background` vs `ink`) to return. No float in the output. Keep `on_accent_for`, `luminance`, `contrast_ratio`, `linearize`, `deep_merge`, `normalize` all `defp`/`@doc false` so they never enter the manifest (D-06; keeps `hidden-modules` assertions green and RG byte-equality clean). Override via `on_accent:` respected, never recomputed (D-04/R2).

**Deep-merge resolver — extend the `Map.merge(defaults, overrides)` idiom from `invoice.ex:466-481`** to nested groups with a small `defp deep_merge/2`; `resolve/1` accepts `keyword | map | %Theme{}`, is idempotent (`resolve(resolve(x)) == resolve(x)`), and never `KeyError`s on partial input.

**S1-seam shape the `colors` group must match (drop-in target; this phase does NOT edit this file):**
```elixir
# lib/rendro/recipes/invoice.ex:466 (defp palette/1) — 7 core roles today
%{ink: {0,0,0}, muted: {0,0,0}, accent: {0,0,0}, on_accent: {0,0,0},
  background: {255,255,255}, surface: {255,255,255}, rule: {0,0,0}}
```
Theme's `colors` is a **superset**: adds `positive` and `negative` (all 9 always present, never nil — D-01/COLOR-01).

---

### `test/rendro/theme_test.exs` (test, example + property)

**Analog:** `test/support/generators.ex` for stream_data usage; sibling `test/rendro/*_test.exs` for ExUnit structure.

**Property-generator idiom — mirror `generators.ex:11-23` (`gen all` + `integer(0..255)` for rgb):**
```elixir
# generators.ex:16-19 — rgb component generators
r <- integer(0..255),
g <- integer(0..255),
b <- integer(0..255)
```
New generators needed (may live inline in the test or extend `generators.ex`): `rgb_gen()` (three `integer(0..255)` → tuple), `partial_map()` (subset of theme keys), `theme_or_partial()` (keyword | map | `%Theme{}`). Use `use ExUnitProperties` (as `generators.ex:5` does) and `property "..."` / `check all`.

**Coverage the tests must carry (from RESEARCH Requirement→Test Map, lines 327-343):**
- THEME-01: `assert %Rendro.Theme{} == Rendro.Theme.default()`; `Map.keys(t.colors)` == the 9 roles; `t.typography.scale` has 6 steps; `:spacing/:rules/:radius/:density/:mode` present.
- THEME-02 (property): `resolve(resolve(t)) == resolve(t)`; partial input never `KeyError`s (`match?(%Theme{}, resolve(part))`); every color role `Color.validate(role) == :ok`; `assert_raise ArgumentError, ~r/hex/, fn -> Theme.resolve(colors: %{ink: "#000"}) end`.
- COLOR-01: exact key set `[:accent,:background,:ink,:muted,:negative,:on_accent,:positive,:rule,:surface]`.
- COLOR-02: `from_brand(accent: {44,107,237})` → accent preserved, `on_accent in [background, ink]`, override `on_accent: {1,2,3}` respected, branch-selection determinism + `is_integer(elem(r,0))`.
- THEME-04: `%Theme{}` has no `:shadow/:elevation/:z_index/:opacity/:gradient` keys (recurse group maps).
- THEME-03: `Code.Typespec` check that all four public fns are `@spec`'d.
- Byte-repro: all color values integers; type-scale values `== Float.round(v, 1)` (rejects `:math.pow` irrationals).

---

### `test/docs_contract/theme_industry_guard_test.exs` (test, source-grep guard)

**Analog:** `test/docs_contract/integrations_claims_test.exs:35-45` (exact working `File.read!` + assert-on-source pattern); placement/structure convention from `test/docs_contract/branding_contract_test.exs:1-4`.

**Exact pattern to mirror** (`integrations_claims_test.exs:42-43` uses `assert source =~`; for a tripwire we invert to `refute`):
```elixir
# integrations_claims_test.exs:42-43
source = File.read!(path)
assert source =~ "if Code.ensure_loaded?(#{dependency}) do"
```
New guard shape (CONTRACT-03 / D-02):
```elixir
defmodule Rendro.DocsContract.ThemeIndustryGuardTest do
  use ExUnit.Case, async: true

  test "theme.ex names no industry or brand" do
    source = File.read!("lib/rendro/theme.ex")
    forbidden = ~w(invoice payslip ticket certificate statement receipt
                   medical legal restaurant retail)  # + named brands
    for term <- forbidden, do: refute source =~ term
  end

  test "theme.ex ships one theme + from_brand/2 only — no genre/preset machinery" do
    source = File.read!("lib/rendro/theme.ex")
    for term <- ~w(preset catalog configurator genre), do: refute source =~ term
  end
end
```
Use `use ExUnit.Case, async: true` (as `branding_contract_test.exs:2`). Equivalent variant: `refute String.contains?(content, term)` (from `accessibility_overclaim_test.exs:89-93`). Assert the positive too (one theme + `from_brand/2`).

---

### `lib/mix/tasks/rendro/api.gen.ex` (config — MODIFY ~L44-104)

**Analog:** the existing `Rendro.Format` entry at `api.gen.ex:86`, inside the adapter-tier block (comment at `api.gen.ex:77` "Adapter tier — ...").

**Exact edit:** add ONE line, `Rendro.Theme`, alphabetically adjacent to `Rendro.Format` in the adapter block:
```elixir
# api.gen.ex:77-99 (adapter block) — insert Rendro.Theme (T sorts after Telemetry region,
# but the list is a plain registry, not sorted at source; the ENCODER sorts output.
# Place it logically next to Rendro.Format per the task directive, e.g. right after line 86)
    Rendro.Format,
    Rendro.Inspector,
    ...
    Rendro.Telemetry,
    Rendro.Theme,     # <-- ADD (adapter tier; module carries @moduledoc tags: [:adapter])
```
No other change to this file. Tier is derived from the module's `@moduledoc tags: [:adapter]` via `Code.fetch_docs/1` at gen time (`api.gen.ex:116-121`), so source-list position is cosmetic — `encode_manifest/1` (`api.gen.ex:140-158`) sorts the output alphabetically.

---

### `priv/public_api.json` (generated artifact — REGENERATE, do NOT hand-edit)

**Analog:** the `Elixir.Rendro.Format` entry at `priv/public_api.json:247-255`:
```json
"Elixir.Rendro.Format": {
  "functions": [ "date/1", "label/1", "money/1" ],
  "tier": "adapter",
  "types": []
}
```
The regenerated `Elixir.Rendro.Theme` entry will look like (functions + types sorted alphabetically, `"tier": "adapter"`):
```json
"Elixir.Rendro.Theme": {
  "functions": [ "dark/1", "default/0", "from_brand/2", "resolve/1" ],
  "tier": "adapter",
  "types": [ "colors/0", "font_role/0", "radius/0", "rgb/0", "rules/0",
             "spacing/0", "t/0", "type_step/0", "typography/0" ]
}
```
**Generate, never edit:** run `mix rendro.api.gen`, then commit `priv/public_api.json`. The two byte-equality tests reject any hand edit. The file ends with a trailing `"\n"` (`api.gen.ex:125`); pretty JSON via `encode_manifest/1`.

---

## Shared Patterns

### Adapter/Evolving tier registration (applies to `theme.ex` + `api.gen.ex` + manifest)
**Source:** `lib/rendro/format.ex:26` (`@moduledoc tags: [:adapter]`) + `api.gen.ex:86` (`@public_modules` entry) + `priv/public_api.json:247-255` (generated entry).
**Apply to:** `Rendro.Theme` end-to-end. Three coordinated touches: (1) `@moduledoc tags: [:adapter]` in the module; (2) one line in `@public_modules`; (3) `mix rendro.api.gen` + commit. Forgetting (1) fails `manifest_test.exs:57`; forgetting (3) fails RG-1 + RG-2.

### Planned red→green manifest reconcile — BOTH assertions (D-06 duplicate trap)
**Source:** `test/docs_contract/public_api_contract_test.exs:72` (RG-1) AND `test/rendro/public_api/manifest_test.exs:98` (RG-2).
**Apply to:** the manifest-commit task. Both are `assert fresh_json == checked_in` byte-compares of `priv/public_api.json`; both red-build the instant `Rendro.Theme` enters `@public_modules` and both go green together after `mix rendro.api.gen` + commit. Pre-declare BOTH in the plan.
```elixir
# manifest_test.exs:93-98 (RG-2 — structurally identical to RG-1)
fresh_json = Mix.Tasks.Rendro.Api.Gen.encode_manifest(fresh_manifest) <> "\n"
checked_in = File.read!("priv/public_api.json")
assert fresh_json == checked_in, ...
```
Completeness check: `grep -rn "fresh_json == checked_in" test/` returns exactly 2 hits.

### Source-grep tripwire guard (applies to the CONTRACT-03 guard test)
**Source:** `test/docs_contract/integrations_claims_test.exs:42-43` (`source = File.read!(path)` + `assert source =~ ...`).
**Apply to:** `theme_industry_guard_test.exs` (invert to `refute`). Live in `test/docs_contract/` alongside `branding_contract_test.exs`.

### Reuse-don't-rebuild boundaries (applies to `theme.ex`)
**Sources:** `Rendro.Color.validate/1` (`color.ex:67`) for color validation; `Rendro.FontRegistry` `:default` built-in for font roles (store logical atoms only, no resolution this phase); `Base.decode16!` for hex→rgb.
**Apply to:** `resolve/1`, `default/0`, `from_brand/2`. Do NOT hand-roll a color range checker, a font resolver, or a hex parser.

### Integer-`{r,g,b}`-resolved-once determinism (applies to `theme.ex`)
**Source:** `color.ex:136-138` (`format_num` does the `n*1.0 float_to_binary` at DRAW time, not in stored values).
**Apply to:** every shipped color value stays an integer tuple; type-scale values stay int/single-decimal; luminance floats pick a branch only (Pitfall 2). Enforce with the byte-repro unit assertions.

---

## No Analog Found

None. Every file has a concrete in-repo analog; the phase is composition, not construction (RESEARCH §Don't Hand-Roll, "every subsystem this module touches already has a tested, canonical entry point").

## Metadata

**Analog search scope:** `lib/rendro/` (format, color, text, font_registry, recipes/invoice), `lib/mix/tasks/rendro/`, `priv/public_api.json`, `test/docs_contract/`, `test/rendro/public_api/`, `test/support/`.
**Files scanned:** 8 read this session (format.ex, color.ex, api.gen.ex, integrations_claims_test.exs, generators.ex, manifest_test.exs, public_api.json, branding_contract_test.exs) + RESEARCH-verified anchors (invoice.ex:466-481, text.ex:14-37, font_registry.ex, public_api_contract_test.exs, tokens.json:18-52).
**Pattern extraction date:** 2026-07-24
</content>
</invoke>

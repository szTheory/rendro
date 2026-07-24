# Phase 119: `Rendro.Theme` core module (the one-way door) — Research

**Researched:** 2026-07-24
**Domain:** Elixir pure-value struct design + public-API manifest contract (adapter tier) + deterministic PDF token modeling
**Confidence:** HIGH (all findings verified against the live codebase this session; no external package research needed — zero new deps)

## Summary

This phase ships one pure-value module, `lib/rendro/theme.ex`, whose **field shape** becomes a frozen public contract while its token **values** stay Evolving. Everything the module must integrate with already exists in the repo and was read directly this session: the S1 `palette/1` seam (`invoice.ex:466`), the color validator (`Color.validate/1`, `color.ex:67`), the font registry's `:default` built-in and typed error path (`font_registry.ex`), the `%Text{}` defaults it must be a metric no-op against (`text.ex:15-23`), the manifest generator (`api.gen.ex`), and **two** independent hidden-modules test files that byte-compare the manifest.

The single highest-risk item is the pre-declared **red→green manifest reconcile**: adding `Rendro.Theme` to the `@public_modules` list will red-build **two** byte-equality assertions (one in `public_api_contract_test.exs:25`, one in `manifest_test.exs:74`) that are structurally identical and will both fail until `mix rendro.api.gen` runs and the regenerated `priv/public_api.json` is committed. This is exactly the "second, plan-unlisted duplicate" trap from Phase 115 (D-06). Both are enumerated below with file:line and exact assertion text.

**Primary recommendation:** Model all seven token groups as **bare typed maps** in module attributes shared by `defstruct` and `default/0` (mirroring how `Rendro.Format` keeps `@labels` and how the recipe `palette/1` returns a plain map); resolve to integer `{r,g,b}` once in `resolve/1`; keep every derivation helper `defp`; register on the adapter tier by adding one line to `api.gen.ex`'s `@public_modules` and regenerating; and plan the manifest reconcile as touching **both** test files, not one.

## Locked decisions — do not re-decide

The design contract is frozen in `119-CONTEXT.md` (D-01..D-06 + R1/R2). Do not relitigate. Pointer:

| Ref | What it locks | Where to implement |
|-----|---------------|--------------------|
| **D-01** | Frozen `%Theme{}` shape: one adapter struct, groups are bare typed maps, `@enforce_keys []`, construct only via `resolve`/`default`/`dark`/`from_brand`; `resolve/1` idempotent + deep-merge + validates every color; full 9-color + typography/spacing/rules/radius/density/mode field set; `@type` per group | `theme.ex` struct + resolver |
| **D-02** | Web concepts excluded by construction (no shadow/z-index/motion/opacity/gradient/scales/weight-axis/letter-spacing); industry-agnostic `lib/` guard | struct shape + new guard test |
| **D-03** | Type scale `%{display: 21, title: 16.5, subtitle: 13, body: 10.5, small: 9, caption: 8}`; `leading: 1.2`; all integers/single-decimals, no `:math.pow` | `default/0` typography |
| **D-04** | `on_accent` auto-derived via WCAG max-contrast (threshold 0.179), returns one of theme's own tuples, overridable, float picks branch only — integer output | private `on_accent_for/*` |
| **D-05** | Mined-Swiss `default/0` palette + dark swap targets (table of `{r,g,b}`); `background = {255,255,255}` forced; fonts default `%{heading: :default, body: :default, mono: :default}` | `default/0` + `dark/1` |
| **D-06** | Adapter-tier registration + `@moduledoc tags: [:adapter]`; helpers `defp`/`@doc false`; reconcile **every** hidden-modules/byte-equality assertion | `api.gen.ex` + both test files |
| **R1** | `leading` ships 1.2 (metric no-op), 1.35 is a Phase-123 target | — |
| **R2** | Dark `on_accent` stays white (accent fill unchanged) | `dark/1` |

**Values source of truth:** `brand/tokens/tokens.json` (`raw` block, verified read). The exact hex→tuple mappings for D-05 are confirmed present: `ink-900 #101827`, `ink-500 #5B6573`, `blue-600 #2C6BED`, `sheet-000 #FFFFFF`, `paper-100 #F7F3EA`, `line-400 #C4BCA9`, `green-700 #147A4B`, `red-700 #C24132`, and the dark `night-*`/`paper-d-*`/`green-300`/`red-300` families. Mine, don't invent. [VERIFIED: brand/tokens/tokens.json:18-52]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| THEME-01 | Public `Rendro.Theme` struct defines FULL token shape up front | D-01 field set; `defstruct` + shared module attrs pattern (Format precedent); bare-map groups drop into existing S1 seam shape (`invoice.ex:466`) |
| THEME-02 | `resolve/1` idempotent, every color role integer `{r,g,b}` validated via `Color.validate/1`, instructive raise on bad token | `Color.validate/1` returns `:ok \| {:error, String.t()}` (`color.ex:67`); reuse as-is, raise on `{:error, msg}` |
| THEME-03 | Adapter/Evolving tier in `priv/public_api.json`, `@spec` on every public fn, doc note, helpers private/`@doc false` | `@moduledoc tags: [:adapter]` + one line in `api.gen.ex:@public_modules`; Format is the exact precedent (`format.ex:26`) |
| THEME-04 | Web concepts excluded by construction; flat-elevation guidance in moduledoc | D-02; struct simply has no such fields; guidance is prose |
| COLOR-01 | 7 core roles + optional positive/negative as `{r,g,b}` read by role | D-05 palette; matches existing 7-role `palette/1` map + adds on_accent/positive/negative |
| COLOR-02 | `from_brand/2` from single `accent:` seed, `on_accent` derived, emits tokens only, registers no asset | D-04; returns a `%Theme{}`, never touches `FontRegistry`/`AssetRegistry` |
| CONTRACT-01 | Regenerate manifest via `mix rendro.api.gen`, reconcile ALL hidden-modules assertions incl. duplicate in `manifest_test.exs` | Both byte-equality assertions enumerated below (§Red→Green) |
| CONTRACT-03 | Industry-agnostic `lib/` guard fails if `theme.ex` names an industry/brand; one theme + `from_brand/2` only | Tripwire pattern: `File.read!("lib/rendro/theme.ex")` + `refute source =~ term` (mirrors `integrations_claims_test.exs:37-42`) |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `%Theme{}` value + resolve/default/dark/from_brand | Pure value (adapter tier module) | — | Inert data; the deterministic pipeline never sees it this phase (CONTEXT §Integration Points) |
| Color validation | `Rendro.Color` (existing) | — | Reuse `validate/1`; no new validator |
| Font role resolution | `Rendro.FontRegistry` (existing) | — | Roles are logical atoms on the existing path; `:default` built-in never raises |
| Manifest registration | `mix rendro.api.gen` + `priv/public_api.json` | contract tests | Adapter-tier surface is generated, then byte-compared |
| Industry guard | new `test/` tripwire | — | Static source grep, mirrors existing tarball/branding guards |

## Standard Stack

Zero new dependencies. Everything is Elixir stdlib on existing surfaces. [VERIFIED: mix.exs — no new deps needed; `stream_data ~> 1.3` already present for property tests, mix.exs:63]

### Core (all existing, in-repo)
| Module | Purpose | Integration fact |
|--------|---------|------------------|
| `Rendro.Color` | `validate/1` per-role color check | `@spec validate(term()) :: :ok \| {:error, String.t()}` — `color.ex:67-79` |
| `Rendro.FontRegistry` | logical font atoms; `:default` built-in | `@default_font :default` always registered (`font_registry.ex:11,16`) |
| `Rendro.Text` | metric no-op target | `size: 12, line_height: 1.2, widows: 2, orphans: 2` defaults (`text.ex:18-22`) |
| `Base.decode16!` | hex→`{r,g,b}` at authoring boundary | stdlib; ~2 lines with binary match |
| `Mix.Tasks.Rendro.Api.Gen` | manifest generator | `@public_modules` list at `api.gen.ex:44-104`; add `Rendro.Theme` in adapter block |

**Installation:** none. (Confirmed: REQUIREMENTS "Out of Scope" bars new runtime/optional/dev deps.)

## Package Legitimacy Audit

Not applicable — this phase installs **zero** external packages. All modules referenced are first-party (`Rendro.*`) or Elixir/OTP stdlib (`Base`, `:erlang`, `:crypto`). No registry verification required.

## Concrete Integration Facts (highest-value output)

### `lib/rendro/recipes/invoice.ex` — the S1 `palette/1` seam (`defp palette/1`, L466)
The `%Theme{}.colors` map must be a drop-in for this shape. Exact map emitted today [VERIFIED: invoice.ex:466-481]:
```elixir
defp palette(opts) do
  overrides = Keyword.get(opts, :palette, %{})
  Map.merge(
    %{
      ink: {0, 0, 0}, muted: {0, 0, 0}, accent: {0, 0, 0}, on_accent: {0, 0, 0},
      background: {255, 255, 255}, surface: {255, 255, 255}, rule: {0, 0, 0}
    },
    overrides
  )
end
```
- Role keys today: **7** — `ink, muted, accent, on_accent, background, surface, rule`. Theme's `colors` map is a **superset**: it adds `positive` and `negative` (D-01 requires all 9 always present, never nil).
- It is a **bare map** (not a struct) → confirms D-01's "groups are bare typed maps" is a literal drop-in; zero call-site churn when Phase 120 wires it.
- The `:palette` override merge idiom (`Map.merge(defaults, overrides)`) is the same deep-merge shape `resolve/1` should use for the `colors` group. This phase does NOT touch this file (recipe wiring is Phase 120).

### `lib/rendro/color.ex` — `validate/1` (L67) + float determinism
- `@spec validate(term()) :: :ok | {:error, String.t()}` [VERIFIED: color.ex:67]. Success clause guards `is_integer` and `0..255` on all three components (L68-74). `resolve/1` calls this on **every** color role and raises the returned `{:error, reason}` message (THEME-02 errors-as-product). The error message is already instructive (What/Where/Why/Next, mentions the hex footgun) — reuse verbatim; do NOT build a new validator (CONTEXT: "reuse as-is; no new validator needed").
- **Float determinism context:** the only float math in this module is `format_num(n) when is_float(n) -> :erlang.float_to_binary(n * 1.0, decimals: 4)` (`color.ex:136-138`), applied at **draw time** by `rg/1`/`rg_stroke/1` (L14, L28) on `r/255` etc. Implication for Theme: keep the shipped `colors` map **integer tuples** so no float ever enters the Theme value; the `/255` float conversion happens later in the render pipeline, not in `%Theme{}`. `on_accent` luminance floats must pick a **branch** only and never appear in the output tuple (D-04).

### `lib/rendro/text.ex` — metric no-op target (`%Text{}`, L14-23)
`@enforce_keys [:content]`; defaults: `font: "Helvetica", size: 12, color: {0,0,0}, line_height: 1.2, widows: 2, orphans: 2` [VERIFIED: text.ex:14-23]. Type: `line_height: float()`, `widows/orphans: non_neg_integer()` (L34-36).
- Theme's `typography.leading` is a **line-height multiplier** with the **same semantics** as `Text.line_height` — ship **1.2** so it is metric-identical to the `%Text{}` default (R1/TYPE-03). `widows`/`orphans` ship **2** to match. Typography is not *applied* to `%Text{}` this phase (that's Phase 122) — but shipping the identical numbers now makes that later application a proven no-op.

### `lib/rendro/font_registry.ex` — logical roles + typed error
- `@default_font :default`; `defstruct fonts: %{@default_font => @helvetica_descriptor}` — the built-in is **always registered** (`font_registry.ex:11,16,68-69`). So `default/0`'s `fonts: %{heading: :default, body: :default, mono: :default}` never raises with no fonts registered (D-05). [VERIFIED: font_registry.ex:11-16]
- Typed error path: `fetch_descriptor/2` returns `{:error, {:unknown_logical_font, logical_name}}` (`font_registry.ex:390-395`). The public `resolve/3` (`font_registry.ex:221`) threads that out. The `{:unknown_logical_font,_}` → `{:unknown_text_font,_}` surfacing and the raise happen **downstream in the build/measure pipeline** (TYPE-02, Phase 122) — **not** in Theme. Phase 119's `default/0` fonts are just three logical atoms; no shape change, no substitution.
- Note: the CONTEXT/REQUIREMENTS reference `build.ex:111` raising `{:unknown_text_font,_}`; that raise is out of this phase's scope (Theme stores atoms, does not resolve fonts). Do not add font resolution to Theme.

### `priv/public_api.json` + `mix rendro.api.gen` — adapter-tier registration
- **The registration mechanism is a single list.** `@public_modules` in `api.gen.ex:44-104` is the source of truth. Add `Rendro.Theme` to the **adapter-tier block** (alongside `Rendro.Format` at `api.gen.ex:86`). [VERIFIED: api.gen.ex:44-104]
- Tier is derived from `@moduledoc tags: [:adapter]` via `Code.fetch_docs/1` at gen time (`api.gen.ex:116-121`, `run/1`). The Format precedent is exact: `@moduledoc tags: [:adapter]` at `format.ex:26`, and its manifest entry is `"tier": "adapter"` with sorted `functions`/`types` (`priv/public_api.json:247-253`). [VERIFIED]
- The generated entry sorts functions and types alphabetically (`api.gen.ex:140-158`, `encode_manifest/1`), pretty JSON + trailing `"\n"` (`api.gen.ex:125`). To regenerate: `mix rendro.api.gen`, then commit `priv/public_api.json`.
- Public function surface that will be manifested for `Rendro.Theme`: `default/0`, `dark/1`, `from_brand/2`, `resolve/1` (all `@spec`'d per THEME-03). Public **types**: `t` + per-group types (rgb, colors, typography, spacing, rules, radius, font_role, type_step) per D-01. Helpers (`on_accent_for`, dark-swap, hex→tuple, normalize) stay `defp`/`@doc false` so they never enter the manifest.

## Red→Green manifest reconcile — FULL enumerated list (the D-06 trap)

Adding `Rendro.Theme` to `@public_modules` and giving it `@moduledoc tags: [:adapter]` makes it appear in a freshly-generated manifest but **not** in the checked-in `priv/public_api.json` until `mix rendro.api.gen` runs and is committed. **Two structurally-identical byte-equality assertions** will red-build. The plan MUST list BOTH. There are also several hidden-modules assertions that must stay green (they should, because helpers are `defp`) — enumerated so the plan can confirm.

### Assertions that RED-BUILD until `mix rendro.api.gen` is run + committed

| # | File:line | Assertion (exact) | Why it goes red |
|---|-----------|-------------------|----------------|
| **RG-1** | `test/docs_contract/public_api_contract_test.exs:72` | `assert fresh_json == checked_in` (in describe "manifest surface equality (D-01/D-03)", test "freshly-generated manifest is byte-identical…", L25) | Fresh manifest now contains `Elixir.Rendro.Theme`; checked-in file does not → drift diff + byte mismatch |
| **RG-2** | `test/rendro/public_api/manifest_test.exs:98` | `assert fresh_json == checked_in` (in describe "idempotency and byte-equality (D-15)", test at L74) | **The plan-unlisted duplicate** — same byte-compare, different file. This is the Phase-115 lesson (D-06). |

Both use `Mix.Tasks.Rendro.Api.Gen.public_modules()` + `PublicApi.build_manifest/1` + `encode_manifest(...) <> "\n"` and compare to `File.read!("priv/public_api.json")`. A single `mix rendro.api.gen` + commit turns **both** green simultaneously. [VERIFIED: public_api_contract_test.exs:30-79; manifest_test.exs:82-104]

### Assertions that MUST STAY GREEN (confirm, don't break)

| # | File:line | Assertion | Stays green because |
|---|-----------|-----------|---------------------|
| G-1 | `public_api_contract_test.exs:115` | `assert module_doc == :hidden` for `hidden_modules` list (L85-93: CidFont, FontSubsetter, Text.Bidi, Audit, Examples, ExamplesData) | Theme is not in this list; adding a `:hidden` module isn't required |
| G-2 | `public_api_contract_test.exs:165` | "every public module has exactly one tier tag: :stable xor :adapter" (L164) | `Rendro.Theme` has exactly `[:adapter]` — one tier tag |
| G-3 | `public_api_contract_test.exs:211` | stable-tier `@spec` coverage (L210) | Theme is adapter-tier, not stable; not in scope of this assertion — but ALL its public fns get `@spec` anyway (THEME-03) |
| G-4 | `manifest_test.exs:37` | `refute mod_key in module_keys` for hidden list (L29-34) | Theme is public, not hidden; unaffected |
| G-5 | `manifest_test.exs:57` | "every module entry has tier stable or adapter — no untagged entries" (L56) | Theme is `adapter` → passes; would FAIL if `@moduledoc tags:` is forgotten |
| G-6 | `manifest_test.exs:139` | `redact_*` helpers `doc: :hidden` in `Rendro.Sign` | unrelated |
| G-7 | schema validation (`public_api_contract_test.exs:17`, `manifest_test.exs:17`) | manifest validates against `priv/schemas/public_api.schema.json` | new adapter entry with functions/tier/types conforms to schema |

**Grep receipts** (so the planner can trust the enumeration is complete):
- `grep -n "fresh_json == checked_in"` → exactly 2 hits: `public_api_contract_test.exs:72`, `manifest_test.exs:98`.
- `grep -rn "hidden_modules"` in `test/rendro/public_api/` + `test/docs_contract/` → `public_api_contract_test.exs:85`, `manifest_test.exs:29` (both are *hidden-modules* lists that Theme is NOT in — no change needed).
- There is **no third** byte-compare or Theme-relevant hidden assertion elsewhere (`rubric_manifest_contract_test.exs` concerns the rubric manifest, not `public_api.json`).

**Reconcile procedure for the plan:** (1) implement `theme.ex` with `@moduledoc tags: [:adapter]` + all `defp` helpers; (2) add `Rendro.Theme` to `api.gen.ex:@public_modules` adapter block; (3) `mix rendro.api.gen`; (4) commit regenerated `priv/public_api.json`; (5) run `mix test test/docs_contract/public_api_contract_test.exs test/rendro/public_api/manifest_test.exs` → both RG-1 and RG-2 green. Pre-declare RG-1 **and** RG-2 in the plan as the expected red→green pair.

## CONTRACT-03 industry-agnostic guard — pattern to mirror

Model the new guard on the existing source-grep tripwires. Exact working pattern from `test/docs_contract/integrations_claims_test.exs:37-42` [VERIFIED]:
```elixir
source = File.read!("lib/rendro/theme.ex")
for term <- forbidden_terms, do: refute source =~ term
```
- `File.read!("lib/rendro/theme.ex")` then `refute source =~ term` for each forbidden industry/brand token (e.g. "invoice", "medical", "legal", "restaurant", named brands). The `accessibility_overclaim_test.exs:89-93` variant (`refute String.contains?(content, term)`) is equivalent.
- Place under `test/docs_contract/` for consistency with sibling guards. Assert the positive too: Theme ships exactly `default/0` + `from_brand/2` and **no** genre/preset/catalog/configurator identifiers (grep `theme.ex` refutes "preset"/"catalog"/"configurator"). This holds D-02/CONTRACT-03 "one theme + from_brand/2 only."

## Architecture Patterns

### Recommended module structure (single file)
```
lib/rendro/theme.ex
  @moduledoc "... field shape stable; token values & rendered bytes may evolve ..."
  @moduledoc tags: [:adapter]
  # module attributes = single source shared by defstruct AND default/0
  @default_colors %{ink: {16,24,39}, ...}          # integer tuples, mined from tokens.json
  @default_typography %{fonts: %{...}, scale: %{...}, leading: 1.2, widows: 2, orphans: 2}
  @default_spacing / @default_rules / @default_radius ...
  defstruct colors: @default_colors, typography: @default_typography, ...,
            density: :comfortable, mode: :light
  @enforce_keys []                                  # explicit empty (D-01)
  @type rgb :: {0..255, 0..255, 0..255}
  @type t :: %__MODULE__{...}                       # + per-group @type
  def default/0  ·  def dark/1  ·  def resolve/1  ·  def from_brand/2   # @spec each
  # everything else defp: on_accent_for, luminance, contrast_ratio, linearize,
  #   hex_to_rgb (Base.decode16!), deep_merge, normalize
```

### Pattern 1: Shared-module-attribute defaults (no half-nil trap)
**What:** defaults live in `@attr`s referenced by both `defstruct` and `default/0`, so a bare `%Rendro.Theme{}` already equals the light default (D-01).
**Precedent:** `Rendro.Format` keeps `@labels` as a module attr consumed by `label/1` (`format.ex:28-34,108`). Same idiom for Theme's group defaults.

### Pattern 2: Idempotent deep-merge resolver
**What:** `resolve/1` accepts keyword | map | `%Theme{}`, deep-merges onto defaults (partial input never `KeyError`s at draw time), validates every color, returns `%Theme{}`. `resolve(resolve(x)) == resolve(x)`.
**Precedent:** the `Map.merge(defaults, overrides)` override idiom in `palette/1` (`invoice.ex:469-480`) — extend to nested groups with a small `defp deep_merge/2`.

### Pattern 3: Branch-only float derivation (`on_accent`)
**What:** compute WCAG relative luminance of `accent`, compare to threshold 0.179 (D-04); the float chooses **which** integer tuple (`background` vs `ink`) to return. No float in the output. Override via `on_accent:` respected, never recomputed.

### Anti-Patterns to Avoid
- **Nested public structs for groups** — each would become its own Hyrum surface + `@type` + tier tag in the manifest (D-01 rejects; use bare maps).
- **`:math.pow` type scale** — materialize explicit points (D-03); a formula leaks irrational floats into the shipped map (TYPE-01).
- **Tinting `background`** — must stay `{255,255,255}`; MODE-02 (Phase 121) gates the dark fill-rect on `background != white` and requires the light default to emit no rect (D-05). A tinted page breaks byte-identity and prints as full-page ink.
- **Re-deriving a new color validator** — reuse `Color.validate/1`.
- **Resolving fonts inside Theme** — store logical atoms only; resolution is Phase 122.

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Color tuple validation | custom range checker | `Rendro.Color.validate/1` (`color.ex:67`) | Already instructive (hex footgun, What/Why/Next) |
| Font role storage | new font map type | logical atoms + `FontRegistry` `:default` | `:default` always registered; typed error downstream |
| hex→rgb | manual parsing | `Base.decode16!` + binary match | 2 lines, stdlib |
| Manifest entry | hand-edit `priv/public_api.json` | `mix rendro.api.gen` | Byte-equality tests reject hand edits (RG-1/RG-2) |
| Deterministic JSON | custom encoder | `encode_manifest/1` (`api.gen.ex:140`) | Sorted keys + trailing `\n` already handled |

**Key insight:** Every subsystem this module touches already has a tested, canonical entry point. The phase is composition, not construction.

## Runtime State Inventory

This is a **greenfield module** (new `theme.ex`), not a rename/refactor. Still, the "one-way door" makes the *manifest* a form of registered state:

| Category | Items found | Action required |
|----------|-------------|-----------------|
| Stored data | None — Theme is a pure value, persists nothing | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts / generated files | `priv/public_api.json` is a **generated, committed** artifact that will drift the moment `@public_modules` gains `Rendro.Theme` | Run `mix rendro.api.gen`, commit the regenerated file (RG-1/RG-2). This is the only "registered state" the phase mutates. |

**Verified:** no ChromaDB/Mem0/n8n/Task-Scheduler/SOPS analogs exist in this Elixir library; the only regenerable registered artifact is the API manifest.

## Common Pitfalls

### Pitfall 1: Reconciling only one byte-equality assertion
**What goes wrong:** plan lists `public_api_contract_test.exs` (RG-1), forgets `manifest_test.exs` (RG-2) → surprise red build in a second file.
**Why:** two independent test modules byte-compare the same `priv/public_api.json` with identical logic.
**Avoid:** pre-declare BOTH RG-1 and RG-2. `grep -rn "fresh_json == checked_in" test/` returns exactly two hits — use it as the completeness check.
**Warning sign:** a green `public_api_contract_test.exs` but a red `Rendro.PublicApi.ManifestTest`.

### Pitfall 2: A float leaking into the shipped `colors`/`scale` map
**What goes wrong:** using `r/255`, `:math.pow`, or a computed luminance in the stored value breaks byte-reproducibility.
**Avoid:** keep every shipped value an integer (`{r,g,b}`) or an explicit int/single-decimal (type scale). Luminance floats pick a branch only. Assert integer-ness in a unit test (see Validation Architecture).

### Pitfall 3: Forgetting `@moduledoc tags: [:adapter]`
**What goes wrong:** module appears in manifest with an untagged tier → `manifest_test.exs:57` ("no untagged entries") and the tier-tag assertions fail with a confusing error unrelated to byte-equality.
**Avoid:** copy the Format header verbatim (`format.ex:26`).

### Pitfall 4: `background` accidentally tinted from `paper-100`
**What goes wrong:** using warm paper for `background` (it's the "page") trips MODE-02's `background != white` gate in Phase 121 and breaks v2.10 byte-identity.
**Avoid:** `background = {255,255,255}` (sheet-000); warm character lives in `surface` (paper-100) + `rule` (line-400). D-05 is explicit.

## Code Examples

### Reuse `Color.validate/1` in `resolve/1` (raise on error)
```elixir
# Source: lib/rendro/color.ex:67 (validate/1 :: :ok | {:error, String.t()})
for {role, value} <- colors do
  case Rendro.Color.validate(value) do
    :ok -> :ok
    {:error, reason} -> raise ArgumentError, reason   # instructive message already built
  end
end
```

### hex→rgb at the authoring boundary
```elixir
# stdlib; keeps tokens.json hex authorable while shipping integer tuples
defp hex_to_rgb("#" <> hex), do: hex_to_rgb(hex)
defp hex_to_rgb(hex) do
  <<r, g, b>> = Base.decode16!(hex, case: :mixed)
  {r, g, b}
end
```

### Adapter-tier module header (mirror Format)
```elixir
# Source: lib/rendro/format.ex:1-26
@moduledoc """
... The field shape is stable; token values and rendered bytes may evolve
across minor versions. Express elevation flatly via `surface` tint + `rule` hairline.
"""
@moduledoc tags: [:adapter]
```

## State of the Art

| Old approach | Current approach | Impact |
|--------------|------------------|--------|
| Inline `{r,g,b}` literals in recipe sections | S1 `palette/1` role map (shipped v2.10) | `%Theme{}.colors` is a literal drop-in for the existing map shape |
| Internal `@moduledoc false` helper modules | Adapter/Evolving tier w/ "output may evolve" note (Format, Phase 115) | Theme follows the exact same tier + reconcile playbook |

**Not applicable / avoided:** W3C DTCG JSON token files, Style Dictionary, Tailwind numbered scales — all considered and rejected in CONTEXT (semantic roles, not palettes; explicit points, not formulas).

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | No third byte-equality or Theme-relevant hidden-modules assertion exists beyond RG-1/RG-2 | Red→Green | LOW — verified via `grep -rn "fresh_json == checked_in"` (2 hits) and `grep -rn hidden_modules`; if a plan adds a new test that byte-compares, it would be authored in-phase and thus known |
| A2 | `mix rendro.api.gen` regenerating with `Rendro.Theme` added produces a schema-valid entry with no manual schema change | Integration facts | LOW — Format's adapter entry already conforms; schema accepts functions/tier/types |
| A3 | Placing the CONTRACT-03 guard under `test/docs_contract/` matches convention | CONTRACT-03 | LOW — sibling guards live there; location is cosmetic |

**All other findings are `[VERIFIED]` against live files this session.**

## Open Questions (RESOLVED)

1. **Exact `@type` phrasing for group maps (`colors`, `typography`, etc.)** — CONTEXT leaves this to planner discretion. **RESOLVED:** Plan 01 Task 1 uses closed `%{required(...) => ...}` map types so the frozen shape is machine-checkable; the acceptance criteria include confirming `mix rendro.api.gen` emits them cleanly on first gen.
2. **`density: :compact` shallow-honoring mechanics in `resolve/1`** — planner discretion (D-01). **RESOLVED:** Plan 01 Task 1 honors `:compact` shallowly as a pure leading/spacing nudge with no new field; not gated by any golden this phase.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix toolchain | compile + `mix rendro.api.gen` | ✓ | project standard | — |
| `stream_data` | property-based unit tests | ✓ | `~> 1.3` (`mix.exs:63`) | example-based tests |
| `:crypto` / `Base` | golden sha256 + hex decode | ✓ (OTP) | — | — |

No external tools/services. Phase is pure code + tests.

## Validation Architecture

Nyquist validation enabled. All tests are **pure unit tests** (no rendering, no I/O) except the existing golden suite which must be re-run **unchanged** to prove zero regression.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (stdlib) + `stream_data ~> 1.3` for properties (`mix.exs:63`) |
| Config file | none custom — standard `mix test` |
| Quick run command | `mix test test/rendro/theme_test.exs` (new) |
| Full suite command | `mix test` |
| Manifest reconcile check | `mix test test/docs_contract/public_api_contract_test.exs test/rendro/public_api/manifest_test.exs` |
| Regression proof | `mix test test/rendro/recipes/` (all 7 recipe suites + `*_byte_identity_test.exs`) — must stay green with NO golden re-bless |

### Requirement → Test Map
| Req / Criterion | Behavior | Test type | Exact assertion / command | File exists? |
|-----------------|----------|-----------|---------------------------|--------------|
| THEME-01 | Full field set present on `%Theme{}` | example unit | `t = %Rendro.Theme{}` then assert `Map.keys(t.colors)` == the 9 roles; assert `t.typography.scale` has 6 steps; assert `:spacing/:rules/:radius/:density/:mode` present | ❌ Wave 0 `theme_test.exs` |
| THEME-01 | Bare `%Theme{}` == light default (no half-nil) | example | `assert %Rendro.Theme{} == Rendro.Theme.default()` | ❌ Wave 0 |
| THEME-02 | `resolve/1` idempotent | **property** | `check all t <- theme_or_partial(), do: assert Theme.resolve(Theme.resolve(t)) == Theme.resolve(t)` | ❌ Wave 0 |
| THEME-02 | deep-merge of partial input never `KeyError`s | **property** | `check all part <- partial_map(), do: (t = Theme.resolve(part); assert match?(%Theme{}, t))` | ❌ Wave 0 |
| THEME-02 | every color role integer `{r,g,b}` | example/property | for each role: `assert Rendro.Color.validate(get(t, role)) == :ok` | ❌ Wave 0 |
| THEME-02 | invalid token raises instructive error | example | `assert_raise ArgumentError, ~r/hex/, fn -> Theme.resolve(colors: %{ink: "#000"}) end` | ❌ Wave 0 |
| COLOR-01 | 9 roles are the only color surface | example | assert exact key set of `t.colors` == `[:accent,:background,:ink,:muted,:negative,:on_accent,:positive,:rule,:surface]` | ❌ Wave 0 |
| COLOR-02 | `from_brand/2` from single `accent:` seed, `on_accent` derived | example | `t = Theme.from_brand(accent: {44,107,237}); assert t.colors.accent == {44,107,237}; assert t.colors.on_accent in [t.colors.background, t.colors.ink]` | ❌ Wave 0 |
| COLOR-02 | `on_accent` branch-selection determinism | **property** | `check all rgb <- rgb_gen(), do: (r = Theme.from_brand(accent: rgb).colors.on_accent; assert r == Theme.from_brand(accent: rgb).colors.on_accent and is_integer(elem(r,0)))` | ❌ Wave 0 |
| COLOR-02 | override respected, never recomputed | example | `assert Theme.from_brand(accent: {44,107,237}, on_accent: {1,2,3}).colors.on_accent == {1,2,3}` | ❌ Wave 0 |
| COLOR-02 | emits tokens only, registers NO asset | example | assert `from_brand/2` returns `%Theme{}` and does not call `FontRegistry`/`AssetRegistry` (assert no side effect: pure return; optionally assert returned struct has no font/asset refs beyond logical atoms) | ❌ Wave 0 |
| THEME-03 | adapter tier + specs + manifest | contract | `mix rendro.api.gen` then RG-1 `public_api_contract_test.exs:72` + RG-2 `manifest_test.exs:98` green; assert `PublicApi.tier_of(Rendro.Theme) == :adapter` | ✅ RG tests exist |
| THEME-03 | every public fn has `@spec` | contract | Code.Typespec check — all of `default/0,dark/1,from_brand/2,resolve/1` specced | ✅ (adapter not in stable-spec assertion; add explicit check in `theme_test.exs`) |
| THEME-03 | helpers private/`@doc false` | contract | `refute` any of `on_accent_for/hex_to_rgb/deep_merge` appear in manifest `functions` for `Elixir.Rendro.Theme` | ❌ Wave 0 (or covered by RG byte-equality) |
| THEME-04 | web concepts absent by construction | example | assert `%Theme{}` has no `:shadow/:elevation/:z_index/:opacity/:gradient` keys anywhere (recurse group maps) | ❌ Wave 0 |
| CONTRACT-01 | ALL hidden/byte assertions reconcile | contract | run RG-1 + RG-2 together, both green after gen+commit | ✅ exist |
| CONTRACT-03 | `theme.ex` names no industry/brand | **source-grep guard** | `source = File.read!("lib/rendro/theme.ex"); for t <- forbidden, do: refute source =~ t` (mirror `integrations_claims_test.exs:37-42`); also refute "preset"/"catalog"/"configurator" | ❌ Wave 0 new guard |
| **Success Criterion 1** (full shape) | see THEME-01 rows | | | |
| **Success Criterion 2** (resolve/from_brand) | see THEME-02 + COLOR-02 rows | | | |
| **Success Criterion 3** (roles only + exclusions) | see COLOR-01 + THEME-04 rows | | | |
| **Success Criterion 4** (tier + red→green) | see THEME-03 + CONTRACT-01 rows | | | |
| **Success Criterion 5** (industry guard) | see CONTRACT-03 row | | | |

### Byte-reproducibility checks (explicit)
- **All shipped color values are integers:** `for {_r, {r,g,b}} <- Theme.default().colors, do: assert is_integer(r) and is_integer(g) and is_integer(b)` (and same for `Theme.dark(Theme.default())`).
- **Type-scale values are integers or single-decimals:** `for {_step, v} <- Theme.default().typography.scale, do: assert v == Float.round(v, 1)` (rejects irrationals from any accidental `:math.pow`).
- **No float in `on_accent` output:** covered by the branch-selection property above (`is_integer(elem(r,0))`).

### Zero-recipe-change regression proof (the central guard)
This phase touches **no** recipe file, so every v2.10 golden must remain byte-identical. Prove by running the existing suites **unchanged, without blessing**:
- `mix test test/rendro/recipes/` — includes `invoice_byte_identity_test.exs` (frozen sha `c3625eb5…`, invoice_byte_identity_test.exs:12), `payslip_byte_identity_test.exs`, `ticket_byte_identity_test.exs`, plus `invoice_test.exs`/`certificate_test.exs`/`statement_test.exs`/`receipt_test.exs`/`payslip_test.exs`/`ticket_test.exs`/`branded_invoice_test.exs`.
- The 62 committed `priv/goldens/**/*.sha256` files (across certificate/invoice/payslip/receipt/statement/ticket) must NOT change. **Do NOT set `MIX_GOLDEN_BLESS`.** A changed hash is a defect, not a refresh.
- Assertion of intent: since `theme.ex` is a new file imported by nothing this phase, a full `mix test` green with zero golden diff *is* the proof. The planner should add a task-level check: `git status priv/goldens` shows no modifications after the suite runs.

### Sampling rate
- **Per task commit:** `mix test test/rendro/theme_test.exs` (+ the new CONTRACT-03 guard).
- **Per wave merge:** `mix test test/rendro/recipes/ test/docs_contract/public_api_contract_test.exs test/rendro/public_api/manifest_test.exs`.
- **Phase gate:** full `mix test` green + `git status priv/goldens` clean, before `/gsd-verify-work`.

### Wave 0 gaps
- [ ] `test/rendro/theme_test.exs` — covers THEME-01/02/04, COLOR-01/02 (example + property).
- [ ] `test/docs_contract/theme_industry_guard_test.exs` — CONTRACT-03 source-grep guard.
- [ ] Property generators for `theme_or_partial()`, `partial_map()`, `rgb_gen()` — can live in `test/rendro/theme_test.exs` or extend `test/support/generators.ex`.
- [ ] No framework install needed (ExUnit + stream_data already present).

## Security Domain

`security_enforcement` posture: this phase introduces **no** attack surface — a pure, inert value struct with no I/O, no deserialization of untrusted input at runtime, no network/filesystem access, no secrets. The only external read is `brand/tokens/tokens.json` at **authoring time** (values transcribed into module attributes as literals), not at runtime.

### Applicable ASVS categories
| ASVS category | Applies | Standard control |
|---------------|---------|------------------|
| V5 Input Validation | yes (mild) | `resolve/1` validates every color via `Color.validate/1` and raises an instructive error on malformed input — this is the errors-as-product control, not a security boundary |
| V2/V3/V4 Auth/Session/Access | no | no auth surface |
| V6 Cryptography | no | `:crypto` used only for golden sha256 in tests, not in the module |

### Known threat patterns for a pure Elixir value module
| Pattern | STRIDE | Mitigation |
|---------|--------|------------|
| Atom exhaustion via `String.to_atom` on untrusted input | DoS | Theme stores font **roles** as compile-time atoms from `default/0`; do NOT `String.to_atom` any caller-supplied string. If `from_brand/2` ever accepts string keys, use `String.to_existing_atom` or a fixed keyword whitelist. |
| Malformed `{r,g,b}` reaching the render pipeline | Tampering | `Color.validate/1` in `resolve/1` rejects non-integer/out-of-range tuples before they can produce a malformed PDF operator. |

## Sources

### Primary (HIGH confidence — read live this session)
- `lib/rendro/recipes/invoice.ex:456-481` — S1 `palette/1` seam, exact 7-role map
- `lib/rendro/color.ex:67-138` — `validate/1` spec + `format_num` float boundary
- `lib/rendro/text.ex:14-37` — `%Text{}` defaults + types (metric no-op target)
- `lib/rendro/font_registry.ex:11-16,68-69,221,390-395` — `:default` built-in + `{:unknown_logical_font,_}` path
- `lib/mix/tasks/rendro/api.gen.ex:35,44-104,116-161` — `@public_modules`, tier via tags, deterministic encoder
- `lib/rendro/format.ex:1-26,108` — adapter-tier precedent (`@moduledoc tags: [:adapter]`, shared `@labels`)
- `priv/public_api.json:247-253` — Format's `"tier":"adapter"` manifest entry shape
- `test/docs_contract/public_api_contract_test.exs:17,72,85,115,165,211` — RG-1 + green-stay assertions
- `test/rendro/public_api/manifest_test.exs:17,29-37,56-57,74,98,139` — RG-2 + green-stay assertions
- `test/docs_contract/integrations_claims_test.exs:37-42,137-155` — `lib/`-source-grep guard pattern (CONTRACT-03)
- `test/docs_contract/branding_contract_test.exs` — sibling guard placement
- `test/rendro/recipes/invoice_byte_identity_test.exs:12,26-40` — frozen-sha regression pattern
- `test/support/golden.ex:44-47` — `assert_or_bless` sha256 mechanism
- `brand/tokens/tokens.json:18-52` — `raw` hex source of truth for D-05 values
- `mix.exs:63` — `stream_data ~> 1.3` availability
- `.planning/ROADMAP.md` §Phase 119 — goal + 5 success criteria

### Secondary (design contract, not re-decided)
- `.planning/phases/119-…/119-CONTEXT.md` — D-01..D-06, R1/R2 (locked)
- `.planning/REQUIREMENTS.md` — THEME/COLOR/CONTRACT rows + Out-of-Scope table

## Metadata

**Confidence breakdown:**
- Integration facts (signatures/lines/error tuples): HIGH — read live from source this session
- Red→green enumeration: HIGH — verified via `grep -rn "fresh_json == checked_in"` (exactly 2 hits) + hidden-modules greps
- Standard stack: HIGH — zero new deps; all first-party/stdlib
- Values (D-05 palette / D-03 scale): locked by CONTEXT; hex sources confirmed present in tokens.json

**Research date:** 2026-07-24
**Valid until:** 2026-08-23 (stable — pure in-repo integration; only invalidated by unrelated churn in `api.gen.ex`'s module list or the two byte-equality tests)
</content>
</invoke>

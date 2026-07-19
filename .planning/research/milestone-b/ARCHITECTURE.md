# Architecture Research — `Rendro.Theme` Integration (Milestone B / SEED-003 / v2.11)

**Domain:** Public PDF theming / design-token contract layered onto an existing deterministic PDF engine.
**Researched:** 2026-07-19
**Confidence:** HIGH — every integration point below is grounded in the actual v2.10 source (`lib/rendro/{color,text,path}.ex`, `lib/rendro/recipes/*.ex`, `lib/rendro/pipeline/paginate.ex`, `priv/public_api.json`), not assumed.

---

## Executive answer (the load-bearing findings)

1. **The engine never sees a `%Theme{}`.** `Rendro.Theme` is a pure recipe-layer value. Recipes resolve it into concrete `%Rendro.Text{color:,size:,font:}` and `%Rendro.Path{fill:}` **before** `Rendro.Document` is built. The `build → compose → measure → paginate → render → validate` pipeline is untouched. This is the whole determinism story: theming adds **zero** core surface.

2. **Light/dark across pagination is already solved by the engine — for free.** `Rendro.Pipeline.Paginate.apply_page_template/5` (`paginate.ex:909`) runs **per page** (every `idx`, including overflow pages), emits every **non-body** region's blocks, and **prepends** them (`anchored_blocks ++ page.blocks`) so they render *beneath* body content. A full-page background `{:rect}` fill is therefore a **page-template concern**: add a full-page `:background` region + a one-block background section. Every page (including overflow) gets the dark fill deterministically, underneath everything, with **no paginate change**.

3. **The S1 seam already exists in 3 of 7 recipes, keyed on the exact SEED-003 roles.** `Invoice`, `Payslip`, `Ticket` each have a private `palette(opts)` returning `%{ink,muted,accent,on_accent,background,surface,rule}`. Migration for those three is a **one-function swap** (`palette/1` reads `Theme.resolve(opts[:theme]).colors`). The other four (`BrandedInvoice`, `Certificate`, `Receipt`, `Statement`) need the seam introduced + literal colors (`{0,0,0}`, `{34,34,34}`) migrated to roles.

4. **Tier decision: `Rendro.Theme` ships on the `adapter` (Evolving) tier, not Stable.** Field *names/role semantics/arities* are frozen-by-intent (define full shape now); concrete default token **values** and the fidelity of the honored-with-defaults tiers (spacing/rules/radius/density) are Evolving. This is the identical discipline used for `Rendro.Format` in Milestone A and is the correct resolution of the "full-shape-now vs tiered-implementation" tension.

---

## System Overview — where `Theme` sits

```
┌──────────────────────────────────────────────────────────────────────┐
│  AUTHOR / CALLER                                                       │
│    Rendro.Recipes.Invoice.document(data, theme: %Theme{} | [accent:]) │
├──────────────────────────────────────────────────────────────────────┤
│  RECIPE LAYER  (the ONLY layer that knows about %Theme{})             │
│                                                                        │
│   document/2 ─┐                                                        │
│               ├─ Theme.resolve(opts[:theme])  →  %Theme{} (once)       │
│   page_template/1 ─── reads theme → adds :background region (dark)     │
│   sections/2 ──────── reads theme.colors.* / theme.typography.*        │
│               │         via private palette(opts) (S1 seam)            │
│               ▼                                                        │
│   Concrete %Text{color,size,font}, %Path{fill}, %Region{}, %Block{}   │
├──────────────────────────────────────────────────────────────────────┤
│  ENGINE  (UNCHANGED — never sees %Theme{})                            │
│   build → compose → measure → paginate → render → validate            │
│                              │                                         │
│              apply_page_template/5 emits :background region           │
│              on EVERY page, prepended (underneath) → dark for free     │
└──────────────────────────────────────────────────────────────────────┘
```

`%Theme{}` is inert data resolved once and threaded through the 3 rungs. It resolves to primitives the engine already renders deterministically. **`Rendro.Document`, `Rendro.PageTemplate`, and the pipeline gain no theme-aware fields.**

---

## Component Responsibilities

| Component | Responsibility | New / Modified |
|-----------|----------------|----------------|
| `Rendro.Theme` (`lib/rendro/theme.ex`) | Pure value + `resolve/1`, `default/0`, `dark/1`, `from_brand/2`; holds `colors`/`typography`/`spacing`/`rules`/`radius`/`density`/`mode` | **NEW** |
| `palette(opts)` seam in each recipe | Return `theme.colors` map; sole source of role → RGB (no inline literals) | **MODIFIED** (3 swap, 4 add) |
| Background-section helper (shared) | Given `%Theme{}` + page geometry, emit the full-page `:background` region + `{:rect}` fill section (dark-mode only) | **NEW** (put in `Rendro.Recipes.Pagination` or a small `Rendro.Recipes.Theming` helper) |
| Recipe `page_template/1` | Prepend `:background` region when theme requires a fill; read type-scale for region sizing where relevant | **MODIFIED** (7 recipes) |
| Recipe `sections/2` | Read `theme.colors.*` + `theme.typography.*`; frozen colorless toy blocks stay literal | **MODIFIED** (7 recipes) |
| `Rendro.Pipeline.Paginate` | Already emits non-body regions per page, prepended | **UNCHANGED** (reused as-is) |
| `priv/public_api.json` / contract test / `support_matrix.json` / `artifacts.json` | Register `Rendro.Theme` (adapter), theming support row, S6 theme/mode tags | **MODIFIED (manifests)** |

---

## 1. Struct shape — full shape up front, tiered implementation

### Recommendation: one public struct, bare typed maps for token groups

Keep **`Rendro.Theme` as the single public module.** `colors`, `typography`, etc. are **bare maps** (not nested public structs), for three reasons:
- The existing S1 seam already returns a **bare map** and recipes already do `colors.ink` (Elixir map dot-access). Swapping to `theme.colors` is then a literal drop-in — no rewrite of the 46 existing `colors.*` reads.
- Fewer public modules ⇒ smaller manifest, smaller Hyrum surface (no `%Rendro.Theme.Colors{}` for callers to pattern-match exhaustively).
- Forward-compat: adding a role/step later is a non-breaking map-key addition; a nested `@enforce_keys` struct would make widening *feel* breaking to strict matchers.

Normalization/validation happens once, in `resolve/1` (fills defaults, validates every `{r,g,b}` via `Rendro.Color.validate/1`, raises errors-as-product on a bad token).

### Full public shape (define ALL of it in v2.11; implement in tiers)

```elixir
defmodule Rendro.Theme do
  @moduledoc tags: [:adapter]        # Evolving — see tier decision §6

  defstruct mode: :light,
            colors: %{},             # filled by resolve/1
            typography: %{},
            spacing: %{},
            rules: %{},
            radius: %{},
            density: :comfortable

  @type rgb :: {0..255, 0..255, 0..255}

  @type colors :: %{
          ink: rgb, muted: rgb, accent: rgb, on_accent: rgb,
          background: rgb, surface: rgb, rule: rgb,
          positive: rgb, negative: rgb          # optional roles, defaulted
        }

  @type typography :: %{
          fonts: %{heading: atom, body: atom, mono: atom},
          scale: %{display: number, title: number, subtitle: number,
                   body: number, small: number, caption: number},
          leading: float,          # → %Text{line_height}
          widows: non_neg_integer, # → %Text{widows}
          orphans: non_neg_integer # → %Text{orphans}
        }

  @type spacing :: %{xs: number, sm: number, md: number, lg: number, xl: number} # points
  @type rules   :: %{hairline: number, regular: number, heavy: number}           # stroke widths (pt)
  @type radius  :: %{none: number, sm: number, md: number}                       # corner radii (pt)
  @type density :: :comfortable | :compact

  @type mode :: :light | :dark

  @type t :: %__MODULE__{
          mode: mode, colors: colors, typography: typography,
          spacing: spacing, rules: rules, radius: radius, density: density
        }
end
```

### Tier map (what "define now, implement in tiers" means concretely)

| Field | Tier | v2.11 behavior |
|-------|------|----------------|
| `colors.*` (7 roles + `positive`/`negative`) | **Fully wired** | Every recipe reads roles; `dark/1` swaps a subset |
| `typography.fonts` / `.scale` / `.leading` / `.widows` / `.orphans` | **Fully wired** | Thread into `%Text{font,size,line_height,widows,orphans}` at compose time |
| `mode: :light \| :dark` | **Fully wired** | Variant selector via `dark/1` + background fill |
| `spacing`, `rules`, `radius`, `density` | **Honored-with-defaults** | Present in the struct with sane defaults; recipes read them **where they already have a corresponding literal** (e.g. `rules.hairline` for a 0.75 stroke, `radius.md` for a `{:rounded_rect}`). Not every recipe wires every optional token in v2.11 — but the *contract* exists so C/D can deepen fidelity without widening the struct. |

### Forward-compatibility / Hyrum's-Law discipline

- **`@enforce_keys []`** and construct only through `resolve/0..1`, `default/0`, `dark/1`, `from_brand/2`. Callers never `%Theme{colors: ..., typography: ...}`-build by hand, so adding a field later can't break them.
- **Bare maps for token groups** ⇒ adding a role/step is a non-breaking key addition.
- **Values are Evolving, not frozen.** Document explicitly (module doc + `api_stability.md`): the *field names and role semantics* are the contract; the *exact default RGB values and rendered typographic output may be tuned across minor versions*. This inoculates against Hyrum's Law on rendered bytes exactly as the `Format` adapter note did in Milestone A. Byte-determinism is a **within-version** guarantee (goldens are versioned), never a cross-version freeze of token values.
- **No accidental internals leak.** Keep luminance/contrast/dark-swap helpers **private or `@doc false`** so the contract test's hidden-set stays clean.

---

## 2. Resolution & threading

### Where `theme:` is resolved

`Rendro.Theme.resolve/1` is **idempotent** and accepts `nil | keyword | %Theme{}`:

```elixir
def resolve(nil),            do: default()
def resolve(%__MODULE__{} = t), do: normalize(t)   # identity-ish; fills any gaps, validates
def resolve(opts) when is_list(opts) or is_map(opts), do: default() |> merge(opts) |> normalize()
```

Because each of the three rungs is independently callable via the escape hatch, **each rung defensively calls `resolve/1`** at its top. Idempotency means `document → page_template → sections` effectively resolves once (resolve of a `%Theme{}` is identity). Concretely:

```elixir
def document(data, opts \\ []) do
  theme = Rendro.Theme.resolve(Keyword.get(opts, :theme))
  opts  = Keyword.put(opts, :theme, theme)      # thread the RESOLVED struct down
  template = page_template(opts)
  secs     = sections(data, opts)
  ...
end

def page_template(opts \\ []) do
  theme = Rendro.Theme.resolve(Keyword.get(opts, :theme))
  # ... use theme for :background region + type-scale-derived region sizing
end

def sections(data, opts \\ []) do
  theme = Rendro.Theme.resolve(Keyword.get(opts, :theme))
  opts  = Keyword.put(opts, :theme, theme)
  ...
end
```

This preserves the existing invariant that each rung is self-sufficient (a caller can invoke `sections/2` alone with `theme:` and get a fully-themed result).

### Migrating the private `palette(opts)` S1 seam

Today (`invoice.ex:466`):

```elixir
defp palette(opts) do
  overrides = Keyword.get(opts, :palette, %{})
  Map.merge(%{ink: {0,0,0}, muted: {0,0,0}, ...}, overrides)
end
```

After:

```elixir
defp palette(opts) do
  Rendro.Theme.resolve(Keyword.get(opts, :theme)).colors
end
```

- **Zero change at call sites.** All 46 existing `colors.ink` / `colors.muted` / `colors.rule` reads keep working — `theme.colors` is a map with the identical keys.
- **Backward `:palette` override:** if the `:palette` opt must survive as a documented escape hatch, keep it as a final `Map.merge(theme.colors, Keyword.get(opts, :palette, %{}))`. Recommend **retiring `:palette`** in favor of `theme:` (it was explicitly seeded as the swap target), but a one-line merge preserves it if any test depends on it — check `grep -rn ":palette" test/` during Phase 120.
- **The intentional visual change:** `Theme.default/0` is the Swiss-ish neutral palette, **not** today's all-black `{0,0,0}` defaults. Swapping changes rendered color for every block that *reads a role*. This is the intended SHOW-01 fix. **Toy-call byte-goldens survive** because the frozen toy blocks (e.g. `Rendro.text("INVOICE ##{id}", size: 18)` with no `color:`) never read the palette — they were deliberately kept colorless in Milestone A precisely so the default could later change without breaking `@toy_golden_sha256`. Only color-reading (anatomy/new) blocks shift, and those demos are re-scored against the rubric anyway.

---

## 3. Light/dark mechanics against pagination — the central determinism question

### Where the fill is injected: page-template region, NOT the body section list

**Do not** prepend the fill into a recipe's body `content` list. Body sections only render on the pages their flow lands on — a body-list rect would appear once, not on overflow pages, and would sit *inside* the body region rather than covering the whole sheet.

**Do** model the background as a dedicated full-page **non-body region** + a one-block section. The engine's existing per-page anchored-region machinery then repeats it on every page for free.

### The exact engine mechanism (verified, unchanged)

`paginate.ex:909`:

```elixir
defp apply_page_template(%Page{} = page, idx, layout, total, page_context) do
  anchored_blocks =
    layout.template.regions
    |> Enum.reject(&(&1.name == :body))        # every NON-body region…
    |> Enum.flat_map(fn region ->
         layout
         |> running_region_entries(region.name)  # …its section blocks…
         |> Enum.flat_map(&running_entry_blocks(&1, idx, total, page_context))
         |> anchor_region_blocks(region, page)   # …placed on THIS page (idx)
       end)

  %{page | blocks: anchored_blocks ++ page.blocks}  # PREPENDED = drawn underneath
end
```

Two properties make this ideal for a background:
- **Per-page + overflow:** called for every page `idx` (including overflow pages), so the fill repeats deterministically everywhere.
- **Draw order:** `anchored_blocks ++ page.blocks` — anchored blocks render **first** = underneath body content. Within anchored blocks, order follows `template.regions` order, so making `:background` the **first region** guarantees it draws under header/footer/logo/frame too.

### The recipe-side addition

`page_template/1` (when a fill is needed) prepends:

```elixir
Rendro.region(name: :background, role: :custom, anchor: :fixed,
              x: 0, y: 0, width: pw, height: ph)
```

`sections/2` (when a fill is needed) adds:

```elixir
Rendro.section(name: :background, region: :background,
  content: [ Rendro.block(
    %Rendro.Path{ops: [{:rect, 0, 0, pw, ph}], fill: theme.colors.background},
    x: 0, y: 0, width: pw, height: ph) ])
```

`{:rect}` fills are already measured (`measure.ex:946`) and rendered; `anchor: :fixed` full-page regions are already used by Certificate's `:frame` and BrandedInvoice's `:logo`, so `maybe_validate_region_fit` passes for a rect exactly the region's size.

### Determinism guard — emit the rect ONLY when it changes pixels

To keep **light-mode toy goldens byte-identical**, gate the whole background region/section behind a predicate:

```elixir
defp needs_background_fill?(theme),
  do: theme.mode == :dark or theme.colors.background != {255, 255, 255}
```

- Light default (`background == paper white`) ⇒ **no region, no section, no rect op** ⇒ byte-identical to v2.10. White paint on white paper is a no-op that would only bloat the content stream and break goldens for nothing.
- Dark (or any non-white background) ⇒ region + fill emitted on every page.

This is the single most important determinism decision: **the fill is additive and conditional, never unconditional.**

### Legibility

`dark/1` swaps `background`/`ink`/`surface`/`on_accent` (per SEED-003). Recipes already read `colors.ink` for text, so dark text becomes light text automatically — the fill and the ink move together. No per-recipe dark-mode branching beyond reading roles.

---

## 4. Typography type-scale threading — no new text pipeline

`%Rendro.Text{}` already carries `font`, `size`, `color`, `line_height`, `widows`, `orphans` (`text.ex:14`). The type-scale threads **directly** into those fields at compose time:

| Theme field | `%Text{}` field |
|-------------|-----------------|
| `typography.scale[:title]` (etc.) | `size:` |
| `typography.fonts.heading` / `.body` / `.mono` (logical atoms) | `font:` |
| `typography.leading` | `line_height:` |
| `typography.widows` / `.orphans` | `widows:` / `orphans:` |

Recipes today pass **literal** `size: 18`. Migration replaces literals with `size: theme.typography.scale.title`, `font: theme.typography.fonts.heading`, etc. Provide a thin convenience so recipes don't hand-assemble opts everywhere:

```elixir
# in Rendro.Theme — returns text opts for a named scale step
def text_opts(%__MODULE__{} = t, step, extra \\ []) do
  Keyword.merge(
    [size: t.typography.scale[step], font: t.typography.fonts.body,
     line_height: t.typography.leading, widows: t.typography.widows,
     orphans: t.typography.orphans],
    extra)   # extra overrides, e.g. [color: t.colors.accent, font: t.typography.fonts.heading]
end
```

Usage: `Rendro.text("Total Due", Rendro.Theme.text_opts(theme, :title, color: theme.colors.accent))`. The frozen colorless toy blocks keep their literal `size:` for byte-identity; only new/role-reading blocks adopt the scale. **No new text stage, no shaping change** — logical font atoms resolve through the document's existing font registry exactly as today.

`density: :compact` (honored-with-defaults) can nudge `leading` and `spacing`; recommend deriving it inside `resolve/1` (compact ⇒ tighter leading + smaller spacing) so recipes read one already-resolved scale rather than branching on density.

---

## 5. `from_brand/2` + single `accent:` seed — assets (who) vs tokens (how)

**Orthogonality is preserved by construction:** `from_brand/2` produces **only tokens** (a `%Theme{}`); it never registers a font file or image. Asset registration stays in each recipe's `document/2` (`register_embedded_font/3`, `register_image/3`) exactly as `BrandedInvoice`/`Certificate` do today.

```elixir
# brand descriptor = the "who": which logical font atoms the brand uses (files
# are registered elsewhere), plus the single accent seed.
def from_brand(%{font_name: heading} = _brand, opts) do
  accent = Keyword.get(opts, :accent, default().colors.accent)
  default()
  |> put_in([:colors, :accent], accent)
  |> put_in([:colors, :on_accent], on_accent_for(accent))
  |> put_in([:typography, :fonts, :heading], heading)
end
```

- **`accent:` is the one-color "plug in my palette" seed** (SEED-003). Everything else stays the strong neutral default; only the accent (and its derived `on_accent`) changes, so a single brand color yields a cohesive document rather than "everything is blue."
- **`on_accent` derivation is pure + deterministic** — WCAG relative luminance of the accent picks legible ink:

```elixir
defp on_accent_for({r, g, b}) do
  lum = (0.2126*r + 0.7152*g + 0.0722*b) / 255
  if lum > 0.55, do: {17, 17, 17}, else: {255, 255, 255}   # dark text on light accent, else white
end
```

- **Assets vs tokens boundary:** `data.brand` (font/logo **files**, registered into the document) = *who*; `theme:` / `from_brand/2` (**tokens**) = *how*. A recipe can take both. `from_brand/2` only maps the brand's **logical font atom** into `typography.fonts.heading` — it does not own the file. "Design systems = code, brands = data" holds: the theme is code-shaped tokens; the brand assets stay data in the registries.
- **`brand/tokens/tokens.json` mining:** convert the web brand's hex values to `{r,g,b}` at the boundary (hex→tuple) to seed `Theme.default/0`'s neutral palette + a demo accent. `tokens.json` stays Hex-excluded; only the resolved integer tuples land in `lib/`.

---

## 6. Manifest / contract impact — tier decision argued

### `priv/public_api.json` (regenerate via `mix rendro.api.gen`)

Add `Elixir.Rendro.Theme`:
```json
"Elixir.Rendro.Theme": {
  "functions": ["default/0", "dark/1", "from_brand/2", "resolve/1", "text_opts/3"],
  "tier": "adapter",
  "types": ["t/0", "colors/0", "typography/0", "spacing/0", "rules/0",
            "radius/0", "density/0", "mode/0", "rgb/0"]
}
```

### Tier decision: **adapter (Evolving), not stable (Tier-1 frozen SemVer)** — argued

The project's two tiers (from v2.5): **Stable** = strict SemVer, output frozen; **adapter/Evolving** = surface may evolve with a migration note. `Rendro.Theme` belongs on **adapter** because:

1. **Tiered implementation inherently evolves output.** `spacing`/`rules`/`radius`/`density` are "honored-with-defaults" in v2.11 and will get *more* wired in C/D. Deepening their fidelity changes rendered bytes — legal on Evolving, a SemVer break on Stable.
2. **Default token values will be tuned.** The whole point of `default/0` is a strong neutral palette that clears the rubric; Hyrum's Law would freeze those exact RGBs forever if Stable. Adapter tier + an explicit "token values may evolve" doc note is the same mitigation used for `Format`'s money/date strings in Milestone A.
3. **Brand-new surface.** First public theming contract; adapter tier buys room to correct the shape's ergonomics in a minor release without a major bump — while the **field names/role semantics stay stable by intent** (widening later is non-breaking; renaming is the one thing to avoid, hence "define full shape up front").

This mirrors the recipes themselves (`Invoice`, `Certificate` are already `tags: [:adapter]`), so `Theme` on adapter is consistent with the layer it serves.

### `public_api_contract_test.exs`

- The lane byte-compares a regenerated manifest to `priv/public_api.json` → **it will red-build until the manifest is regenerated** with the new `Theme` entry. Flag this as the expected, planned red build (same surprise `Format` produced in A).
- Every manifested module needs **exactly one tier tag** — `@moduledoc tags: [:adapter]` on `Rendro.Theme`. ✔
- The `@spec`-on-every-stable-function rule does **not** bind adapter tier, but spec `resolve/1`, `default/0`, `dark/1`, `from_brand/2`, `text_opts/3` anyway (cheap, aids Dialyzer).
- Keep all derivation helpers (`on_accent_for/1`, dark-swap, `normalize/1`) **private / `@doc false`** so the hidden-internals assertions stay green.

### `priv/support_matrix.json`

Add a terminal **`theming`** family row (flat, **no `viewers` sub-key** — theming is deterministic bytes, not viewer-sensitive), mirroring the `page_numbering` row shape: `supported` + a resolvable test-evidence pointer (theme golden / dark-mode overflow golden). Optionally split `theming.light` / `theming.dark` if the rubric wants them scored separately.

### Docs-contract + S6 artifacts

- New `guides/theming.md` (HexDocs "Recipes & Primitives" group) — every claim bounded by the support row + evidence, enforced by the existing docs-contract lanes; add a claims test.
- `artifacts.json`: populate the S6-reserved `theme`/`mode`/`preset` tags on the new themed + dark gallery renders (the manifest key already exists from Milestone A — no re-keying).

---

## 7. Suggested build order — candidate phases from 119

Dependency-ordered; each keeps the 7-recipe blast radius controlled and determinism guarded.

### Phase 119 — `Rendro.Theme` core value (NEW component, zero recipe change)
Ship `lib/rendro/theme.ex`: full struct, `resolve/1` (idempotent + validate via `Rendro.Color.validate/1`), `default/0` (Swiss-ish neutral, hex→tuple mined from `tokens.json`), `dark/1` (swap `background`/`ink`/`surface`/`on_accent`), `from_brand/2` + `on_accent_for/1`, `text_opts/3`, typography scale, honored-with-defaults spacing/rules/radius/density. Register in `public_api.json` (**adapter**) + `support_matrix.json` skeleton; update `public_api_contract_test.exs` (planned red→green). Pure unit tests: light/dark round-trips, on_accent contrast, resolve idempotency, bad-token errors-as-product. **No recipe touched ⇒ all existing goldens untouched.**

### Phase 120 — Migrate the 3 already-seamed recipes (Invoice, Payslip, Ticket)
Swap each private `palette(opts)` → `Theme.resolve(opts[:theme]).colors`; thread `theme:` through `document/2`/`page_template/1`/`sections/2`; adopt `typography.scale` on role-reading blocks via `text_opts/3`. Frozen colorless toy blocks stay literal (byte-goldens hold). This is where the SHOW-01 visual upgrade lands for these three families. Verify `@toy_golden_sha256`-class goldens unchanged; re-score anatomy demos.

### Phase 121 — Introduce the seam in the 4 un-seamed recipes (BrandedInvoice, Certificate, Receipt, Statement)
Add `palette/1` + typography reads; migrate literals to roles (`statement.ex:306` `{0,0,0}` stroke → `rule`; `certificate.ex` `{34,34,34}` frame default → `rule`; BrandedInvoice/Receipt text → `ink`/`muted`). **Certificate is the stress case** (geometry-derived, centered, optional frame + optional brand) — validate frame color reads `theme.colors.rule` and centering math is theme-independent. Guard byte-identity for un-themed calls (default theme neutral reproduces intended output; where a literal was non-black like `{34,34,34}`, decide whether the default `rule` matches or the golden re-blesses — flag in the plan).

### Phase 122 — Light/dark background-fill mechanism (all 7 recipes)
Add the shared background helper (in `Rendro.Recipes.Pagination` or new `Rendro.Recipes.Theming`): `needs_background_fill?/1` + the `:background` region (first in region list, `anchor: :fixed`, full-page) + the `{:rect}` fill section. Wire into all 7 recipes' `page_template/1` + `sections/2`. **Zero paginate change** (reuses `apply_page_template/5`). Golden proofs: (a) light default emits **no** rect (byte-identical); (b) dark mode paints every page including a forced **overflow** page (multi-page invoice/statement) — the determinism-across-pagination proof. Could fold into 120/121, but its cross-recipe + determinism-golden nature argues for a dedicated slice.

### Phase 123 — `from_brand/2` E2E + demos + rubric closure (SHOW-01)
`from_brand/2` end-to-end with `brand:` assets orthogonal; render themed + dark demos across the family×domain matrix; populate `artifacts.json` S6 `theme`/`mode` tags; `guides/theming.md` + claims test; finalize `support_matrix.json`; re-score all demos against the Milestone-A rubric (hierarchy=5, core≥4, gates pass) — **this is the phase that formally closes the Phase-118 SHOW-01 gap** the milestone folded in.

**Fold option:** 120+121 could merge (all-recipe seam migration in one phase) if the plan prefers coarse granularity (precedent: v2.4 Phase 75 shipped 2 recipes at once; Milestone A folded 7→5). Recommendation: keep 120/121 split by **seam-present vs seam-absent** because the risk profiles differ (120 is near-mechanical; 121 touches literals + Certificate geometry and is more likely to re-bless goldens).

---

## New vs Modified — component inventory

| Item | Status | Notes |
|------|--------|-------|
| `lib/rendro/theme.ex` | **NEW** | Only new `lib/` module; adapter tier |
| Background helper (`Recipes.Theming` or in `Recipes.Pagination`) | **NEW** | Full-page fill region + section; conditional |
| `Rendro.Recipes.Invoice` / `Payslip` / `Ticket` | **MODIFIED (light)** | `palette/1` one-line swap + type-scale + `theme:` thread |
| `Rendro.Recipes.BrandedInvoice` / `Certificate` / `Receipt` / `Statement` | **MODIFIED (heavier)** | Introduce seam + migrate color literals |
| `lib/rendro/pipeline/*` (build/compose/measure/paginate/render/validate) | **UNCHANGED** | Core not widened — the headline guarantee |
| `Rendro.Document` / `Rendro.PageTemplate` / `Rendro.Text` / `Rendro.Path` / `Rendro.Color` | **UNCHANGED** | Theme resolves to existing primitives |
| `priv/public_api.json` | **MODIFIED** | + `Rendro.Theme` (adapter); `mix rendro.api.gen` |
| `public_api_contract_test.exs` | **MODIFIED** | Planned red→green; tier tag + hidden-set intact |
| `priv/support_matrix.json` | **MODIFIED** | + `theming` row (no viewers sub-key) |
| `artifacts.json` | **MODIFIED (data)** | Populate S6 `theme`/`mode` tags |
| `guides/theming.md` + docs-contract | **NEW/MODIFIED** | Claims bounded by support row |

---

## Anti-Patterns (theme-specific, plan against them)

### AP1 — Threading `%Theme{}` into the engine / `Rendro.Document`
**Do not** add theme-aware fields to `Document`, `PageTemplate`, or any pipeline stage. It would widen the deterministic core (violates the standing constraint) and couple the engine to presentation. **Instead:** resolve theme entirely in the recipe layer; the engine only ever sees concrete `%Text{}`/`%Path{}`.

### AP2 — Unconditional full-page fill
Emitting a white `{:rect}` in light mode bloats every content stream and breaks every existing golden for zero visual gain. **Instead:** gate on `needs_background_fill?/1` (dark or non-white background only).

### AP3 — Background as a body-list block
A rect in `sections/2` body content renders once, not on overflow pages, and sits inside the body region. **Instead:** a full-page non-body `:background` region — let `apply_page_template/5` repeat it per page.

### AP4 — Inlining `{r,g,b}` literals in a themed recipe
Any surviving literal (`statement.ex:306`, `certificate.ex` `{34,34,34}`) silently escapes theming/dark-mode. **Instead:** every color sources from `palette(opts)`/`theme.colors.*`; add a test/grep guard that themed recipes contain no bare color tuples outside `palette/1`.

### AP5 — Promoting `Theme` to Stable tier
Freezes default token values + optional-tier fidelity forever (Hyrum). **Instead:** adapter/Evolving tier + explicit "values may evolve" note; field names stable by intent.

### AP6 — Sub-structs for `colors`/`typography`
Extra public modules enlarge the manifest and invite exhaustive pattern-matching (Hyrum). **Instead:** bare typed maps validated in `resolve/1`, matching the existing seam idiom.

---

## Integration Points — internal boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Caller ↔ recipe | `theme:` opt (`%Theme{}` \| keyword \| nil) | Resolved at each rung; idempotent |
| Recipe ↔ `Rendro.Theme` | `resolve/1`, `default/0`, `dark/1`, `from_brand/2`, `text_opts/3` | Pure; no side effects |
| Recipe ↔ engine | Concrete `%Text{}`, `%Path{}`, `%Region{}`, `%Block{}` | Engine theme-agnostic |
| Recipe ↔ paginate (dark) | `:background` non-body region | Reuses `apply_page_template/5`; no core change |
| `Theme` ↔ `Rendro.Color` | `Color.validate/1` in `resolve/1` | Errors-as-product on bad token |
| Assets ↔ tokens | `data.brand` (files, registries) vs `theme:`/`from_brand/2` (tokens) | Orthogonal by construction |

---

## Sources

- `lib/rendro/pipeline/paginate.ex` (`apply_page_template/5`, `running_region_entries/2`) — per-page non-body region emission + prepend draw order. **HIGH** (source).
- `lib/rendro/recipes/{invoice,payslip,ticket}.ex` — existing S1 `palette(opts)` seam keyed on SEED-003 roles. **HIGH** (source).
- `lib/rendro/recipes/{branded_invoice,certificate,receipt,statement}.ex` — un-seamed recipes + color literals to migrate. **HIGH** (source).
- `lib/rendro/{color,text,path}.ex` — `{r,g,b}` contract, `%Text{}` field set, `%Path{}` `{:rect}`/`{:rounded_rect}`/stroke. **HIGH** (source).
- `priv/public_api.json` — tier structure + manifest shape for the `Rendro.Theme` entry. **HIGH** (source).
- `.planning/seeds/SEED-003-*.md`, `.planning/PROJECT.md`, `.planning/research/milestone-a/SUMMARY.md` — locked design, tier discipline, S1/S4/S5/S6 seams, fold-precedent. **HIGH** (project canon).

---
*Architecture research for: public PDF theming / design-token contract on a deterministic PDF engine.*
*Researched: 2026-07-19*

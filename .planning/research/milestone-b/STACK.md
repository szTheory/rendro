# Stack Research

**Domain:** Public deterministic PDF theming / design-token contract (`Rendro.Theme`) inside a pure-Elixir, browser-free document engine
**Researched:** 2026-07-19
**Confidence:** HIGH — grounded directly in the v2.10 codebase (`color.ex`, `text.ex`, `path.ex`, `font_registry.ex`, the S1 `palette(opts)` seam already shipped in Invoice/Payslip/Ticket, and the S6 `artifacts.json` tags), with stdlib capabilities confirmed by live execution on the repo's Elixir `~> 1.19`.

## Headline verdict: ZERO new runtime dependencies

The honest answer is **no new deps — runtime or otherwise.** Everything the `Rendro.Theme` contract needs (hex→`{r,g,b}` at the boundary, deterministic type-scale arithmetic, light/dark role derivation, and the one optional bit of contrast math) is a few dozen lines of Elixir stdlib on top of the existing `Rendro.Color` / `Rendro.Text` / `Rendro.Path` / `Rendro.FontRegistry` surfaces. Adding a color library, a CSS/token toolchain, or an i18n layer would each violate a standing Key Decision (pure Elixir core; locale-free; no Node/npm/browser in core) to save code that is smaller than the dependency's own README.

This is consistent with the milestone's own framing — *"design systems = code, brands = data."* A theme is an inert Elixir value (`%Rendro.Theme{}`) resolved once and threaded through the 3 rungs; the tokens it carries are already the engine's native types (`{r,g,b}` integer tuples, point numbers, logical font atoms). There is nothing to *convert* at render time, so there is nothing to pull in.

## Recommended Stack

### Core Technologies (all already present — nothing to add)

| Technology | Version | Purpose for Theme | Why it's sufficient |
|------------|---------|-------------------|---------------------|
| Elixir stdlib (`Kernel`, `Map`, `:math`) | `~> 1.19` (pinned in `mix.exs`) | Role maps, dark/1 swap, modular-scale arithmetic, luminance/contrast | Colors are `{r,g,b}` int tuples; scale steps are plain point numbers; dark mode is a pure `Map` swap. `:math.pow/2` (Erlang) covers modular scale + WCAG gamma. Confirmed working. |
| `Base` / binary pattern-match | stdlib | hex `"#2C6BED"` → `{44,107,237}` at the API boundary only | `Base.decode16!("2C6BED")` + `<<r,g,b>>` (or `String.to_integer("2C", 16)`). Verified: `Base.decode16!("2C6BED")` → `{44,107,237}`. |
| `Rendro.Color` | in-repo (`@moduledoc false`) | Emits `rg`/`RG` PDF operators; `validate/1` already rejects hex strings with an instructive "use `{r,g,b}`" error | The single DeviceRGB color model the whole contract conforms to. No second color space exists to convert to. |
| `Rendro.Text` (`:stable`) | in-repo | `font` (logical atom), `size`, `color`, `line_height`, `widows`, `orphans` — the exact fields typography tokens drive | Type-scale = choosing `size:`; leading = `line_height:`. Already public and stable. No shape change. |
| `Rendro.Path` (`:stable`) | in-repo | `{:rect}` full-page dark background + `surface` fills; `{:rounded_rect,…,radius}`; stroke `width` for rule tokens | Every optional token (spacing/rules/radius) maps to an existing op or a point number. No new primitive. |
| `Rendro.FontRegistry` (`:stable`) | in-repo | Resolves logical font *roles* (`:heading`/`:body`/`:mono`) → descriptors, with a built-in fallback chain | Already resolves logical atoms and supports `fallbacks:`. Font *roles* are just logical names. See "Font-role resolution" below. |
| `Decimal` | `>= 2.3.0 and < 4.0.0` (already a dep) | **Not used by Theme** — noted only to rule it out | Sizes/spacing are plain points; colors are ints. No money/exact-decimal need in the theme layer. |

### Supporting Libraries

**None.** There is no supporting-library tier for this milestone. Every helper is in-repo Elixir.

The only *new file* is `lib/rendro/theme.ex` (plus its tests and manifest updates). No `mix.exs` `deps` change of any kind — not runtime, not optional, not dev/test.

### Development Tools (unchanged — listed to confirm no additions)

| Tool | Purpose | Notes |
|------|---------|-------|
| `jsv` (`~> 0.18`, dev/test) | JSON-Schema validation of `priv/public_api.json` + manifests | Already the manifest validator; extend schemas for the new `Rendro.Theme` public entries. No new tool. |
| Built-in `JSON` module | Dev/authoring: mine `brand/tokens/tokens.json` for `{r,g,b}` seeds | Elixir 1.18+ ships `JSON`; the codebase already mandates `JSON.decode!`, **never `Jason`** (Jason is a dev/test transitive dep that would crash prod Hex consumers — see the Phase-114 Key Decision). Token mining is an authoring/dev activity, not a runtime path. |
| `mix rendro.launch_artifacts.gen` | Regenerates `assets/rendro/artifacts.json` with `theme`/`mode`/`preset` tags | Already emits those fields (`theme:null, mode:"light", preset:null`). B populates them. No tool change. |

## Capability-by-capability: hand-roll vs pull in

### 1. hex → `{r,g,b}` at the API boundary — **hand-roll (stdlib), ~5 lines**

The engine contract is `{r,g,b}` integer tuples end-to-end; `Rendro.Color.validate/1` deliberately errors on hex strings and even names the footgun ("Rendro uses `{r,g,b}` integer tuples (0–255), never hex strings"). So hex parsing is **not** a core color operation — it is a convenience at the *authoring boundary* only (`Rendro.Theme.from_brand/2` and the dev-time `tokens.json` mining):

```elixir
# boundary helper — accept "#2C6BED" | "2C6BED" | {44,107,237}
def rgb("#" <> hex), do: rgb(hex)
def rgb(<<_::binary-size(6)>> = hex), do: (fn <<r,g,b>> -> {r,g,b} end).(Base.decode16!(hex, case: :mixed))
def rgb({r,g,b} = rgb) when is_integer(r), do: rgb
```

Verified live: `Base.decode16!("2C6BED")` binary-matched → `{44, 107, 237}`. **No color-parsing dependency.** Keep it a thin, explicit boundary; internally the struct stores tuples only, so `Rendro.Color` stays the single source of truth and every existing determinism guarantee holds unchanged.

### 2. Type-scale arithmetic — **hand-roll (stdlib), and prefer a static numeric map over runtime `pow`**

The named steps (`display/title/subtitle/body/small/caption`) are point sizes fed straight into `Rendro.Text.size`. Two viable shapes:

- **Recommended default: a frozen numeric map** in `Rendro.Theme.default/0`, e.g. a restrained Swiss-ish ramp `%{display: 28, title: 20, subtitle: 15, body: 11, small: 9, caption: 8}`. Concrete integers/half-points are trivially deterministic, human-legible, and reviewable in a diff.
- **Optional constructor: a modular scale** `Theme.scale(base: 11, ratio: 1.25)` computed with `:math.pow(ratio, step)` (Erlang stdlib; `:math.pow(1.25, 3)` → `1.953125`, confirmed).

**Determinism guidance (STACK-level):** if you offer the modular-scale constructor, **round the result to a fixed precision** (e.g. `Float.round(x, 2)` or snap to 0.5pt) and **resolve it once at `Theme.resolve/1` time**, storing concrete numbers in the struct — never recompute transcendental math per render. Rendro already depends on IEEE-754 float determinism (`/255` in `Rendro.Color`, `:erlang.float_to_binary(_, decimals: 4)`), so same-BEAM float math is already inside the determinism envelope; rounding at resolve time keeps the *stored* token stable across refactors and keeps hash-checked goldens from drifting on a formula tweak. No dependency either way.

### 3. Light/dark role derivation — **hand-roll (stdlib), pure `Map` swap, zero math**

The locked design is a *variant selector, not separate art*: `Rendro.Theme.dark/1` swaps `background`/`ink`/`surface`/`on_accent` roles and recipes prepend a full-page `{:rect}` fill. That is `Map.merge/2` over the roles map plus one `Rendro.Path` op — no color-space math, no HSL, no "darken by 10%" library call. Zero dep.

### 4. Relative-luminance / contrast — **optional, hand-roll only if `from_brand/2` auto-picks `on_accent`; ~12 lines**

The locked `dark/1` design does **not** require contrast computation (it swaps explicit roles). The *one* place a tiny luminance helper earns its keep is `from_brand/2` deciding whether `on_accent` should be black or white given a single seeded `accent:` — so a user "plugs in one brand color" and legible text falls out. The WCAG relative-luminance formula is ~12 lines using `:math.pow` for the sRGB gamma expansion (exponent 2.4), then a `> 0.5`-ish threshold to choose ink-on-accent. Hand-roll it, keep it **internal and deterministic**.

**Guard (product-honesty, from the milestone's accessibility posture):** do **not** expose a general public "contrast checker" API and do **not** claim WCAG/AA/PDF-UA conformance from it — the engine holds "no tagged-PDF/PDF-UA accessibility claims." It's an internal legibility heuristic for `on_accent`, nothing more. If you'd rather not carry even that, make `on_accent` a required explicit role and skip luminance entirely (still zero dep).

## What NOT to Use

| Avoid | Current status | Why it's wrong here | Use instead |
|-------|----------------|---------------------|-------------|
| **`chameleon`** (color-model conversion: RGB/CMYK/HSL/Pantone/hex) | Latest `2.5.0`, released **2022-01-25** (stale ~4.5 yrs) | Rendro has exactly **one** color model — DeviceRGB `{r,g,b}`. HSL/CMYK/Pantone are never emitted. It would add a dep + supply-chain + `hex.audit` surface to replace ~5 lines of `Base.decode16!`. Teams reach for it reflexively when porting a web design-token mental model. | `Base.decode16!/2` + binary match at the boundary |
| **`css_colors` / `tint` / `color` (color-manipulation libs)** | various | "darken/lighten/mix" operations aren't in the contract — dark mode is an explicit role swap, not algorithmic tinting. Adds transcendental color-space math and a dep for behavior the design deliberately excludes. | Explicit role tokens; `Map.merge` for `dark/1` |
| **Any CSS/LESS/SCSS parser** | n/a | Rendro is **not a browser** (permanent Out-of-Scope: "HTML/CSS parity or browser-style layout"). Themes are Elixir values, not stylesheets. `brand/tokens/tokens.json` mining is a **dev-time** hex extraction, not a runtime CSS parse. | Elixir literals in `lib/rendro/theme.ex`; dev-time `JSON.decode!` to seed values |
| **`ex_cldr` / `gettext` / CLDR data** | n/a | Standing Key Decision: the engine is **locale-free by construction**; i18n is a caller-supplied override, never core. `Theme` is *pure presentation, industry-agnostic* — it has no locale dimension at all. | Nothing — locale stays out of the theme layer |
| **Style Dictionary / Amazon-style token toolchains (Node/npm)** | n/a | Standing Key Decision: **Node/npm must never be a core runtime, required CI, or Hex dependency** (held since v2.7). Token "compilation" solves a multi-platform-export problem Rendro doesn't have — it emits one target (PDF) from one source (Elixir). | The theme *is* the compiled artifact — a plain `%Rendro.Theme{}` struct |
| **`ex_money` / `money`** | already ruled out for `Format` | Money/decimal formatting is `Rendro.Format`'s concern (already locked locale-free), not the theme layer. Theme sizes/spacing are plain point numbers. | n/a — not a theme concern |
| **A new font library / font-shaping dep for roles** | `harfbuzz_ex` stays optional | Font *roles* (heading/body/mono) are logical atoms the existing `FontRegistry` already resolves. No shaping/subsetting change is needed to *name three roles*. | `Rendro.FontRegistry.register/register_embedded` + `resolve` (see below) |

**Where teams wrongly reach for a dep:** anyone told "build a design-token system" reflexively assembles the web trinity — Style Dictionary (token compilation) + Chameleon-style color conversion + CSS-variable parsing. All three are load-bearing *only* when you must export tokens to many heterogeneous targets (CSS, iOS, Android, Figma) and juggle multiple color spaces. Rendro exports to exactly one deterministic target and speaks one color model, so all three collapse to stdlib. The pull is cultural, not technical.

## Font-role resolution: existing path covers it — no shape change

The existing font path **already** supports logical font *roles*; the Theme contract is plumbing, not new infrastructure:

- `Rendro.Text.font` accepts a **logical atom** (`:heading`, `:body`, `:mono`) and passes it through `normalize_font/1` unchanged (only string aliases are narrowed to Helvetica).
- `Rendro.FontRegistry.resolve/3` maps a logical name → descriptor and already carries a **`fallbacks:` chain** (`resolve_pdf_font_chain/3`) — exactly the mechanism for `:mono` → `:body` → `:default` fallback when a role isn't separately registered.
- Registration is unchanged: built-in roles via `Rendro.Document.register_font(:heading, built_in: :helvetica)`, brand faces via the already-used `register_embedded_font/3` path (`BrandedInvoice` does this today for `brand.font_name`).

So `typography.fonts: %{heading, body, mono}` are **three logical atoms** that ride the existing registration + resolution path with **no `FontRegistry`/`Text` struct change**. What Milestone B actually adds is only:

1. `document/2` registers the theme's three role atoms if they aren't the built-in default (a few `register_font` calls, mirroring how `BrandedInvoice.document/2` already registers `brand.font_name`).
2. Recipe section builders read `theme.typography.fonts.heading|body|mono` and pass them as `font:` on the relevant text blocks (today most blocks use the default). This is the typography analogue of the S1 color swap.
3. `Theme.default/0` points all three roles at the built-in Helvetica-compatible family (or the already-vendored B612 unicode fallback via `fallbacks:`), so the default is browser-free and ships no new font files. **Curated preset fonts are explicitly Milestone C** — B needs only the role→registry plumbing, not a font catalog.

One small watch-item: `Rendro.Text`'s struct default is the string `"Helvetica"` while roles are atoms resolving through the registry — keep Theme roles as **registered logical atoms** and let recipes pass them explicitly, rather than leaning on the string default, so role resolution always goes through `FontRegistry.resolve` (and thus the fallback chain). No code shape changes; it's a convention the recipe plumbing must follow.

## S6 `artifacts.json` + light/dark determinism × the hash-checked gallery

The S6 seam is already in place and requires **no re-keying**: every gallery entry in `assets/rendro/artifacts.json` already carries `"theme"`, `"mode"` (currently `"light"`), and `"preset"` (currently `null`), each hash-checked via `png_sha256` + `source_pdf_sha256` through the pinned `pdfium-render` lane.

Interaction facts for B:

- **Both modes are deterministic.** Light and dark are *both* byte-reproducible: `dark/1` is a pure role swap and the dark background is a fixed-color full-page `{:rect}` drawn first (deterministic draw order — the engine has no z-index, only draw order). So a dark variant produces a stable `source_pdf_sha256` exactly like a light one and can be blessed as a golden with no special handling. **Guard:** derive the dark background color from a *role*, never a literal, and draw it as the first op so ordering is fixed.
- **One row per `(recipe × mode)`.** A themed dark demo is a new gallery entry (e.g. `id: "invoice-dark"`, `mode: "dark"`, optional `theme: "<name>"`), with its own PNG + PDF hashes. The `id` uniqueness the manifest already assumes is what keeps light/dark variants distinct. `mix rendro.launch_artifacts.gen` regenerates and re-hashes; the existing docs-contract/hash lane enforces it.
- **`preset` stays `null` in B.** Style-genre presets are Milestone C; leaving the field `null` (already its state) means C appends preset-tagged rows through the identical schema — the whole point of the S6 shape-now decision. No schema migration in B.
- **Rubric coupling.** The Phase-118 SHOW-01 gap is folded into B: the themed demos (including `Theme.default/0`) must clear the Milestone-A reader-quality rubric, whose scores append through the S5 `priv/quality/rubric_scores.json` manifest — also already schema-gated. No new tooling; B just adds rows to two existing append-only manifests.

## Alternatives Considered

| Recommended | Alternative | When the alternative would make sense |
|-------------|-------------|----------------------------------------|
| Hand-rolled `rgb/1` boundary helper | `chameleon` | Only if Rendro ever had to *emit* CMYK/spot-color PDFs (print-shop separations) — a different color space, a different (deferred) milestone. Not this contract. |
| Frozen numeric type-scale map | Runtime modular scale via `:math.pow` | If authors demand parametric scales (`base`+`ratio`) as a first-class feature; still zero-dep, just round-at-resolve for determinism. Offer as an optional constructor, not the default. |
| Internal `on_accent` luminance heuristic | Required explicit `on_accent` role (no math) | If you want to avoid *any* transcendental math in the theme layer — make `on_accent` mandatory and drop the helper. Slightly worse "one brand color" DX, marginally simpler. |
| Logical font-role atoms via existing `FontRegistry` | A dedicated font-catalog module | Milestone C, when curated preset fonts arrive. B deliberately stops at role plumbing. |

## Version Compatibility

| Package | Version | Notes |
|---------|---------|-------|
| Elixir | `~> 1.19` | Ships `Base.decode16!`, `:math`, and the `JSON` module. No change. |
| `decimal` | `>= 2.3.0 and < 4.0.0` | Present; **untouched** by Theme. |
| `unicode` `~> 1.22`, `telemetry` `~> 1.4` | present | **Untouched** by Theme. |
| `jsv` `~> 0.18` (dev/test) | present | Extend existing schemas for the new public `Rendro.Theme` entries; no version bump. |

**Net `mix.exs` change for this milestone: none.** The deliverable is `lib/rendro/theme.ex` + recipe plumbing + manifest/schema/gallery updates.

## Stack Patterns by Variant

**If the team wants "plug in one brand color" DX (`from_brand/2` + single `accent:`):**
- Add the internal WCAG-luminance `on_accent` heuristic (~12 lines, `:math.pow`, no dep).
- Because auto-legible ink-on-accent is the whole value of a one-color seed.

**If the team wants strict determinism paranoia on the type-scale:**
- Ship the frozen numeric map as `default/0`; if you also offer `Theme.scale/1`, round at `resolve/1` and store concrete numbers.
- Because hash-checked goldens must not drift when a scale formula is refactored.

**If the team later needs print separations (CMYK/spot):**
- That is a *new color space* → a separate future milestone, and only *then* re-evaluate a conversion dep. Explicitly out of scope for B.

## Sources

- In-repo (HIGH): `lib/rendro/color.ex`, `lib/rendro/text.ex`, `lib/rendro/path.ex`, `lib/rendro/font_registry.ex`, `lib/rendro/recipes/invoice.ex` (shipped S1 `palette(opts)` seam + `Keyword.take` whitelist), `lib/rendro/recipes/branded_invoice.ex` (existing `register_embedded_font` brand path), `assets/rendro/artifacts.json` (S6 `theme`/`mode`/`preset` tags already present), `mix.exs` deps — read directly.
- Live execution (HIGH): Elixir `~> 1.19` confirmed `String.to_integer("2C", 16) → 44`, `:math.pow(1.25, 3) → 1.953125`, `Base.decode16!("2C6BED")` binary-match → `{44,107,237}`.
- `hex.pm/packages/chameleon` (HIGH): latest `2.5.0`, released 2022-01-25; color-model conversion (RGB/CMYK/HSL/Pantone/hex) — verified stale and out-of-model for Rendro.
- Project context (HIGH): `.planning/PROJECT.md` (Constraints: pure Elixir core, no browser/Node/Python; locale-free Key Decision; no PDF-UA claims), `.planning/seeds/SEED-003-*.md` (locked design + token-vs-excluded discipline), `.planning/research/milestone-a/SUMMARY.md` (S1/S4/S5/S6 shape-now seams).

---
*Stack research for: deterministic PDF theming / design-token contract (`Rendro.Theme`)*
*Researched: 2026-07-19*

# Architecture Research

**Domain:** Elixir/Phoenix deterministic PDF library — adding style-genre presets, curated fonts, a public example catalog, and a static configurator on top of an already-shipped `%Rendro.Theme{}` design-token contract.
**Researched:** 2026-07-28
**Confidence:** HIGH — every claim below is grounded in files actually read in this repo (`lib/rendro/theme.ex`, `lib/rendro/font_registry.ex`, `lib/rendro/launch_artifacts.ex`, `lib/rendro/recipes/invoice.ex`, `lib/rendro/recipes/branded_invoice.ex`, `lib/mix/tasks/brand.gen.ex`, `priv/quality/rubric_scores.json`, `test/docs_contract/rubric_manifest_contract_test.exs`, `mix.exs`, `priv/public_api.json`, `priv/support_matrix.json`), not from the Elixir/PDF ecosystem in general.

## Standard Architecture

### System Overview — where Milestone C plugs in

```
┌───────────────────────────────────────────────────────────────────────────┐
│ AUTHORING-TIME / BUILD-TIME (NEW — Milestone C, mix tasks, dev-only)       │
│                                                                             │
│  priv/examples/<domain>/<brand>/*.json   (DATA, existing + 2 more brands) │
│  priv/fonts/<family>/*.ttf               (DATA, NEW — vendored fonts)     │
│  lib/rendro/theme/presets.ex             (CODE, NEW — style-genre data)   │
│         │                                                                  │
│         ▼                                                                 │
│  Rendro.Theme.preset(:editorial, accent:, mode:) ──► %Rendro.Theme{}      │
│         │                                            (Theme.resolve/1     │
│         │                                             + Theme.dark/1,     │
│         │                                             REUSED unmodified)  │
│         ▼                                                                 │
│  Rendro.Theme.Presets.register_fonts(doc, :editorial)                     │
│         │  (bridges pure Theme value → Document.font_registry)            │
│         ▼                                                                 │
│  Recipe.document(data, theme: theme)   ◄── UNCHANGED 3-rung recipe API    │
│         ▼                                                                 │
├───────────────────────────────────────────────────────────────────────────┤
│ RUNTIME ENGINE (UNCHANGED — one pipeline, zero new stages)                │
│  build → compose → measure → paginate → render → validate                 │
├───────────────────────────────────────────────────────────────────────────┤
│ AUTHORING-TIME continued (NEW)                                            │
│         ▼                                                                 │
│  Rendro.Catalog (extends Rendro.LaunchArtifacts pdfium/hash machinery)    │
│         ▼                                                                 │
│  assets/rendro/catalog/<domain>/<brand>/<preset>-<mode>.png  (NEW tree)   │
│  assets/rendro/catalog.json                                   (NEW file) │
│  priv/quality/rubric_scores.json  scores[] ── additive brand/preset/mode │
│         ▼                                                                 │
│  assets/rendro/configurator/{index.html,configurator.js}      (NEW)      │
│    - static, no server, no DB, URL query-string state                     │
│    - exact-match lookup against a trimmed catalog index                   │
│                                                                             │
│  lib/mix/tasks/rendro/gen/theme.ex  (NEW — models mix brand.gen)          │
│    CLI opts → lib/my_app/*_theme.ex  (+ --check drift gate)               │
└───────────────────────────────────────────────────────────────────────────┘
```

The engine box in the middle is drawn to make the point visually: **nothing in Milestone C adds a pipeline stage, an alternate render path, or a new runtime dependency.** Every new capability is either (a) a new pure-data/pure-function seam feeding the *existing* `theme:` opt, or (b) a build-time/dev-time `mix` task that calls the existing recipe/render/pdfium-render machinery in a loop.

### Component Responsibilities

| Component | Responsibility | Status |
|-----------|-----------------|--------|
| `Rendro.Theme` (`lib/rendro/theme.ex`) | Pure struct + `default/0`/`resolve/1`/`dark/1`/`from_brand/2` | **Modified** — gains `preset/2` |
| `Rendro.Theme.Presets` (`lib/rendro/theme/presets.ex`) | Style-genre catalog as partial `%Theme{}` attrs (colors sans accent, typography, spacing, rules, radius, density) + `register_fonts/2` bridge | **New** |
| `Rendro.PresetFonts` (or folded into `Presets`) | Path resolution for vendored `priv/fonts/*.ttf`, mirrors `Rendro.Branded` | **New** |
| `Rendro.FontRegistry` / `Rendro.Document` | Per-document font registration (`register_embedded_font/family`) | **Unmodified** — reused exactly as-is |
| `Rendro.Recipes.*` (7 recipes) | 3-rung pattern; `palette/1`/`typography/1` seams read `theme.colors.*`/`theme.typography.*` | **Unmodified** — presets are just new `Theme` values flowing through the existing seam |
| `Rendro.LaunchArtifacts` (`lib/rendro/launch_artifacts.ex`) | 11-row hand-authored launch gallery + `artifacts.json` + README/guide doc blocks | **Unmodified** — stays byte-identical; catalog is additive, not a rewrite |
| `Rendro.Catalog` (new module) | Data-driven domain×brand×preset×mode grid spec generator + dispatcher, reusing `LaunchArtifacts`-style render/hash helpers | **New** |
| `priv/examples/<domain>/<brand>/` | Fixture data (existing 1 brand/domain + 1-2 new brands/domain) | **Modified** (new sibling dirs, data only) |
| `priv/quality/rubric_scores.json` + schema | Reader-quality ratchet | **Modified** — additive `brand`/`preset`/`mode` fields |
| `assets/rendro/catalog.json` + `assets/rendro/catalog/` | Public catalog manifest + PNG tree | **New** |
| `assets/rendro/configurator/` | Static client-side HTML/JS configurator | **New** |
| `lib/mix/tasks/brand.gen.ex` | Existing "source → derived files → `--check`" codegen pattern | **Reference only** — pattern reused, file untouched |
| `lib/mix/tasks/rendro/gen/theme.ex` | `mix rendro.gen.theme <preset> --accent` codegen | **New** |

## Integration Point 1 — `Rendro.Theme.preset/2`

### Where it lives and how it composes

`lib/rendro/theme/presets.ex` holds **data only**: a module-attribute map of preset name → partial `%Theme{}` attrs (`colors` *minus* `accent`/`on_accent`, `typography.fonts` pointing at the new preset font-role atoms, `typography.scale`/`leading`, `spacing`, `rules`, `radius`, `density`) plus `fetch!/1` and `names/0`. It is `@moduledoc false` (mirrors `Rendro.Branded`, `Rendro.ExamplesData`, `Rendro.LaunchArtifacts` — all internal helpers behind one public-facing function), so it does **not** widen the public API surface on its own.

`Rendro.Theme.preset/2` is the one new **public** function, added to `lib/rendro/theme.ex` next to `default/0`/`resolve/1`/`dark/1`/`from_brand/2` (same module, same doc tier `:adapter`). Its body is pure composition of already-shipped, already-tested primitives — it adds **zero new merge/validation logic**:

```elixir
def preset(name, opts \\ []) do
  attrs = Rendro.Theme.Presets.fetch!(name)
  accent = Keyword.get(opts, :accent)
  colors = if accent, do: put_in(attrs.colors[:accent], accent), else: attrs.colors

  theme = resolve(%{attrs | colors: colors})           # SAME path as resolve/1 — Color.validate!
                                                          # runs on every role, idempotency preserved
  theme =
    if accent do
      %{theme | colors: Map.put(theme.colors, :on_accent, on_accent_for(accent, theme.colors))}
    else
      theme
    end

  case Keyword.get(opts, :mode, :light) do
    :dark -> dark(theme)                                 # SAME dark/1, UNMODIFIED
    _ -> theme
  end
end
```

This reuses:
- `resolve/1`'s existing deep-merge + `validate_colors!/1` (every preset color role is validated exactly like `from_brand/2`'s output — no new validation code path, no new failure mode).
- `on_accent_for/2`, already private in `theme.ex` — called directly (no export needed) since `preset/2` lives in the same module.
- `dark/1`, completely unmodified.

**Key finding on dark-mode composition:** `Theme.dark/1` does **not** do a relative darken — it does `Map.merge(resolved.colors, @dark_colors)`, an *absolute* swap of `ink`/`muted`/`background`/`surface`/`rule`/`positive`/`negative` to one fixed, universal dark palette regardless of what the light theme's own values were (`accent`/`on_accent` are deliberately excluded from the swap). This means **presets get dark "for free" with zero code change to `dark/1`**, exactly as the seed promises ("dark derived from roles"), but it also means every preset's dark mode converges on the *same* neutral dark surface/ink/rule constants — only `accent`, the font roles, and the type scale distinguish one preset's dark render from another's. This is a property of the existing shipped design, not a new decision Milestone C must make — but it should be stated explicitly in the presets guide so nobody "discovers" it as a bug later.

**Byte-reproducibility / idempotent-resolver safety:**
- `preset/2` never touches `@default_colors`, `@default_typography`, or any code path that `default/0`/the no-theme literal branches in each recipe's `palette/1`/`typography/1` read. Zero risk to the 7 recipes' byte-identity goldens or the un-themed-call-reproduces-v2.10-bytes guarantee (PLUMB-03).
- **Swiss preset must be a separate, explicit entry in `presets.ex`, not implemented by having `default/0` call into `Presets`.** The seed calls Swiss "also the `Theme.default()` basis" — read that as *design lineage*, not *code sharing*. `default/0` must stay a bare `%__MODULE__{}` literal exactly as today (`iex> Rendro.Theme.default() == %Rendro.Theme{}` is a doctested invariant); Swiss's preset data can numerically match today's defaults without `default/0` depending on `presets.ex` in any way. Coupling them would make `presets.ex` load-bearing for the core no-theme/default path, which is the one thing that must never regress.
- `resolve(resolve(x)) == resolve(x)` idempotency is inherited automatically because `preset/2`'s only mutation after calling `resolve/1` is a pure `Map.put` on `on_accent` using the same deterministic WCAG-contrast branch `from_brand/2` already uses — no new state, no floats feeding stored values beyond the already-audited `linearize/1`.

### Font-role atoms — the seam Theme never crosses

`Theme` is documented as touching "no registry" — `typography.fonts.heading/body/mono` are just atoms. A preset that names `heading: :preset_serif` produces a perfectly valid `%Theme{}` even if `:preset_serif` is never registered anywhere; the *typed error* only fires downstream, inside `Rendro.FontRegistry.resolve/3` (`{:unknown_logical_font, :preset_serif}`), when the recipe pipeline actually tries to draw text in that logical font and the calling `Rendro.Document` never registered it. This is exactly the seed's stated contract ("no silent substitution") and requires **no new error-handling code** — it already exists.

The real integration gap this creates: **something has to call `Document.register_embedded_family/3` for a preset's fonts before render**, because `Theme.preset/2` (pure value) cannot reach into a `%Document{}` (registry-bearing) itself, and no recipe's `document/2` today inspects `opts[:theme]` to auto-register fonts. The fix is a small, explicit bridge:

```elixir
# Rendro.Theme.Presets.register_fonts/2 — the ONE new registry-touching function
doc
|> Rendro.Theme.Presets.register_fonts(:editorial)   # registers exactly the font roles :editorial needs
|> then(&Rendro.Recipes.Invoice.document(data, theme: theme, ...))
```

or, more ergonomically, folded into a convenience that recipes already support via the escape hatch (`page_template/1` + `sections/2` + manual `Document.add_*`), since `document/2` composes the whole pipeline in one call and cannot easily be retrofitted to also register fonts without becoming preset-aware (which would violate "Theme touches no registry"). **Recommendation: keep `document/2` untouched; `register_fonts/2` is an explicit step the caller (catalog generator, codegen output, and docs examples) always performs right after building the `Document` returned by `document/2` — this is a `%Document{}` transform, so it composes as `data |> Recipe.document(theme: theme) |> Rendro.Theme.Presets.register_fonts(:editorial)` (font registration doesn't require the sections to already exist, only that draws which reference those logical names happen after render begins — resolution is at render time via `FontRegistry.preflight/1`, not at `document/2` call time).** This keeps `Theme` pure, keeps recipes untouched, and gives the codegen task (`mix rendro.gen.theme`) a one-line call to emit in generated modules.

## Integration Point 2 — Vendored fonts (`priv/fonts/`)

The exact precedent already exists: `Rendro.Branded` (`lib/rendro/branded.ex`, `@moduledoc false`) resolves `Application.app_dir(:rendro, "priv/branded/fonts/B612-Regular.ttf")`, and `mix.exs`'s `package.files` allowlists `priv/branded` (but explicitly **excludes** `priv/quality` and `priv/schemas` from the Hex tarball). Curated preset fonts must follow the same shape:

- `priv/fonts/<family>/<Weight>.ttf` (one dir per curated family: a grotesque, a humanist sans, a text serif, a mono — 4 families per the seed's starter set).
- A `NOTICE`-style per-font license block, exactly mirroring the existing B612/SIL-OFL entry already in `NOTICE` — every curated font must ship its own attribution the same way.
- `mix.exs`'s `package.files` list **must add `priv/fonts`** (it is currently absent; unlike `priv/quality`/`priv/schemas`, these files ship to consumers, so they belong in the same allowlist bucket as `priv/branded`/`priv/examples`, not the excluded bucket).
- Path-resolution lives in code (`Rendro.Theme.Presets` or a small sibling `Rendro.PresetFonts`), never as a literal path string inside a recipe or inside `presets.ex`'s data map directly — keep the same one-hop indirection `Rendro.Branded.font_path/0` already establishes.

Registration is via `Document.register_embedded_family/3` (four-variant family helper) if bold/italic faces are curated, or the simpler `register_embedded_font/3` (single face) if only Regular ships initially — `FontRegistry.register_embedded_family/3` already validates the full 4-variant set and raises a typed `EmbeddedFontFamilyError` on partial families, so **starting with Regular-only via `register_embedded_font/3` is the lower-risk, lower-scope choice** unless bold headings are load-bearing for a specific preset's hierarchy.

## Integration Point 3 — Catalog generation extends `mix rendro.launch_artifacts.gen`

### Why the existing `@gallery_specs` list cannot just grow

`Rendro.LaunchArtifacts.@gallery_specs` is a hand-authored, 11-entry literal list, each entry hardwired to its own `build_source_document/1` pattern-match clause (`defp build_source_document("invoice") do ... end`, etc.) in the same module. This is intentionally small and explicit for a curated *launch* gallery. A full domain × 2-3 brands × ~5 presets × 2 modes grid (6 domains × 3 brands × 5 presets × 2 modes + 6 unbranded-default rows ≈ 186 tiles) cannot be hand-enumerated the same way without an unmaintainable wall of pattern-match clauses.

**Recommendation: add a new, separate module `Rendro.Catalog` (`lib/rendro/catalog.ex`, `@moduledoc false`) rather than bloating `LaunchArtifacts` in place.** It:

1. Enumerates domains by listing `priv/examples/*` (mirrors the directory convention `Rendro.Examples` already establishes) and, per domain, enumerates the 2-3 brand fixture directories.
2. Cross-products domains × brands × `Rendro.Theme.Presets.names/0` × `[:light, :dark]`, plus one `unbranded default` row per domain (`Theme.default()` / `Theme.dark(Theme.default())`).
3. Builds spec maps shaped like today's `@gallery_specs` entries but extended with `domain:`, `brand:`, `preset:` fields (the manifest's `preset`/`theme`/`mode` S6 keys were **already reserved as `nil`-tolerant on every existing row** — `Rendro.LaunchArtifacts`'s own D-13 comments literally say *"preset stays null on every row (Milestone C reserves this key untouched)"* — so populating them for catalog rows requires zero schema change on the shared key names, only a new manifest to hold the much larger row set).
4. Reuses (small, explicit duplication, matching this codebase's existing "duplicate the `palette/1` twin per recipe rather than over-abstract" style) a `render → pdfium raster → sha256` helper equivalent to `LaunchArtifacts.build_gallery_entries/1`'s inner loop, rather than trying to generalize `LaunchArtifacts` itself.

**Keep `Rendro.LaunchArtifacts`'s existing 11-row `@gallery_specs`, `artifacts.json`, and `assets/rendro/gallery/` completely untouched.** They are already docs-contract-tested (`launch_artifacts_claims_test.exs`, the README/`guides/recipes.md` generated-block markers, the required-checks lockstep). Splitting the catalog into its **own** manifest (`assets/rendro/catalog.json`) and **own** asset tree (`assets/rendro/catalog/<domain>/<brand>/<preset>-<mode>.png`, satisfying the seed's "organized by-domain, brand-tagged" requirement directly via directory structure) avoids widening the blast radius of the one thing in this milestone that is genuinely load-bearing for existing green CI (the 11-row launch gallery), and avoids bloating README/HexDocs with 180+ inline images.

A new mix task, `lib/mix/tasks/rendro/catalog/gen.ex` (`mix rendro.catalog.gen`), is the thin CLI wrapper — same shape as `Mix.Tasks.Rendro.LaunchArtifacts.Gen` (parse `--pdfium`, call `Rendro.Catalog.generate/1`, print/exit).

### Rubric-ratchet tracking → `priv/quality/rubric_scores.json`

Today: `scores[]` is a flat array, one entry per domain (`demo_id: "invoice-acme-phoenix-saas"`), each carrying `domain`, `family`, `dimension_scores` (6 dims), `gate_results` (2 gates), `passed`, human sign-off metadata, and `evidence_ref` — a path into `assets/rendro/gallery/*.png`. `test/docs_contract/rubric_manifest_contract_test.exs` validates the manifest against `priv/schemas/rubric_scores.schema.json` and cross-checks `evidence_ref` values against `assets/rendro/artifacts.json`'s `gallery[].png_path` set via a `gallery_png_paths/0` helper.

Extend **additively** (this codebase's established discipline — see v2.3's `explicit_deferral` field addition to `support_matrix.json` as direct precedent):
- Add optional `brand`, `preset`, `mode` fields to each score entry (schema addition, `required` stays as today for the 6 existing hero fields; new fields optional).
- `demo_id` convention for catalog rows becomes `<domain>-<brand>-<preset>-<mode>` (e.g. `invoice-acme-phoenix-saas-editorial-dark`), staying disjoint from the 6 existing hero `demo_id`s (which keep scoring the unbranded-default light renders, unchanged, at their existing `evidence_ref` paths — **do not migrate or re-point them**).
- Widen the contract test's `gallery_png_paths/0` cross-check into an "evidence must resolve against `gallery` OR `catalog` manifest" check (add a sibling `catalog_png_paths/0` reading the new `assets/rendro/catalog.json`).
- **Do not require 100% grid coverage.** With ~186 cells, mandating a human-signed score for every cell before merge is untenable and contrary to the seed's own framing — "a standing quality ratchet... over time." The schema/contract enforces that any *present* score entry is well-formed and evidence-resolvable, mirroring the existing `stress_exemption` block's spirit (declarative, honest, incomplete-by-design bookkeeping rather than brute-force universal coverage at ship time). Score the flagship subset first (one preset × light/dark × each domain's primary existing brand, for whichever presets ship in Milestone C) and leave the rest of the grid as an intentionally open, trackable backlog.

## Integration Point 4 — Static configurator + `mix rendro.gen.theme`

### Asset location and shape

`assets/rendro/` is already the established home for public, hash-checked, committed artifacts (`gallery/`, `artifacts.json`, `manual.pdf`). The configurator belongs alongside them: `assets/rendro/configurator/index.html` + `configurator.js` (+ optional `.css`), plus a **trimmed** JSON index generated by the same catalog-gen pass (a `write_configurator_index/1` step appended to `Rendro.Catalog.generate/1`, mirroring how `LaunchArtifacts.generate/1` already appends `write_docs_blocks/1` onto its pipeline). The trimmed index carries only what client JS needs per tile (`domain`, `brand`, `preset`, `accent_id`, `mode`, `png_path`) rather than the full catalog manifest's hash/renderer metadata, keeping the client bundle small.

### "Nearest pre-rendered tile" is exact-match, not color-distance

The seed's own wording — "pick a preset + a sample accent **from a small palette**" — means the configurator's accent choices are the *same finite, curated set of accent values already baked into the catalog grid*, not a free-form color picker. This means "nearest tile" reduces to a **plain key lookup** `{domain, preset, accent_id, mode} → catalog_index[key]`, not fuzzy/Euclidean color-distance matching. This is the right simplification: it needs no client-side color math, guarantees the shown preview is *exactly* what `Theme.preset(...)` would render (never an approximation), and keeps the "no server compute" constraint trivially true. Recommend explicitly designing the configurator's accent picker as a **swatch list drawn from the catalog's own generated accent set**, not an arbitrary hex input, to preserve this property.

### URL-state and code export

- State lives in the query string (`?domain=invoice&preset=editorial&accent=teal&mode=dark`), parsed on load by client JS — shareable, bookmarkable, zero storage.
- The "one-click copy" snippet (`Rendro.Theme.preset(:editorial, accent: {14, 124, 118}, mode: :dark)` + a one-line recipe usage example) is pure client-side string templating from the selected tile's already-known `{preset, accent, mode}` — no server roundtrip needed, since the accent value is already resolved data sitting in the configurator index.

### `mix rendro.gen.theme` — reusing `mix brand.gen`'s pattern, not its code

`lib/mix/tasks/brand.gen.ex` is the concrete pattern to imitate, but it is **not** structurally identical to what's needed — it reads one fixed input path (`brand/tokens/tokens.json`, no CLI args) and regenerates two fixed derived files. `mix rendro.gen.theme <preset> --accent "#…" [--mode dark] [--out path]` instead takes **positional/flag CLI args** and writes **one caller-named module**. What transfers directly is the **`--check` drift-gate idiom**: read the target file if it exists, compare byte-for-byte against freshly-computed content, and `Mix.raise` a `"STALE — run mix rendro.gen.theme ..."` message on mismatch (exact structure of `brand.gen`'s `check?`/`drift` branch). The generated module should also emit the font-registration bridge call so materialized theme modules "just work" without the caller having to know about `Rendro.Theme.Presets.register_fonts/2` separately:

```elixir
defmodule MyApp.Theme do
  @moduledoc "GENERATED by `mix rendro.gen.theme editorial --accent #0E7C76`. Do not hand-edit."
  def theme(opts \\ []),
    do: Rendro.Theme.preset(:editorial, Keyword.merge([accent: {14, 124, 118}], opts))
  def register_fonts(document),
    do: Rendro.Theme.Presets.register_fonts(document, :editorial)
end
```

New file: `lib/mix/tasks/rendro/gen/theme.ex` (`Mix.Tasks.Rendro.Gen.Theme`).

### Livebook as third tinkerer surface

`guides/livebook/first_invoice.livemd` (aliased at `doc/first_invoice.livemd`, listed in `mix.exs`'s package `:files` and `docs.extras`) is the existing Livebook. Extending it with a preset-picking cell (`Rendro.Theme.preset(:editorial, accent: Kino.Input.color(...), mode: :light)` re-rendered live) is additive content in the same file — no new module needed, but it does mean `mix.exs`'s docs-contract Livebook lane (whatever currently asserts the `.livemd` renders/executes) needs to keep passing with the new cell.

## New File/Directory Layout

```
lib/
├── rendro/
│   ├── theme.ex                    # MODIFIED — + preset/2
│   ├── theme/
│   │   └── presets.ex              # NEW — style-genre data + register_fonts/2 bridge
│   ├── branded.ex                  # unchanged — reference pattern for font path resolution
│   └── catalog.ex                  # NEW — domain × brand × preset × mode grid generator
├── mix/tasks/
│   ├── brand.gen.ex                # unchanged — reference pattern for --check drift gate
│   └── rendro/
│       ├── launch_artifacts/gen.ex # unchanged
│       ├── catalog/gen.ex          # NEW — mix rendro.catalog.gen
│       └── gen/theme.ex            # NEW — mix rendro.gen.theme
priv/
├── examples/<domain>/
│   ├── <existing-brand>/           # unchanged
│   ├── <new-brand-2>/              # NEW data, no code
│   └── <new-brand-3>/              # NEW data, no code
├── fonts/                          # NEW — vendored curated fonts (4 families)
│   ├── <grotesque>/*.ttf
│   ├── <humanist-sans>/*.ttf
│   ├── <text-serif>/*.ttf
│   └── <mono>/*.ttf
└── quality/rubric_scores.json      # MODIFIED — additive brand/preset/mode fields
assets/rendro/
├── gallery/, artifacts.json        # UNCHANGED — the existing 11-row launch showcase
├── catalog/<domain>/<brand>/       # NEW — <preset>-<mode>.png tree
├── catalog.json                    # NEW manifest
└── configurator/                   # NEW — static index.html + configurator.js
NOTICE                               # MODIFIED — + one license block per curated font
mix.exs                              # MODIFIED — package.files += priv/fonts; docs extras += new guide(s)
priv/public_api.json                 # MODIFIED (regenerated) — Rendro.Theme gains preset/2
priv/support_matrix.json             # MODIFIED — new theming.presets row
priv/schemas/rubric_scores.schema.json # MODIFIED — additive optional fields
guides/theming.md or guides/presets.md # MODIFIED/NEW — presets + font-registration bridge documented
```

## Architectural Patterns

### Pattern 1: Pure-value composition over a fixed pipeline seam

**What:** `Theme.preset/2` is built entirely from existing, already-audited primitives (`resolve/1`, `dark/1`, `on_accent_for/2`) rather than introducing new merge/validation code.
**When to use:** Any time a new "constructor" for `%Rendro.Theme{}` is needed (this is the same shape `from_brand/2` already established).
**Trade-off:** Slightly less flexible (a preset can't define its own bespoke dark palette, since `dark/1`'s swap is universal) in exchange for zero new risk surface and automatic idempotency/validation inheritance.

### Pattern 2: Data lives in `priv/`, logic lives in `lib/`, one path-resolution hop between them

**What:** `Rendro.Branded.font_path/0` → `priv/branded/fonts/*.ttf`; the same shape applies to `Rendro.Theme.Presets`/`Rendro.PresetFonts` → `priv/fonts/*.ttf`, and to `Rendro.Examples.load!/1` → `priv/examples/<domain>/<brand>/*.json`.
**When to use:** Any new binary/data asset the library ships.
**Trade-off:** None significant — this is the established, low-risk convention; deviating (e.g. hardcoding a path inline in a recipe) would be the anti-pattern.

### Pattern 3: Additive-only manifest/schema evolution

**What:** New optional fields added to existing JSON contracts (`rubric_scores.json`, `artifacts.json`'s already-reserved `theme`/`mode`/`preset` keys) rather than breaking/renaming existing shape. Precedent: v2.3's `explicit_deferral` field addition to `support_matrix.json`.
**When to use:** Every manifest touched by this milestone.
**Trade-off:** Slightly more verbose schemas over time, in exchange for every existing docs-contract test continuing to pass unmodified.

### Pattern 4: Separate manifest/tree for a new artifact class rather than widening an existing one

**What:** `assets/rendro/catalog.json` + `assets/rendro/catalog/` as siblings of `artifacts.json` + `gallery/`, instead of growing `@gallery_specs` from 11 to ~186 entries in place.
**When to use:** When the new artifact class has materially different cardinality/purpose (public browsable catalog vs. curated README hero strip) from the existing one.
**Trade-off:** Two manifests to keep mentally distinct, in exchange for zero regression risk to the already-tested, already-required 11-row launch gallery contract.

## Data Flow

### Catalog-generation flow (new, build-time only)

```
priv/examples/<domain>/<brand>/*.json  ──Rendro.Examples.load!──► raw fixture map
        │
        ▼  ExamplesData.transform_<family>/1
   recipe data map
        │
        ├──────────────────────────────────────────────┐
        │                                               │
Rendro.Theme.Presets.fetch!(:editorial) ──► Theme.preset(:editorial, accent:, mode:) ──► %Theme{}
        │                                               │
        ▼                                               │
Theme.Presets.register_fonts(doc, :editorial)            │
        │                                               ▼
        └──────────────► Recipe.document(data, theme: theme) ──► %Rendro.Document{}
                                                          │
                                    (UNCHANGED pipeline: build→compose→measure→paginate→render→validate)
                                                          ▼
                                                   deterministic PDF bytes
                                                          ▼
                                    Rendro.Adapters.Pdfium.render (raster, advisory lane)
                                                          ▼
                                sha256 + write PNG under assets/rendro/catalog/<domain>/<brand>/
                                                          ▼
                                append row to assets/rendro/catalog.json
                                                          ▼
                     (optional, incremental) human-scored row in priv/quality/rubric_scores.json
                                                          ▼
                          write_configurator_index (trimmed subset for client JS)
```

### Configurator runtime flow (client-side, zero server)

```
browser loads assets/rendro/configurator/index.html
        │
        ▼ parse location.search
{domain, preset, accent_id, mode} ──► exact key lookup in configurator_index.json
        │
        ▼
show pre-rendered PNG (assets/rendro/catalog/.../<preset>-<mode>.png)
        │
        ▼ "copy" click
client-side string template: `Rendro.Theme.preset(:editorial, accent: {...}, mode: :dark)`
        │
        ▼
selection re-serialized into location.search (shareable URL)
```

### `mix rendro.gen.theme` flow (separate, simplest)

```
CLI args (preset, --accent, --mode, --out) ──► compute module source string
        │
        ├── no --check:  File.write!(out_path, source)
        │
        └── --check: File.read(out_path) vs. computed source
                       match → OK
                       drift → Mix.raise("STALE — run mix rendro.gen.theme ...")
```

## Boundary & Determinism Considerations

| Concern | Milestone C impact | Why it holds |
|---------|---------------------|---------------|
| Byte-reproducibility of un-themed calls | None | `preset/2` and `presets.ex` never touch the `theme: nil` literal branches in any recipe's `palette/1`/`typography/1`, nor `@default_colors`/`@default_typography`. |
| `resolve/1` idempotency | Preserved | `preset/2`'s final step is a call to the unmodified `resolve/1`; no new merge logic is introduced. |
| `dark/1` correctness | Preserved, and reused verbatim | The existing absolute-swap semantics apply identically to preset-derived themes; zero code change required. |
| Design-systems-as-code / brands-as-data boundary | Preserved, extended correctly | `presets.ex` (style genres, industry-agnostic) stays code; new brand fixtures stay JSON under `priv/examples/<domain>/<brand>/`, never `.ex` modules. `theme_industry_guard_test.exs` should gain a sibling assertion scanning `presets.ex` for the same industry-agnostic guarantee. |
| Hex package hygiene | Requires one addition | `priv/fonts` must be added to `mix.exs`'s `package.files` (fonts ship to consumers); `priv/quality`/`priv/schemas`/`assets/rendro/catalog*` stay dev/docs-only and should **not** be added, mirroring the existing `priv/quality`/`priv/schemas` exclusion precedent. |
| Public API surface discipline | One controlled widening | Only `Rendro.Theme.preset/2` becomes public (`priv/public_api.json`'s `Rendro.Theme` entry gains one function via `mix rendro.api.gen`); `Rendro.Theme.Presets`, `Rendro.Catalog`, `Rendro.PresetFonts` stay `@moduledoc false` internals, consistent with `Rendro.Branded`/`Rendro.ExamplesData`/`Rendro.LaunchArtifacts`. |
| Font error semantics | Unchanged, reused | `{:unknown_logical_font, name}` is the existing typed error; presets introduce no new error shape, only new callers who must remember to call `register_fonts/2`. |
| Catalog artifact determinism | Same hash-check discipline as launch gallery | `deterministic: true` render + sha256 + committed manifest, exactly like `Rendro.LaunchArtifacts`; the only new decision is a *second* manifest/tree rather than growing the first. |

## Anti-Patterns to Avoid

### Anti-Pattern 1: Making `default/0` depend on `presets.ex`

**What people might do:** Since Swiss is "the `Theme.default()` basis," implement `default/0` by calling `Presets.fetch!(:swiss)` to avoid duplicating numbers.
**Why it's wrong:** Couples the single most safety-critical byte-identity path (`default/0`, doctested as `== %Rendro.Theme{}`) to new, evolving preset data — any future preset tuning risks silently changing `default/0`'s output and every recipe's byte-identity golden.
**Do this instead:** Keep `default/0` a bare struct literal; let Swiss's preset entry in `presets.ex` numerically echo it as an independent, explicit data definition.

### Anti-Pattern 2: Auto-registering preset fonts inside `document/2`

**What people might do:** Make each recipe's `document/2` inspect `opts[:theme]` and silently call `Document.register_embedded_family/3` for any preset font roles it finds, to spare callers the extra step.
**Why it's wrong:** Violates `Theme`'s "touches no registry" purity guarantee, makes every recipe implicitly `presets.ex`-aware (widening seven files instead of one), and contradicts the seed's explicit "no silent substitution" contract — silent auto-registration is a form of silent substitution risk (wrong font file resolved without the caller ever seeing the failure mode).
**Do this instead:** Keep the explicit `Theme.Presets.register_fonts(document, preset_name)` step; make it a one-liner that catalog gen, codegen output, and docs examples all call consistently.

### Anti-Pattern 3: Growing `@gallery_specs` in place to 186 entries

**What people might do:** Treat "extends `mix rendro.launch_artifacts.gen`" literally and append 175 more pattern-match clauses to `Rendro.LaunchArtifacts`.
**Why it's wrong:** Turns an already-tested, required-CI-lane module into an unmaintainable wall of near-duplicate clauses, and risks accidental drift in the 11 existing, already-blessed rows during a large diff.
**Do this instead:** New sibling module (`Rendro.Catalog`) + new sibling manifest/tree, reusing (not modifying) `LaunchArtifacts`'s render/hash idiom.

### Anti-Pattern 4: Fuzzy color-distance "nearest tile" matching in the configurator

**What people might do:** Implement Euclidean/CIE-distance nearest-neighbor matching between an arbitrary user-picked color and the catalog's baked-in accents.
**Why it's wrong:** Adds client-side color-math complexity for no real benefit, and can show a preview that is *not actually* what the copied `Theme.preset(...)` snippet renders (an accent the user picked ≠ the accent baked into the shown tile) — a truthfulness gap in a project that otherwise polices claim/evidence honesty rigorously (`priv/support_matrix.json`, docs-contract lanes).
**Do this instead:** Constrain the accent picker to the catalog's own finite, generated swatch set; "nearest tile" becomes an exact key lookup that is always truthful.

### Anti-Pattern 5: Requiring 100% rubric coverage of the full catalog grid before shipping

**What people might do:** Block Milestone C close on every one of ~186 cells having a human-signed rubric score.
**Why it's wrong:** Contradicts the seed's own "standing ratchet... over time" framing, and human visual sign-off does not scale to that cardinality in one milestone — it would either become a bottleneck or (worse) get rubber-stamped, undermining the honesty discipline the rubric exists to enforce.
**Do this instead:** Score a flagship subset now; leave the schema/tooling able to grow the `scores[]` array incrementally in future sessions, mirroring the `stress_exemption` block's declarative-and-honest-about-scope pattern already in the codebase.

## Suggested Build Order (dependency-respecting)

1. **Fonts + presets (foundation).**
   a. Vendor curated font files under `priv/fonts/`, add per-font `NOTICE` entries, add `priv/fonts` to `mix.exs` package files.
   b. Build the `Rendro.Theme.Presets`/`Rendro.PresetFonts` path-resolution + `register_fonts/2` bridge.
   c. Add `presets.ex` preset data + `Rendro.Theme.preset/2`, byte-provable in isolation (no catalog/configurator dependency) — regenerate `priv/public_api.json`.
   *No dependency on anything else in this milestone; independently testable end-to-end (`Theme.preset/2` → recipe `document/2` → render → pdfium raster).*

2. **New example-brand fixtures (data, parallel-safe).**
   Add 1-2 more brand directories per domain under `priv/examples/<domain>/`. Depends only on the *already-shipped* v2.11 theme contract, not on presets — can be authored in parallel with step 1.

3. **Carryover polish (WINDOWS ids 1-3 + `from_brand` golden + typography depth) — pull this forward, not last.**
   The milestone context explicitly notes this polish "directly affect[s] catalog quality (dark tiles in the ratchet must look right)." Doing it *after* catalog generation means regenerating hash-checked catalog artifacts a second time once the fixes land. Land it here, before catalog gen, so the very first catalog generation pass already reflects legible dark tiles, correct Ticket hierarchy, and wrap-safe Payslip numeric cells.

4. **Catalog generation.**
   Depends on steps 1-3 all existing (presets + fonts to theme the grid, multi-brand fixtures to populate it, polish fixes so the first generated grid is already correct). Build `Rendro.Catalog`, the new `mix rendro.catalog.gen` task, `assets/rendro/catalog.json` + tree, and widen the `rubric_manifest_contract_test.exs` cross-check to accept catalog evidence.

5. **Rubric-ratchet scoring pass (flagship subset).**
   Depends on step 4's artifacts existing. Score a deliberately bounded subset (not the full grid) with human sign-off, following the existing `rubric_scores.json` justification/evidence discipline.

6. **Static configurator + `mix rendro.gen.theme`.**
   The configurator strictly depends on step 4's catalog PNG tree/index existing as its data source. The codegen task depends only on step 1 (presets) and could technically ship earlier, but bundling it here keeps "the ergonomics half of the milestone" as one coherent phase, and lets the generated-module pattern be demonstrated against real catalog tiles in docs. Extend the Livebook (`guides/livebook/first_invoice.livemd`) as the third tinkerer surface in this same phase.

7. **Docs/manifest closure.**
   `priv/support_matrix.json` new `theming.presets` row, `guides/presets.md` (or `guides/theming.md` extension), README/HexDocs wiring, final `mix rendro.api.gen`/`mix rendro.launch_artifacts.check`-style contract verification pass.

## Sources

- `/Users/jon/projects/rendro/lib/rendro/theme.ex` (full read) — struct shape, `default/0`/`resolve/1`/`dark/1`/`from_brand/2` implementations, idempotency and validation mechanics.
- `/Users/jon/projects/rendro/lib/rendro/font_registry.ex` (full read) — registration API, typed error shapes, embedded-family validation.
- `/Users/jon/projects/rendro/lib/rendro/recipes/invoice.ex` (full read) — 3-rung pattern, `palette/1`/`typography/1` twin seams, theme threading.
- `/Users/jon/projects/rendro/lib/rendro/recipes/branded_invoice.ex` (excerpt) — `Document.register_embedded_font/register_image` call pattern.
- `/Users/jon/projects/rendro/lib/rendro/launch_artifacts.ex` (full read) — `@gallery_specs`, manifest shape, S6 `theme`/`mode`/`preset` seam already reserved, hash-check/docs-block generation machinery.
- `/Users/jon/projects/rendro/lib/mix/tasks/rendro/launch_artifacts/gen.ex`, `check.ex` — mix task wrapper shape.
- `/Users/jon/projects/rendro/lib/mix/tasks/brand.gen.ex` (full read) — `--check` drift-gate idiom to reuse for `mix rendro.gen.theme`.
- `/Users/jon/projects/rendro/lib/rendro/branded.ex` — path-resolution precedent for vendored assets.
- `/Users/jon/projects/rendro/priv/quality/rubric_scores.json`, `/Users/jon/projects/rendro/test/docs_contract/rubric_manifest_contract_test.exs` — ratchet schema, cross-manifest validation pattern.
- `/Users/jon/projects/rendro/priv/examples/` directory listing + `/Users/jon/projects/rendro/priv/examples/invoice/DOMAIN.md` — current one-brand-per-domain fixture layout.
- `/Users/jon/projects/rendro/priv/public_api.json` (`Elixir.Rendro.Theme` entry), `/Users/jon/projects/rendro/priv/support_matrix.json` (`theming` block) — current manifest shapes to extend.
- `/Users/jon/projects/rendro/mix.exs` (`package/0`, `docs/0`) — Hex package file allowlist, guide/extras wiring.
- `/Users/jon/projects/rendro/.planning/PROJECT.md` — milestone context, shipped v2.11 theme contract, carryover WINDOWS items.
- `/Users/jon/projects/rendro/.planning/seeds/SEED-004-style-genre-presets-public-catalog.md`, `SEED-003-document-theming-token-system.md` — locked design + breadcrumbs.

---
*Architecture research for: Rendro v2.12 Style-Genre Presets, Public Catalog & Static Configurator*
*Researched: 2026-07-28*

# Stack Research

**Domain:** Pure-Elixir PDF library — style-genre presets, vendored open-license fonts, public example catalog, static client-side configurator, codegen task
**Researched:** 2026-07-28
**Confidence:** HIGH (font licenses verified against official upstream license files; configurator/codegen approach verified against this repo's actual existing pipeline, not inferred)

## Recommended Stack

### Core Technologies

No new runtime dependencies for any of the four target features. This milestone is **pure composition over what already ships** — `Rendro.Theme`, `Rendro.FontRegistry`, `Rendro.LaunchArtifacts`/`mix rendro.launch_artifacts.gen`, ExDoc's existing asset copy-through, and `mix brand.gen`'s codegen shape. That is itself the headline stack finding: nothing in `mix.exs` `deps()` needs to change.

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `Rendro.Theme.resolve/1` + `dark/1` (existing) | shipped v2.11 | Backing value type for every preset | `PRESET-01` presets are *just* `%Rendro.Theme{}` values built via the existing constructors — a new `lib/rendro/theme/presets.ex` module with named functions (e.g. `preset(:editorial, accent:, mode:)`) that call `resolve/1`/`dark/1` internally. No new struct, no new resolution engine. |
| `Rendro.FontRegistry.register_embedded/register_embedded_family` (existing) | shipped | Loads vendored TTFs into a document's font table | Presets reference **font roles** (`:default`, `:heading`, etc.), not files directly — the caller (or a preset-provided default registry helper) registers `priv/fonts/<family>/*.ttf` through this existing seam. An unregistered role already raises a typed error (no silent substitution) — this milestone adds font *files*, not font *plumbing*. |
| ExDoc `docs: [assets: %{"assets" => "assets"}]` (existing, `mix.exs:135`) | ex_doc (existing dep) | Publishes the static configurator with zero new CI | `assets/` is already copied byte-for-byte into the ExDoc build and published by the existing `hexdocs.yml` `mix hex.publish docs` step. Put the configurator at `assets/rendro/configurator/index.html` (+ `.css`/`.js`) and it ships for free on the next docs publish — no new workflow, no build step, no Node. |
| `Mix.Task` + `OptionParser` (Elixir stdlib) | bundled | `mix rendro.gen.theme` codegen | `mix brand.gen` (`lib/mix/tasks/brand.gen.ex`) is the exact template: parse opts → build file content as a string → `File.write!/2`, with a `--check` mode that re-derives the expected content and diffs it against what's on disk, `Mix.raise`-ing on drift. `mix rendro.gen.theme` reuses this shape verbatim; no templating engine (EEx unnecessary for this much text — plain string interpolation matches the existing `build_css`/`build_tailwind` style). |

### Supporting Libraries (fonts)

**Constraint verified against `lib/rendro/pdf/font_subsetter.ex`:** Rendro's embedded-font path parses/subsets **TrueType glyf/loca-table fonts** (`fetch_required_table(tables, "glyf")`, `"loca"`). It does **not** walk a CFF table. This means every vendored font **must ship an official static TrueType (`.ttf`) build** — CFF-flavored OpenType (`.otf`)-only or variable-font-only distributions are not usable as-is. All four recommendations below have official static-TTF releases, so this is a real constraint but not a blocker.

| Font Role | Family | Version / Source | License | Genre(s) Covered | Why |
|-----------|--------|-------------------|---------|-------------------|-----|
| Grotesque | **Inter** | rsms/inter (latest stable release), static `Inter-*.ttf` build | SIL OFL 1.1 (`Inter` is a Reserved Font Name — restricts only who may call a *derivative* "Inter"; bundling/embedding/redistributing the original is explicitly permitted) | **Swiss / International** (also the sans body in **Editorial**) | A true neutral grotesque with tight, Univers/Helvetica-adjacent metrics and no personality of its own — exactly the "serious default" register Swiss/International needs. Enormous glyph/script coverage, mature hinting, the most widely vetted OFL grotesque in current use. |
| Humanist sans | **Source Sans 3** | `adobe-fonts/source-sans` (release branch), static `TTF/` build | SIL OFL 1.1 | **Humanist** | Adobe's first open-source family; genuinely humanist proportions (open apertures, larger x-height, warmer than Inter) without drifting into display/quirky territory — fits "SaaS/consumer" warmth while staying business-document-safe. |
| Text serif | **Source Serif 4** | `adobe-fonts/source-serif` (release branch), static `TTF/` build | SIL OFL 1.1 | **Editorial** (headings) + **Corporate-Classic** (body/headings, restrained settings) | Designed as Source Sans's metrics-compatible sibling by the same foundry — the "serif headings + sans body" Editorial pairing is a first-party, intentionally-designed pairing, not an improvised one. The same family serves Corporate-Classic by dialing the *theme* (tighter type-scale contrast, restrained navy/gray, boxed rules) rather than swapping fonts — one vendored serif, two genres, per the milestone's 4-font budget. |
| Mono | **JetBrains Mono** | `JetBrains/JetBrainsMono` (latest release), static `fonts/ttf/*.ttf` | **Apache License 2.0** | **Minimal-Mono** | Purpose-built for tabular/code contexts: true tabular figures, disambiguated glyphs (0/O, 1/l/I), restrained default tracking — matches "tracked-caps labels, tabular figures" intent for dev-tool/fintech documents. Also satisfies the "Apache-2.0 preferred" note — it's the one family in this set under Apache-2.0 rather than OFL, which changes the attribution mechanics slightly (see Licensing below). |

**Already vendored, reusable as a fifth option / precedent:** `priv/branded/fonts/B612-Regular.ttf` (SIL OFL 1.1, The B612 Project / Airbus, 153 KB) — currently used for `BrandedInvoice`'s demo brand font. Its sibling **B612 Mono** (same license, same foundry) is a legitimate alternate Minimal-Mono candidate if JetBrains Mono's coding-tool connotation feels too narrow for a genre also aimed at "fintech" documents — noted as an alternative, not the primary recommendation, because JetBrains Mono's tabular-figure discipline is stronger for numeric-heavy business tables.

### Licensing mechanics (verified, not assumed)

- **SIL OFL 1.1** (Inter, Source Sans 3, Source Serif 4, B612): explicitly permits fonts to be "bundled, embedded, redistributed and/or sold with any software" — a Hex package tarball is exactly this case. The only restriction is Condition 1 (the font may not be sold *by itself*) and the Reserved Font Name clause (derivatives can't reuse the original name). Requirement: **the OFL 1.1 license text + copyright notice must travel with the font** — either as a standalone `OFL.txt` next to each font file, or consolidated in the repo's `NOTICE` file. This repo already has the second pattern (`NOTICE` currently holds B612's copyright line + full OFL 1.1 text verbatim) — extend it with one additional copyright line per new OFL font (the license body itself is identical across all four OFL fonts, so it does not need repeating four times, only the per-font copyright attribution line does).
- **Apache License 2.0** (JetBrains Mono): permits redistribution with or without modification, in source or binary form, provided a copy of the license and a `NOTICE` file (if the upstream project ships one) are included and any modifications are marked. JetBrains's repo ships a `LICENSE` (Apache 2.0 text); no separate `NOTICE` file to propagate. Add the Apache 2.0 license text as its own attribution block in the repo's `NOTICE` file, clearly scoped to "JetBrains Mono" so it isn't mistaken for governing the whole package (which is MIT per `package: [licenses: ["MIT"]]` in `mix.exs`).

### Fonts explicitly NOT safe / NOT recommended to redistribute

| Font | Why it's excluded |
|------|--------------------|
| Helvetica Neue, Univers, Akzidenz-Grotesk, SF Pro, Frutiger, Futura | Proprietary commercial licenses (Linotype/Monotype/Apple). Frequently what people *mean* by "neutral grotesque" for a Swiss preset, but none are redistributable inside an open-source Hex tarball. Inter is the correct free substitute — it was explicitly designed to fill this exact gap. |
| Google-hosted "Google Fonts" families in general | Most Google Fonts entries are individually OFL/Apache and *would* be fine to vendor by license, but pulling them means checking each family's actual upstream `OFL.txt` — Google's own mirrored copies sometimes lag or subset differently from the type designer's canonical release. Prefer the type designer's/foundry's own GitHub release (as done above for Inter, Source Sans/Serif, JetBrains Mono) as the license-of-record and the byte-identical source to vendor from. |
| Any variable-font-only distribution (single `[wght]` axis file, no static instances) | Compatible with modern browsers but not with `Rendro.PDF.FontSubsetter`'s glyf/loca walk in the way a single-weight static TTF is, and it embeds every interpolation instance's outline data whether used or not — wasteful for a fixed-weight PDF embed. All four recommended families ship static per-weight TTFs alongside their variable build; vendor the static ones. |
| Fonts distributed only as `.otf`/CFF (e.g. many classic Adobe Originals postscript-only releases) | `Rendro.PDF.FontSubsetter.subset/2` requires `glyf`/`loca` TrueType outline tables; a CFF-outline OTF would fail the subsetter's `fetch_required_table` calls. Confirm a TTF build exists before adding any additional family later. |

### File-size / subsetting implications for the Hex tarball

- Reference point already in the tree: `priv/branded/fonts/B612-Regular.ttf` = **153 KB** for one weight.
- Representative single-weight sizes for the new picks (official static TTF release, full glyph/script coverage as shipped): Inter Regular ≈ **300 KB**, JetBrains Mono Regular ≈ **260 KB**; Source Sans 3 / Source Serif 4 static weights are comparable (~150–300 KB each, Adobe's broad Latin/Cyrillic/Greek coverage). These are full, un-subset upstream files — treat them as upper bounds, not the vendored size.
- **Rendro already performs per-render glyph subsetting at PDF-embed time** (`Rendro.PDF.FontSubsetter.subset/2`, driven by `used_glyphs` from the actual document text) — so the *runtime PDF output* size is unaffected by how large the vendored source TTF is. The size concern is scoped **entirely to the Hex package tarball / git repo**, not to generated documents.
- Recommendation: **do not vendor the full family (all 18 weight/style combinations)**. `Rendro.FontRegistry.register_embedded_family/3` needs exactly 4 variants (regular/bold/italic/bold_italic) *if* a role is registered as a full family; `register_embedded/4` allows registering fewer, individually. Start lean: **Regular + Bold per role** (headings/emphasis), add **Italic** only for the text serif (Editorial captions/attributions commonly use it), skip Bold-Italic until a preset actually needs it. That's roughly 4 grotesque + 4 humanist + 6 serif (adds italic) + 4 mono = **~18 files**, versus 64 for four full 4-variant families — cutting vendored bytes by roughly two-thirds before any subsetting.
- Further shrink with **`fonttools pyftsubset`** (Python, dev-time-only tool — not a runtime dependency, run once when curating the vendored files, output committed as static bytes) restricted to Latin + Latin-1 Supplement + Latin Extended-A/B + General Punctuation + Currency Symbols. This is the standard web-font subsetting move and typically removes the bulk of a broad-coverage family's Cyrillic/Greek/extended-script glyph data — expect roughly a 50–70% size reduction on Inter/Source Sans/Source Serif specifically, since their upstream builds carry multi-script coverage this project doesn't need for business documents in Latin-script locales. JetBrains Mono is already narrower in script coverage, so the win there is smaller. Treat the subsetting step as **curation-time, not build-time or runtime** — commit the already-subsetted static bytes to `priv/fonts/`, do not add `fonttools`/Python to the mix release or CI dependency graph.
- **Packaging integration point:** `mix.exs` `package[:files]` (currently `lib assets/rendro priv/branded priv/examples bench/results guides ...`) does **not** include `priv/fonts` — it must be added explicitly, or the new fonts should follow the existing `priv/branded/fonts/` convention instead of a new `priv/fonts/` top-level directory (the seed's breadcrumb names `priv/fonts/`, but `priv/branded/fonts/` is the directory Hex packaging already allowlists and NOTICE already documents — worth a deliberate decision at plan time, not a default). Either path is Hex-package-allowlist-based (deny-by-default), so silently adding a new `priv/` directory without touching `package[:files]` will make the fonts invisible in the published Hex tarball while still working in local/CI checkouts — a classic footgun this project has already guarded against once (`priv/schemas`/`priv/quality` are deliberately excluded elsewhere).

### Static configurator — architecture (no framework, no build step)

| Piece | Approach | Why |
|-------|----------|-----|
| Markup/behavior | Single self-contained `assets/rendro/configurator/index.html` with inline or co-located `<script>`/`<style>` (plain HTML5 + vanilla ES2020+ JS, no bundler, no `<script type="module">` import graph needed for this scope) | Zero build step means zero new required-CI surface — the file is committed as-is and served as-is, matching the project's existing "static assets are just files in git" posture (`assets/rendro/gallery/*.png` today). |
| State | `URLSearchParams` (native browser API) reading/writing `?preset=editorial&accent=0c4a6e&mode=dark` | Matches the locked design ("Config state in the URL query string; shareable") with zero storage/server. Native since all evergreen browsers; no polyfill dependency. |
| Preview | Static `<img>` swap against the pre-rendered catalog PNGs already produced by `mix rendro.launch_artifacts.gen` (extended for `CATALOG-01`) — "nearest pre-rendered preview," not a live render | No client-side PDF rendering, no WASM PDF engine, no server round-trip. The configurator is a thin picker UI over artifacts that already exist as files. |
| Copy-to-clipboard | `navigator.clipboard.writeText(...)` (native browser API) | No clipboard.js or similar micro-library needed; broadly supported in evergreen browsers, and this is a documentation tool, not a product surface with legacy-browser SLAs. |
| Publishing | Ride the existing `docs: [assets: %{"assets" => "assets"}]` ExDoc copy-through + `hexdocs.yml` `mix hex.publish docs` job | No new workflow file, no new required check. Link to it from a short new extras page (e.g. `guides/configurator.md`, added to `mix.exs` `docs()` `extras:`/`groups_for_extras:` the same way `guides/theming.md` was added in v2.11) so it's discoverable from HexDocs navigation. |
| Local dev loop | `python3 -m http.server` or literally opening the file — no dev server dependency needed for a static single-page tool | Keeps the "no Node in core" boundary — this repo's one existing Node usage (`scripts/pdfjs_observer`) is already isolated to the non-required `ci.advisory` lane; the configurator should not become a second Node touchpoint at all, required or not. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `mix format` / `.formatter.exs` | Format the new `lib/rendro/theme/presets.ex` and `lib/mix/tasks/rendro/gen/theme.ex` | Already covers all `lib/`; no config change needed unless new file globs fall outside existing patterns. |
| `mix rendro.launch_artifacts.gen` / `.check` (existing) | Generates + hash-verifies the extended catalog grid | `CATALOG-01` extends `@gallery_specs` in `lib/rendro/launch_artifacts.ex` — the `theme`/`mode`/`preset` keys are **already reserved and threaded** in the current v2.11 schema (`@gallery_optional_s6_keys`, all 11 existing rows render `preset: null` with an explicit comment "Milestone C reserves this key untouched"). This milestone is the one that finally populates `preset:` — no schema migration needed, just new spec entries. |
| `pdfium-cli` (existing, advisory) | Rasters the catalog PNGs | Already the renderer behind `mix rendro.launch_artifacts.gen`; no new raster tool needed for a larger grid, just more invocations. |
| `fonttools` (Python, dev-machine-only, curation-time) | Subsetting vendored font source files before committing | Not a project dependency — a one-time (or occasional, on font update) manual step by whoever curates `priv/fonts/`, same spirit as this repo's existing `.tmp-pyhanko-venv` Python tooling being used only for signing-adapter dev/test, never a shipped dependency. |

## Installation

There is no `npm install` / `pip install` step for this milestone's *shipped* product — everything above is either already in `mix.exs` or a vendored static asset. The only "installation" actions are:

```bash
# 1. Fetch/verify official static TTF releases (curation-time, not automated in CI)
#    — download from each foundry's official GitHub Releases page, confirm the
#    accompanying OFL.txt / LICENSE matches what's documented above, then commit
#    the chosen weights under priv/fonts/<family>/ (or priv/branded/fonts/<family>/,
#    per the packaging decision above).

# 2. Optional: subset before committing (curation-time only, not CI)
pyftsubset Inter-Regular.ttf --output-file=Inter-Regular.ttf \
  --unicodes="U+0020-007E,U+00A0-024F,U+2000-206F,U+20A0-20CF"

# 3. Add the vendored directory to the Hex package allowlist
#    (mix.exs `package[:files]`) — otherwise it renders/tests fine locally
#    but silently ships without fonts from `mix hex.build`.

# 4. No `npm`/`node` step for the configurator — it is committed static HTML/CSS/JS
#    under assets/rendro/configurator/ and rides the existing ExDoc `assets:` copy-through.
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|--------------|-------------|--------------------------|
| Inter (grotesque) | IBM Plex Sans (SIL OFL 1.1) | If a more overtly "corporate technical" grotesque character is wanted over Inter's screen-optimized neutrality — Plex was explicitly designed as IBM's global signature face with an international/Bauhaus-adjacent brief close to the Swiss genre's intent. Equally safe to redistribute; deferred to secondary because Inter's metrics are the closer Helvetica/Univers analog the genre name implies. |
| Source Sans 3 (humanist) | Public Sans (SIL OFL 1.1, US Web Design System) | If a slightly more grotesque-leaning humanist (less warm, more government/institutional) reads better for a given customer segment. |
| Source Serif 4 (text serif) | Spectral (SIL OFL 1.1, Production Type / built for the Financial Times) or PT Serif (SIL OFL 1.1, ParaType) | Spectral if Editorial should read even more "designed for long-form screen reading" than Source Serif's more neutral Adobe house style; PT Serif if Corporate-Classic should feel more conservative/institutional than Editorial rather than sharing one family across both. Splitting into two serif files instead of one would require expanding the "4 curated fonts" budget the milestone locked. |
| JetBrains Mono (mono) | B612 Mono (SIL OFL 1.1, already-vendored sibling of `B612-Regular.ttf`) | If avoiding any "coding font" connotation matters for a fintech/business-document context — B612 Mono was designed for aircraft cockpit legibility, not developer tooling, and reuses a license/attribution already present in `NOTICE`. |
| Plain vanilla JS + native `URLSearchParams`/Clipboard APIs for the configurator | A tiny framework (Alpine.js, Preact via CDN `<script>` tag) | Only if the configurator's interaction complexity grows well past "pick from a few selects, swap an `<img>`, build a string" — e.g. if `SEED-005`'s live Studio absorbs this surface later. For the locked `CONFIG-01` scope (browse → pick → copy), a framework adds a CDN dependency and a version-pin concern for zero functional benefit. |
| Ride existing ExDoc `assets:` copy-through for configurator publishing | A dedicated GitHub Pages workflow | Only if the configurator needs its own domain/URL independent of `hexdocs.pm/rendro`, or interactive features ExDoc's static copy can't serve (neither is true today — no GitHub Pages workflow exists in this repo, and adding one would be new CI surface for no proven benefit). |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|--------------|
| Any CSS/JS framework or bundler (Tailwind, esbuild, webpack, Vite, React/Vue) for the configurator | Would introduce Node/npm as a **required** build input for a documentation-adjacent static tool, contradicting the "no Node in core CI" constraint and this repo's existing precedent of isolating its one Node usage (`scripts/pdfjs_observer`) to a non-required advisory lane | Hand-written static HTML/CSS/vanilla JS, committed as-is |
| Remote font loading (`@font-face` pointing at Google Fonts CDN, or the `mix rendro.gen.theme` codegen emitting a CDN `<link>`) | Violates the existing constraint against remote asset fetching (already an explicit `PROJECT.md` out-of-scope item: "Remote asset fetching... defer until..."), and breaks the deterministic/offline rendering guarantee — a PDF that embeds fonts must embed real bytes, not reference a URL | Vendor the TTF bytes in `priv/fonts/` (or `priv/branded/fonts/`) and register them through `Rendro.FontRegistry.register_embedded*` |
| Variable-font-only or CFF/OTF-only font distributions | Incompatible with `Rendro.PDF.FontSubsetter`'s TrueType `glyf`/`loca` table walk | Static per-weight TTF builds (all four recommended families ship these officially) |
| A new templating dependency (EEx-as-a-generator-DSL library, Mustache/Handlebars-style lib) for `mix rendro.gen.theme` | `mix brand.gen` already proves plain string-building (`build_css`, `build_tailwind`) is sufficient for this class of small generated file; adding a templating dependency for symmetry with a *different* problem (large multi-file scaffolds) is unjustified scope | Plain Elixir string interpolation / `IO.iodata`, matching `lib/mix/tasks/brand.gen.ex`'s existing style |
| Proprietary/commercial "neutral grotesque" families (Helvetica Neue, Univers, Akzidenz-Grotesk, SF Pro) | Not legally redistributable inside an open-source Hex package tarball | Inter (SIL OFL 1.1) |
| A brand-new `priv/<something>` directory for fonts without a corresponding `mix.exs` `package[:files]` update | Hex packaging is allowlist-based (deny-by-default) — this repo has already had to deliberately exclude `priv/schemas`/`priv/quality` from the tarball in a prior milestone, proving the allowlist is easy to silently miss | Explicitly add the chosen font directory to `package[:files]`, and add a docs-contract-style test asserting the fonts are present in a built tarball (mirroring the existing `branding_claims_test.exs` tarball-exclusion tripwire pattern) |

## Stack Patterns by Variant

**If a preset needs a font role no other preset uses (e.g. a future Brutalist genre wants a distinct display face):**
- Register it under its own logical name via `Rendro.FontRegistry.register_embedded/4` (not the full-family helper) if only one or two variants are actually used by the preset's type scale (e.g. only `:regular` for all-caps tracked labels never need `:italic`).
- Because an unregistered role raises a typed error rather than silently substituting, a preset can safely reference a role it expects the *caller's* registry to provide (e.g. a caller-branded heading font) — presets should default-register their own recommended vendored font but document that callers may override the role before calling the recipe.

**If the codegen task (`mix rendro.gen.theme`) needs to support multiple presets/accents per invocation later:**
- Keep the single-preset-per-invocation shape for v1 (matches `mix brand.gen`'s single-source-of-truth shape); a `--check` drift gate is far simpler to reason about and test when the generated file has one deterministic expected content string per invocation.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|------------------|-------|
| `Rendro.FontRegistry.register_embedded_family/3` | Any 4-variant TrueType set (regular/bold/italic/bold_italic) | Strict — `validate_embedded_family!/2` raises `Rendro.FontRegistry.EmbeddedFontFamilyError` on missing/extra variants. If a curated family only ships Regular + Bold, register those two individually via `register_embedded/4` under distinct logical names rather than forcing a full-family call. |
| `Rendro.PDF.FontSubsetter.subset/2` | TrueType fonts with `head`/`maxp`/`hhea`/`loca`/`glyf`/`hmtx` tables present | Confirmed by reading `lib/rendro/pdf/font_subsetter.ex`; all four recommended families' official static TTF builds carry this standard table set. |
| ExDoc `docs: [assets: ...]` copy-through | Whatever `ex_doc` version is already pinned in `mix.exs` | No version bump implied — this is existing, already-working config being extended with one more subdirectory. |
| `mix.exs` `package[:files]` allowlist | Hex package build (`mix hex.build`) | Additive-only change (append the font directory); does not interact with any other packaged path. |

## Sources

- `lib/rendro/pdf/font_subsetter.ex` (this repo) — confirmed glyf/loca TrueType requirement, HIGH confidence (primary source, code read directly).
- `lib/rendro/font_registry.ex` (this repo) — confirmed `register_embedded`/`register_embedded_family` variant contract, HIGH confidence.
- `lib/rendro/launch_artifacts.ex`, `mix.exs` `docs()`/`package()`, `.github/workflows/hexdocs.yml` (this repo) — confirmed the existing catalog-schema S6 reservation (`theme`/`mode`/`preset` keys already present, `preset: null` on all 11 v2.11 rows) and the ExDoc asset-copy publishing pipeline, HIGH confidence (primary source).
- `lib/mix/tasks/brand.gen.ex` (this repo) — the codegen template `mix rendro.gen.theme` follows, HIGH confidence (primary source).
- [Font Squirrel: Inter license](https://www.fontsquirrel.com/license/inter) — SIL OFL 1.1 confirmation, MEDIUM-HIGH (secondary aggregator, consistent with known OFL terms).
- [adobe-fonts/source-sans LICENSE.md](https://github.com/adobe-fonts/source-sans/blob/main/LICENSE.md), [adobe-fonts/source-serif LICENSE.md](https://github.com/adobe-fonts/source-serif/blob/release/LICENSE.md) — SIL OFL 1.1, official upstream repos, HIGH confidence.
- [JetBrains/JetBrainsMono](https://github.com/JetBrains/JetBrainsMono) — Apache License 2.0, official upstream repo, HIGH confidence.
- `priv/branded/fonts/B612-Regular.ttf` + repo `NOTICE` file (this repo) — existing precedent for OFL 1.1 vendoring/attribution convention, HIGH confidence (primary source).
- File-size figures (Inter Regular ≈300 KB, JetBrains Mono Regular ≈264 KB) — WebSearch aggregator results citing GitHub-hosted file sizes, MEDIUM confidence (approximate; verify exact bytes for the specific release actually vendored).

---
*Stack research for: Rendro v2.12 (Style-Genre Presets, Public Catalog & Static Configurator)*
*Researched: 2026-07-28*

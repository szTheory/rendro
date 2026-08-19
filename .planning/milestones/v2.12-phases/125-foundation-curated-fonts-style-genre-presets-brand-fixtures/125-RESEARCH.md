# Phase 125: Foundation — Curated fonts, style-genre presets & brand fixtures - Research

**Researched:** 2026-08-16  
**Domain:** Pure-Elixir theme values, embedded static TrueType fonts, deterministic PDF rendering, data-only fixtures  
**Confidence:** HIGH for internal seams; MEDIUM for upstream release metadata (re-verify asset bytes at vendoring time).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Public API: exactly `Rendro.Theme.preset/2`; canonical atoms `:swiss`, `:humanist`, `:editorial`, `:corporate_classic`, `:minimal_mono`, with `:brutalist` only if fully shipped. No `/1`, aliases, strings, or normalization.
- `preset/2` requires `accent:`; accepts RGB tuple or strict six-digit hex, optional `on_accent:`, `mode: :light | :dark` (default `:light`), and density (preset default). Reject unknown keys and invalid/missing values with actionable `ArgumentError`. Return a resolved `%Rendro.Theme{}`; build light first, derive/honor `on_accent`, then call existing `dark/1` last.
- Keep `%Theme{}` registry-inert. The pipeable bridge is `Rendro.Theme.Presets.register_fonts(document, genre)`. Register only the roles for that genre; same Rendro descriptor is idempotent, caller-owned collisions raise, and omission preserves typed unknown-font failure.
- `theme.ex` gets one narrow delegation only. Keep the existing forbidden vocabulary unchanged and strengthen its guard to allow/assert exactly that delegation; all token tables, genre dispatch, paths, and catalog behavior live in `lib/rendro/theme/presets.ex`.
- Use the D-10 token matrix from CONTEXT.md verbatim as the design contract: five required structural genres (font mapping, materialized scale, leading, spacing, rules, radius, neutrals) and optional complete `:brutalist`. Minimal-Mono defaults to `:comfortable` / `leading: 1.25`; explicit compact remains the existing `1.1` behavior.
- Vendor exactly four unmodified Regular static TTF faces: Inter 4.1, Source Sans 3 3.052R, Source Serif 4 4.005R, JetBrains Mono 2.304. Pin tag, commit, immutable URL, original filename, SHA-256, license/NOTICE provenance; accept only TrueType `glyf`/`loca` + supported cmap/metrics tables and embeddable fonts. No variants and no pre-subsetting.
- Use role atoms `:rendro_preset_grotesque`, `:rendro_preset_humanist_sans`, `:rendro_preset_text_serif`, and `:rendro_preset_mono`. Add `priv/fonts` to Hex package files; prove tarball inclusion and normalized subset-byte determinism per face.
- Add exactly two synthetic data-only brands to every existing example domain (12 directories): the D-22 Northline/Cedar, Signal/Aster, Poppy/Circuit, Aster Institute/Meridian, and Field Notes/Letterpress matrix. Brand data carries slug, display name, six-digit accent, recommended preset, and local deterministic logo reference; no modules, remote assets, custom fonts, real data, recipe branches, gradients, faux barcodes, or color-only meaning.
- Certificate cannot be excluded: fix its compose-time centered-font metric incompatibility while preserving the public `Recipe.document(theme: theme) |> Presets.register_fonts(genre)` order. Prove each required genre in light/dark, each recipe with at least one genre, all four fonts embedded, token distinctness on three material axes, no-theme/default byte identity, package/provenance/subset evidence, and human-reviewed pinned-pdfium rasters. Make no quality/accessibility/PDF-UA/print-safety guarantee.

### the agent's Discretion

Choose private helper/table representation, the registry-aware Certificate metric seam, fixture IDs/dates/amounts that preserve arithmetic, deterministic logo mechanics, and test partitioning. Small D-10 token adjustments require before/after raster evidence and must preserve genre ordering. Do not widen APIs, change atoms, add variants, reduce the fixture matrix, weaken the source guard, or pull later-phase catalog/configurator/docs work forward.

### Deferred Ideas (OUT OF SCOPE)

Phase 126 dark/hierarchy/payslip polish; Phase 127 catalog generation/curation; Phase 128 configurator/codegen; Phase 129 public docs/manifest closure; font weights/styles/features; hosted studio and persistence.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| PRESET-01 | Strict `Theme.preset/2` returns resolved theme | Delegate to a private preset data module; reuse `resolve/1`, `coerce_color`, `on_accent_for`, then `dark/1`. |
| PRESET-02 | Five quantified structural genres | Implement D-10 literal token table; test signatures and material-axis distance. |
| PRESET-03 | Preset tables only in `presets.ex` | Thin `theme.ex` delegation plus exact guard exception/positive assertion. |
| PRESET-04 | Deterministic light/dark/accent composition | Pure construction, literal token values, old byte-golden suite unchanged. |
| PRESET-05 | Missing roles fail loudly | Do not auto-register; use existing `FontRegistry` resolver error. |
| PRESET-06 | Complete optional Brutalist | Add only after five-preset proof matrix passes; otherwise omit atom. |
| FONT-01 | Four vendored static TTF faces | Release-download/preflight workflow and one role per Regular file. |
| FONT-02 | Pinned license/provenance NOTICE | Per-font delimited notice with immutable source, commit, hash, OFL and RFN statement. |
| FONT-03 | Hex package inclusion proof | Add `priv/fonts` to `package.files`; inspect `mix hex.build --unpack` contents. |
| FONT-04 | Explicit registration bridge | `Presets.register_fonts(doc, genre)` with descriptor equality/collision policy. |
| FONT-05 | Deterministic subsetting | Sort/dedupe input at `FontSubsetter.subset/2` boundary and test permutations per face. |
| CATALOG-05 | More data-only brands | Extend generic JSON schema/loader only as required; add 12 JSON + supported local marks. |
</phase_requirements>

## Summary

The phase is composition, not a new rendering system. `Rendro.Theme` already owns deep resolution, color validation, `on_accent` derivation, and absolute dark-role swapping; `Document` already owns embedded-font registration; the render pipeline already preflights and subsets registered fonts. The new private module should therefore own immutable genre data, curated font paths, and the explicit document transformation. [VERIFIED: codebase grep]

The only architectural blocker is Certificate: it resolves text widths during `document/2`, before the prescribed post-document font bridge runs, and deliberately rejects non-Helvetica roles. The plan must introduce a registry-aware metric seam (or defer geometry calculation to a point where document registration is available) without changing the caller pipe or silently measuring curated fonts using Helvetica metrics. [VERIFIED: codebase grep]

**Primary recommendation:** build the pure preset API and explicit, collision-safe font bridge first; close Certificate metric ordering second; then vendor/preflight fonts and add fixtures/proofs around the stable seam.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Preset resolution and validation | API / Backend | — | Pure Elixir value construction belongs in `Rendro.Theme`; no document state. |
| Curated font registration | API / Backend | Database / Storage | A `%Document{}` owns registry state; immutable TTF assets live under package `priv/fonts`. |
| Font preflight/subsetting/rendering | API / Backend | — | Existing pipeline resolves, parses, subsets, and embeds font bytes deterministically. |
| Certificate centered measurement | API / Backend | — | Geometry must use the same resolved font metrics as emitted text. |
| Brand fixture data/local marks | CDN / Static | API / Backend | JSON/SVG are package static data; generic loader/schema reads and validates them. |
| Raster evidence | API / Backend | External tool boundary | Rendro produces PDF; pinned PDFium performs advisory visual rasterization. |

## Project Constraints (from AGENTS.md)

- Keep core pure: no Phoenix, Oban, or admin dependency.
- Preserve deterministic and advisory verification lane separation.
- Treat documentation claims as contracts; do not claim unsupported capability.
- Prefer optional dependency guards for integrations.
- Maintain `build -> compose -> measure -> paginate -> render -> validate`; fixed and flow APIs share that core.

## Standard Stack

### Core

| Library / component | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing `Rendro.Theme` | shipped v2.11 | Resolve/validate theme data and dark mode | Reuses public struct shape and established semantics. [VERIFIED: codebase grep] |
| Existing `Rendro.Document` + `FontRegistry` | shipped | Document-local explicit embedded fonts | Already preflights embedded bytes and fails unknown roles loudly. [VERIFIED: codebase grep] |
| Existing `Rendro.PDF.FontSubsetter` | shipped | Per-render TrueType subsetting | Existing parser requires `glyf`/`loca`; normalize caller glyph IDs. [VERIFIED: codebase grep] |
| Inter Regular | 4.1 | Curated grotesque | Official release is pinned and Inter is OFL 1.1; use only static Regular TTF. [CITED: https://github.com/rsms/inter/releases/tag/v4.1] |
| Source Sans 3 Regular | 3.052R | Curated humanist sans | Official release includes TTF assets; select static Regular file. [CITED: https://github.com/adobe-fonts/source-sans/releases/tag/3.052R] |
| Source Serif 4 Regular | 4.005R | Curated text serif | Official release includes TTF and repository is OFL-1.1. [CITED: https://github.com/adobe-fonts/source-serif/releases] |
| JetBrains Mono Regular | 2.304 | Curated mono | Official release tag/commit and official OFL 1.1 statement. [CITED: https://github.com/JetBrains/JetBrainsMono/releases/tag/v2.304] |

### Supporting

| Component | Purpose | When to Use |
|---|---|---|
| `JSV` schema already in dev/test | Validate every example JSON | Extend brand-object properties generically, then test all fixtures. [VERIFIED: codebase grep] |
| `mix hex.build --unpack` | Build and inspect Hex tarball | Positive test for every `priv/fonts` path. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] |
| Existing PDFium adapter | Fixed-version raster evidence | Advisory/human proof only; pinned ref hashes remain CI-container-blessed. [VERIFIED: codebase grep] |

**Installation:** none. This phase adds no Hex dependency and therefore requires no package-legitimacy audit. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
caller opts
  -> Theme.preset(genre, accent: ..., mode: ...)
  -> Presets (private literal token table) -> Theme.resolve -> Theme.dark? -> %Theme{}
  -> Recipe.document(data, theme: theme) -> %Document{sections, font_registry}
  -> Presets.register_fonts(document, genre)
       -> collision/equality policy -> Document.register_embedded_font/3
  -> build -> preflight -> measure -> paginate -> render -> validate
       -> FontSubsetter.subset(sorted_unique_glyph_ids) -> deterministic PDF
       -> optional pinned PDFium raster proof

priv/fonts/*.ttf + NOTICE -> package allowlist -> `mix hex.build --unpack` proof
priv/examples/<domain>/<brand>/{json,svg} -> Examples.load!/schema -> later catalog consumer
```

### Recommended Project Structure

```text
lib/rendro/theme/presets.ex        # private table, strict dispatch, paths, bridge
lib/rendro/theme.ex                # exactly one public `preset/2` delegation
priv/fonts/<family>/<Regular>.ttf  # four unmodified static binaries
priv/examples/<domain>/<brand>/    # JSON plus deterministic local SVG mark(s)
test/rendro/theme/presets_test.exs # API/tokens/registration/role failures
test/rendro/pdf/font_subsetter_test.exs # glyph-order determinism per curated face
```

### Pattern 1: Pure constructor, explicit registry bridge

**What:** keep theme construction separate from document mutation. `Theme.preset/2` may resolve data but must never read font files or touch a registry; `register_fonts/2` works only on the caller’s already-created document. [VERIFIED: codebase grep]

```elixir
theme = Rendro.Theme.preset(:editorial, accent: "#0E7C76", mode: :dark)

doc =
  data
  |> Rendro.Recipes.Invoice.document(theme: theme)
  |> Rendro.Theme.Presets.register_fonts(:editorial)
```

### Pattern 2: Registration must be stable, never overwriting

Define an expected descriptor per role (`{:path, Application.app_dir(...)}`), inspect `document.font_registry` first, register if absent, accept an existing descriptor only if it describes the identical Rendro-curated file, otherwise raise an actionable collision error. Do not use `Map.put` overwrite behavior exposed by lower-level registry registration as public bridge policy. [VERIFIED: codebase grep]

### Pattern 3: Certificate metric seam

The current `centering_measure_font/1` only allows default/Helvetica because section composition happens before a document registry exists. The plan must choose one private solution that gets curated font metrics from the same curated descriptor before calculating `x`, widths, line count, and vertical estimate. Reusing its font parser/preflight helper is preferable to a second metrics parser; then test centered blocks with non-Helvetica roles and preserve no-theme bytes. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid

- **Recipe genre switches:** do not add `case genre` branches; recipe typography already consumes semantic roles.
- **Auto-registration:** hides configuration and violates the typed missing-font contract.
- **Measuring with Helvetica, rendering with curated font:** yields silently de-centered Certificate text.
- **Variable, TTC, CFF/OTTO, WOFF input:** the current subsetter validates TrueType versions and requires `glyf`/`loca`.
- **Pre-subsetting vendor files:** destroys straightforward upstream-byte provenance and turns upgrades into opaque transforms.
- **Binary marks in examples:** existing fixture and tarball tests allow only `.json`, `.md`, `.svg` under `priv/examples`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Theme merge/dark semantics | Separate preset resolver | Existing `Theme.resolve/1`, `on_accent_for/2`, `dark/1` | Preserves validated deep merge and role swap. |
| Font registry | Global font cache / auto loader | Document-owned `FontRegistry` | Keeps renders isolated and typed failures intact. |
| TTF parser/subsetter | New fonttools pipeline | Existing `FontSubsetter` + `FontRegistry.preflight/1` | Current renderer owns accepted format and PDF mapping. |
| Package inspection | Checkout-exists assertion | `mix hex.build --unpack` / tar content test | Consumers receive only allowed package files. |
| Raster baseline | Local arbitrary raster tool | Existing pinned PDFium advisory test flow | Existing bless guard prevents platform-dependent hashes. |
| Fixture-specific code | One module per brand | JSON + generic schema/loader | Maintains brands-as-data boundary. |

## Common Pitfalls

### Certificate ordering

**What goes wrong:** post-`document/2` registration is too late for Certificate’s centered text metrics.  
**Avoid:** private preflight/metric seam using the exact font descriptor, plus a regression render for a serif/mono role and default byte test. [VERIFIED: codebase grep]

### Raw-source guard failure

**What goes wrong:** adding the required word `preset` makes the current forbidden-substring test fail.  
**Avoid:** preserve vocabulary; replace the all-or-nothing assertion with a narrow removal/positive-delegation rule that permits exactly one readable `Rendro.Theme.Presets` delegation. [VERIFIED: codebase grep]

### Asset trust drift

**What goes wrong:** a mutable URL or wrong archive member makes license/provenance or parser assumptions false.  
**Avoid:** download official release archive once, record tag/commit/URL/filename/SHA-256 in NOTICE, and make preflight reject unsupported outlines/tables/embedding. [CITED: https://github.com/rsms/inter/releases/tag/v4.1]

### Subset nondeterminism

**What goes wrong:** `MapSet.to_list/1` produces unspecified order, so equal glyph sets can serialize differently.  
**Avoid:** `used_glyphs |> Enum.uniq() |> Enum.sort()` at the `subset/2` boundary and prove permutation/duplicate equality for all four faces. [VERIFIED: codebase grep]

### False visual claim

**What goes wrong:** token inequality gets described as guaranteed quality or accessibility.  
**Avoid:** assert deterministic tokens/bytes and label PDFium raster review as bounded, human/advisory evidence only. [VERIFIED: codebase grep]

## Code Examples

### Deterministic glyph boundary

```elixir
def subset(bytes, used_glyphs) when is_binary(bytes) and is_list(used_glyphs) do
  normalized = used_glyphs |> Enum.uniq() |> Enum.sort()
  # existing parser/subsetter flow receives normalized
end
```

Source: existing `Rendro.PDF.FontSubsetter.subset/2` is the sole TTF subset entry point. [VERIFIED: codebase grep]

### Positive package proof

```elixir
{_output, 0} = Rendro.Test.HexBuildCache.get_build_output()
{contents, 0} = System.cmd("sh", ["-c", "tar -xOf rendro-#{version}.tar contents.tar.gz | tar -tzf -"])
assert "priv/fonts/inter/Inter-Regular.ttf" in String.split(contents, "\n")
```

Source: the existing examples tarball contract uses this same build/cache/content-list pattern. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Recipes use only built-in default font roles | Theme typography may name document-registered logical roles | Registration must be explicit and metric-aware. [VERIFIED: codebase grep] |
| Existing examples have one brand/domain | Three fixture candidates/domain after this phase | Phase 127 can curate rather than invent catalog data. [VERIFIED: codebase grep] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | A reusable internal FontRegistry preflight/metric helper can be exposed without broadening public API. | Certificate metric seam | Planner must instead add narrowly scoped private parsing or refactor compose ordering. |
| A2 | Exact release archive filenames/layouts will match the vendoring script’s expected static Regular member. | Font vendoring | Verify archive contents and SHA-256 before committing assets. |

## Open Questions (RESOLVED)

1. **Certificate seam — resolved:** use a private `Rendro.Theme.Presets.metric_font!/1` seam that recognizes only the four Rendro-owned curated role atoms, builds and preflights the exact descriptor later consumed by `register_fonts/2` through the existing `FontRegistry` parser, and returns the parsed `%Rendro.PDF.Font{}` for Certificate centering and line estimates. Preserve the existing `:default`/`"Helvetica"` path and its bytes; unknown non-curated roles continue to fail actionably. This is private implementation only and adds no wider public API.
2. **Deterministic SVG contract — resolved:** fixtures may use local, text-free, one-color SVG marks composed only from simple deterministic geometry accepted by the existing text-only example/package path. The generic contract requires a safe-relative path resolving inside the fixture directory and rejects scripts, external references, embedded images, gradients, filters, and text. Recipe/catalog consumption remains outside Phase 125 and requires no recipe branch here.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Erlang / Elixir / Mix | build, tests, Hex proof | ✓ | OTP 28; project pins Elixir ~> 1.19 | — |
| `mix hex.build` | tarball proof | ✓ | Hex task present in project CI alias | — |
| `pdftoppm` | local preview only | ✓ | 26.04.0 | Existing PDFium advisory lane remains canonical |
| `pdfium-cli` | pinned raster proof | ✗ | — | CI pinned container/bless flow; do not substitute for canonical hashes |
| `unzip`, `shasum` | font archive/hash vendoring | ✓ | system tools | `:crypto.hash/2` can verify hash in test |

**Missing dependencies with fallback:** `pdfium-cli` is absent locally; use existing CI-only raster reference blessing. [VERIFIED: environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit (project Mix test suite) |
| Config file | `mix.exs` aliases; no separate test config needed |
| Quick run command | `mix test test/rendro/theme/presets_test.exs test/rendro/pdf/font_subsetter_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| PRESET-01..04 | strict constructor, token values, light/dark/accent, old bytes | unit + integration | `mix test test/rendro/theme/presets_test.exs` | ❌ Wave 0 |
| PRESET-05 | unregistered role typed failure | integration | `mix test test/rendro/theme/presets_test.exs` | ❌ Wave 0 |
| PRESET-06 | optional all-or-nothing Brutalist | unit + raster | same plus advisory raster | ❌ Wave 0 |
| FONT-01..02 | static-TTF parser/preflight/provenance | unit | `mix test test/rendro/theme/preset_fonts_test.exs` | ❌ Wave 0 |
| FONT-03 | archive contains four files | package integration | `mix test test/docs_contract/*font*` | ❌ Wave 0 |
| FONT-04 | pipeable registration/collision/idempotence | integration | `mix test test/rendro/theme/presets_test.exs` | ❌ Wave 0 |
| FONT-05 | glyph permutation subset bytes | unit | `mix test test/rendro/pdf/font_subsetter_test.exs` | ✅ extend |
| CATALOG-05 | 12 fixtures/schema/data-only extension/domain invariants | schema + fixture | `mix test test/docs_contract/examples_schema_contract_test.exs` | ✅ extend |

### Sampling Rate

- **Per task commit:** relevant focused ExUnit files plus `mix format --check-formatted`.
- **Per wave merge:** `mix test`.
- **Phase gate:** full suite green; separate advisory pinned-PDFium raster run reviewed before claiming visual distinctness.

### Wave 0 Gaps

- [ ] Preset constructor/token/registration/collision/Cerificate coverage.
- [ ] Curated-font preflight, table/embedding, NOTICE metadata and package-tarball contract.
- [ ] Four-font subset permutation determinism cases.
- [ ] Fixture count, generic brand block and arithmetic/domain-invariant tests.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No authentication surface. |
| V3 Session Management | no | No session surface. |
| V4 Access Control | no | No access-control surface. |
| V5 Input Validation | yes | Strict preset keyword/color validation and generic JSON schema validation. |
| V6 Cryptography | yes | SHA-256 asset provenance via platform crypto; do not hand-roll hashing. |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Malformed font / parser exhaustion | Denial of service | Vendored-only assets, strict preflight, required TTF table checks. |
| Asset substitution / supply-chain drift | Tampering | Immutable official release URL, tag/commit, original filename and SHA-256 recorded/tested. |
| Caller role overwrite | Tampering | Bridge equality check; clear collision error instead of overwrite. |
| Fixture path traversal | Elevation of privilege | Existing `Path.safe_relative/1` loader boundary. |

## Sources

### Primary (HIGH confidence)

- Local `lib/rendro/theme.ex`, `font_registry.ex`, `pdf/font_subsetter.ex`, `document.ex`, `recipes/certificate.ex`, `examples.ex`, `mix.exs`, and tests — current implementation and contracts. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- [Inter 4.1 official release](https://github.com/rsms/inter/releases/tag/v4.1) — pinned release/commit and official distribution.
- [Source Sans 3.052R official release](https://github.com/adobe-fonts/source-sans/releases/tag/3.052R) — official TTF-containing release.
- [Source Serif 4.005 official releases](https://github.com/adobe-fonts/source-serif/releases) — official TTF/OFL release record.
- [JetBrains Mono v2.304 official release](https://github.com/JetBrains/JetBrainsMono/releases/tag/v2.304) and [official license page](https://www.jetbrains.com/lp/mono/) — release pin and OFL statement.
- [Hex `mix hex.build` documentation](https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html) — `:files` allowlist and `--unpack` inspection.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing project primitives; upstream asset member/hash remains a vendoring-time check.
- Architecture: HIGH — code inspection identifies the exact registry and Certificate ordering seam.
- Pitfalls: HIGH — guard, parser, registry, and raster-lane behavior are all covered by existing source/tests.

**Research date:** 2026-08-16  
**Valid until:** 2026-09-15 for code architecture; re-verify upstream archives immediately before asset vendoring.

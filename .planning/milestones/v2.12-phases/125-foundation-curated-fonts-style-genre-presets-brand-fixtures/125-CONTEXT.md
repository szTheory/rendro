# Phase 125: Foundation — Curated fonts, style-genre presets & brand fixtures - Context

**Gathered:** 2026-08-16
**Status:** Ready for planning
**Decision mode:** User selected all gray areas and delegated a one-shot, research-backed recommendation to typed GSD advisor researchers. The decisions below synthesize those studies with the live codebase, current milestone research, official font releases, the living `brand/` system, and the older `prompts/` sources where still applicable.

<domain>
## Phase Boundary

Phase 125 establishes the independently provable foundation for the v2.12 preset/catalog milestone:

- five required style-genre presets (`:swiss`, `:humanist`, `:editorial`, `:corporate_classic`, `:minimal_mono`) and one genuinely optional P2 preset (`:brutalist`);
- four curated, pinned, open-license static TrueType font faces shipped inside the Hex package;
- an explicit, pipeable bridge that registers only the curated fonts a chosen preset needs while keeping `%Rendro.Theme{}` pure and registry-inert;
- two additional synthetic example-brand fixtures for each of the six existing `priv/examples/<domain>/` families, authored as data and local assets rather than modules; and
- proof that preset construction, font registration/subsetting, recipe rendering, rasterization, package contents, errors, and byte determinism behave truthfully.

This phase does **not** generate the public catalog, perform the Phase-126 dark/hierarchy/payslip polish, build the configurator/code generator, or publish the final guide/support-matrix claims. It may create bounded proof rasters for the preset foundation, but no catalog tree or standing quality-ratchet baseline.

</domain>

<decisions>
## Implementation Decisions

### Caller-facing API and registry flow

- **D-01 — One strict constructor:** expose exactly `Rendro.Theme.preset/2`; do not add a convenience `/1`. The first argument accepts only the canonical atoms `:swiss`, `:humanist`, `:editorial`, `:corporate_classic`, and `:minimal_mono`, plus `:brutalist` only if that optional preset actually ships. Strings, alternate spellings, aliases, and silent normalization are rejected. — **Reversibility: costly** — accepted names become a public API and generated/configurator snippets in later phases will depend on them.
- **D-02 — Required brand intent, conservative defaults:** the second argument is a keyword list with required `:accent`, optional `:on_accent`, optional `:mode` (default `:light`), and optional `:density` (default to the preset's declared value). `:accent`/`:on_accent` accept an RGB tuple or a strict six-digit hex string, matching the existing `from_brand/2` authoring boundary. Unknown keys, missing accent, malformed colors, unsupported modes, and unsupported densities raise an actionable `ArgumentError`; do not silently ignore input.
- **D-03 — Pure value result:** `preset/2` returns a fully resolved `%Rendro.Theme{}` directly, not an `{:ok, theme}` tuple. These are programmer-supplied static configuration values, matching `default/0`, `resolve/1`, `dark/1`, and `from_brand/2`. Construct the light preset first, derive or honor `on_accent`, then apply the existing `dark/1` role swap last for `mode: :dark`. No preset calculation runs per draw, block, page, or render.
- **D-04 — Error ergonomics:** every new public error follows the living voice system: what happened, which argument/role caused it, why it is invalid, and the canonical values or next call to try. Error messages show real atoms and values. They never expose file-loader internals when the actionable problem is a missing registration step.
- **D-05 — Explicit genre bridge:** the registry API is `Rendro.Theme.Presets.register_fonts(document, genre)`, document first so it reads naturally in a pipe:

  ```elixir
  preset = :editorial
  theme = Rendro.Theme.preset(preset, accent: "#0E7C76", mode: :dark)

  document =
    data
    |> Rendro.Recipes.Invoice.document(theme: theme)
    |> Rendro.Theme.Presets.register_fonts(preset)
  ```

  Register only the curated roles needed by that genre. A repeated call is idempotent only when the existing role points at the identical Rendro-curated descriptor. A caller-owned collision raises clearly rather than being overwritten. Omitting the bridge preserves the existing typed unknown-font render failure; no automatic registration or silent Helvetica fallback is added. — **Reversibility: costly** — this call shape will be copied by the Phase-128 configurator and generator.
- **D-06 — No recipe exclusion:** every required preset must compose through every applicable existing recipe path. The current Certificate implementation measures centered text before a post-`document/2` font bridge can register the preset role; Phase 125 must remove that incompatibility or introduce a registry-aware metric seam without changing the public call above. A Certificate carve-out is not acceptable. The planner chooses the internal remediation after focused research.
- **D-07 — Reconcile the raw-source guard honestly:** the current guard literally rejects the substring `preset` anywhere in `theme.ex`, while PRESET-01 requires `Rendro.Theme.preset/2`. Preserve the existing forbidden-word list unchanged, but strengthen the guard to allow and positively assert exactly one narrowly-shaped delegation to `Rendro.Theme.Presets`; run the unchanged forbidden vocabulary scan over the remaining source. `theme.ex` contains no token tables, genre dispatch, font paths, catalog logic, or other preset-aware behavior. Never hide the function through generated/dynamically named code merely to fool a source grep.

### Preset grammar and exact token direction

- **D-08 — Structural genres, not palette aliases:** genre identity comes from a coherent combination of font roles, materialized type scale, leading, spacing rhythm, rule scale, radius scale, and selected neutral-role values. Caller accent remains the only brand-color input. A preset is not accepted as distinct if it differs only by color or one numeric field.
- **D-09 — No per-genre recipe branches:** recipes continue reading the same semantic roles established in Phases 120-122. Presets change values behind those roles; they do not add `case genre` branches, per-recipe preset tables, new `%Theme{}` fields, or per-draw arithmetic. Dark mode may reduce neutral-palette differentiation because the existing absolute role swap is authoritative; typography and geometry must keep genres recognizable in both modes.
- **D-10 — Required preset token matrix:** use the following values as the design contract. Small implementation-only adjustments are allowed only when a real render proves overflow or illegibility; record any adjustment with before/after raster evidence and preserve the stated genre ordering (Corporate lowest drama, Brutalist highest).

| Preset | Fonts: heading / body / mono | Scale: display / title / subtitle / body / small / caption | Leading | Spacing: unit / tight / normal / loose / section | Rules: hairline / thin / thick | Radius: none / sm / md | Density | Neutral-role direction |
|---|---|---|---:|---|---|---|---|---|
| `:swiss` | grotesque / grotesque / mono | `21 / 16.5 / 13 / 10.5 / 9 / 8` | `1.30` | `6 / 4 / 8 / 12 / 24` | `0.5 / 1 / 2` | `0 / 1 / 2` | `:comfortable` | Preserve default high-contrast ink, white page, quiet warm rule/surface; hairlines and grid do the work. |
| `:humanist` | humanist sans / humanist sans / mono | `22 / 17 / 13.5 / 11 / 9.5 / 8.5` | `1.45` | `6 / 5 / 10 / 16 / 28` | `0.5 / 0.75 / 1.5` | `0 / 3 / 6` | `:comfortable` | Warm muted `{101,91,78}`, surface `{247,243,234}`, rule `{205,194,174}`; spacing separates sections more than rules. |
| `:editorial` | text serif / humanist sans / mono | `30 / 18 / 13 / 10 / 8.5 / 7.5` | `1.42` | `7 / 4 / 9 / 14 / 32` | `0.5 / 1 / 2` | `0 / 1 / 2` | `:comfortable` | Near-black text, muted captions, warm-white surface, restrained rule; accent remains a cue, not a body-text color. |
| `:corporate_classic` | text serif / text serif / mono | `18 / 14 / 12 / 10 / 9 / 8` | `1.30` | `6 / 4 / 8 / 12 / 24` | `0.5 / 1 / 2.5` | `0 / 0 / 0` | `:comfortable` | Cool muted `{78,89,105}`, surface `{244,246,248}`, rule `{143,154,169}`; square geometry and strong totals/frame rule. |
| `:minimal_mono` | mono / grotesque / mono | `16 / 13 / 11 / 9.5 / 8.5 / 8` | `1.25` | `4 / 3 / 6 / 10 / 20` | `0.5 / 0.75 / 1.5` | `0 / 0 / 0` | `:comfortable` | Near-monochrome muted `{96,96,96}`, surface `{248,248,248}`, rule `{184,184,184}`; mono is for headings, labels, IDs, and figures, never body prose. |
| `:brutalist` *(P2)* | grotesque / grotesque / mono | `34 / 20 / 13 / 10 / 9 / 8` | `1.20` | `8 / 4 / 8 / 12 / 24` | `1 / 2 / 3` | `0 / 0 / 0` | `:comfortable` | Maximum ink/page contrast, surface `{238,238,238}`, near-ink rule `{16,24,39}`; size and rules create force because no font-weight axis exists. |

- **D-11 — Minimal-Mono density is deliberate:** keep its default `density: :comfortable` with explicit `leading: 1.25` and compact literal spacing. The current `Theme.resolve/1` forces `leading: 1.1` whenever density is `:compact`; claiming both compact density and 1.25 would be false. A caller may explicitly request `density: :compact` and receive the existing 1.1 behavior.
- **D-12 — Brutalist is a complete P2, not a partial sixth row:** implement it only after all five required presets pass the same API, font, determinism, render, and legibility checks. If it does not fit, omit its atom entirely. Do not ship a stub or lower the five-preset proof bar to include it.

### Curated font set, licensing, and package footprint

- **D-13 — Four exact upstream faces:** vendor the unmodified Regular static TTF from each official release below:
  - Inter `4.1` — neutral grotesque;
  - Source Sans 3 `3.052R` — humanist sans;
  - Source Serif 4 `4.005R` — text serif; and
  - JetBrains Mono `2.304` — mono.

  All four official projects currently use SIL OFL 1.1. Pin the exact release tag, commit, immutable download URL, original filename, and SHA-256 at vendoring time. Re-verify the file itself has TrueType `glyf`/`loca` outlines and supported cmap/metric tables; a family name or extension alone is not proof.
- **D-14 — Four faces means four binaries:** ship one Regular face per curated role in Phase 125. Rendro's current public text contract selects a logical font atom but exposes no weight/style axis, so Bold/Italic/Bold-Italic files would be unused future-proofing, add tarball and proof cost, and create false expectations. Defer variants until a real authoring seam can select them. Do not pre-subset the vendored upstream files with `fonttools`; keep upstream bytes intact and let Rendro's existing per-render subsetter reduce generated PDFs. This makes provenance, OFL/RFN compliance, upgrades, and hashes easier to audit.
- **D-15 — Stable Rendro-owned role atoms:** use `:rendro_preset_grotesque`, `:rendro_preset_humanist_sans`, `:rendro_preset_text_serif`, and `:rendro_preset_mono`. Presets reference these roles as follows:

  | Preset | Roles registered |
  |---|---|
  | Swiss | grotesque + mono |
  | Humanist | humanist sans + mono |
  | Editorial | text serif + humanist sans + mono |
  | Corporate-Classic | text serif + mono |
  | Minimal-Mono | mono + grotesque |
  | Brutalist P2 | grotesque + mono |

- **D-16 — License and provenance are part of the artifact:** each family gets a clearly delimited `NOTICE` block with upstream project/foundry, copyright, OFL 1.1 text/reference, exact tag/commit, immutable source URL, SHA-256, and a statement that the vendored file is unmodified and retains its Reserved Font Name. Never copy from a mutable CDN or a Google Fonts mirror when the official foundry release exists.
- **D-17 — Fail closed at curation and packaging boundaries:** reject variable-only fonts, WOFF/WOFF2, TTC collections, CFF/`OTTO` outlines, restricted embedding flags, missing required tables, or parser/preflight failures. Add `priv/fonts` explicitly to `mix.exs`'s package allowlist and prove every referenced file exists in `mix hex.build` output. A local checkout render is not package proof.
- **D-18 — Determinism before catalog scale:** sort and deduplicate glyph IDs at the `FontSubsetter.subset/2` boundary (defensively, not merely by convention), run two subsets for each vendored face with differently ordered/duplicated equivalent glyph lists, and assert identical bytes. Verify no subset table introduces current timestamps. A font upgrade is an explicit, reviewable asset migration that re-runs metrics, layout, raster, PDF-byte, license, and package tests.

### Example-brand fixture system

- **D-19 — Two new brands per domain:** add exactly two fixtures to each of the six existing domains—12 new fixture directories total. This gives Phase 127 three candidates per domain including the existing fixture, enough to curate a bounded 2-3-brand catalog without inventing data during catalog work.
- **D-20 — Brands remain data:** each fixture directory contains realistic domain JSON plus a data-only brand block with a stable slug/display name, six-digit accent, canonical recommended-preset name, and local logo reference. Add no brand module, recipe branch, remote asset, or custom font. Extend the schema/loader contract only as needed to validate and preserve those data fields generically.
- **D-21 — Restrained local marks:** logo assets are simple one-color geometric page-frame, monogram, grid, route, seal, or ticket-stub marks. Use a renderer-supported deterministic local format and provide light/dark-safe variants when the consuming recipe/catalog requires them. No gradients, stock imagery, faux barcodes, tiny text in marks, or color-only meaning. Assets are fixture data, not additions to Rendro's own living brand identity.
- **D-22 — Exact fixture creative-direction matrix:** use the following synthetic brands and pairings. Realistic names and content are required; no real customer, employee, account, credential, or payment data.

  | Domain | Brand / accent / preset | JTBD and visual direction |
  |---|---|---|
  | Invoice | **Northline Logistics** / `#2C6BED` / Swiss | B2B freight-services invoice; amount/due-date scan first; `NL` route-line/page-frame mark. |
  | Invoice | **Cedar Mutual** / `#1F4FB8` / Corporate-Classic | Conservative insurance premium invoice; sober arithmetic ladder; `CM` seal monogram. |
  | Payslip | **Northline Logistics** / `#2C6BED` / Swiss | Same cross-domain brand, operational payroll; net pay first; route-line mark reused consistently. |
  | Payslip | **Cedar Mutual** / `#1F4FB8` / Corporate-Classic | Same cross-domain brand, proof-of-income formality; net/gross/YTD clarity; seal reused. |
  | Statement | **Signal Ledger** / `#0E7C76` / Minimal-Mono | Fintech operating account; closing balance and reconciliation continuity; `SL` ledger-tab/grid mark. |
  | Statement | **Aster Research Fund** / `#6E3CB8` / Editorial | Research-grant fund statement; long-form authority with readable ledger detail; restrained `AR` wordmark. |
  | Receipt | **Poppy & Grain** / `#147A4B` / Humanist | Neighborhood bakery/cafe; total/date/merchant survive a narrow print/photo; warm geometric sprig/`PG` mark. |
  | Receipt | **Circuit Supply Co.** / `#2C6BED` / Minimal-Mono | Parts-counter receipt; dense SKUs and aligned amounts; `CSC` circuit-grid mark. |
  | Certificate | **Aster Institute** / `#1F4FB8` / Swiss | Technical training credential; recipient and issuer authority; page-frame `AI` monogram. |
  | Certificate | **Meridian Arts Fellowship** / `#6E3CB8` / Editorial | Ceremonial arts award; recipient-first composition; restrained `M` seal. |
  | Ticket | **Field Notes Conference** / `#0E7C76` / Minimal-Mono | Developer conference admission; placement and reference found in seconds; `FN` registration/grid mark. |
  | Ticket | **The Letterpress Hall** / `#C24132` / Editorial | Cultural event ticket; title/time/placement hierarchy; ticket-stub `LH` mark. |

- **D-23 — Existing fixtures remain useful controls:** preserve their unthemed bytes and domain truth. Phase 127 may pair the existing fixtures with suitable presets; if Brutalist ships, Aurora Live Ticket is the preferred bounded showcase only after Phase 126 resolves or explicitly exempts its hierarchy defect.

### Proof bar and honest claims

- **D-24 — Genre proof matrix:** every required preset renders in light and dark through at least one suitable existing recipe with its curated font roles registered, and every existing domain recipe renders at least one required preset. Across that bounded matrix, all four font faces must be embedded at least once. Dark renders in this phase prove plumbing only; Phase 126 owns dark-cell visual closure before catalog generation.
- **D-25 — Distinctness has teeth:** add a token-signature contract proving no two required presets resolve to the same values and each differs from its nearest neighbor on at least three material axes among font mapping, display/body ratio, leading, spacing, rules, radius, and neutrals. Back this with human-reviewed pdfium rasters at a fixed pinned version; do not assert taste from token inequality alone.
- **D-26 — Preserve existing contracts:** the complete no-theme/default byte-identity suite stays unchanged; the current `Theme.resolve/1`/`dark/1` semantics and stable struct shape stay unchanged; no new runtime dependency is introduced; an unregistered role still fails loudly; and package contents, font provenance, and subset determinism are tested positively.
- **D-27 — No quality or compliance overclaim:** describe presets as curated, genre-distinct starting points. Never claim guaranteed design quality, accessibility, WCAG/PDF-UA conformance, print safety for dark mode, or suitability for every domain/preset pairing. Human reader-quality judgment remains separate from deterministic plumbing evidence.

### the agent's Discretion

The planner may choose private helper names, internal data-table representation, the precise registry-aware Certificate remediation, fixture IDs/dates/amounts that preserve each domain's arithmetic invariants, deterministic logo-generation mechanics, and test-file partitioning. It may make small token adjustments only under D-10's raster-evidence rule. It may not widen public APIs, add font variants, change canonical genre/role atoms, reduce the 12-fixture matrix, weaken the raw-source guard, or move later-phase capabilities into Phase 125.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** The living `brand/` sources supersede older `prompts/` brand guidance wherever they conflict.

### Phase scope and milestone research

- `.planning/ROADMAP.md` — Phase 125 goal, fixed boundary, success criteria, and phase sequencing.
- `.planning/REQUIREMENTS.md` — PRESET-01..06, FONT-01..05, CATALOG-05, and explicit exclusions.
- `.planning/PROJECT.md` — product constraints, pure-core boundary, determinism, and no-overclaim posture.
- `.planning/seeds/SEED-004-style-genre-presets-public-catalog.md` — original style-genre/catalog vision and locked starter set.
- `.planning/research/SUMMARY.md` — current v2.12 synthesis and sequencing risks.
- `.planning/research/FEATURES.md` — shipped token vocabulary and prior quantitative genre intent.
- `.planning/research/ARCHITECTURE.md` — preset/font bridge seam and data/code separation.
- `.planning/research/STACK.md` — font parser constraints, packaging, and official-source policy; D-13..18 supersede its inconsistent variant count and outdated JetBrains license classification.
- `.planning/research/PITFALLS.md` — licensing, determinism, float-math, guard, and no-overclaim failure modes.

### Living brand and older prompt context

- `brand/README.md` — living brand authority and source-of-truth order.
- `brand/tokens/tokens.json` — current palette, typography, light/dark semantics, and contrast facts.
- `brand/copy/VOICE.md` — API/error wording and anti-magic voice rules.
- `brand/audit/SCORECARD.md` — design, accessibility, distinctiveness, and maintainability pressure test.
- `brand/audit/AUDIT.md` — current living-brand critique and typography decisions.
- `prompts/Rendro Brand Book.txt` — older typography/layout/art-direction reference; defer to `brand/` on conflict.
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md` — comparable-library lessons and original product/JTBD research.
- `prompts/rendro-gsd-seed.md` — primary personas, architecture defaults, and quality posture.
- `prompts/rendro-integration-opportunities.md` — optional-adapter and coupling policy.
- `prompts/rendro-oss-dna.md` — Elixir package/API, CI, proof-lane, and docs-contract conventions.

### Prior locked theming decisions

- `.planning/milestones/v2.11-phases/119-rendro-theme-core-module-the-one-way-door/119-CONTEXT.md` — Theme field-shape, purity, and industry-agnostic boundary.
- `.planning/milestones/v2.11-phases/122-typography-type-scale-application-font-role-leading-wiring/122-CONTEXT.md` — recipe font-role/type-scale seams and typed missing-font behavior.
- `.planning/milestones/v2.11-phases/123-from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani/123-CONTEXT.md` — default palette/leading, proof discipline, and deferred preset/catalog work.

### Domain/JTBD sources

- `priv/examples/invoice/DOMAIN.md` — amount/due-date scan, audit, and print conventions.
- `priv/examples/payslip/DOMAIN.md` — net-pay, proof-of-income, privacy, and reconciliation conventions.
- `priv/examples/statement/DOMAIN.md` — closing balance, running continuity, and multi-page audit conventions.
- `priv/examples/receipt/DOMAIN.md` — narrow-format total/proof/photo-readability conventions.
- `priv/examples/certificate/DOMAIN.md` — recipient-first ceremony and verifier-authority conventions.
- `priv/examples/ticket/DOMAIN.md` — placement/code/time-pressure and small-format conventions.

### Code and contract integration points

- `lib/rendro/theme.ex` — current public constructors and fixed token shape.
- `lib/rendro/font_registry.ex` — document-owned registry, explicit embedded registration, collisions to guard, and typed resolution errors.
- `lib/rendro/pdf/font_subsetter.ex` — TrueType table and determinism boundary.
- `lib/rendro/examples.ex` — safe fixture loading/listing pattern.
- `lib/rendro/examples_data.ex` — domain transformations and current brand-slot behavior.
- `lib/rendro/recipes/certificate.ex` — pre-registration centering metric incompatibility D-06 must close.
- `mix.exs` — Hex package allowlist and CI/package proof surface.
- `priv/schemas/examples.schema.json` — additive brand-fixture data contract.
- `test/docs_contract/theme_industry_guard_test.exs` — raw-source guard that needs the exact-delegation reconciliation in D-07.

### Official upstream font sources (verify exact assets again at vendoring time)

- `https://github.com/rsms/inter/releases/tag/v4.1` — Inter 4.1 release.
- `https://github.com/adobe-fonts/source-sans/releases/tag/3.052R` — Source Sans 3.052R release.
- `https://github.com/adobe-fonts/source-serif/releases/tag/4.005R` — Source Serif 4.005R release.
- `https://github.com/JetBrains/JetBrainsMono/releases/tag/v2.304` — JetBrains Mono 2.304 release.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Rendro.Theme.resolve/1`, `from_brand/2`, and `dark/1` already supply deep resolution, accent derivation behavior, validation, and absolute dark-role swapping; presets should compose these rather than create a second theme engine.
- `Rendro.FontRegistry.register_embedded/4`, `preflight/1`, and resolution errors already implement document-owned font loading and fail-loud lookup. The bridge needs policy and collision checks, not new registry architecture.
- `Rendro.PDF.FontSubsetter.subset/2` already subsets generated PDFs; Phase 125 should normalize glyph input and prove determinism rather than pre-process upstream font assets.
- `Rendro.Examples` and `priv/schemas/examples.schema.json` already provide safe data loading and an additive `brand` object seam.
- Every recipe already reads `theme.typography.fonts` and the materialized type scale; there is no need for per-genre recipe logic.

### Established Patterns

- Pure values compose first; I/O and registry mutation are explicit caller steps.
- Public constructors return values and raise on static programmer errors; render/layout operations retain typed error results.
- Package contents are allowlisted and must be proven from a built tarball, not inferred from the checkout.
- Deterministic and advisory/human verification remain separate. Token contracts, bytes, and hashes are machine proof; quality/taste is human judgment.
- Documentation claims are product contracts, and known limitations are stated beside capabilities.

### Integration Points

- New `lib/rendro/theme/presets.ex`: all genre names, token maps, font paths, registration policy, and bridge behavior.
- `lib/rendro/theme.ex`: one public delegation only, with D-07's exact guard exception.
- `priv/fonts/` + `NOTICE` + `mix.exs`: four pinned binaries, provenance/license blocks, and Hex inclusion.
- `priv/examples/<domain>/<brand>/`: 12 new realistic JSON fixtures and local logo assets.
- `lib/rendro/recipes/certificate.ex`: registry-metric compatibility fix required by the public bridge order.
- Tests: preset/API contract, guard contract, recipe breadth/raster proofs, parser/preflight, subset determinism, fixture schema/domain invariants, unthemed byte identity, and positive Hex tarball contents.

</code_context>

<specifics>
## Specific Ideas

- The preset family should feel like one disciplined document system with five recognizable grammars, not five unrelated templates. Font, hierarchy, rhythm, rules, and geometry carry identity; accent personalizes it.
- The living Rendro brand is a reference for restraint, evidence, warm paper, precise errors, and light/dark honesty. Example brands are intentionally synthetic third parties and must not all masquerade as Rendro sub-brands.
- Cross-domain reuse of Northline Logistics and Cedar Mutual demonstrates that one brand can remain coherent across different document jobs without becoming a code module.
- Four unmodified upstream Regular faces are a deliberate scope-and-trust choice. Rendro should add weights/styles when users can actually select them, not ship dormant binaries as speculative architecture.

</specifics>

<deferred>
## Deferred Ideas

- Phase 126: invoice dark-table legibility, Ticket hierarchy resolution/exemption, payslip numeric wrapping, preset/accent byte goldens, and remaining typography-depth tests.
- Phase 127: public catalog generation, catalog row budget, scored/unscored ratchet coverage, and final light/dark brand/preset pair curation.
- Phase 128: static configurator, exact-match preview palette, shared snippet/codegen template, URL state, and Livebook extension.
- Phase 129: public presets guide, README/HexDocs/support-matrix/API-manifest closure, and claim-language tripwires.
- Font weights, italics, OpenType feature selection, small caps, and tabular-feature toggles: future work after a real public authoring seam exists.
- Live server-rendered Studio, arbitrary token editor, accounts, persistence, and hosted preview: Milestone D (`SEED-005`).

</deferred>

---

*Phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures*
*Context gathered: 2026-08-16*

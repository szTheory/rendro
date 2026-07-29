# Project Research Summary

**Project:** Rendro v2.12 — Style-Genre Presets, Public Catalog & Static Configurator
**Domain:** Pure-Elixir deterministic PDF library — design-token presets, vendored open-license fonts, a public rendered-example catalog, and a static client-side configurator
**Researched:** 2026-07-28
**Confidence:** HIGH

## Executive Summary

This milestone is pure composition over machinery Rendro already ships — `Rendro.Theme.resolve/1`/`dark/1`, `Rendro.FontRegistry`, `Rendro.LaunchArtifacts`, the `mix brand.gen` codegen shape, and ExDoc's existing asset copy-through. All four researchers converged independently on the same headline finding: zero new runtime dependencies are needed. `Theme.preset/2` is just a named partial `%Theme{}` map fed through the existing merge/validate/dark pipeline; the catalog is an additive extension of the already-reserved `theme`/`mode`/`preset` schema keys; the configurator is committed static HTML/JS riding the existing `assets:` ExDoc copy-through; and `mix rendro.gen.theme` clones `mix brand.gen`'s proven `--check` drift-gate pattern verbatim. Four curated, license-verified open fonts (a grotesque, a humanist sans, a text serif, a mono — Inter, Source Sans 3, Source Serif 4, JetBrains Mono, all OFL 1.1/Apache 2.0 with confirmed static TrueType builds) back five locked genre presets (Swiss, Humanist, Editorial, Corporate-Classic, Minimal-Mono), with a Brutalist preset as ship-if-time.

The recommended approach is disciplined isolation, not organic growth: presets live in a new `lib/rendro/theme/presets.ex` file, never in `theme.ex` (a shipped v2.11 test, `theme_industry_guard_test.exs`, statically refutes `preset`/`catalog`/`configurator`/`genre` in `theme.ex` and must never be edited to "fix" a violation); the catalog is a new sibling module and manifest (`Rendro.Catalog` + `assets/rendro/catalog.json`), not 175 more pattern-match clauses bolted onto the existing 11-row `@gallery_specs`; and the configurator's "nearest preview" is an exact key lookup against a closed, curated accent palette, never fuzzy color-distance matching against an open picker. The catalog's true cross product (~186-200 cells against a literal full grid) is the single biggest scale risk across all four research files and needs an explicit, tested row-count budget from the first commit — never generated unbounded and pruned later.

The primary risks are: (1) packaging/licensing hygiene for vendored fonts (missing `NOTICE` attribution, missing `mix.exs` `package.files` entry for `priv/fonts`, non-redistributable font sourcing) — each has a concrete precedent-based fix already established by the existing B612 font; (2) determinism regressions at catalog scale (unsorted glyph sets breaking font-subsetting byte-identity, float math sneaking into preset derivation) — both preventable by extending existing determinism tests rather than inventing new discipline; (3) sequencing — the folded-in v2.11 carryover polish (dark-mode table-body legibility, Ticket hierarchy, payslip numeric wrap) is a hard prerequisite, not a nice-to-have, because it must land before any dark-mode catalog cell is generated and rubric-scored, or the ratchet's baseline starts dishonest; and (4) quality-ratchet honesty at scale — the rubric process (human visual sign-off) cannot cover ~186-200 cells, so the ratchet must extend additively and score a flagship subset, exactly mirroring the existing `stress_exemption` precedent of declarative, honest, incomplete-by-design coverage rather than demanding 100% grid sign-off.

## Key Findings

### Recommended Stack

No new `mix.exs` dependency for any of the four target features. `Theme.preset/2` composes over shipped `resolve/1`/`dark/1`; font embedding rides the existing `FontRegistry.register_embedded`/`register_embedded_family` seam; the configurator is committed static HTML/CSS/vanilla-JS served through ExDoc's existing `docs: [assets: ...]` copy-through with zero build step; and `mix rendro.gen.theme` clones `mix brand.gen`'s plain-string-interpolation + `--check` drift-gate shape. The one hard technical constraint: `Rendro.PDF.FontSubsetter` walks TrueType `glyf`/`loca` tables directly — every vendored font must ship an official static TrueType build (no CFF-only OTF, no variable-font-only distribution).

**Core technologies:**
- `Rendro.Theme.resolve/1` + `dark/1` (existing) — backing value type/merge engine for every preset; no new struct or merge logic
- `Rendro.FontRegistry.register_embedded*` (existing) — loads vendored TTFs; already raises a typed error on an unregistered role (no silent substitution, for free)
- ExDoc `docs: [assets: ...]` copy-through (existing, `mix.exs:135`) — publishes the configurator with zero new CI surface
- `Mix.Task` + stdlib `OptionParser`, modeled on `lib/mix/tasks/brand.gen.ex` — `mix rendro.gen.theme` codegen, no templating dependency needed

**Curated fonts (all confirmed static-TTF, redistributable licenses):** Inter (grotesque, OFL 1.1), Source Sans 3 (humanist sans, OFL 1.1), Source Serif 4 (text serif, OFL 1.1, serves both Editorial and Corporate-Classic), JetBrains Mono (mono, Apache 2.0). Vendor Regular+Bold per role (Italic added only for the text serif) — roughly 18 files vs. 64 for four full 4-variant families. Subset to Latin/Latin-1/Latin-Extended-A/B at curation time with `fonttools` (dev-machine-only, never a shipped dependency).

### Expected Features

`Theme.preset/2` returns a full `%Theme{}` built from a named partial map (colors minus accent, typography, spacing, rules, radius, density) — every preset speaks only the existing `Theme` field vocabulary; no new struct fields, no modular-scale formula, no 4th rule weight (all explicitly out of scope — would widen the locked v2.11 struct contract).

**Must have (table stakes / P1):**
- `Theme.preset/2` with the 5 locked genres (Swiss, Humanist, Editorial, Corporate-Classic, Minimal-Mono) — each a concrete, quantified token delta (scale-contrast ratio, leading, rule weight, radius, spacing rhythm, color-role usage) against the `default()` baseline
- 4 curated open-license fonts, correctly embedded (regular/bold/italic where the family provides it) and packaged into the Hex tarball
- Carryover polish (dark table-body legibility, Ticket hierarchy decision, payslip numeric wrap, from_brand/preset golden depth) landed before any dark-mode catalog generation
- Public catalog: organized by domain (7 families) x curated brand/preset combos x light/dark, hash-checked, `preset`/`theme`/`mode` tags populated in the already-reserved schema keys
- Quality ratchet: every generated catalog cell scored or explicitly flagged unscored; thresholds enforced; a fail-loud coverage guard — but not 100% grid coverage as a ship gate
- Static configurator: preset + accent + mode pickers, nearest-preview snap (exact match against a closed palette), one-click copy of a `Theme.preset(...)` snippet, URL-query state
- `mix rendro.gen.theme <preset> --accent` with `--check` drift gate

**Should have (differentiators / P2):** Livebook as a third tinkerer surface; Brutalist preset (ship-if-time, hardest to keep legible); deep-linkable per-cell catalog/configurator URLs (falls out of URL-state for free).

**Explicitly deferred / anti-features:** WYSIWYG token editor, hosted/server-rendered live preview, saved-themes/accounts, per-brand custom fonts beyond the 4 curated files, auto-scoring the rubric with an LLM/heuristic — all correctly scoped out to `SEED-005`'s live Studio or rejected outright as violating the static/zero-backend/human-judgment constraints.

### Architecture Approach

Milestone C adds zero pipeline stages and zero alternate render paths — everything is either a new pure-data/pure-function seam feeding the existing `theme:` opt, or a build-time `mix` task looping the existing recipe/render/pdfium-raster machinery. `Theme.preset/2` is added to `theme.ex` as a thin public function that calls into a new `lib/rendro/theme/presets.ex` (`@moduledoc false` data module) for genre token tables, then reuses `resolve/1`'s existing deep-merge/validation and `dark/1`'s existing absolute color-swap unmodified. A small explicit bridge, `Rendro.Theme.Presets.register_fonts/2`, is the one new registry-touching function — it must stay an explicit caller step, never auto-invoked inside `document/2` (which would make every recipe implicitly preset-aware and violate "Theme touches no registry").

**Major components:**
1. `Rendro.Theme.Presets` (new, `lib/rendro/theme/presets.ex`) — genre token data + `register_fonts/2` bridge; the only place preset/genre vocabulary is allowed to live
2. `Rendro.Catalog` (new, sibling to `Rendro.LaunchArtifacts`, not a modification of it) — domain x brand x preset x mode grid generator, its own manifest (`assets/rendro/catalog.json`) and asset tree (`assets/rendro/catalog/`), reusing but not touching the existing 11-row launch-gallery machinery
3. `assets/rendro/configurator/` (new, static HTML/CSS/vanilla-JS) — client-side picker over pre-rendered catalog PNGs, URL-query state, exact-match lookup against a closed accent palette
4. `lib/mix/tasks/rendro/gen/theme.ex` (new) — CLI codegen modeled on `mix brand.gen`'s `--check` drift-gate idiom, sharing its snippet-format template with the configurator's copy button (never two independent implementations)

### Critical Pitfalls

1. **Preset logic leaking into `theme.ex` and tripping the locked industry-guard test** — `theme_industry_guard_test.exs` statically refutes `preset`/`catalog`/`configurator`/`genre` in `theme.ex`'s source; all genre-specific token tables and dispatch must live only in `lib/rendro/theme/presets.ex`. Never edit the guard's forbidden-word list to "fix" a failure — relocate the code.
2. **Missing/incomplete font packaging and licensing artifacts** — `priv/fonts` is not currently in `mix.exs` `package.files`; fonts will render fine locally but silently ship broken to real Hex consumers unless the allowlist is updated and a positive tarball-content test is added. Every font needs its own clearly-delimited `NOTICE` copyright block with a pinned upstream version, not one generic OFL entry.
3. **Catalog combinatorial explosion** — a literal full domain x brand x preset x mode cross product is ~186-200 cells (roughly 20x today's 11-row gallery), which balloons render/CI time, tarball size, and turns golden re-blessing into an unreviewable rubber stamp. Requires an explicit, tested row-count budget/ceiling from the first commit — curated {brand x preset} pairs per domain, not the full product.
4. **Font-subsetting nondeterminism at catalog scale** — `used_glyphs` is a caller-supplied list; unsorted/undeduplicated input can produce byte-different subset output for logically identical glyph sets, silently breaking sha256 catalog goldens. Sort/dedupe at the call site (or defensively inside `subset/2`) and add a double-subset determinism test per vendored font.
5. **Sequencing: carryover polish must land before dark-mode catalog generation, never after or concurrently** — every dark-mode catalog cell inherits the current dark table-body legibility bug; generating/scoring ~20-25 dark cells before the fix means either expensive re-generation or shipping a known-bad baseline into the standing ratchet.
6. **Configurator preview/render drift and overclaim risk** — an open freeform accent picker against a small pre-rendered set breaks the "preview equals actual output" guarantee; must use a closed curated accent palette so "nearest tile" is a truthful exact-match lookup, not fuzzy color-distance approximation. Combined with this: preset/catalog marketing copy must stay conditional ("a strong starting point"), never imply a blanket quality guarantee the rubric's own honest `passed: false` entries (e.g. Ticket) contradict.

## Implications for Roadmap

Based on combined research (all four files independently converge on this build order), suggested phase structure:

### Phase 1: Carryover Polish (pulled forward, not last)
**Rationale:** Every researcher flags this as a hard sequencing dependency — dark-mode catalog cells and the rubric ratchet's dark-cell scores are meaningless (or worse, dishonest) if generated against known-bad dark legibility, Ticket hierarchy, and payslip wrap defects. Doing this last means expensive re-generation of hash-checked artifacts.
**Delivers:** Fixed dark table-body legibility (WINDOWS id 1), an explicit locked decision on Ticket hierarchy (fix now, or name a `stress_exemption`-style carve-out), fixed payslip numeric-cell wrap (WINDOWS id 3, a direct prerequisite for Minimal-Mono), and expanded `from_brand`/preset golden-test depth.
**Avoids:** Pitfall 5 (hash-check drift/wasted re-bless), Pitfall 8 (ratchet baseline dishonesty).

### Phase 2: Curated Fonts + `Theme.preset/2` (foundation)
**Rationale:** Independently testable end-to-end with no catalog/configurator dependency (`Theme.preset/2` -> recipe `document/2` -> render -> pdfium raster). Presets need real font files to render as intended; fonts need presets to justify their inclusion — build together as one foundation phase.
**Delivers:** 4 curated OFL/Apache fonts vendored under `priv/fonts/` (or `priv/branded/fonts/`, a deliberate packaging decision) with `NOTICE` attribution and `mix.exs` `package.files` update; `lib/rendro/theme/presets.ex` with 5 genre token maps; `Rendro.Theme.preset/2` added to `theme.ex` as a thin composition over `resolve/1`/`dark/1`; `Rendro.Theme.Presets.register_fonts/2` bridge.
**Addresses:** PRESET-01, PRESET-02 from FEATURES.md.
**Avoids:** Pitfalls 1, 2, 3, 4, 15 from PITFALLS.md — license sourcing, tarball packaging, subsetting determinism, float-math purity, and the industry-guard boundary are all foundational-phase concerns, not later cleanup.

### Phase 3: Multi-Brand Example Fixtures (parallel-safe)
**Rationale:** Depends only on the already-shipped v2.11 theme contract, not on presets — can be authored in parallel with Phase 2.
**Delivers:** 1-2 additional brand fixture directories per domain under `priv/examples/<domain>/`, each a data tuple (never a module), preserving the brands-as-data boundary.
**Addresses:** the brand-variety input the catalog needs.

### Phase 4: Public Catalog + Quality Ratchet
**Rationale:** Requires Phases 1-3 all existing (presets + fonts to theme the grid, multi-brand fixtures to populate it, polish fixes so the first generated grid is already correct).
**Delivers:** New sibling `Rendro.Catalog` module + `mix rendro.catalog.gen` task + `assets/rendro/catalog.json`/`assets/rendro/catalog/` tree (never growing `@gallery_specs` in place); an explicit, tested combinatorial row-count budget; rubric-ratchet schema extended additively (`brand`/`preset`/`mode` fields on `rubric_scores.json`); a flagship-subset human-scored pass, not full-grid coverage.
**Addresses:** CATALOG-01 from FEATURES.md.
**Avoids:** Pitfalls 6, 7, 8, 13, 14 — combinatorial explosion, rubber-stamped re-blessing, ratchet dishonesty, quality-guarantee overclaim, accessibility-implication overclaim.

### Phase 5: Static Configurator + `mix rendro.gen.theme` + Livebook
**Rationale:** Strictly depends on Phase 4's catalog PNG tree/index as its data source ("nearest pre-rendered preview" has nothing to snap to without a populated catalog). The codegen task technically only depends on Phase 2 but is bundled here to demonstrate the generated-module pattern against real catalog tiles and to share the snippet-template source with the configurator's copy button in one coherent phase.
**Delivers:** `assets/rendro/configurator/` static HTML/CSS/vanilla-JS (zero Node/npm/build step), closed curated accent palette, URL-query state, one-click copy sharing a canonical snippet-format with `mix rendro.gen.theme`; `lib/mix/tasks/rendro/gen/theme.ex` with `--check` drift gate; extended `guides/livebook/first_invoice.livemd` as the third tinkerer surface.
**Addresses:** CONFIG-01 from FEATURES.md.
**Avoids:** Pitfalls 9, 10, 11, 12 — accidental Node/build-step creep, URL-state XSS, snippet/codegen drift producing invalid Elixir, preview/render drift.

### Phase 6: Docs/Manifest Closure
**Rationale:** Final pass once all functional surfaces exist, to close the loop on the project's no-overclaim discipline and guardrails lockstep.
**Delivers:** `priv/support_matrix.json` new `theming.presets` row; `guides/presets.md` (or extended `guides/theming.md`); README/HexDocs wiring; docs-contract lane extensions for catalog/configurator claim-language (bumping the guardrails lockstep triple — lane count, contract test, `required_status_checks.json` — together); final `mix rendro.api.gen` regeneration for `Theme.preset/2`.
**Addresses:** the overclaim/accessibility-implication closure all four researchers flagged as easy to silently skip on a net-new public surface.

### Phase Ordering Rationale

- Determinism and licensing risks are front-loaded (Phases 1-2) because they compound: a font-subsetting or float-math bug discovered at catalog scale means re-generating dozens of hash-checked artifacts, not one.
- Catalog before configurator is a hard dependency, not a preference — the configurator's entire value proposition (nearest pre-rendered preview) requires the catalog to exist first.
- The architecture pattern of "new sibling module/manifest, never grow the existing one in place" repeats at both the presets layer (`presets.ex` separate from `theme.ex`) and the catalog layer (`Rendro.Catalog`/`catalog.json` separate from `Rendro.LaunchArtifacts`/`artifacts.json`) — this is the single structural theme across all four research files and should be treated as a locked constraint, not a suggestion, during phase planning.
- Docs/overclaim closure is deliberately last so it can honestly describe what was actually built (actual rubric coverage, actual preset scope) rather than being written speculatively before the surfaces exist.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (Catalog + Ratchet):** the combinatorial-budget number itself (how many curated brand x preset pairs per domain) is a design decision, not fully resolved by research — needs explicit sizing during phase planning, informed by CI time/tarball budget.
- **Phase 5 (Configurator):** the exact shape of the closed accent palette (how many swatches, which values) and the shared snippet-template mechanism (how the JS and Elixir codegen consume one canonical format) need concrete design during planning, not just the architectural direction research already established.

Phases with standard patterns (skip deep research-phase):
- **Phase 1 (Carryover Polish):** these are named, already-diagnosed bugs from prior milestones (WINDOWS ids 1-3) — fix-scoped, not exploratory.
- **Phase 2 (Presets + Fonts):** the composition pattern (`resolve/1`/`dark/1` reuse, `FontRegistry` registration) is fully proven by existing `from_brand/2` and `Rendro.Branded` precedent.
- **Phase 6 (Docs Closure):** direct extension of existing, well-understood docs-contract lane patterns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Font licenses verified against official upstream license files/repos; every codegen/asset-pipeline claim verified by reading this repo's actual shipped code (`mix.exs`, `lib/mix/tasks/brand.gen.ex`, `lib/rendro/launch_artifacts.ex`), not inferred from ecosystem norms |
| Features | HIGH | Token contract, gallery/artifacts schema, font registry, rubric schema, and codegen precedent all read directly from shipped `lib/`/`priv/` code; genre-typography quantitative mapping is original synthesis against the shipped token contract (explicitly labeled as such, not sourced externally) |
| Architecture | HIGH | Every claim grounded in files actually read in this repo (`theme.ex`, `font_registry.ex`, `launch_artifacts.ex`, recipe modules, `brand.gen.ex`, `rubric_scores.json`, contract tests, `mix.exs`), not general Elixir/Phoenix ecosystem knowledge |
| Pitfalls | HIGH | Font-licensing mechanics, determinism-preservation patterns, catalog-scaling risk, and overclaim tripwires grounded directly in this codebase's existing source, tests, and locked v2.11 decisions; general OFL/XSS knowledge cross-checked against this repo's own existing font-vendoring precedent |

**Overall confidence:** HIGH

### Gaps to Address

- Exact combinatorial budget for the catalog grid — research establishes the principle (curated subset, explicit ceiling, never full cross product) but not the specific number; must be locked during Phase 4 planning against actual CI/tarball constraints.
- Packaging location for vendored fonts — `priv/fonts/` (new top-level dir, matches the seed's own breadcrumb) vs. `priv/branded/fonts/` (existing Hex-allowlisted convention) — STACK.md explicitly flags this as "worth a deliberate decision at plan time, not a default."
- Exact flagship-subset scoring scope for the rubric ratchet — research establishes "not 100%, score a flagship subset" but the precise subset definition (which preset x domain combos) needs to be locked during Phase 4 planning, matching human-reviewer capacity.
- Closed accent palette values — which specific accent colors populate the configurator's curated swatch set is a design decision deferred to Phase 5 planning, not resolved by research.

## Sources

### Primary (HIGH confidence)
- `lib/rendro/theme.ex`, `lib/rendro/font_registry.ex`, `lib/rendro/pdf/font_subsetter.ex`, `lib/rendro/launch_artifacts.ex`, `lib/rendro/branded.ex`, `lib/rendro/recipes/invoice.ex`, `lib/rendro/recipes/branded_invoice.ex` — read directly, this repo
- `lib/mix/tasks/brand.gen.ex`, `lib/mix/tasks/rendro/launch_artifacts/gen.ex` — codegen/task pattern precedent, this repo
- `mix.exs`, `NOTICE`, `priv/quality/rubric_scores.json`, `priv/schemas/rubric_scores.schema.json`, `priv/public_api.json`, `priv/support_matrix.json`, `assets/rendro/artifacts.json` — packaging/manifest ground truth, this repo
- `test/docs_contract/theme_industry_guard_test.exs`, `test/docs_contract/rubric_manifest_contract_test.exs`, `test/guardrails/required_checks_contract_test.exs` — locked tripwires, this repo
- `.planning/PROJECT.md`, `.planning/seeds/SEED-004-style-genre-presets-public-catalog.md`, `.planning/seeds/SEED-003-document-theming-token-system.md` — milestone scope and locked design
- adobe-fonts/source-sans LICENSE.md, adobe-fonts/source-serif LICENSE.md, JetBrains/JetBrainsMono — official upstream license repos

### Secondary (MEDIUM-HIGH confidence)
- Font Squirrel Inter license page — SIL OFL 1.1 confirmation via aggregator, consistent with known OFL terms
- File-size figures for vendored fonts (WebSearch aggregator, approximate — verify exact bytes for the release actually vendored)

### Tertiary (design-history / UX-pattern context, not code facts)
- International Typographic Style, Swiss Style (design), Humanist Typography Guide, Editorial Design Grid Systems, What is Brutalism — qualitative genre-identity grounding, quantitative mapping is original synthesis
- tweakcn, shadcn/ui theme picker, Shadcn Theme Generator — 2026 static-configurator UX pattern cross-check

---
*Research completed: 2026-07-28*
*Ready for roadmap: yes*

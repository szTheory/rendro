# Feature Research

**Domain:** Style-genre presets, public example catalog & static configurator for a deterministic PDF library (`Rendro.Theme`)
**Researched:** 2026-07-28
**Confidence:** HIGH (token contract, gallery/artifacts schema, font registry, rubric schema, and codegen precedent all read directly from shipped `lib/`/`priv/` code; genre-typography conventions cross-checked against current design-history sources; configurator UX cross-checked against current shadcn/ui-ecosystem theme-generator practice)

## Grounding: what already exists (do not re-research, but every token below is keyed to it)

`lib/rendro/theme.ex` (`SEED-003`, shipped v2.11) defines the **exact** mutable surface a preset can set — this is the only vocabulary presets are allowed to speak:

| Group | Fields | Default values (the "Swiss-ish serious default" baseline every preset is a deviation from) |
|---|---|---|
| `colors` | `ink, muted, accent, on_accent, background, surface, rule, positive, negative` (all `{r,g,b}`) | `ink {16,24,39}`, `muted {91,101,115}`, `accent {44,107,237}`, `on_accent {255,255,255}`, `background {255,255,255}`, `surface {247,243,234}`, `rule {196,188,169}`, `positive {20,122,75}`, `negative {194,65,50}` |
| `typography.fonts` | `heading, body, mono` (logical `FontRegistry` atoms) | all `:default` (built-in Helvetica-compatible) |
| `typography.scale` | `display, title, subtitle, body, small, caption` (pt, materialized not formula) | `21 / 16.5 / 13 / 10.5 / 9 / 8` — display:body ≈ **2.0:1** |
| `typography.leading/widows/orphans` | | `1.35 / 2 / 2` |
| `spacing` | `unit, tight, normal, loose, section` (pt) | `6 / 4 / 8 / 12 / 24` |
| `rules` | `hairline, thin, thick` (stroke pt) | `0.5 / 1 / 2` |
| `radius` | `none, sm, md` (pt) | `0 / 2 / 4` |
| `density` | `:comfortable \| :compact` | `:comfortable` (compact = shallow `leading → 1.1` nudge, no other field changes today) |
| `mode` | `:light \| :dark` | dark swaps `ink/muted/background/surface/rule/positive/negative`; `accent`/`on_accent` never change |

A preset is therefore literally: **a named partial map into this exact shape**, fed through the existing `Theme.resolve/1` deep-merge (accent/on_accent/mode still supplied by the caller at call time — `Theme.preset(:editorial, accent:, mode:)`). No new fields, no new merge machinery. `radius`/`rules`/`spacing` currently ship as flat 3-key scales — a preset **cannot** introduce a 4th rule weight or a modular-scale formula without widening the public struct (out of scope this milestone).

`FontRegistry` (`lib/rendro/font_registry.ex`, `:stable` tier) already raises `{:unknown_logical_font, name}` for anything not registered — this is the exact mechanism `SEED-004`'s "no silent substitution" requirement rides on for free; presets just need their 4 curated fonts registered under logical names before being referenced.

`Rendro.LaunchArtifacts` (`lib/rendro/launch_artifacts.ex`) already carries **reserved, currently-`null`** `theme`/`mode`/`preset` tags on every gallery-spec entry and in `artifacts.json` (`@gallery_optional_s6_keys`, D-13/D-03 from Phase 123) — this milestone is what **populates** `preset`, not what invents the key. The catalog is a direct, additive extension of the existing 11-row `@gallery_specs` mechanism, not a parallel system.

`priv/quality/rubric_scores.json` already has an appendable `scores: []` array keyed by `demo_id/domain/family/dimension_scores`, plus a precedent (`stress_exemption`) for a schema-`required`, fail-loud exemption block — this is the exact seam the "ratchet" extends.

`mix brand.gen` (`lib/mix/tasks/brand.gen.ex`) is the proven codegen template `mix rendro.gen.theme` should clone: read a source-of-truth → write generated file(s) → `--check` flag re-derives and byte-compares against committed output, `Mix.raise`s on drift.

---

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---|---|---|---|
| `Theme.preset/2` returns a full `%Theme{}` | SEED-004 API is locked (`Theme.preset(:editorial, accent:, mode:)`); anything less breaks the promised ergonomics | LOW | Pure function: named partial map → `Theme.resolve/1`; reuses existing merge/validate path entirely |
| 5 presets ship at minimum (Swiss, Humanist, Editorial, Corporate-Classic, Minimal-Mono) | Named explicitly as the "locked starter set" in `SEED-004`; fewer feels like a stub | MEDIUM | Each is ~15-20 lines of literal token maps; the design labor (getting values right, not code volume) is the real cost |
| Presets compose uniformly with light/dark | `Theme.dark/1` already swaps roles generically; a preset that breaks under `dark/1` is a regression, not a new feature | LOW | Because presets only set colors/typography/spacing/rules/radius/density (never bypass `dark/1`'s role-swap), this should fall out "for free" — the real risk is *legibility*, not *plumbing* (see Carryover Polish below) |
| Unregistered font role raises the existing typed error | `SEED-004`: "no silent substitution" | LOW (already exists) | `FontRegistry` raises `{:unknown_logical_font, _}` today; presets just need to reference logical names that flagship demos register |
| 4 curated open-license fonts in `priv/fonts/` (grotesque, humanist sans, text serif, mono) | Presets are meaningless without real font files to back the flagship look | MEDIUM | License vetting (OFL-family) + embedding correctness (regular/bold/italic/bold_italic variants per `embedded_variant` type) is the real cost, not the registration call |
| Catalog covers every existing family × 2-3 brands × light/dark + unbranded default | `SEED-004`'s explicit catalog shape | MEDIUM-HIGH | 7 families × (1 unbranded + 2-3 branded × 2 modes) ≈ **35-50 hash-checked artifacts**, ~3-4x the current 11-row gallery — a real generation/CI-time and storage cost, not just a data-modeling one |
| Catalog artifacts are deterministic, hash-checked | Matches every existing launch-artifact guarantee (`png_sha256`, `source_pdf_sha256`) | LOW | Pure extension of `@gallery_specs`/`build_gallery_entries/1` — same mechanism, more rows |
| Catalog organized by domain (not a flat list) | `SEED-004`: "organized by-domain, brand-tagged" | LOW | Mirrors the existing `priv/examples/<domain>/` directory convention already used for fixtures |
| Configurator: preset picker + accent input + light/dark toggle | Minimum viable "pick a look" UI | LOW-MEDIUM | Pure client-side (HTML/CSS/vanilla JS or a tiny framework) against the pre-rendered catalog — no build step requiring a server |
| Configurator: nearest pre-rendered preview snap | Static-only constraint (no server render) means an arbitrary accent must snap to a *rendered* preview, not synthesize a new one live | MEDIUM | The honest UX move: show "closest available preview" plus the exact snippet with the user's *actual* chosen accent (code is always exact; the picture is nearest-match) |
| Configurator: one-click copy of `Theme.preset(...)` snippet | The whole point of "browse → pick → copy code" | LOW | Snippet is a template string; no codegen infrastructure needed for this alone |
| Configurator state lives in the URL query string | `SEED-004`: "shareable... no server compute, no DB" | LOW | Standard `URLSearchParams` read/write; page load restores selection deterministically |
| `mix rendro.gen.theme <preset> --accent "#…"` codegen task with `--check` | `SEED-004` names this explicitly, modeled on `mix brand.gen` | LOW-MEDIUM | Direct clone of the proven `brand.gen` shape: opts → write `lib/my_app/..._theme.ex` → `--check` drift gate; the pattern is already battle-tested in this repo |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---|---|---|---|
| Quality ratchet across the full catalog grid | Turns "we have examples" into "we have a standing, re-scoreable design bar that never silently regresses" — most doc-generation libraries show one static screenshot per feature, not a scored grid | MEDIUM | Extends `rubric_scores.json.scores[]`; the differentiator is the *discipline* (every new/changed catalog cell gets scored, thresholds enforced), not new schema |
| Brutalist preset (ship-if-time) | Signals design range beyond "generic corporate PDF library"; distinctive in a category where everything looks like a spreadsheet export | MEDIUM | Genuinely harder to get right at business-document legibility bounds — `radius: none`, `rules.thick` everywhere, and the *largest* display:body contrast ratio in the set (~3.3:1) without becoming illegible; correctly scoped as optional |
| Three-tinkerer-surface parity (catalog+configurator, Livebook, `mix rendro.gen.theme`) | Meets users wherever they already are (browser-only, notebook, or terminal/codegen) with the *same* preset vocabulary | LOW-MEDIUM | Livebook extension is additive; no new concepts, just a third entry point into `Theme.preset/2` |
| Transparent "nearest accent" disclosure in the configurator | Most static config generators silently substitute; being explicit about *which* rendered preview you're looking at vs. the exact code you're copying preserves the honesty-in-claims posture this project has held since v2.3 (`explicit_deferral` precedent) | LOW | A one-line UI label; consistent with the project's established "proof-backed, no overclaim" culture — not just nice UX, it's on-brand |
| Deep-linkable per-cell catalog/configurator URLs | Lets a user share "this exact preset+accent+mode+family" combo, useful for design review / support / docs | LOW | Falls out of the URL-query-state requirement almost for free |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---|---|---|---|
| WYSIWYG token editor (drag sliders for every color/spacing/radius value) | "Let me tweak everything visually" feels like the natural evolution of a configurator | Explodes surface area into a live-render problem (arbitrary token combos need arbitrary rendering) that only the deferred `SEED-005` live Studio is scoped to solve; also invites incoherent, off-brand combinations the preset system exists specifically to prevent | Configurator exposes only preset + accent + mode — full token control already exists programmatically via `Theme.resolve/1` for power users |
| Hosted/server-rendered live preview (type any hex, get a live-rendered PDF back) | Feels more "real" than a nearest-match snap | Requires a render server, breaks the "no server compute, no DB" constraint, and is explicitly `SEED-005`'s job, not this milestone's | Static nearest-pre-rendered-preview + exact-code copy, as locked in `SEED-004` |
| Saved themes / accounts / theme marketplace | "Let me save my custom combos" | Requires a database and auth — directly contradicts the static, zero-backend design; also a scope explosion for a library, not a hosted product | URL query string *is* the save mechanism (shareable, bookmarkable, no account) |
| A 5th+ rule weight, modular-scale formula, or per-preset new struct fields | "Editorial needs its own special scale math" | Widens the public `%Theme{}` struct — SEED-003 explicitly locked the field *shape* as a stable contract; widening it here is a breaking-adjacent move outside this milestone's charter | Every preset expresses itself only through the 6 existing groups' existing keys; genre distinctiveness comes from *chosen values*, not new fields |
| Per-brand custom fonts baked into the public catalog as committed binaries beyond the 4 curated ones | "Show a realistic third-party brand font too" | Balloons the Hex/git tarball with licensed or non-open fonts, and risks the exact `priv/fonts` licensing/packaging traps `SEED-002`/`v2.6` were careful to avoid elsewhere | Catalog brand rows vary accent + preset + logo only; fonts stay confined to the 4 curated open-license files, consistent with "a brand is never a module / brands are data" |
| Auto-scoring the rubric (an LLM or heuristic assigns `dimension_scores`) | Scoring 35-50 cells by hand is a lot of manual review | Rubric anchors are explicitly non-designer, human-judgment prose (`priv/quality/rubric_scores.json` dimension anchors) — the project's whole quality culture rests on human sign-off (see v2.11 Phase 118 SHOW-01 closure "with human sign-off"); automating it would quietly erode the one honest signal in the pipeline | Ratchet mechanics can flag *which* cells are unscored/stale and enforce thresholds on scored cells, but the act of scoring itself stays human |

---

## Per-Genre Token Intent Matrix (concrete values, not adjectives)

Every row is a delta against the `default()` baseline above. `font role` names are the curated `priv/fonts/` logical atoms this milestone introduces (`grotesque`, `humanist_sans`, `text_serif`, `mono`); `:default` means "leave the built-in Helvetica-compatible font" (only Swiss needs no new font at all, since it's already the default's basis).

| Genre | Fonts (heading / body / mono) | Scale intent (display→caption, pt) & display:body ratio | Leading | Rules | Radius | Spacing rhythm / density | Color-role usage |
|---|---|---|---|---|---|---|---|
| **Swiss / International** (= `default()` basis, "the serious default") | `grotesque / grotesque / mono` — one neutral grotesque family end-to-end | `21 / 16.5 / 13 / 10.5 / 9 / 8` — **≈2.0:1**, near-linear steps (no exponential jumps) | **1.3** (tight; lower bound of the 1.3–1.45 Swiss print-prose band) | **`hairline` (0.5) dominant**, `thin`/`thick` rarely invoked — the tight-grid feel comes from rule *restraint*, not weight | `none`/`sm` only (0–2) — square, grid-honest corners | `unit 6`, `tight 4`, `normal 8` — **no `loose`/`section` air**; density `:comfortable` default, `:compact` variant offered | High figure/ground contrast: near-black `ink` vs pure-white `background`; single `accent`, `rule` = light neutral gray; minimal `surface` tint use |
| **Humanist** | `humanist_sans / humanist_sans / mono` — one warm sans family | Same 6 steps as Swiss but `body` nudged to **11** — flatter, roomier feel at reading size | **1.45–1.5** (loose; above the Swiss band's upper bound) | Favor **spacing over rules** — `hairline` used sparingly; sections separated by `spacing.loose`/`section` rather than drawn lines | `sm`/`md` (2–4) — visibly rounded surfaces/boxes | `normal 10`, `loose 16`, `section 28` — roomier than Swiss at every step; density always `:comfortable` | Warmer `surface` tint leaned into (cream/off-white, not neutral gray); `muted` skews warm-gray not cool-gray; `accent` fills are used more generously than Swiss (less austere) |
| **Editorial** | `text_serif / grotesque (or humanist_sans)` — the signature serif-heading/sans-body pairing; `mono` untouched | `28-32 / 18 / 13 / 10 / 8.5 / 7.5` — **≈2.8-3.0:1**, the steepest jump between `display` and everything below it (magazine-headline effect) | **1.4-1.45** — generous prose leading (reports/statements read like long-form copy) | `hairline` only, strictly **functional** (table/column dividers) — zero decorative rule use, reinforcing restraint under a bold headline | `none`/`sm` — sharp corners read as more "print magazine," less "SaaS card" | Big `section` gaps (`loose 14`, `section 32`) around large headline blocks, but tight leading *within* body columns | `ink` near-black for serif legibility; `muted` role carries captions/bylines; `accent` used sparingly (pull-quote rule or byline only) — restraint is the point, not the palette size |
| **Corporate-Classic** | `text_serif / text_serif / mono` (mono reserved for tabular money columns) — one conservative serif family top-to-bottom | `18 / 14 / 12 / 10 / 9 / 8` — **≈1.8:1**, the *narrowest* contrast in the set ("nothing shouts") | **1.3** (tight, dense financial-table appropriate) | **`thick` (2pt+) deliberately reserved for boxed/ruled totals rows**; `hairline` for regular table rows — the literal mechanism behind "boxed/ruled totals" | **`none` (0)** — square, formal, boxed-statement look | `unit 6`, modest `normal 8`, but generous `section` breaks between statement blocks | Restrained navy-family `accent` + cool `muted` gray; `rule` kept dark enough to read as a real box border (not a hairline suggestion); `positive`/`negative` pulled toward dark green/dark red rather than bright — finance/insurance/legal register |
| **Minimal-Mono** | `mono / grotesque (or humanist_sans) / mono` — mono doubles as **label** font (tracked-caps small/caption steps) *and* the numeric-column font (tabular figures) | `16 / 13 / 11 / 9.5 / 8.5 / 8` — **≈1.8:1** ratio but the *smallest absolute sizes* in the set — "ultra-restrained" reads as compact, not just low-contrast | **1.25** (tight, technical/dev-tool register) | `hairline` only, used sparingly — deliberately few visual elements besides mono labels + whitespace | **`none` (0)** — square, technical | `unit 4` (tighter base than Swiss), `tight 3`, `normal 6`, `loose 10`, `section 20` — the *densest* rhythm in the set; density defaults to `:compact` | Near-monochrome: `ink`/`muted`/`background` do almost all the work; `accent` confined to mono-label color or a single header-row underline; fewest distinct colors deployed of any preset — restraint measured in color-role *count*, not just weight |
| **Brutalist** *(ship-if-time)* | `grotesque / grotesque / mono` | `32-36 / 20 / 13 / 10 / 9 / 8` — **≈3.3:1+**, the **steepest** contrast of the whole set — blocky oversized headline vs. workmanlike body (no numeric weight axis exists per the token contract, so "heavy" is achieved through size + rule weight, never bold-weight text) | **1.2** (tight; body reads dense against huge headlines) | **`thick` (2pt+) as the dominant motif** — used everywhere other presets reserve for emphasis-only (table borders, section frames, header rules) | **`none` (0)**, explicitly — locked in `SEED-004`'s own language | Default `unit/loose/section` values are fine as-is; the "blocky" feel comes from `rules.thick` framing every section, not from spacing changes | Maximum `ink`/`background` contrast; `rule` pulled *dark* (near-ink strength, not a soft gray) so it reads as loud, not quiet; `surface` used as a bold flat block rather than a subtle tint |

**Design note on the scale-contrast dimension:** ratios above are display:body point ratios computed from each row's own numbers — they are the single most legible way to see genre difference at a glance (Corporate-Classic 1.8:1 low-drama through Brutalist 3.3:1+ maximum-drama), and every value stays within the existing `type_step :: number()` contract (no formula, no runtime computation — materialized literals per `@default_typography`'s own documented discipline).

**Sources for genre conventions:** [International Typographic Style — Wikipedia](https://en.wikipedia.org/wiki/International_Typographic_Style), [Swiss Style (design) — Wikipedia](https://en.wikipedia.org/wiki/Swiss_Style_(design)), [Humanist Typography Guide — Number Analytics](https://www.numberanalytics.com/blog/ultimate-guide-to-humanist-typography), [Editorial Design Grid Systems — Fiveable](https://fiveable.me/advanced-editorial-design/unit-2/grid-systems-structure/study-guide/FQeFisxPQIbPGPye), [What is Brutalism — Ciderhouse Media](https://ciderhouse.media/brutalism-a-guide-to-architecture-web-design/). These establish the *qualitative* genre identities (grotesque/hairline/grid for Swiss; warm/organic/loose for Humanist; serif-heading contrast for Editorial; oversized/clashing/rebellious for Brutalist); the *quantitative* pt/ratio/weight mapping onto `%Rendro.Theme{}` fields above is original synthesis against the shipped token contract, not sourced externally (no such mapping exists anywhere else — it is this milestone's actual design work).

---

## Catalog Organization & Quality-Ratchet Mechanics

### Organization

- **Primary axis: domain (family).** Mirrors the existing `priv/examples/<domain>/` convention. 7 families today: `invoice, branded_invoice, statement, receipt_report, certificate, payslip, ticket`.
- **Secondary axis: brand.** 2-3 example brands per family, each a **data** tuple of `{preset, accent, logo}` living under `priv/examples/<domain>/` (never a module — the `SEED-003`/`SEED-004` "design systems = code, brands = data" boundary holds exactly here).
- **Tertiary axis: mode.** `light` + `dark` per brand row.
- **Plus:** exactly 1 unbranded-default row per family (`Theme.default()`, no preset/brand) — this is the row the rubric already gates hardest (v2.11 Phase 118's SHOW-01 closure precedent).
- **Volume:** 7 families × (1 unbranded + up to 3 brands × 2 modes) = up to **~50 catalog cells**, versus today's 11-row gallery. This is a 4-5x artifact-generation and CI-time cost, not just a data-modeling change — budget for it explicitly (raster + hash-check time scales linearly with cell count).
- **Mechanism:** extend `Rendro.LaunchArtifacts`'s existing `@gallery_specs` → `build_gallery_entries/1` pipeline (or a parallel `@catalog_specs` list feeding the same `artifacts.json` schema) rather than inventing new generation machinery. The `theme`/`mode`/`preset` keys are **already reserved and schema-present** (`@gallery_optional_s6_keys`, currently always `null`) — this milestone is precisely what starts writing real values into `preset`.
- **Public presentation:** group by domain (7 sections), brand/preset selectable as tabs/chips within each domain section — avoids a 50-tile undifferentiated wall.

### Quality-ratchet mechanics

- **Extension point:** `priv/quality/rubric_scores.json`'s existing appendable `scores: []` array (`demo_id, domain, family, dimension_scores`) is the ratchet's storage — no new schema needed, only more rows.
- **What "ratchet" means concretely:** every catalog cell that exists gets a scored entry; the existing `thresholds` block (`hierarchy_min: 5`, `core_min: 4`) already defines pass bars — a ratchet check fails when *any scored cell* is below threshold, and flags any catalog cell that has **no** corresponding `scores[]` entry (new/changed cells can't silently ship unscored).
- **Precedent to reuse, don't reinvent:** `stress_exemption` is the existing model for a schema-`required`, fail-loud carve-out block with a `gate_scope`. A parallel `catalog_coverage` (or similar) block, machine-checked the same way `stress_exemption` is guarded by "4 fail-loud D-15 contract guards including a non-vacuous disjointness+teeth guard" in Phase 117, is the right shape for "every catalog cell must have a score, and no score may sit below threshold."
- **Human-in-the-loop stays non-negotiable:** dimension anchors are explicitly non-designer prose read by a human (v2.11's "DATA-first order with human sign-off" precedent) — the ratchet enforces *coverage and thresholds*, never generates the judgment itself (see Anti-Features: auto-scoring is explicitly excluded).
- **Growth-over-time framing:** because `scores[]` is append/update-able, "ratchet" literally means re-running the rubric over time as presets are tuned — a later milestone changing Editorial's leading, say, should re-trigger scoring on every Editorial catalog cell, and the mechanism should make that obligation visible (stale-score detection), not just possible.

---

## Static Configurator UX (browse → pick → copy code)

Cross-checked against 2026 practice in the shadcn/ui theme-generator ecosystem (tweakcn, shadcn/ui's own official theme picker, Shadcn Studio) — the dominant pattern for "pick a preset, adjust an accent, copy code" static config tools:

- **Table-stakes UX (see table above)** — preset picker, accent input, light/dark toggle, nearest-preview snap, one-click copy, URL-query state.
- **What the shadcn ecosystem validates as standard, worth matching:**
  - Live-feeling immediacy even though rendering is static — swap the *preview image* instantly on any control change (no page reload), even though the underlying artifact is pre-rendered, not recomputed.
  - Copy button gives explicit success feedback (checkmark/toast), not silent clipboard writes.
  - A visible "reset to default" affordance back to the unbranded `Theme.default()`.
  - Family/recipe switcher alongside preset/accent/mode — letting a user preview *their* document type (invoice vs. statement vs. certificate), not just an abstract swatch.
- **Rendro-specific differentiator over the shadcn pattern:** those tools output raw CSS custom properties users paste; Rendro's copy target is a **typed Elixir call** (`Rendro.Theme.preset(:editorial, accent: {12, 74, 110}, mode: :dark)`) plus a recipe-usage snippet — closer to a "code generator" than a "CSS variable dump," which is why the `mix rendro.gen.theme` materialized-module path matters as a *second* tier for users who want a committed file rather than an inline literal.
- **Anti-features confirmed by ecosystem contrast, not just this project's own constraints:** none of the surveyed shadcn tools require login/save-to-account for the base "generate + copy" flow — validates that Rendro's zero-DB, zero-auth static approach is not a compromise but the *proven* right shape for this exact interaction, not just an internal Hex-package constraint dressed up as a feature.

Sources: [tweakcn — Theme Editor & Generator for shadcn/ui](https://tweakcn.com/), [Official shadcn/ui theme picker](https://ui.shadcn.com/create), [Shadcn Theme Generator — shadcndesign](https://www.shadcndesign.com/theme-generator).

---

## Feature Dependencies

```
PRESET-02 (curated fonts in priv/fonts/)
    └──requires──> nothing new (FontRegistry.register/3 already exists)

PRESET-01 (Theme.preset/2, 5-6 genre maps)
    └──requires──> PRESET-02 (flagship presets reference the curated font roles;
                    "unregistered font role raises the existing typed error" only
                    matters once presets actually point at logical names)
    └──requires──> Rendro.Theme.resolve/1, dark/1 (SEED-003, already shipped)

Carryover polish (dark table-body legibility, Ticket hierarchy, payslip numeric wrap,
from_brand accent-op golden, typography-test depth)
    └──blocks──> CATALOG-01 dark-mode rows and the rubric ratchet's dark-cell scores
                 (see "Carryover Polish" section below — this is a hard sequencing
                 dependency, not a nice-to-have)

CATALOG-01 (public catalog + ratchet)
    └──requires──> PRESET-01 (catalog brand rows are presets + accent, by definition)
    └──requires──> Carryover polish landing FIRST for any preset × dark cell
    └──enhances──> the existing Milestone-A rubric (extends scores[], doesn't replace it)

CONFIG-01 (static configurator + mix rendro.gen.theme)
    └──requires──> CATALOG-01 (the configurator previews are the catalog's
                    pre-rendered artifacts — "nearest pre-rendered preview" has
                    nothing to snap to without the catalog existing first)
    └──requires──> PRESET-01 (the snippet the configurator copies is Theme.preset/2)
    └──models──> mix brand.gen (existing codegen shape: opts → write file → --check)

Brutalist preset (ship-if-time)
    └──enhances──> PRESET-01, but is explicitly last-priority / droppable without
                    blocking CATALOG-01 or CONFIG-01 for the other 5 genres
```

### Dependency Notes

- **CATALOG-01 requires the carryover polish landing first, not concurrently or after:** every dark-mode catalog cell (up to half of all new artifacts, since every brand row gets a light+dark pair) inherits whatever dark-mode table-body legibility bug exists today (WINDOWS id 1). Generating and rubric-scoring ~20-25 dark cells *before* that fix means either re-generating/re-scoring all of them later (wasted CI/artifact/reviewer time) or shipping a known-bad quality bar into the "standing ratchet" — which defeats the ratchet's entire purpose. Fix once at the shared color-role level (the bug is presumably a role-choice issue in table-body draw code, not per-recipe), then generate.
- **Ticket hierarchy inversion (id 2) is a locked Phase-122 decision, not an open bug** — it needs an explicit call before Ticket appears in the catalog under multiple presets: either (a) fix it now so it doesn't multiply across every Ticket preset row, or (b) keep it locked and make sure the rubric's `stress_exemption`-style mechanism (or a similar named carve-out) explicitly excuses Ticket cells from the `content_hierarchy` dimension so the ratchet doesn't flag a known, accepted deviation as a regression on every re-score. Silently scoring it low without a named reason would corrode the ratchet's honesty.
- **Payslip numeric-cell wrap (id 3) is a direct prerequisite for Minimal-Mono specifically:** that preset's entire identity is "tabular figures" in tight, small (9.5pt body) mono columns — it is the genre most likely to re-trigger or worsen numeric-cell wrap if the underlying issue isn't fixed first. Sequence: fix wrap → build Minimal-Mono payslip rows, not the reverse.
- **from_brand accent-op golden + typography-test depth carryover directly informs preset testing strategy:** `Theme.preset/2` composes over the same `resolve`/`from_brand`-shaped merge path presets will use with dozens of accent values across the catalog. The deferred golden-test depth should be scoped to *cover preset × accent combinations*, not just the original single `from_brand` call site — otherwise the catalog's ~50 cells are the first real stress test of that path, which is backwards (tests should precede volume, not be discovered by it).
- **CONFIG-01 requires CATALOG-01, not the other way around:** the configurator's core promise ("nearest pre-rendered preview") is meaningless without a populated catalog to snap to. Building the configurator UI shell concurrently with catalog generation is fine; wiring its preview-selection logic before real catalog artifacts exist is not.

---

## MVP Definition

### Launch With (v2.12 / this milestone)

- [ ] `Theme.preset/2` with the 5 locked genres (Swiss, Humanist, Editorial, Corporate-Classic, Minimal-Mono) — the named starter set is the actual deliverable, not a stretch goal
- [ ] 4 curated open-license fonts registered and embedded correctly (regular/bold/italic/bold_italic where the font family provides them)
- [ ] Carryover polish (dark table-body legibility, Ticket hierarchy decision, payslip numeric wrap, from_brand/preset golden depth) landed **before** dark-mode catalog generation
- [ ] Public catalog: 7 families × unbranded default + 2-3 brands × light/dark, hash-checked, `preset`/`theme`/`mode` tags populated in `artifacts.json`
- [ ] Quality ratchet: every catalog cell scored in `rubric_scores.json`, thresholds enforced, a fail-loud coverage guard for unscored/stale cells
- [ ] Static configurator: preset + accent + mode pickers, nearest-preview snap, copy-to-clipboard snippet, URL-query state
- [ ] `mix rendro.gen.theme <preset> --accent` with `--check` drift gate, modeled on `mix brand.gen`
- [ ] Livebook extended as the third tinkerer surface

### Add After Validation (v1.x-equivalent — later in this milestone if time allows)

- [ ] Brutalist preset (`radius: none`, `rules.thick` motif, steepest scale contrast in the set) — explicitly ship-if-time per `SEED-004`

### Future Consideration (deferred to Milestone D / `SEED-005`)

- [ ] Live, server-rendered Studio (arbitrary token values, live render, not just nearest-match)
- [ ] Any hosted/DB-backed saved-theme or account surface
- [ ] Full WYSIWYG token editing beyond preset + accent + mode

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---|---|---|---|
| `Theme.preset/2` (5 genres) | HIGH | MEDIUM | P1 |
| Curated fonts (`priv/fonts/`) | HIGH (blocks presets rendering as intended) | MEDIUM | P1 |
| Carryover dark/hierarchy/wrap polish | HIGH (blocks trustworthy catalog dark cells) | LOW-MEDIUM | P1 |
| Public catalog (domain × brand × mode) | HIGH | MEDIUM-HIGH (volume, not novelty) | P1 |
| Quality ratchet mechanics | HIGH (the standing quality guarantee) | LOW-MEDIUM (schema extension only) | P1 |
| Static configurator core (preset/accent/mode/copy/URL-state) | HIGH | MEDIUM | P1 |
| `mix rendro.gen.theme --check` | MEDIUM-HIGH | LOW (proven template exists) | P1 |
| Livebook third surface | MEDIUM | LOW | P2 |
| Brutalist preset | MEDIUM (distinctiveness) | MEDIUM-HIGH (hardest to keep legible) | P2 |
| Deep-linkable per-cell URLs | LOW-MEDIUM | LOW (falls out of URL-state) | P2 |

**Priority key:**
- P1: Must have — named explicitly in the locked `SEED-004` design or is a hard dependency of something that is
- P2: Should have if time allows within this milestone

## Sources

- `lib/rendro/theme.ex`, `lib/rendro/font_registry.ex`, `lib/rendro/launch_artifacts.ex`, `lib/mix/tasks/brand.gen.ex`, `lib/mix/tasks/rendro/launch_artifacts/gen.ex`, `assets/rendro/artifacts.json`, `priv/quality/rubric_scores.json` — read directly from the Rendro repository (ground truth for every concrete token value, schema field, and codegen pattern above).
- `.planning/PROJECT.md`, `.planning/seeds/SEED-004-style-genre-presets-public-catalog.md`, `.planning/seeds/SEED-003-document-theming-token-system.md` — milestone scope and locked design.
- [International Typographic Style — Wikipedia](https://en.wikipedia.org/wiki/International_Typographic_Style)
- [Swiss Style (design) — Wikipedia](https://en.wikipedia.org/wiki/Swiss_Style_(design))
- [The Ultimate Guide to Humanist Typography — Number Analytics](https://www.numberanalytics.com/blog/ultimate-guide-to-humanist-typography)
- [Grid Systems and Structure — Advanced Editorial Design, Fiveable](https://fiveable.me/advanced-editorial-design/unit-2/grid-systems-structure/study-guide/FQeFisxPQIbPGPye)
- [What is Brutalism? A Guide to Brutalist Design — Ciderhouse Media](https://ciderhouse.media/brutalism-a-guide-to-architecture-web-design/)
- [tweakcn — Theme Editor & Generator for shadcn/ui](https://tweakcn.com/)
- [Official shadcn/ui theme picker](https://ui.shadcn.com/create)
- [Shadcn Theme Generator — shadcndesign](https://www.shadcndesign.com/theme-generator)

---
*Feature research for: Rendro v2.12 (Style-Genre Presets, Public Catalog & Static Configurator)*
*Researched: 2026-07-28*

# Feature Research — Document Theming & Design-Token Contract (`Rendro.Theme`)

**Domain:** Deterministic PDF theming / design-token system for a pure-Elixir document engine (NOT a browser)
**Milestone:** B — v2.11 `SEED-003` "Document Theming & Design-Token System"
**Researched:** 2026-07-19
**Confidence:** HIGH (design-token prior art is stable and cross-confirmed; PDF-mapping is grounded in the engine's own primitives per SEED-003 breadcrumbs)

---

## How to read this file

The downstream consumer is **requirements definition for v2.11**. Features are organized as six **categories**, and within each category every token concept is classified **Table stakes / Differentiator / Anti-feature** with a complexity rating and its dependency on an existing Rendro surface. A consolidated **permanently-excluded** list and a **Milestone-C/D out-of-scope** list follow, kept strictly separate (excluded = never maps to deterministic PDF; out-of-scope = maps fine but belongs to a later milestone).

**Core translation thesis (grounded in prior art):** every mature token system (W3C DTCG, Tailwind, Radix, Material 3, Spectrum, Style Dictionary) layers a small **semantic** vocabulary on top of raw values. Radix makes "the same step number means the same UI role across every palette"; Tailwind teams "add a semantic design-tokens layer on top of base tokens"; Material 3 color *roles* are "the connective tissue between UI elements and what color goes where." **Rendro should ship ONLY the semantic layer** — roles, named type steps, and a handful of scalar tokens — and deliberately NOT ship the raw-scale generators, wide-gamut color spaces, or interaction/motion tokens that a browser design system carries. That single decision is what keeps the contract industry-agnostic, deterministic, and small enough to freeze as public API.

---

## Category 1 — Color roles

**Concept in prior art:** Design systems separate a *raw palette* (Radix's 12 steps 1→12; Tailwind's `gray-300`, `indigo-500`) from *semantic roles* that name intent (Material's `primary` / `on-primary` / `surface` / `on-surface`). Roles are what components reference; raw scales are an implementation detail behind them. Radix bakes UI intent into step numbers (bg 1–2, borders 6–8, text 11–12); Material assigns tones to named roles; the DTCG format ships a `color` primitive type but leaves semantics to the consumer.

**Rendro translation:** a document needs far fewer roles than an interactive UI (no hover/pressed/focus states, no interactive-component fills). The locked 7 + 2 covers every mark a business document draws.

| Feature | Classification | Complexity | Maps to / depends on |
|---------|----------------|------------|----------------------|
| **7 core semantic roles** `ink`, `muted`, `accent`, `on_accent`, `background`, `surface`, `rule` as `{r,g,b}` | **Table stakes** | MEDIUM | `lib/rendro/color.ex` `{r,g,b}` contract; consumed by every recipe's private `palette(opts)` seam (S1, shipped v2.10) |
| **`on_accent` "on-color" convention** (foreground guaranteed legible on the accent fill) | **Table stakes** | LOW | Mirrors Material's `on-*` roles; prevents the "brand-blue text on brand-blue band" failure |
| **Optional `positive` / `negative` status roles** (credits/debits, paid/overdue) | **Differentiator** | LOW | Business-doc-specific; industry-agnostic (family-not-industry: a *balance sign*, not a "finance" color). Default to `ink` when unset so recipes never hard-require them |
| **Single `accent:` seed** — one color in, cohesive theme out | **Differentiator** | LOW | `Rendro.Theme.from_brand/2` + `accent:` opt; derives `on_accent` by contrast pick; the "plug in my palette in one line" ergonomic |
| Raw N-step color **scales** (Radix-style 1–12, Tailwind `50–950`) | **Anti-feature** | — | A document draws flat fills + hairlines; it never needs 12 interaction tints. Shipping scales bloats the frozen public contract and invites "which step for X?" ambiguity. Roles only. |
| Wide-gamut color spaces (**Display-P3, Oklch, CSS Color 4**) that DTCG 2025.10 now supports | **Anti-feature** | — | Rendro is device `{r,g,b}` / sRGB by construction. Accept hex→tuple at the boundary; do not widen the color model. |

**Naming convention (lock it):** role names are **intent nouns, not values** — `ink` not `black`, `accent` not `blue`, `rule` not `gray-300`. This is exactly why Milestone-A's S1 seam banned inline `{0,0,0}` in sections. Keep names singular, lowercase, snake_case atoms to match Elixir idiom and the existing `%{font_name, logo_name}` brand shape.

**Why 7 (not 3, not 20):** three (`ink`/`accent`/`bg`) can't express a tinted totals panel (`surface`) or a hairline table rule (`rule`) distinct from body text (`ink`) — you'd be forced back to literals. Twenty is Material's interactive-UI count and carries roles (container/inverse/scrim/outline-variant) that a static printed page has no mark for. Seven core + two status is the minimum complete basis for the six shipped families.

---

## Category 2 — Typography scale

**Concept in prior art:** A **modular type scale** is a base size multiplied by a fixed ratio: step *n* = `base × ratio^n`. Common ratios: Major Third **1.25** and Perfect Fourth **1.333** are the most-used; **1.125–1.2** for dense/compact UIs; **1.333+** for dramatic editorial contrast. The DTCG `typography` composite type bundles `fontFamily`, `fontSize`, `fontWeight`, `letterSpacing`, `lineHeight`. Named steps (Material's `display/headline/title/body/label`) give roles instead of raw px.

**Rendro translation — this is the NEWEST surface.** Rendro today has font/size/color/line_height/widows/orphans on `Rendro.Text`, but **NO type scale, NO numeric weight axis, NO letter-spacing, NO native leading token**. The scale is a genuinely new abstraction this milestone introduces.

| Feature | Classification | Complexity | Maps to / depends on |
|---------|----------------|------------|----------------------|
| **Named type scale** `display / title / subtitle / body / small / caption` (6 pt steps) | **Table stakes** | MEDIUM | NEW abstraction; each step is a point size wired into `Rendro.Text` `size`. This is the single feature that produces visual hierarchy → directly the rubric's key-fact-dominance dimension |
| **`fonts` roles** `%{heading, body, mono}` (logical atoms → resolved font resources) | **Table stakes** | MEDIUM | Font family + size already map cleanly (`text.ex`); roles decouple recipe from concrete font. Unregistered role → existing typed error, no silent substitution |
| **`leading` token** driving line-height per step | **Table stakes** | LOW | Rendro emulates `line_height` faithfully today; leading is a named default over it |
| **`widows` / `orphans`** centralized as theme defaults | **Table stakes** | LOW | Fields already exist on `Rendro.Text`; theme just supplies coherent defaults instead of per-call values |
| **Step ratio choice baked into `default/0`** — restrained business ratio (~1.2 major second → 1.25 major third), NOT editorial 1.333+ | **Differentiator** | LOW | Ratio is picked once and materialized as explicit pt values (determinism: ship the numbers, not the formula). Restraint = the rubric's "restraint/cohesion" dimension |
| Tabular/lining figure selection, small-caps | **Differentiator (defer)** | HIGH | Needs OpenType feature plumbing Rendro lacks today; not required to clear the rubric. Note as future, not v2.11 |
| **Numeric weight axis** (`fontWeight: 100–900`, variable fonts) | **Anti-feature (for B)** | — | Rendro resolves weight via *distinct font files per role*, not a synthetic/variable weight axis. A numeric axis implies faux-bold or variable-font machinery the engine doesn't have. Weight lives in the `fonts` role (a bold face is a registered font), not a token axis |
| **`letter-spacing` / tracking** | **Anti-feature (for B)** | — | No letter-spacing primitive exists in the writer; it needs a new glyph-advance concept. DTCG includes it, but it does not map to a deterministic-PDF primitive Rendro ships today. Exclude from the contract (revisit only if a preset in C proves demand) |
| CSS units (`rem`, `em`, `%`, viewport units) | **Anti-feature** | — | The page is points on paper, not a viewport. Scale steps are absolute pt. No unit indirection |

**Picking the ratio (guidance for `default/0`):** business documents are dense, information-first artifacts. Use a **conservative ratio (major second 1.125 to major third 1.25)** so `body`→`title`→`display` climbs are legible-but-distinct, not billboard-dramatic. Reserve high-contrast editorial ratios (1.333+) for the *Editorial* preset in Milestone C. Materialize the computed sizes as explicit points in `default/0` (e.g. caption 8 / small 9 / body 10.5 / subtitle 12 / title 16 / display 22) — **ship the numbers, not the formula**, so byte-determinism is trivial and the scale is auditable.

---

## Category 3 — Spacing, rules, radius, density

**Concept in prior art:** Spacing scales (Tailwind `space-1..96`, Material 4dp grid), border-width tokens (hairline/regular/thick), radius tokens (`none/sm/md/lg/full`), and density modes (Material's comfortable/compact) are standard scalar token families. All are pure geometry.

**Rendro translation:** every one of these maps cleanly to an existing primitive — points for spacing, stroke width for rules, `{:rounded_rect,…,radius}` for radius. SEED-003 marks these "honored as optional tokens with sane defaults." Recommendation: **rules is table stakes (print-safety), the rest are optional-with-defaults differentiators.**

| Feature | Classification | Complexity | Maps to / depends on |
|---------|----------------|------------|----------------------|
| **`rules`** `hairline / regular / heavy` stroke weights (in pt) | **Table stakes** | LOW | `lib/rendro/path.ex` stroke width. Hairline rule weight is a **print-safety** concern (too-thin rules drop out / too-heavy rules muddy) → feeds the rubric's print-safety gate |
| **`spacing`** scale (named pt steps for margins/gutters/padding) | **Differentiator (optional, defaulted)** | MEDIUM | Points map directly, but "px≠pt" and there's no existing spacing-scale abstraction — it's new-ish. Honor with sane defaults; recipes may read or ignore |
| **`radius`** `none / sm / md` | **Differentiator (optional, defaulted)** | LOW | `{:rounded_rect,…,radius}` already exists; `none` = plain `{:rect}`. Cheap, high polish-per-effort |
| **`density`** `:comfortable | :compact` | **Differentiator (optional, defaulted)** | MEDIUM | A single scalar that scales spacing/leading; the honest home for "Compact-Operational" (SEED-004 explicitly folds that would-be preset into `density: :compact`). Wire the token now, deep recipe honoring can be shallow in B |

**Scope guard:** define the FULL shape of these tokens up front (widening a public struct later is breaking) but implement `spacing/rules/radius/density` as **honored-with-defaults**, not deeply threaded through every recipe. Colors + typography + mode get *fully wired*; these four get *present-and-defaulted*. That tiered implementation is exactly the SEED-003 "define full shape, implement in tiers" instruction.

---

## Category 4 — Light / Dark mode

**Concept in prior art:** Mature systems treat dark mode as a **role re-derivation, not a second set of art**. Material 3 derives dark surfaces by re-toning the same roles (tone-based surfaces); Radix ships light/dark scales where step *N* keeps its role in both; Tailwind's semantic layer is "what enables dark mode" precisely because components reference roles, not raw values.

**Rendro translation:** `mode: :light | :dark` is a variant selector on the *same* theme. `Rendro.Theme.dark/1` swaps `background`/`ink`/`surface`/`on_accent`; recipes prepend a full-page `{:rect}` background fill. Because every recipe reads roles (never literals — enforced by S1), **every recipe gets dark for free**.

| Feature | Classification | Complexity | Maps to / depends on |
|---------|----------------|------------|----------------------|
| **`mode: :light | :dark`** first-class selector | **Table stakes** | MEDIUM | Variant on one theme; `Rendro.Theme.dark/1` |
| **Full-page background fill in dark** so pages aren't white-on-white | **Table stakes** | LOW | `{:rect}` page-size fill (page geometry, `path.ex`) prepended in `page_template/1` |
| **Dark derived from roles, not authored separately** | **Table stakes** | MEDIUM | The whole point: no per-recipe dark art. Depends on S1 literal-free sections |
| **Strong restrained UNBRANDED default** — Swiss/International **neutral-ink**, high-contrast, NOT everything-blue | **Differentiator** | MEDIUM | `Theme.default/0` (see Category 5). Accent used *sparingly* (one anchor mark), ink does the hierarchy work |
| **`from_brand/2` + single `accent:` seed** feeding both modes | **Differentiator** | MEDIUM | One brand color derives light+dark coherently; mine `brand/tokens/tokens.json` light/dark pairs for `{r,g,b}` reference values (hex→tuple at boundary) |

**Honest print-safety note (flag for requirements):** dark-mode PDFs are **screen-first artifacts**. A full-page dark fill is heavy toner/ink if printed and can look wrong on paper. The *light* default must be the one that clears the rubric's print-safety gate; dark is an additive screen variant, not the print target. Do not let dark mode weaken the light default. (This is an advisory framing, not a support-matrix claim — consistent with the no-overclaim culture.)

---

## Category 5 — Unbranded default & rubric-gap closing

This category is where the milestone's *folded-in* obligation lives: the Phase-118 SHOW-01 gap (all six v2.10 demos scored **below** the Milestone-A reader-quality rubric). `Theme.default/0` and themed demos must **clear** the rubric.

**What clears the rubric (the rubric-gap-closing features, in priority order):**

| Feature | Classification | Rubric dimension it moves | Complexity |
|---------|----------------|---------------------------|------------|
| **Type scale creating a dominant key-fact** (`display` step for the ONE key fact: invoice total / net pay / seat) | **Table stakes** | **Content hierarchy (MUST score 5)** — the single biggest lever; the rubric requires the key fact be the visual anchor | MEDIUM |
| **`accent` + `on_accent` used to spotlight the anchor** (one restrained accent mark, not decoration everywhere) | **Table stakes** | Content hierarchy + restraint/cohesion | LOW |
| **`surface` tint + `rule` hairline to group** (totals panel, table bands) | **Table stakes** | Information architecture; typographic craft | LOW |
| **Print-safe hairline rule weights + ink contrast** | **Table stakes** | **Print-safety gate (pass/fail)** | LOW |
| **Restrained neutral-ink `default/0`** (Swiss/International: neutral grotesque intent, tight rhythm, high contrast, sparse accent) | **Differentiator** | Restraint/cohesion; domain-fit/least-surprise | MEDIUM |
| **Invoice under-build fix** (the canonical recipe currently under-sells; theming + the anatomy the demo exercises) | **Table stakes** | Information architecture (SHOW-01 named the invoice specifically) | MEDIUM |

**Design of the unbranded default (opinionated, locked by seed):** neutral **ink** does the hierarchy work through the *type scale*, not color. Accent appears once or twice (the anchor, a rule) — **NOT everything-is-blue**. This is the "serious default" and doubles as the basis for Milestone-C's Swiss/International preset. It must clear the rubric **on its own, unbranded** — that is the acceptance bar.

**Note:** the rubric itself already exists as an appendable schema-backed manifest (`priv/quality/rubric_scores.json`, S5 from Milestone A). B **populates/clears** it; it does not redesign it. Threshold arithmetic (hierarchy = 5, core ≥ 4, gates pass) stays a test helper, not `lib/` code.

---

## Category 6 — Recipe plumbing & manifests/contract

**Concept in prior art:** Style Dictionary's model is "define tokens once, transform/thread everywhere"; a theme is resolved once to a flat inert value and referenced, never recomputed per component. DTCG files are inert JSON resolved by a build step.

**Rendro translation:** `Rendro.Theme` is a **pure inert struct resolved once** and threaded through the existing 3-rung escape hatch. This reuses the exact seam Milestone A pre-installed (S1 `palette(opts)`), so theming is a *one-line swap per recipe*, not a rewrite.

| Feature | Classification | Complexity | Maps to / depends on |
|---------|----------------|------------|----------------------|
| **`Rendro.Theme` struct** — full shape defined up front, implemented in tiers | **Table stakes** | MEDIUM | New `lib/rendro/theme.ex`; pure value, no engine widening |
| **`theme:` opt resolved at `document/2`** via `Rendro.Theme.resolve/1`, default `Rendro.Theme.default/0` | **Table stakes** | MEDIUM | Reuses the open top-level `opts` + `Keyword.take` whitelist pattern (v2.10). Threaded through `page_template/1` + `sections/2` |
| **Threaded through all 8 recipes' 3 rungs** reading roles (never literals) | **Table stakes** | MEDIUM | S1 `palette(opts)` seam already present in v2.10 recipes → one-line swap, not a 6-recipe color rewrite |
| **`brand:` stays orthogonal** (assets = *who*, theme = *how*) | **Table stakes** | LOW | `brand: %{font_name, logo_name}` untouched; `Theme.from_brand/2` bridges brand→theme without coupling |
| **`Rendro.Theme.dark/1` / `default/0` / `resolve/1` / `from_brand/2`** public functions | **Table stakes** | LOW–MEDIUM | New public API surface |
| **`priv/public_api.json` + `priv/support_matrix.json`** updated + machine-checked | **Table stakes** | LOW | Existing docs-contract lanes; a stable-vs-adapter tier tag decision for `Theme` (recommend **stable** for the struct/roles, since widening is breaking and the contract is meant to be frozen) |
| **`artifacts.json` theme/mode/preset tags** already seeded (S6) | Enabler (already shipped) | — | C's catalog explosion won't re-key the manifest; nothing new needed in B beyond honoring the tags |

**Contract discipline (critical, from seed):** define the **FULL struct shape now** (colors + typography + spacing + rules + radius + density + mode), because widening a public struct later is a breaking change. Implement colors/typography/mode fully; honor the rest with defaults. This is the "public contract, tiered implementation" rule.

---

## Consolidated: Anti-Features (permanently EXCLUDED from the theme contract)

These do **not** map to a deterministic-PDF primitive and must be permanently excluded — not deferred. Excluding them is the honest answer to "ideally shadow/z-index/etc."

| Excluded token | Why requested | Why it doesn't map to deterministic PDF | Honest alternative |
|----------------|---------------|------------------------------------------|--------------------|
| **shadow / elevation** | Depth, card affordance | No native shadow/vector-alpha/blur primitive; would be non-deterministic raster or fake | **Express elevation FLATLY: `surface` tint + `rule` hairline.** This is exactly what Material 3 does — "elevation mainly using tonal color overlays," surface-container tone levels instead of shadow. A tinted panel with a hairline *reads* as raised on paper. |
| **z-index** | Layering | PDF has only **draw order**; there is no stacking-context model | Author draw order in the recipe (later marks paint over earlier). No token. |
| **motion / transition / duration / easing** | UI animation | A PDF is a static medium; nothing animates | None — the medium is static |
| **focus-ring / hover / pressed / selected / active** | Interaction states | Printed/static documents have no interaction states | None — collapse to the single resting appearance |
| **opacity / alpha / gradient** | Tints, fades, overlays | No native vector-alpha or gradient primitive; determinism + toner-safety suffer | Use a **pre-computed solid `{r,g,b}`** at the target tint (mix against background at author time), not runtime alpha |
| **grid max-width / breakpoints / responsive** | Fluid layout | The page is a fixed physical size, not a resizing viewport | Page geometry (margins/columns in pt) — already the recipe model |
| raw color **scales** (12-step / 50–950) | Familiarity from Radix/Tailwind | A document draws flat fills; scales bloat a frozen contract | Semantic **roles** only (Category 1) |
| **numeric weight axis** / variable fonts | `fontWeight: 700` habit | No variable-font/synthetic-weight machinery; weight = a registered font file | `fonts` role points at a bold face (Category 2) |
| **letter-spacing / tracking** | Tracked caps labels | No glyph-advance/tracking primitive in the writer today | Excluded for B; revisit only if a C preset proves demand |
| P3 / Oklch / wide-gamut color | DTCG 2025.10 now supports them | Rendro is device `{r,g,b}` / sRGB | hex→tuple at the boundary; stay sRGB |

**Guard to hold:** none of these should appear as fields on `%Rendro.Theme{}`, even "for future use." Their absence is a feature — it keeps the contract honest and byte-deterministic.

---

## OUT OF SCOPE for Milestone B (deferred to C/D — NOT anti-features)

These map fine to the token contract but belong to a later milestone. They must not bleed into v2.11 requirements.

| Deferred capability | Milestone | Why not in B |
|---------------------|-----------|--------------|
| **Style-genre presets** (Swiss/Humanist/Editorial/Corporate-Classic/Minimal-Mono/Brutalist) as `%Theme{}` values | **C (`SEED-004`)** | Presets ARE themes, but need curated fonts + real design labor; must not block the token contract |
| **Curated open-license fonts** in `priv/fonts/` | **C** | Presets need them to render out of the box; B ships the contract, not a font library |
| **Public example catalog** (domain × brands × light/dark grid, hash-checked artifacts) | **C** | Depends on presets + brand data; B ships `default/0` + themed demos only |
| **Static client-side configurator + URL state + `mix rendro.gen.theme` codegen** | **C** | The "browse → pick → copy code" path is a C ergonomic over the C catalog |
| **Live in-app server-rendered Studio playground** | **D (`SEED-005`)** | Heaviest surface; optional and last |
| Tabular figures / small-caps / OpenType features | Future (demand-gated) | Needs OT plumbing; not required to clear the rubric |

**Boundary that must hold across B→C→D:** *design systems = code (`lib/rendro/theme*`), brands = data (`priv/examples/`)*. A brand is never a module. `Theme` is pure presentation and industry-agnostic (family-not-industry). Engine stays locale-free and byte-deterministic. No accessibility/PDF-UA claims.

---

## Feature Dependencies

```
Rendro.Theme struct (full shape up front)
    └──requires──> Rendro.Color {r,g,b} contract            [exists]
    └──requires──> S1 palette(opts) literal-free seam        [shipped v2.10]

theme: threading (document/2 → page_template/1 → sections/2)
    └──requires──> Theme struct
    └──requires──> open top-level opts + Keyword.take whitelist [shipped v2.10]

mode: :dark
    └──requires──> color roles (dark = role re-derivation)
    └──requires──> {:rect} full-page background fill (path.ex)  [exists]
    └──requires──> S1 literal-free sections (dark for free)     [shipped v2.10]

Type scale (NEW)
    └──drives──> Rendro.Text size field                      [exists]
    └──enables──> key-fact dominance → rubric hierarchy = 5

rules / radius tokens
    └──requires──> path.ex stroke width + {:rounded_rect,…,radius} [exists]

from_brand/2 + accent: seed
    └──requires──> hex→tuple boundary (mine brand/tokens/tokens.json) [reference data]
    └──derives──> on_accent by contrast pick

Theme.default/0 (unbranded, clears rubric)
    └──requires──> type scale + accent/on_accent + surface/rule + print-safe hairlines
    └──closes──> Phase-118 SHOW-01 rubric gap

Presets (C) ──requires──> Theme struct + light/dark   [B is the prerequisite]
Catalog (C) ──requires──> presets + brand data
Studio (D)  ──requires──> catalog (read-only consumer)
```

**Dependency notes:**
- **Theme threading is cheap because S1 already landed.** The single highest-leverage Milestone-A seam (`palette(opts)` keyed on these exact roles, defaulting to today's literals) means B is a one-line swap per recipe, not a six-recipe color rewrite. This is the load-bearing dependency.
- **Type scale has no existing surface** — it is the one genuinely new abstraction and the one most likely to need its own careful phase.
- **Everything geometric already exists** (`{r,g,b}`, stroke, `{:rect}`, `{:rounded_rect,…,radius}`, `line_height`, `widows`/`orphans`) — colors, rules, radius, spacing, dark-fill all thread through primitives shipped before v2.11.

---

## MVP Definition

### Launch With (v2.11 core — fully wired)

- [ ] **`Rendro.Theme` struct with FULL shape defined** (colors + typography + spacing + rules + radius + density + mode) — widening later is breaking, so shape is complete on day one.
- [ ] **7 core color roles + 2 optional status roles**, `{r,g,b}`, consumed via S1 `palette(opts)`.
- [ ] **Named type scale** (6 steps) + **`fonts` roles** (heading/body/mono) + **leading** + widows/orphans — the NEW surface; produces hierarchy.
- [ ] **`mode: :light | :dark`** via `dark/1` + full-page background fill; dark derived from roles.
- [ ] **`theme:` resolved at `document/2`** (`resolve/1`, default `default/0`) threaded through all 8 recipes' 3 rungs.
- [ ] **`Rendro.Theme.default/0`** — restrained neutral-ink Swiss-ish unbranded default that **clears the Milestone-A rubric on its own** (closes SHOW-01).
- [ ] **`from_brand/2` + single `accent:` seed**; `brand:` stays orthogonal.
- [ ] **`public_api.json` + `support_matrix.json`** updated + docs-contract lanes green.

### Add After (same milestone, honored-with-defaults — tiered implementation)

- [ ] **`spacing` / `rules` / `radius` / `density`** tokens present with sane defaults (`rules` gets real hairline print-safety values; the rest defaulted, shallow recipe honoring). Full shape now, deep wiring later.

### Future Consideration (defer — C/D or demand-gated)

- [ ] Style-genre **presets** + curated **fonts** + **catalog** + **configurator** → Milestone C.
- [ ] Live **Studio** → Milestone D.
- [ ] Tabular figures / small-caps / OpenType, letter-spacing, numeric weight axis → demand-gated future (need new primitives).

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Color roles (7+2) + S1 threading | HIGH | MEDIUM | **P1** |
| Type scale + fonts roles (NEW) | HIGH | MEDIUM | **P1** |
| `theme:` plumbing through 3 rungs | HIGH | MEDIUM | **P1** |
| `default/0` clears rubric (SHOW-01) | HIGH | MEDIUM | **P1** |
| `mode: :light/:dark` role-derived | HIGH | MEDIUM | **P1** |
| `from_brand/2` + `accent:` seed | HIGH | LOW | **P1** |
| Manifests (`public_api`/`support_matrix`) | MEDIUM | LOW | **P1** |
| `rules` hairline (print-safety) | MEDIUM | LOW | **P1** |
| `radius` / `spacing` / `density` (defaulted) | MEDIUM | MEDIUM | **P2** |
| `positive` / `negative` status roles | MEDIUM | LOW | **P2** |
| Tabular figures / OT features | LOW | HIGH | **P3** |

---

## Competitor / Prior-Art Feature Mapping

| Token concept | Radix Colors | Material 3 | Tailwind | W3C DTCG 2025.10 | **Rendro (deterministic PDF)** |
|---------------|--------------|------------|----------|------------------|-------------------------------|
| Semantic color | 12-step, role-per-step | named roles + tonal palettes | semantic layer over raw scales | `color` primitive (P3/Oklch) | **7+2 named roles, `{r,g,b}` only — no scales, no wide gamut** |
| "On" foreground | contrast-guaranteed 11/12 | `on-primary`/`on-surface` | manual | — | **`on_accent` role** |
| Elevation | — | **tonal surface overlay** (no shadow) | `shadow-*` | `shadow` composite | **surface tint + rule hairline (flat)** — EXCLUDE shadow |
| Type scale | — | `display/…/label` steps | `text-xs…9xl` | `typography` composite | **6 named pt steps, restrained ratio, materialized numbers** |
| Weight | — | numeric | numeric | `fontWeight` | **`fonts` role = registered face — no numeric axis** |
| Letter-spacing | — | tracking | `tracking-*` | `letterSpacing` | **EXCLUDE (no primitive)** |
| Radius | — | shape scale | `rounded-*` | `dimension` | **`radius none/sm/md` → `{:rounded_rect}`** |
| Dark mode | dark scales | tone re-derivation | `dark:` variant | — | **`dark/1` role re-derivation, full-page fill** |
| Motion/focus/z-index | — | full | full | — | **EXCLUDE all — static medium** |

**Takeaway:** Rendro's contract is the *intersection* of these systems' semantic layers, minus everything that assumes a screen (scales, wide gamut, shadow, motion, interaction, letter-spacing, numeric weight). That intersection is small, complete for business documents, and freezable as public API.

---

## Sources

- [Design Tokens specification reaches first stable version (W3C DTCG, 2025.10)](https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/) — HIGH (curated/standards body); confirms `color`/`dimension`/`typography` types and the `typography` composite (fontFamily/fontSize/fontWeight/letterSpacing/lineHeight)
- [Design Tokens Format Module 2025.10](https://www.designtokens.org/tr/drafts/format/) — HIGH
- [Understanding W3C Design Token Types — F. Improta](https://designtokens.substack.com/p/understanding-w3c-design-token-types) — MEDIUM
- [Material Design 3 — Color roles](https://m3.material.io/styles/color/roles) — HIGH (curated); the `on-*` convention and role-as-connective-tissue framing
- [Material 3 — Tone-based surface color (flat elevation)](https://m3.material.io/blog/tone-based-surface-color-m3) — HIGH; validates "express elevation flatly via surface tint" (tonal overlay, not shadow)
- [Radix Colors — Understanding the scale / composing a palette](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale) — HIGH; step-to-role mapping and "same step = same role across palettes"
- [Tailwind CSS — Theme variables / semantic tokens](https://tailwindcss.com/docs/theme) + [semantic color tokens guide](https://www.subframe.com/blog/how-to-setup-semantic-tailwind-colors) — MEDIUM; the semantic-layer-over-raw-scales pattern that enables theming/dark mode
- [Modular type scale ratios (modularscale.com common ratios)](https://spec.fm/specifics/type-scale) — MEDIUM; `base × ratio^n`, Major Third 1.25 / Perfect Fourth 1.333 most common, smaller ratios for dense UI
- Rendro internal (HIGH, authoritative for this repo): `SEED-003` (locked token/excluded discipline), `SEED-004` (C out-of-scope boundary), Milestone-A `SUMMARY.md` (S1 palette seam, rubric thresholds, honest-affordance findings), `PROJECT.md` v2.11 scope

---
*Feature research for: deterministic PDF theming / design-token contract (`Rendro.Theme`), Milestone B / v2.11*
*Researched: 2026-07-19*

# Milestone B (SEED-003 / v2.11) — Research Synthesis & Locked Recommendation

**Milestone:** v2.11 "Document Theming & Design-Token System" (hex `1.2.0`, additive minor).
**Program context:** Milestone B of the 4-milestone Happy-Path Home Runs program (A realistic examples → **B theming** → C presets+catalog → D optional Studio). Phase numbering continues at **119**.
**Method:** 4 parallel research lenses (STACK, FEATURES, ARCHITECTURE, PITFALLS), each grounded directly in the shipped v2.10 codebase. Full reports in `.planning/research/milestone-b/{STACK,FEATURES,ARCHITECTURE,PITFALLS}.md`.

## Direction verdict — GREEN. Ship it.

All four lenses independently confirm v2.11 as scoped is **coherent and buildable, with an unusually low technical-risk profile** — the design translates cleanly to the engine's existing primitives, adds **zero new dependencies**, and adds **zero deterministic-core surface**. `Rendro.Theme` is a pure inert value resolved once in the recipe layer; the engine (`build → compose → measure → paginate → render → validate`) never sees a `%Theme{}` and gains no theme-aware field. The load-bearing enabler already shipped: Milestone A's S1 `palette(opts)` seam, keyed on the exact SEED-003 roles, turns theming into a one-line swap per recipe rather than a color rewrite. The risk in this milestone is **not** technical feasibility — it is contract discipline (freeze the right shape once), determinism discipline (dark mode + type scale must not drift bytes), and honesty discipline (close the folded-in Phase-118 rubric gap by fixing DATA, not by cranking the theme).

**Version:** additive minor **v2.11 / hex `1.2.0`**, NOT a major. The public API only *grows* (new `Rendro.Theme` module); the default theme is engineered to be a **byte-identity no-op** on today's un-themed calls (`document(data)` with no `theme:` reproduces v2.10 bytes for all 7 recipes). Because B changes `lib/`, it IS a versioned release.

## The single irreversible act (guard it)

**The new public `Rendro.Theme` API surface entering `priv/public_api.json`** is the milestone's only one-way door — and a struct has far more observable Hyrum's-Law surface than the three `Format` functions promoted in Milestone A. Once `%Theme{}` ships, its field set, nesting shape, default token values, and every value it computes become an observable contract adopters pattern-match against. The specific trap: shipping a *partial* struct (only the wired tiers) and being forced to widen it in Milestone C when presets need `spacing`/`radius`/`density` fields left out.

**Tier decision — RESOLVED. Ship `Rendro.Theme` on the `adapter` (Evolving) tier, NOT Stable.** The researchers disagreed (STACK/FEATURES leaned toward tagging the struct/roles **Stable** since widening is breaking and the contract is meant to be frozen; ARCHITECTURE/PITFALLS argued **adapter/Evolving**). The crux is the "define full shape up front, implement in tiers, values may evolve" tension — and it resolves decisively toward **adapter**, because the two claims are not in conflict once you separate *shape* from *values*:

- **Field names / role semantics / arities are frozen by intent** — this is what "define the FULL shape up front" buys, and it is what the Stable-leaning lenses were really protecting. Widening a bare map later is a *non-breaking key addition*; the one thing to never do is *rename*. So the shape is stable-by-discipline without needing the Stable *tag*.
- **Default token VALUES and honored-with-defaults fidelity are Evolving** — `default/0`'s exact `{r,g,b}`s exist to clear the rubric and *will* be tuned; `spacing`/`rules`/`radius`/`density` get deeper wiring in C/D, which changes rendered bytes. Tier-1 Stable would freeze all of that forever via Hyrum's Law. This is the identical discipline locked for `Rendro.Format` in Milestone A: adapter tier + an explicit "token values and rendered output may evolve; the field shape is stable" doc note. Byte-determinism stays a **within-version** guarantee (goldens are versioned), never a cross-version freeze.

**This requires editing the `public_api_contract_test.exs` hidden set** — the surprise-red-build class. The lane byte-compares a regenerated manifest to `priv/public_api.json`, so it red-builds until `mix rendro.api.gen` runs with the new `Theme` entry. Pre-declare it as a planned red→green step (exactly the surprise `Format` produced in Phase 115) and **grep for ALL hidden-modules assertions, not just the one the plan lists** — Phase 115's lesson was a *second, plan-unlisted* duplicate hidden-modules assertion in `manifest_test.exs`. Tag `@moduledoc tags: [:adapter]`, `@spec` every public function, and keep all derivation helpers (`on_accent_for/1`, dark-swap, hex→tuple, `normalize/1`) `defp`/`@doc false` so the hidden-internals assertions stay green.

## Code-grounded correction (the biggest non-obvious scope item)

**The "migrate 8 recipes from `palette(opts)` to `theme.colors.*`" premise is FALSE as stated — the S1 seam exists in only 3 of 7 recipes.** Direct audit of the shipped code:

| Recipe | S1 `palette` seam present? | Inline `{r,g,b}` literals outside a seam |
|--------|---------------------------|------------------------------------------|
| `invoice`, `payslip`, `ticket` | ✅ (Phases 115/116) | 0 — one-line swap ready |
| `statement` | ❌ | 2 inline literals (e.g. `statement.ex:306` `{0,0,0}` stroke) |
| `certificate` | ❌ | 3 inline literals (e.g. `{34,34,34}` frame default) |
| `receipt` | ❌ | 0 (little/no color, own story) |
| `branded_invoice` | ❌ | 0 (font+logo branding, own color story) |

So **4 recipes need a byte-identical seam RETROFIT before any theme swap can touch them.** This must be **two steps, per-recipe, never combined in one commit**: (1) *retrofit* `palette(opts)` with defaults = today's exact literals, proven byte-identical by a fresh rendered sha256 golden *before* any theme wiring; then (2) *swap* `palette(opts)` → `theme.colors.*` where the default theme reproduces those same defaults. This mirrors Milestone A's "split the verbatim move from the normalization" discipline. Certificate is the stress case (geometry-derived centered layout + optional frame + optional brand). Where a literal was non-black (`{34,34,34}`), decide in-plan whether the default `rule` role matches or the golden re-blesses.

## Right-sized phase list — candidate phases from 119, keyed by RISK profile

Both ARCHITECTURE (5 phases 119–123) and PITFALLS (6 P-tags) proposed compatible decompositions. Synthesized recommendation, ordered by dependency and isolating each risk class:

### Phase 119 — `Rendro.Theme` core module (the one-way door) — NEW component, zero recipe change
Ship `lib/rendro/theme.ex`: the **full struct shape defined up front** (colors + typography + spacing + rules + radius + density + mode — even honored-with-defaults tiers, so C appends *values* never *fields*), `resolve/1` (idempotent; validates every `{r,g,b}` via `Rendro.Color.validate/1`; errors-as-product on bad token), `default/0` (Swiss-ish neutral, hex→tuple mined from `tokens.json`), `dark/1` (role swap), `from_brand/2` + `on_accent_for/1`, `text_opts/3`, the materialized type scale. Register in `public_api.json` (**adapter tier**) + `support_matrix.json` skeleton; reconcile `public_api_contract_test.exs` (planned red→green + grep ALL hidden assertions). Pure unit tests only. **No recipe touched ⇒ every existing golden untouched.** This is the reviewed irreversible-act phase; the web-concept exclusions (shadow/z-index/opacity/gradient/motion/focus) are enforced by construction here.
*Risk: contract-freeze (Hyrum). Highest-stakes, lowest-blast-radius phase.*

### Phase 120 — S1 seam retrofit + full `theme:` swap across all 7 recipes
Two-step per recipe: **retrofit** the 4 un-seamed recipes (Statement/Certificate/Receipt/BrandedInvoice) with byte-identical `palette/1` goldens first, then **swap** all 7 to `theme.colors.*` and thread the resolved `theme:` through the 3 rungs (`document/2` → `page_template/1` → `sections/2`), each rung defensively `resolve/1`-ing. Adopt `typography.scale` on role-reading blocks via `text_opts/3`; frozen colorless toy blocks keep literal `size:` for byte-identity. Confirm each recipe's `Keyword.take` whitelist admits `:theme`. **The single most important regression guard of the milestone: `document(data)` with no theme is a byte-identity no-op for all 7 recipes.**
*Risk: byte regression across the recipe blast radius. May fold the 3-seamed and 4-retrofit recipes into one phase, but keep the retrofit commits split from the swap commits regardless.*

### Phase 121 — Light/dark background-fill mechanism (all 7 recipes) — dedicated determinism-golden slice
Add the shared background helper (`Rendro.Recipes.Theming` or in `Recipes.Pagination`): `needs_background_fill?/1` + a first-in-list `:background` non-body region (`anchor: :fixed`, full-page) + the `{:rect}` fill section. Wire into all 7 recipes' `page_template/1` + `sections/2`. **Zero paginate change.** Golden proofs: (a) light default emits **no** rect (byte-identical); (b) dark mode paints every page including a forced **overflow** page. Its cross-recipe + determinism-golden nature argues for a dedicated slice rather than folding into 120.
*Risk: determinism across pagination. See "Light/dark determinism" below.*

### Phase 122 — Typography type-scale + font-role resolution (the one net-new abstraction)
Materialize the named scale (`display/title/subtitle/body/small/caption`) as **explicit point sizes** and thread them into `%Text{size,font,line_height,widows,orphans}`. This is the single biggest lever for closing the Phase-118 SHOW-01 hierarchy gap. Font roles (`heading/body/mono`) resolve through the existing `FontRegistry` (which already carries a `fallbacks:` chain and raises the correct typed `{:unknown_text_font, _}` error — no shape change, no silent Helvetica substitution). `default/0`'s scale/leading must be a **metric no-op** so Phase-117 stress goldens are unchanged. *May fold into 120* if the plan prefers, but its rubric-leverage and pagination-sensitivity favor isolation.
*Risk: type scale fighting measure/paginate; silent font substitution.*

### Phase 123 — `from_brand/2` E2E + rubric-gap remediation (done honestly) + manifest/docs closure
`from_brand/2` end-to-end with `brand:` assets orthogonal (single `accent:` seed, `on_accent` derived). **Remediate the folded-in Phase-118 SHOW-01 gap in the honest order: fix DATA first, theme second.** Repair `Rendro.ExamplesData.transform_invoice` (it drops parties/totals), make the one key fact structurally dominant (size/placement/whitespace via the `display` step), *then* apply `default/0`, then re-score against the Milestone-A rubric (hierarchy = 5, core ≥ 4, gates pass) with **human sign-off** — do NOT flip a rubric score to `passed:true` in a commit that only changed colors. Populate S6 `theme`/`mode` tags on themed + dark gallery renders; finalize `support_matrix.json` theming row(s); `guides/theming.md` + claims test; docs-contract + tarball lanes green.
*Risk: dishonest rubric pass; manifest/contract drift (the surprise-red-build class).*

**Fold guidance:** 120+122 could merge (all-recipe color+type swap together); 121 could fold into 120/122. Recommendation: keep them split by **risk class** — 120 is near-mechanical byte-preservation, 121 is the determinism-across-pagination proof, 122 is the one genuinely new abstraction. Precedent for coarser folding exists (v2.4 Phase 75 shipped 2 recipes at once; Milestone A folded 7→5), so the roadmapper may compress if it prefers coarse granularity.

## Light/dark determinism — the concrete mechanism (locked)

The engine already solves light/dark across pagination **for free**. `Rendro.Pipeline.Paginate.apply_page_template/5` (`paginate.ex:909`) runs **per page** (every `idx`, including overflow pages), emits every non-`:body` region's blocks, and **prepends** them (`anchored_blocks ++ page.blocks`) so they render *beneath* body content. Therefore:

- **Background is a page-template region, never a body-list block.** A rect in `sections/2` body content renders once (not on overflow pages) and sits inside the body region → the killer "dark page 1, white pages 2..N, invisible text" bug. Model it as a dedicated full-page `:background` non-body region, first in the region list, and `apply_page_template/5` repeats it deterministically on every page. **Zero paginate change.**
- **Emit the rect ONLY when it changes pixels.** Gate on `needs_background_fill?(theme) = theme.mode == :dark or theme.colors.background != {255,255,255}`. Light default paints no rect → byte-identical to v2.10. The fill is additive and conditional, never unconditional.
- **Resolve every role to integer `{r,g,b}` once in `resolve/1`.** `Rendro.Color.format_num/1` emits `float_to_binary(n*1.0, decimals: 4)`; any float tint math (deriving `surface` from `background`, deriving `on_accent`) done per-draw can round differently across the `rg`/`RG` paths → non-reproducible bytes. `dark/1` swaps *pre-resolved* integer tuples; no transcendental math at draw time.

## Type scale = the one genuinely new surface and the biggest rubric lever

The named type scale is the single feature with **no existing engine surface** — everything geometric (colors, stroke, `{:rect}`, `{:rounded_rect}`, `line_height`, `widows`/`orphans`) already exists. It is also the **single biggest lever for closing the Phase-118 SHOW-01 rubric gap** (content hierarchy MUST score 5): the `display` step makes the ONE key fact (invoice total / net pay / seat) the visual anchor. **Materialize the scale as explicit point sizes, not a runtime `:math.pow` formula** — ship the numbers, not the formula, so byte-determinism is trivial and the scale is diff-auditable. Use a restrained business ratio (major second 1.125 → major third 1.25), NOT editorial 1.333+ (reserve that for a Milestone-C Editorial preset). `leading` is a **multiplier** matching `Text.line_height`'s existing `1.2` semantics, never points.

## Rubric-gap remediation done honestly (the highest-risk trap)

The Phase-118 SHOW-01 gap (all six v2.10 demos honestly scored `passed:false`) is folded into B, and the recorded root cause is **DATA, not color**: `transform_invoice` drops parties/totals, and demos fail to make the one key fact structurally dominant. Because this milestone's tool is theming, every problem *looks* like a theming problem — the trap is to apply a slick accent palette, declare the demos prettier, and mark the rubric passed. That re-commits the exact honesty violation Phase 118 *refused* (it paused rather than score dishonestly). **A better palette raises "typographic craft" and "restraint/cohesion" — which were NOT the failing dimensions.** Hierarchy and information-architecture failures come from what data is present and what is emphasized. So: fix the transform → make the key fact structurally dominant → *then* apply `default/0` → honest re-score with human sign-off. Rubric scores are an appendable S5 manifest; commit a `passed:true` only on an honest clear.

## Zero new dependencies — decisive

Everything `Rendro.Theme` needs is a few dozen lines of Elixir stdlib on the existing `Rendro.Color` / `Rendro.Text` / `Rendro.Path` / `Rendro.FontRegistry` surfaces plus the S1 seam. Hex→`{r,g,b}` is `Base.decode16!` + a binary match at the *authoring boundary only*. Dark mode is a `Map` swap. The type scale is a static numeric map. The one optional `on_accent` luminance heuristic is ~12 lines of `:math.pow`. **`mix.exs` deps change for this milestone: none** — not runtime, not optional, not dev/test. The reflexive "build a design-token system" instinct assembles the web trinity (Style Dictionary + Chameleon-style color conversion + CSS-variable parsing), all load-bearing *only* for multi-target export across multiple color spaces. Rendro exports to one deterministic target and speaks one color model (DeviceRGB), so all three collapse to stdlib. Each would also violate a standing Key Decision (pure Elixir core; locale-free; no Node/npm/browser). **Font-role resolution needs no shape change** — `FontRegistry.resolve/3` already maps logical atoms and carries the `fallbacks:` chain; roles are just three logical names riding the existing registration/resolution path.

## Shape-now note — S6 already absorbs B (no re-keying)

The S6 seam shipped in Milestone A: every `artifacts.json` gallery entry already carries `theme` / `mode` / `preset` tags (currently `null`/`"light"`/`null`), each hash-checked via `png_sha256` + `source_pdf_sha256`. B **populates** them — no schema migration. Each `(recipe × mode)` becomes its own hash-checked gallery row (e.g. `id: "invoice-dark"`, `mode: "dark"`), with `id` uniqueness keeping light/dark variants distinct. `preset` stays `null` in B (presets are C, which appends preset-tagged rows through the identical schema). Both modes are byte-reproducible, so a dark variant is blessed as a golden with no special handling.

## Locked decisions (cross-lens consensus)

- **`Rendro.Theme` is a single public module; token groups are bare typed maps**, not nested public structs — matches the S1 seam idiom (recipes already do `colors.ink`), keeps the manifest small, and makes widening a non-breaking key addition. `@enforce_keys []`; construct only via `resolve`/`default`/`dark`/`from_brand`.
- **Engine untouched.** No theme-aware field on `Document`, `PageTemplate`, or any pipeline stage. The theme resolves entirely in the recipe layer to concrete `%Text{}`/`%Path{}`. This is the headline determinism guarantee (AP1).
- **`brand:` (who — logo/font files, registries) stays orthogonal to `theme:` (how — tokens).** `from_brand/2` produces only tokens; it never registers an asset. "Design systems = code, brands = data" holds.
- **`default/0` and every shipped demo are LIGHT.** Dark is an available, screen-oriented mode with an explicit "not print-recommended / ink-heavy" doc + support-matrix boundary — no print-safety claim for dark, consistent with the no-overclaim / no-PDF-UA culture.
- **Permanent exclusions by construction:** shadow/elevation, z-index, motion, focus/hover, opacity/gradient, raw color scales, numeric weight axis, letter-spacing, wide-gamut color. None appear as `%Theme{}` fields even "for future use." Express elevation flatly (`surface` tint + `rule` hairline). Mine `tokens.json` for `{r,g,b}` ONLY.
- **Industry-agnostic `lib/` guard** (mirroring the branding/accessibility tripwires): fail if `theme.ex` references an industry or named brand. B ships exactly one theme (`default/0`) + `from_brand/2` — no genre presets, no catalog, no configurator (those are C).

## Explicitly OUT of scope for B (deferred — NOT anti-features)

These map fine to the token contract but belong to later milestones and must not bleed into v2.11:

- **Style-genre presets** (Swiss/Humanist/Editorial/Corporate-Classic/Minimal-Mono/Brutalist) as `%Theme{}` values → **Milestone C (SEED-004)**
- **Curated open-license preset fonts** in `priv/fonts/` → **C**
- **Public example catalog** (domain × brands × light/dark grid, hash-checked) → **C**
- **Static client-side configurator + URL state + `mix rendro.gen.theme` codegen** → **C**
- **Live server-rendered Studio playground** → **Milestone D (SEED-005)**
- Tabular figures / small-caps / OpenType features → demand-gated future (need new primitives)

## Open questions for phase planning

- **Type scale:** exact ratio + the 6 materialized point sizes (candidates diverge: FEATURES suggests caption 8 / small 9 / body 10.5 / subtitle 12 / title 16 / display 22; STACK suggests display 28 / title 20 / subtitle 15 / body 11 / small 9 / caption 8). Lock one restrained ramp in Phase 119/122.
- **`on_accent` derivation:** required-explicit role vs luminance-derived (WCAG `>0.5`-ish threshold). If auto-derived, keep it internal/deterministic and make no WCAG/AA conformance claim.
- **Legacy `:palette` opt:** retire in favor of `theme:` (its seeded swap target) or preserve via a final `Map.merge(theme.colors, opts[:palette])`? `grep -rn ":palette" test/` during Phase 120 to check for dependents.
- **Support matrix granularity:** does `support_matrix.json` score `theming.light` / `theming.dark` separately, or one flat `theming` row?
- **`density: :compact`:** shallow honoring in B (nudge leading/spacing via `resolve/1`) vs present-and-defaulted only.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | **HIGH** | Zero-dep conclusion verified by live execution on the repo (`Base.decode16!`, `:math.pow`) + direct read of `color.ex`/`text.ex`/`path.ex`/`font_registry.ex`. |
| Features | **HIGH** | Token prior art (W3C DTCG 2025.10, Material 3, Radix, Tailwind) is stable and cross-confirmed; PDF-mapping grounded in the engine's own primitives + SEED-003 locks. |
| Architecture | **HIGH** | Every integration point grounded in actual v2.10 source (`paginate.ex:909` per-page prepend verified; the 3-of-7 seam audit is code-exact). |
| Pitfalls | **HIGH** | Grounded in shipped code + the Phase-115 `Format`-promotion and Phase-118 SHOW-01 precedents, including the second plan-unlisted hidden assertion. |

**Overall confidence:** **HIGH.** This is a low-technical-risk, high-discipline-risk milestone. The feasibility questions are settled; the open questions are calibration (scale numbers, `on_accent` rule) not architecture.

### Gaps to Address

- **Non-black literal defaults (`{34,34,34}`):** during Phase 120 retrofit, decide per-recipe whether the default `rule` role matches the existing literal or the golden re-blesses. Flag explicitly in the plan.
- **`transform_invoice` data repair:** confirm the exact fields it drops (parties/totals) before Phase 123; the rubric fix depends on this being data-complete first.
- **Materialized scale numbers:** the two research files propose different ramps — resolve to one at planning time and freeze it as explicit points.

## Sources

### Primary (HIGH confidence)
- Rendro v2.10 codebase (direct read): `lib/rendro/{color,text,path,font_registry}.ex`; `lib/rendro/recipes/{invoice,payslip,ticket,statement,certificate,receipt,branded_invoice}.ex` (3-of-7 S1 seam audit); `lib/rendro/pipeline/{paginate,build}.ex` (`apply_page_template/5` per-page prepend; typed font errors); `priv/public_api.json`; `assets/rendro/artifacts.json` (S6 tags); `mix.exs`.
- Live execution: Elixir `~> 1.19` — `Base.decode16!("2C6BED") -> {44,107,237}`, `:math.pow(1.25,3) -> 1.953125`.
- Project canon: `.planning/PROJECT.md` (v2.11 scope, constraints), `.planning/seeds/SEED-003-*.md` (locked design, exclusions), `.planning/research/milestone-a/SUMMARY.md` (`Format` irreversible-act precedent, S1/S4/S5/S6 seams, reader-quality rubric), `.planning/STATE.md` (Phase-118 SHOW-01 findings, Phase-115 duplicate hidden-assertion lesson).

### Secondary (MEDIUM confidence)
- W3C DTCG 2025.10 (design-token types + `typography` composite); Material 3 color roles + tone-based flat elevation; Radix Colors scale semantics; Tailwind semantic-layer-enables-dark-mode; modular type-scale ratios.

---
*Research completed: 2026-07-19*
*Ready for roadmap: yes*

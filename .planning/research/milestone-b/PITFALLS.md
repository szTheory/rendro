# Pitfalls Research

**Domain:** Adding a public `Rendro.Theme` design-token contract to a deterministic, byte-reproducible 1.0 pure-Elixir PDF engine (Milestone B / SEED-003 / v2.11)
**Researched:** 2026-07-19
**Confidence:** HIGH (grounded in the shipped codebase — `lib/rendro/recipes/*`, `lib/rendro/color.ex`, `lib/rendro/text.ex`, `lib/rendro/pipeline/build.ex`, the S1 palette seam, `priv/public_api.json`/`priv/support_matrix.json` machinery — plus the locked SEED-003 design and the Milestone-A `Format`-promotion precedent. Candidate phase numbers are provisional: v2.11 phases continue from 119; the roadmap is not yet built.)

> **Candidate phase vocabulary used below** (roadmap TBD; phases continue from 119):
> - **P-DEF** — Theme contract definition: `%Theme{}` full shape, tier choice, `default/0`, `resolve/1`, manifest wiring (the one-way door).
> - **P-SEAM** — S1 seam completion + `theme:` threading across all recipes (palette→`theme.colors.*`, byte-identical goldens).
> - **P-DARK** — `mode: :light | :dark`, `dark/1`, full-page background fill, contrast + print-safety.
> - **P-TYPE** — typography scale + font-role resolution (may fold into P-DEF/P-SEAM).
> - **P-DEFAULT** — unbranded `default/0` + honest Phase-118 rubric-gap remediation.
> - **P-CLOSE** — manifest/support-matrix/docs/contract-lane closure.

---

## Critical Pitfalls

### Pitfall 1: Freezing the wrong `%Theme{}` shape (Hyrum's Law one-way door)

**What goes wrong:**
`Rendro.Theme` is a **public struct on a 1.0 library**. The moment `%Theme{}` ships, its field set, nesting shape, default values, and every value it *computes* become an observable contract that adopters pattern-match and `Map.get` against. Widening it later (adding a role, renaming `scale` steps, changing a default `{r,g,b}`) is a **breaking change** requiring a major bump — the same one-way-door class as Milestone A's `Format` promotion, except a struct has far more observable surface than three functions. The specific failure is shipping a *partial* struct (only the tiers you wired) and being forced to widen it in Milestone C when presets need `spacing`/`radius`/`density` fields that were left out.

**Why it happens:**
The natural instinct is "implement in tiers, ship the struct that matches what's wired." That leaks the tiering decision into the *contract*. SEED-003 explicitly warns against this: **"Define the FULL shape up front; implement in tiers."** The shape is the frozen thing; the *behavior* of the optional tiers is what evolves.

**How to avoid:**
- **Define the complete struct now**, including `spacing`, `rules`, `radius`, `density` — even the tiers "honored as optional tokens with sane defaults." Absent/unset ⇒ deterministic no-op, never a `KeyError`. C appends *values*, never *fields*.
- **Choose the adapter/Evolving tier for `Rendro.Theme`, not Tier-1 Stable** — mirror the locked `Format` decision. A themable presentation contract *must* be allowed to grow role values and default palettes; Tier-1 strict SemVer would freeze the default palette's exact `{r,g,b}` forever. Tag `@moduledoc tags: [:adapter]` and ship a "token *values* and defaults may evolve; the *field shape* is stable" doc note.
- **Do not expose internal token math.** Keep `dark/1`'s role-swap logic, any tint/contrast derivation, and hex→tuple conversion as `defp`/`@doc false`. Publish *roles and their resolved `{r,g,b}`*, never the transform that produced them — otherwise the derivation becomes frozen too.
- **No accidental fields.** Run the `%Theme{}` through `mix rendro.api.gen`; if a named `@type` for a sub-map appears in `priv/public_api.json`, inline it (Milestone A did exactly this — `Cell.cell_align`/`Table.cell_align` were inlined into `t()` specifically to avoid widening the frozen manifest with named types). Every named type in the struct is a separately-frozen symbol.
- **Treat P-DEF as its own reviewed decision**, exactly as `Format` promotion was treated as "its single irreversible act."

**Warning signs:**
- A struct field is added in a P-SEAM/P-DARK commit rather than all-at-once in P-DEF.
- `priv/public_api.json` diff shows a new `Rendro.Theme.*` named type after a later phase.
- Anyone proposes "we'll add the `radius` field in Milestone C."
- `default/0` returns a struct with fewer keys than `%Theme{}` defines.

**Phase to address:** **P-DEF** (define full shape + adapter-tier tag + manifest entry in one reviewed act, before any recipe reads it).

---

### Pitfall 2: Dark mode breaks byte-determinism

**What goes wrong:**
`mode: :dark` is where a themable engine most easily loses its determinism guarantee — the single most valuable property Rendro sells. Concrete failure modes, all specific to this engine:
- **Color rounding drift.** `Rendro.Color.format_num/1` emits `float_to_binary(n*1.0, decimals: 4)`. A dark role whose `{r,g,b}` divides to a value that rounds differently across the `rg` (fill) vs `RG` (stroke) paths, or a mined `brand/tokens/tokens.json` hex that converts to a non-round float, can produce non-reproducible bytes if any intermediate math (tinting a `surface`, deriving `on_accent`) is done in float before the 4-decimal emit. All role `{r,g,b}` values must be **integers 0–255 fixed at resolve time**, converted once, never recomputed per draw.
- **Background-fill draw-order nondeterminism.** Dark mode prepends a full-page `{:rect}` background fill. If that rect is appended to a section list that is later sorted, or inserted at a position that depends on map iteration order, the PDF content-stream operator order changes → different bytes. The background must be prepended at a **fixed, first** position in a deterministically-ordered list.
- **Missing background on overflow/continuation pages.** The killer bug: the page-1 background renders but pages 2..N (pagination-generated continuation pages) render on white because the background was attached to the *first composed page* rather than to the **page template applied to every page**. Result: a "dark" invoice that flashes white from page 2 — and light text on white = invisible content.

**Why it happens:**
Dark mode feels like "just swap some colors," so it's added as a per-section literal swap instead of a page-template-level fill. Continuation pages are generated by the paginate stage *after* the recipe's `sections/2` ran, so a background added in `sections/2` never reaches them. And float-based tint derivation is the "obvious" way to make a `surface` slightly lighter than `background`.

**How to avoid:**
- **Two-run determinism gate on every themed recipe × mode.** Extend `Rendro.Test.Golden`'s `assert_deterministic!/1` (shipped Phase 117) to cover `{recipe, :light}` and `{recipe, :dark}` cells. Byte-identical across two runs is the acceptance criterion.
- **Resolve all roles to integer `{r,g,b}` once in `Rendro.Theme.resolve/1`.** `dark/1` swaps *pre-resolved* role tuples; it never does float arithmetic at draw time. Any tint (`surface` from `background`) is computed once at resolve, rounded to integer components, and stored.
- **Attach the background fill in `page_template/1`, not `sections/2`** — the template is applied to every physical page including paginate-generated continuation pages. Add a golden fixture that is *deliberately multi-page in dark mode* and assert page 2's content stream contains the background rect.
- **Prepend at a fixed index** into an explicitly-ordered draw list; never rely on map ordering for draw order (the engine already treats "draw order only, no z-index" as the model — honor it).
- **Blessed goldens for the un-themed default call stay byte-identical.** `mode: :light` with `default/0` on the toy call must reproduce today's bytes (see Pitfall 5).

**Warning signs:**
- A dark render's page 2 is visually white / text invisible.
- `assert_deterministic!` passes for light but is never run for dark.
- Any `* 1.0`, `/ 255`, or `round/1` on a color inside a per-block/per-section render function rather than in `resolve/1`.
- The background rect appears in `sections/2` output.

**Phase to address:** **P-DARK** (fill in `page_template/1`; multi-page dark golden; per-mode two-run determinism gate).

---

### Pitfall 3: Poor dark-mode contrast + the dark-PDF print footgun

**What goes wrong:**
Two distinct failures beyond determinism:
1. **A role pair fails contrast in one mode.** `muted` text on `surface`, or `on_accent` on `accent`, can be readable in light and unreadable in dark (or vice-versa) because `dark/1` swaps `background`/`ink`/`surface`/`on_accent` but a role *not* in the swap set (`muted`, `accent`) now sits on an inverted ground. The rubric's **print-safety pass/fail gate** (a hard gate, shipped in Milestone A) then fails honestly.
2. **Dark PDFs are a print footgun.** A user prints a dark-background invoice → the printer floods the page with ink (or, on "background-graphics off," prints black text on nothing). A business document defaulting to dark, or a demo shipped in dark, actively harms the reader.

**Why it happens:**
Dark mode is treated as a free win ("every recipe gets dark for free") without asking *should this document be dark at all.* Contrast is assumed rather than checked because there's no automated contrast lane.

**How to avoid:**
- **`default/0` and every shipped demo are LIGHT.** Dark is an *available* mode, not a default and not the demonstrated one. The rubric-gated demos (Pitfall 7) render light.
- **Document dark as screen-oriented**, with an explicit "not recommended for print / ink-heavy" note in the `Theme` docs and support matrix — same honest-boundary discipline as the accessibility non-claims. Do **not** claim print-safety for dark.
- **Contrast check as data, not vibes.** Add a test that computes WCAG-style contrast ratio for the load-bearing role pairs (`ink`/`background`, `on_accent`/`accent`, `muted`/`surface`) in **both** modes for `default/0`, asserting a floor. This is a test helper (like the rubric threshold arithmetic), not `lib/` product code — preserves the "no new deterministic-core surface" boundary.
- **`dark/1` must swap the full ground-dependent set** so no role is left sitting on an inverted background.

**Warning signs:**
- A demo is rendered in dark mode "to show it off."
- No contrast assertion exists for the swapped roles.
- Support-matrix or docs imply dark PDFs are print-ready.

**Phase to address:** **P-DARK** (contrast test + honest dark-print boundary); **P-DEFAULT** (default + demos stay light).

---

### Pitfall 4: A type-scale that fights the measure/paginate stage; font-role resolution that silently substitutes

**What goes wrong:**
Two coupled typography failures:
1. **Type-scale vs. the existing measure/paginate contract.** SEED-003 introduces a *named type-scale* (`display/title/subtitle/body/small/caption`) — a genuinely new concept; the engine today has no scale, no numeric weight axis, no native leading. If the theme changes a recipe's body size or leading, it changes measured row heights → different pagination → the Phase-117 stress-matrix goldens and all recipe determinism gates go red, and "keep totals with last rows" / "carried-forward balance" logic can break at the new break points. `Rendro.Text.line_height` defaults to `1.2` (a multiplier, emulated — there is no native leading); a theme that ships `leading` as *points* instead of a multiplier, or that fights the existing `widows: 2`/`orphans: 2` defaults, causes silent regressions.
2. **Font-role resolution that silently substitutes.** The theme references logical font roles (`fonts: %{heading, body, mono}`). If a theme names a font role the document's `FontRegistry` has not registered, the correct behavior is to **raise the existing typed error** — the build stage already returns `{:error, {:unknown_text_font, logical_name}}` (see `lib/rendro/pipeline/build.ex`) and Milestone A's Payslip work established the explicit-fallback pattern (register B612 as a *deliberate* unicode fallback, never a silent one). The failure is a theme layer that quietly falls back to Helvetica when a brand font role is missing, producing a wrong-but-rendering document.

**Why it happens:**
Type scales are a web/design-token idiom where changing sizes is free (reflow). In a paginated deterministic engine, size *is* layout. And "just fall back to a default font" feels friendlier than raising — but it manufactures a false success.

**How to avoid:**
- **`default/0`'s scale and leading reproduce today's recipe metrics exactly.** The default theme must be a byte-identity no-op on the existing recipes (Pitfall 5). The scale is *available* for callers to override, but the shipped default does not move any measured height.
- **`leading` is a multiplier** matching `Text.line_height`'s existing semantics (default `1.2`), not points. Widows/orphans stay `2`/`2` unless a caller opts in.
- **Any theme size/leading override re-runs the two-run determinism gate + the Phase-117 stress matrix** for affected recipes. Treat a golden change as a red flag requiring explicit re-bless, never an auto-refresh.
- **Font-role resolution raises the existing typed `Rendro.Error` / `{:unknown_text_font, _}`** — theme font roles resolve *through* `FontRegistry`; a missing role is an instructive `ArgumentError` at the recipe boundary (errors-as-product), never a silent Helvetica substitution. Mirror Payslip's *deliberate, logged* fallback registration if a fallback is genuinely wanted.

**Warning signs:**
- Phase-117 stress goldens change when `default/0` is threaded in.
- `leading` is specified in points anywhere.
- A grep finds a `rescue`/`with ... else` around font resolution that returns a default font instead of propagating the error.
- Body/title sizes in `default/0` differ from the current recipe literals.

**Phase to address:** **P-TYPE** (scale semantics as multiplier; default = metric no-op; font-role errors propagate typed). Determinism re-verification lands wherever `default/0` is first threaded (**P-SEAM**).

---

### Pitfall 5: The S1 seam migration — uneven coverage and byte regressions across the recipe blast radius

**What goes wrong:**
The milestone brief says "migrate 8 recipes from literal `palette(opts)` defaults to `theme.colors.*` while keeping the toy/default calls byte-identical." **The codebase does not actually match that premise, and assuming it does is the pitfall.** Audit of the shipped recipes:

| Recipe | S1 `palette` seam present? | Inline `{r,g,b}` literals not behind the seam |
|--------|---------------------------|----------------------------------------------|
| `invoice` | ✅ (Phase 115) | 0 (the 7 literals are the role defaults *inside* `palette/1`) |
| `payslip` | ✅ (Phase 116) | 0 |
| `ticket` | ✅ (Phase 116) | 0 |
| `statement` | ❌ | 2 inline literals |
| `certificate` | ❌ | 3 inline literals |
| `receipt` | ❌ | 0 (little/no color) |
| `branded_invoice` | ❌ | 0 (font+logo branding, own color story) |

Only **3 of 7 recipes are seam-ready** for a one-line `palette(opts)` → `theme.colors.*` swap. Statement and Certificate still inline color literals with **no seam at all**. If Milestone B treats all recipes as "just swap the seam," Statement/Certificate get either (a) skipped (un-themable — the "fully themable" claim becomes false) or (b) hastily retrofitted *and* swapped in the same commit, mixing two change kinds and risking byte regressions on recipes that never had a byte-identity golden for their color output.

**Why it happens:**
Milestone A's S1 seam was scoped to the recipes A actually touched (Invoice in 115, the two new families in 116). The "8 recipes" framing in the B brief over-generalizes A's partial seam coverage into a uniform starting state.

**How to avoid:**
- **Two-step, per-recipe, never combined:** (1) *retrofit* the `palette(opts)` seam into Statement/Certificate/Receipt/BrandedInvoice with defaults = today's exact literals, proven **byte-identical** by a fresh sha256 golden before any theme wiring; then (2) *swap* `palette(opts)` → `theme.colors.*` where the default theme reproduces those same defaults. Mirror Milestone A's "split the verbatim move from the normalization" discipline (Pitfall-6 idiom from A).
- **Golden the default/toy call for every recipe before touching it.** Compute goldens by *actually rendering pristine code* (`mix run`) and embedding the sha256 — never hand-type a hash (Phase-115 D-note: hand-typed goldens silently freeze wrong bytes).
- **The default theme's role values must equal each recipe's current literals**, so `document(data)` (no `theme:`) is a byte-identity no-op across all 7 recipes. This is the single most important regression guard of the milestone.
- **`page_template/1` `Keyword.take` whitelist stays open at the top level** so `theme:` threads additively (already established in Phase 115). Confirm the whitelist for the 4 un-seamed recipes admits `:theme` without dropping it.

**Warning signs:**
- A recipe without a pre-existing color golden gets a theme swap.
- A single commit both introduces `palette/1` *and* replaces it with `theme.colors.*`.
- `document(data)` (no theme) produces different bytes than the shipped v2.10 render for any recipe.
- Statement/Certificate remain un-themable at milestone end (breaks "fully themable").

**Phase to address:** **P-SEAM** (retrofit-then-swap, per-recipe byte-identity goldens, `theme:` threading through all 7 recipes' 3 rungs).

---

### Pitfall 6: "Fixing" the Phase-118 rubric gap by cranking the theme instead of fixing the data transform

**What goes wrong:**
This is the folded-in SHOW-01 gap and the **highest-risk remediation trap.** Phase 118 honestly scored all six v2.10 demos `passed: false`: the root cause recorded in STATE.md is **data/transform**, not color — `transform_invoice` *drops parties and totals*, and other demos *fail to make the one key fact dominant* (the rubric's hierarchy dimension MUST score 5). The trap: a theming milestone makes it seductive to "improve" the demos by applying a slick accent palette, a bigger display size, or dark mode, declare them prettier, and mark the rubric passed — **without fixing the underlying transform that drops the invoice's parties/totals or the hierarchy that never anchors the one key fact.** That is overclaiming a rubric pass; it re-commits the exact honesty violation Phase 118 refused to commit (it *paused* rather than score dishonestly).

**Why it happens:**
The milestone's tool is theming, so every problem looks like a theming problem. A better palette genuinely raises the "typographic craft" and "restraint/cohesion" rubric dimensions — but those were not the failing dimensions. Hierarchy and information-architecture failures come from *what data is present and what is emphasized*, which theming cannot fix.

**How to avoid:**
- **Fix the transform first, theme second.** The remediation phase must (1) repair `Rendro.ExamplesData.transform_invoice` so parties + totals reach the recipe, and enrich the other transforms so the anchor fact (invoice total, net pay, seat/gate) is *present and structurally emphasized*; (2) *then* apply `default/0`. Sequence matters: a themed-but-data-broken demo is still a fail.
- **Hierarchy = 5 is achieved by structure, not color.** The key fact becomes dominant via size/placement/whitespace (the type-scale's `display` step + a totals box kept with last rows), which is layout, not palette. Verify against the rubric's non-designer anchors, honestly.
- **Re-use the shipped honesty machinery.** Phase 118 encoded the ceiling as machine-checked data (`demonstration_set.boundaries` disclaiming rubric-pass, plus the D-14 accessibility-overclaim tripwire). Rubric scores are an *appendable* manifest (S5); scores are only committed when the render *honestly* clears `hierarchy = 5, core ≥ 4, gates pass`. Do not weaken the threshold arithmetic to make demos pass.
- **A human sign-off gate on the rubric scores**, as Phase 118 required (the scoring was container/human-gated and deliberately not auto-committed).

**Warning signs:**
- A rubric score flips to `passed: true` in the same commit that only changed colors/mode.
- `transform_invoice` still drops parties/totals but a demo is marked passing.
- Anyone proposes "dark mode makes it look premium" as the hierarchy fix.
- The `boundaries` disclaimers are deleted rather than the underlying gap closed.

**Phase to address:** **P-DEFAULT** (transform enrichment → make key fact dominant → then apply default theme → honest rubric re-score with human sign-off).

---

### Pitfall 7: Over-scoping the token contract with non-deterministic web concepts

**What goes wrong:**
A "themable" API invites the full web design-token vocabulary: `shadow`/elevation, `gradient`, `opacity`/alpha, `z-index`, `motion`, `focus`/`hover`/selection, grid max-widths. **None of these map to Rendro's deterministic PDF model** (no native shadow/gradient/vector-alpha; draw-order-only, no z-index; a static document has no motion or focus). Adding them to `%Theme{}` — even as "honored later" fields — either (a) forces a faithless render (a fake shadow via a gray rect, a fake gradient via banding) that violates the determinism/craft posture, or (b) freezes dead fields into the public struct that can never be honored, permanently.

**Why it happens:**
Brand token files (including the project's own `brand/tokens/tokens.json`, which is a *web* token set) contain these keys. Mining that file for `{r,g,b}` values (the intended use) risks importing its shadow/gradient/opacity keys wholesale. "Design parity with CSS" feels like completeness.

**How to avoid:**
- **The exclusion is permanent and explicit** — SEED-003 locks it: shadow/elevation, z-index, motion, focus/hover, opacity/gradient are *out of the contract, forever.* Express elevation flatly (a `surface` tint + a `rule` hairline), not with a shadow token.
- **Mine `brand/tokens/tokens.json` for `{r,g,b}` only**, converting hex→tuple at the boundary; ignore every non-color/non-typography key. `brand/tokens/tokens.json` stays Hex-excluded (it already is).
- **Document the exclusions as a first-class part of the contract** ("what a theme deliberately does NOT control"), the same honest-boundary discipline used for accessibility/viewer claims. A named exclusion is a feature, not a gap.
- **The struct only contains fields that map cleanly**: colors, fonts, scale, leading, widows/orphans, spacing (points), rules (widths), radius, density. If a proposed field can't render deterministically and faithfully, it doesn't go in.

**Warning signs:**
- A PR adds `shadow`, `elevation`, `gradient`, `opacity`, `z_index`, or `blur` to `%Theme{}`.
- Any render approximates a shadow/gradient with rects or banding.
- The hex→tuple mining step copies keys other than colors from `tokens.json`.

**Phase to address:** **P-DEF** (struct shape excludes web concepts by construction; exclusions documented).

---

## Moderate Pitfalls

### Pitfall 8: Boundary erosion — theming pulls industry/brand assumptions into `lib/`, or Milestone C scope bleeds into B

**What goes wrong:**
Two related erosions of hard-won boundaries:
1. **Family-not-industry / "brands are data" erosion.** A theme that ships industry presets ("legal theme," "medical theme"), or that hardcodes a specific company's palette into `lib/`, breaks the locked boundary: *design systems = code, brands = data.* `Theme` must be pure presentation and industry-agnostic. `brand:` (who — logo + font files) stays orthogonal to `theme:` (how — tokens).
2. **Milestone C creep.** SEED-003 explicitly defers style-genre *presets*, a public *catalog*, a static *configurator*, and *curated preset fonts* to Milestone C (SEED-004), and the live Studio to D. B builds the *contract and default*; the moment B starts shipping named preset themes or a catalog, it has absorbed C's scope and destabilized its own API before it's proven.

**Why it happens:**
"Themable" naturally suggests "ship some themes." A single `from_brand/2` helper feels like it wants companion preset themes. The 4-milestone program's boundaries are easy to blur under one theming banner.

**How to avoid:**
- **B ships exactly one theme: `default/0`** (a restrained neutral-ink Swiss-ish palette — *not* everything-is-blue), plus `from_brand/2` + a single `accent:` seed so "plug in my palette" is one color. No named genre presets, no catalog, no configurator.
- **`Theme` is industry-agnostic by construction** — no industry names, no company palettes in `lib/`. Brand values arrive as *data* via `from_brand/2`, mined from a caller's tokens, never baked in.
- **A `lib/` grep guard** (mirroring the existing branding-claims / accessibility tripwires) that fails if `lib/rendro/theme.ex` references an industry or a named brand.
- **S4/S6 seams already absorb C's future needs** (empty `brand`/`logo` fixture slot; optional `theme`/`mode`/`preset` artifact tags) — so B does not need to build C's surfaces to stay forward-compatible.

**Warning signs:**
- A named preset theme (`Theme.legal/0`, `Theme.corporate/0`) appears in B.
- An industry string or specific company palette lands in `lib/`.
- A catalog/configurator/preset-font PR opens under the B milestone.

**Phase to address:** **P-DEF** (single `default/0` + `from_brand/2`; industry-agnostic guard). Scope-fence enforced at milestone-planning time.

---

### Pitfall 9: Manifest / contract drift — the "surprise red build" class

**What goes wrong:**
Adding a public module + threading it through recipes touches every machine-checked manifest and contract lane Rendro enforces. Forgetting any one produces a red build that looks unrelated to the change:
- **`priv/public_api.json` not regenerated** — a new public `Rendro.Theme` (+ any public functions: `resolve/1`, `default/0`, `dark/1`, `from_brand/2`) makes `public_api_contract_test.exs` fail with a two-list drift diff until `mix rendro.api.gen` is run.
- **Hidden-set / tier-tag edits** — `Theme` needs its `@moduledoc tags: [:adapter]` tag; every public fn needs an `@spec` (the contract lane asserts stable-tier fns have specs and every module carries exactly one tier tag). Milestone A's `Format` promotion is the precedent: STATE.md flags editing the Phase-79 hidden set as "the likeliest surprise red build," and Phase 115 found a *second, plan-unlisted* duplicate hidden-modules assertion in `manifest_test.exs`. Expect a deliberate red build until tags + hidden set are reconciled.
- **`priv/support_matrix.json` rows missing** — every public claim must be proof-backed; a `theming` (colors/light-dark/typography) row with resolvable test evidence is required, matched by `recipes_claims_test.exs`-style assertions. No row ⇒ overclaim.
- **Docs-contract lanes** — new `Theme` claims in README/HexDocs/guides must be bounded by the docs-contract lanes; an unbacked claim fails CI.
- **Tarball allowlist** — if any theme asset ships, the exact-allowlist tarball audit must admit it; if nothing new ships, confirm no accidental inclusion.

**Why it happens:**
The manifests are enforced by lanes that run late; the failure surfaces as a cryptic drift diff far from the code change. Milestone A hit exactly this and it's the best-documented "expected red build" in the project.

**How to avoid:**
- **A P-CLOSE checklist**, run as acceptance criteria: `mix rendro.api.gen` regenerated + committed; `Theme` tier tag + all `@spec`s present; hidden-set/manifest assertions reconciled (grep for *all* hidden-modules assertions, not just the one the plan lists — Phase 115's lesson); `support_matrix.json` theming rows with resolvable evidence + matching claims test; docs-contract lanes green; tarball audit green.
- **Expect and pre-declare the red build** — treat the manifest reconciliation as a known, deliberate step (STATE.md already carries this watch-item pattern), not a surprise.
- **`@spec` every public `Theme` function** up front (the contract lane requires it for stable-tier; adapter-tier still benefits and avoids a later gap).

**Warning signs:**
- `public_api_contract_test.exs` or `manifest_test.exs` red after adding `Theme`.
- A theming claim in docs/README with no `support_matrix.json` row.
- `mix rendro.api.gen` output differs from committed `priv/public_api.json`.

**Phase to address:** **P-CLOSE** (manifest regen, tier tags/specs, support-matrix rows, docs-contract + tarball reconciliation). Partial reconciliation also lands in **P-DEF** (the tier tag + first manifest entry ship with the struct).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Ship a *partial* `%Theme{}` struct (only wired tiers) | Less to define now | Widening = breaking change on a 1.0 lib; forces major bump in C | **Never** — define full shape, implement in tiers (SEED-003 lock) |
| Skip the retrofit; theme only the 3 seam-ready recipes | Faster; touches less code | "Fully themable" claim is false; Statement/Certificate un-themable | Never — but retrofit can be its own sub-phase |
| Combine `palette` retrofit + `theme.colors.*` swap in one commit | One PR per recipe | Mixes two change kinds; byte regressions on recipes with no prior color golden | Never — split verbatim/normalize (Milestone-A idiom) |
| Derive dark `surface`/`on_accent` via float tint at draw time | "Nicer" dark palette | Non-deterministic bytes; breaks the flagship guarantee | Never at draw time — do it once in `resolve/1`, store integers |
| Mark demos rubric-passed after a palette refresh | Milestone "looks done" | Overclaim; re-commits the Phase-118 honesty violation | Never — fix transform/hierarchy first |
| Add `shadow`/`gradient` as "honored later" fields | CSS parity feel | Dead frozen fields that can never render faithfully | Never — permanently excluded |
| Ship dark mode as a demo/default | "Premium" look | Print footgun; contrast failures; harms readers | Never for default/demos — dark is an available, screen-only mode |
| Hand-type a golden sha256 | Fast | Silently freezes wrong bytes | Never — render pristine code and embed the computed hash |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `brand/tokens/tokens.json` (web token source) | Import shadow/gradient/opacity keys along with colors; or start shipping the file | Mine `{r,g,b}` only, hex→tuple at the boundary; file stays Hex-excluded |
| `FontRegistry` (font-role resolution) | Silently fall back to Helvetica when a theme font role is unregistered | Propagate the existing typed `{:unknown_text_font, _}` / raise instructive `ArgumentError`; deliberate fallback only if registered + logged (Payslip B612 pattern) |
| `Recipes.Pagination` (keep-with-last-rows) | Theme changes body size → break points move → totals/CF-BF logic misfires | `default/0` is a metric no-op; any size override re-runs the stress matrix + determinism gate |
| paginate stage (continuation pages) | Attach dark background in `sections/2` → pages 2..N render white | Attach background in `page_template/1` (applied to every physical page) |
| `priv/public_api.json` / `mix rendro.api.gen` | Forget regen; miss a duplicate hidden-modules assertion | Regenerate + commit; grep for *all* hidden/tier assertions (Phase-115 lesson) |

## Security / Safety Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Accidentally ship `brand/tokens/tokens.json` when mining it | Leaks project brand internals into Hex; bloats tarball | Keep Hex-excluded; exact-allowlist tarball audit stays green |
| Bake a specific company/industry palette into `lib/` | Breaks "brands are data"; ships someone's brand as code | Industry-agnostic guard; brand values arrive via `from_brand/2` data |
| Claim dark PDFs are print-safe or accessibility-conformant | Overclaim; user prints ink-flooded/invisible doc; false a11y claim | Honest dark-print boundary in docs + support matrix; D-14 accessibility-overclaim tripwire holds |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| `default/0` is "everything-is-blue" | Generic, un-premium; every adopter's doc looks the same | Restrained neutral-ink Swiss-ish default that clears the rubric on its own |
| Dark mode as default or in demos | Print footgun; possible invisible text on page 2 | Light default + light demos; dark is opt-in, screen-oriented |
| `theme:` requires many keys to plug in a brand | High friction; adopters won't bother | `from_brand/2` + single `accent:` seed = one-color brand adoption |
| Un-themable Statement/Certificate | "Fully themable" promise feels broken | Retrofit S1 seam into all recipes before claiming full themability |

## "Looks Done But Isn't" Checklist

- [ ] **`%Theme{}` struct:** Often missing the *full shape* — verify `spacing`/`rules`/`radius`/`density` fields exist even if only default-honored (C must append values, never fields).
- [ ] **Default theme:** Often not a byte-identity no-op — verify `document(data)` (no `theme:`) reproduces v2.10 bytes for **all 7 recipes** via fresh sha256 goldens.
- [ ] **Dark mode:** Often only page-1 tested — verify a **multi-page** dark render fills the background on pages 2..N and passes the **two-run** determinism gate.
- [ ] **Font roles:** Often silently substituting — verify an unregistered theme font role raises the typed error, never falls back silently.
- [ ] **Type scale:** Often shifts pagination — verify Phase-117 stress goldens are unchanged under `default/0`.
- [ ] **S1 coverage:** Often assumed uniform — verify Statement/Certificate/Receipt/BrandedInvoice were retrofitted with the seam (only invoice/payslip/ticket had it).
- [ ] **Rubric demos:** Often "passed" via palette not data — verify `transform_invoice` no longer drops parties/totals and hierarchy = 5 is structural, with human sign-off.
- [ ] **Manifests:** Often stale — verify `mix rendro.api.gen` regenerated, `Theme` adapter-tier tag + specs, support-matrix theming rows with evidence, docs-contract + tarball lanes green.
- [ ] **Exclusions:** Often creeping — verify no `shadow`/`gradient`/`opacity`/`z-index`/`motion`/`focus` field in `%Theme{}`.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Shipped a partial `%Theme{}` and need a new field | **HIGH** | Major version bump + migration doc; the whole point of P-DEF is to never be here — define full shape up front |
| Dark mode nondeterministic bytes | MEDIUM | Move all color math into `resolve/1`, store integer `{r,g,b}`; re-bless per-mode goldens after fix |
| Dark background missing on continuation pages | LOW–MEDIUM | Move the background fill from `sections/2` to `page_template/1`; add a multi-page dark golden |
| S1 swap regressed byte output on an un-seamed recipe | LOW | Revert; retrofit seam as a separate byte-identical commit first, then swap |
| Demos marked rubric-passed dishonestly | MEDIUM | Revert the scores (they're an appendable manifest); fix `transform_invoice` + hierarchy; re-score with human sign-off |
| Web-concept field frozen into the struct | HIGH | Requires major bump to remove; avoid by excluding at P-DEF |
| Manifest drift red build | LOW | `mix rendro.api.gen`; reconcile all hidden/tier assertions + support-matrix rows (expected, pre-declared step) |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. Wrong `%Theme{}` shape frozen | **P-DEF** | `%Theme{}` defines all tiers' fields; adapter-tier tag; no named sub-types in `public_api.json` diff |
| 2. Dark mode breaks determinism | **P-DARK** | Per-mode `assert_deterministic!` green; multi-page dark golden shows bg on page 2 |
| 3. Dark contrast/print footgun | **P-DARK** + **P-DEFAULT** | Contrast-ratio test on swapped role pairs (both modes); default + demos are light; honest dark-print boundary in docs/matrix |
| 4. Type-scale fights pagination; silent font substitution | **P-TYPE** (+ **P-SEAM**) | Phase-117 stress goldens unchanged under `default/0`; unregistered font role raises typed error |
| 5. S1 seam migration blast radius | **P-SEAM** | All 7 recipes seam-ready + byte-identical default goldens; retrofit split from swap |
| 6. Rubric gap "fixed" by theming | **P-DEFAULT** | `transform_invoice` restores parties/totals; hierarchy = 5 structural; scores committed only on honest pass + human sign-off |
| 7. Over-scoping with web concepts | **P-DEF** | No excluded field in `%Theme{}`; exclusions documented; token mining is color-only |
| 8. Boundary erosion / C creep | **P-DEF** + planning fence | Single `default/0` + `from_brand/2`; industry-agnostic `lib/` guard; no presets/catalog in B |
| 9. Manifest/contract drift | **P-CLOSE** (+ **P-DEF**) | `mix rendro.api.gen` committed; tier tags/specs; support-matrix rows w/ evidence; docs-contract + tarball green |

## Sources

- Rendro codebase (HIGH — direct read): `lib/rendro/recipes/{invoice,payslip,ticket,statement,certificate,receipt,branded_invoice}.ex` (S1 palette-seam audit — only 3/7 recipes seam-ready), `lib/rendro/color.ex` (`format_num` 4-decimal rounding; hex-footgun validation), `lib/rendro/text.ex` (`line_height: 1.2` multiplier, `widows/orphans: 2` defaults, no native leading), `lib/rendro/pipeline/build.ex` (typed `{:unknown_text_font, _}` font-resolution errors — no silent substitution), `lib/rendro/font_registry.ex`.
- `.planning/PROJECT.md` — v2.11 milestone goal, constraints (determinism, locale-free, no PDF-UA claims, proof-backed claims), Key Decisions (Format promotion, seams).
- `.planning/seeds/SEED-003-document-theming-token-system.md` — locked theme design, full-shape-up-front discipline, permanent exclusions, brand-vs-theme orthogonality, `tokens.json` mining.
- `.planning/research/milestone-a/SUMMARY.md` — the single-irreversible-act (`Format`) precedent; S1/S4/S5/S6 seams; the reader-quality rubric (hierarchy = 5).
- `.planning/STATE.md` — Phase-118 SHOW-01 findings (`transform_invoice` drops parties/totals; all 6 demos `passed:false`, D-11), Phase-115 duplicate hidden-modules assertion lesson, hand-typed-golden warning, Payslip deliberate-fallback pattern.

---
*Pitfalls research for: adding a public `Rendro.Theme` design-token contract to a deterministic 1.0 PDF engine (Milestone B / v2.11)*
*Researched: 2026-07-19*

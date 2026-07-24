# Phase 119: `Rendro.Theme` core module (the one-way door) - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship `lib/rendro/theme.ex` — the full public `Rendro.Theme` value contract: a pure,
inert design-token value (color roles + typography + spacing + rules + radius +
density + mode) resolved once via `resolve/1` · `default/0` · `dark/1` ·
`from_brand/2`, on the **adapter/Evolving** tier. **Zero recipe change this phase** —
every existing v2.10 golden is untouched. This is the milestone's only one-way door:
once `%Theme{}` ships, its **field set and nesting shape** become an observable public
contract. Requirements: THEME-01..04, COLOR-01/02, CONTRACT-01, CONTRACT-03.

**In scope:** the struct + resolver + default/dark/from_brand constructors, web-concept
exclusions by construction, the industry-agnostic `lib/` guard, adapter-tier registration
in `priv/public_api.json` + the planned red→green `public_api_contract_test.exs`
reconcile, pure unit tests only.

**Out of scope (later phases / milestones):** any recipe wiring / `theme:` threading
(Phase 120), the background-fill / dark mechanism (Phase 121), typography application into
`%Text{}` (Phase 122), `default/0` rubric-closure tuning + gallery/docs + support-matrix
rows (Phase 123). Genre presets, catalog, configurator (Milestone C), Studio (D).

**Frozen-shape vs Evolving-values distinction (load-bearing for this phase):** Phase 119
freezes the **field shape** (names, group keys, arities, nesting) forever. The **token
values** below (default palette, type-scale numbers, leading) are the recommended
*starting* values on the Evolving tier — locked as recommendations, tunable at rubric
closure (Phase 123) without a cross-version break. Downstream agents: implement the shape
exactly; treat the values as defaults to ship now and refine later.

</domain>

<decisions>
## Implementation Decisions

Deep multi-lens research (4 parallel agents: Elixir/Phoenix idioms, W3C DTCG / Material 3 /
Tailwind / Radix / Bootstrap prior art, typographic-scale theory, WCAG luminance, Swiss
document design) produced ONE coherent, cross-checked design. All four decisions below fit
together; two intentional reconciliations are noted at the end.

### D-01 — Frozen `%Theme{}` shape (THEME-01, the contract)
- **One** adapter-tier public struct `Rendro.Theme`. Token GROUPS are **bare typed maps**,
  NOT nested public structs. Rationale: matches the existing S1 seam (recipes already read
  `colors.ink` from a plain map → zero call-site churn); keeps `public_api.json` to one
  module (nested structs each become their own Hyrum surface + `@type` + tier tag);
  widening later is a non-breaking `Map.put`/`Map.merge`; nesting capped at two levels
  (`theme.typography.scale.body`).
- **`@enforce_keys []`** (stated explicitly — intentional empty set so every future field,
  always defaulted, is a non-breaking addition). Construct ONLY via `resolve/1` /
  `default/0` / `dark/1` / `from_brand/2`. A bare `%Rendro.Theme{}` equals the light
  default (defaults live in module attributes shared by `defstruct` and `default/0`) — no
  half-nil trap.
- **`resolve/1` is idempotent**, deep-merges any input (keyword/map/`%Theme{}`) onto the
  defaults (partial input never yields a draw-time `KeyError`), and validates **every**
  color role via `Rendro.Color.validate/1`, raising the instructive errors-as-product error
  on a bad token (THEME-02). Because it's idempotent, defensively re-resolving at each of
  the 3 recipe rungs (Phase 120) is free.
- **The complete frozen field set** (freeze all of this NOW, even shallowly-honored tiers):
  - `colors:` `%{ink, muted, accent, on_accent, background, surface, rule, positive, negative}`
    — all 9 **always present** with integer `{r,g,b}` (positive/negative ship with real
    values, never nil — absence must never become an observable contract).
  - `typography:` `%{fonts: %{heading, body, mono}, scale: %{display, title, subtitle, body,
    small, caption}, leading, widows, orphans}`. `fonts` roles are logical `FontRegistry`
    atoms; `scale` steps are explicit points (materialized numbers, never a `:math.pow`
    formula — TYPE-01); `leading` is a line-height **multiplier** (matches `Text.line_height`
    1.2 semantics), `widows`/`orphans` are `non_neg_integer()`.
  - `spacing:` `%{unit, tight, normal, loose, section}` — points (semantic named steps, NOT
    a Tailwind-style numbered scale that would leak raw units into the contract).
  - `rules:` `%{hairline, thin, thick}` — stroke widths in points.
  - `radius:` `%{none, sm, md}` — corner radii in points.
  - `density:` `:comfortable | :compact` — a bare atom (smallest complete shape; `resolve/1`
    honors it shallowly in B by nudging leading/spacing, deepens in C with no field change).
  - `mode:` `:light | :dark` — a bare atom.
- **`@type t` + a `@type` per group** (rgb, font_role, type_step, colors, typography,
  spacing, rules, radius). `@spec` on every public function (THEME-03).

### D-02 — Excluded-by-construction (THEME-04, the industry/web-concept guard)
- Web concepts that do not map to deterministic PDF appear as **no field at all** (never
  even "for future use"): shadow/elevation, z-index, motion, focus/hover/selection,
  opacity/gradient, raw color scales (Radix 12-step), numeric weight axis, letter-spacing,
  wide-gamut color. Honest guidance in the moduledoc: express elevation flatly via
  `surface` tint + `rule` hairline.
- **Industry-agnostic `lib/` guard** (CONTRACT-03, mirroring the branding/accessibility
  tripwires): a test fails if `theme.ex` references any industry or named brand. B ships
  exactly one theme (`default/0`) + `from_brand/2` — no genre presets, catalog, configurator.

### D-03 — Type scale + leading (values; TYPE-01, Evolving)
- **Locked ramp (tuned):** `%{display: 21, title: 16.5, subtitle: 13, body: 10.5, small: 9,
  caption: 8}` (points). Monotonic adjacent ratios 1.125 → 1.273 (no step reaches the
  editorial 1.333); **display:body = 2.0×** for clean, restrained hero dominance.
- This is a **tuned third ramp**, chosen over the two prior research proposals. It fixes two
  real defects in the REQUIREMENTS draft (`8/9/10.5/12.5/16/22`): subtitle 12.5 was only
  1.19× body (collapses into body → raised to 13 = 1.24×); title 16 → display 22 was a 1.375
  editorial spike in an otherwise-restrained ramp (retuned to 16.5 → 21 = 1.273). Rejected
  the STACK proposal (`display 28`) as SaaS-hero + editorial mid-ratios — reserve drama for a
  Milestone-C Editorial preset. Body 10.5 = dead-center of business-doc convention (LaTeX
  10/11/12; the recipes' own literal 10–11); caption 8 respects the print legibility floor.
- **`default/0` ships `leading: 1.2`** (not the brand's generous 1.35) so TYPE-03's
  metric-no-op is trivially true — the engine default is 1.2, so existing goldens are
  untouched. The generous **1.35** is the documented tuning target realized on role-reading
  prose blocks at rubric closure (Phase 123, within-version re-bless). See reconciliation R1.
- All values are integers or single decimals → byte-reproducible; no `:math.pow` irrationals
  in the shipped map.

### D-04 — `on_accent` derivation (COLOR-02)
- **Auto-derive** via WCAG max-contrast between the accent and the theme's two neutral poles
  (`background` vs `ink`) — pick whichever pole has the greater contrast ratio against the
  accent. Equivalent to the single-threshold spelling "relative luminance > **0.179** → dark
  pole, else light pole" (0.179 is derived, not guessed: it's where black/white contrast is
  exactly equal, `√(1.05·0.05) − 0.05`). Prior art: Bootstrap `color-contrast()`, Material 3
  `on-*` tones.
- **Return one of the theme's own token tuples** (background/ink), NOT raw white/black — keeps
  the accent chip native to the page and makes dark mode a free integer swap. Auto by default;
  **explicitly overridable** via `on_accent:` in `from_brand/2` and `resolve/1` (an override is
  respected, never silently recomputed).
- **Determinism:** the luminance floats pick a branch only; the OUTPUT is always an integer
  tuple resolved once in `from_brand/2`/`resolve/1` — no float reaches the byte stream.
- **Claims discipline:** word it as a "sensible readable default," **NEVER** a WCAG-AA/AAA or
  PDF-UA conformance claim. Note honestly that mid-tone accents may miss 4.5:1 either way and
  point to the override. Keep `on_accent_for/*` (+ `luminance`, `contrast_ratio`, `linearize`)
  private / `@doc false`.

### D-05 — `default/0` mined-Swiss palette (values; DEFAULT-01, COLOR-01, Evolving)
Commits to the `brand/tokens/tokens.json` **warm-paper / cool-ink** system (coherent print
pairing), not flat pure-black — "looks strong on its own" is the whole point of a mined
default. Light roles + dark-mode swap targets (all integer `{r,g,b}`, hex→tuple at the
authoring boundary via `Base.decode16!`):

| role | light | source | dark swap | dark source |
|---|---|---|---|---|
| ink | `{16,24,39}` | ink-900 `#101827` | `{242,236,224}` | paper-d-50 |
| muted | `{91,101,115}` | ink-500 `#5B6573` | `{150,143,126}` | paper-d-400 |
| accent | `{44,107,237}` | blue-600 `#2C6BED` | unchanged | — |
| on_accent | `{255,255,255}` | sheet-000 | unchanged | — |
| background | `{255,255,255}` | sheet-000 | `{27,23,19}` | night-800 |
| surface | `{247,243,234}` | paper-100 `#F7F3EA` | `{35,32,25}` | night-700 |
| rule | `{196,188,169}` | line-400 `#C4BCA9` | `{74,68,57}` | night-400 |
| positive | `{20,122,75}` | green-700 `#147A4B` | `{63,179,127}` | green-300 |
| negative | `{194,65,50}` | red-700 `#C24132` | `{224,113,95}` | red-300 |

- **`background` = pure white is essentially forced**, for two convergent reasons: (1)
  MODE-02 (Phase 121) gates the dark background-fill rect on `background != {255,255,255}` and
  requires the light default to emit **no rect** and stay byte-identical to v2.10 — a tinted
  page would trip it; (2) a full-page paper wash prints as an all-over ink coverage. The warm
  brand character lives in **`surface`** (bands/cards), not the page. Do NOT tint `background`.
- `rule` = line-**400** (not line-300, which vanishes at ~1.5:1 on white). ink-on-white 17.8:1;
  muted 5.9:1; `rule` intentionally quiet ~1.9:1 (separator, not a graphic). Keep `surface`+`rule`
  both warm (paper/line family) and `ink`+`accent` both cool — never mix per-role or the
  warm/cool pairing breaks.
- `fonts` default = `%{heading: :default, body: :default, mono: :default}` — `:default` is the
  FontRegistry always-registered built-in (Helvetica-compatible, verified), so `default/0`
  never raises `{:unknown_text_font, _}` with no fonts registered. Recipes that register real
  fonts set their own role atoms (Phase 122).

### D-06 — Public-API contract reconcile (CONTRACT-01, the surprise-red-build class)
- `Rendro.Theme` enters `priv/public_api.json` on the **adapter** tier via `mix rendro.api.gen`;
  `@moduledoc tags: [:adapter]` + a doc note "field shape is stable; token values and rendered
  bytes may evolve." All derivation helpers (`on_accent_for`, dark-swap, hex→tuple, normalize)
  stay `defp`/`@doc false` so hidden-internals assertions stay green.
- **Pre-declared planned red→green step:** `public_api_contract_test.exs` byte-compares a
  regenerated manifest, so it red-builds until the gen runs. **Grep ALL hidden-modules
  assertions, not just the one the plan lists** — Phase 115's lesson was a *second,
  plan-unlisted* duplicate hidden-modules assertion in `manifest_test.exs`. Reconcile every one.

### Reconciliations (intentional coherence calls across the 4 decisions)
- **R1 — Leading:** `default/0.leading = 1.2` (metric no-op, honors TYPE-03 literally) wins over
  the brand book's generous 1.35, which becomes a Phase-123 rubric-closure target on role-reading
  prose blocks (re-bless within version).
- **R2 — Dark `on_accent`:** kept **white** in dark mode (accent fill is unchanged blue-600 → the
  chip reads identically in both modes), rather than re-deriving to paper-d-50. The general
  max-contrast derivation (D-04) is the rule for arbitrary `from_brand/2` accents; for the fixed
  default it resolves to white in both modes.

### Claude's Discretion
User asked for a one-shot, coherent, locked recommendation set ("so i dont have to think") —
all five presented gray areas were decided by research, not deferred. Remaining freedom for the
planner: exact `defp` helper names, `@type` phrasing, `density :compact` shallow-honoring mechanics
in `resolve/1`, and the exact moduledoc prose (must carry the stability note + flat-elevation
guidance).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone locks & requirements
- `.planning/REQUIREMENTS.md` — THEME-01..04, COLOR-01/02, CONTRACT-01/03 (Phase 119 rows);
  "Open Questions for Phase Planning" (now resolved by decisions above).
- `.planning/ROADMAP.md` §"Phase 119" — goal, depends-on, 5 success criteria.
- `.planning/research/milestone-b/SUMMARY.md` — locked cross-lens decisions; the "single
  irreversible act" (adapter-tier reasoning); the S1-seam 3-of-7 audit; the
  `public_api_contract_test.exs` red→green + duplicate-hidden-assertion lesson;
  light/dark determinism mechanism; type-scale-as-explicit-points.
- `.planning/PROJECT.md` §"Current Milestone: v2.11" + "Key Decisions" — family-not-industry
  boundary, engine-untouched, brand⊥theme, no-overclaim culture.

### Design source of truth
- `brand/tokens/tokens.json` — `raw` + `semantic.light` + `semantic.dark` blocks; the `{r,g,b}`
  values mined for `default/0` and `dark/1`. **This is the token source of truth — mine it, don't
  invent values.** (web-only, excluded from Hex — hex→tuple at the boundary.)
- `prompts/Rendro Brand Book.txt` — §9 Typography (type scale, "clear hierarchy / generous
  line-height", avoid "huge SaaS hero typography"), §"Color Ratios by Brand Role" (60% paper /
  25% ink-line / 10% blue / 5% semantic; "own an ink/paper/blue system", not purple-heavy).

### Code the module must integrate with (read before planning)
- `lib/rendro/recipes/invoice.ex` (~L466 `palette/1`) — the existing S1 role→`{r,g,b}` seam the
  struct is a drop-in for.
- `lib/rendro/color.ex` — `validate/1` (the per-role validator `resolve/1` calls) + color format
  helpers (float determinism context).
- `lib/rendro/text.ex` (~L14) — `%Text{}` fields (`size`, `font`, `line_height` 1.2, `widows`/
  `orphans` 2) the typography defaults must be metric no-ops against.
- `lib/rendro/font_registry.ex` — logical font roles; `@default_font :default` built-in;
  `{:unknown_logical_font, _}` → `{:unknown_text_font, _}` typed error path (via `build.ex:111`).
- `priv/public_api.json` + `mix rendro.api.gen` (`Mix.Tasks.Rendro.Api.Gen`) — manifest gen.
- `test/docs_contract/public_api_contract_test.exs` + `manifest_test.exs` — the hidden-modules
  assertions to reconcile (grep BOTH).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **S1 `palette/1` seam** (`invoice.ex`, `payslip.ex`, `ticket.ex`): already a bare
  role→`{r,g,b}` map with exactly the 7 core roles → the `%Theme{}.colors` map is a literal
  drop-in; zero call-site churn (this phase doesn't touch recipes, but it shapes the contract).
- **`Rendro.Color.validate/1`**: instructive `{:error, reason}` on non-`{r,g,b}` input — reuse
  as-is in `resolve/1`; no new validator needed.
- **`FontRegistry` `:default`/Helvetica built-in + `fallbacks:` chain + typed
  `{:unknown_text_font, _}` error**: font roles are just three logical atoms on the existing
  resolution path — no shape change, no silent Helvetica substitution.
- **`Base.decode16!` + binary match**: hex→`{r,g,b}` in ~2 lines at the authoring boundary.

### Established Patterns
- **Adapter/Evolving tier + explicit "output may evolve" note** (precedent: `Rendro.Format`
  Phase 115): `@moduledoc tags: [:adapter]`, `@spec` on every public fn, derivation helpers
  private/`@doc false`.
- **Planned red→green manifest reconcile** (precedent: Phase 115 `Format`): gen the manifest,
  reconcile every hidden-modules assertion — grep for duplicates.
- **`lib/` industry/brand tripwire guard** (precedent: branding/accessibility tarball tests):
  a test that greps `theme.ex` for industry/brand names and fails.
- **Integer-`{r,g,b}`-resolved-once determinism** (`Color.format_num` does
  `float_to_binary(n*1.0, decimals: 4)`): all color math resolves to integer tuples in
  `resolve/1`; `dark/1` swaps pre-resolved tuples; no draw-time transcendental color math.

### Integration Points
- **None into the engine this phase.** `%Theme{}` is a pure value; the deterministic pipeline
  (`build → compose → measure → paginate → render → validate`) never sees it. Recipe threading,
  background fill, and typography application are Phases 120–122. Phase 119 = new module + manifest
  entry + contract test reconcile only.

</code_context>

<specifics>
## Specific Ideas

- The user's directive: research all decision points deeply via subagents across every relevant
  lens (Elixir/ecosystem idiom, cross-language design-token prior art, DX/least-surprise, Swiss
  document design, typographic theory, WCAG luminance), and one-shot a **coherent, cohesive**
  locked recommendation set — API elegance from the *consumer's* perspective, principle of least
  surprise, hide backend guts, restrained brand-aligned aesthetics.
- Concrete "like X" anchors that emerged: Bootstrap `color-contrast()` / Material 3 `on-*` for
  `on_accent`; W3C DTCG composite typography token for the typography group shape; Tailwind
  `theme` (as an anti-pattern to avoid — numbered scales leak units); Swiss/International
  Typographic Style (Müller-Brockmann/Vignelli restraint) for `default/0`.
- Full per-decision research (pros/cons/footguns/worked examples) is preserved in
  `119-DISCUSSION-LOG.md`.

</specifics>

<deferred>
## Deferred Ideas

- **Generous `leading: 1.35`** on prose blocks → applied at Phase-123 rubric closure (re-bless),
  not baked into `default/0` (would risk the TYPE-03 metric-no-op).
- **`density: :compact` deep wiring** (real spacing/leading multipliers) → Milestone C; B honors
  it shallowly in `resolve/1` only.
- **Accent-as-text-on-dark** (blue-300 `#7FA9FF` token) → Milestone-C refinement; B keeps accent
  a fill with white text in both modes.
- **Genre presets, curated preset fonts, public catalog, static configurator** → Milestone C
  (`SEED-004`). **Live Studio playground** → Milestone D (`SEED-005`). Tabular figures / small-caps
  / OpenType features → demand-gated (need new engine primitives).
- **`default/0` value tuning + themed/dark gallery renders + support-matrix `theming.light`/
  `theming.dark` rows + `guides/theming.md`** → Phase 123 (CONTRACT-02, DEFAULT-02/03).

</deferred>

---

*Phase: 119-rendro-theme-core-module-the-one-way-door*
*Context gathered: 2026-07-24*

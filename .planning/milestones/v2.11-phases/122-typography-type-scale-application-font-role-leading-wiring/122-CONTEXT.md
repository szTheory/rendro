# Phase 122: Typography type-scale application + font-role/leading wiring - Context

**Gathered:** 2026-07-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Read `theme.typography.*` into `%Rendro.Text{size, font, line_height, widows,
orphans}` across all 7 recipes — the deferred typography read on the seam Phase
120 already plumbed (the whole resolved `%Theme{}` is threaded through every
recipe's 3 rungs; 120 read only `colors`, 122 reads `typography`). **No new
plumbing.** This is the milestone's biggest rubric-hierarchy lever and feeds the
Phase-123 rubric closure. Requirements: TYPE-01, TYPE-02, TYPE-03.

**In scope:**
- Thread the materialized named type scale (`display 21 / title 16.5 /
  subtitle 13 / body 10.5 / small 9 / caption 8`, frozen in Phase 119 D-03) into
  every recipe's `%Text{size}` via a `size: scale.<role>` seam (TYPE-01).
- Resolve font roles (`heading`/`body`/`mono`) through the existing
  `FontRegistry`; a theme referencing an **unregistered** font role raises the
  existing typed `{:unknown_text_font, _}` error and **never** silently
  substitutes Helvetica (TYPE-02) — proven by a dedicated raise-path test.
- Thread `leading` → `%Text{line_height}` plus `widows`/`orphans` from the theme
  onto text blocks (TYPE-03).
- Per-recipe **literal-default** type scale + font roles + leading that reproduce
  today's exact metrics on the no-theme path → Phase-117 stress goldens and
  Phase-120's 7 byte-identity goldens render byte-identically (TYPE-03 metric
  no-op).

**Out of scope (later phases / milestones):**
- `default/0` value tuning, the deferred `leading: 1.35` prose realization,
  themed/dark gallery re-renders, support-matrix `theming.*` rows,
  `guides/theming.md`, and the honest SHOW-01 rubric re-score → Phase 123.
- The `%Theme{}` value contract itself (Phase 119, untouched) and the color/
  background threading (Phases 120/121, untouched).
- Genre presets, curated preset fonts, tabular figures / small-caps / OpenType
  features → Milestone C+ (demand-gated on new engine primitives).

**Byte-identity mechanism is FORCED, not chosen** (mirrors Phase 120 D-01/D-02):
the no-theme path uses per-recipe **literal** typography defaults reproducing
today's exact sizes/fonts/leading; the theme's `typography` is read **only** when
a `theme:` opt is present. Confirmed safe: `test/support/edge_fixtures.ex` /
`edge_matrix_test.exs` render **un-themed** (no `theme:` opt), and the 7 recipe
byte-identity goldens are `document(data)` no-theme renders — so preserving the
no-theme literals keeps every existing golden green with **zero re-bless**.

</domain>

<decisions>
## Implementation Decisions

User directive: research-first, one-shot — all 3 gray areas decided by analysis
and locked (per the settled Rendro posture and the Phase 119/120/121 precedent of
zero-deferral locked recommendations). The core mechanism was forced by the
byte-identity guard, not open for choice.

### D-01 — Per-recipe role-assignment mapping (TYPE-01, the rubric lever)
- Seam every `%Text{}` size as `size: scale.<role>` where `scale` =
  `theme.typography.scale` when a `theme:` opt is present, else a **per-recipe
  literal-default scale** whose values reproduce that recipe's exact current
  size literals. Mirrors Phase 120's per-recipe color literal→role mapping
  ("flag every literal→role mapping explicitly in the plan").
- **Exactly one element per recipe binds to `display`** — the "one key fact" —
  so the hierarchy anchor is unambiguous and dominant (`display:body = 2.0×` in
  `default/0`). The anchors:
  - Invoice / BrandedInvoice → **Total Due** amount
  - Receipt → **total**
  - Statement → **closing balance**
  - Payslip → **net pay**
  - Ticket → **confirmation / reference code**
  - Certificate → **recipient name**
- All other elements map down to `title`/`subtitle`/`body`/`small`/`caption` by
  current size rank. The exact per-element mapping table is a
  research/planning deliverable (reviewable, like the Phase-120 color table).
- On the **no-theme path** each recipe's literal-default scale reproduces its
  current sizes exactly (byte-identical); on the **themed path** all recipes
  collapse onto the theme's uniform scale — that unification is what creates
  consistent cross-recipe hierarchy. — **Reversibility:** reversible (the
  literal-default scale is a private per-recipe seam; role assignments are
  tunable without a public-contract change — the `scale` field shape is already
  frozen in Phase 119).

### D-02 — Font-role wiring breadth + `mono` designation (TYPE-02)
- Seam **every** text run to a font role now — `font: fonts.<role>` where
  `fonts` = `theme.typography.fonts` (if theme) else per-recipe literal defaults
  (all `:default`) — byte-identical on the default path since `:default` is the
  always-registered Helvetica-compatible built-in. Mirrors Phase-120 D-03's
  "seam text→ink NOW so dark/brand just works."
- Role assignment: `heading` for titled/anchor text (the display/title elements),
  `body` for prose/labels, `mono` for machine/reference strings — ticket
  confirmation & reference codes, and invoice/receipt IDs + amounts (strings
  where tabular/machine-issued reading is the intent). Exact per-element
  `mono` list is a planning deliverable.
- **TYPE-02 raise-path is proven**, not assumed: a test constructs a theme whose
  `fonts.heading` (or body/mono) is an **unregistered** atom, renders a recipe,
  and asserts it raises `{:unknown_text_font, _}` via the existing
  `FontRegistry` → `build.ex` typed-error path — never a silent Helvetica
  fallback. `default/0` fonts are all `:default` (registered) so the default
  path never raises. — **Reversibility:** reversible.

### D-03 — `leading` / widows / orphans breadth (TYPE-03)
- Thread `line_height: leading`, `widows:`, `orphans:` from the theme onto
  **all** text blocks (uniform seam), defaulting on the no-theme path to the
  recipe's current values (which equal the `%Text{}` struct defaults 1.2 / 2 / 2,
  matching `default/0`) → metric no-op, goldens byte-identical.
- Applying leading to single-line text is inert (line_height only affects
  multi-line layout); wiring it everywhere keeps the seam uniform and makes the
  Phase-119-deferred `leading: 1.35` prose target a **one-line Phase-123 change**
  (not pulled forward — that re-bless belongs to rubric closure). —
  **Reversibility:** reversible.

### Claude's Discretion
Planner freedom: exact per-recipe `defp` seam helper naming; the precise
per-element role/mono mapping tables (subject to the D-01 anchor rule + byte
identity); whether the 7 recipes are one slice or split; whether the literal
defaults live in a per-recipe `typography/1` seam mirroring `palette/1` or fold
into it. Binding constraints: exactly-one-`display`-anchor per recipe, no-theme
byte identity, TYPE-02 raise-path proven with teeth.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone locks & requirements
- `.planning/REQUIREMENTS.md` — TYPE-01, TYPE-02, TYPE-03 (Phase 122 rows).
- `.planning/ROADMAP.md` §"Phase 122" — goal, depends-on (Phase 120), 3 success
  criteria (materialized scale, font-role raise-path, leading metric no-op).
- `.planning/PROJECT.md` §"Current Milestone: v2.11" — byte-identity-first,
  engine-untouched, brand⊥theme, no-overclaim, family-not-industry boundary.
- `.planning/research/milestone-b/SUMMARY.md` — type-scale-as-explicit-points;
  the metric-no-op discipline; the font-role/raise-path reasoning.

### Prior-phase context (the seam this phase reads from)
- `.planning/phases/119-rendro-theme-core-module-the-one-way-door/119-CONTEXT.md`
  — D-03 (frozen type-scale VALUES `21/16.5/13/10.5/9/8`, `leading 1.2`,
  `widows/orphans 2`); the Evolving-values note (`leading: 1.35` is the Phase-123
  target); `fonts` default all `:default`.
- `.planning/phases/120-s1-seam-retrofit-full-theme-swap-across-all-7-recipes/120-CONTEXT.md`
  — D-04 (typography read deferred to 122, plumbing already threaded); D-01/D-02
  (per-recipe literal-default + `Map.merge` override pattern to replicate for
  typography); D-03 (seam-now-for-dark/brand precedent).
- `.planning/phases/121-light-dark-background-fill-mechanism-all-7-recipes/121-CONTEXT.md`
  — the shared-helper wiring pattern across all 7 recipes.

### Design source of truth
- `prompts/Rendro Brand Book.txt` — §9 Typography (clear hierarchy / generous
  line-height; avoid huge SaaS-hero type). Informs the D-01 anchor ambition.
- `brand/tokens/tokens.json` — typography tokens (web-only, excluded from Hex);
  reference for the Phase-123 `leading: 1.35` target, not baked in here.

### Code to integrate with (read before planning)
- `lib/rendro/theme.ex` (~L75 `@default_typography`, `@type typography` ~L117,
  `apply_density` ~L318 compact-leading nudge) — the `typography` map shape being
  read; `resolve/1` idempotence (safe to re-resolve per rung).
- `lib/rendro/text.ex` (L15 defstruct: `size: 12`, `line_height: 1.2`,
  `widows: 2`, `orphans: 2`, `font: "Helvetica"`; `normalize_font/1`) — the
  target struct; metric-no-op baseline; logical-atom vs Helvetica-alias path.
- `lib/rendro/font_registry.ex` (`@default_font :default` L11; `resolve/1` L221,
  `resolve_pdf_font/2` L234; `{:unknown_logical_font, _}` L50) → the typed-error
  source for TYPE-02.
- `lib/rendro/build.ex` (~L111 `{:unknown_logical_font,_}` → `{:unknown_text_font,_}`
  mapping) — the raise-path the TYPE-02 test asserts on.
- All 7 recipes' current `size:`/`font:` call sites and their `palette/1` seam
  (the pattern to mirror for a `typography` seam):
  `lib/rendro/recipes/invoice.ex` (`palette/1` ~L466; sizes 18/12/10 at
  L246/247/398/405; Total Due ~L457), `branded_invoice.ex` (only recipe with an
  explicit `font: font_name` ~L213/214; brand font registered ~L174),
  `statement.ex`, `receipt.ex`, `certificate.ex` (Helvetica-only note ~L323;
  brand font registered-but-unapplied), `payslip.ex`, `ticket.ex` (`@*_size`
  module attrs; reference/present-code sizes ~L459/468).

### Test & golden infrastructure
- `test/support/golden.ex` + `test/support/edge_fixtures.ex` +
  `test/rendro/edge_matrix_test.exs` — un-themed; must stay byte-identical.
- `test/rendro/recipes/*` byte-identity + `no_inline_color_literals_test.exs`
  (a `no_inline_size_literals`-style scan guard for sizes is a candidate teeth
  test, planner's call).
- `test/rendro/recipes/invoice_opts_threading_test.exs` — `:palette`/`:theme`
  threading test template.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Threaded `%Theme{}` value** (Phase 120): the whole resolved theme already
  reaches every recipe's `sections/2` — Phase 122 needs zero new plumbing, only
  new READS of `theme.typography.*`.
- **`palette/1` per-recipe seam** (all 7 recipes): the exact shape to mirror for
  a `typography` seam — `base = if theme, do: theme.typography, else: <literals>`,
  values read by named role.
- **`FontRegistry` `:default` built-in + `{:unknown_text_font,_}` typed error**:
  font roles are three logical atoms on the existing resolution path — no shape
  change, no silent Helvetica substitution; the raise-path already exists.
- **`%Text{}` struct defaults (1.2 / 2 / 2)** == `default/0` typography → leading/
  widows/orphans wiring is a metric no-op on the default path by construction.

### Established Patterns
- **Per-recipe literal-default + theme-read split** (Phase 120 D-01/D-02):
  no-theme path = literals (byte-identical), themed path = theme reads.
- **Seam-now-for-free-later** (Phase 120 D-03 ink seam → dark "just works"):
  seaming all text to font roles + scale now makes Phase-123's `default/0`
  application and any `from_brand/2` scale a pure data change.
- **Integer/single-decimal materialized values** (Phase 119 D-03): scale steps
  are explicit points, leading a single decimal → byte-reproducible; no
  `:math.pow` in the shipped map.
- **Source-scan teeth tests** (`no_inline_color_literals_test.exs`): precedent
  for a matching no-inline-`size:`-literal guard.

### Integration Points
- **None into the engine.** `%Theme{}` stays in the recipe layer; the
  deterministic pipeline (`build → compose → measure → paginate → render →
  validate`) never sees it. All work is the 7 recipe modules + their tests. The
  ONE engine touch-point is read-only: the existing `FontRegistry`→`build.ex`
  `{:unknown_text_font,_}` path that TYPE-02 asserts on (already shipped).

</code_context>

<specifics>
## Specific Ideas

- The "one key fact" per recipe MUST be the single `display`-anchored element —
  this is the concrete lever for closing the Phase-118 SHOW-01 hierarchy gap in
  Phase 123 (make the key fact structurally dominant before applying the palette;
  a slick palette alone does NOT fix hierarchy).
- `mono` role is intended for machine/reference strings (confirmation codes,
  IDs, tabular amounts) — the "issued by a system" reading — not general body.
- Brand Book §9: restrained hierarchy + generous line-height, explicitly NOT
  huge SaaS-hero type — bounds how aggressive the `display` anchor should read.

</specifics>

<deferred>
## Deferred Ideas

- **`leading: 1.35` prose realization** — Phase 123 rubric closure (one-line
  change on role-reading prose blocks; re-bless within version). Not pulled
  forward — kept a metric no-op here.
- **`default/0` value tuning + themed/dark gallery renders + support-matrix
  `theming.*` rows + `guides/theming.md` + honest SHOW-01 re-score** — Phase 123.
- **`density: :compact` deep leading/spacing multipliers** — Milestone C (honored
  shallowly in `resolve/1` today).
- **Tabular figures / small-caps / OpenType `mono` refinements** — demand-gated
  on new engine primitives (Milestone C+).
- **Applying the registered-but-unapplied brand font** in Certificate (currently
  embedded but never used on a text run) — if it becomes a `heading` role
  candidate, that is a themed-path behavior change; keep byte-identity the
  binding constraint and treat as planner's call within D-02, else defer.

None out-of-scope surfaced — discussion stayed within the phase domain.

</deferred>

---

*Phase: 122-typography-type-scale-application-font-role-leading-wiring*
*Context gathered: 2026-07-27*

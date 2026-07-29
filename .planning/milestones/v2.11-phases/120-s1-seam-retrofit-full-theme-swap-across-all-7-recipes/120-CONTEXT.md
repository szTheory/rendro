# Phase 120: S1 seam retrofit + full `theme:` swap across all 7 recipes - Context

**Gathered:** 2026-07-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Pure plumbing. Make every recipe themable by threading a **resolved `%Theme{}`**
through each recipe's 3 rungs (`document/2` → `page_template/1` → `sections/2`) and
reading `theme.colors.*` by role — in two disciplined steps: (1) **retrofit** the 4
un-seamed recipes (Statement, Certificate, Receipt, BrandedInvoice) with a
byte-identical `palette/1` seam whose defaults equal today's exact literals; then (2)
**swap** all 7 recipes to read `theme.colors.*`. The un-themed call
(`document(data)` with no `theme:`) must reproduce v2.10 bytes exactly for all 7
recipes — the milestone's central regression guard.

**In scope:**
- Byte-identical `palette/1` retrofit for the 4 un-seamed recipes, each proven by a
  fresh sha256 golden **committed separately** from any theme wiring (PLUMB-01).
- Threading the resolved `%Theme{}` value through the 3 rungs of all 7 recipes;
  reading `theme.colors.*` by role; no inline `{r,g,b}` literals left in sections;
  each recipe's `Keyword.take` opts whitelist admits `:theme` (PLUMB-02, colors only).
- `document(data)` no-theme byte-identity no-op across all 7 recipes (PLUMB-03).
- Seaming the two colorless recipes' (Receipt, BrandedInvoice) primary text to
  `theme.colors.ink` now (default `{0,0,0}` → byte-identical) — see D-03.

**Out of scope (later phases):**
- `theme.typography.*` reads into `%Text{}` (Phase 122) — 120 threads the whole
  theme value but reads **only** colors (D-04).
- Light/dark background-fill mechanism (Phase 121).
- `default/0` rubric-closure tuning, gallery/docs, support-matrix rows (Phase 123).
- The `%Theme{}` value contract itself — shipped in Phase 119, untouched here.

</domain>

<decisions>
## Implementation Decisions

Phase 120 is heavily pre-specified by the milestone-b research SUMMARY and Phase 119's
locked `%Theme{}` shape. Four decisions below; three locked from research + code
evidence, one (D-03) chosen by the user.

- **D-01 — Legacy `:palette` opt: preserve, override-wins** (PLUMB-02 back-compat)
- **Preserve** `:palette` — do NOT retire it. Resolution per recipe:
  `base = if theme = opts[:theme], do: Rendro.Theme.resolve(theme).colors, else: <today's literal defaults>`,
  then `Map.merge(base, Keyword.get(opts, :palette, %{}))` as the **final** layer.
- **Precedence:** explicit `:palette` override > `:theme` > recipe literal defaults.
  An explicit `:palette` override wins over a supplied theme (never silently ignored).
- **Evidence:** exactly ONE test dependent —
  `test/rendro/recipes/invoice_opts_threading_test.exs` asserts a `:palette` override
  changes only the footer color. The merge-on-top design keeps that test green with
  zero back-compat break. No other `:palette` callers exist in `test/` or `lib/`.
- Each rung defensively `Rendro.Theme.resolve/1`-es its input — resolve is idempotent
  (Phase 119 D-01), so re-resolving at each of the 3 rungs is free and prevents a
  partial-theme draw-time `KeyError`.

- **D-02 — Per-literal role mapping; no-theme path stays byte-identical** (PLUMB-01/03)
- The retrofit `palette/1` default for each recipe reproduces its **exact current
  literal** — per-recipe, NOT a uniform all-black default. Concretely:
  - **Certificate:** frame `{34,34,34}` (near-ink keyline) → maps to `rule` role;
    the recipe's retrofit default for `rule` is `{34,34,34}` (NOT `{0,0,0}`).
  - **Statement:** band fill `{245,245,245}` → `surface`; band stroke `{0,0,0}` →
    `rule`. Retrofit defaults reproduce those exact literals.
  - **Receipt / BrandedInvoice:** primary text implicit-black → `ink`, retrofit
    default `{0,0,0}` (see D-03).
- **No golden re-bless on the no-theme path** — because every retrofit default equals
  today's literal, un-themed renders are byte-identical (PLUMB-03). The only new
  goldens are the fresh retrofit sha256 goldens (PLUMB-01) and any *themed* goldens
  (net-new, no prior bytes to match).
- **Flag every literal→role mapping explicitly in the plan** (research directive):
  which role each recipe literal binds to is a deliberate, reviewable choice.

- **D-03 — Colorless recipes (Receipt, BrandedInvoice): seam text→ink NOW** *(user decision)*
- Introduce explicit `theme.colors.ink` reads on the **primary text** of both
  recipes now, defaulting to `{0,0,0}` so the no-theme render is byte-identical.
- **Rationale (user-selected):** makes both recipes genuinely themable in Phase 120,
  and means Phase 121 dark mode "just works" — a dark theme swaps `ink` to a light
  tuple, so text stays readable on the dark background-fill. Deferring the ink-read to
  121 would leave these two recipes black-on-white (unreadable in dark mode) until then.
- Accepts a slightly larger byte-identity blast radius for these two recipes; proven
  by their fresh retrofit sha256 goldens (all default to `{0,0,0}` → identical bytes).

- **D-04 — Typography threading boundary: colors only in 120** (scope split with Phase 122)
- Phase 120 threads the **whole resolved `%Theme{}`** value through the 3 rungs
  (shared plumbing) but reads **only** `theme.colors.*`.
- All `theme.typography.*` reads into `%Text{size,font,line_height,widows,orphans}`
  belong to Phase 122 — which needs **no new plumbing** because the value is already
  threaded here. (PLUMB-02's REQUIREMENTS wording mentions `theme.typography.*`; the
  ROADMAP splits typography into Phase 122. Resolution: thread once in 120, read
  colors in 120, read typography in 122.)

### Claude's Discretion
- Exact `defp` seam helper naming per recipe; whether the 3-seamed and 4-retrofit
  recipes are planned as one phase or split slices (research permits folding, but
  **retrofit commits MUST stay split from swap commits regardless** — research line 48).
- Exact ordering of the 4 retrofit commits.
- Which specific text/section elements in Receipt/BrandedInvoice count as "primary
  text" for the D-03 ink seam (keep byte-identity the binding constraint).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone locks & requirements
- `.planning/REQUIREMENTS.md` — PLUMB-01, PLUMB-02, PLUMB-03 (Phase 120 rows) and the
  Open Questions rows (legacy `:palette`, non-black literals) resolved by D-01/D-02.
- `.planning/ROADMAP.md` §"Phase 120" — goal, depends-on (Phase 119), 3 success criteria.
- `.planning/research/milestone-b/SUMMARY.md` — the definitive Phase 120 guidance:
  the 3-of-7 S1 seam audit; the **two-step retrofit-then-swap, split-commit** discipline
  (§"Phase 120", lines 46–48); the legacy-`:palette` preserve-vs-retire question (line
  112); the non-black-literal `{34,34,34}` per-recipe decision (line 129); Certificate
  as the stress case.
- `.planning/phases/119-rendro-theme-core-module-the-one-way-door/119-CONTEXT.md` —
  the locked `%Theme{}` shape: `colors` map roles (`ink, muted, accent, on_accent,
  background, surface, rule, positive, negative`), `resolve/1` idempotence, `default/0`
  mined-Swiss palette values, `dark/1` swap targets.
- `.planning/PROJECT.md` §"Current Milestone: v2.11" + "Key Decisions" — engine-untouched,
  brand⊥theme, byte-identity-first, no-overclaim culture.

### Code to integrate with (read before planning)
- `lib/rendro/recipes/invoice.ex` (`palette/1` ~L466; threaded at L216/350/407; opts
  whitelist `Keyword.take` ~L138) — the **reference seam pattern** to replicate.
- `lib/rendro/recipes/payslip.ex`, `lib/rendro/recipes/ticket.ex` — the other 2 seamed
  recipes (swap-only, no retrofit).
- `lib/rendro/recipes/statement.ex` (band fill `{245,245,245}` + stroke `{0,0,0}` ~L305),
  `lib/rendro/recipes/certificate.ex` (frame `{34,34,34}` ~L374, `@border_allowed_keys`
  ~L62), `lib/rendro/recipes/receipt.ex` (no color literals),
  `lib/rendro/recipes/branded_invoice.ex` (no color literals; font/logo brand story) —
  the 4 retrofit targets.
- `lib/rendro/theme.ex` — `Rendro.Theme.resolve/1` (idempotent; call at each rung),
  `default/0`, `.colors` map shape.
- `lib/rendro/color.ex` — `validate/1` (role validation `resolve/1` performs).

### Test & golden infrastructure
- `test/support/golden.ex` + `test/support/golden_test.exs` — the sha256 golden helper
  for the fresh retrofit goldens (PLUMB-01) and no-theme regression goldens (PLUMB-03).
- `test/rendro/deterministic_test.exs` — determinism harness.
- `test/rendro/recipes/invoice_opts_threading_test.exs` — the ONE `:palette` dependent
  (D-01 must keep it green); template for per-recipe `:theme`/`:palette` threading tests.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Invoice `palette/1` seam** (`invoice.ex` ~L466): bare role→`{r,g,b}` map merged with
  `Keyword.get(opts, :palette, %{})`; threaded at 3 call sites (L216/350/407). Copy this
  exact shape into the 4 retrofit recipes (with per-recipe literal defaults), then extend
  the base to `theme.colors` when a `:theme` opt is present.
- **`Keyword.take` opts whitelist** (`invoice.ex` ~L138): the mechanism that threads
  `:palette` through to `sections/2`; add `:theme` to each recipe's whitelist (PLUMB-02).
- **`Rendro.Theme.resolve/1`** (Phase 119): idempotent, deep-merges + validates; safe to
  call defensively at every rung.
- **sha256 golden helper** (`test/support/golden.ex`): existing infra for the fresh
  retrofit + no-theme regression goldens; no new test tooling needed.

### Established Patterns
- **Two-step split-commit discipline** (research; mirrors Milestone A's "split verbatim
  move from normalization"): commit (1) byte-identical retrofit + fresh goldens, THEN
  commit (2) the theme swap — never combined.
- **No-theme = byte-identity no-op** (PLUMB-03): the load-bearing regression guard; every
  retrofit default reproduces today's literal so un-themed bytes never move.
- **Integer-`{r,g,b}`-resolved-once determinism** (Phase 119 D-04): theme colors resolve
  to integer tuples before draw; no float reaches the byte stream.

### Integration Points
- **None into the engine.** `%Theme{}` stays in the recipe layer; the deterministic
  pipeline (`build → compose → measure → paginate → render → validate`) never sees it.
  All work is confined to the 7 recipe modules + their tests.

</code_context>

<specifics>
## Specific Ideas

- The two colorless recipes (Receipt, BrandedInvoice) get their primary text seamed to
  `theme.colors.ink` in **this** phase (user decision D-03) — chosen specifically so
  Phase 121 dark mode renders readable text on both without a later retrofit.
- Certificate is the retrofit stress case: geometry-derived centered layout + optional
  frame (`{34,34,34}`) + optional brand — plan its retrofit golden carefully.

</specifics>

<deferred>
## Deferred Ideas

- **`theme.typography.*` reads into `%Text{}`** — Phase 122 (plumbing threaded here, reads
  deferred).
- **Light/dark background-fill rect + `mode` handling** — Phase 121.
- **`default/0` value tuning, themed/dark gallery renders, support-matrix `theming.*`
  rows, `guides/theming.md`** — Phase 123.
- **Retiring `:palette` entirely** — rejected for v2.11 (back-compat); could revisit in a
  future major if `:theme` fully supersedes it.

</deferred>

---

*Phase: 120-s1-seam-retrofit-full-theme-swap-across-all-7-recipes*
*Context gathered: 2026-07-27*

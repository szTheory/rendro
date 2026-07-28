# Phase 122: Typography type-scale application + font-role/leading wiring - Research

**Researched:** 2026-07-27
**Domain:** Elixir PDF-generation recipe layer (Rendro) — typography seam application across 7 recipes
**Confidence:** HIGH (every mapping grounded in `file:line` evidence from the actual source)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — Per-recipe role-assignment mapping (TYPE-01):**
- Seam every `%Text{}` size as `size: scale.<role>` where `scale` = `theme.typography.scale` when a `theme:` opt is present, else a **per-recipe literal-default scale** whose values reproduce that recipe's exact current size literals (mirrors Phase 120's per-recipe color literal→role mapping).
- **Exactly one element per recipe binds to `display`** — the "one key fact." Anchors:
  - Invoice / BrandedInvoice → **Total Due** amount
  - Receipt → **total**
  - Statement → **closing balance**
  - Payslip → **net pay**
  - Ticket → **confirmation / reference code**
  - Certificate → **recipient name**
- All other elements map down to `title`/`subtitle`/`body`/`small`/`caption` by current size rank. The exact per-element mapping table is this research's deliverable (reviewable, like the Phase-120 color table).
- No-theme path: each recipe's literal-default scale reproduces its current sizes exactly (byte-identical). Themed path: all recipes collapse onto the theme's uniform scale. Reversible.

**D-02 — Font-role wiring breadth + `mono` designation (TYPE-02):**
- Seam **every** text run to a font role now — `font: fonts.<role>` where `fonts` = `theme.typography.fonts` (if theme) else per-recipe literal defaults (all `:default`) — byte-identical on the default path since `:default` is the always-registered Helvetica-compatible built-in.
- Role assignment: `heading` for titled/anchor text, `body` for prose/labels, `mono` for machine/reference strings (ticket confirmation & reference codes, invoice/receipt IDs + amounts). Exact per-element `mono` list is a planning deliverable.
- **TYPE-02 raise-path proven, not assumed:** a test constructs a theme whose `fonts.heading` (or body/mono) is an **unregistered** atom, renders a recipe, and asserts it raises/returns the existing `{:unknown_text_font, _}` typed error — never a silent Helvetica fallback. `default/0` fonts are all `:default` (registered) so the default path never raises. Reversible.

**D-03 — `leading` / widows / orphans breadth (TYPE-03):**
- Thread `line_height: leading`, `widows:`, `orphans:` from the theme onto **all** text blocks (uniform seam), defaulting on the no-theme path to the recipe's current values (which equal the `%Text{}` struct defaults 1.2 / 2 / 2, matching `default/0`) → metric no-op, goldens byte-identical.
- Applying leading to single-line text is inert; wiring everywhere keeps the seam uniform and makes the Phase-119-deferred `leading: 1.35` prose target a one-line Phase-123 change. Reversible.

### Claude's Discretion
Planner freedom: exact per-recipe `defp` seam helper naming; the precise per-element role/mono mapping tables (subject to the D-01 anchor rule + byte identity); whether the 7 recipes are one slice or split; whether the literal defaults live in a per-recipe `typography/1` seam mirroring `palette/1` or fold into it. Binding constraints: exactly-one-`display`-anchor per recipe, no-theme byte identity, TYPE-02 raise-path proven with teeth.

### Deferred Ideas (OUT OF SCOPE)
- `leading: 1.35` prose realization → Phase 123 (kept a metric no-op here).
- `default/0` value tuning + themed/dark gallery renders + support-matrix `theming.*` rows + `guides/theming.md` + honest SHOW-01 re-score → Phase 123.
- `density: :compact` deep leading/spacing multipliers → Milestone C (honored shallowly in `resolve/1` today).
- Tabular figures / small-caps / OpenType `mono` refinements → Milestone C+ (demand-gated on new engine primitives).
- Applying the registered-but-unapplied brand font in Certificate → planner's call within D-02 (byte-identity binding), else defer.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TYPE-01 | Named type scale (`display`/`title`/`subtitle`/`body`/`small`/`caption`) materialized as explicit points and threaded into `%Text{}` size fields | Per-recipe size→role mapping tables below (§Per-Recipe Mapping Tables); frozen scale already lives in `theme.ex:77`; seam pattern mirrors `palette/1` (§Standard Stack) |
| TYPE-02 | Font roles (`heading`/`body`/`mono`) resolve through `FontRegistry`; unregistered role raises `{:unknown_text_font, _}`, never silent substitution | Typed-error path confirmed `font_registry.ex:393` → `build.ex:110-111`; existing assertion precedent `font_test.exs:90` (§TYPE-02 Raise-Path) |
| TYPE-03 | `leading` + widows/orphans theme-driven; `default/0` scale/leading a metric no-op vs Phase-117 goldens | No recipe currently sets `line_height:`/`widows:`/`orphans:` (grep-confirmed) — all use `%Text{}` defaults 1.2/2/2 == `default/0` typography == metric no-op by construction (§TYPE-03) |
</phase_requirements>

## Summary

This is a pure codebase-survey phase: the whole resolved `%Theme{}` already reaches every recipe's `sections/2` (Phase 120 plumbing), the frozen type scale already exists in `theme.ex` (`display 21 / title 16.5 / subtitle 13 / body 10.5 / small 9 / caption 8`, `leading 1.2`, `widows/orphans 2`), and the `{:unknown_text_font, _}` typed-error path already ships. Phase 122 adds **only new READS** of `theme.typography.*` into `%Text{size, font, line_height, widows, orphans}` across the 7 recipe modules — no engine touch, no new plumbing, no new dependency.

The mechanism is forced, not chosen: each recipe gets a `typography`-style seam mirroring the existing `palette/1` (`base = if theme, do: theme.typography, else: <per-recipe literals>`; `Map.merge` override layer). On the no-theme path the literal defaults reproduce each recipe's current sizes/fonts/leading exactly → all existing byte-identity goldens and Phase-117 stress goldens stay green with zero re-bless. On the themed path all recipes collapse onto the uniform scale, creating the cross-recipe hierarchy that Phase 123 leverages for the SHOW-01 rubric fix.

**The single most important finding:** 6 of 7 recipes map cleanly (≤6 distinct sizes → the 6 named scale roles), but **Ticket has SEVEN distinct sizes (26, 16, 10, 9, 8, 7, 6) against only six roles** — it cannot be fully seamed to `scale.<role>` while preserving byte-identity without exempting at least one size. Additionally, **BrandedInvoice has no Total-Due text run** (its D-01 anchor lives inside the table, not a `%Text`), and its two header runs use a data-driven **brand embedded font** (`font: font_name`) whose literal-default is NOT `:default`. These two are the phase's real planning risks; the other five are mechanical.

**Primary recommendation:** Build one `typography/1` seam per recipe (mirroring `palette/1`), drive the 5 clean recipes off the mapping tables below verbatim, and resolve Ticket + BrandedInvoice via the two flagged open questions before writing their plans. Add a source-scan teeth test (no-inline-`size:`-literal, mirroring `no_inline_color_literals_test.exs`) plus one TYPE-02 raise-path test per the `font_test.exs:90` pattern.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Type-scale size selection | Recipe layer (`recipes/*.ex`) | Theme value (`theme.ex`) | Recipe assigns a role per call site; theme supplies the numbers. Engine never sees `%Theme{}`. |
| Font-role resolution | Recipe (chooses role) → `FontRegistry` (resolves atom→descriptor) | `build.ex` (validates, maps error) | Roles are three logical atoms on the existing resolution path; the typed-error path is engine-side and read-only. |
| Leading / widows / orphans | Recipe layer (threads onto `%Text{}`) | `%Text{}` struct defaults | Struct defaults (1.2/2/2) already equal `default/0` typography → literal-default is inert. |
| Byte-identity guard | Test layer (byte-identity + edge goldens) | — | The regression contract; untouched engine + literal defaults keep it green. |

**No engine tier is involved.** The one engine touch-point is read-only: the `FontRegistry` → `build.ex` `{:unknown_text_font, _}` path that TYPE-02 asserts on (already shipped).

## Standard Stack

### The seam to mirror — `palette/1` (verbatim shape, all 7 recipes)

Every recipe already carries this exact seam (evidence: `invoice.ex:491`, `branded_invoice.ex:263`, `statement.ex:373`, `receipt.ex:497`, `certificate.ex:403`, `payslip.ex:706`, `ticket.ex:540`):

```elixir
# Source: lib/rendro/recipes/invoice.ex:491 [VERIFIED: codebase]
defp palette(opts) do
  base =
    case opts[:theme] do
      nil ->
        %{ink: {0, 0, 0}, muted: {0, 0, 0}, accent: {0, 0, 0}, on_accent: {0, 0, 0},
          background: {255, 255, 255}, surface: {255, 255, 255}, rule: {0, 0, 0}}
      theme ->
        Rendro.Theme.resolve(theme).colors
    end

  Map.merge(base, Keyword.get(opts, :palette, %{}))
end
```

The Phase-122 `typography/1` seam is the exact analogue:

```elixir
# Proposed shape [ASSUMED — planner's naming discretion per CONTEXT §Discretion]
defp typography(opts) do
  base =
    case opts[:theme] do
      nil -> @default_typography_literals   # per-recipe: scale + fonts + leading/widows/orphans
      theme -> Rendro.Theme.resolve(theme).typography
    end
  Map.merge(base, Keyword.get(opts, :typography, %{}))   # optional override layer, planner's call
end
```

### Frozen theme values already in place (no change this phase)

```elixir
# Source: lib/rendro/theme.ex:75-81 [VERIFIED: codebase]
@default_typography %{
  fonts: %{heading: :default, body: :default, mono: :default},
  scale: %{display: 21, title: 16.5, subtitle: 13, body: 10.5, small: 9, caption: 8},
  leading: 1.2,
  widows: 2,
  orphans: 2
}
```

`resolve/1` is idempotent (safe to re-resolve per rung), and `apply_density(typography, :compact)` nudges only `leading` to `1.1` (`theme.ex:321`). Typed `typography` shape is frozen at `theme.ex:117-134`.

### Target struct

```elixir
# Source: lib/rendro/text.ex:15-23 [VERIFIED: codebase]
defstruct [:content, font: "Helvetica", size: 12, color: {0, 0, 0},
           line_height: 1.2, widows: 2, orphans: 2]
```

Struct defaults (`line_height: 1.2, widows: 2, orphans: 2`) are metric-identical to `@default_typography` → TYPE-03 wiring is a no-op on the default path by construction.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Separate `typography/1` seam | Fold literals into existing `palette/1` (rename to e.g. `tokens/1`) | Fewer functions, but conflates color and type concerns and forces re-touching all color call sites. Recommend a separate seam mirroring `palette/1`. Planner's call (CONTEXT §Discretion). |

**No new dependencies.** This phase is Elixir stdlib + existing Rendro surfaces only.

## Per-Recipe Mapping Tables (the core deliverable)

Legend: **Role** = proposed named scale step; **Font** = proposed D-02 role; **Literal-default** = the value the no-theme `scale.<role>` MUST carry to stay byte-identical. All line numbers `[VERIFIED: codebase]`.

Font-role convention derived from the anchors: **anchor is `mono` when it is an amount/ID/code, `heading` when it is a name/title.** 6 of 7 anchors are amounts/codes (→ mono); Certificate's recipient-name anchor is `heading`.

### 1. Invoice (`lib/rendro/recipes/invoice.ex`) — 5 distinct sizes, CLEAN
Distinct sizes: 20, 18, 12, 10, 9.

| Element | file:line | Cur size | → Role | Literal-default | Font role | Notes |
|---------|-----------|----------|--------|-----------------|-----------|-------|
| **Total Due** amount | L457-458 (`@dominant_total_size` 20) | 20 | **display** ✓ANCHOR | 20 | mono | Only element at 20 — anchor unambiguous |
| `INVOICE #<id>` | L246 | 18 | title | 18 | mono (or heading — see risk) | ID + title; no `color:`/`font:` today |
| bill-to / party name | L398 | 12 | subtitle | 12 | body | helper block |
| `Date:` | L247 | 10 | body | 10 | body | no `color:` today |
| thank-you / due / terms / muted lines | L379, L405, L409, L413 | 10 | body | 10 | body | |
| minor totals (subtotal/tax) | L444-445 (`@minor_totals_size` 9) | 9 | small | 9 | mono | amounts |

`caption` unused. Anchor rule satisfied (exactly one display).

### 2. BrandedInvoice (`lib/rendro/recipes/branded_invoice.ex`) — 3 distinct sizes, **RISK**
Distinct sizes: 18, 12, 10.

| Element | file:line | Cur size | → Role | Literal-default | Font role | Notes |
|---------|-----------|----------|--------|-----------------|-----------|-------|
| `Rendro, Inc.` (brand name) | L213 | 18 | display? title? | 18 | **`font_name` (BRAND FONT)** | `font: font_name` today — NOT `:default` |
| `Invoice #<id>` | L214 | 12 | title/subtitle | 12 | **`font_name` (BRAND FONT)** | `font: font_name` today |
| `Date:` | L215 | 10 | body | 10 | :default / body | |
| thank-you | L246 | 10 | body | 10 | :default / body | |

**Two risks — see Open Questions Q1 & Q2:**
1. **No Total-Due text run exists.** The D-01 anchor ("Total Due amount") lives inside the `Rendro.table/2` body (L226-230), not a `%Text{}` call site. There is nothing to bind `display` to. Largest run is the brand name (18).
2. **Brand-font literal-default is NOT `:default`.** L213/L214 use `font: font_name` (the data-driven embedded brand font registered at `branded_invoice.ex:174-177`). Their literal-default MUST remain `font_name` to stay byte-identical — the sole exception to D-02's "all `:default`."

### 3. Statement (`lib/rendro/recipes/statement.ex`) — 5 distinct sizes, CLEAN
Distinct sizes: 22, 14, 12, 10, 9.

| Element | file:line | Cur size | → Role | Literal-default | Font role | Notes |
|---------|-----------|----------|--------|-----------------|-----------|-------|
| **closing balance** amount | L341 | 22 | **display** ✓ANCHOR | 22 | mono | Only element at 22 |
| closing-balance label | L338 | 9 | small | 9 | body | muted |
| account name | L347 | 14 | title | 14 | heading | |
| period / opening-balance | L348, L349 | 10 | body | 10 | body | muted |
| table cell text (`cell_text/2`) | L543 | 12 | subtitle | 12 | body (mono for amount cols — see note) | reused across L419-422, L496-512 |

Note: `cell_text/2` is a single helper (L542-543) used for BOTH label and amount columns. If amount columns should be `mono` while label columns stay `body`, the helper must split or take a role arg — otherwise all cells share one font role. Recommend keeping one role (`body`) for byte-safety now; mono-ising amount columns is a themed-path refinement, planner's call.

### 4. Receipt (`lib/rendro/recipes/receipt.ex`) — 6 distinct sizes, EXACTLY FULL
Distinct sizes: 18, 16, 14, 12, 10, 9 → all six roles consumed, **no headroom**.

| Element | file:line | Cur size | → Role | Literal-default | Font role | Notes |
|---------|-----------|----------|--------|-----------------|-----------|-------|
| **Total** amount | L445-446 (`@dominant_total_size` 18) | 18 | **display** ✓ANCHOR | 18 | mono | Only element at 18 |
| section header (`render_section_header`) | L329 | 16 | title | 16 | heading | |
| receipt title | L303 | 14 | subtitle | 14 | heading | |
| customer name | L304 | 12 | body | 12 | body | |
| date | L305 | 10 | small | 10 | body | |
| minor totals | L432-433 (`@minor_totals_size` 9) | 9 | caption | 9 | mono | amounts |

All six roles used exactly once — clean but tight. No off-scale sizes.

### 5. Certificate (`lib/rendro/recipes/certificate.ex`) — 5 distinct typographic sizes + 1 artifact
Distinct typographic sizes: 34, 20, 12, 11, 10. Plus `size: 1` spacer artifact.

| Element | file:line | Cur size | → Role | Literal-default | Font role | Notes |
|---------|-----------|----------|--------|-----------------|-----------|-------|
| **recipient name** | L303 (`@recipient_size` 34), used L353 | 34 | **display** ✓ANCHOR | 34 | heading | Name anchor → heading |
| title | L301 (`@title_size` 20), used L351 | 20 | title | 20 | heading | |
| "This certifies that" subtitle | L302 (`@subtitle_size` 12), used L352 | 12 | subtitle | 12 | body | |
| body paragraph | L304 (`@body_size` 11), used L354 | 11 | body | 11 | body | |
| date / seal meta | L305 (`@meta_size` 10), used L355-356 | 10 | small | 10 | body | |
| empty vertical spacer | L347 `Rendro.text("", size: 1)` | 1 | **OFF-SCALE** | keep literal `1` | n/a | Layout hack, not typography — do NOT seam |

`caption` unused. Two implementation notes:
- **Sizes feed measurement, not just text runs.** `@body_size`/`@title_size`/etc. are consumed by `line_h/1` (L366) and `text_width/3` (L338) for vertical-centering math (L338-345) and horizontal centering (`centered_line/5` L371-374). The seam must thread the resolved size into BOTH the `%Text{}` AND these measurement calls, or centering drifts. On the no-theme path literal-defaults keep the math identical; on the themed path the centering recomputes against the new sizes (correct, themed-path behavior).
- **Brand font stays registered-but-unapplied** (`certificate.ex:274-282` registers it; text runs pass no `font:` → default Helvetica, `certificate.ex:322-326` comment confirms). Applying it as a `heading` role is a themed-path behavior change — deferred per CONTEXT unless planner opts in within byte-identity.

### 6. Payslip (`lib/rendro/recipes/payslip.ex`) — 5 distinct sizes, CLEAN
Distinct sizes: 27, 13, 11, 10, 9.

| Element | file:line | Cur size | → Role | Literal-default | Font role | Notes |
|---------|-----------|----------|--------|-----------------|-----------|-------|
| **net pay** amount | L418 | 27 | **display** ✓ANCHOR | 27 | mono | Only element at 27 |
| net-pay label | L415 | 10 | body | 10 | body | muted |
| employer | L345 | 13 | title | 13 | heading | |
| employee | L348 | 11 | subtitle | 11 | body | muted |
| table cells (`cell_text/2`) | L573 (`@cell_size` 11) | 11 | subtitle | 11 | body (mono for amounts — see note) | same value as employee |
| period / pay date | L350, L351 | 10 | body | 10 | body | |
| equation | L619 | 10 | body | 10 | mono (equation string) | |
| footer / notes / page number | L635, L689, L695 | 9 | small | 9 | body | |

`caption` unused. `@cell_size` (11) collides with employee (11) — both `subtitle` (fine, same literal). Same single-`cell_text`-helper amount-vs-label font caveat as Statement.

### 7. Ticket (`lib/rendro/recipes/ticket.ex`) — **SEVEN distinct sizes, HARD BLOCKER**
Distinct sizes: 26, 16, 10, 9, 8, 7, 6 → **7 values, only 6 roles.**

| Element | file:line | Cur size | Intended role | Literal-default | Font role | Notes |
|---------|-----------|----------|---------------|-----------------|-----------|-------|
| **reference code** | L459 (`@reference_size` 8) | 8 | **display** ✓ANCHOR (D-01) | 8 | mono | The "one key fact" per D-01 — but currently only 8pt |
| placement value (seat/date/etc.) | L321 (`@placement_value_size` 26) | 26 | title? | 26 | body/mono | **Largest element, but NOT the anchor** |
| ticket title | L348 | 16 | subtitle? | 16 | heading | |
| subtitle | L337 | 10 | body? | 10 | body | muted |
| issuer | L345 | 9 | small? | 9 | body | muted |
| placement label / terms | L316, L487 | 8 | (same as ref) | 8 | body | muted |
| reference caption | L455 (`@caption_size` 7) | 7 | caption? | 7 | body | muted |
| present code | L468 (`@present_code_size` 6) | 6 | ??? | 6 | mono | 7th distinct value — no role left |

**Why it cannot be fully seamed (structural):** The literal-default `scale` map can hold exactly ONE value per role name. Byte-identity forbids collapsing two distinct current sizes into one role (their literals differ → bytes change). With 7 distinct sizes and 6 role names, at least one size has no home. Non-monotone assignment (e.g. `display=8` for the reference code while `title=26` for the placement value) is *allowed* for byte-identity and is even the intended themed-path re-ranking (reference 8→21, placement 26→16.5), but it does NOT solve the 7-vs-6 count.

See Open Question Q3 for the recommended resolution (exempt one machine/`mono` micro-size from the scale seam).

## TYPE-03: leading / widows / orphans (metric no-op — confirmed)

**No recipe currently sets `line_height:`, `widows:`, or `orphans:` on any `%Text{}`** (grep across all 7 recipes returns zero hits). Every text run therefore uses the struct defaults `line_height: 1.2, widows: 2, orphans: 2` (`text.ex:19-22`), which are identical to `@default_typography` (`theme.ex:78-80`) and `default/0`. Threading `line_height: leading, widows:, orphans:` with literal-defaults `1.2 / 2 / 2` is a **pure no-op**: same struct values → same measurement → same bytes. Certificate's `@line_height 1.2` (`certificate.ex:306`) is used only in `line_h/1` measurement, never on a text run — unaffected.

## TYPE-02: Raise-Path (proven, with teeth)

The typed-error path is fully in place and testable today:

```
FontRegistry.fetch/2 miss → {:error, {:unknown_logical_font, name}}   # font_registry.ex:393
  → Build.validate_block_fonts → {:error, {:unknown_text_font, name}} # build.ex:110-111
```

**`Rendro.render/2` returns `{:error, Rendro.Error.t()}` — it does NOT raise** (`rendro.ex:44-45`). The lowest-level exact-typed assertion is on `Build.run/1`, and there is an existing precedent to mirror:

```elixir
# Source: test/rendro/pdf/font_test.exs:90 [VERIFIED: codebase]
assert {:error, {:unknown_text_font, :heading}} = Build.run(doc)
```

**Recommended TYPE-02 test shape:** construct a theme whose `typography.fonts.heading` (or `.mono`/`.body`) is an unregistered atom (e.g. `:no_such_font`), build a recipe document with `theme:` that theme, and assert `Build.run(doc)` returns `{:error, {:unknown_text_font, :no_such_font}}` — proving no silent Helvetica fallback. (A `Rendro.render/2` variant asserting `{:error, %Rendro.Error{}}` is a valid higher-level companion but the `Build.run/1` assertion is the exact typed proof.) `default/0` fonts are all `:default` (registered), so the default path never enters this branch.

Note: the theme must survive `Rendro.Theme.resolve/1` (the seam calls it). `resolve/1` does not validate font atoms against any registry (it only validates colors), so an unregistered font role passes resolution and the error surfaces at build/validate time — exactly the path under test.

## Byte-Identity Mechanism (confirmed safe)

- **Per-recipe literal-default carries the current value**, so byte-identity holds regardless of whether current sizes match the frozen scale numbers. The frozen `21/16.5/13/10.5/9/8` values apply ONLY on the themed path. Off-scale current sizes (e.g. Invoice 20 ≠ frozen 21) are a non-issue for the default path.
- **Existing goldens are all no-theme renders:** `invoice_byte_identity_test.exs` renders `Invoice.document(toy_data())` with no `theme:` opt and asserts a frozen sha256 (`invoice_byte_identity_test.exs:12,41`). All 7 `*_byte_identity_test.exs` follow this shape. `edge_fixtures.ex` renders un-themed (`recipe_module(family).document(build(...), opts(...))`, L90 — no `theme:` injected). Preserving the no-theme literals keeps every one green with zero re-bless.
- **The `Map.merge` override layer** (`palette/1` pattern) means a future `:typography` override opt is additive and does not affect the no-theme path.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Theme→recipe threading | New opts plumbing | Existing 3-rung `theme:` thread (Phase 120) | Already reaches every `sections/2`; zero new plumbing (CONTEXT §Reusable Assets) |
| Type-scale numbers | A `:math.pow` runtime formula | The materialized `@default_typography.scale` (`theme.ex:77`) | Frozen explicit points (Phase 119 D-03) — byte-reproducible, no float drift |
| Font-role resolution | A per-recipe font lookup/fallback | `FontRegistry.resolve_pdf_font/3` via the atom role | Existing resolution path + typed error; three logical atoms, no shape change |
| Unregistered-font handling | A rescue/fallback to Helvetica | The existing `{:unknown_text_font, _}` error | TYPE-02 demands raise-not-substitute; the path already ships (`build.ex:110`) |
| No-theme size defaults | Reading `default/0` on the no-theme path | Per-recipe literal-default map | Reading `default/0` would apply the frozen `21/16.5/…` scale and BREAK byte-identity |

**Key insight:** The entire phase is READ wiring on surfaces that already exist. The only genuinely net-new artifact is the per-recipe literal-default typography map — and its values are dictated (not designed) by each recipe's current size/font/leading literals.

## Common Pitfalls

### Pitfall 1: Reading `default/0` instead of per-recipe literals on the no-theme path
**What goes wrong:** Size jumps from the recipe's current literal (e.g. Invoice Total Due 20) to the frozen scale value (21) → every byte-identity + Phase-117 stress golden breaks.
**Why:** The frozen scale is the *themed* value; the *no-theme* path must reproduce today's literals.
**How to avoid:** `case opts[:theme] do nil -> <per-recipe literals>; theme -> ...resolve(theme).typography end` — never `Rendro.Theme.default().typography` in the `nil` branch.
**Warning sign:** any `*_byte_identity_test.exs` sha256 drift after wiring.

### Pitfall 2: Certificate — seaming the text run but not the measurement math
**What goes wrong:** `@body_size`/`@title_size`/etc. feed `line_h/1` and `text_width/3` centering (`certificate.ex:338-345, 372`). If the `%Text{}` reads the seam but the measurement still reads the old attr, themed sizes de-center; even on no-theme a mixed read can drift.
**How to avoid:** Resolve the size once per element and pass it to BOTH the text run AND the measurement call.
**Warning sign:** certificate golden drift or visibly off-centre content on themed renders.

### Pitfall 3: BrandedInvoice — overwriting the brand font with a role default
**What goes wrong:** Seaming L213/L214 to `font: fonts.heading` (`:default`) drops the data-driven brand embedded font → byte drift AND loss of brand identity (violates brand⊥theme).
**How to avoid:** Keep `font: font_name` as the literal-default for those two runs; decide themed-path behavior in Q2.
**Warning sign:** `branded_invoice_byte_identity_test.exs` drift.

### Pitfall 4: Ticket — assuming a clean 6-way map
**What goes wrong:** Silently collapsing two of the 7 distinct sizes into one role changes bytes.
**How to avoid:** Resolve Q3 first — exempt one `mono` micro-size from the scale seam.
**Warning sign:** `ticket_byte_identity_test.exs` drift; or a `scale` map that can't hold all 7 values.

### Pitfall 5: `cell_text/2` single-helper font role (Statement, Payslip)
**What goes wrong:** One helper renders both label and amount table columns; giving it `mono` mono-ises labels, giving it `body` leaves amounts non-tabular.
**How to avoid:** Keep one role (`body`) for byte-safety now; split the helper only if a mono amount column is wanted (themed-path refinement, planner's call).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline `size:` literals scattered per call site | Named-role seam (`size: scale.<role>`) | Phase 122 (this) | Uniform cross-recipe hierarchy on the themed path; a no-inline-`size:` teeth test can guard it |
| Colors seamed, typography deferred (Phase 120 D-04) | Typography read enabled | Phase 122 | The `no_inline_color_literals_test.exs:81` "no `.typography` read" assertion (D-04 guard) must be RELAXED/removed this phase (see Metadata risk) |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `typography/1` seam name/shape (mirroring `palette/1`) | Standard Stack | None — explicitly planner's discretion (CONTEXT §Discretion) |
| A2 | Anchor-amount → `mono`, name/title-anchor → `heading` font convention | Mapping tables | Low — all fonts are `:default` on no-theme path, so font role choice is byte-identical now; only affects Phase-123 themed renders |
| A3 | `INVOICE #<id>` → `mono` vs `heading` (title with embedded ID) | Invoice table | Low — byte-identical now; themed-path aesthetic only |
| A4 | Ticket resolution via exempting one `mono` micro-size (Q3 recommendation) | Ticket / Q3 | Medium — this is a binding-constraint intersection; needs planner sign-off before Ticket plan |
| A5 | BrandedInvoice display anchor = brand name @18 (no Total-Due run) (Q1) | BrandedInvoice / Q1 | Medium — D-01 names "Total Due" but no such run exists; needs a decision |

## Open Questions

### Q1 — BrandedInvoice has no Total-Due text run; where does `display` bind?
- **What we know:** D-01 names BrandedInvoice's anchor "Total Due amount," but totals live inside `Rendro.table/2` (`branded_invoice.ex:226-235`), not a `%Text{}`. The only `%Text` runs are brand name (18), invoice id (12), date (10), thank-you (10).
- **What's unclear:** Whether to (a) bind `display` to the brand name (18, the current largest run), (b) leave BrandedInvoice with no `display` element (violates "exactly one per recipe"), or (c) promote the table total to a `%Text` (scope creep, byte-risk).
- **Recommendation:** Bind `display` to the brand name (18) — it is BrandedInvoice's de-facto "one key fact" (a branded invoice leads with brand). Document the deviation from the literal "Total Due" wording. Do NOT add a new total run (byte-identity risk). Needs planner confirmation.

### Q2 — BrandedInvoice brand-font on the themed path
- **What we know:** L213/L214 use `font: font_name` (data-driven brand embedded font, brand⊥theme). Literal-default must stay `font_name` for byte-identity.
- **What's unclear:** On the themed path, does the brand name/id keep `font_name` (brand wins) or switch to `fonts.heading`?
- **Recommendation:** Brand font wins (keep `font: font_name` on both paths for those two runs; do not seam them to a theme role). Rationale: brand⊥theme is a standing Key Decision; the theme controls *how* (tokens), the brand controls *who* (assets/fonts). Seam only the non-brand runs (date, thank-you) to roles. Needs planner confirmation.

### Q3 — Ticket: 7 distinct sizes vs 6 roles
- **What we know:** Distinct sizes {26,16,10,9,8,7,6}; byte-identity forbids collapsing any two; 6 roles can name at most 6 distinct literals.
- **What's unclear:** Which size stays outside the scale seam.
- **Recommendation:** **Exempt `@present_code_size` (6) — and if needed `@caption_size` (7) — from the scale seam, keeping them literal module attrs, and seam only their FONT to `mono`.** The present-code and reference-caption are machine/label micro-text, not part of the semantic display→caption hierarchy; the 6-step scale governs the semantic ramp. This drops the scale-seamed distinct set to ≤6 (e.g. 26→title, 16→subtitle, 10→body, 9→small, 8→caption, reference-code 8→**display** anchor via non-monotone assignment). Alternative (rejected): a 7th private role — but the frozen theme scale has no 7th step, so the themed path has nothing to read. Needs planner sign-off; this is the phase's one genuine architecture decision.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) |
| Config file | `mix.exs` (aliases `ci`, `ci.fast`, `test.all`, `verify`; `elixirc_paths(:test)` includes `test/support`) |
| Quick run command | `mix test test/rendro/recipes/<recipe>_byte_identity_test.exs` |
| Full suite command | `mix test` (or `mix test.all` / `mix ci`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TYPE-01 | No-theme render byte-identical after size seam | golden | `mix test test/rendro/recipes/invoice_byte_identity_test.exs` (×7 recipes) | ✅ (all 7 `*_byte_identity_test.exs`) |
| TYPE-01 | Themed render differs from no-theme (seam is live) | unit | `mix test test/rendro/recipes/invoice_opts_threading_test.exs` | ✅ (all 7 `*_opts_threading_test.exs`) |
| TYPE-01 | No inline `size:` literal in section builders | static scan | `mix test test/rendro/recipes/no_inline_size_literals_test.exs` | ❌ Wave 0 (mirror `no_inline_color_literals_test.exs`) |
| TYPE-02 | Unregistered font role → `{:unknown_text_font, _}` | unit | `mix test test/rendro/recipes/<recipe>_typography_test.exs` | ❌ Wave 0 (new; pattern = `font_test.exs:90`) |
| TYPE-03 | Edge/stress matrix byte-identical (leading no-op) | golden | `mix test test/rendro/edge_matrix_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** the touched recipe's `*_byte_identity_test.exs` + `*_opts_threading_test.exs`.
- **Per wave merge:** all 7 byte-identity tests + `edge_matrix_test.exs` + `no_inline_color_literals_test.exs`.
- **Phase gate:** `mix test` (full suite) green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/rendro/recipes/no_inline_size_literals_test.exs` — TYPE-01 teeth (mirror `no_inline_color_literals_test.exs` structure: exclude the `typography/1`/`palette/1` body region + `@*_size` attr definitions; scan for `size:` followed by an integer/float literal in section builders). Planner's call whether to include.
- [ ] `test/rendro/recipes/<recipe>_typography_test.exs` (or fold into existing `*_opts_threading_test.exs`) — TYPE-02 raise-path per recipe (or a representative subset), asserting `Build.run(doc)` → `{:error, {:unknown_text_font, _}}` on an unregistered-font theme.
- [ ] **Relax the D-04 guard:** `no_inline_color_literals_test.exs:81` asserts "no recipe file performs a `.typography` read" (Phase-120 colors-only boundary). Phase 122 legitimately adds `.typography` reads → this assertion must be removed or inverted. Flag as a pre-declared red→green step.

*Framework already present; no install needed.*

## Security Domain

`security_enforcement` posture: this is a deterministic PDF library with no auth, session, network, or datastore surface in the recipe layer. Most ASVS categories are **N/A by construction**.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes (weak) | Errors-as-product: recipe `validate_data!/1` + the typed `{:unknown_text_font, _}` path (TYPE-02) — an unregistered font atom is rejected, never silently substituted |
| V6 Cryptography | no | (byte-identity uses `:crypto.hash(:sha256, …)` for golden verification only — not a security control) |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Silent font fallback masking a bad theme | Tampering / Repudiation | Typed `{:unknown_text_font, _}` raise-path (TYPE-02) — fail loud, never substitute |

No new attack surface: zero new dependencies, no file/network I/O added, engine untouched.

## Environment Availability

Skipped — no external dependencies. This phase is Elixir-stdlib code/test changes in the recipe layer only (CONTEXT §Integration Points: "None into the engine").

## Sources

### Primary (HIGH confidence — direct codebase evidence)
- `lib/rendro/theme.ex:75-134, 321` — `@default_typography`, `typography` type, compact-leading
- `lib/rendro/text.ex:15-23, 51-61` — `%Text{}` defaults, `normalize_font/1`
- `lib/rendro/font_registry.ex:11, 221-240, 323-329, 390-395` — `:default`, resolve path, `{:unknown_logical_font, _}`
- `lib/rendro/pipeline/build.ex:102-119` — `{:unknown_text_font, _}` mapping (validate_block_fonts)
- `lib/rendro/recipes/{invoice,branded_invoice,statement,receipt,certificate,payslip,ticket}.ex` — all `size:`/`font:` call sites and `palette/1` seams (line numbers in tables)
- `test/rendro/recipes/no_inline_color_literals_test.exs`, `invoice_byte_identity_test.exs`, `invoice_opts_threading_test.exs`, `test/rendro/pdf/font_test.exs:90` — test templates
- `test/support/edge_fixtures.ex:89-90` — un-themed edge renders

### Secondary / Tertiary
- None — no web research; codebase survey only.

## Metadata

**Confidence breakdown:**
- Standard stack / seam pattern: HIGH — `palette/1` verbatim across all 7 recipes.
- Per-recipe size→role mapping: HIGH — every call site read at `file:line`; distinct-size tallies exact.
- Font-role assignment (mono vs heading): MEDIUM — byte-identical now (all `:default`), so choices are low-risk; only affect Phase-123 themed aesthetics (A2/A3).
- Ticket (Q3) & BrandedInvoice (Q1/Q2) resolutions: MEDIUM — recommendations sound but need planner sign-off (binding-constraint intersections).
- TYPE-02 raise-path: HIGH — path shipped, existing assertion at `font_test.exs:90`.
- TYPE-03 no-op: HIGH — grep-confirmed no recipe sets `line_height`/`widows`/`orphans`.

**Known red→green step:** the D-04 "no `.typography` read" guard (`no_inline_color_literals_test.exs:81-99`) must be relaxed/removed this phase — pre-declare it, mirroring the Phase-119 public-API manifest red→green lesson.

**Research date:** 2026-07-27
**Valid until:** 2026-08-26 (stable — internal codebase, no fast-moving external deps)

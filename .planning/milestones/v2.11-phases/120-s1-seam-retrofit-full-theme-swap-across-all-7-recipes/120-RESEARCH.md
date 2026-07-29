# Phase 120: S1 seam retrofit + full `theme:` swap across all 7 recipes - Research

**Researched:** 2026-07-27
**Domain:** Elixir PDF-generation recipe layer — color-seam retrofit + design-token threading, byte-determinism preservation
**Confidence:** HIGH (every claim grounded in direct v2.11 source reads + live execution on this repo)

## Summary

Phase 120 is near-mechanical byte-preservation plumbing, heavily pre-specified by CONTEXT.md (D-01..D-04) and the milestone-b SUMMARY. This research **verified every load-bearing assumption against the shipped code** and found the phase to be lower-risk than feared, with two concrete surprises the planner must handle. The `Rendro.Theme` value shipped in Phase 119 is exactly as documented (9 color roles, idempotent `resolve/1`, integer `{r,g,b}` tuples), and the reference seam in `invoice.ex` is precisely where CONTEXT says it is.

**The single most important verified finding:** adding `color: {0,0,0}` to a currently-uncolored text block produces **byte-identical** PDF output (proven by live render + sha256 comparison — see Code Examples). This de-risks D-03 entirely: the Receipt/BrandedInvoice ink seam is a genuine no-op on the no-theme path, and the whole "swap to `theme.colors.*` with all-black/white literal defaults" strategy is byte-safe by construction.

**Two surprises the planner MUST address (both verified by live probe):** `Rendro.Recipes.Receipt.page_template/1` and `Rendro.Recipes.BrandedInvoice.page_template/1` **raise `KeyError`** when passed a `:palette` or `:theme` opt today — Receipt uses `Keyword.delete(opts, :header_height)` (forwards everything else to `struct!/2`), and BrandedInvoice uses `Keyword.merge(defaults, opts)` (forwards everything). Both need an opts whitelist added during retrofit. The other 5 recipes are already opts-safe. Additionally, **BrandedInvoice has NO existing golden** and is absent from the `edge_matrix_test.exs` byte-golden matrix — it needs a net-new byte-identity test/golden for PLUMB-01/03.

**Primary recommendation:** Two split commits per the locked discipline. Commit 1 (retrofit, PLUMB-01): add `palette/1` seams + opts whitelists to the 4 un-seamed recipes, move inline literals into role reads, add 4 fresh `*_byte_identity_test.exs` files (statement/certificate/receipt/branded_invoice — the exact 4 recipes lacking one today) freezing toy sha256s. Commit 2 (swap, PLUMB-02/03): extend every `palette/1` to branch `base = if theme, do: Theme.resolve(theme).colors, else: <literal defaults>`, admit `:theme` in all 7 whitelists, add themed threading tests, and prove no-theme byte-identity via the frozen goldens + green `edge_matrix`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — Legacy `:palette` opt: preserve, override-wins (PLUMB-02 back-compat)**
- **Preserve** `:palette` — do NOT retire it. Resolution per recipe:
  `base = if theme = opts[:theme], do: Rendro.Theme.resolve(theme).colors, else: <today's literal defaults>`,
  then `Map.merge(base, Keyword.get(opts, :palette, %{}))` as the **final** layer.
- **Precedence:** explicit `:palette` override > `:theme` > recipe literal defaults.
  An explicit `:palette` override wins over a supplied theme (never silently ignored).
- **Evidence:** exactly ONE test dependent — `test/rendro/recipes/invoice_opts_threading_test.exs`
  asserts a `:palette` override changes only the footer color. Merge-on-top keeps it green.
- Each rung defensively `Rendro.Theme.resolve/1`-es its input — resolve is idempotent (Phase 119 D-01).

**D-02 — Per-literal role mapping; no-theme path stays byte-identical (PLUMB-01/03)**
- Retrofit `palette/1` default per recipe reproduces its **exact current literal** — per-recipe, NOT uniform all-black:
  - **Certificate:** frame `{34,34,34}` → `rule` role; retrofit default for `rule` is `{34,34,34}` (NOT `{0,0,0}`).
  - **Statement:** band fill `{245,245,245}` → `surface`; band stroke `{0,0,0}` → `rule`.
  - **Receipt / BrandedInvoice:** primary text implicit-black → `ink`, retrofit default `{0,0,0}` (D-03).
- **No golden re-bless on the no-theme path** — every retrofit default equals today's literal.
- **Flag every literal→role mapping explicitly in the plan** (a deliberate, reviewable choice).

**D-04 — Typography threading boundary: colors only in 120 (scope split with Phase 122)**
- Phase 120 threads the **whole resolved `%Theme{}`** value through the 3 rungs but reads **only** `theme.colors.*`.
- All `theme.typography.*` reads belong to Phase 122 (no new plumbing — value already threaded here).

### Claude's Discretion

**D-03 — Colorless recipes (Receipt, BrandedInvoice): seam text→ink NOW *(user decision, locked as chosen)***
- Introduce explicit `theme.colors.ink` reads on the **primary text** of both recipes now, defaulting to `{0,0,0}` so no-theme render is byte-identical. Makes both genuinely themable now and Phase 121 dark mode "just works."

- Exact `defp` seam helper naming per recipe; whether the 3-seamed and 4-retrofit recipes are planned as one phase or split slices (research permits folding, but **retrofit commits MUST stay split from swap commits regardless** — research line 48).
- Exact ordering of the 4 retrofit commits.
- Which specific text/section elements in Receipt/BrandedInvoice count as "primary text" for the D-03 ink seam (keep byte-identity the binding constraint).

### Deferred Ideas (OUT OF SCOPE)

- **`theme.typography.*` reads into `%Text{}`** — Phase 122.
- **Light/dark background-fill rect + `mode` handling** — Phase 121.
- **`default/0` value tuning, themed/dark gallery renders, support-matrix `theming.*` rows, `guides/theming.md`** — Phase 123.
- **Retiring `:palette` entirely** — rejected for v2.11 (back-compat).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PLUMB-01 | The 4 un-seamed recipes (Statement, Certificate, Receipt, BrandedInvoice) retrofitted with a byte-identical `palette/1` seam (defaults = today's exact literals), proven by fresh sha256 goldens in commits *separate* from any theme wiring. | Exact literal inventory verified (Statement L305–306, Certificate L374); byte-identity of `color: {0,0,0}` seam verified live; the 4 recipes are exactly those lacking a `*_byte_identity_test.exs` today — add one each. |
| PLUMB-02 | All 7 recipes thread a resolved `theme:` through the 3-rung pattern, reading `theme.colors.*`, with each recipe's opts whitelist admitting `:theme`. | Reference seam + call sites captured for all 7; Theme.resolve/1 idempotence + 9-role contract confirmed; **2 whitelists (Receipt, BrandedInvoice) must be added — they KeyError today** (verified live). |
| PLUMB-03 | `document(data)` with no `theme:` opt is a byte-identity no-op for all 7 recipes. | Existing `edge_matrix_test.exs` (62 byte-golden cells across 6 recipes) + `invoice/payslip/ticket_byte_identity_test.exs` are the guards; **BrandedInvoice is NOT in edge_matrix and has no golden** — needs a net-new byte-identity golden. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Resolve `:theme` opt → color map | Recipe layer (`palette/1`) | `Rendro.Theme.resolve/1` | Theme is a pure inert value; recipes read it. Engine never sees `%Theme{}`. |
| Thread opts document→template→sections | Recipe `document/2`/`page_template/1`/`sections/2` | — | The 3-rung tiered-composition pattern already threads `opts`; only the whitelist + seam change. |
| Read color role → `%Text{color:}` / `%Path{fill/stroke:}` | Recipe section builders | — | Colors resolve to concrete `{r,g,b}` before draw; no float reaches byte stream. |
| Byte-determinism guarantee | `Rendro.render(doc, deterministic: true)` (engine) | golden sha256 tests | Engine unchanged this phase; determinism is a within-version golden guarantee. |

**Zero engine integration.** All 7 changes are confined to `lib/rendro/recipes/*.ex` + their test files. The deterministic pipeline (`build → compose → measure → paginate → render → validate`) is untouched.

## Standard Stack

No new dependencies. Everything is existing project surface.

### Core
| Module | Purpose | Why Standard |
|--------|---------|--------------|
| `Rendro.Theme` (`lib/rendro/theme.ex`) | `resolve/1` → `%Theme{colors: %{...9 roles...}}` | Shipped Phase 119; idempotent; validates every role via `Rendro.Color.validate/1`. |
| `Rendro.Test.Golden` (`test/support/golden.ex`) | `assert_deterministic!/1`, `assert_or_bless/3` | Existing sha256 golden infra; MISSING ref hard-flunks; bless via `MIX_GOLDEN_BLESS=true`. |
| `Rendro.Recipes.Invoice.palette/1` (invoice.ex L466–481) | The reference S1 seam to replicate | Already the blessed pattern; comment L460–465 says Theme "can slot in." |

**Installation:** none — `mix.exs` deps change for this phase: **none** `[VERIFIED: repo grep + milestone-b SUMMARY]`.

**No `## Package Legitimacy Audit` section:** this phase installs zero external packages.

## Reference Seam — exact shape to replicate (`invoice.ex`)

`[VERIFIED: direct read of lib/rendro/recipes/invoice.ex]`

**`palette/1` — L466–481 (note: 7 roles, NO `positive`/`negative`):**
```elixir
defp palette(opts) do
  overrides = Keyword.get(opts, :palette, %{})

  Map.merge(
    %{
      ink: {0, 0, 0},
      muted: {0, 0, 0},
      accent: {0, 0, 0},
      on_accent: {0, 0, 0},
      background: {255, 255, 255},
      surface: {255, 255, 255},
      rule: {0, 0, 0}
    },
    overrides
  )
end
```

**Threading call sites (colors = palette(opts)):** L216 `header_section/2`, L350 `footer_section/2`, L407 `build_totals_blocks/2`.

**Roles actually read into draw output:** `colors.ink` (footer L356, issuer L375), `colors.muted` (customer L382, due_date L386, terms L390), `colors.accent` (dominant total L437). `surface`/`rule`/`background`/`on_accent` are defined in the map but not currently read by Invoice.

**Opts whitelist — L137–148 (the mechanism that keeps recipe-level opts off `struct!/2`):**
```elixir
template_opts =
  Keyword.take(opts, [
    :name, :width, :height,
    :margin_top, :margin_right, :margin_bottom, :margin_left,
    :regions
  ])
Rendro.page_template(Keyword.merge(defaults, template_opts))
```
`:palette` (and, after this phase, `:theme`) is intentionally NOT in the whitelist, so it threads to `sections/2`/`palette/1` instead of raising `KeyError` at `struct!/2`.

### The D-01 swap transform (apply to all 7 `palette/1` fns in Commit 2)
```elixir
defp palette(opts) do
  base =
    case opts[:theme] do
      nil   -> %{ ...today's literal defaults for THIS recipe... }
      theme -> Rendro.Theme.resolve(theme).colors        # idempotent; 9 integer-{r,g,b} roles
    end

  Map.merge(base, Keyword.get(opts, :palette, %{}))       # :palette override wins (D-01)
end
```
This preserves the invoice_opts_threading_test invariant (no theme → literal defaults → `:palette` override still changes only the footer). When a theme IS present, `base` becomes the resolved 9-role theme map (a superset of the 7 the recipes read).

## Per-Recipe Literal → Role Inventory (D-02)

`[VERIFIED: direct source reads]` — this is the reviewable literal→role map the plan MUST flag explicitly.

| Recipe | Seamed today? | Inline literal (location) | Role | No-theme retrofit default | Swap notes |
|--------|---------------|---------------------------|------|---------------------------|------------|
| **Invoice** | ✅ | none (already seamed) | ink/muted/accent | `{0,0,0}` / `{0,0,0}` / `{0,0,0}` | Swap-only: add `:theme` branch + whitelist entry. |
| **Payslip** | ✅ | none (palette L677–692) | ink/muted/surface/rule | ink`{0,0,0}` muted`{0,0,0}` surface`{255,255,255}` rule`{0,0,0}` | Swap-only. Reads at L303/371/443/658. Band fill=`surface`, stroke=`rule` (summary_section L379–387). |
| **Ticket** | ✅ | none (palette L509–524) | muted/ink/rule | muted`{0,0,0}` ink`{0,0,0}` rule`{0,0,0}` | Swap-only. Reads at L273/353/447. Perforation+box stroke=`rule` (L366/L379). |
| **Statement** | ❌ retrofit | fill `{245,245,245}` (L305); stroke `{0,0,0}` (L306) — `closing_backdrop` in `header_section/2` | fill→`surface`; stroke→`rule` | surface`{245,245,245}` rule`{0,0,0}` | opts-safe (Keyword.take L199–208). Add `palette/1`, thread into `header_section/2`, add `:palette`/`:theme` to whitelist. Stroke `width: 0.75` stays literal. |
| **Certificate** | ❌ retrofit | frame color `{34,34,34}` (`resolve_frame_opts/7` default L374; used as `frame_opts.color` stroke L188) | frame→`rule` | rule`{34,34,34}` **(NON-BLACK — the stress case)** | opts-safe (explicit construction). Change `Map.get(border_map, :color, {34,34,34})` → `Map.get(border_map, :color, colors.rule)`; `colors.rule` default `{34,34,34}` keeps byte-identity AND preserves the `border: %{color: ...}` override AND lets a theme set the frame. `@border_allowed_keys` (L62) already lists `:color` — no change. Thread `palette(opts)` into `sections/2`. |
| **Receipt** | ❌ retrofit | **none** (D-03 ink seam) | primary text→`ink` | ink`{0,0,0}` | **page_template RAISES KeyError on `:palette`/`:theme` today** (L178 `Keyword.delete(opts, :header_height)`) → MUST add whitelist. Add `color: colors.ink` to primary text (title L262, customer L263, date L264, merchant L288, minor/total L388/L395). Byte-identical (verified). |
| **BrandedInvoice** | ❌ retrofit | **none** (D-03 ink seam) | primary text→`ink` | ink`{0,0,0}` | **page_template RAISES KeyError on `:palette`/`:theme` today** (L92 `Keyword.merge(defaults, opts)`) → MUST add whitelist. Add `color: colors.ink` to header (brand L160, id L161, date L162) + footer (L191). **No existing golden** — add byte-identity test. |

**`%Theme{}` colors contract (Phase 119, `lib/rendro/theme.ex` L48–58) — the 9 roles a theme resolves to:**
`ink {16,24,39}`, `muted {91,101,115}`, `accent {44,107,237}`, `on_accent {255,255,255}`, `background {255,255,255}`, `surface {247,243,234}`, `rule {196,188,169}`, `positive {20,122,75}`, `negative {194,65,50}`. `[VERIFIED]` All integer tuples; `resolve/1` deep-merges + validates each via `Rendro.Color.validate/1` and is idempotent (`resolve(resolve(x)) == resolve(x)`, theme.ex L188–189, L200–222).

## Architecture Patterns

### Threading flow (unchanged structurally — only whitelist + seam edited)
```
caller ──opts (may carry :theme, :palette)──► document/2
                                                │
                    ┌───────────────────────────┼───────────────────────────┐
                    ▼                           ▼                           ▼
             page_template(opts)          sections(data, opts)      (Document builder)
             │ Keyword.take whitelist      │ per section builder
             │ → :theme/:palette DROPPED   │   colors = palette(opts)
             │   (never hits struct!/2)    │   base = theme?resolve(theme).colors : literals
             ▼                             │   Map.merge(base, opts[:palette]||%{})
        %PageTemplate{}                    ▼
                              %Text{color: colors.ink} / %Path{fill: colors.surface, ...}
                                            │
                                            ▼  Rendro.render(doc, deterministic: true)
                                    integer {r,g,b} → byte stream (no float at draw time)
```
The theme value threads via `opts`; `page_template/1` (layout-only) must merely NOT choke on it (whitelist). `sections/2` reads colors via `palette/1`. This satisfies the "resolved theme through the 3 rungs" requirement.

### Pattern 1: Certificate frame — role default that still honors the `border:` override
**What:** The frame color has three sources of truth in priority order. **When:** Certificate only.
```elixir
# resolve_frame_opts/7 currently (L365–379): Map.get(border_map, :color, {34,34,34})
# Retrofit — thread colors in and use rule as the default:
color: Map.get(border_map, :color, colors.rule)   # colors.rule default {34,34,34}
```
Precedence becomes: explicit `border: %{color: ...}` > theme `rule` > literal `{34,34,34}`. Byte-identical with no border override + no theme.

### Anti-Patterns to Avoid
- **Do NOT combine retrofit + swap in one commit.** Research line 48: retrofit goldens commit SEPARATELY from theme wiring. This is the milestone's split-commit discipline (mirrors Milestone A "split the verbatim move from the normalization").
- **Do NOT re-bless any existing `edge_matrix` golden on the no-theme path.** If a retrofit drifts a golden, that is a DEFECT, not a refresh (`golden.ex` L84). A green existing golden IS the byte-identity proof.
- **Do NOT add `:theme`/`:palette` to a `page_template/1` whitelist.** They must be dropped there so they thread to `palette/1`.
- **Do NOT hand-roll color resolution / merge order.** Use `Rendro.Theme.resolve/1` and the exact `Map.merge(base, palette_override)` order (D-01).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Theme→color map | Manual struct field plucking | `Rendro.Theme.resolve/1` then `.colors` | Idempotent, validates every role, deep-merges partials without `KeyError`. |
| Byte-identity proof | Ad-hoc PDF diffing | `Rendro.Test.Golden` sha256 helpers + `edge_matrix` | Cross-platform-stable hashes; missing-ref hard-flunk; bless is human-gated. |
| Opts→sections threading | New plumbing | Existing tiered `document/2`→`page_template/1`→`sections/2` | Already threads `opts`; only whitelist + seam change. |
| Color validation | Re-validating tuples in recipes | `resolve/1` already validated | Recipes receive already-validated integer tuples. |

**Key insight:** Every "new" capability this phase needs already exists. The work is moving 4 inline literals behind a copy of an existing 16-line seam and adding one `case opts[:theme]` branch to 7 copies of it.

## Runtime State Inventory

This is a code-only refactor with a byte-identity guarantee — no stored data, live-service config, OS registration, secrets, or build artifacts embed the changed values.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — colors are compile-time literals in recipe source, not stored anywhere. | none |
| Live service config | None — no external service references recipe colors. | none |
| OS-registered state | None. | none |
| Secrets/env vars | None. (`MIX_GOLDEN_BLESS`/`MIX_GOLDEN_DUMP` are test-time knobs, not persisted state.) | none |
| Build artifacts | Existing committed goldens under `priv/goldens/{invoice,statement,certificate,receipt,payslip,ticket}/` — these are the PLUMB-03 guards and must stay green (no re-bless). **`priv/goldens/branded_invoice/` does not exist** — a fresh golden dir is created for it. | Add branded_invoice golden; keep all others green. |

## Common Pitfalls

### Pitfall 1: Receipt / BrandedInvoice page_template KeyError
**What goes wrong:** Threading `:theme`/`:palette` through `document/2` reaches `page_template/1`, which forwards unknown opts to `Rendro.page_template` → `struct!(PageTemplate, ...)` → `KeyError`. `[VERIFIED live: both raise KeyError today]`
**Why:** Receipt does `Keyword.merge(defaults, Keyword.delete(opts, :header_height))` (L178) — only deletes `:header_height`. BrandedInvoice does `Keyword.merge(defaults, opts)` (L92) — forwards everything.
**How to avoid:** Add a `Keyword.take([...struct keys...])` whitelist to both (copy invoice.ex L137–148). Certificate is safe (constructs the template with explicit keys); Invoice/Statement/Payslip/Ticket already use `Keyword.take`.
**Warning signs:** A recipe threading test that calls `page_template(theme: ...)` red-builds with `KeyError`.

### Pitfall 2: Certificate non-black `{34,34,34}` default (the stress case)
**What goes wrong:** Mapping the frame to `rule` with the theme's default `rule {196,188,169}` on the no-theme path would move bytes.
**Why:** The retrofit default must equal today's literal `{34,34,34}`, NOT the eventual theme value and NOT `{0,0,0}`.
**How to avoid:** The recipe's OWN literal-default map sets `rule: {34,34,34}`; only when a `:theme` is supplied does `rule` become the theme's value. Flag this explicitly in the plan (D-02).
**Warning signs:** Certificate `text_wrap`/`missing_optional_fields`/`page_size_a4_letter` goldens flap.

### Pitfall 3: Assuming `color: {0,0,0}` might move bytes (it does not)
**What goes wrong:** Over-cautious plans avoid the D-03 ink seam fearing byte drift.
**Why not:** Verified — an explicit `{0,0,0}` color renders byte-identically to no color arg (see Code Examples). D-03 is safe.
**Warning signs:** none — this is a de-risking finding.

### Pitfall 4: BrandedInvoice regression blind spot
**What goes wrong:** Trusting `edge_matrix` to catch BrandedInvoice drift — it can't; BrandedInvoice is not in `@families` and has no golden.
**How to avoid:** Add `branded_invoice_byte_identity_test.exs` (mirror `invoice_byte_identity_test.exs`) freezing a toy sha256 in the RETROFIT commit.

## Code Examples

### VERIFIED: explicit `{0,0,0}` == no color (the D-03 de-risking proof)
```elixir
# Live probe (2026-07-27) — both branches sha256 to the SAME value:
#   no color:        0ee719f95f5f4587bafd7957fc4a98cd03941ba3ef5ebbc2c3cbb3f859a5b93a
#   explicit {0,0,0}: 0ee719f95f5f4587bafd7957fc4a98cd03941ba3ef5ebbc2c3cbb3f859a5b93a  → IDENTICAL
Rendro.text("Hello World", size: 14)                    # current Receipt/BrandedInvoice
Rendro.text("Hello World", size: 14, color: {0, 0, 0})  # after D-03 ink seam — byte-identical
```

### Fresh retrofit byte-identity test (mirror invoice_byte_identity_test.exs)
```elixir
# test/rendro/recipes/branded_invoice_byte_identity_test.exs — one per retrofit recipe
@toy_golden_sha256 "<blessed in the RETROFIT commit, before any theme wiring>"

test "fresh render sha256 matches the frozen retrofit baseline" do
  doc = BrandedInvoice.document(toy_data())          # no :theme, no :palette
  assert {:ok, pdf} = Rendro.render(doc, deterministic: true)
  assert Base.encode16(:crypto.hash(:sha256, pdf), case: :lower) == @toy_golden_sha256
end
```

### Themed threading test (mirror invoice_opts_threading_test.exs, PLUMB-02)
```elixir
test ":theme threads through page_template/1 without KeyError" do
  assert %Rendro.PageTemplate{} = Receipt.page_template(theme: Rendro.Theme.default())
end

test ":palette override wins over :theme (D-01)" do
  themed  = Receipt.sections(data, theme: Rendro.Theme.default())
  ovr     = Receipt.sections(data, theme: Rendro.Theme.default(), palette: %{ink: {200,0,0}})
  refute themed == ovr    # explicit :palette still wins
end

test "no-theme render is byte-identical to pre-swap (PLUMB-03)" do
  assert Receipt.sections(data) == Receipt.sections(data, [])
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline `{r,g,b}` in 4 recipe section builders | Role reads via `palette/1` seam | This phase (retrofit) | Recipes become themable without a color rewrite. |
| `:palette` map override only | `:theme` (resolved `%Theme{}`) with `:palette` as final override layer | This phase (swap) | Design-token theming; `:palette` preserved for back-compat (D-01). |

**Deprecated/outdated:** none. `:palette` is explicitly preserved, not deprecated (D-01; retiring it is deferred to a future major).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | (none) | — | All claims in this research were verified against live source/execution or cited to specific line numbers. No `[ASSUMED]` claims. |

**This table is empty:** every factual claim was verified by direct read or live probe on this repo — no user confirmation needed.

## Open Questions

1. **Which exact text blocks are "primary text" for the D-03 ink seam?**
   - What we know: byte-identity holds regardless (default `{0,0,0}`), so any/all text blocks are safe to seam.
   - What's unclear: whether to seam ALL text (fully dark-mode-ready) or only headline/total text.
   - Recommendation (Claude's discretion per CONTEXT): seam ALL text runs in Receipt (title, customer, date, merchant, minor totals, dominant total) and BrandedInvoice (brand, id, date, footer) to `colors.ink` — Phase 121 dark mode then "just works" with zero further retrofit. Byte-identity is preserved either way.

2. **Dedicated retrofit byte-identity tests vs. relying on `edge_matrix`?**
   - What we know: Statement/Certificate/Receipt already have `edge_matrix` byte goldens; BrandedInvoice does not.
   - Recommendation: add a dedicated `*_byte_identity_test.exs` for all 4 retrofit recipes (they are exactly the 4 lacking one). This mirrors the existing invoice/payslip/ticket convention and gives PLUMB-01 an explicit, per-recipe frozen baseline in the retrofit commit, independent of the broader matrix.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix toolchain | compile + `mix test` | ✓ | project-pinned (~> 1.19) | — |
| `Rendro.Theme` module | theme swap (Phase 119) | ✓ | shipped, on adapter tier | — |
| Golden infra (`test/support/golden.ex`) | PLUMB-01/03 proofs | ✓ | in repo | — |

No external tools/services. Green baseline confirmed: `invoice_opts_threading_test` + `invoice_byte_identity_test` + `edge_matrix_test` = **78 tests, 0 failures** `[VERIFIED live 2026-07-27]`.

## Validation Architecture

**Nyquist validation is enabled** (`.planning/config.json` → `workflow.nyquist_validation: true`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (`use ExUnit.Case, async: true`) |
| Config file | `test/test_helper.exs` (standard); goldens under `priv/goldens/<family>/<dim>.sha256` |
| Quick run command | `mix test test/rendro/recipes/<recipe>_byte_identity_test.exs test/rendro/recipes/<recipe>_opts_threading_test.exs` |
| Full suite command | `mix test` |
| Golden bless (human-gated) | `MIX_GOLDEN_BLESS=true mix test <file>` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLUMB-01 | 4 retrofit recipes render byte-identically after seam (fresh frozen sha256, retrofit commit) | golden/unit | `mix test test/rendro/recipes/{statement,certificate,receipt,branded_invoice}_byte_identity_test.exs` | ❌ Wave 0 (all 4 new) |
| PLUMB-01 | Existing matrix goldens stay green through retrofit (no re-bless) | golden | `mix test test/rendro/edge_matrix_test.exs` | ✅ |
| PLUMB-02 | `:theme` threads all 3 rungs; `page_template` no KeyError; `:palette` override wins (D-01) | unit | `mix test test/rendro/recipes/*_opts_threading_test.exs` | ⚠️ invoice/branded exist; add theme cases + new files for statement/certificate/receipt/payslip/ticket |
| PLUMB-02 | No inline `{r,g,b}` literal remains in section builders (roles only) | static/source-scan | new claims-style test scanning `lib/rendro/recipes/*.ex` (exclude `palette/1` default maps + non-color numerics like `width: 0.75`) | ❌ Wave 0 (optional but recommended) |
| PLUMB-03 | `document(data)` no-theme = v2.10 bytes for all 7 recipes | golden | `mix test test/rendro/edge_matrix_test.exs test/rendro/recipes/*_byte_identity_test.exs` | ⚠️ 6/7 covered; **branded_invoice new** |

### Sampling Rate
- **Per task commit:** the touched recipe's `*_byte_identity_test.exs` + `*_opts_threading_test.exs` (< 1s).
- **Per wave merge:** `mix test test/rendro/edge_matrix_test.exs test/rendro/recipes/` (byte goldens + all recipe tests).
- **Phase gate:** full `mix test` green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/rendro/recipes/statement_byte_identity_test.exs` — freezes retrofit toy sha256 (PLUMB-01)
- [ ] `test/rendro/recipes/certificate_byte_identity_test.exs` — retrofit toy sha256, incl. `border: true` `{34,34,34}` frame case (PLUMB-01, stress case)
- [ ] `test/rendro/recipes/receipt_byte_identity_test.exs` — retrofit toy sha256 (PLUMB-01)
- [ ] `test/rendro/recipes/branded_invoice_byte_identity_test.exs` — **net-new golden** (PLUMB-01/03; not in edge_matrix)
- [ ] `*_opts_threading_test.exs` for statement/certificate/receipt/payslip/ticket (invoice + branded exist; extend all with `:theme` cases) (PLUMB-02)
- [ ] (Recommended) source-scan test asserting no inline color literal remains in section builders (PLUMB-02)
- [ ] Framework install: none — ExUnit + golden infra already present.

## Security Domain

`security_enforcement` is not set in config (absent = enabled). This is a pure-Elixir, offline PDF-recipe refactor with **no** authn/z, network, session, or secret surface. The only relevant control category is input validation, which is already enforced.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (no auth surface) |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Existing `validate_data!/1` + `validate_border!/2` (errors-as-product `ArgumentError`); `Rendro.Theme.resolve/1` validates every color role via `Rendro.Color.validate/1`. No new untrusted input introduced this phase. |
| V6 Cryptography | no | sha256 here is a golden fingerprint, not a security control — never hand-rolled crypto. |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed color token from caller `:theme`/`:palette` | Tampering/DoS | `Rendro.Theme.resolve/1` → `Rendro.Color.validate/1` raises instructive `ArgumentError` before draw; recipes never reach the pipeline with an invalid tuple. |
| Byte-nondeterminism leak (supply-chain/reproducibility) | Repudiation | `assert_deterministic!/1` renders twice and refuses to bless a differing pair; goldens are human-gated. |

## Sources

### Primary (HIGH confidence)
- `lib/rendro/recipes/invoice.ex` — reference `palette/1` (L466–481), call sites (L216/350/407), whitelist (L137–148), roles read (L356/375/382/386/390/437).
- `lib/rendro/recipes/{statement,certificate,receipt,branded_invoice,payslip,ticket}.ex` — full reads; literal inventory, whitelist mechanisms, section builders.
- `lib/rendro/theme.ex` — `resolve/1` idempotence + validation (L200–222), 9-role `@default_colors` (L48–58), `default/0` (L180).
- `test/support/golden.ex` — sha256 assert/bless doctrine; `test/rendro/recipes/invoice_byte_identity_test.exs` + `invoice_opts_threading_test.exs` + `branded_invoice_opts_threading_test.exs` — test shapes; `test/rendro/edge_matrix_test.exs` — 62-cell byte-golden matrix (6 families, BrandedInvoice absent).
- Live execution (2026-07-27): `color: {0,0,0}` byte-identity proof; `page_template` KeyError probe (Receipt + BrandedInvoice raise; other 5 safe); green baseline (78 tests, 0 failures).
- `.planning/phases/120-.../120-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/research/milestone-b/SUMMARY.md`.

### Secondary (MEDIUM confidence)
- none required — every claim traced to primary source.

### Tertiary (LOW confidence)
- none.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero-dep, all existing modules read directly.
- Architecture / seam pattern: HIGH — reference seam + all 6 other recipes read line-by-line; threading verified.
- Literal→role inventory: HIGH — every literal located by line number.
- Byte-identity risk (D-03): HIGH — proven by live render + sha256.
- Whitelist gotchas: HIGH — Receipt/BrandedInvoice KeyError reproduced live.
- Test/golden shapes: HIGH — existing test files + golden infra read directly; green baseline confirmed.

**Research date:** 2026-07-27
**Valid until:** stable — 30 days (recipe layer + Theme contract are frozen for v2.11; re-verify only if `theme.ex` or any recipe changes before planning).

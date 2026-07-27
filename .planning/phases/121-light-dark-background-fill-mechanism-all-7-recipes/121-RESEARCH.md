# Phase 121: Light/dark background-fill mechanism (all 7 recipes) - Research

**Researched:** 2026-07-27
**Domain:** Deterministic PDF rendering — page-template regions, `%Rendro.Path{}` fill primitives, recipe color seams, byte-identity golden testing (Elixir, zero new deps)
**Confidence:** HIGH — every recommendation is grounded in a read of the exact source lines named in CONTEXT.md's Canonical References; no external packages are introduced.

## Summary

This phase is a HOW-to research, not a WHAT-to-decide research. The four design decisions (D-01…D-10) are already locked in `121-CONTEXT.md`. The engine already has every primitive needed — **no engine change is required.** The `:background` full-page fill rides three existing, proven mechanics: (1) `%Rendro.Path{}` fill rects (the exact construction Payslip's summary band and Certificate's border frame already use), (2) `apply_page_template/5`'s order-preserving `anchored_blocks ++ page.blocks` prepend that runs per-page including overflow (`paginate.ex:909-924`), and (3) the writer's list-order painter's-algorithm emission (`writer.ex:511-515`). First-in-`regions` `:background` = bottom of the paint stack on every page.

The single highest-risk area is **byte-identity on the light path**, and the strongest guard already exists: the seven frozen per-recipe `*_byte_identity_test.exs` sha256 goldens. If the light/no-theme path emits zero background ops (guaranteed by the `background == {255,255,255}` sentinel, D-06), those goldens stay green **automatically** — that IS the MODE-02 light-path proof. The plan's job is to keep them green (never re-bless). The one real per-cell byte trap is Statement's body table cells, which are currently plain strings measured at `Rendro.Text`'s default size 12; the color seam must preserve size **exactly 12** so measurement and rendered bytes are unchanged.

**Primary recommendation:** Copy Certificate's `frame_block` construction (`certificate.ex:181-190`) verbatim, changing `stroke:` → `fill: colors.background`, region/block dims → full page (`pw`, `ph`), and gate emission on `colors.background != {255, 255, 255}`. Centralize this in one shared helper (`Rendro.Recipes.Background`) that all 7 recipes call from `page_template/1` (prepend region) and `sections/2` (prepend section). Statement + Certificate additionally get their foreground text-color seams completed; the other five recipes get only the background-region wiring.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Ship legibility-complete dark, not page-background-only. Foreground role contract: no recipe draws text with a hardcoded literal or the implicit `Rendro.Text` default `{0,0,0}`. Primary text → `colors.ink`; secondary/captions/page-numbers → `colors.muted`; text on `surface` → `ink`/`muted`; text on `accent` → `on_accent` (latent, no live draw-site today); rules/borders/frames → `rule`.
- **D-02:** Only **two** recipes need text-seam edits: **Statement** (passes NO `color:` on any text block today) and **Certificate** (its two `Rendro.text(text, size: size)` body draw-sites). **Payslip** is the reference pattern (already all-correct). Verify-only for text seams: Payslip, Invoice, Receipt, Branded Invoice, Ticket. *(NOTE — see Pitfall 6: all 7 recipes still get the background-region wiring; "verify-only" is scoped to the text-color seam, not the region.)*
- **D-03:** Byte-identity preserved by construction — in each seamed recipe's `palette/1` **nil-branch**, add the neutral roles at today's literal (`ink: {0,0,0}`, `muted: {0,0,0}`) so `color: colors.ink` resolves to `{0,0,0}` on the no-theme path. Frozen sha256 goldens + `edge_matrix` are the enforcement gate.
- **D-04:** Add `:background` as the **first region** in each recipe's `template.regions`, painting one `%Rendro.Path{}` full-page fill rect (`{:rect, 0, 0, page_w, page_h}`, region `x:0 y:0 width:page_w height:page_h`, block `height: page_h`). Z-order already guaranteed by the engine (paginate.ex:911-923; writer.ex:511-513). `validate_region_fit!` passes iff region ≥ page. **Reversible** — recipe-level ordering convention, no engine change.
- **D-05:** Every existing colored element rides the `dark/1` swap for free — zero recipes get a bespoke dark branch. Grep confirms no recipe ever does `fill: colors.background` — the `:background` role is consumed solely by the new region.
- **D-06:** Emit the `:background` fill **iff `theme.colors.background != {255,255,255}`** (exact integer-tuple equality, **no tolerance, no near-white rounding**). Value-driven, not mode-gated. Pure white `{255,255,255}` is the reserved no-paint identity value. `default/0` → white → no paint → byte-identical. `dark/1` → `{27,23,19}` → always paints.
- **D-07:** Ship **zero** shipped/public dark demos in Phase 121. Prove the mechanism with a deterministic **test**; defer the human-facing dark visual to Phase 123. **Reversible** — a phasing choice.
- **D-08:** The mechanism test asserts: (a) light/no-theme emits **no** background rect and is byte-identical to the v2.10 golden (reuse PLUMB-03 identity guard); (b) dark emits the `:background` fill as the **first** content op on page 1 **and** on a **forced-overflow** page, fill color == resolved `theme.colors.background`; (c) existing band/frame/section ops byte-unchanged.
- **D-09:** Add a `theming` support-matrix stub row: `light` = `supported`; `dark` = `supported_screen_oriented` with boundaries `print_recommended`, `accessibility_pdf_ua_claim`, `wcag_contrast_claim`, `gui_viewer_visual_fidelity_claim` all `unsupported`. Add `theming_claims_test.exs` asserting boundary keys are set, no `theming` row carries a print/PDF-UA/WCAG support term, and `Rendro.Theme.dark/1`'s `@doc` contains the explicit "screen-oriented, not recommended for print" boundary sentence. **Do NOT create `guides/theming.md`** (Phase 123 / CONTRACT-02).
- **D-10:** Centralize the `:background` region construction (geometry + the D-06 emit predicate) in **one shared helper**, not duplicated across 7 recipes — pays down the Phase-120 WR-02 `palette/1` duplication finding.

### Claude's Discretion
- Exact test file name/placement (new file vs folding into the existing determinism-golden suite), provided D-08's assertions are all covered.
- Precise shape of the shared `:background` helper (module-private function vs a small shared recipe helper module), provided D-10's single-source-of-truth intent holds.
- Whether to seam Certificate's empty spacer `Rendro.text("", size: 1)` — no visible glyphs, harmless either way.

### Deferred Ideas (OUT OF SCOPE)
- Human-facing dark gallery visual + `guides/theming.md` — Phase 123 (DEFAULT-03 + CONTRACT-02).
- `accent`-fill bands reading `on_accent` — no recipe fills with `accent` today; latent future-proofing only.
- Tinted/cream light `default/0` — Phase 123 rubric tuning (would require net-new blessed goldens + human sign-off).
- Any WCAG/PDF-UA/print-safety dark claim — permanently out.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MODE-01 | `mode: :light \| :dark` selector via `Rendro.Theme.dark/1` swapping pre-resolved integer role tuples; no draw-time transcendental color math. | The selector already exists at the Theme layer (`theme.ex:239-243` `dark/1` sets `mode: :dark`, `Map.merge(resolved.colors, @dark_colors)`; `background {27,23,19}`). `resolve/1` is idempotent so `resolve(dark_theme)` preserves dark colors + mode (§Architecture Patterns → Pattern 3). Phase 121's contribution: the recipe consuming `colors.background` and painting it. No new math — the fill op is a static integer→float division in `Color.rg/1` (`color.ex:14-16`). |
| MODE-02 | Full-page background on EVERY page incl. paginate overflow via a `:background` region; light emits no rect, byte-identical to v2.10. | Per-page application proven at `paginate.ex:909-924` (runs per page, incl. overflow). First-in-`regions` → bottom of paint stack (`writer.ex:511-515`). Light-path no-rect + byte-identity is enforced by the existing 7 frozen `*_byte_identity_test.exs` goldens (§Validation Architecture). Sentinel `!= {255,255,255}` (D-06). |
| MODE-03 | Dark documented screen-oriented, explicit non-print boundary + support-matrix row; no print/PDF-UA/accessibility claim; all shipped demos light. | Support-matrix row shape modeled on `priv/support_matrix.json` `statement` row; overclaim tripwire modeled on `test/docs_contract/accessibility_overclaim_test.exs`. D-07 keeps zero dark demos shipped. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` or `./.claude/CLAUDE.md` exists in this repo, and no `.claude/skills/` or `.agents/skills/` directory exists. Project conventions are instead encoded in the codebase itself and in `.planning/`:

- **Zero new dependencies** — the milestone is Elixir stdlib on existing `Color`/`Text`/`Path`/`PageTemplate`/`Region` surfaces (REQUIREMENTS.md "Out of Scope"). [CITED: REQUIREMENTS.md:82]
- **Errors-as-product** — validation raises instructive `ArgumentError` with What/Where/Why/Next structure (pervasive in all recipes). Any new validation follows this shape.
- **Deterministic golden discipline (D-04 doctrine)** — a hash change is a DEFECT, not a refresh, unless a human re-authorizes via `MIX_GOLDEN_BLESS=true`; a missing ref hard-flunks (`test/support/golden.ex:55-95`). [VERIFIED: codebase]
- **No inline color literals in section builders** — every color routes through the recipe's `palette/1` seam; enforced by `test/rendro/recipes/no_inline_color_literals_test.exs` (also bans `.typography` reads in Phase-120 scope). [VERIFIED: codebase]
- **`density: :compact` idempotence, colors-only reads** — recipes read `theme.colors.*` only in this milestone slice (type scale is Phase 122).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dark color derivation (`mode`, role swap) | `Rendro.Theme` (value) | — | Pure value transform, already shipped Phase 119 (`theme.ex:239-243`). No draw-time math. |
| Background emit decision (`!= {255,255,255}`) | Shared recipe helper (`Rendro.Recipes.Background`) | Each recipe's `palette/1` | Single source of truth (D-10); reads the recipe's already-merged `colors` map. |
| `:background` region declaration | Each recipe's `page_template/1` | Shared helper (builds the `%Region{}`) | Region geometry is per-page-size; recipe owns pw/ph, helper owns the region shape. |
| Full-page fill rect construction | `%Rendro.Path{}` + `Rendro.path/2` | Shared helper | Existing primitive; identical to Certificate frame + Payslip band. |
| Per-page repetition (incl. overflow) | `pipeline/paginate.ex` `apply_page_template/5` | — | Existing, theme-unaware; MUST stay theme-unaware. |
| Z-order (background at bottom) | `pdf/writer.ex` `build_content_stream/4` | `paginate.ex` region order | List-order painter's algorithm; first region = first painted = bottom. |
| Foreground legibility (text reads on dark) | Each recipe's section builders + `palette/1` | `Rendro.Text.color` | D-01 role contract; the connective tissue that makes dark honest. |
| Claim boundary (screen-only, no print/UA) | `priv/support_matrix.json` + `test/docs_contract/theming_claims_test.exs` | `theme.ex` `dark/1` `@doc` | Docs-contract discipline; mirrors accessibility overclaim tripwire. |

## Standard Stack

No external packages. This phase uses only in-repo modules already on the surface.

### Core (in-repo, no install)
| Module | File:Line | Purpose | Why Standard |
|--------|-----------|---------|--------------|
| `Rendro.Path` | `lib/rendro/path.ex` | Full-page fill rect (`ops: [{:rect,0,0,pw,ph}]`, `fill: {r,g,b}`) | The engine's declarative vector primitive; `{nil, fill} → f` paint op (`path.ex:42`). [VERIFIED: codebase] |
| `Rendro.path/2` | `lib/rendro.ex:242-260` | Builds a `%Block{}` wrapping a `%Path{}`; splits `:x/:y/:width/:height` block attrs from `:fill/:stroke` path attrs | Exact call shape Payslip's band uses (`payslip.ex:380-387`). [VERIFIED: codebase] |
| `Rendro.Region` | `lib/rendro/region.ex` | Named layout region; `role: :custom`, `anchor: :fixed`, `x/y/width/height` | Certificate's `:frame` region is the same idiom (`certificate.ex:119-128`). [VERIFIED: codebase] |
| `Rendro.PageTemplate` | `lib/rendro/page_template.ex` | Holds ordered `regions:` list — order = z-order | First-in-list `:background` = bottom of stack (D-04). [VERIFIED: codebase] |
| `Rendro.Theme` | `lib/rendro/theme.ex` | `dark/1` → `background {27,23,19}`; `resolve/1` idempotent; `default/0` → `{255,255,255}` | Shipped Phase 119; the mode selector + role source. [VERIFIED: codebase] |
| `Rendro.Color.rg/1` | `lib/rendro/color.ex:14-16` | Emits `"<r> <g> <b> rg\n"` fill-color op (4-decimal floats) | Deterministic fill color; the test asserts against `Rendro.Color.rg(colors.background)`. [VERIFIED: codebase] |
| `Rendro.page_number/1` | `lib/rendro.ex:222-227` | Forwards `color:`/`size:` to `text/1` | Statement footer seam vehicle (D-02). [VERIFIED: codebase] |

### Supporting
| Module | File:Line | Purpose | When to Use |
|--------|-----------|---------|-------------|
| `Rendro.Recipes.Pagination` | `lib/rendro/recipes/pagination.ex` | Existing shared recipe-helper module (`chunk_rows_into_pages`, `label_resolver`, `formatter`, `validate_*`) | Candidate home for the D-10 background helper, OR keep a new sibling `Rendro.Recipes.Background`. |
| `Rendro.Test.Golden` | `test/support/golden.ex` | `assert_deterministic!/1` + `assert_or_bless/3` (sha256 refs under `priv/goldens/`) | The D-08 dark golden + forced-overflow golden. [VERIFIED: codebase] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| First-in-`regions` `:background` region | A post-paginate engine injection of a background block | Would be an engine change (out of scope, D-04 says recipe-level); breaks "engine stays theme-unaware". Rejected. |
| Value-driven emit (`!= {255,255,255}`) | Mode-gated emit (`mode == :dark`) | Mode-gated forces reopening `paginate.ex` in Phase 123 for tinted-light backgrounds. D-06 locks value-driven. |
| Shared helper module (`Rendro.Recipes.Background`) | Duplicating region+predicate in each recipe | Duplication is exactly the WR-02 finding D-10 pays down. Rejected. |

**Installation:** None. `mix deps.get` unaffected; no `mix.exs` change.

## Package Legitimacy Audit

**Not applicable.** This phase installs no external packages (npm/PyPI/crates/Hex). All modules are in-repo. Zero-new-dependency is an explicit milestone constraint. [CITED: REQUIREMENTS.md:82]

## Architecture Patterns

### System Architecture Diagram

```
  recipe.document(data, theme: Theme.dark(base))
        │
        ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ palette(opts)  →  colors map  (background = {27,23,19})       │  ← D-06 predicate input
  └─────────────────────────────────────────────────────────────┘
        │                                            │
        ▼ page_template/1                            ▼ sections/2
  Background.emit?(colors)? ──no──> regions unchanged (light path: byte-identical)
        │yes                                    │yes
        ▼                                        ▼
  prepend %Region{name: :background,       prepend %Section{region: :background,
     x:0,y:0,width:pw,height:ph,              content:[ %Path{ops:[{:rect,0,0,pw,ph}],
     role: :custom, anchor: :fixed}              fill: colors.background} ]}
        │                                        │
        └───────────────┬────────────────────────┘
                        ▼
  compose.ex: region_blocks[:background] = [path block]   (compose.ex:92-95)
                        ▼
  measure.ex: measured with region.width = pw             (measure.ex:461-481)
              body_capacity() ignores :background          (measure.ex:483-510 — only :header/:footer)
                        ▼
  paginate.ex apply_page_template/5  (runs PER PAGE incl. overflow)
     anchored_blocks = regions |> reject(:body) |> flat_map(...)   (paginate.ex:910-921)
     %{page | blocks: anchored_blocks ++ page.blocks}               (paginate.ex:923)
        → :background is FIRST region → FIRST in anchored_blocks → FIRST in page.blocks
                        ▼
  writer.ex build_content_stream/4: Enum.map_join(page.blocks, ...)  (writer.ex:511-515)
     → background path emitted FIRST → painted at bottom (painter's algorithm)
     → render_block(Path): "q\n1 0 0 1 <x> <y> cm\n<rg>\n0 0 pw ph re\nf\nQ"   (writer.ex:588-626)
                        ▼
              Every page carries the fill; text/bands/frames paint on top.
```

### Recommended Structure (new/changed files)
```
lib/rendro/recipes/
├── background.ex          # NEW (D-10): Background.region/2, Background.section/3, Background.emit?/1
├── statement.ex           # EDIT: text seam (D-02) + palette nil-branch (D-03) + bg wiring
├── certificate.ex         # EDIT: text seam (D-02) + palette nil-branch (D-03) + bg wiring
├── payslip.ex             # EDIT: bg wiring only (text already correct)
├── invoice.ex             # EDIT: bg wiring only
├── receipt.ex             # EDIT: bg wiring only
├── branded_invoice.ex     # EDIT: bg wiring only
└── ticket.ex              # EDIT: bg wiring only
lib/rendro/theme.ex        # EDIT: add "screen-oriented, not recommended for print" sentence to dark/1 @doc (D-09)
priv/support_matrix.json   # EDIT: add `theming` row(s) (D-09)
test/rendro/recipes/theme_mode_background_golden_test.exs   # NEW (D-08)
test/docs_contract/theming_claims_test.exs                  # NEW (D-09)
priv/goldens/<recipe>/dark.sha256                           # NEW blessed dark golden(s)
```

### Pattern 1: Full-page background fill block (COPY Certificate's frame_block)
**What:** The `:background` fill is structurally identical to Certificate's border frame — same `%Rendro.Path{}`-in-`%Block{}`, only `stroke:` → `fill:` and inset→full-page.
**When to use:** The one `:background` region block, in the shared helper.
**Proven analog — `certificate.ex:181-190`:**
```elixir
# EXISTING (frame, stroked, inset):
frame_block = %Rendro.Block{
  width: region_w, height: region_h, x: 0, y: 0,
  content: %Rendro.Path{
    ops: [{:rect, 0, 0, region_w, region_h}],
    stroke: %{color: frame_opts.color, width: frame_opts.weight}
  }
}
```
**Recommended `:background` block (via `Rendro.path/2`, matching Payslip's band call style):**
```elixir
# lib/rendro/recipes/background.ex  — Source: derived from certificate.ex:181-190 + payslip.ex:380-387
def section(colors, page_w, page_h) do
  block =
    Rendro.path([{:rect, 0, 0, page_w, page_h}],
      fill: colors.background,   # {nil, fill} → "f" paint op (path.ex:42)
      x: 0, y: 0, width: page_w, height: page_h
    )

  Rendro.section(name: :background, region: :background, content: [block])
end
```
**Coordinate proof (why full page lands at PDF (0,0)–(pw,ph)):** region `x:0,y:0` → `relative_x = 0 - margin_left`, `relative_y = 0 - margin_top` (`paginate.ex:1176-1177`). `anchor_region_blocks` sets block `x = -margin_left`, `y = -margin_top` (`paginate.ex:1092-1108`). Writer then computes `x = block.x + margin_left = 0` and `y = page.height - (block.y + block.height) - margin_top = ph - (-mt + ph) - mt = 0` (`writer.ex:596-597`). The `{:rect,0,0,pw,ph}` op Y-flips to bottom `h - 0 - ph = 0` (`writer.ex:1977-1990`). Result: `re` at `(0,0,pw,ph)` — exact full page. [VERIFIED: codebase]

### Pattern 2: `:background` region as first region (COPY Certificate/Payslip region construction)
**What:** Prepend a `%Region{}` to the recipe's `regions:` list. Order in the list = z-order (`paginate.ex:910`, `writer.ex:512`).
**Recommended region (in the shared helper), matching Certificate's `:frame` region idiom (`certificate.ex:119-128`):**
```elixir
def region(page_w, page_h) do
  Rendro.region(
    name: :background, role: :custom, anchor: :fixed,
    x: 0, y: 0, width: page_w, height: page_h
  )
end
```
**Wiring in each recipe's `page_template/1`** (must apply the same D-06 gate as `sections/2`):
```elixir
colors = palette(opts)
regions =
  if Rendro.Recipes.Background.emit?(colors),
    do: [Rendro.Recipes.Background.region(pw, ph) | base_regions],   # FIRST → bottom
    else: base_regions
```
**Geometry constraint (`validate_region_fit!`):** the region must be **exactly** page-sized. `block_fits_bounds?` uses exact comparison, no epsilon (`paginate.ex:1310-1319`); region bounds and block dims both derive from the same `pw`/`ph` floats, so equality holds exactly. `bounded_region?` is true because `pw,ph > 0` (`paginate.ex:1360-1362`), so `maybe_validate_region_fit` will run the check (`paginate.ex:1271-1283`). [VERIFIED: codebase]

### Pattern 3: The emit predicate — value-driven, exact-tuple (D-06)
**What:** Paint iff `colors.background != {255,255,255}` — exact integer-tuple equality, no tolerance.
```elixir
# lib/rendro/recipes/background.ex
@paper_white {255, 255, 255}
def emit?(%{background: bg}), do: bg != @paper_white
```
**Determinism proof:** `default/0` → `background {255,255,255}` exactly (`theme.ex:56`) → predicate false → no ops → frozen goldens hold. `dark/1` → `Map.merge(resolved.colors, @dark_colors)` where `@dark_colors.background = {27,23,19}` (`theme.ex:68`) → predicate true → paints. `resolve/1` on an already-dark theme preserves the dark tuples (deep_merge lets the override win) and `mode: :dark` (`theme.ex:200-222, 302-303`), so a recipe that receives `theme: Theme.dark(base)` and internally calls `Theme.resolve(theme)` in `palette/1` keeps `{27,23,19}`. [VERIFIED: codebase]

### Pattern 4: Foreground text seam (COPY Payslip's `cell_text/2` + colored `Rendro.text`)
**What:** Every foreground reads a swappable role. Payslip is the reference (`payslip.ex`): header `color: colors.ink`/`colors.muted` (`payslip.ex:319-325`), table cells via `cell_text/2` = `Rendro.block(Rendro.text(text, size: @cell_size, color: colors.ink))` (`payslip.ex:546-547`), footer `Rendro.page_number(color: colors.muted, size: 9)` (`payslip.ex:669`).
**Statement seam sites (D-02):**
- `statement.ex:324` `Rendro.text(account_name, size: 14)` → add `color: colors.ink`
- `statement.ex:325` `Rendro.text(period_str, size: 10)` → `color: colors.muted`
- `statement.ex:326` `Rendro.text(ob_str, size: 10)` → `color: colors.muted`
- `statement.ex:315` `closing_label ... size: 9` → `color: colors.muted`
- `statement.ex:318` `closing_value ... size: 22` → `color: colors.ink`
- Body table cells: `formatted_rows` are plain strings (`statement.ex:383-386`), and the bf/cf rows are plain strings too (`statement.ex:457, 465`). Introduce a `cell_text/2` at **`size: 12`** (see Pitfall 1) that wraps `Rendro.text(str, size: 12, color: colors.ink)`. Feed the same cells into both `Rendro.measure_rows` (`statement.ex:393`) and `Rendro.table` (`statement.ex:475`).
- Footer page number (`statement.ex:495`): `Rendro.page_number(Keyword.put_new(page_number_opts, :color, colors.muted))`.
**Certificate seam sites (D-02):**
- `certificate.ex:350` `centered_line`: `Rendro.text(text, size: size)` → `color: colors.ink`
- `certificate.ex:357` `centered_paragraph`: `Rendro.text(text, size: size)` → `color: colors.ink`
- Thread `colors = palette(opts)` into `body_section/3` and pass to `centered_line/centered_paragraph`.
- Spacer `certificate.ex:324` `Rendro.text("", size: 1)` — Claude's discretion (no glyphs).

### Pattern 5: `palette/1` nil-branch completion (D-03)
Add the neutral roles at today's literals so `color: colors.ink` = `{0,0,0}` on the no-theme path. Statement's nil-branch currently has only `surface`/`rule` (`statement.ex:351-354`) → add `ink: {0,0,0}, muted: {0,0,0}, background: {255,255,255}`. Certificate's has only `rule: {34,34,34}` (`certificate.ex:378-380`) → add `ink: {0,0,0}, background: {255,255,255}` (Certificate uses no `muted`; add it too for symmetry, harmless). The other five recipes already carry `background: {255,255,255}` in their nil-branch (verified: branded_invoice:238, invoice:477, payslip:689, receipt:483, ticket:521) — they need **no** palette change. [VERIFIED: codebase]

### Anti-Patterns to Avoid
- **Painting the background as a body-flow block.** It would push body content down and be subject to pagination/overflow. It MUST be an anchored region, not `region: :body`.
- **Sizing the region larger than the page "to be safe."** `validate_region_fit!` throws `:content_overflow` if the block exceeds region bounds (`paginate.ex:1298-1308`); and an over-page region is nonsense. Size exactly `pw × ph`.
- **A near-white tolerance / rounding.** D-06 forbids it; any "close enough to white" cutoff is a non-deterministic footgun and would silently stop painting a legitimately-requested near-white tint.
- **Re-blessing the frozen byte-identity goldens** to make them pass. A drift there is a DEFECT (Pitfall 2). The light path must be a true no-op.
- **Changing Statement body cell size** from the implicit 12 (Pitfall 1).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-page background repetition (incl. overflow) | A loop over pages appending a rect | The existing `:background` region + `apply_page_template/5` | Engine already applies regions per page incl. paginate overflow (`paginate.ex:909-924`). Zero engine change. |
| Z-order / "paint behind everything" | A z-index field or a sort | First position in `regions:` list | Painter's algorithm in list order (`writer.ex:511-515`); first region = bottom. |
| Fill rect geometry / Y-flip | Manual PDF `re`/`cm` math | `%Rendro.Path{ops:[{:rect,...}]}` | Writer handles the single Y-flip + `cm` translate (`writer.ex:588-626, 1977-1990`). |
| Fill color op formatting | Hand-format `"r g b rg"` | `Rendro.Color.rg/1` | Deterministic 4-decimal float format (`color.ex:14-16, 136-138`). |
| Dark color derivation | Draw-time luminance/tint math | `Rendro.Theme.dark/1` | Pre-resolved integer swap; no transcendental math at draw time (MODE-01). |
| Golden byte assertion + bless workflow | A bespoke sha256 compare | `Rendro.Test.Golden.assert_or_bless/3` | Human-gated bless, missing-ref hard-flunk (`golden.ex:43-95`). |

**Key insight:** Every hard part is already solved by shipped, tested engine mechanics. Phase 121 is composition + a color seam + tests, not new engine capability.

## Runtime State Inventory

This is a code + test + one-JSON-row change with **no runtime/stored/OS/secret state**. Explicit per-category audit:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — Rendro is a stateless pure-render library; no DB, no datastore. Verified by absence of any storage/registry write in the render path. | none |
| Live service config | None — no external service; PDFs are produced in-process. | none |
| OS-registered state | None — no scheduled tasks, daemons, or OS registrations. | none |
| Secrets/env vars | Only test-time `MIX_GOLDEN_BLESS`/`MIX_GOLDEN_DUMP` (developer-invoked, not stored). No secret rename. | none |
| Build artifacts | New golden ref files under `priv/goldens/<recipe>/dark.sha256` (created via `MIX_GOLDEN_BLESS=true` on the deliberate dark bless). The Hex tarball ships `priv/` — confirm `support_matrix.json` change and any new golden refs are intended tarball content (they are 1-line hashes, not PDFs — consistent with existing goldens). | bless dark golden(s) deliberately; commit the `.sha256` refs |

## Common Pitfalls

### Pitfall 1: Statement body-table cells — the one real byte-risk
**What goes wrong:** Converting Statement's plain-string table cells to colored `Rendro.text` changes the rendered/measured bytes if the size differs from the implicit default.
**Why it happens:** Plain-string cells are normalized to `Rendro.text(content)` with **default `size: 12`** (`compose.ex:61-62`, `text.ex:20`). Payslip deliberately chose `size: 11` for its cells — but that was a 118-08 fix with **new** goldens (`payslip.ex:436-547`). Statement in Phase 121 must NOT change bytes.
**How to avoid:** The Statement `cell_text/2` MUST use `size: 12` (the current implicit default), `color: colors.ink`, `font` default. An explicit `%Text{content: s, size: 12, color: {0,0,0}, font: "Helvetica"}` is byte-identical to the string-normalized `%Text{}`. Feed identical cells into both `measure_rows` and `table`. Color does not affect measurement (only `size`/`font` do), so heights/chunking are unchanged.
**Warning signs:** `statement_byte_identity_test.exs` sha256 drift (`@toy_golden_sha256 = "87f6a2c8…"`, `statement_byte_identity_test.exs:13`) on the no-theme path.

### Pitfall 2: Re-blessing a frozen golden to "fix" a failing test
**What goes wrong:** The light path emits a stray op, a golden flunks, and someone runs `MIX_GOLDEN_BLESS=true` to make it pass — masking a real byte-identity regression.
**Why it happens:** The bless escape hatch is easy; the doctrine is that a hash change is a DEFECT unless human-authorized (`golden.ex:15-17, 84-89`).
**How to avoid:** On the light/no-theme path the background predicate must be false → zero ops → the 7 `*_byte_identity_test.exs` goldens and the `edge_matrix` stay green with **no** bless. Only the **new dark** golden is blessed (once, deliberately).
**Warning signs:** A diff touching any existing `*.sha256` under `priv/goldens/` or any `@*_golden_sha256` literal in a `*_byte_identity_test.exs`.

### Pitfall 3: Emitting the empty region on the light path (subtle byte risk)
**What goes wrong:** Always adding the `:background` region (even light) with no section content could, in principle, alter output.
**Why it (does not) happen:** An empty region contributes `[] ++ page.blocks` (`paginate.ex:923`), `body_capacity` ignores non-`:header`/`:footer` regions (`measure.ex:483-510`), and `measure_region_blocks` only iterates regions present in `region_blocks` (`measure.ex:461-481`). So an unused region is inert.
**How to avoid (belt-and-suspenders):** Gate **both** the region (in `page_template/1`) and the section (in `sections/2`) on `Background.emit?(colors)` so the light template is literally unchanged. This makes the byte-identity argument trivial and robust. (Same predicate, same `palette(opts)` — they cannot disagree.)
**Warning signs:** Any light golden drift after the region is wired.

### Pitfall 4: Wrong page dimensions for landscape / non-A4 recipes
**What goes wrong:** Hardcoding A4 portrait `595.28 × 841.89` breaks Certificate (landscape default) and any `page_size: :us_letter`/`{w,h}` override.
**Why it happens:** Certificate resolves `{pw, ph} = Rendro.PageSize.resolve(page_size, orientation)` (`certificate.ex:91`); Payslip via `geometry(opts)` (`payslip.ex:259-296`); Statement uses module constants `@page_width/@page_height` (`statement.ex:87-88`).
**How to avoid:** The helper takes `pw, ph` as args; each recipe passes its own resolved dimensions (Statement: the constants; Certificate/Payslip: the resolved tuple). Never hardcode inside the helper.
**Warning signs:** A dark Certificate whose fill covers only a portrait sub-rectangle of the landscape page.

### Pitfall 5: Asserting "first content op" against a compressed stream
**What goes wrong:** A test greps the PDF binary for the fill op but the page content stream is compressed.
**Why it (does not) happen here:** Page content streams under `deterministic: true` are **uncompressed** — `path_test.exs:89-93` asserts `pdf =~ "re\nS"` against the raw binary and passes. (FlateDecode in `writer.ex:372/385/405` is for embedded fonts/images, not the page content stream.)
**How to avoid:** The dark test may assert `pdf =~ Rendro.Color.rg(colors.background)` and that this `rg`/`re`/`f` sequence appears **before** the first `BT` (text) token, per page content stream. For "every page incl. overflow", count occurrences == page count. Prefer the full-document sha256 golden (via `Golden.assert_or_bless`) as the primary lock, with the structural op-order assertion as the human-readable proof.
**Warning signs:** A test that only checks presence of `rg` (not order) would pass even if z-order regressed.

### Pitfall 6: "Verify-only" misread — all 7 recipes still get the region wiring
**What goes wrong:** Planner reads D-02 "only two recipes need edits" and skips wiring the background region into the other five.
**Why it happens:** D-02's "verify-only" is scoped to the **text-color seam**. The background **region** (D-04/D-10) is added to **all 7** recipes (each owns its own `page_template/1` + `sections/2`).
**How to avoid:** Treat as two independent edit sets: (a) text seams → Statement + Certificate only; (b) background-region wiring → all 7. The five "verify-only" recipes get only (b) plus a verification that their `palette/1` nil-branch already carries `background`.

### Pitfall 7: `no_inline_color_literals_test.exs` scans the new helper file
**What goes wrong:** The guard scans every `lib/rendro/recipes/*.ex` for `(?:color|fill|stroke):\s*\{\d,\d,\d\}` outside the `defp palette` body (`no_inline_color_literals_test.exs:29, 62-88`).
**Why it's fine:** The helper uses `fill: colors.background` (a variable read, not a literal) and the sentinel `background != {255,255,255}` is a `!=` context, not `color:/fill:/stroke:`. Neither matches the regex. The new file also performs no `.typography` read. So the guard stays green.
**How to avoid:** Keep the sentinel as a module attribute `@paper_white {255,255,255}` or a bare `!=`; never write `fill: {255,255,255}`.

## Code Examples

### The shared helper (D-10) — proposed shape
```elixir
# lib/rendro/recipes/background.ex
# Source: certificate.ex:181-190 (frame block) + payslip.ex:380-387 (band call) + theme.ex:56/68 (sentinel)
defmodule Rendro.Recipes.Background do
  @moduledoc false
  @paper_white {255, 255, 255}

  @doc "Paint iff the resolved background is not paper-white (D-06, exact tuple)."
  def emit?(%{background: bg}), do: bg != @paper_white

  @doc "Full-page :background region — must be prepended FIRST for bottom-of-stack z-order (D-04)."
  def region(page_w, page_h) do
    Rendro.region(name: :background, role: :custom, anchor: :fixed,
                  x: 0, y: 0, width: page_w, height: page_h)
  end

  @doc "The single full-page fill-rect section."
  def section(colors, page_w, page_h) do
    block =
      Rendro.path([{:rect, 0, 0, page_w, page_h}],
        fill: colors.background, x: 0, y: 0, width: page_w, height: page_h)

    Rendro.section(name: :background, region: :background, content: [block])
  end
end
```

### Recipe wiring (Certificate shown — landscape, resolved dims)
```elixir
# certificate.ex page_template/1 — after {pw, ph} = Rendro.PageSize.resolve(...)
colors = palette(opts)
bg_regions =
  if Rendro.Recipes.Background.emit?(colors),
    do: [Rendro.Recipes.Background.region(pw, ph)],
    else: []
regions = bg_regions ++ [body_region | frame_region_if_border]   # :background FIRST

# certificate.ex sections/2
bg_sections =
  if Rendro.Recipes.Background.emit?(colors),
    do: [Rendro.Recipes.Background.section(colors, pw, ph)],
    else: []
bg_sections ++ [body | frame_section_if_border]
```

### Dark fill color op (deterministic) — what the test asserts
```elixir
# {27,23,19} → Rendro.Color.rg/1 → "0.1059 0.0902 0.0745 rg\n"   (color.ex:14-16, 4-decimal)
assert pdf =~ Rendro.Color.rg(Rendro.Theme.dark(Rendro.Theme.default()).colors.background)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Recipes passed no `theme:`; colors implicit | All 7 thread `theme:` through 3 rungs, read `theme.colors.*` via `palette/1` seam | Phase 120 (shipped) | The seam this phase extends already exists; background just adds one more consumed role. |
| Dark = separate art / per-mode branches | `dark/1` value swap of pre-resolved integer tuples | Phase 119 (shipped) | No bespoke dark code in recipes (D-05). |
| Elevation via shadow/opacity (web idiom) | Flat: `surface` tint + `rule` hairline on a darker page (Material "surface tint = elevation") | v2.11 by construction | Rendro bans shadow/opacity/gradient; dark reads as a lighter surface on a darker page. [ASSUMED — ecosystem framing from CONTEXT.md:103] |
| Background painted in body flow | Page-level fill drawn first (Typst `page(fill:)`, ReportLab/Prawn draw-rect-first) | industry norm | Motivates the first-region anchored approach. [ASSUMED — ecosystem framing from CONTEXT.md:103] |

**Deprecated/outdated:** none relevant.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Page content streams are uncompressed under `deterministic: true`, so the dark test can regex the raw binary for the fill op and its order. | Pitfall 5 | LOW — corroborated by `path_test.exs:89-93` passing on `pdf =~ "re\nS"`. If wrong, use a full-doc sha256 golden as the sole lock (still covers D-08). |
| A2 | `resolve/1` applied to an already-dark theme inside `palette/1` preserves the dark `{27,23,19}` background and `mode: :dark`. | Pattern 3 | LOW — follows directly from `deep_merge` override-wins semantics (`theme.ex:200-222, 309-313`); a plan-time unit test confirms trivially. |
| A3 | Ecosystem framing (Typst `page(fill:)`, ReportLab draw-rect-first, Material surface-tint) — used only as design rationale, not as an API claim. | State of the Art | NONE — decorative context; the locked decisions already encode it. |
| A4 | Committing new `priv/goldens/<recipe>/dark.sha256` 1-line refs is acceptable Hex-tarball content (consistent with existing golden refs). | Runtime State Inventory | LOW — existing goldens already ship in `priv/`; confirm no PDF bytes are committed (the helper writes only hashes, `golden.ex:59`). |

## Open Questions

1. **Which recipe carries the forced-overflow dark golden (D-08b)?**
   - What we know: Certificate is single-page (body ≤ 2000 bytes, `certificate.ex:550`), so it cannot spill. Statement and Payslip paginate natively (`chunk_rows_into_pages`).
   - What's unclear: whether to prove overflow on Statement (simplest data) or Payslip.
   - Recommendation: use **Statement** with enough `:lines` to force page 2+ (mirror the existing Statement multi-page fixtures); assert the fill op appears in **each** page content stream. Keep a single-page dark golden on a second recipe (e.g. Certificate landscape) to prove non-portrait geometry.

2. **Home for the D-10 helper: new `Rendro.Recipes.Background` vs a function in `Rendro.Recipes.Pagination`?**
   - What we know: `Pagination` is the existing shared recipe-utility module but is semantically about row chunking.
   - Recommendation: a new `@moduledoc false` `Rendro.Recipes.Background` — cleaner single responsibility; `@doc false` keeps it out of the public API manifest (mirrors `payslip.ex:77-79`).

3. **Should each recipe expose a convenience `mode: :dark` opt, or is `theme: Theme.dark(base)` the sole selector?**
   - What we know: MODE-01's "selector" is satisfied by `dark/1` + the existing `theme:` opt; no recipe currently reads a `mode:` opt.
   - Recommendation: no new `mode:` opt this phase — `theme: Rendro.Theme.dark(...)` is the selector. (A `mode:` sugar, if ever wanted, is a Phase-123 ergonomics concern.)

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang/OTP | compile + test | ✓ | OTP 28 (erts-16.3, JIT) | — |
| Elixir + Mix | build, `mix test` | ✓ | present (project builds; 7 byte-identity goldens run) | — |
| ExUnit | all tests | ✓ | bundled with Elixir | — |
| External packages | — | n/a | — | none needed (zero new deps) |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir), `deterministic: true` render + sha256 goldens |
| Config file | `mix.exs` aliases (`test.all`, `verify.*`); goldens under `priv/goldens/`, helper `test/support/golden.ex` |
| Quick run command | `mix test test/rendro/recipes/theme_mode_background_golden_test.exs` |
| Full suite command | `mix test --exclude quarantine` (the `check`/`test.all` alias baseline) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MODE-02 (light) | No-theme render byte-identical to v2.10 (no background rect) | golden (existing) | `mix test test/rendro/recipes/statement_byte_identity_test.exs` (and the other 6) | ✅ (must stay green, no bless) |
| MODE-02 (dark, p1) | Dark emits `:background` fill as FIRST content op on page 1; fill == `colors.background` | golden + structural | `mix test test/rendro/recipes/theme_mode_background_golden_test.exs` | ❌ Wave 0 |
| MODE-02 (dark, overflow) | Fill present on a forced-overflow page too (per-page) | golden + structural | same file | ❌ Wave 0 |
| MODE-02 (composition) | Existing band/frame/section ops byte-unchanged under dark (clean z-order) | golden | same file (dark sha256 stable across two renders) | ❌ Wave 0 |
| MODE-01 | `Theme.dark/1` swaps background to `{27,23,19}`; recipe consumes it; no draw-time float math | unit | assert `Theme.dark(Theme.default()).colors.background == {27,23,19}` + rendered fill matches | ❌ Wave 0 (theme unit exists Phase 119; recipe-consumption assertion new) |
| MODE-01 (legibility) | Seamed recipes read roles, not literals; nil-branch byte-identical | static + golden | `mix test test/rendro/recipes/no_inline_color_literals_test.exs` + byte-identity goldens | ✅ guard exists; extend fixtures |
| MODE-03 | `theming.light`/`theming.dark` rows exist with boundary keys `unsupported`; no print/UA/WCAG support term; `dark/1` `@doc` carries the boundary sentence | docs-contract | `mix test test/docs_contract/theming_claims_test.exs` | ❌ Wave 0 |
| MODE-03 (no overclaim) | No showcase term co-occurs with an accessibility term in theming docs | docs-contract | existing `accessibility_overclaim_test.exs` (pattern to mirror) | ✅ pattern exists |

### Sampling Rate
- **Per task commit:** the quick run above + the touched recipe's `*_byte_identity_test.exs` (proves no light drift).
- **Per wave merge:** `mix test test/rendro/recipes/ test/docs_contract/theming_claims_test.exs`.
- **Phase gate:** full suite (`mix test --exclude quarantine`) green before `/gsd-verify-work`, including the `edge_matrix` gate.

### Wave 0 Gaps
- [ ] `test/rendro/recipes/theme_mode_background_golden_test.exs` — covers MODE-01/MODE-02 (light no-rect via reused byte-identity guard; dark first-op page 1; dark forced-overflow; two-render dark determinism; fill == `Color.rg(colors.background)`).
- [ ] `test/docs_contract/theming_claims_test.exs` — covers MODE-03 (boundary keys `unsupported`; no print/UA/WCAG support term on any `theming` row; `dark/1` `@doc` boundary sentence present; non-vacuity/teeth assertions mirroring `accessibility_overclaim_test.exs`).
- [ ] `priv/goldens/<recipe>/dark.sha256` — blessed once via `MIX_GOLDEN_BLESS=true` (deliberate, human-authorized) for the chosen overflow recipe (Statement) + one non-portrait recipe (Certificate landscape).
- [ ] `priv/support_matrix.json` — `theming` row(s) (D-09).
- [ ] Framework install: none — ExUnit present.

## Security Domain

`security_enforcement` is not set in `.planning/config.json` (absent = enabled), but this phase introduces **no new external-input surface**. The only new "input" is a theme color tuple, which is already validated as an integer `{0..255,0..255,0..255}` via `Rendro.Color.validate/1` inside `Theme.resolve/1` (`theme.ex:322-330`, shipped Phase 119). No auth, sessions, access control, secrets, crypto, deserialization, or network I/O is touched.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes (pre-existing) | `Rendro.Color.validate/1` on every role in `resolve/1`; recipe `validate_data!/1` errors-as-product. No new validation gap. |
| V6 Cryptography | no (sha256 is test-only golden hashing, not a security control) | — |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Content-stream injection via unescaped op values | Tampering | Fill color is numeric-only (`Color.rg/1`, 4-decimal floats); rect coords are numeric; no string interpolation of user text into path ops. Unknown path ops emit empty (`writer.ex:2000-2003`). |
| Non-determinism leak breaking reproducibility | Repudiation | `assert_deterministic!/1` renders twice and refuses to bless a mismatch (`golden.ex:26-32`). |

## Sources

### Primary (HIGH confidence — read this session)
- `lib/rendro/theme.ex` — `default/0` white, `dark/1` `{27,23,19}`, `resolve/1` idempotence, `@dark_colors`.
- `lib/rendro/pipeline/paginate.ex:909-924, 1092-1109, 1176-1177, 1266-1319, 1360-1362` — per-page region application, anchor math, `validate_region_fit!`, `bounded_region?`, exact-fit `block_fits_bounds?`.
- `lib/rendro/pdf/writer.ex:511-515, 588-626, 1935-1990` — list-order emission, Path render coordinate transform, fill color + rect ops.
- `lib/rendro/path.ex`, `lib/rendro/region.ex`, `lib/rendro/page_template.ex`, `lib/rendro/color.ex:14-16,136-138`, `lib/rendro.ex:207-260`.
- `lib/rendro/recipes/payslip.ex` (reference pattern: band `380-387`, `cell_text` `546-547`, `page_number` `669`, nil-branch `683-698`), `statement.ex` (seam sites `314-330, 383-386, 457-495`, palette `347-361`), `certificate.ex` (frame block `181-190`, region `119-128`, text sites `350, 357`, palette `374-387`).
- `lib/rendro/pipeline/compose.ex:60-142`, `measure.ex:461-512` — region→blocks routing, `body_capacity` ignores non-header/footer regions.
- `test/support/golden.ex`, `test/rendro/recipes/statement_byte_identity_test.exs`, `test/rendro/recipes/no_inline_color_literals_test.exs`, `test/docs_contract/accessibility_overclaim_test.exs`, `priv/support_matrix.json`, `test/rendro/path_test.exs:79-143`.
- `.planning/phases/121-.../121-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`.

### Secondary (MEDIUM confidence)
- `mix.exs` aliases (`check`, `test.all`, `verify.*`) — test command surface.

### Tertiary (LOW confidence)
- Ecosystem framing (Typst/ReportLab/Prawn/Material) — design rationale from CONTEXT.md, not independently re-verified this session.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all in-repo, read directly; zero new deps.
- Architecture (z-order, per-page, coordinate math): HIGH — traced end-to-end through paginate + writer with exact line refs and a worked coordinate proof.
- Pitfalls: HIGH — the Statement cell-size trap and golden-bless doctrine are read from the code and the frozen golden test.
- Validation architecture: HIGH — reuses existing golden helper + guard tests; new-file gaps enumerated.

**Research date:** 2026-07-27
**Valid until:** 2026-08-26 (stable — pure in-repo mechanics; refresh only if the pipeline region/writer code changes).

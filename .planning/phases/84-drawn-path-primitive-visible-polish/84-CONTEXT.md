# Phase 84: Drawn-Path Primitive & Visible Polish - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver three net-new **permanent Tier-1 public APIs** on shipped 1.0 Rendro, plus their byte-determinism golden tests and terminal support-matrix rows:

1. A declarative `%Rendro.Path{}` vector-graphics **block element** (move/line/curve/rect/rounded-rect; stroke color/width/dash/cap/join; fill) rendered through the standard pipeline (PATH-01).
2. Opt-in **table borders, row/column rules, and header-band shading** on `Rendro.Table`, with default output **byte-identical to today's borderless rendering** (PATH-02).
3. A decorative **`border:` frame option on `Rendro.Recipes.Certificate`**, all coordinates derived from page geometry, proven at A4 and US Letter (PATH-03).
4. Byte-determinism golden tests + terminal `priv/support_matrix.json` rows; **transforms, clipping, and gradients explicitly deferred** (PATH-04).

This phase is about the **shape** of these permanent APIs (the *what* is locked by PATH-01..04). Because Rendro is SemVer-locked 1.0 with a machine-checked public API manifest (`priv/public_api.json`), every shape choice here is permanent and widening-only.

</domain>

<decisions>
## Implementation Decisions

Each decision was reached via a two-pass parallel research sweep (ecosystem idioms across Prawn/ReportLab/pdf-lib/Scenic/mudbrick/Typst + the project's own `prompts/` and `.planning/research/`). The four decisions are mutually coherent: **one canonical color type threads through every surface**, the **Certificate frame dogfoods the Path primitive**, and **table `border_style` reuses the Path stroke convention**.

### Color representation (cross-cutting — all three surfaces)
- **D-01:** Accept **only `{r, g, b}` integer tuples, 0–255**, on all new surfaces (`%Rendro.Path{}` stroke/fill, table `border_style`/`header_fill`, Certificate frame). This is the **exact convention shipped `Rendro.Text` already uses** — one color model library-wide. Rationale: Scenic (closest Elixir graphics lib) uses 0–255 tuples; mudbrick (in-niche) uses tuples; **no serious lib accepts a bare hex string in a struct field** (all route hex through an explicit constructor like `rgb("#..")`). Tuples are trivially byte-deterministic via the existing `format_num(x/255)` path — hex would add a permanent byte-stable-parser surface (case-folding, 3→6 expansion, `#`-optional ambiguity) to freeze forever.
- **D-02:** Introduce **one internal canonical helper module `Rendro.Color`** (`to_pdf_components/1` → `{0–1 floats}`, `rg/1`, `rg_stroke/1` (a.k.a. `RG`), `validate/1`). **Keep it internal** (`@moduledoc false` / not added to `priv/public_api.json`) so the frozen surface stays minimal and hex/named-colors/0–1-floats remain a clean **future backward-compatible widening** routed through `Rendro.Color.rgb("#..")`.
- **D-03:** **Retrofit** the existing Text writer path (`lib/rendro/pdf/writer.ex` ~638–639) to call `Rendro.Color` instead of inline `format_num(r/255)`. Pure internal dedupe — **no public type change**, and since no recipe sets a non-default color today, output stays byte-identical (add a golden asserting black-text bytes unchanged).
- **D-04:** Invalid-color errors are **errors-as-product** (`ArgumentError`, What/Where/Why/Next) and **must explicitly name the hex footgun** in Why/Next (e.g. "got a hex string; Rendro uses 0–255 RGB tuples … Convert `#2C6BED` → `{44, 107, 237}`") because the ROADMAP trained the wrong expectation.
- **D-05:** **Correct the ROADMAP** (`.planning/ROADMAP.md` Phase-84 example): change `stroke: %{color: "#000", width: 1.0}` → `stroke: %{color: {0, 0, 0}, width: 1.0}`. The hex example is an unvetted draft that contradicts the shipped engine and has no library precedent.
- **D-06:** The Brand Book hex palette (`#101827`, `#2C6BED`, `line-300 #D8D2C3`, …) is **web/brand chrome, not an engine color-input format** — it does NOT argue for hex in the API. (Brand colors are still expressible as `{r,g,b}` tuples on any surface.)

### Path coordinate model + struct/op shape (PATH-01)
- **D-07:** `%Rendro.Path{}` is a **flow block**; op coordinates are **block-relative, author top-left, Y-down** — identical to Text/Image/Table. The writer reuses its existing per-block Y-flip (`y_pdf = page.height - (block.y + block.height) - margin_top`) and emits **one balanced `q … cm … Q`** translating ops into the block's slot (each op's `y' = block.height - y`; cubic Béziers are affine-invariant so control points flip correctly). Rejected: page/region-absolute PDF bottom-left (inverts the Y convention the whole API uses; can't flow/paginate).
- **D-08:** **Bounding box in flow:** primary path is **caller-declared `width`/`height`** on the Block (mirrors `Rendro.Image` requiring `fit` dims; the Certificate frame uses this). **Fallback:** when dims are omitted, compute a **deterministic ops-extent bbox** (fold ops, `max_x`/`max_y`, conservative curve bound) so a bare `%Rendro.Path{ops: [...]}` still measures. Paths **never fragment** across pages (single intrinsic block).
- **D-09:** **Op vocabulary = raw tagged-tuple op list** (no builder DSL — matches Scenic's idiom and Rendro's inert-struct culture; mudbrick's pipe-builder is explicitly rejected as a culture mismatch). Six ops:
  - `{:move, x, y}` → `m`; `{:line, x, y}` → `l`; `{:curve, x1,y1, x2,y2, x3,y3}` → `c` (cubic, 2 control pts + endpoint)
  - `{:rect, x, y, w, h}` → `re`
  - `{:rounded_rect, x, y, w, h, radius}` → **first-class op**, deterministically decomposed via `m`/`l`/`c` using the **`0.5522847498` kappa already in `circle_path`** (writer.ex ~1419–1459). Not author-sugar — the decomposition must live in one audited place.
  - `:close` (bare atom) → `h`
- **D-10:** **`stroke` and `fill` each accept a bare color tuple OR a map** (bare color = the 90% path):
  - `stroke: %{color: {0,0,0}, width: 1.0, dash: nil, cap: :butt, join: :miter}` — enum→PDF: `cap` `:butt|:round|:square` → `J` `0|1|2`; `join` `:miter|:round|:bevel` → `j` `0|1|2`; `dash` `nil`→solid else `[on,off]`(+phase) → `d`.
  - `fill: {r,g,b}` (or `%{color: {r,g,b}}`); default fill rule nonzero `f` (even-odd `f*` deferred).
  - **Defaults match PDF's initial graphics state** (`0 0 0`, width 1.0, butt, miter) so omitting them emits nothing → byte-clean.
- **D-11:** **Deterministic paint-op selection** (pure fn of `{stroke?, fill?}`): `{nil,nil}→n` (reserves the empty-paint case for a future `W n` clip), `{nil,_fill}→f`, `{_strk,nil}→S`, `{_strk,_fill}→B` (fill then stroke). Graphics-state ops (`RG`/`rg`/`w`/`J`/`j`/`d`) set once before construction, **default-valued ones omitted**.
- **D-12:** `@enforce_keys [:ops]`; `defstruct [:ops, fill: nil, stroke: nil]`; `@moduledoc tags: [:stable]`. Add a `Rendro.path(ops, attrs \\ [])` builder returning `%Block{content: %Path{}}` (mirrors `Rendro.text/2`, supports `width:`/`height:`). **Does not preclude deferred transforms/clipping/gradients** — they drop into the same balanced `q…Q` later.

### Table borders / rules / shading (PATH-02)
- **D-13:** Add **three flat fields** to `%Rendro.Table{}`, all defaulting to inert (rejected: a single nested command-map/DSL — ReportLab's `TableStyle` is the named DX **anti-model**; and per-cell edge fields — Prawn's double-draw footgun):
  - `borders: :none` (default) — accepts a **single atom OR a set-list**.
  - `border_style: nil` — `nil` → built-in hairline `%{color: {0,0,0}, width: 0.5, dash: nil}`; else `%{color, width, dash}` (the **inert subset of the Path stroke** — `cap`/`join` omitted because axis-aligned full edges render identically; forward-compatible).
  - `header_fill: nil` — `nil` → no band; else `{r,g,b}` (kept a **distinct field** because shading is `fill`, not `stroke` — matches Typst's stroke/fill split; only applies when `table.header` present).
- **D-14:** **`borders:` vocabulary** (ReportLab BOX/INNERGRID/GRID granularity as composable atoms): `:none` | `:outer` (perimeter) | `:rows` (horizontal interior rules) | `:columns` (vertical interior rules) | `:grid` (= rows+columns, no outer) | `:all` (= outer+grid). A **list is a set**: order-independent, de-duplicated, normalized to a canonical form at construction (so golden bytes are stable regardless of author ordering). `[:outer, :rows]` is the canonical invoice look.
- **D-15:** **Byte-identity is structural** (PITFALLS #7): defaults are inert; the struct lowers to a content stream (never persisted), so new fields with inert defaults change zero bytes. The writer table branch (writer.ex ~511–535) gains a guarded first line — `table_decoration(table, page)` returns `""` when `borders ∈ {:none, [], nil} and header_fill == nil`; prepend decoration **only when non-empty** (no stray newline).
- **D-16:** **Load-bearing render contract — collapse model, draw each interior edge ONCE.** Compute vertical/horizontal gridline positions once from `column_widths`/`row_heights`/`header_height`; emit each interior line as a single `m`/`l` segment (never per-cell → kills Prawn double-stroke). Emit `RG`/`w`/`d` once per stroke pass, `rg` once per fill. **Rowspan/colspan-aware**: suppress boundary segments where `_grid_layout` anchors (`ref_r`/`ref_c`) match across the boundary. Draw order: header fill → strokes → cell content (text always on top). All coords via `format_num` (PITFALLS #6). Reuse the writer's existing flow→PDF transform so borders register exactly with content.

### Certificate decorative frame (PATH-03)
- **D-17:** **Option shape: `border: false | true | %{...}`** (mirrors the recipe's existing `brand:` true/map idiom — least surprise). `true ≡ %{}` (all defaults); a map **merges over** the built-in defaults (subset override). Rejected: boolean-only (real additive-later risk → flat-option sprawl) and map-only (reintroduces the hardcoded-numerics footgun PATH-03 forbids).
- **D-18:** **Default design — single near-ink keyline (OVERTURNS the classic double-rule).** The Brand Book is explicitly anti-ornamental ("not flashy", **"not print-shop nostalgic"**, monoline/thin shapes, no skeuomorphism; personality "70% senior maintainer, 20% typographer"). A heavy double-rule is the diploma cliché the brand rejects and rasterizes worse (parallel hairlines shimmer at gallery DPI). Default = **one crisp keyline**, all geometry-derived ratios (orientation-invariant; `short = min(pw, ph)`):
  - `style: :single` (default)
  - `inset = 0.5 * min(ml, mr, mt, mb)` — half the smallest margin → frame provably sits in the dead margin band, never crosses content (the asymmetric-margin safety guard).
  - `weight = max(1.0, short / 400)` (~1.5pt) — substantial keyline, never sub-pixels at raster DPI.
  - `color = {34, 34, 34}` near-ink on the white sheet (brand `line-300` is "too subtle for essential boundaries"; brand-color frames reachable via the map).
  - square corners (radius 0).
  - **`:double` offered as a tunable, NOT the default** (gap `0.3·inset`, inner `weight/2`, 2:1 ratio) for users who explicitly want the diploma look.
- **D-19:** **Dogfood `%Rendro.Path{}`** — the frame is one Path with `:rect` op(s) + stroke (single) or two nested `:rect` ops (double). No bespoke ops (PITFALLS #5 respected: rect+stroke only, no transforms/clip/gradient/flourishes).
- **D-20:** **Layering mechanism (critical correction — do NOT draw "first in the body section").** A full-region Path in the `:body` flow region would consume the entire vertical flow budget and shove text off-page. Instead add a dedicated **`anchor: :fixed` `:frame` region** spanning the inset rect (`x: inset, y: inset, width: pw-2·inset, height: ph-2·inset`, all geometry-derived) and a `:certificate_frame` section targeting it. Anchored region blocks are **prepended** to `page.blocks` (`lib/rendro/pipeline/paginate.ex` ~422) → they serialize first = **painted underneath** the body text automatically. No z-index machinery; body flow untouched; `border: false` (default) stays byte-identical (no `:frame` region emitted). The Path block is sized to the region and draws a rect at its own block-relative bounds — the canonical D-07/D-08 case, **no tension** with the Path coord model.
- **D-21:** **Validation (errors-as-product, closed key allowlist):** reject `border` not in `false|true|map`; unknown map keys (allowlist `[:style, :color, :inset, :gap, :weight]`); `:style` not in `[:single, :double]`; non-numeric/negative `:inset`/`:weight`/`:gap`; `:inset >= min(margins)` (would cross into content — name the safe max); invalid `:color` → **delegate to the Path color validator** (one canonical `{r,g,b}` rejection message library-wide).

### Cross-cutting determinism & scope discipline
- **D-22:** **Every coordinate, color channel, line width, and dash entry routes through the existing `format_num`** (`:erlang.float_to_binary(n*1.0, decimals: 4)`) — no raw `Float.to_string` (PITFALLS #6). Op order = emit order; no sorting/reordering.
- **D-23:** **Transforms (`cm`), clipping (`W`), gradients, blend modes are DEFERRED** with explicit support-matrix entries (PATH-04, PITFALLS #5). v1 path surface = move/line/curve/rect/rounded-rect + stroke/fill only. The design must not preclude them (they wrap/sit inside the same balanced `q…Q`) but must not implement them.

### Claude's Discretion
- Exact module/function names, file layout, and internal helper signatures (planner/executor decide), provided they honor the locked public shapes above.
- Precise golden-fixture contents and test-file organization, provided they cover: existing-fixtures-unchanged (byte-identity), `%Rendro.Path{}` rect/line/curve/rounded-rect determinism, `borders: :all`/`[:outer,:rows]`/`header_fill` ops, draw-once/no-double-stroke, rowspan suppression, Certificate frame at A4 + Letter (both orientations) + `border: false` byte-identity.
- Exact `priv/support_matrix.json` row keys for the path surface + deferrals (follow the existing flat-row schema + validator).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap (authoritative scope)
- `.planning/REQUIREMENTS.md` — PATH-01..04 full text (the locked *what*). Note PATH-01 stroke convention `color/width/dash/cap/join; fill`.
- `.planning/ROADMAP.md` — Phase 84 goal + 4 success criteria. **Contains the `"#000"` example that D-05 corrects** — fix as part of this phase.

### Project research (mined for these decisions)
- `.planning/research/PITFALLS.md` — **Phase 84 section is binding**: #5 (no scope creep into a graphics package — defer transforms/clipping/gradients), #6 (float-format determinism via `format_num`), #7 (table borders opt-in, byte-identical default). Also #15 (gallery visuals follow the Brand Book).
- `.planning/research/JTBD-USER-FLOWS.md` — persona (Phoenix SaaS engineer); "fixed-position vs flow" API framing; tables are first-order for invoices/statements/receipts.
- `.planning/research/FEATURES.md` / `ARCHITECTURE.md` / `STACK.md` — pipeline shape (build→measure→paginate→render→validate), single-pass discipline, ReportLab DX anti-model.
- `prompts/rendro-oss-dna.md` — engineering DNA: data-first declarative AST, **errors-as-product (What/Where/Why/Next)**, "few options, document every one", honest support matrix, no overclaims.
- `prompts/Rendro Brand Book.txt` — **§5** personality/anti-personality (lines ~152–169), **§8** color system (lines ~317–388; `line-300` token line ~322, near-ink pairings line ~344, "too subtle for essential boundaries" line ~359), **§10** spacing/radius (lines ~487–502, "sheet of paper not rounded SaaS card"), **§11** illustration style (lines ~538–559, monoline/no gradients), **§12** iconography 2px stroke (line ~568). Drives the Certificate keyline design (D-18).

### Codebase touchpoints (verified file:line)
- `lib/rendro/text.ex:19,33` — canonical `{r,g,b}` 0–255 color type Path/tables/frame must match.
- `lib/rendro/pdf/writer.ex` — `:638-639` only color lowering (`r/255 … rg`); `:621-637` flow→PDF transform + Y-flip; `:1419-1459` `circle_path` kappa `0.5522847498` (reuse for rounded_rect); `:1758-1762` `format_num`; `:511-577` `render_block` dispatch (add Path + table-decoration clauses); `:1284-1334` existing `RG`/`re`/`S`/`f` form-field emission (reuse as template).
- `lib/rendro/image.ex` + `lib/rendro/pipeline/measure.ex:101-139` — Image bbox precedent = the model for the Path measure clause; `measure.ex:278-345` `_grid_layout` structure.
- `lib/rendro/pipeline/paginate.ex:~402-422,~515-532` — anchored-region prepend = the Certificate-frame background-layer mechanism (D-20); `stack_table_cells` ~104-141 sets absolute cell x/y.
- `lib/rendro/table.ex`, `lib/rendro/cell.ex` — structs to extend (D-13); `lib/rendro.ex` `table/2` + `normalize_table_attrs` (validation hook).
- `lib/rendro/recipes/certificate.ex` — geometry derivation, `page_template`/`sections`/`document` rungs, `validate_data!`/`brand:` idiom (extend for `border:`); `lib/rendro/page_size.ex` `resolve/2`; `lib/rendro/recipes/branded_invoice.ex` brand-map precedent.
- `test/rendro/deterministic_test.exs` + `test/rendro/recipes/certificate_test.exs` (C3/C4/C5/C11 multi-size patterns) — golden/byte-identity test patterns to extend.
- `priv/support_matrix.json` (+ its schema + validator + docs-contract lane) — terminal rows for the path surface and deferrals (PATH-04).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Low-level PDF graphics emission already exists** in form-field appearance streams (`writer.ex` ~1284–1459): `m`/`l`/`c`/`re`/`S`/`f`/`w`/`q`/`Q`, color via `rg`/`RG`, and a cubic-Bézier `circle_path` with the `0.5522847498` kappa. Path + table borders + the frame all reuse this — the heavy lift is the **render dispatch + content-stream assembly**, not new operator plumbing.
- **`format_num/1`** (writer.ex:1758–1762) is the single determinism discipline — all new coords/colors route through it.
- **`Rendro.PageSize.resolve/2`** returns `{w,h}` floats for `:a4`/`:us_letter` + orientation + custom tuples — the source of all geometry-derived Certificate-frame coordinates.
- **`_grid_layout`** (measure.ex:278) is the rowspan/colspan-resolved grid that drives draw-once border logic; cells already carry absolute `{x,y,width,height}` (set by `stack_table_cells` in paginate.ex).

### Established Patterns
- **Plain declarative structs dispatched by pattern-match** in `render_block` (no `Element` protocol) — `%Rendro.Path{}` follows Text/Image/Table; no builder DSL.
- **Author top-left / Y-down** everywhere; the writer owns the single Y-flip — Path reuses it (D-07).
- **Errors-as-product** (`ArgumentError`, What/Where/Why/Next) — all new validation follows it; the Certificate color validator **delegates** to the Path one (single canonical message).
- **Opt-in + inert default = byte-identical** discipline (already used for table/recipe options) — borders and the frame both honor it.
- **`@moduledoc tags: [:stable]`** on public modules; new public surface lands in `priv/public_api.json` via `mix rendro.api.gen` (the `Rendro.Color` helper stays internal / out of the manifest, D-02).

### Integration Points
- `render_block/5` (writer.ex) — new clauses: `%Rendro.Path{}`, and a table-decoration guarded branch.
- `measure.ex` — new `measure_block` clause for `%Rendro.Path{}` (after Image).
- `Rendro.table/2` + `normalize_table_attrs` (lib/rendro.ex) — borders/style/header_fill validation + set-normalization.
- `Rendro.Recipes.Certificate` `page_template`/`sections` — add the `:frame` region + section when `border` truthy; `validate_border!`.
- `priv/support_matrix.json` + docs-contract lane — terminal path rows + explicit deferral rows.

</code_context>

<specifics>
## Specific Ideas

- The four decisions were deliberately designed to be **mutually coherent**: a single `{r,g,b}` 0–255 color type is the through-line; the Certificate frame is built **on** the Path primitive (PATH-03 dogfoods PATH-01); table `border_style` is the **inert subset** of the Path stroke map. Plan them as one connected surface, in dependency order: **`Rendro.Color` + `%Rendro.Path{}` first**, then table borders (reuse stroke/color), then the Certificate frame (reuse Path).
- The user's standing preference (profile `opinionated` / `minimal_decisive`): research deeply, lock ONE coherent recommendation, proceed. These decisions are locked — do not re-open settled shape questions during planning; surface only genuinely new high-impact forks.

</specifics>

<deferred>
## Deferred Ideas

- **Transforms (`cm`), clipping (`W`/`W*`), gradients, blend modes, even-odd fill rule (`f*`)** — explicitly deferred to a future phase with support-matrix deferral rows (PATH-04 / PITFALLS #5). The Path design must not preclude them (same balanced `q…Q`), but must not implement them.
- **Hex / named / 0–1-float color input** — deferred as a future backward-compatible widening through `Rendro.Color.rgb("#..")` (Typst-style constructor), only if adopters ask. Never a bare hex string in a struct field.
- **Per-edge / per-range table border styling** (different style per side or cell range, à la ReportLab `TableStyle` ranges) — out of scope; v1 is one style across all drawn edges. Revisit only on demand.
- **Certificate corner flourishes / ornamental motifs** — out of scope (rect ops only; brand is anti-ornamental).

None of these are blockers; all are recorded so they aren't lost.

</deferred>

---

*Phase: 84-drawn-path-primitive-visible-polish*
*Context gathered: 2026-06-10*

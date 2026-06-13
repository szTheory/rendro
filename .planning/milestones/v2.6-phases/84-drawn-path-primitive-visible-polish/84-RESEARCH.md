# Phase 84: Drawn-Path Primitive & Visible Polish — Research

**Researched:** 2026-06-10
**Domain:** PDF vector graphics (PDF content-stream operators), Elixir struct extension, pipeline dispatch, docs-contract enforcement
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

D-01 through D-23 are FINAL — no alternatives to be researched or re-opened.

**Color (D-01 – D-06):** Accept `{r,g,b}` 0–255 tuples only on all new surfaces. Introduce internal `Rendro.Color` (`@moduledoc false`, NOT in `public_api.json`). Retrofit Text writer path to call `Rendro.Color` (D-03). Invalid-color errors are errors-as-product naming the hex footgun (D-04). Correct ROADMAP Phase-84 example from `"#000"` to `{0,0,0}` (D-05).

**Path (D-07 – D-12):** `%Rendro.Path{}` is a flow block; block-relative Y-down coords; one balanced `q … cm … Q`; caller-declared width/height primary, ops-extent fallback. Six ops: `{:move,x,y}`, `{:line,x,y}`, `{:curve,x1,y1,x2,y2,x3,y3}`, `{:rect,x,y,w,h}`, `{:rounded_rect,x,y,w,h,radius}`, `:close`. Stroke = bare tuple or map with `color/width/dash/cap/join`. Fill = bare tuple or `%{color:}`. Defaults match PDF initial state. Paint-op selection: `{nil,nil}→n`, `{nil,fill}→f`, `{strk,nil}→S`, `{strk,fill}→B`. `@enforce_keys [:ops]`, `defstruct [:ops, fill: nil, stroke: nil]`, `@moduledoc tags: [:stable]`. Add `Rendro.path(ops, attrs \\ [])` builder.

**Table (D-13 – D-16):** Three new flat fields: `borders: :none` (default), `border_style: nil`, `header_fill: nil`. Vocabulary: `:none|:outer|:rows|:columns|:grid|:all` or set-list. Byte-identity when defaults are inert. Draw-once collapse model; rowspan/colspan-aware; `table_decoration` returns `""` when inert.

**Certificate (D-17 – D-21):** `border: false | true | %{...}` option. Default = single near-ink keyline; `:double` opt-in. Dogfood `%Rendro.Path{}`. Layering via `anchor: :fixed` `:frame` region prepended to `page.blocks`. `border: false` stays byte-identical. Validation: closed allowlist `[:style, :color, :inset, :gap, :weight]`.

**Determinism (D-22 – D-23):** All coords/colors/widths through `format_num`. Transforms/clipping/gradients DEFERRED with explicit support-matrix rows.

### Claude's Discretion

- Exact module/function names, file layout, and internal helper signatures.
- Precise golden-fixture contents and test-file organization (must cover all listed cases).
- Exact `priv/support_matrix.json` row keys for path surface + deferrals (follow existing flat-row schema).

### Deferred Ideas (OUT OF SCOPE)

- Transforms (`cm`), clipping (`W`/`W*`), gradients, blend modes, even-odd fill rule (`f*`).
- Hex / named / 0-1-float color input.
- Per-edge / per-range table border styling.
- Certificate corner flourishes / ornamental motifs.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PATH-01 | Declarative `%Rendro.Path{}` block element (move/line/curve/rect/rounded-rect; stroke color/width/dash/cap/join; fill) rendered through the standard pipeline — transforms/clipping/gradients explicitly deferred | D-07..D-12 locked shape; writer.ex:1284–1483 provides all needed PDF operators; measure.ex:101–139 Image clause is the measure pattern |
| PATH-02 | Tables support opt-in borders/rules/header-band shading; default output byte-identical to today | D-13..D-16 locked shape; writer.ex:511–535 table render branch; measure.ex:278 `_grid_layout` is the collision data |
| PATH-03 | Certificate `border:` frame option; all coordinates geometry-derived; proven at A4 and US Letter | D-17..D-21; certificate.ex page_template idiom; paginate.ex:402–422 anchored-region prepend |
| PATH-04 | Byte-determinism golden tests + terminal `priv/support_matrix.json` rows | deterministic_test.exs + certificate_test.exs patterns; support_matrix.schema.json viewer_row constraints |

</phase_requirements>

---

## Summary

Phase 84 delivers three interlocking permanent-API surfaces on top of an already-clean 1.0 codebase. The heavy lifting is **dispatch and content-stream assembly**, not new PDF operator plumbing — every needed operator (`m/l/c/re/S/f/B/w/J/j/d/RG/rg/q/Q`) already exists in `lib/rendro/pdf/writer.ex`'s form-field appearance stream helpers (lines 1283–1483). The key research finding is that the content-stream construction pattern is already well established: `q … cm … Q` for Image (line 628), `q … re … S/f … Q` in form fields (lines 1283–1310). Path just needs a new `render_block` clause that uses the same Y-flip formula and emits a balanced `q … Q` containing the translated ops.

The table-decoration branch is the most algorithmically complex piece — it needs gridline positions derived from `table.column_widths`/`table.row_heights`/`table.header_height` (all present after Measure), and span-aware suppression using the `_grid_layout` 2-D list (already populated). The Certificate frame is architecturally clean: a `anchor: :fixed` region prepended to `page.blocks` via the existing `apply_page_template` mechanism (paginate.ex:422) paints underneath body text with no Z-index machinery.

All three surfaces share a single `Rendro.Color` internal module; the Certificate color validator delegates to the Path validator (one canonical error message). All coordinates and color channels flow through the existing `format_num/1` discipline. The public API manifest (`priv/public_api.json`) is maintained by `mix rendro.api.gen` via `@moduledoc tags:`; `Rendro.Color` stays out of the manifest by using `@moduledoc false`.

**Primary recommendation:** Implement in dependency order: (1) `Rendro.Color` internal helper + Text writer retrofit, (2) `%Rendro.Path{}` struct + measure clause + writer dispatch, (3) table borders + `_grid_layout` collapse + header shading, (4) Certificate frame region + validation. Wire golden tests and support_matrix rows last as a dedicated wave.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Color lowering (0–255 → 0–1 PDF floats) | Internal helper (`Rendro.Color`) | — | Cross-cutting; must not be inline in three separate places |
| Path struct / op validation | `lib/rendro/path.ex` (new) | `lib/rendro.ex` builder | Struct lives in its own file per project convention; builder is in top-level facade |
| Path bbox measurement | `lib/rendro/pipeline/measure.ex` | — | measure_block clause pattern; Image is the direct precedent |
| Path content-stream emission | `lib/rendro/pdf/writer.ex` | — | render_block dispatch; existing Y-flip + q/Q machinery |
| Table new fields / validation | `lib/rendro/table.ex` (struct) + `lib/rendro.ex` (normalize_table_attrs) | — | Same as existing: struct field + validation in the builder |
| Table border geometry + draw-once rendering | `lib/rendro/pdf/writer.ex` (table_decoration helper) | — | Gridline positions derived from already-populated Measure fields |
| Certificate frame region/section | `lib/rendro/recipes/certificate.ex` | — | Same three-rung pattern (page_template/sections/document) |
| Certificate border validation | `lib/rendro/recipes/certificate.ex` (validate_border!) | `Rendro.Color.validate/1` | Closed allowlist check; delegates color to canonical validator |
| Support matrix rows | `priv/support_matrix.json` | `test/docs_contract/` lane | Flat-row schema; validator gate; lane self-registration |
| Public API manifest update | `priv/public_api.json` via `mix rendro.api.gen` | `lib/mix/tasks/rendro/api.gen.ex` `@public_modules` list | New public modules (`Rendro.Path`) added to `@public_modules` |

---

## Standard Stack

No new external dependencies are introduced. This phase is pure Elixir + PDF operator reuse.

### Core — Existing, Reused
| Module / Asset | Location | Purpose | Why |
|----------------|----------|---------|-----|
| `format_num/1` | `writer.ex:1758–1762` | Deterministic float serialization | `:erlang.float_to_binary(n*1.0, decimals: 4)` — D-22 mandate |
| `circle_path/3` kappa `0.5522847498` | `writer.ex:1419–1483` | Cubic Bézier arc segments | D-09 `:rounded_rect` decomposition reuses this |
| `_grid_layout` | `measure.ex:278–285` | 2-D list of `%{is_continuation, cell, ref_r, ref_c}` | D-16 span-aware border suppression input |
| `apply_page_template` prepend | `paginate.ex:402–422` | `anchored_blocks ++ page.blocks` | D-20 Certificate frame paints underneath |
| `page_template`/`sections`/`document` three-rung | `certificate.ex:68–167` | Recipe composition idiom | D-17 `border:` option extends this cleanly |
| `validate_data!` ArgumentError pattern | `certificate.ex:197–279` | What/Where/Why/Next errors | D-21 validate_border! follows same shape |
| `PageSize.resolve/2` | `page_size.ex:11–18` | `{pw, ph}` floats for `:a4`/`:us_letter` | D-18/D-20 geometry-derived frame coords |

### New Modules (No External Deps)
| Module | Location | Purpose |
|--------|----------|---------|
| `Rendro.Color` | `lib/rendro/color.ex` | Internal: `to_pdf_components/1`, `rg/1`, `rg_stroke/1` (alias `RG`), `validate/1` — `@moduledoc false` |
| `Rendro.Path` | `lib/rendro/path.ex` | Struct: `@enforce_keys [:ops]`, `defstruct [:ops, fill: nil, stroke: nil]`, `@moduledoc tags: [:stable]` |

**Installation:** none — no new hex dependencies.

---

## Package Legitimacy Audit

> No external packages are introduced in this phase. All implementation uses existing Elixir/OTP standard library and already-present project dependencies.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Author API
  Rendro.path(ops, attrs)          Rendro.table(rows, borders: :all, ...)
         │                                    │
         ▼                                    ▼
  %Rendro.Block{                   %Rendro.Block{
    content: %Rendro.Path{}}         content: %Rendro.Table{borders:, border_style:, header_fill:}}
         │                                    │
         └───────────────────────────────────┘
                        │
                  Pipeline: Build → Compose → Measure
                        │
                  measure_block/3 ◄── new clause: %Rendro.Path{}
                  (Image precedent: caller dims primary, ops-extent fallback)
                        │
                  Pipeline: Paginate
                        │
                  apply_page_template/4
                  anchored_blocks ++ page.blocks   ◄── Certificate :frame region prepended
                        │
                  Pipeline: Render (writer.ex)
                        │
              build_content_stream/4
                  │                    │
            render_block               render_block
         %Rendro.Path{}            %Rendro.Table{}
              │                         │
    q … cm … Q                  table_decoration(table, page)
    (Y-flip + ops loop)          → "" when borders inert
    format_num all coords        → "rg w d RG … m l S" when active
              │                         │
              └───────────┬─────────────┘
                          ▼
                    PDF content stream bytes
                          │
                  priv/support_matrix.json
                  (path rows + deferral rows)
```

### Recommended Project Structure (New Files Only)

```
lib/rendro/
├── color.ex           # NEW: internal @moduledoc false helper
├── path.ex            # NEW: %Rendro.Path{} struct, @moduledoc tags: [:stable]
test/rendro/
├── path_test.exs      # NEW: golden + byte-determinism tests for PATH-01
├── table_borders_test.exs   # NEW: PATH-02 border rendering + byte-identity
test/rendro/recipes/
├── certificate_test.exs     # EXTEND: add C15..C20 border frame tests
test/docs_contract/
├── path_claims_test.exs     # NEW (optional): support_matrix + manifest claims lane
```

### Pattern 1: Content-Stream Block Rendering (Path)

[VERIFIED: codebase inspection `lib/rendro/pdf/writer.ex`]

The existing Image dispatch (writer.ex:610–633) shows the exact pattern:

```elixir
# Image pattern (writer.ex:621–628) — the template for Path
x = block.x + ox + page.margin_left
y = page.height - (block.y + oy + block.height) - page.margin_top
w = block.width
h = block.height
"q\n#{format_num(w)} 0 0 #{format_num(h)} #{format_num(x)} #{format_num(y)} cm\n/#{img_name} Do\nQ"
```

For Path the Y-flip becomes a **translation** (not scaling), and each op's y is reflected inside the `q…Q`:

```elixir
# Path render_block pattern (new)
defp render_block(_doc, %Rendro.Block{content: %Rendro.Path{} = path} = block, page,
                  _font_map, _image_map) do
  x = block.x + page.margin_left
  # block-bottom in PDF coords
  y = page.height - (block.y + block.height) - page.margin_top
  h = block.height

  # Graphics-state ops (omit if default)
  gstate = render_path_gstate(path)

  # Path construction ops (each op's y' = h - y_author)
  ops = render_path_ops(path.ops, h)

  # Paint op: {nil,nil}->n, {nil,fill}->f, {strk,nil}->S, {strk,fill}->B
  paint = paint_op(path.stroke, path.fill)

  IO.iodata_to_binary([
    "q\n",
    "1 0 0 1 ", format_num(x), " ", format_num(y), " cm\n",
    gstate,
    ops,
    paint, "\n",
    "Q"
  ])
end
```

Key: the `cm` here is a **translation-only matrix** (`1 0 0 1 tx ty`) — no scale — because ops carry their own width/height semantics. D-07 says "Y-flip by `y' = block.height - y`" for each op; the `cm` moves the origin to block-bottom-left in PDF space.

### Pattern 2: Rounded Rect Op Decomposition

[VERIFIED: codebase inspection `lib/rendro/pdf/writer.ex:1419–1483`]

`circle_path/3` at writer.ex:1419 already uses kappa `0.5522847498` to build cubic Bézier arcs for a full ellipse. The same kappa applies for `:rounded_rect`. For a rectangle `(x, y, w, h, r)` (block-relative, Y-down author space), the four-corner decomposition:

```
top-left arc:     m at (x+r, y)           → corner from top edge to left edge
top-right arc:    from (x+w-r, y)         → corner from left edge to top edge
bottom-right arc: from (x+w, y+h-r)       → etc.
bottom-left arc:  from (x+r, y+h)         → etc.
```

Each arc: 3-point `c` with control-point distance `r * 0.5522847498`.

After the Y-flip (`y' = block_h - y_author`), all `c` control points are just `x_author, block_h - y_author` — the kappa arithmetic is unchanged because `cm` is affine.

### Pattern 3: Table Decoration (Draw-Once Collapse)

[VERIFIED: codebase inspection `lib/rendro/pipeline/measure.ex:278–285`, `lib/rendro/pipeline/paginate.ex:104–141`]

After Measure, `table.column_widths`, `table.row_heights`, `table.header_height`, and `table._grid_layout` are all populated. After Paginate's `stack_table_cells`, each cell has absolute `{x, y}` in block-relative coords.

The collapse model: compute one set of vertical lines and one set of horizontal lines. Emit each as a single `m/l` segment (never draw per-cell edges twice):

```elixir
defp table_decoration(table, page, block) do
  # Guard: early exit when all new fields are inert
  if table.borders in [:none, [], nil] and is_nil(table.header_fill), do: "", else:
    do_table_decoration(table, page, block)
end

defp do_table_decoration(table, page, block) do
  # Y-flip origin: block's bottom-left in PDF coords
  bx = block.x + page.margin_left
  by = page.height - (block.y + block.height) - page.margin_top
  total_w = Enum.sum(table.column_widths)
  total_h = table.header_height + Enum.sum(table.row_heights)

  borders = normalize_borders(table.borders)

  # 1. Header fill rectangle (if header_fill set and header exists)
  fill_ops = render_header_fill(table, bx, by, total_w, total_h)

  # 2. Stroke setup (emit RG/w/d once)
  stroke_ops = render_stroke_setup(table.border_style)

  # 3. Outer border (4 lines)
  outer_ops = if :outer in borders, do: render_outer(bx, by, total_w, total_h), else: ""

  # 4. Interior horizontal rules (between rows)
  h_rules = if :rows in borders or :grid in borders or :all in borders,
    do: render_h_rules(table, bx, by, total_h), else: ""

  # 5. Interior vertical rules (between columns)
  v_rules = if :columns in borders or :grid in borders or :all in borders,
    do: render_v_rules(table, bx, by, total_h, page), else: ""

  IO.iodata_to_binary(["q\n", fill_ops, stroke_ops, outer_ops, h_rules, v_rules, "Q\n"])
end
```

**Span suppression** for interior rules: before emitting a vertical line at `x_offset` between col `c` and `c+1`, check each row `r` — if `grid_layout[r][c].ref_c != c` (it's a colspan continuation), skip that horizontal segment for row `r` (emit two segments: one above, one below the merged cell). Similarly for rowspan and horizontal lines.

### Pattern 4: Certificate Frame Region Prepend

[VERIFIED: codebase inspection `lib/rendro/pipeline/paginate.ex:402–422`]

`apply_page_template/4` at line 402 does:
```elixir
%{page | blocks: anchored_blocks ++ page.blocks}
```

Anchored (non-body) region blocks are **prepended** to `page.blocks`. Content-stream assembly in `build_content_stream/4` is `Enum.map_join(page.blocks, ...)` — so prepended blocks serialize **first** = painted underneath. No Z-index needed.

The Certificate `page_template/1` must emit a `:frame` region when `border` is truthy:

```elixir
# In Certificate.page_template/1 (when border truthy):
inset = 0.5 * Enum.min([ml, mr, mt, mb])
Rendro.region(
  name: :frame,
  role: :custom,
  anchor: :fixed,
  x: inset,
  y: inset,
  width: pw - 2 * inset,
  height: ph - 2 * inset
)
```

And `sections/2` adds a `:certificate_frame` section targeting the `:frame` region containing a `%Rendro.Path{}` block sized to the region with a `:rect` op at block-relative `{0, 0, width, height}`.

### Pattern 5: `_grid_layout` Shape for Border Logic

[VERIFIED: codebase inspection `lib/rendro/pipeline/measure.ex:278–285`]

`_grid_layout` is a 2-D list (list of lists), `grid_layout[r][c]` is a map:
```elixir
%{
  is_continuation: boolean(),   # true when this cell spans here from another origin
  cell: measured_cell | nil,    # the %Rendro.Cell{} at its canonical origin
  ref_r: integer(),             # origin row index
  ref_c: integer()              # origin column index
}
```

To detect a column-spanning cell at position `{r, c}`: `grid_layout[r][c].is_continuation == true and grid_layout[r][c].ref_r == r` (same row, but `ref_c != c` → colspan). To detect a row-spanning cell: `is_continuation == true and ref_c == c` (same column, but `ref_r != r` → rowspan).

### Anti-Patterns to Avoid

- **Inline color lowering:** Do not replicate `format_num(r/255)` at each new call site. Writer.ex:638–639 is the one remaining inline instance — it must be replaced by `Rendro.Color.rg/1` in the D-03 retrofit. New code calls `Rendro.Color`.
- **`Float.to_string` in any new coordinate:** Use `format_num/1` exclusively. Raw `Float.to_string` produces nondeterministic precision (PITFALLS #6).
- **Table decoration with per-cell loops:** Drawing two lines per shared edge is the Prawn double-stroke footgun (D-16). Compute gridline positions once; emit each segment once.
- **Full-region body Path for Certificate frame:** A Path in the `:body` flow region consumes the full body height, pushing all text off-page. The D-20 `anchor: :fixed` `:frame` region is the correct mechanism.
- **Sorting/reordering ops:** Op order = emit order (D-22). No sorting.
- **Using `border_style` `cap`/`join` for table axis-aligned lines:** Omit cap/join from `border_style` (D-13) — they're irrelevant for horizontal/vertical segments and their omission keeps the struct clean.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Float serialization | Custom float formatter | `format_num/1` (writer.ex:1758) | D-22; `format_num` is the existing determinism discipline |
| Cubic arc corners | Custom trigonometry | Reuse `0.5522847498` kappa from `circle_path/3` (writer.ex:1423) | Kappa is already audited; one place in the codebase |
| PDF operator emission | New PDF writer module | Inline iodata in existing `render_block` clauses | All operators already present in form-field appearance helpers |
| Color validation | Inline guard clauses | `Rendro.Color.validate/1` | One canonical `{r,g,b}` rejection message for Path, Table, Certificate |
| Grid span detection | Custom span-lookup | `_grid_layout[r][c]` fields (`ref_r`, `ref_c`, `is_continuation`) | Already populated by Measure; no re-computation needed |
| Page geometry | Hardcoded A4 constants | `Rendro.PageSize.resolve/2` | D-18/D-20; page_size.ex:11–18 already has `:a4` and `:us_letter` |
| `borders` set normalization | Ad-hoc dedup | Canonical normalization in `normalize_table_attrs` (or a helper it calls) | Stable golden bytes require canonical form regardless of author ordering |

**Key insight:** The PDF operator machinery is already present. Every `m/l/c/re/S/f/B/w/J/j/d/RG/rg/q/Q` operator used in Phase 84 exists verbatim in writer.ex lines 1283–1483. Phase 84 assembles these into a new dispatch path, not new operator plumbing.

---

## Research Focus Area Findings

### 1. Content-Stream Assembly Mechanics

[VERIFIED: `lib/rendro/pdf/writer.ex` direct inspection]

**`build_content_stream/4`** (writer.ex:505–509):
```elixir
defp build_content_stream(doc, %Rendro.Page{} = page, font_map, image_map) do
  Enum.map_join(page.blocks, "\n", fn block ->
    render_block(doc, block, page, font_map, image_map)
  end)
end
```

Each block's contribution is joined with `"\n"`. A new `render_block` clause for `%Rendro.Path{}` fits naturally after the Image clause (line 567–575 dispatches to the 5-arity overload; line 577 is the catch-all returning `""`).

**Y-flip formula** (writer.ex:621–622, Image clause):
```
x = block.x + ox + page.margin_left
y = page.height - (block.y + oy + block.height) - page.margin_top
```
For Path (no `ox`/`oy` offset — Path is a top-level block, not a cell):
```
x = block.x + page.margin_left
y = page.height - (block.y + block.height) - page.margin_top
```
This places the **block's bottom-left corner** at `(x, y)` in PDF user space (Y-up). The `cm` matrix `1 0 0 1 x y` then makes `(0,0)` within the `q…Q` equal to the block's bottom-left, and each op's `y' = block.height - y_author` completes the Y-flip.

**Existing PDF operators** (writer.ex:1282–1340, form-field appearance helpers):
- `re` → rectangle path: `format_num(x) <> " " <> format_num(y) <> " " <> format_num(w) <> " " <> format_num(h) <> " re"`
- `S` → stroke only
- `f` → fill only
- `m/l` → moveto/lineto
- `c` → cubic Bézier (6 operands: x1 y1 x2 y2 x3 y3)
- `RG` → stroke color (0–1 floats)
- `rg` → fill color (0–1 floats)
- `w` → line width
- `q/Q` → save/restore graphics state
- `h` → close path (`:close` op)
- `n` → no-op path terminator (for `{nil, nil}`)
- `B` → fill then stroke (for `{stroke, fill}`)
- `J` → line cap (0=butt, 1=round, 2=square)
- `j` → line join (0=miter, 1=round, 2=bevel)
- `d` → dash pattern: `[array] phase d` (e.g., `[3 2] 0 d`)

**Graphics-state default omission:** PDF initial graphics state is `0 0 0` stroke/fill, width `1.0`, butt cap (0), miter join (0), solid dash. When Path fields match these values, emit nothing (D-10 says "defaults match PDF initial state so omitting them emits nothing → byte-clean").

### 2. Determinism Harness

[VERIFIED: `test/rendro/deterministic_test.exs`, `test/rendro/recipes/certificate_test.exs` direct inspection]

**Pattern:** `Rendro.render(doc, deterministic: true)` is the entry point. The existing determinism tests use three approaches:

**Approach A — Two-render byte identity:**
```elixir
{:ok, pdf1} = Rendro.render(doc, deterministic: true)
{:ok, pdf2} = Rendro.render(doc, deterministic: true)
assert pdf1 == pdf2
```
Used in: `DeterministicTest` "two deterministic renders", `CertificateTest` C11.

**Approach B — Content-stream string assertion:**
```elixir
assert pdf1 =~ "/Subtype /Link"
assert pdf1 =~ "(Linked body) Tj"
```
PDF binary content assertions with `=~`. Can directly verify PDF operator presence for Path tests.

**Approach C — Cross-instance structural equality:**
```elixir
{:ok, pdf1} = Rendro.render(embedded_file_order_doc(:alpha_first), deterministic: true)
{:ok, pdf2} = Rendro.render(embedded_file_order_doc(:zeta_first), deterministic: true)
assert pdf1 == pdf2
```
Proves that two semantically-equivalent documents produce byte-identical output.

**For Phase 84** the required assertions are:
- `pdf =~ "re\nS"` or `pdf =~ "re\nf"` (rect + paint op) — PATH-01 rect
- `pdf =~ "m\n" <> ... <> "l\n"` patterns for line ops
- Content-stream ops have all numbers formatted via `format_num` (4 decimal places max)
- Two renders of same Path document are byte-identical (Approach A)
- Document without borders option is byte-identical to prior fixture (Approach A between `border: nil` and no-borders-field doc)

**No golden PNG harness yet** — Phase 85 is the raster lane. Phase 84's validation is PDF binary assertions + byte-identity comparisons only. D-03 says "add a golden asserting black-text bytes unchanged" but this is a standard Approach A test, not a file-based golden.

### 3. Measure.ex Bbox Clause for `%Rendro.Path{}`

[VERIFIED: `lib/rendro/pipeline/measure.ex:101–141` direct inspection]

The Image clause (measure.ex:101–139) is the direct template:

```elixir
defp measure_block(
       doc,
       %Rendro.Block{content: %Rendro.Image{} = image} = block,
       _container_width
     ) do
  # ... intrinsic dims from asset registry ...
  {width, height} =
    case {block.width, block.height, image.fit} do
      {nil, nil, {fit_w, fit_h}} -> ...
      {w, nil, nil} when not is_nil(w) -> ...
      {nil, h, nil} when not is_nil(h) -> ...
      {w, h, nil} when not is_nil(w) and not is_nil(h) -> {w, h}
      _ -> {intrinsic_w, intrinsic_h}
    end
  {:ok, %{block | width: width, height: height}}
end
```

For `%Rendro.Path{}` the clause is:

```elixir
defp measure_block(
       _doc,
       %Rendro.Block{content: %Rendro.Path{} = path} = block,
       _container_width
     ) do
  {width, height} =
    case {block.width, block.height} do
      {w, h} when not is_nil(w) and not is_nil(h) ->
        {w, h}  # caller-declared dims — primary path (D-08)

      {w, nil} when not is_nil(w) ->
        {w, compute_ops_height(path.ops)}

      {nil, h} when not is_nil(h) ->
        {compute_ops_width(path.ops), h}

      {nil, nil} ->
        {compute_ops_width(path.ops), compute_ops_height(path.ops)}
    end
  {:ok, %{block | width: width, height: height}}
end
```

**`compute_ops_extent`:** fold ops accumulating `max_x`/`max_y` — conservative (D-08 says "conservative curve bound"):
- `{:move, x, y}` → `{x, y}`
- `{:line, x, y}` → `{x, y}`
- `{:curve, x1, y1, x2, y2, x3, y3}` → `{max(x1,x2,x3), max(y1,y2,y3)}`
- `{:rect, x, y, w, h}` → `{x+w, y+h}`
- `{:rounded_rect, x, y, w, h, _r}` → `{x+w, y+h}` (radius doesn't extend beyond w/h)
- `:close` → no change

D-08: "single intrinsic block" — Path never fragments across pages. The measure clause returns the full height; paginate treats it as `split_policy: :atomic` effectively (the block is never split).

### 4. `_grid_layout` → Draw-Once Borders

[VERIFIED: `lib/rendro/pipeline/measure.ex:278–285`, `lib/rendro/pipeline/paginate.ex:104–141` direct inspection]

**Grid position inputs** (all available after Measure + Paginate):
- `table.column_widths` — list of column widths (floats)
- `table.row_heights` — list of row heights (floats)
- `table.header_height` — header height (float or 0)
- `table._grid_layout` — 2-D list: `grid_layout[r][c] = %{is_continuation:, cell:, ref_r:, ref_c:}`

**Gridline position derivation:**

```elixir
# Cumulative x positions of vertical lines (including left and right edges)
# [0, col0_w, col0_w+col1_w, ..., total_w]
x_positions = Enum.scan([0 | table.column_widths], 0, &(&1 + &2))

# Cumulative y positions of horizontal lines (Y-down author space)
# [0, header_h, header_h+row0_h, ..., total_h]
y_positions = [0, table.header_height | Enum.scan(table.row_heights, table.header_height, &(&1 + &2))]
```

Then translate each `(x_pos, y_pos)` by the block's `cm` offset before emitting.

**Span suppression for interior vertical lines** (between col `c` and `c+1`):
For each `r`, if `grid_layout[r][c].ref_c != c` (the cell at `[r][c]` has its origin in a column before `c`, meaning it spans this boundary) → skip that row's vertical segment at this column boundary. Emit the partial segments above and below instead (or fully omit if the entire vertical stripe is merged).

**Span suppression for interior horizontal lines** (between row `r` and `r+1`):
For each `c`, if `grid_layout[r][c].ref_r != r` (rowspan extends this boundary) → skip that column's horizontal segment. Similarly if `grid_layout[r+1][c].ref_r < r+1`.

**Practical approach:** For each interior vertical rule at column boundary `c+1`: scan all rows `r`; emit a `m … l` segment only if `grid_layout[r][c].ref_c == c` and `grid_layout[r][c+1].ref_c == c+1` (neither cell spans across this boundary at row `r`). Group consecutive unspanned rows into a single segment to minimize operators.

### 5. Anchored-Region Prepend Mechanism

[VERIFIED: `lib/rendro/pipeline/paginate.ex:402–422` direct inspection]

```elixir
defp apply_page_template(%Page{} = page, idx, layout, total) do
  region_suppress_on = Map.get(layout, :region_suppress_on, %{})

  anchored_blocks =
    layout.template.regions
    |> Enum.reject(&(&1.name == :body))
    |> Enum.flat_map(fn region ->
      ...
      |> anchor_region_blocks(region, page)   # assigns absolute x/y to each block
      ...
    end)

  %{page | blocks: anchored_blocks ++ page.blocks}  # ← PREPEND
end
```

The `anchor_region_blocks/3` (line 515–532) iterates region blocks and sets `block.x = start_x + block.x` and `block.y = current_y`, stacking vertically. For the Certificate `:frame` region containing a single Path block sized to fill the region, the single block gets `{x: inset, y: inset}` after anchoring.

**Critical:** The `:frame` region must be added to `layout.template.regions` (the `%PageTemplate{}.regions` list) and the Path block must be in `layout.region_blocks[:frame]`. The `document/2` rung sets both via the standard `add_section/2` mechanism (sections target regions by name).

**`border: false` byte-identity:** When `border` is `false` or absent (default), no `:frame` region is added to the template and no `:certificate_frame` section is added. The `layout.region_blocks` map has no `:frame` key. `apply_page_template` iterates `regions |> Enum.reject(:body)` — with no `:frame` region in the template, the anchored_blocks list is identical to before the feature addition. Result: zero-byte change in the output PDF. [VERIFIED: consistent with D-15 `table_decoration` inert-guard pattern and D-20 explicit design]

### 6. Support Matrix Schema + Validator + Docs-Contract Lane

[VERIFIED: `priv/schemas/support_matrix.schema.json`, `test/docs_contract/script_support_claims_test.exs` direct inspection]

The schema (`additionalProperties: true` at the top level) means the path surface can be added as a **new top-level key** `"path_primitive"` without touching the required-fields list (`forms`, `signing`, `embedded_files`, `links`, `protection`).

**Viewer row schema** (`$defs.viewer_row`): The `viewer_row` definition applies to items in `viewer_map` objects. But PATH-04's support-matrix entries are **capability entries**, not viewer rows — they describe engine behavior, not viewer rendering. Looking at the `text_shaping` section (added in Phase 83), those rows use `{status: "explicit_deferral", evidence_deferred: "..."}` inside a named section. This is the same schema used by `explicit_deferral` viewer rows, applied to capability entries.

**Path surface rows structure:**
```json
"path_primitive": {
  "capabilities": {
    "move_line_curve_rect_rounded_rect": "supported",
    "stroke_color_width_dash_cap_join": "supported",
    "fill": "supported",
    "deterministic_output": "supported"
  },
  "behaviors": {
    "block_relative_y_down_coords": "supported",
    "ops_extent_bbox_fallback": "supported",
    "format_num_determinism": "supported"
  },
  "explicit_deferrals": {
    "transforms_cm": {
      "status": "explicit_deferral",
      "evidence_deferred": "Affine transforms (cm operator) deferred — adds viewer-compat surface; v1 path surface is move/line/curve/rect/rounded-rect + stroke/fill only."
    },
    "clipping_W": {
      "status": "explicit_deferral",
      "evidence_deferred": "Clipping paths (W/W* operators) deferred — adds viewer-compat surface."
    },
    "gradients": {
      "status": "explicit_deferral",
      "evidence_deferred": "Gradients (shading dictionaries) deferred — adds viewer-compat surface."
    }
  }
}
```

**Docs-contract lane for path:** Follow the `script_support_claims_test.exs` pattern — add `test/docs_contract/path_claims_test.exs` that asserts:
- `matrix =~ ~s|"path_primitive"|`
- `matrix =~ ~r/"transforms_cm".*?"status".*?"explicit_deferral"/s`
- `matrix =~ ~r/"clipping_W".*?"status".*?"explicit_deferral"/s`
- `matrix =~ ~r/"gradients".*?"status".*?"explicit_deferral"/s`

And add the lane to `scripts/verify_docs.exs` (self-registration pattern — the lane test itself asserts the script contains it, as seen in `api_stability_claims_test.exs:104–109`).

### 7. Public API Manifest (`priv/public_api.json` + `mix rendro.api.gen`)

[VERIFIED: `lib/mix/tasks/rendro/api.gen.ex` direct inspection]

`mix rendro.api.gen` reads `@public_modules` (the explicit list in `api.gen.ex:43–98`) and introspects `Code.fetch_docs/1` for `tags: [:stable]` or `tags: [:adapter]`. It writes a sorted, deterministic JSON manifest.

**What lands in the manifest for Phase 84:**

| Module | Action | Why |
|--------|--------|-----|
| `Rendro.Path` | Add to `@public_modules` (stable tier) | `@moduledoc tags: [:stable]` — new public struct |
| `Rendro.Table` | Already in manifest | New fields don't change manifest (struct fields not tracked) |
| `Rendro` | Already in manifest; add `path/2` function | New builder function → manifest shows new function |
| `Rendro.Recipes.Certificate` | Already in manifest | No new public function; `border:` is an existing `document/2` option |
| `Rendro.Color` | NOT added | `@moduledoc false` → excluded by the `tags:` filter |

**Manifest update process:**
1. Write `Rendro.Color` with `@moduledoc false`.
2. Write `Rendro.Path` with `@moduledoc tags: [:stable]`.
3. Add `Rendro.Path` to `@public_modules` list in `api.gen.ex`.
4. Add `Rendro.path/2` spec to `Rendro` (the function appears in the manifest since `Rendro` is already there).
5. Run `mix rendro.api.gen` → updates `priv/public_api.json`.
6. Commit updated manifest.

The `public_api_contract_test.exs` (Assertion 2) automatically fails if the checked-in manifest doesn't match the generated one — this is the regression guard.

---

## Common Pitfalls

### Pitfall 1: Double Y-Flip in Path Op Rendering
**What goes wrong:** Applying the block-level Y-flip and then also flipping each op's y, or not flipping at all, produces upside-down or displaced graphics.
**Why it happens:** Confusion between the `cm` translation (which positions block origin) and the op-level flip (`y' = block.height - y_author`).
**How to avoid:** The `cm` matrix translates to block bottom-left in PDF space: `1 0 0 1 {block_x_pdf} {block_y_pdf}`. Inside the `q…Q`, `(0,0)` is the block's bottom-left. Author ops are Y-down from block top-left; `y_pdf = block.height - y_author` for every op. The `cm` handles the page-level placement; the per-op flip handles the axis convention.
**Warning signs:** A rendered rect appears at the wrong vertical position on the page; an `{:rect, 0, 0, w, h}` doesn't align with the block boundary.

### Pitfall 2: Non-Canonical `borders` Set → Non-Deterministic Golden Bytes
**What goes wrong:** `borders: [:all, :outer]` and `borders: [:outer, :all]` produce the same visual output but different atoms in the struct, causing byte-identical tests to fail.
**Why it happens:** Elixir lists are ordered; struct fields are serialized to content-stream in field-value order.
**How to avoid:** Normalize at construction in `normalize_table_attrs`: `border_atoms |> MapSet.new() |> MapSet.to_list() |> Enum.sort()` (or use a canonical expansion: `:all → [:outer, :rows, :columns]`). D-14: "A list is a set: order-independent, de-duplicated, normalized to a canonical form at construction".

### Pitfall 3: Stray Newline When Table Decoration Returns Empty
**What goes wrong:** If `table_decoration` returns `""` but it's joined with `"\n"` in the content-stream assembly, a stray newline appears in the output, breaking byte-identity with the prior borderless baseline.
**Why it happens:** `Enum.map_join(page.blocks, "\n", ...)` between blocks is fine, but within the table render clause, prepending decoration naively adds an extra separator.
**How to avoid:** D-15: "prepend decoration **only when non-empty** (no stray newline)." Use `if decoration == "", do: cells_content, else: decoration <> "\n" <> cells_content`.

### Pitfall 4: `measure_block` Catch-All Clause Ordering
**What goes wrong:** Adding the `%Rendro.Path{}` clause after the catch-all `defp measure_block(_doc, block, _container_width), do: {:ok, block}` means Path blocks are never measured.
**Why it happens:** Elixir function clause matching is sequential; the catch-all at measure.ex:141 would match first.
**How to avoid:** Insert the Path clause **before** the catch-all at line 141. Same position relative to Image (line 101).
**Warning signs:** Path blocks have `nil` height and never render (empty content-stream contribution).

### Pitfall 5: Certificate Frame Path Sized to Full Page Instead of Inset Rect
**What goes wrong:** The Path block's `:rect` op uses the region's `width` and `height` but the region was already positioned at `(inset, inset)` — so the rect coordinate is already block-relative `{0, 0, region_w, region_h}`.
**Why it happens:** Confusion about absolute vs. block-relative coordinates. The Path block is sized to fill its region; the region handles the inset placement.
**How to avoid:** The Path block should have `width: region_w, height: region_h` and ops `[{:rect, 0, 0, region_w, region_h}]`. The `anchor_region_blocks` mechanism assigns the absolute `{x: inset, y: inset}` position; the Path render clause then computes `block.x + page.margin_left` etc. from those absolute coords.

### Pitfall 6: Missing `Rendro.Path` in `@public_modules` After Implementation
**What goes wrong:** `public_api_contract_test.exs` Assertion 2 fails because the freshly-generated manifest contains `Rendro.Path` but the checked-in `priv/public_api.json` does not (or vice versa).
**Why it happens:** Forgetting to both (a) add to `@public_modules` AND (b) run `mix rendro.api.gen` and commit the updated manifest.
**How to avoid:** Make manifest regen a distinct task in the plan; assert CI fails before the regen step. The test is `async: false` and regenerates in-memory — it will catch this automatically.

### Pitfall 7: `inset >= min(margins)` Certificate Validation Omission
**What goes wrong:** A caller passes `inset: 200` on a page with 72pt margins; the frame rect extends outside the page content area, crossing into body text.
**Why it happens:** No validation of `inset` vs. margin bounds.
**How to avoid:** D-21 mandates: `validate_border!` raises when `:inset >= min(margins)` with a message naming the safe max.

---

## Code Examples

### Color Lowering — Existing Pattern (to Retrofit)

[VERIFIED: `lib/rendro/pdf/writer.ex:635–639`]

```elixir
# Current inline (writer.ex:638–639) — to be replaced by Rendro.Color.rg/1
{r, g, b} = text.color
color_op = "#{format_num(r / 255)} #{format_num(g / 255)} #{format_num(b / 255)} rg"
```

`Rendro.Color` internal module interface (to implement):
```elixir
defmodule Rendro.Color do
  @moduledoc false

  # Returns "R G B rg\n" (fill color)
  def rg({r, g, b}),
    do: "#{format_num(r / 255)} #{format_num(g / 255)} #{format_num(b / 255)} rg\n"

  # Returns "R G B RG\n" (stroke color)
  def rg_stroke({r, g, b}),
    do: "#{format_num(r / 255)} #{format_num(g / 255)} #{format_num(b / 255)} RG\n"

  # Returns {r_f, g_f, b_f} as 0–1 floats
  def to_pdf_components({r, g, b}),
    do: {r / 255, g / 255, b / 255}

  # Returns :ok | {:error, reason_string}
  def validate({r, g, b})
      when is_integer(r) and r in 0..255 and
           is_integer(g) and g in 0..255 and
           is_integer(b) and b in 0..255, do: :ok

  def validate(value) do
    {:error, """
    Invalid color value: #{inspect(value)}.
    What:  Rendro color values must be {r, g, b} integer tuples with each channel 0–255.
    Where: Color validation
    Why:   Got #{inspect(value)}. If you have a hex color string like "#2C6BED",
           convert it to a tuple: {44, 107, 237}.
    Next:  Use a {r, g, b} tuple. Example: {0, 0, 0} for black, {255, 255, 255} for white.
    """}
  end

  defp format_num(n), do: :erlang.float_to_binary(n * 1.0, decimals: 4)
end
```

### Path Op Rendering Sketch

[VERIFIED: codebase pattern extrapolation from existing PDF operators in writer.ex]

```elixir
defp render_path_op({:move, x, y}, block_h),
  do: "#{format_num(x)} #{format_num(block_h - y)} m\n"

defp render_path_op({:line, x, y}, block_h),
  do: "#{format_num(x)} #{format_num(block_h - y)} l\n"

defp render_path_op({:curve, x1, y1, x2, y2, x3, y3}, block_h),
  do: "#{format_num(x1)} #{format_num(block_h - y1)} " <>
      "#{format_num(x2)} #{format_num(block_h - y2)} " <>
      "#{format_num(x3)} #{format_num(block_h - y3)} c\n"

defp render_path_op({:rect, x, y, w, h}, block_h),
  # PDF re: x y w h re; origin is bottom-left, h is positive upward
  do: "#{format_num(x)} #{format_num(block_h - y - h)} " <>
      "#{format_num(w)} #{format_num(h)} re\n"

defp render_path_op(:close, _block_h), do: "h\n"
```

Note: `{:rect, x, y, w, h}` in author (Y-down) → `{x, block_h - y - h}` in PDF (Y-up) with same `w` and `h`. The `re` operator takes bottom-left x/y, width, height.

### Paint Op Selection

[VERIFIED: D-11 lock; PDF specification `n`, `S`, `f`, `B` operators]

```elixir
defp paint_op(nil, nil), do: "n"
defp paint_op(nil, _fill), do: "f"
defp paint_op(_stroke, nil), do: "S"
defp paint_op(_stroke, _fill), do: "B"
```

### Stroke Graphics-State Setup

```elixir
defp render_path_gstate(%Rendro.Path{stroke: nil}), do: ""
defp render_path_gstate(%Rendro.Path{stroke: stroke}) do
  {r, g, b} = stroke_color(stroke)
  width = stroke_width(stroke)
  cap = stroke_cap(stroke)
  join = stroke_join(stroke)
  dash = stroke_dash(stroke)
  IO.iodata_to_binary([
    Rendro.Color.rg_stroke({r, g, b}),
    if(width == 1.0, do: "", else: "#{format_num(width)} w\n"),
    if(cap == :butt, do: "", else: "#{cap_code(cap)} J\n"),
    if(join == :miter, do: "", else: "#{join_code(join)} j\n"),
    if(is_nil(dash), do: "", else: render_dash(dash))
  ])
end
```

### Certificate Frame Geometry

[VERIFIED: `lib/rendro/page_size.ex:5–18`, `lib/rendro/recipes/certificate.ex:69–101` direct inspection]

```elixir
# In certificate.ex page_template/1, when opts[:border] is truthy:
{pw, ph} = Rendro.PageSize.resolve(page_size, orientation)
short = min(pw, ph)
inset = 0.5 * Enum.min([ml, mr, mt, mb])
weight = max(1.0, short / 400)

# Page geometry for A4-landscape: pw=841.89, ph=595.28, margin=72
# → inset = 0.5 * 72 = 36.0
# → short = 595.28, weight = max(1.0, 595.28/400) = 1.4882

frame_region = Rendro.region(
  name: :frame,
  role: :custom,
  anchor: :fixed,
  x: inset,           # region x in absolute page coords
  y: inset,           # region y in absolute page coords
  width: pw - 2 * inset,
  height: ph - 2 * inset
)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline `format_num(r/255)` per-site | `Rendro.Color.rg/1` centralized | Phase 84 (D-03) | Single canonical message + single place |
| No vector graphics element | `%Rendro.Path{}` flow block | Phase 84 | Gallery shows bordered tables, certificate frames |
| Borderless-only tables | Opt-in `borders:` field | Phase 84 | Invoice/statement visual polish |
| Certificate no border | `border: false/true/%{}` option | Phase 84 | Diploma/certificate visual completeness |

**Deprecated/outdated:**
- The `stroke: %{color: "#000", width: 1.0}` hex-string example in ROADMAP.md Phase-84 success criterion 1 — D-05 mandates correcting to `{0,0,0}`. This is a documentation fix, not an API removal.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `:frame` region in Certificate must be added via a new region entry in `page_template/1`'s `regions:` list, and the corresponding blocks added via a new section from `sections/2` targeting `:frame` | Architecture Patterns §4 | If the layout system doesn't support `:frame` as a region name, a different mechanism is needed — but `anchor: :fixed` is already a valid `Region.anchor()` type (`lib/rendro/region.ex:17`) so this is [VERIFIED] |
| A2 | `borders: :all` expands to `[:outer, :rows, :columns]` (outer + all interior lines) | Research §4 | D-14 says `:all = outer+grid`; `:grid = rows+columns` — so `:all = [:outer, :rows, :columns]`. This is [CITED: D-14] |
| A3 | `table._grid_layout` is populated before the writer's table render branch is called | Research §4 | Measure populates `_grid_layout` (measure.ex:278); Paginate runs after Measure; writer runs after Paginate. Pipeline order is Build→Compose→Measure→Paginate→Render [VERIFIED: pipeline_test.exs run order] |
| A4 | Adding `Rendro.path/2` to the top-level `Rendro` module requires a new `@spec` to pass the stable-tier spec coverage test (`public_api_contract_test.exs` Assertion 5) | Research §7 | The test explicitly checks stable-tier functions for `@spec` — `Rendro` is stable tier. This is [VERIFIED: test/docs_contract/public_api_contract_test.exs:209-239] |

**If this table is empty:** N/A — 4 low-risk assumptions documented above.

---

## Open Questions (RESOLVED)

1. **Does `apply_page_template` handle `anchor: :fixed` identity with a `region_suppress_on` check?**
   - What we know: `apply_page_template` uses `region_suppress_on = Map.get(layout, :region_suppress_on, %{})` to optionally suppress region content on specific pages.
   - What's unclear: Whether a `:frame` region with no suppression config will behave correctly on all pages of a multi-page document (unlikely for certificates, which are single-page, but important for correctness).
   - Recommendation: For Certificate, use a single-page layout — no multi-page concern. The frame region will appear on every page if the certificate ever becomes multi-page, which is desirable.

2. **`table_decoration` positioning relative to `block.x`/`block.y` after `stack_table_cells`**
   - What we know: `stack_table_cells` (paginate.ex:104) sets absolute cell positions within the table block; the table block itself has `block.x` and `block.y` set by `anchor_region_blocks`. The writer's table render clause dispatches cells but doesn't currently compute block position for decoration.
   - What's unclear: Whether `table_decoration` needs access to the outer `block` struct (to get the block's `{x, y}` for the Y-flip origin) in addition to `table` and `page`.
   - Recommendation: Yes — `table_decoration` needs `block` for the same Y-flip formula used for Image/Path. The render_block clause signature passes `block` so it's available.

---

## Environment Availability

Step 2.6: SKIPPED — phase is pure Elixir/PDF code and configuration changes; no external tools, databases, or CLIs are required beyond the existing project toolchain (`mix`, `elixir`).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (standard; no new dep) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/rendro/path_test.exs test/rendro/table_borders_test.exs test/rendro/recipes/certificate_test.exs -x` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PATH-01 | `%Rendro.Path{}` renders `:rect` op to PDF `re\nS` ops | unit | `mix test test/rendro/path_test.exs::P01a -x` | ❌ Wave 0 |
| PATH-01 | Two renders of same Path doc are byte-identical | determinism | `mix test test/rendro/path_test.exs::P01b -x` | ❌ Wave 0 |
| PATH-01 | Path ops use `format_num` precision (4 decimal places max) | unit | `mix test test/rendro/path_test.exs::P01c -x` | ❌ Wave 0 |
| PATH-01 | `{:rounded_rect, x, y, w, h, r}` decomposes to `c` ops with kappa `0.5522847498` | unit | `mix test test/rendro/path_test.exs::P01d -x` | ❌ Wave 0 |
| PATH-01 | Stroke-only path produces `S`; fill-only produces `f`; both produces `B`; neither produces `n` | unit | `mix test test/rendro/path_test.exs::P01e -x` | ❌ Wave 0 |
| PATH-01 | D-03 retrofit: Text writer still produces byte-identical black-text output after `Rendro.Color` refactor | regression | `mix test test/rendro/deterministic_test.exs -x` | ✅ (existing test extended) |
| PATH-01 | `Rendro.Color.validate/1` raises `ArgumentError` with hex-footgun message on non-tuple input | unit | `mix test test/rendro/path_test.exs::P01f -x` | ❌ Wave 0 |
| PATH-02 | `borders: :all` table renders `re` + `S` ops in PDF content stream | unit | `mix test test/rendro/table_borders_test.exs::P02a -x` | ❌ Wave 0 |
| PATH-02 | Table with no `borders` field produces output byte-identical to pre-Phase-84 baseline | regression | `mix test test/rendro/table_borders_test.exs::P02b -x` | ❌ Wave 0 |
| PATH-02 | `borders: false` (D-20 parity) → same byte-identity | regression | `mix test test/rendro/table_borders_test.exs::P02c -x` | ❌ Wave 0 |
| PATH-02 | `[:outer, :rows]` emits perimeter + horizontal rules only (no vertical) | unit | `mix test test/rendro/table_borders_test.exs::P02d -x` | ❌ Wave 0 |
| PATH-02 | Draw-once: no doubled line segments at shared cell boundaries | unit | `mix test test/rendro/table_borders_test.exs::P02e -x` | ❌ Wave 0 |
| PATH-02 | `header_fill: {r,g,b}` emits `rg … re … f` ops for header band | unit | `mix test test/rendro/table_borders_test.exs::P02f -x` | ❌ Wave 0 |
| PATH-03 | Certificate `border: true` renders `re\nS` in PDF content stream | unit | `mix test test/rendro/recipes/certificate_test.exs::C15 -x` | ❌ Wave 0 |
| PATH-03 | Certificate `border: false` (default) output byte-identical to prior baseline | regression | `mix test test/rendro/recipes/certificate_test.exs::C16 -x` | ❌ Wave 0 |
| PATH-03 | Frame coords differ between A4-landscape and US-Letter-landscape (geometry-derived proof) | unit | `mix test test/rendro/recipes/certificate_test.exs::C17 -x` | ❌ Wave 0 |
| PATH-03 | Frame inset formula: `inset = 0.5 * min(ml, mr, mt, mb)` ≠ hardcoded | unit | `mix test test/rendro/recipes/certificate_test.exs::C18 -x` | ❌ Wave 0 |
| PATH-03 | `border: %{color: {255, 0, 0}}` overrides default and appears in content stream | unit | `mix test test/rendro/recipes/certificate_test.exs::C19 -x` | ❌ Wave 0 |
| PATH-03 | `validate_border!` rejects unknown keys, invalid color, `inset >= min_margin` | unit | `mix test test/rendro/recipes/certificate_test.exs::C20 -x` | ❌ Wave 0 |
| PATH-04 | `priv/support_matrix.json` has `path_primitive` section with `transforms_cm`, `clipping_W`, `gradients` as `explicit_deferral` | docs-contract | `mix test test/docs_contract/path_claims_test.exs -x` | ❌ Wave 0 |
| PATH-04 | `priv/public_api.json` contains `Rendro.Path` and `Rendro.path/2` in manifest | docs-contract | `mix test test/docs_contract/public_api_contract_test.exs -x` | ✅ (existing test; fails until manifest updated) |

**Key regression guards (must stay green throughout implementation):**
- `mix test test/rendro/deterministic_test.exs` — Property-based byte-identity for all existing doc types. Must stay green throughout (D-03 retrofit must not change existing Text output bytes).
- `mix test test/rendro/recipes/certificate_test.exs` — All 14 existing C1–C14 tests must stay green (border feature is additive-only).
- `mix test test/docs_contract/public_api_contract_test.exs` — Manifest drift detection. Will go red when `Rendro.Path` is added to code but manifest not regenerated; goes green again after `mix rendro.api.gen`.

### Sampling Rate
- **Per task commit:** `mix test test/rendro/path_test.exs test/rendro/table_borders_test.exs test/rendro/recipes/certificate_test.exs test/rendro/deterministic_test.exs -x`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/rendro/path_test.exs` — covers PATH-01 (P01a through P01f)
- [ ] `test/rendro/table_borders_test.exs` — covers PATH-02 (P02a through P02f)
- [ ] New test cases C15–C20 in `test/rendro/recipes/certificate_test.exs` — covers PATH-03
- [ ] `test/docs_contract/path_claims_test.exs` — covers PATH-04 support-matrix lane
- [ ] Lane entry in `scripts/verify_docs.exs` — self-registration for the path claims lane

---

## Security Domain

`security_enforcement` is not set to `false` in `.planning/config.json`. However, this phase introduces no authentication, session management, cryptographic operations, file upload handling, or external data intake surfaces. All inputs are Elixir structs constructed in-process by the caller (a Phoenix engineer building a document). The relevant ASVS consideration is:

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | Yes (limited) | `Rendro.Color.validate/1` rejects non-`{r,g,b}` tuples; `validate_border!` rejects out-of-range numerics. `ArgumentError` with What/Where/Why/Next messages (errors-as-product) |
| V6 Cryptography | No | — |

No new threat surface introduced. Input validation is developer-facing (struct construction time), not a web-boundary surface.

---

## Sources

### Primary (HIGH confidence — direct codebase inspection)
- `lib/rendro/pdf/writer.ex:511–577` — render_block dispatch structure [VERIFIED: direct inspection]
- `lib/rendro/pdf/writer.ex:621–633` — Image Y-flip + q/cm/Do/Q pattern [VERIFIED: direct inspection]
- `lib/rendro/pdf/writer.ex:1283–1340` — form-field appearance stream: re/S/f/RG/rg/w/q/Q operators [VERIFIED: direct inspection]
- `lib/rendro/pdf/writer.ex:1419–1483` — circle_path kappa 0.5522847498 [VERIFIED: direct inspection]
- `lib/rendro/pdf/writer.ex:1758–1762` — format_num/1 implementation [VERIFIED: direct inspection]
- `lib/rendro/pipeline/measure.ex:101–141` — Image measure_block clause + catch-all [VERIFIED: direct inspection]
- `lib/rendro/pipeline/measure.ex:278–285` — _grid_layout 2-D list structure [VERIFIED: direct inspection]
- `lib/rendro/pipeline/paginate.ex:104–141` — stack_table_cells absolute cell positioning [VERIFIED: direct inspection]
- `lib/rendro/pipeline/paginate.ex:402–422` — apply_page_template anchored_blocks prepend [VERIFIED: direct inspection]
- `lib/rendro/pipeline/paginate.ex:515–532` — anchor_region_blocks absolute x/y assignment [VERIFIED: direct inspection]
- `lib/rendro/recipes/certificate.ex` — page_template/sections/document three-rung pattern; validate_data! idiom [VERIFIED: direct inspection]
- `lib/rendro/page_size.ex` — PageSize.resolve/2 with A4/US-Letter values [VERIFIED: direct inspection]
- `lib/rendro/table.ex` — existing Table struct fields [VERIFIED: direct inspection]
- `lib/rendro/region.ex` — anchor: :fixed is a valid Region.anchor() [VERIFIED: direct inspection]
- `lib/mix/tasks/rendro/api.gen.ex` — @public_modules list; mix rendro.api.gen introspection mechanism [VERIFIED: direct inspection]
- `priv/schemas/support_matrix.schema.json` — viewer_row schema; additionalProperties: true at top level [VERIFIED: direct inspection]
- `test/rendro/deterministic_test.exs` — byte-identity test patterns [VERIFIED: direct inspection]
- `test/rendro/recipes/certificate_test.exs` — C1–C14 test patterns; C11 multi-size determinism [VERIFIED: direct inspection]
- `test/docs_contract/script_support_claims_test.exs` — support-matrix lane pattern [VERIFIED: direct inspection]
- `test/docs_contract/api_stability_claims_test.exs:104–109` — lane self-registration pattern [VERIFIED: direct inspection]
- `test/docs_contract/public_api_contract_test.exs` — manifest drift detection; stable-tier @spec coverage [VERIFIED: direct inspection]

### Secondary (MEDIUM confidence)
- PDF specification: `re`, `m`, `l`, `c`, `S`, `f`, `B`, `n`, `h`, `w`, `J`, `j`, `d`, `RG`, `rg`, `q`, `Q`, `cm` operators — well-established PDF 1.4 operator semantics. These operators are already used correctly in the existing codebase, confirming their semantics. [CITED: existing writer.ex usage as evidence]
- Kappa value `0.5522847498` for Bézier circle approximation — standard value (also documented in numerous PDF/graphics references). [CITED: writer.ex:1423 existing usage]

### Tertiary (LOW confidence — training knowledge, not verified in this session)
- `borders: :all` terminology alignment with D-14's "outer+grid" definition — sourced from D-14 lock (CONTEXT.md), which is authoritative. Not LOW confidence.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; all operators present in codebase
- Architecture: HIGH — all patterns verified from direct codebase inspection
- Pitfalls: HIGH — traced from direct code analysis and D-15/D-16 locked decisions
- Test map: HIGH — patterns verified from existing test files; new test names are discretionary

**Research date:** 2026-06-10
**Valid until:** 2026-07-10 (stable codebase; no fast-moving dependencies)

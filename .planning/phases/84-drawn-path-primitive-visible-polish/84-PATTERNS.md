# Phase 84: Drawn-Path Primitive & Visible Polish - Pattern Map

**Mapped:** 2026-06-10
**Files analyzed:** 12 new/modified files
**Analogs found:** 12 / 12

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/color.ex` | utility | transform | `lib/rendro/pdf/writer.ex:638-639` (inline) + `lib/rendro/page_size.ex` (@moduledoc false) | exact |
| `lib/rendro/path.ex` | model | CRUD | `lib/rendro/image.ex` + `lib/rendro/text.ex` | exact |
| `lib/rendro/pdf/writer.ex` (new clauses) | service | request-response | `lib/rendro/pdf/writer.ex:610-633` (Image clause) + `lib/rendro/pdf/writer.ex:1283-1340` (form-field ops) | exact |
| `lib/rendro/pipeline/measure.ex` (new clause) | service | transform | `lib/rendro/pipeline/measure.ex:101-141` (Image clause) | exact |
| `lib/rendro/pipeline/paginate.ex` (frame prepend) | service | request-response | `lib/rendro/pipeline/paginate.ex:402-422` (apply_page_template) | exact |
| `lib/rendro/table.ex` (new fields) | model | CRUD | `lib/rendro/table.ex:1-38` (existing struct) | exact |
| `lib/rendro/cell.ex` (no change needed) | model | CRUD | `lib/rendro/cell.ex:1-38` | exact |
| `lib/rendro.ex` (table/2 + path/2 builders) | controller | request-response | `lib/rendro.ex:234-240` (text/2) + `lib/rendro.ex:346-359` (normalize_table_attrs) | exact |
| `lib/rendro/recipes/certificate.ex` (border: option) | service | request-response | `lib/rendro/recipes/certificate.ex:68-167` (page_template/sections/document) + `lib/rendro/recipes/branded_invoice.ex:49-80` (brand map idiom) | exact |
| `priv/support_matrix.json` (path rows) | config | CRUD | `priv/support_matrix.json` (text_shaping section) | exact |
| `lib/mix/tasks/rendro/api.gen.ex` (@public_modules) | config | CRUD | `lib/mix/tasks/rendro/api.gen.ex:43-98` (@public_modules list) | exact |
| `test/rendro/path_test.exs` (new) | test | request-response | `test/rendro/deterministic_test.exs:14-78` | exact |
| `test/rendro/table_borders_test.exs` (new) | test | request-response | `test/rendro/deterministic_test.exs:14-78` + `test/rendro/recipes/certificate_test.exs:29-41` | exact |
| `test/rendro/recipes/certificate_test.exs` (C15-C20) | test | request-response | `test/rendro/recipes/certificate_test.exs:188-218` (C11-C12 patterns) | exact |
| `test/docs_contract/path_claims_test.exs` (new) | test | request-response | `test/docs_contract/script_support_claims_test.exs` | exact |

---

## Pattern Assignments

---

### `lib/rendro/color.ex` (utility, transform)

**Analog 1 — `@moduledoc false` module structure:** `lib/rendro/page_size.ex:1-20`

```elixir
defmodule Rendro.PageSize do
  @moduledoc false

  @a4_portrait {595.28, 841.89}
  @us_letter_portrait {612.0, 792.0}

  @spec resolve(atom() | {number(), number()}, :portrait | :landscape) ::
          {number(), number()}
  def resolve(size, orientation \\ :portrait)
  ...
end
```

**Analog 2 — inline color lowering being replaced:** `lib/rendro/pdf/writer.ex:635-639`

```elixir
defp render_text_block(block, page, ox, oy, text, lines, line_height, font_map) do
  x = block.x + ox + page.margin_left
  y = page.height - (block.y + oy) - page.margin_top - text.size
  {r, g, b} = text.color
  color_op = "#{format_num(r / 255)} #{format_num(g / 255)} #{format_num(b / 255)} rg"
```

**Analog 3 — `format_num/1` to copy:** `lib/rendro/pdf/writer.ex:1758-1762`

```elixir
defp format_num(n) when is_integer(n), do: Integer.to_string(n)

defp format_num(n) when is_float(n) do
  :erlang.float_to_binary(n * 1.0, decimals: 4)
end
```

**Pattern to implement:** `Rendro.Color` must be `@moduledoc false` (excluded from `priv/public_api.json`), define a private `format_num/1` identical to the writer's, and expose:
- `rg({r,g,b})` — returns `"R G B rg\n"` string  
- `rg_stroke({r,g,b})` — returns `"R G B RG\n"` string  
- `to_pdf_components({r,g,b})` — returns `{r/255, g/255, b/255}`  
- `validate({r,g,b})` — `:ok` or `{:error, reason}` with hex-footgun message (D-04)

---

### `lib/rendro/path.ex` (model, CRUD)

**Analog — `lib/rendro/image.ex:1-17` (inert declarative struct, `@enforce_keys`, `@moduledoc tags: [:stable]`):**

```elixir
defmodule Rendro.Image do
  @moduledoc """
  AST representation of a registered image asset to be rendered.
  """
  @moduledoc tags: [:stable]

  @enforce_keys [:logical_name]
  defstruct [
    :logical_name,
    :fit
  ]

  @type t :: %__MODULE__{
          logical_name: atom(),
          fit: {number(), number()} | nil
        }
end
```

**Supplementary analog for color field type — `lib/rendro/text.ex:19,33` (`{r,g,b}` 0-255 type):**

```elixir
defstruct [
  :content,
  font: "Helvetica",
  size: 12,
  color: {0, 0, 0},    # ← the canonical color type: {r, g, b} 0–255
  ...
]

@type t :: %__MODULE__{
        ...
        color: {non_neg_integer(), non_neg_integer(), non_neg_integer()},
        ...
      }
```

**Pattern to implement:** `Rendro.Path` copies Image's `@moduledoc tags: [:stable]` and `@enforce_keys` idiom. The struct shape per D-12:

```elixir
@enforce_keys [:ops]
defstruct [:ops, fill: nil, stroke: nil]
```

`@type t` must type the `{r,g,b}` color fields using the same `{non_neg_integer(), non_neg_integer(), non_neg_integer()}` convention from `text.ex:33`.

---

### `lib/rendro/pdf/writer.ex` — new `%Rendro.Path{}` render clause (service, request-response)

**Analog A — Image dispatch shim (5-arity → 7-arity):** `lib/rendro/pdf/writer.ex:567-575`

```elixir
defp render_block(
       doc,
       %Rendro.Block{content: %Rendro.Image{}} = block,
       page,
       font_map,
       image_map
     ) do
  render_block(doc, block, page, font_map, image_map, 0, 0)
end
```

**Analog B — Image Y-flip + `q…cm…Q`:** `lib/rendro/pdf/writer.ex:610-633`

```elixir
defp render_block(
       _doc,
       %Rendro.Block{content: %Rendro.Image{} = image} = block,
       page,
       _font_map,
       image_map,
       ox,
       oy
     ) do
  case Map.fetch(image_map, image.logical_name) do
    {:ok, _allocation} ->
      x = block.x + ox + page.margin_left
      y = page.height - (block.y + oy + block.height) - page.margin_top
      w = block.width
      h = block.height

      img_name = image_resource_name(image.logical_name)

      "q\n#{format_num(w)} 0 0 #{format_num(h)} #{format_num(x)} #{format_num(y)} cm\n/#{img_name} Do\nQ"

    :error ->
      ""
  end
end
```

**Key difference for Path:** `cm` is a translation-only matrix (`1 0 0 1 tx ty`), not a scale matrix. The Path clause (no `ox`/`oy`, no `image_map` lookup) uses:

```
x = block.x + page.margin_left
y = page.height - (block.y + block.height) - page.margin_top
```

Then emits `"q\n1 0 0 1 #{format_num(x)} #{format_num(y)} cm\n"` followed by gstate ops, path construction ops (each op's `y' = block.height - y_author`), paint op, `"Q"`.

**Analog C — form-field PDF operators (re/S/f/RG/rg/w/m/l/c/q/Q template):** `lib/rendro/pdf/writer.ex:1282-1310`

```elixir
[
  "q\n",
  "1 1 1 rg\n",
  "0 0 ",
  format_num(width),
  " ",
  format_num(height),
  " re\nf\n",
  "0 0 0 RG\n",
  "0 0 ",
  format_num(width),
  " ",
  format_num(height),
  " re\nS\n",
  ...
  "Q"
]
|> IO.iodata_to_binary()
```

This is the iodata assembly pattern to replicate for Path ops. Note: use `IO.iodata_to_binary/1` (not string concatenation) per the established pattern.

**Analog D — `circle_path/3` kappa for `:rounded_rect` decomposition:** `lib/rendro/pdf/writer.ex:1419-1483`

```elixir
defp circle_path(width, height, inset) do
  radius = max(min(width, height) / 2.0 - inset, 1.0)
  center_x = width / 2.0
  center_y = height / 2.0
  control = radius * 0.5522847498   # ← kappa constant to reuse
  left = center_x - radius
  right = center_x + radius
  top = center_y + radius
  bottom = center_y - radius

  [
    format_num(center_x),
    " ",
    format_num(top),
    " m\n",
    format_num(center_x + control),
    " ",
    format_num(top),
    " ",
    format_num(right),
    " ",
    format_num(center_y + control),
    " ",
    format_num(right),
    " ",
    format_num(center_y),
    " c\n",
    ...
  ]
end
```

The kappa `0.5522847498` is the single audited constant in the codebase. `:rounded_rect` decomposition reuses `control = radius * 0.5522847498` for all four corner arcs. Each arc has 3 PDF `c` arguments (x1 y1 x2 y2 x3 y3), all run through `format_num` and all `y` values Y-flipped via `block_h - y_author`.

**Analog E — `table_decoration` guard pattern (for table border dispatch):** `lib/rendro/pdf/writer.ex:511-535`

The existing Table `render_block` clause (lines 511-535) emits only cell content. The new table-decoration branch must be **prepended** with an early-exit guard (D-15: no stray newline when inert):

```elixir
# Writer table render_block (lines 511-535) — existing, shows structure
defp render_block(
       doc,
       %Rendro.Block{content: %Rendro.Table{} = table},
       page,
       font_map,
       image_map
     ) do
  header_ops = ...
  rows_ops = ...
  [header_ops | rows_ops] |> List.flatten() |> Enum.join("\n")
end
```

The planner's action must modify this clause to prepend decoration: `if decoration == "", do: cells_content, else: decoration <> "\n" <> cells_content`.

---

### `lib/rendro/pipeline/measure.ex` — new `%Rendro.Path{}` measure clause (service, transform)

**Analog — Image measure clause:** `lib/rendro/pipeline/measure.ex:101-141`

```elixir
defp measure_block(
       doc,
       %Rendro.Block{content: %Rendro.Image{} = image} = block,
       _container_width
     ) do
  with {:ok, %{width: intrinsic_w, height: intrinsic_h}} <-
         Rendro.AssetRegistry.fetch(doc.asset_registry, image.logical_name) do
    aspect_ratio = intrinsic_w / intrinsic_h

    {width, height} =
      case {block.width, block.height, image.fit} do
        {nil, nil, {fit_w, fit_h}} ->
          fit_aspect = fit_w / fit_h

          if aspect_ratio > fit_aspect do
            {fit_w, fit_w / aspect_ratio}
          else
            {fit_h * aspect_ratio, fit_h}
          end

        {w, nil, nil} when not is_nil(w) ->
          {w, w / aspect_ratio}

        {nil, h, nil} when not is_nil(h) ->
          {h * aspect_ratio, h}

        {w, h, nil} when not is_nil(w) and not is_nil(h) ->
          {w, h}

        _ ->
          {intrinsic_w, intrinsic_h}
      end

    {:ok, %{block | width: width, height: height}}
  else
    :error ->
      {:error, {:missing_asset, image.logical_name}}
  end
end

defp measure_block(_doc, block, _container_width), do: {:ok, block}  # ← catch-all at line 141
```

**Critical:** The Path clause MUST be inserted BEFORE the catch-all at line 141. Pattern match structure for Path:

```elixir
defp measure_block(
       _doc,
       %Rendro.Block{content: %Rendro.Path{} = path} = block,
       _container_width
     ) do
  {width, height} =
    case {block.width, block.height} do
      {w, h} when not is_nil(w) and not is_nil(h) -> {w, h}
      {w, nil} when not is_nil(w) -> {w, compute_ops_height(path.ops)}
      {nil, h} when not is_nil(h) -> {compute_ops_width(path.ops), h}
      {nil, nil} -> {compute_ops_width(path.ops), compute_ops_height(path.ops)}
    end
  {:ok, %{block | width: width, height: height}}
end
```

`compute_ops_extent` helpers fold the ops list, using `max_x`/`max_y` accumulation. For `{:curve, x1,y1,x2,y2,x3,y3}` use conservative bound `{max(x1,x2,x3), max(y1,y2,y3)}`; for `{:rect, x,y,w,h}` use `{x+w, y+h}`; for `{:rounded_rect, x,y,w,h,_r}` use `{x+w, y+h}` (radius doesn't extend beyond w/h).

**`_grid_layout` shape for table decoration (also in measure.ex):** `lib/rendro/pipeline/measure.ex:278-285`

```elixir
grid_layout =
  for r <- 0..(length(rows) - 1)//1 do
    for c <- 0..(col_count - 1)//1 do
      Map.get(grid_map, {r, c}, %{is_continuation: false, cell: nil})
    end
  end
```

Each `grid_layout[r][c]` map carries `%{is_continuation:, cell:, ref_r:, ref_c:}`. To detect a colspan at `{r,c}`: `grid_layout[r][c].ref_c != c`. To detect a rowspan: `grid_layout[r][c].ref_r != r`.

---

### `lib/rendro/pipeline/paginate.ex` — Certificate `:frame` region prepend (service, request-response)

**Analog — `apply_page_template/4`:** `lib/rendro/pipeline/paginate.ex:402-422`

```elixir
defp apply_page_template(%Page{} = page, idx, layout, total) do
  region_suppress_on = Map.get(layout, :region_suppress_on, %{})

  anchored_blocks =
    layout.template.regions
    |> Enum.reject(&(&1.name == :body))
    |> Enum.flat_map(fn region ->
      suppress_on = Map.get(region_suppress_on, region.name)

      anchored_region_blocks =
        layout.region_blocks
        |> Map.get(region.name, [])
        |> apply_suppression(suppress_on, idx)
        |> evaluate_fn_blocks(idx, total)
        |> replace_page_numbers(idx, total)
        |> anchor_region_blocks(region, page)

      maybe_validate_region_fit(anchored_region_blocks, region, page, idx, region.name)
    end)

  %{page | blocks: anchored_blocks ++ page.blocks}   # ← PREPEND: anchored first = painted under body
end
```

**Analog — `anchor_region_blocks/3`:** `lib/rendro/pipeline/paginate.ex:515-532`

```elixir
defp anchor_region_blocks(blocks, %Region{} = region, %Page{} = page) do
  start_x = relative_x(region, page)
  start_y = relative_y(region, page)

  {anchored, _} =
    Enum.reduce(blocks, {[], start_y}, fn block, {acc, current_y} ->
      anchored_block =
        block
        |> Map.put(:x, start_x + block.x)
        |> Map.put(:y, current_y)
        |> stack_table_cells()

      next_y = current_y + (block.height || 0)
      {acc ++ [anchored_block], next_y}
    end)

  anchored
end
```

**Pattern for Certificate `:frame` region:** No changes to paginate.ex are needed — the existing `apply_page_template` mechanism handles any `anchor: :fixed` region. The Certificate recipe's `page_template/1` function adds the `:frame` region to the template's `regions:` list, and `sections/2` adds a `:certificate_frame` section targeting `:frame`. The paginate pipeline then prepends the frame block automatically.

**Analog for `anchor: :fixed` region — `lib/rendro/recipes/branded_invoice.ex:53-63`:**

```elixir
Rendro.region(
  name: :logo,
  role: :custom,
  anchor: :fixed,
  x: 72,
  y: 72,
  width: 64,
  height: 64
)
```

This is the exact `anchor: :fixed` pattern the Certificate `:frame` region uses — same field names, same struct idiom.

---

### `lib/rendro/table.ex` — new flat fields (model, CRUD)

**Analog — existing `%Rendro.Table{}` struct:** `lib/rendro/table.ex:1-38`

```elixir
defmodule Rendro.Table do
  @moduledoc """
  Table primitive for structured data.
  """
  @moduledoc tags: [:stable]

  @enforce_keys [:rows]
  defstruct [
    :rows,
    header: nil,
    columns: nil,
    split_policy: :row_atomic,
    repeat_header: true,
    decoration_break: :slice,
    # Pipeline geometry fields populated by Measure
    column_widths: nil,
    row_heights: nil,
    header_height: nil,
    _grid_layout: nil
  ]

  @type row :: [Rendro.Block.t() | String.t()] | Rendro.Row.t()
  @type column_rule :: {:fixed, number()} | {:share, number()}
  @type split_policy :: :row_atomic | :atomic | :fragment
  @type decoration_break :: :slice | :clone
  @type t :: %__MODULE__{
          rows: [row()],
          ...
          _grid_layout: list(list(map())) | nil
        }
end
```

**Pattern:** Append three flat fields after `decoration_break:` with inert defaults:

```elixir
borders: :none,
border_style: nil,
header_fill: nil,
```

Add corresponding type entries in `@type t`. All three fields have inert defaults — existing test output remains byte-identical (D-15).

---

### `lib/rendro.ex` — `table/2` normalize hook + `path/2` builder (controller, request-response)

**Analog A — `text/2` builder:** `lib/rendro.ex:234-240`

```elixir
@spec text(String.t(), keyword()) :: Text.t()
def text(content, attrs \\ []) do
  attrs
  |> normalize_text_attrs()
  |> Keyword.put(:content, content)
  |> then(&struct!(Text, &1))
end
```

**Pattern for `path/2`:** Mirror `text/2` exactly — normalize attrs (validate color tuples via `Rendro.Color.validate/1`), set `:ops`, return `%Block{content: %Path{}}` (since `path/2` is the flow-element builder, it wraps in a block like other builders):

```elixir
@spec path([term()], keyword()) :: Block.t()
def path(ops, attrs \\ []) do
  attrs
  |> normalize_path_attrs()
  |> Keyword.put(:ops, ops)
  |> then(&struct!(Path, &1))
  |> then(&struct!(Block, content: &1))
end
```

**Analog B — `normalize_table_attrs/1` with validation:** `lib/rendro.ex:346-359`

```elixir
defp normalize_table_attrs(attrs) do
  case Keyword.get(attrs, :split_policy, :row_atomic) do
    :row_atomic ->
      Keyword.put(attrs, :split_policy, :row_atomic)

    :atomic ->
      Keyword.put(attrs, :split_policy, :row_atomic)

    split_policy ->
      raise ArgumentError,
            "Rendro.table/2 only supports split_policy: :row_atomic" <>
              " (or temporary alias :atomic); got: #{inspect(split_policy)}"
  end
end
```

**Pattern:** Extend `normalize_table_attrs/1` to also normalize `borders:` — canonicalize the borders set-list (sort atoms, deduplicate, expand `:all → [:outer, :rows, :columns]`, `:grid → [:rows, :columns]`) and validate `border_style` / `header_fill` color tuples via `Rendro.Color.validate/1`. The `:width` / `:border` guard at lines 303-306 is an existing example of `raise ArgumentError` for unsupported attrs.

---

### `lib/rendro/recipes/certificate.ex` — `border:` option (service, request-response)

**Analog A — `brand:` true/map idiom in `document/2`:** `lib/rendro/recipes/certificate.ex:148-161`

```elixir
base_doc =
  if brand = Map.get(data, :brand) do
    base_doc
    |> Rendro.Document.register_embedded_font(
      brand.font_name,
      {:path, Rendro.Branded.font_path()}
    )
    |> Rendro.Document.register_image(
      brand.logo_name,
      {:path, Rendro.Branded.logo_path()}
    )
  else
    base_doc
  end
```

**Pattern for `border:`:** The same `if opts[:border]` guard controls whether the `:frame` region and `:certificate_frame` section are added. `true` ≡ `%{}` (use all defaults), a map merges over defaults. When `border` is falsy (`false` or absent), NO region is added — byte-identical output.

**Analog B — `validate_data!` ArgumentError What/Where/Why/Next pattern:** `lib/rendro/recipes/certificate.ex:197-279`

```elixir
defp validate_data!(data) do
  required = [:title, :recipient, :date]

  missing =
    Enum.reject(required, fn key ->
      case Map.fetch(data, key) do
        {:ok, val} when not is_nil(val) -> true
        _ -> false
      end
    end)

  unless missing == [] do
    raise ArgumentError, """
    Rendro.Recipes.Certificate.document/2 — missing required key(s) in data.

    What:  Required certificate data keys are missing.
    Where: Rendro.Recipes.Certificate.validate_data!/1
    Why:   Missing key(s): #{inspect(missing)}.
    Next:  Provide all required keys: #{Enum.map_join(required, ", ", &inspect/1)}.
    """
  end
  ...
end
```

**Pattern for `validate_border!/2`:** Use the identical `raise ArgumentError, """..."""` format with What/Where/Why/Next. The closed allowlist check (D-21): `[:style, :color, :inset, :gap, :weight]`. Color validation delegates to `Rendro.Color.validate/1` — one canonical hex-footgun error message library-wide.

**Analog C — geometry derivation in `page_template/1`:** `lib/rendro/recipes/certificate.ex:69-102`

```elixir
def page_template(opts \\ []) do
  page_size = Keyword.get(opts, :page_size, @default_page_size)
  orientation = Keyword.get(opts, :orientation, @default_orientation)
  {pw, ph} = Rendro.PageSize.resolve(page_size, orientation)

  ml = Keyword.get(opts, :margin_left, @default_margin)
  mr = Keyword.get(opts, :margin_right, @default_margin)
  mt = Keyword.get(opts, :margin_top, @default_margin)
  mb = Keyword.get(opts, :margin_bottom, @default_margin)

  content_w = pw - ml - mr
  content_h = ph - mt - mb

  Rendro.page_template(
    name: Keyword.get(opts, :name, :certificate),
    width: pw,
    height: ph,
    margin_top: mt,
    ...
    regions: [
      Rendro.region(name: :body, role: :body, anchor: :flow, x: ml, y: mt, ...)
    ]
  )
end
```

**Pattern:** When `border:` is truthy, add the `:frame` region to the `regions:` list using the same `{pw, ph}`, `ml/mr/mt/mb` locals already computed:

```elixir
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

---

### `priv/support_matrix.json` — path surface rows (config, CRUD)

**Analog — `text_shaping` section structure** (visible from the schema and `script_support_claims_test.exs`):

```json
"text_shaping": {
  ...
  "arabic": {
    "status": "explicit_deferral",
    "evidence_deferred": "..."
  },
  ...
}
```

**Pattern:** Add a top-level `"path_primitive"` key (the schema has `additionalProperties: true` at top level). Structure with `"capabilities"`, `"behaviors"`, and `"explicit_deferrals"` sub-objects. Deferral entries use `{"status": "explicit_deferral", "evidence_deferred": "..."}` with `evidence_deferred` at least 40 characters (schema: `minLength: 40`).

---

### `lib/mix/tasks/rendro/api.gen.ex` — `@public_modules` update (config, CRUD)

**Analog — existing `@public_modules` list:** `lib/mix/tasks/rendro/api.gen.ex:43-98`

```elixir
@public_modules [
  # Stable tier — core document model and facades
  Rendro,
  Rendro.Artifact,
  ...
  Rendro.Image,    # ← insert Rendro.Path after this line
  ...
  Rendro.Table,
  Rendro.Text,
  ...
]
```

**Pattern:** Add `Rendro.Path` to the stable tier list (alphabetical order between `Rendro.Page` and `Rendro.PageTemplate`). Do NOT add `Rendro.Color` (it is `@moduledoc false` and intentionally excluded per D-02).

---

### `test/rendro/path_test.exs` (new test, request-response)

**Analog — `test/rendro/deterministic_test.exs:14-40` (Approach A and B patterns):**

```elixir
describe "property: deterministic byte-identity" do
  property "two deterministic renders of the same document produce identical binaries" do
    check all(doc <- renderable_document_gen(), max_runs: 100) do
      {:ok, pdf1} = Rendro.render(doc, deterministic: true)
      {:ok, pdf2} = Rendro.render(doc, deterministic: true)
      assert pdf1 == pdf2
    end
  end
end
```

**Content-stream assertion pattern (Approach B):**

```elixir
{:ok, pdf} = Rendro.render(doc, deterministic: true)
assert pdf =~ "/Subtype /Link"      # PDF binary content scan
assert pdf =~ "(Linked body) Tj"
```

**Pattern for path tests:**
- P01a: `assert pdf =~ "re\nS"` (rect + stroke-only paint op)
- P01b: two-render byte-identity (Approach A)
- P01c: `assert pdf =~ "0.0000"` or `refute pdf =~ "1.0e"` (format_num precision, 4 decimals max)
- P01d: `assert pdf =~ "0.5523"` (kappa in content stream for rounded_rect)
- P01e: stroke-only → `assert pdf =~ "S\n"`, fill-only → `assert pdf =~ "f\n"`, both → `assert pdf =~ "B\n"`, neither → `assert pdf =~ "n\n"`
- P01f: `assert_raise ArgumentError, ~r/hex/i, fn -> Rendro.Color.validate("#000") end`

---

### `test/rendro/table_borders_test.exs` (new test, request-response)

**Analog — Certificate test describe structure:** `test/rendro/recipes/certificate_test.exs:29-41`

```elixir
describe "C1: document/2 basic render" do
  test "returns a Rendro.Document struct" do
    assert %Rendro.Document{} = Certificate.document(fixture_data())
  end

  test "Rendro.render returns {:ok, pdf} binary starting with %PDF-" do
    doc = Certificate.document(fixture_data())
    assert {:ok, pdf} = Rendro.render(doc)
    assert is_binary(pdf)
    assert String.starts_with?(pdf, "%PDF-")
  end
end
```

**Pattern:** Same `describe "P02x: ..."` structure with fixture helper (`simple_table/1`, `bordered_table/1`). Each describe block covers one behavior from the test map.

---

### `test/rendro/recipes/certificate_test.exs` — C15-C20 (test, request-response)

**Analog — C11 determinism test:** `test/rendro/recipes/certificate_test.exs:188-195`

```elixir
describe "C11: deterministic byte-identical render" do
  test "renders same certificate twice with deterministic: true -> byte-identical" do
    doc = Certificate.document(fixture_data())
    {:ok, pdf1} = Rendro.render(doc, deterministic: true)
    {:ok, pdf2} = Rendro.render(doc, deterministic: true)
    assert pdf1 == pdf2
  end
end
```

**Analog — C5 geometry-derived difference proof:** `test/rendro/recipes/certificate_test.exs:102-112`

```elixir
describe "C5: body width differs between page sizes" do
  test "A4-landscape body width != US-Letter-landscape body width" do
    t_a4 = Certificate.page_template(page_size: :a4, orientation: :landscape)
    t_us = Certificate.page_template(page_size: :us_letter, orientation: :landscape)
    body_a4 = Enum.find(t_a4.regions, &(&1.role == :body))
    body_us = Enum.find(t_us.regions, &(&1.role == :body))
    refute_in_delta body_a4.width, body_us.width, 0.01
  end
end
```

**Pattern for C17 (geometry-derived frame proof):** Same `refute_in_delta` approach comparing `:frame` region coordinates between A4 and US Letter.

**Pattern for C20 (validate_border! rejection):**

```elixir
describe "C20: validate_border! rejects invalid options" do
  test "unknown key raises ArgumentError" do
    assert_raise ArgumentError, ~r/unknown.*key/i, fn ->
      Certificate.document(fixture_data(), border: %{unknown_key: true})
    end
  end

  test "invalid color raises ArgumentError mentioning hex" do
    assert_raise ArgumentError, ~r/hex/i, fn ->
      Certificate.document(fixture_data(), border: %{color: "#000"})
    end
  end

  test "inset >= min_margin raises ArgumentError naming safe max" do
    assert_raise ArgumentError, ~r/inset/i, fn ->
      Certificate.document(fixture_data(), border: %{inset: 9999})
    end
  end
end
```

---

### `test/docs_contract/path_claims_test.exs` (new test, request-response)

**Analog — `test/docs_contract/script_support_claims_test.exs:1-43` (full file):**

```elixir
defmodule Rendro.DocsContract.ScriptSupportClaimsTest do
  use ExUnit.Case, async: true

  test "support matrix has text_shaping section with four explicit_deferral entries" do
    matrix = File.read!("priv/support_matrix.json")

    assert matrix =~ ~s|"text_shaping"|
    assert matrix =~ ~s|"arabic"|

    assert matrix =~
             ~r/"arabic"\s*:\s*\{\s*"status"\s*:\s*"explicit_deferral"/

    # Verify evidence_deferred strings are non-empty (schema: minLength 40)
    assert matrix =~
             ~r/"arabic".*?"evidence_deferred"\s*:\s*".{40,}"/s
    ...
  end

  test "docs verification script includes the script support claims lane" do
    script = File.read!("scripts/verify_docs.exs")

    assert script =~
             ~s|{"Script support claims lane", ["test", "test/docs_contract/script_support_claims_test.exs"]}|
  end
end
```

**Analog for lane self-registration — `test/docs_contract/api_stability_claims_test.exs:104-110`:**

```elixir
test "docs verification script includes the api stability claims lane" do
  script = File.read!("scripts/verify_docs.exs")

  assert script =~
           ~s|{"API stability claims lane", ["test", "test/docs_contract/api_stability_claims_test.exs"]}|
end
```

**Pattern:** The `path_claims_test.exs` uses `File.read!("priv/support_matrix.json")` and `=~ ~r/...` to assert `path_primitive` section presence and three `explicit_deferral` entries (`transforms_cm`, `clipping_W`, `gradients`). Its second test asserts `File.read!("scripts/verify_docs.exs") =~ ~s|{"Path claims lane", ["test", "test/docs_contract/path_claims_test.exs"]}|` (self-registration).

**Also required:** Add the lane entry to `scripts/verify_docs.exs:7-21` (the `lanes = [...]` list) as:

```elixir
{"Path claims lane", ["test", "test/docs_contract/path_claims_test.exs"]},
```

---

## Shared Patterns

### `format_num` Determinism (apply to ALL new coordinate/color emission)

**Source:** `lib/rendro/pdf/writer.ex:1758-1762`

```elixir
defp format_num(n) when is_integer(n), do: Integer.to_string(n)

defp format_num(n) when is_float(n) do
  :erlang.float_to_binary(n * 1.0, decimals: 4)
end
```

**Apply to:** Every numeric literal emitted in Path op rendering, table decoration coordinates, Certificate frame geometry. Never use `Float.to_string` or string interpolation of floats directly (PITFALLS #6 / D-22).

---

### `@moduledoc false` Internal Module Pattern (apply to `Rendro.Color`)

**Source:** `lib/rendro/page_size.ex:1-3`

```elixir
defmodule Rendro.PageSize do
  @moduledoc false
  ...
end
```

**Apply to:** `lib/rendro/color.ex`. This excludes the module from `priv/public_api.json` manifest generation (D-02). Verify: `Rendro.Color` must NOT appear in `@public_modules` in `api.gen.ex`.

---

### `@moduledoc tags: [:stable]` Public Module Pattern (apply to `Rendro.Path`)

**Source:** `lib/rendro/image.ex:5-6` and `lib/rendro/text.ex:10`

```elixir
@moduledoc """
AST representation of a registered image asset to be rendered.
"""
@moduledoc tags: [:stable]
```

**Apply to:** `lib/rendro/path.ex`. Required for `mix rendro.api.gen` to include `Rendro.Path` in the manifest. Must also add `Rendro.Path` to `@public_modules` list in `lib/mix/tasks/rendro/api.gen.ex`.

---

### Errors-as-Product ArgumentError (apply to ALL new validation)

**Source:** `lib/rendro/recipes/certificate.ex:209-217`

```elixir
raise ArgumentError, """
Rendro.Recipes.Certificate.document/2 — missing required key(s) in data.

What:  Required certificate data keys are missing.
Where: Rendro.Recipes.Certificate.validate_data!/1
Why:   Missing key(s): #{inspect(missing)}.
Next:  Provide all required keys: #{Enum.map_join(required, ", ", &inspect/1)}.
"""
```

**Apply to:** `Rendro.Color.validate/1` (with hex-footgun message naming `"#2C6BED"` → `{44, 107, 237}` conversion), `validate_border!/2` in Certificate, `normalize_table_attrs/1` additions in `lib/rendro.ex`. All four lines (What/Where/Why/Next) required per D-04.

---

### `IO.iodata_to_binary` Content-Stream Assembly (apply to ALL new PDF op emission)

**Source:** `lib/rendro/pdf/writer.ex:1309-1311`

```elixir
]
|> IO.iodata_to_binary()
```

**Apply to:** `render_path_ops/2`, `render_path_gstate/1`, `table_decoration/3` helpers. Use iodata lists (not string concatenation) throughout, finalize with `IO.iodata_to_binary/1` at the clause boundary. This is the established pattern for every PDF content-stream builder in the writer.

---

### `q … Q` Graphics State Save/Restore (apply to Path and table decoration)

**Source:** `lib/rendro/pdf/writer.ex:1282-1283` and `1308`

```elixir
[
  "q\n",
  ...operators...
  "Q"
]
```

**Apply to:** Path `render_block` clause (balanced `q … cm … Q`) and `table_decoration` helper (balanced `q … Q`). Required for all graphics state isolation (color, line width, dash, cap, join must not leak into subsequent blocks).

---

## No Analog Found

All files in this phase have close analogs. No entries.

---

## Metadata

**Analog search scope:** `lib/rendro/`, `lib/rendro/pdf/`, `lib/rendro/pipeline/`, `lib/rendro/recipes/`, `lib/mix/tasks/rendro/`, `test/rendro/`, `test/docs_contract/`, `priv/`, `scripts/`
**Files scanned:** 18 analog files read directly
**Pattern extraction date:** 2026-06-10

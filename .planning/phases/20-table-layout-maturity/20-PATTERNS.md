# Phase 20: Table Layout Maturity - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 16
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/table.ex` | model | request-response | `lib/rendro/table.ex` | exact |
| `lib/rendro.ex` | utility | request-response | `lib/rendro.ex` | exact |
| `lib/rendro/pipeline/compose.ex` | service | transform | `lib/rendro/pipeline/compose.ex` | exact |
| `lib/rendro/pipeline/measure.ex` | service | transform | `lib/rendro/pipeline/measure.ex` | exact |
| `lib/rendro/pipeline/paginate.ex` | service | transform | `lib/rendro/pipeline/paginate.ex` | exact |
| `lib/rendro/pdf/writer.ex` | service | transform | `lib/rendro/pdf/writer.ex` | exact |
| `lib/rendro/error.ex` | utility | transform | `lib/rendro/error.ex` | exact |
| `lib/rendro/recipes.ex` | utility | request-response | `lib/rendro/recipes.ex` | exact |
| `lib/rendro/adapters/accrue.ex` | adapter | request-response | `lib/rendro/adapters/accrue.ex` | exact |
| `README.md` | utility | transform | `README.md` | exact |
| `guides/integrations.md` | utility | transform | `guides/integrations.md` | exact |
| `test/rendro/flow_test.exs` | test | request-response | `test/rendro/flow_test.exs` | exact |
| `test/rendro/pipeline/measure_test.exs` | test | transform | `test/rendro/pipeline/measure_test.exs` | exact |
| `test/rendro/pipeline/paginate_test.exs` | test | transform | `test/rendro/pipeline/paginate_test.exs` | exact |
| `test/rendro/pdf/writer_test.exs` | test | transform | `test/rendro/pdf/writer_test.exs` | exact |
| `test/rendro/adapters/accrue_test.exs` | test | request-response | `test/rendro/adapters/accrue_test.exs` | role-match |

## Pattern Assignments

### `lib/rendro/table.ex` (model, request-response)

**Analog:** `lib/rendro/table.ex`

**Current struct contract** (lines 6-20):
```elixir
@enforce_keys [:rows]
defstruct [
  :rows,
  header: nil,
  width: :fill,
  border: true
]

@type row :: [Rendro.Block.t() | String.t()]
@type t :: %__MODULE__{
        rows: [row()],
        header: row() | nil,
        width: number() | :fill,
        border: boolean()
      }
```
Phase 20 should extend or narrow this struct in place. Copy the existing Rendro model pattern: defaults in `defstruct`, mirrored in `@type`, no pipeline-only fields added here unless they are part of the truthful public contract.

**Closest model-shape analog:** `lib/rendro/block.ex` and `lib/rendro/text.ex` as used in Phase 19. Public layout semantics live directly on the struct/type, not in hidden metadata.

### `lib/rendro.ex` (utility, request-response)

**Analog:** `lib/rendro.ex`

**Builder wrapper pattern** (lines 80-97):
```elixir
@spec block(Text.t() | term(), keyword()) :: Block.t()
def block(content, attrs \\ []) do
  struct!(Block, Keyword.put(attrs, :content, content))
end

@spec table([Table.row()], keyword()) :: Table.t()
def table(rows, attrs \\ []) do
  struct!(Table, Keyword.put(attrs, :rows, rows))
end
```
Keep `Rendro.table/2` as a thin `struct!` wrapper. New table semantics should surface as explicit builder attrs on `%Rendro.Table{}` rather than a second helper layer or a side-channel in `Rendro.block/2`.

### `lib/rendro/pipeline/compose.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/compose.ex`

**Table normalization seam** (lines 36-50):
```elixir
defp compose_block(%Rendro.Block{content: %Rendro.Table{} = table} = block) do
  normalized_header = if table.header, do: normalize_row(table.header), else: nil
  normalized_rows = Enum.map(table.rows, &normalize_row/1)
  %{block | content: %{table | header: normalized_header, rows: normalized_rows}}
end

defp normalize_row(row) do
  Enum.map(row, fn
    %Rendro.Block{} = b -> b
    content when is_binary(content) -> Rendro.block(Rendro.text(content))
    other -> Rendro.block(other)
  end)
end
```
If Phase 20 adds explicit column-rule surface, normalize authored table inputs here only when they are pure structural coercions. Do not measure widths, assign x/y, or paginate rows here.

### `lib/rendro/pipeline/measure.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/measure.ex`

**Stage entry and propagation pattern** (lines 16-24, 82-105):
```elixir
@spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
def run(%Rendro.Document{} = doc) do
  font = Font.helvetica()

  doc
  |> measure_pages(font)
  |> measure_content(font)
  |> measure_layout(font)
end
```
```elixir
measured_region_blocks =
  Enum.into(layout.region_blocks, %{}, fn {name, blocks} ->
    {name, Enum.map(blocks, &measure_block(&1, font))}
  end)
```

**Current table-measure hook** (lines 41-56):
```elixir
defp measure_block(%Rendro.Block{content: %Rendro.Table{} = table, width: nil} = block, font) do
  row_height = 14.4
  col_width = 100
  header_h = if table.header, do: row_height, else: 0
  rows_h = length(table.rows) * row_height
  height = header_h + rows_h
  width = table_width(table, col_width)

  measured_header = if table.header, do: measure_row(table.header, font), else: nil
  measured_rows = Enum.map(table.rows, &measure_row(&1, font))

  table = %{table | header: measured_header, rows: measured_rows}
  %{block | content: table, width: width, height: height}
end
```
This is the primary landing zone for Phase 20 table semantics. Replace the demo geometry here with explicit authored column resolution, measured cell widths/heights, row heights, and table height calculation. Keep the pattern: measure child cells first, then write finalized geometry back onto the block/content before paginate sees it.

**Text measurement analog to copy** (lines 58-73):
```elixir
lines = wrap_text(text.content, block.width, font, text.size)
measured_width = measured_text_width(lines, font, text.size)
width = block.width || measured_width
measured_height = text.size * text.line_height * length(lines)
height = block.height || measured_height
```
Table cell text should reuse this model: width constraint authored on the containing cell/block, measurement produces deterministic height, and measured content carries render-ready data forward.

### `lib/rendro/pipeline/paginate.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/paginate.ex`

**Flow routing and typed overflow pattern** (lines 23-52):
```elixir
defp paginate_flow(%Document{} = doc) do
  layout = flow_layout(doc)
  template = layout.template
  page_template = page_from_template(template)
  body_blocks = Map.get(layout.region_blocks, :body, doc.content)
  max_h = layout.body_capacity

  try do
    pages =
      paginate_blocks(
        body_blocks,
        [%{page_template | blocks: []}],
        page_template,
        max_h,
        %{overflow_source: :bounded_region, region: :body}
      )
```
All row-integrity and repeated-header behavior belongs here, after measurement and before rendering.

**Single-block fit/fail pattern** (lines 124-155, 272-285):
```elixir
defp paginate_block(block, [current_page | rest] = _pages, template, max_h, overflow_details) do
  block_h = block.height || 0
  current_h = Enum.sum(Enum.map(current_page.blocks, &(&1.height || 0)))
```
```elixir
if current_h + block_h <= max_h do
  [%{current_page | blocks: current_page.blocks ++ [block]} | rest]
else
  check_overflow!(block, block_h, max_h, failure_details)
  [%{template | blocks: [block]}, current_page | rest]
end
```
```elixir
defp check_overflow!(block, block_h, max_h, overflow_details) do
  if block_h > max_h do
    throw({:error, :content_overflow, Map.merge(%{block_height: block_h, max_height: max_h, block: block_rect(block)}, overflow_details)})
  end
end
```
For impossible single-row fits, extend `details` through this same throw/catch path. Do not raise, clip, shrink, or invent a table-only error family.

**Current table split seam** (lines 236-269, 588-623):
```elixir
available_h = max_h - current_h
{this_page_table, remaining_table} = split_table(table, available_h)
```
```elixir
defp split_table(%Rendro.Table{rows: rows, header: header} = table, available_h) do
  row_height = 14.4
  header_h = if header, do: row_height, else: 0

  if available_h < header_h + row_height do
    {nil, table}
  else
    fit_count = floor((available_h - header_h) / row_height)
    split_table_rows(table, rows, fit_count)
  end
end
```
```elixir
defp split_table_rows(table, rows, fit_count) do
  {this_rows, rest_rows} = Enum.split(rows, fit_count)

  case rest_rows do
    [] -> {table, nil}
    _ ->
      this_table = %{table | rows: this_rows}
      rest_table = %{table | rows: rest_rows}
      {this_table, rest_table}
  end
end
```
Phase 20 should replace this fixed-height/fixed-count split logic with measured-row-aware splitting, but keep the same seam and the same repeated-header approach of emitting a new `%Rendro.Table{}` continuation block. Do not create an alternate pagination path outside `paginate_block/5`.

**Stacking seam for finalized geometry** (lines 93-120):
```elixir
defp stack_table_cells(%Rendro.Block{content: %Rendro.Table{} = table} = block) do
  row_height = 14.4
  col_width = 100

  header_y = block.y || 0
  stacked_header =
    if table.header, do: stack_cells(table.header, header_y, col_width), else: nil
```
This is where measured column widths and row offsets should be applied to child cells. Keep it as coordinate assignment only. By the time execution reaches this function, all geometry decisions should already be final.

### `lib/rendro/pdf/writer.ex` (service, transform)

**Analog:** `lib/rendro/pdf/writer.ex`

**Page stream assembly pattern** (lines 138-156):
```elixir
defp build_content_stream(%Rendro.Page{} = page, font) do
  Enum.map_join(page.blocks, "\n", fn block -> render_block(block, page, font) end)
end

defp render_block(%Rendro.Block{content: %Rendro.Table{} = table} = block, page, font) do
  header_ops =
    if table.header do
      Enum.map(table.header, &render_block(&1, page, font, block.x, block.y))
    else
      []
    end

  rows_ops =
    Enum.map(table.rows, fn row ->
      Enum.map(row, &render_block(&1, page, font, block.x, block.y))
    end)

  [header_ops | rows_ops] |> List.flatten() |> Enum.join("\n")
end
```
Keep table rendering as a recursive serialization of already-measured child blocks. Writer should consume positions and lines; it should not resolve columns, compute row breaks, or infer table width.

**Measured text serialization analog** (lines 172-201):
```elixir
defp render_block(%Rendro.Block{content: %MeasuredText{} = text} = block, page, _font, ox, oy) do
  render_text_block(block, page, ox, oy, text.source, text.lines, text.line_height)
end
```
```elixir
line_ops =
  lines
  |> Enum.with_index()
  |> Enum.flat_map(fn {line, index} ->
    if index == 0 do
      ["#{format_num(x)} #{format_num(y)} Td", "(#{escape_pdf_string(line)}) Tj"]
    else
      ["0 #{format_num(-line_offset)} Td", "(#{escape_pdf_string(line)}) Tj"]
    end
  end)
```
Any table-cell wrapping should serialize through this existing measured-text path, not a table-specific string writer.

### `lib/rendro/error.ex` (utility, transform)

**Analog:** `lib/rendro/error.ex`

**Structured error wrapper** (lines 23-41):
```elixir
def from_stage(stage, reason, context \\ %{}) when is_atom(stage) do
  %__MODULE__{
    what: what(stage, reason),
    where: "Rendro.Pipeline.#{stage_module_suffix(stage)}",
    why: why(reason),
    next: next_step(stage, reason),
    stage: stage,
    reason: reason,
    render_id: Map.get(context, :render_id),
    details:
      Map.merge(
        %{document_type: Map.get(context, :document_type), deterministic: Map.get(context, :deterministic)},
        Map.get(context, :details, %{})
      )
  }
end
```

**Paginate guidance text** (lines 74-80):
```elixir
defp next_step(:paginate, :content_overflow) do
  "Reduce content size or expand the declared page/region bounds; Rendro does not auto-fit overflowing content."
end
```
Add table-specific overflow facts under `details` only, for example row index, row height, header height, or available height. Preserve the existing `:paginate/:content_overflow` contract.

### `lib/rendro/recipes.ex` (utility, request-response)

**Analog:** `lib/rendro/recipes.ex`

**Recipe consumer pattern** (lines 16-38):
```elixir
header = [
  Rendro.block(Rendro.text("INVOICE ##{data.id}", size: 18))
]

table_rows =
  Enum.map(data.items, fn item ->
    [item.name, Integer.to_string(item.qty), "$#{item.price}"]
  end)

table = Rendro.table(table_rows, header: ["Item", "Qty", "Price"])
```
Phase 20 should update recipe consumers to use the explicit table contract directly. This file is the simplest public example for invoices; keep it narrow and declarative.

### `lib/rendro/adapters/accrue.ex` (adapter, request-response)

**Analog:** `lib/rendro/adapters/accrue.ex`

**Optional-dependency guard** (lines 1-2):
```elixir
if Code.ensure_loaded?(Accrue) do
  defmodule Rendro.Adapters.Accrue do
```

**Pure recipe boundary** (lines 42-58):
```elixir
@spec recipe(term()) ::
        {:ok, Rendro.Document.t()} | {:error, {:invalid_invoice, term()}}
def recipe(%Accrue.Invoice{} = invoice) do
  header = build_header(invoice)
  content = build_content(invoice)
  footer = build_footer(invoice)

  doc =
    Rendro.flow(content,
      header: header,
      footer: footer
    )

  {:ok, doc}
end

def recipe(other), do: {:error, {:invalid_invoice, other}}
```

**Table consumer seam** (lines 68-87):
```elixir
rows =
  Enum.map(line_items || [], fn %Accrue.LineItem{} = item ->
    [
      to_string(item.description),
      to_string(item.quantity),
      format_amount(item.unit_amount),
      format_amount(item.subtotal)
    ]
  end)

table =
  Rendro.table(rows,
    header: ["Description", "Qty", "Unit", "Subtotal"]
  )
```
This adapter should remain a consumer of the core table API, not a special layout engine. Update it only to exercise the truthful Phase 20 table surface.

### `README.md` (utility, transform)

**Analog:** `README.md`

**Executable docs-contract pattern** (lines 16-18, 101-110):
```markdown
Verified by the README compile/eval lane in `mix docs.contract`.
```
```elixir
# docs-contract: readme-fixed-compile
page = Rendro.page(blocks: [
  Rendro.block(Rendro.text("Fixed Position"), x: 100, y: 100)
])
```
Keep new table docs in the compile/eval lane when possible. Public claims should stay narrow, explicit, and executable.

**Truthful scope language analog** (lines 77-84):
```markdown
`keep_together`, `keep_with_next`, `break_before`, and `break_after` are the full
Phase 19 public break surface ...

Rendro does not currently promise widow/orphan control, hyphenation, browser or CSS break-model parity, or best-effort keep-rule relaxation ...
```
Use this tone for Phase 20 tables: explicitly say what is supported, and explicitly name what remains out of scope.

### `guides/integrations.md` (utility, transform)

**Analog:** `guides/integrations.md`

**Core-vs-adapter boundary language** (lines 15-27):
```markdown
Wrapped flow text and pagination directives are core-library behavior, not
adapter-specific behavior.
...
Those scope boundaries come from the Rendro core layout contract and remain the same regardless of delivery path.
```

**Accrue recipe contract pattern** (lines 328-352):
```markdown
`recipe/1` reads the following fields from the `%Accrue.Invoice{}`:

| Field | Usage |
|---|---|
| `:line_items` | List of `%Accrue.LineItem{}` mapped into a table with columns Description, Qty, Unit, Subtotal. |
```
If table semantics change, update this guide by describing the observable document contract at the adapter boundary, not internal pipeline details.

### `test/rendro/flow_test.exs` (test, request-response)

**Analog:** `test/rendro/flow_test.exs`

**Public end-to-end table smoke test** (lines 37-64):
```elixir
table =
  Rendro.table(
    [
      ["A1", "B1"],
      ["A2", "B2"]
    ],
    header: ["Col A", "Col B"]
  )

doc =
  Rendro.flow([
    Rendro.block(Rendro.text("Above Table")),
    Rendro.block(table),
    Rendro.block(Rendro.text("Below Table"))
  ])
```

**Header-repeat render proof** (lines 66-86):
```elixir
rows = for i <- 1..50, do: ["A#{i}", "B#{i}"]
table = Rendro.table(rows, header: ["Col A", "Col B"])
doc = Rendro.flow([Rendro.block(table)])
{:ok, pdf} = Rendro.render(doc)

assert length(Regex.scan(~r/\(Col A\) Tj/, pdf)) == 2
```
Extend this file for public semantics: explicit columns, atomic row overflow, repeated headers, and invoice-like multi-page behavior.

### `test/rendro/pipeline/measure_test.exs` (test, transform)

**Analog:** `test/rendro/pipeline/measure_test.exs`

**Deterministic measurement pattern** (lines 119-143):
```elixir
assert {:ok, first} = Measure.run(doc)
assert {:ok, second} = Measure.run(doc)
assert %MeasuredText{lines: lines} = first_block.content
assert lines == second_block.content.lines
```

**Constraint-driven sizing pattern** (lines 205-229):
```elixir
assert constrained_block.width == 70
assert constrained_block.height > unconstrained_block.height
assert length(constrained_block.content.lines) > 1
```
Copy this style for table measurement tests: assert stable column resolution, stable row heights, authored width preservation, and deterministic repeated runs.

### `test/rendro/pipeline/paginate_test.exs` (test, transform)

**Analog:** `test/rendro/pipeline/paginate_test.exs`

**Template-aware pagination proof** (lines 68-140):
```elixir
{:ok, doc} = Build.run(doc)
{:ok, doc} = Compose.run(doc)
{:ok, doc} = Measure.run(doc)
assert {:ok, paginated} = Paginate.run(doc)
```
Use the full pipeline in pagination tests so table splitting operates on measured geometry, not hand-built assumptions.

**Typed overflow-detail pattern** (lines 216-241):
```elixir
assert {:error, %Rendro.Error{} = error} = paginate_flow(doc)
assert error.stage == :paginate
assert error.reason == :content_overflow
assert error.details.keep_rule == :keep_with_next
assert error.details.max_height == 30
assert error.details.region == :body
```
Phase 20 table overflow tests should follow this exact shape, with table-specific facts stored under `error.details`.

**Nested directive validation pattern** (lines 269-304):
```elixir
%Rendro.Block{
  content: %Rendro.Table{
    rows: [
      [
        %Rendro.Block{
          content: Rendro.text("Nested fixed"),
          break_before: true
        }
      ]
    ]
  }
}
```
This file already asserts that table children are traversed for layout directives. Keep table semantics aligned with the main flow engine rather than special-casing tables as opaque blobs.

### `test/rendro/pdf/writer_test.exs` (test, transform)

**Analog:** `test/rendro/pdf/writer_test.exs`

**Measured-line serialization proof** (lines 165-194):
```elixir
measured =
  %MeasuredText{
    source: source,
    lines: ["alpha beta", "gamma"],
    line_height: source.line_height,
    width: 60,
    height: 36
  }

assert pdf =~ "(alpha beta) Tj"
assert pdf =~ "(gamma) Tj"
assert pdf =~ "0 -18.0000 Td"
```
Add table writer tests at the PDF operator level only when they validate serialization of already-measured geometry, such as repeated headers or column positions. Do not duplicate measurement logic assertions here.

### `test/rendro/adapters/accrue_test.exs` (test, request-response)

**Analog:** `test/rendro/adapters/accrue_test.exs`

**Adapter contract proof** (lines 20-37):
```elixir
assert {:ok, %Rendro.Document{} = doc} = Adapter.recipe(sample_invoice())
assert is_list(doc.content) and doc.content != []

{:ok, doc} = Adapter.recipe(sample_invoice())
assert {:ok, binary} = Rendro.render(doc)
assert <<"%PDF-", _rest::binary>> = binary
```
If invoice table semantics become explicit, update this file to assert the adapter emits the intended public table contract and still renders end-to-end.

## Shared Patterns

### One Layout Path Only
**Sources:** `lib/rendro/pipeline/compose.ex:36-50`, `lib/rendro/pipeline/measure.ex:41-56`, `lib/rendro/pipeline/paginate.ex:236-269`, `lib/rendro/pdf/writer.ex:142-156`

Apply this split of responsibilities:

- `Compose`: normalize authored rows/cells into `%Rendro.Block{}` only.
- `Measure`: resolve explicit column rules, measure cell content, compute row/table geometry.
- `Paginate`: decide page breaks from measured row heights, repeat headers, fail truthfully on impossible rows.
- `Writer`: serialize pre-measured cells at assigned coordinates.

Planner guidance: do not introduce a table-only preprocessor, alternate pagination engine, or writer-side layout inference.

### Typed Overflow, Not Silent Fallback
**Sources:** `lib/rendro/pipeline/paginate.ex:272-285`, `lib/rendro/error.ex:74-76`, `test/rendro/pipeline/paginate_test.exs:216-241`

Use the existing overflow contract:
```elixir
throw({:error, :content_overflow, details})
...
{:error, Rendro.Error.from_stage(:paginate, :content_overflow, %{details: details})}
```
Impossible single-row fits should report richer `details`; they should not split rows, shrink content, or downgrade to warnings.

### Public Contract Truthfulness
**Sources:** `README.md:77-84`, `guides/integrations.md:15-27`, `guides/integrations.md:328-352`

Document only the table behavior the engine actually honors:

- explicit authored column rules
- repeated headers on continuation pages
- atomic rows by default
- typed overflow when an authored row cannot fit

Remove or deprecate misleading `%Rendro.Table{}` fields instead of documenting around them.

### Adapter Boundaries Stay Consumers
**Sources:** `lib/rendro/recipes.ex:20-25`, `lib/rendro/adapters/accrue.ex:68-87`, `guides/integrations.md:15-27`

Recipes and adapters should adopt the new table API as clients. They should not define layout heuristics or adapter-local table semantics.

## No Analog Found

None. All planned Phase 20 seams already exist in-repo; the work is to mature the current table path rather than add a second architecture.

## Metadata

**Analog search scope:** `lib/rendro`, `test/rendro`, `test/docs_contract`, `README.md`, `guides/integrations.md`, prior phase pattern map
**Files scanned:** 18
**Pattern extraction date:** 2026-04-29

# Phase 37: Advanced Table Layout & Fragmentation - Pattern Map

**Mapped:** 2026-05-04 (or current date)
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/table.ex` | model | transform | `lib/rendro/table.ex` | exact |
| `lib/rendro/row.ex` | model | transform | `lib/rendro/block.ex` | role-match |
| `lib/rendro/cell.ex` | model | transform | `lib/rendro/block.ex` | role-match |
| `lib/rendro/pipeline/paginate.ex` | service | transform | `lib/rendro/pipeline/paginate.ex` | exact |
| `lib/rendro/pipeline/measure.ex` | service | transform | `lib/rendro/pipeline/measure.ex` | exact |

## Pattern Assignments

### `lib/rendro/table.ex` (model, transform)

**Analog:** `lib/rendro/table.ex`

**Table Struct Pattern** (lines 6-18):
```elixir
  @enforce_keys [:rows]
  defstruct [
    :rows,
    header: nil,
    columns: nil,
    split_policy: :row_atomic,
    # Pipeline geometry fields populated by Measure
    column_widths: nil,
    row_heights: nil,
    header_height: nil
  ]
```
*Note: We will add `repeat_header: boolean()` (default `false`) and `decoration_break: :slice | :clone` (default `:slice`) to this struct to handle continuation decorators.*

---

### `lib/rendro/row.ex` & `lib/rendro/cell.ex` (model, transform)

**Analog:** `lib/rendro/block.ex`

**Block Behavior Pattern** (lines 6-19):
```elixir
  @enforce_keys [:content]
  defstruct [
    :content,
    x: 0,
    y: 0,
    width: nil,
    height: nil,
    keep_together: false,
    keep_with_next: false,
    break_before: false,
    break_after: false
  ]
```
*Note: Both `Rendro.Row` and `Rendro.Cell` will implement standard block behavior options alongside their specific overrides (e.g. `split_policy: :atomic` on a cell to override the table's global `:fragment` policy).*

---

### `lib/rendro/pipeline/paginate.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/paginate.ex`

**Pagination Splitting Pattern** (lines 244-255):
```elixir
  defp handle_table_split(
         block,
         table,
         current_page,
         rest,
         template,
         max_h,
         current_h,
         _block_h,
         overflow_details,
         diagnostics
       ) do
    available_h = max_h - current_h
    {this_page_table, remaining_table} = split_table(table, available_h)
```
*Note: The current `split_table/2` logic splits recursively by rows. The new design treats cells as isolated pagination flows. The row iterates through its cells, calling the standard `paginate_block` logic (lines 107-147) and `handle_text_split` (lines 286-348), maintaining the invariant that all cells in a fragmented row break at the exact same Y-coordinate relative to the row.*

---

### `lib/rendro/pipeline/measure.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/measure.ex`

**Table Measurement Pattern** (lines 35-57):
```elixir
  defp measure_block(
         doc,
         %Rendro.Block{content: %Rendro.Table{} = table} = block,
         container_width
       ) do
    width = block.width || container_width || 595.28

    col_count = max_columns(table)
    col_widths = resolve_columns(table.columns, col_count, width)

    with {:ok, {measured_header, header_h}} <- measure_table_row(doc, table.header, col_widths),
         {:ok, {measured_rows, row_heights}} <- measure_table_rows(doc, table.rows, col_widths) do
```
*Note: To avoid rowspan fragmentation issues, this measurement phase will be updated to introduce the **Grid Projection Algorithm**. The table will be projected into a 2D Grid structure containing flags like `is_continuation: true`, enabling the `Paginate` phase to slice the grid horizontally rather than as nested nodes.*

---

## Shared Patterns

### Break Semantics
**Source:** `lib/rendro/pipeline/paginate.ex`
**Apply to:** Row and Cell fragmentation logic
```elixir
    if total_lines == 0 do
      if current_h == 0 do
        check_overflow!(block, block_h, max_h, overflow_details)
      else
        {[%{template | blocks: [block]}, current_page | rest], diagnostics}
      end
```
*Note: Cells act as standard block containers with remaining height. Mid-sentence splits are naturally handled by existing pagination flows.*

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `Grid Projection Structs` | utility | transform | No existing 2D Grid representation logic in layout pipeline |

## Metadata

**Analog search scope:** `lib/rendro/`
**Files scanned:** 5
**Pattern extraction date:** 2026-05-04
# Phase 41: Widow/Orphan Layout Controls - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/text.ex` | model | pipeline config | `lib/rendro/text.ex` (existing defaults) | exact |
| `lib/rendro/pipeline/measured_text.ex` | model | pipeline state | `lib/rendro/pipeline/measured_text.ex` (existing struct) | exact |
| `lib/rendro/pipeline/paginate.ex` | service (pipeline stage) | transform | `lib/rendro/pipeline/paginate.ex` (`handle_table_split/10`) | exact |

## Pattern Assignments

### `lib/rendro/text.ex` (model, pipeline config)

**Analog:** `lib/rendro/text.ex` (Existing schema properties)

**Schema Definition & Defaults Pattern** (lines 14-22):
```elixir
  @enforce_keys [:content]
  defstruct [
    :content,
    font: "Helvetica",
    size: 12,
    color: {0, 0, 0},
    line_height: 1.2,
    widows: 2,
    orphans: 2
  ]
```

**Type Spec Pattern** (lines 28-36):
```elixir
  @type t :: %__MODULE__{
          content: String.t(),
          font: font_ref(),
          size: number(),
          color: {non_neg_integer(), non_neg_integer(), non_neg_integer()},
          line_height: float(),
          widows: non_neg_integer(),
          orphans: non_neg_integer()
        }
```

---

### `lib/rendro/pipeline/measured_text.ex` (model, pipeline state)

**Analog:** `lib/rendro/pipeline/measured_text.ex` (Existing struct definition)

**Struct Definition Pattern** (lines 4-13):
```elixir
  @enforce_keys [
    :source,
    :lines,
    :line_height,
    :width,
    :height,
    :resolved_font,
    :widows,
    :orphans
  ]
  defstruct [:source, :lines, :line_height, :width, :height, :resolved_font, :widows, :orphans]
```

---

### `lib/rendro/pipeline/paginate.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/paginate.ex` (`handle_table_split/10`)

**Block Splitting Controller Pattern** (lines 268-293):
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

    cond do
      this_page_table && remaining_table ->
        this_block = %{block | content: this_page_table, height: table_height(this_page_table)}

        remaining_block = %{
          block
          | content: remaining_table,
            height: table_height(remaining_table)
        }

        current_page = %{current_page | blocks: current_page.blocks ++ [this_block]}
```

**Diagnostics & Pagination State Pattern** (lines 295-303):
```elixir
        new_diagnostic = %{
          level: :info,
          type: :table_split,
          page_index: overflow_details.page_index,
          reason: :insufficient_height
        }

        {[%{template | blocks: [remaining_block]}, current_page | rest],
         [new_diagnostic | diagnostics]}
```

**Overflow/Failure Pattern** (lines 305-316):
```elixir
      remaining_table ->
        if current_h == 0 do
          impossible_row_h = List.first(table.row_heights || []) || 0

          details =
            Map.merge(overflow_details, %{
              row_index: 0,
              row_height: impossible_row_h,
              header_height: table.header_height || 0,
              column_widths: table.column_widths || []
            })

          throw({:error, :content_overflow, details})
        else
          {[%{template | blocks: [block]}, current_page | rest], diagnostics}
        end

      true ->
        {[%{current_page | blocks: current_page.blocks ++ [block]} | rest], diagnostics}
    end
```

## Shared Patterns

### Elixir Struct Constraints
**Source:** `lib/rendro/text.ex`
**Apply to:** Models (`Rendro.Text`, `Rendro.Pipeline.MeasuredText`)
- Explicit `@enforce_keys` for required fields.
- Type definitions (`@type t :: %__MODULE__{}`) clearly mapping fields and their bounds (e.g. `non_neg_integer()`).

### Block Transformation in Pagination
**Source:** `lib/rendro/pipeline/paginate.ex`
**Apply to:** Layout logic in `Rendro.Pipeline.Paginate`
- Splitting a block involves evaluating `available_h`, calculating physically fitting entities, then checking numeric constraints.
- AST Mutation relies on explicit function matching mapping directly to specific block contents.
- Emits a `this_block` for the current page and a `remaining_block` for the next using `[%{template | blocks: [remaining_block]}, current_page | rest]`.
- Propagates an updated info diagnostic.

## Metadata

**Analog search scope:** `lib/rendro/**/*.ex`
**Files scanned:** 3
**Pattern extraction date:** 2024-05-24

# Phase 36: Widow/Orphan Layout Controls - Pattern Map

**Mapped:** 2024-05-04
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/text.ex` | model | data struct | `lib/rendro/text.ex` | exact |
| `lib/rendro/pipeline/measured_text.ex` | model | data struct | `lib/rendro/pipeline/measured_text.ex` | exact |
| `lib/rendro/pipeline/paginate.ex` | service | transform | `lib/rendro/pipeline/paginate.ex` | exact |

## Pattern Assignments

### `lib/rendro/text.ex` (model, data struct)

**Analog:** `lib/rendro/text.ex` (self)

**Core struct defaults pattern** (lines 13-20):
```elixir
  @enforce_keys [:content]
  defstruct [
    :content,
    font: "Helvetica",
    size: 12,
    color: {0, 0, 0},
    line_height: 1.2
  ]
```

**Type definition pattern** (lines 26-32):
```elixir
  @type t :: %__MODULE__{
          content: String.t(),
          font: font_ref(),
          size: number(),
          color: {non_neg_integer(), non_neg_integer(), non_neg_integer()},
          line_height: float()
        }
```

---

### `lib/rendro/pipeline/measured_text.ex` (model, data struct)

**Analog:** `lib/rendro/pipeline/measured_text.ex` (self)

**Core struct definition pattern** (lines 4-5):
```elixir
  @enforce_keys [:source, :lines, :line_height, :width, :height, :resolved_font]
  defstruct [:source, :lines, :line_height, :width, :height, :resolved_font]
```

**Type definition pattern** (lines 9-16):
```elixir
  @type t :: %__MODULE__{
          source: Rendro.Text.t(),
          lines: [[run()]],
          line_height: number(),
          width: number(),
          height: number(),
          resolved_font: Rendro.PDF.Font.t()
        }
```

---

### `lib/rendro/pipeline/paginate.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/paginate.ex` (self)

**Function matching for fragmentable splitting** (lines 280-308, `handle_table_split/10`):
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
# ...
```

**Block integration pattern for explicit types** (lines 135-156, `paginate_block/5`):
```elixir
      %Rendro.Table{} = table ->
        case table_split_policy(table, failure_details) do
          :row_atomic when current_h + block_h > max_h ->
            handle_table_split(
              block,
              table,
              current_page,
              rest,
              template,
              max_h,
              current_h,
              block_h,
              failure_details,
              diagnostics
            )

          :row_atomic ->
            {[%{current_page | blocks: current_page.blocks ++ [block]} | rest], diagnostics}
        end
```

**Math-based logical splitting** (lines 405-419, `split_table/2`):
```elixir
  defp split_table(%Rendro.Table{} = table, available_h) do
    header_h = table.header_height || 0
    row_heights = table.row_heights || []

    {fit_count, _} =
      Enum.reduce_while(row_heights, {0, header_h}, fn rh, {count, current_h} ->
        if current_h + rh <= available_h do
          {:cont, {count + 1, current_h + rh}}
        else
          {:halt, {count, current_h}}
        end
      end)

    if fit_count == 0 do
      {nil, table}
    else
      split_table_rows(table, fit_count)
    end
  end
```

## Shared Patterns

### Error Handling
**Source:** `lib/rendro/pipeline/paginate.ex`
**Apply to:** Text splitting in `paginate.ex`
```elixir
    throw({:error, :content_overflow, details})
```

## No Analog Found

None. All files have clear analogs either in their existing state or via the existing `handle_table_split/10` function.

## Metadata

**Analog search scope:** `lib/rendro/`
**Files scanned:** 3 modified files, plus `lib/rendro/table.ex`
**Pattern extraction date:** 2024-05-04
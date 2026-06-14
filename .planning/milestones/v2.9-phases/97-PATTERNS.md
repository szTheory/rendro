# Phase 97: Location Tracking & Primitives - Pattern Map

**Mapped:** 2024-05-30
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/block.ex` | model | transform | `lib/rendro/block.ex` | exact |
| `lib/rendro/metadata.ex` | model | struct | `lib/rendro/metadata.ex` | exact |
| `lib/rendro/pipeline/paginate.ex` | pipeline phase | batch / transform | `lib/rendro/pipeline/paginate.ex` & `lib/rendro/rules/check_form_fields.ex` | exact |
| `lib/rendro/rules/check_ids.ex` (new) | validation rule | batch | `lib/rendro/rules/check_form_fields.ex` | exact |

## Pattern Assignments

### `lib/rendro/block.ex` (model, transform)

**Analog:** `lib/rendro/block.ex`

**Struct definition pattern** (lines 9-19):
```elixir
  @enforce_keys [:content]
  defstruct [
    :content,
    id: nil, # <-- new field
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

**Type definition pattern** (lines 21-32):
```elixir
  @type t :: %__MODULE__{
          content: ...
          id: String.t() | nil, # <-- new type
          x: number(),
          ...
```

---

### `lib/rendro/metadata.ex` (model, struct)

**Analog:** `lib/rendro/metadata.ex`

**Struct definition pattern** (lines 14-21):
```elixir
  defstruct [
    :title,
    :author,
    :creator,
    :creation_date,
    :modification_date,
    anchors: %{}, # <-- new field (ANC-02)
    custom: %{}
  ]
```

---

### `lib/rendro/pipeline/paginate.ex` (pipeline phase, batch/transform)

**Analog:** `lib/rendro/pipeline/paginate.ex` and `lib/rendro/rules/check_form_fields.ex`

**Pages Mapping and Metadata Mutation Pattern** (lines 35-43 in `paginate.ex`):
```elixir
      pages =
        pages
        |> Enum.with_index(1)
        |> Enum.map(fn {page, idx} ->
          page
          |> stack_body_blocks(layout.body_region)
          |> validate_body_region_fit!(layout.body_region, idx)
          |> apply_page_template(idx, layout, total, Map.fetch!(page_contexts, idx))
        end)

      # Extract anchors using the newly localized, absolute physical bounds:
      # anchors = collect_anchors(pages)
      # new_metadata = %{doc.metadata | anchors: anchors}

      {:ok,
       %{
         doc
         | pages: pages,
           metadata: new_metadata, # <-- updated with anchors map
           content: [],
           diagnostics: Enum.reverse(diagnostics) ++ doc.diagnostics
       }}
```

---

### `lib/rendro/rules/check_ids.ex` (validation rule, batch)

**Analog:** `lib/rendro/rules/check_form_fields.ex`

**Rule Contract Pattern** (lines 10-15 in `check_form_fields.ex`):
```elixir
  def check(%Document{} = doc, _root_doc) do
    errors = duplicate_ids(doc)

    case errors do
      [] -> :ok
      _ -> {:errors, errors}
    end
  end
```

**Duplicate Detection Pattern** (lines 115-131 in `check_form_fields.ex`):
```elixir
  defp duplicate_ids(%Document{} = doc) do
    doc
    |> collect_blocks_with_ids()
    |> duplicate_strings()
    |> Enum.map(&{:duplicate_id, &1})
  end

  defp duplicate_strings(values) do
    values
    |> Enum.group_by(& &1)
    |> Enum.filter(fn {_value, grouped} -> length(grouped) > 1 end)
    |> Enum.map(fn {value, _grouped} -> value end)
    |> Enum.sort()
  end
```

**Pipeline Integration** (lines 13-20 in `lib/rendro/pipeline/validate.ex`):
```elixir
  @default_rules [
    CheckReferences,
    CheckBounds,
    CheckRequiredKeys,
    CheckFormFields,
    CheckLinks,
    CheckEmbeddedFiles,
    CheckIds # <-- newly registered rule
  ]
```

---

## Shared Patterns

### Tree Traversal & Block Collection
**Source:** `lib/rendro/rules/check_form_fields.ex` (lines 145-161)
**Apply to:** Both anchor extraction in `paginate.ex` and duplicate validation in `check_ids.ex`
```elixir
  defp collect_blocks_with_ids(%Document{pages: pages}) do
    Enum.flat_map(pages, &collect_page_ids/1)
  end

  defp collect_page_ids(%Page{blocks: blocks}) do
    Enum.flat_map(blocks, &collect_block_ids/1)
  end

  defp collect_block_ids(%Block{id: id, content: %Table{} = table}) when is_binary(id) do
    [id] ++ collect_row_ids(table.header) ++ Enum.flat_map(table.rows, &collect_row_ids/1)
  end

  defp collect_block_ids(%Block{content: %Table{} = table}) do
    collect_row_ids(table.header) ++ Enum.flat_map(table.rows, &collect_row_ids/1)
  end

  defp collect_block_ids(%Block{id: id}) when is_binary(id), do: [id]
  defp collect_block_ids(%Block{}), do: []

  defp collect_row_ids(nil), do: []
  defp collect_row_ids(%Row{cells: cells}) do
    Enum.flat_map(cells, fn %Rendro.Cell{content: block} -> collect_block_ids(block) end)
  end
```

## No Analog Found
None. Block attributes, validation rules, and tree traversal are standard patterns in the pipeline.

## Metadata
**Analog search scope:** `lib/rendro/`, `lib/rendro/pipeline/`, `lib/rendro/rules/`
**Files scanned:** 12
**Pattern extraction date:** 2024-05-30

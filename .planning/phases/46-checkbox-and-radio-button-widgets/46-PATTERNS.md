# Phase 46: Checkbox and Radio Button Widgets - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/form_field.ex` | component | request-response | `lib/rendro/form_field.ex` | exact |
| `lib/rendro.ex` | facade | transform | `lib/rendro.ex` | exact |
| `lib/rendro/rules/check_form_fields.ex` | validator | transform | `lib/rendro/rules/check_form_fields.ex` | exact |
| `lib/rendro/pipeline/measure.ex` | pipeline | transform | `lib/rendro/pipeline/measure.ex` | exact |
| `lib/rendro/pdf/writer.ex` | service | transform | `lib/rendro/pdf/writer.ex` | exact |
| `test/rendro/pdf/writer_test.exs` | test | proof | `test/rendro/pdf/writer_test.exs` | exact |

## Pattern Assignments

### `lib/rendro/form_field.ex`

**Analog:** current `lib/rendro/form_field.ex`

**Struct extension pattern**
```elixir
@enforce_keys [:name]
defstruct [
  :name,
  value: "",
  font: "Helvetica",
  size: 12
]
```

Phase 46 should extend this struct in place instead of replacing it with parallel checkbox/radio structs.

---

### `lib/rendro.ex`

**Analog:** current `Rendro.form_field/3`

**Keyword split pattern**
```elixir
{field_attrs, block_attrs} = Keyword.split(attrs, [:font, :size])
field = struct!(FormField, Keyword.merge(field_attrs, name: name, value: value))
struct!(Block, Keyword.put(block_attrs, :content, field))
```

Phase 46 should keep the same split-builder shape while allowing additional field keys like `:type`, `:checked`, `:group`, and `:export_value`.

---

### `lib/rendro/rules/check_form_fields.ex`

**Analog:** current `check/2` clauses

**Clause-based validation pattern**
```elixir
def check(%Rendro.FormField{name: name}, _doc) when is_binary(name) and byte_size(name) > 0,
  do: :ok

def check(%Rendro.FormField{}, _doc), do: {:error, {:missing_required_key, :name}}
```

Phase 46 should keep the same focused rule module but add:
- type validation
- radio `group` / `export_value` requirements
- document-level group default checks

---

### `lib/rendro/pipeline/measure.ex`

**Analog:** current form-field measurement clause

**Fallback geometry pattern**
```elixir
defp measure_block(
       _doc,
       %Rendro.Block{content: %Rendro.FormField{}} = block,
       _container_width
     ) do
  {:ok, %{block | width: block.width || 150.0, height: block.height || 20.0}}
end
```

Phase 46 should preserve this dedicated clause and only refine defaults by widget type where necessary.

---

### `lib/rendro/pdf/writer.ex`

**Analogs:** current helper seams

**Allocation pattern**
```elixir
defp allocate_form_field_nums(form_fields, start_num) do
  Enum.map_reduce(form_fields, start_num, fn form_field, num ->
    allocation = %{
      block: form_field.block,
      field: form_field.field,
      page_index: form_field.page_index,
      widget_obj_num: num,
      appearance_obj_num: num + 1
    }

    {allocation, num + 2}
  end)
end
```

**Page-local annotation pattern**
```elixir
{annot_refs, form_objects} =
  build_form_field_objects(
    page,
    page_num,
    Enum.filter(form_field_allocations, &(&1.page_index == page_index)),
    opts
  )
```

**Text-field widget pattern**
```elixir
"/Subtype /Widget\n",
"/FT /Tx\n",
"/AP <<\n/N ",
```

Phase 46 should preserve the helper-per-responsibility structure:
- allocation/group preparation
- page annotation assembly
- widget dictionary serialization
- appearance stream serialization

It should add button-specific helpers instead of inlining all logic into one giant writer clause.

---

### `test/rendro/pdf/writer_test.exs`

**Analog:** existing text-field PDF substring assertions

**Rendered PDF proof pattern**
```elixir
assert pdf =~ "/Subtype /Widget"
assert pdf =~ "/FT /Tx"
assert pdf =~ "/AP <<"
assert pdf =~ "/Rect [82 676 262 700]"
```

Phase 46 should follow the same strategy with button-specific assertions for:
- `/FT /Btn`
- `/AS`
- on/off appearance states
- radio grouping markers

## Shared Patterns

### Table-Aware Recursive Collection
Writer collectors already recurse through tables, rows, and cells. Button widgets should reuse `collect_block_form_fields/2` and related helpers rather than introducing a second traversal path.

### Deterministic Object Numbering
Every writer resource today is allocated through explicit sequential numbering. Radio parent fields should use the same explicit allocation flow so tests can assert stable serialization order.

## Metadata

**Analog search scope:** `lib/rendro/`, `test/rendro/`
**Files scanned:** 6
**Pattern extraction date:** 2026-05-05

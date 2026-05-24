# Phase 45: AcroForm and Interactive Text Fields - Pattern Map

**Mapped:** 2024-05
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/form_field.ex` | component | request-response | `lib/rendro/text.ex` | exact |
| `lib/rendro.ex` | facade | transform | `lib/rendro.ex` | exact |
| `lib/rendro/pdf/writer.ex` | service | transform | `lib/rendro/pdf/writer.ex` | exact |
| `lib/rendro/rules/check_form_fields.ex` | validator | transform | `lib/rendro/rules/check_required_keys.ex` | role-match |
| `lib/rendro/pipeline/validate.ex` | pipeline | transform | `lib/rendro/pipeline/validate.ex` | exact |

## Pattern Assignments

### `lib/rendro/form_field.ex` (component, request-response)

**Analog:** `lib/rendro/text.ex`

**Struct and Typespec pattern** (lines 12-28):
```elixir
  @enforce_keys [:content]
  defstruct [
    :content,
    font: "Helvetica",
    size: 12,
    color: {0, 0, 0}
  ]

  @type t :: %__MODULE__{
          content: String.t(),
          font: font_ref(),
          size: number(),
          color: {non_neg_integer(), non_neg_integer(), non_neg_integer()}
        }
```

---

### `lib/rendro.ex` (facade, transform)

**Analog:** `lib/rendro.ex`

**DSL builder pattern** (lines 142-148):
```elixir
  @spec text(String.t(), keyword()) :: Text.t()
  def text(content, attrs \\ []) do
    attrs
    |> normalize_text_attrs()
    |> Keyword.put(:content, content)
    |> then(&struct!(Text, &1))
  end
```
*(Use similar pattern for `form_field(name, attrs \\ [])`)*

---

### `lib/rendro/pdf/writer.ex` (service, transform)

**Analog:** `lib/rendro/pdf/writer.ex`

**Catalog dictionary update pattern** (lines 57-62):
```elixir
    catalog_dict =
      {:dict,
       [
         {"Type", {:name, "Catalog"}},
         {"Pages", {:ref, pages_num, 0}}
       ]}
```
*(Add `{"AcroForm", {:dict, [...]}}` into `catalog_dict` conditionally when fields exist)*

**Page dictionary Annotations update pattern** (lines 201-209):
```elixir
      page_dict =
        {:dict,
         [
           {"Type", {:name, "Page"}},
           {"Parent", {:ref, pages_num, 0}},
           {"MediaBox", media_box},
           {"Contents", {:ref, content_num, 0}},
           {"Resources", resources}
         ]}
```
*(Add `{"Annots", {:array, [...]}}` into `page_dict` if the page contains form fields)*

---

### `lib/rendro/rules/check_form_fields.ex` (validator, transform)

**Analog:** `lib/rendro/rules/check_required_keys.ex`

**Rule matching pattern** (lines 3-10):
```elixir
  def check(%Rendro.Document{pages: pages}, _doc) when is_list(pages), do: :ok
  def check(%Rendro.Document{}, _doc), do: {:error, {:missing_required_key, :pages}}

  def check(%Rendro.Page{blocks: blocks}, _doc) when is_list(blocks), do: :ok
  def check(%Rendro.Page{}, _doc), do: {:error, {:missing_required_key, :blocks}}

  def check(%Rendro.Block{content: nil}, _doc), do: {:error, {:missing_required_key, :content}}
  def check(%Rendro.Block{}, _doc), do: :ok
```

---

### `lib/rendro/pipeline/validate.ex` (pipeline, transform)

**Analog:** `lib/rendro/pipeline/validate.ex`

**Pipeline child traversal pattern** (lines 32-35):
```elixir
  defp walk_children(%Rendro.Page{blocks: blocks}, doc, rules) do
    Enum.flat_map(blocks, &walk(&1, doc, rules))
  end

  defp walk_children(%Rendro.Block{content: content}, doc, rules) do
    walk(content, doc, rules)
  end
```

## Shared Patterns

### Dictionary Serialization
**Source:** `lib/rendro/pdf/object.ex`
**Apply to:** `Rendro.PDF.Writer`
```elixir
  def serialize({:dict, entries}, opts) when is_list(entries) do
    # Used for serializing both AcroForm and Annots dictionaries
  end
```

## Metadata

**Analog search scope:** `lib/rendro/`
**Files scanned:** 5
**Pattern extraction date:** 2024-05

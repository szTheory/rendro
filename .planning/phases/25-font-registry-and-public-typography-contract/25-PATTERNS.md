# Phase 25: Font Registry and Public Typography Contract - Patterns

## Existing Analogs

### Document-Owned Registries
- `lib/rendro/document.ex`
  - Existing builder pattern lives on `Rendro.Document` with append/merge helpers like `add_template/2`, `add_section/2`, and `put_options/2`.
  - Phase 25 should mirror this style for font registration instead of introducing a separate mutable service object.

### Pure Data Leaves
- `lib/rendro/text.ex`
  - `%Rendro.Text{}` is a plain struct with styling fields and no stage-specific metadata.
  - Keep font selection as authored data here; do not store writer refs or PDF object numbers on text nodes.

### Shared Pipeline Consumption
- `lib/rendro/pipeline/measure.ex`
- `lib/rendro/pdf/writer.ex`
  - Both currently instantiate `Rendro.PDF.Font.helvetica/0` locally.
  - Phase 25 should replace that duplicate choice with a shared resolver function or helper module consumed by both files.

### Public Builder Compatibility
- `lib/rendro.ex`
- `test/rendro_builders_test.exs`
  - Top-level builders already normalize or reject authored inputs at the boundary (`Rendro.table/2` is the closest recent example).
  - Font-registration helpers should follow the same pattern: explicit supported inputs, tight compatibility behavior, focused boundary tests.

## Recommended File Roles

| File | Role In Phase 25 | Closest Existing Analog |
|------|------------------|-------------------------|
| `lib/rendro/font_registry.ex` | new pure-core registry and resolution helper | `lib/rendro/table.ex` for contract definition + `lib/rendro/pdf/font.ex` for domain data |
| `lib/rendro/document.ex` | store registry/default font and add builder helpers | current template/section builder API |
| `lib/rendro/text.ex` | tighten public logical-font docs/types | existing style leaf contract |
| `lib/rendro.ex` | top-level builder wrappers for registration/defaults | `Rendro.table/2` boundary normalization style |
| `lib/rendro/pipeline/measure.ex` | consume shared resolved font for width math | current hard-coded Helvetica path |
| `lib/rendro/pdf/writer.ex` | consume shared resolved font for `/Tf` emission | current hard-coded Helvetica path |

## Code Excerpts To Preserve

### Builder ergonomics
`lib/rendro/document.ex`
```elixir
def add_template(%__MODULE__{} = doc, %Rendro.PageTemplate{} = template) do
  %__MODULE__{doc | page_templates: doc.page_templates ++ [template]}
end
```

Phase 25 should keep this style: pure transformation over `%Rendro.Document{}` with no hidden global registry.

### Boundary normalization precedent
`lib/rendro.ex`
```elixir
def table(rows, attrs \\ []) do
  attrs
  |> normalize_table_attrs()
  |> Keyword.put(:rows, rows)
  |> then(&struct!(Table, &1))
end
```

If Phase 25 keeps compatibility aliases like `"Helvetica"` or `:helvetica`, normalize them explicitly at the boundary or inside one shared resolver. Do not leave alias behavior implicit.

### Shared font drift to eliminate
`lib/rendro/pipeline/measure.ex`
```elixir
font = Font.helvetica()
```

`lib/rendro/pdf/writer.ex`
```elixir
font = Font.helvetica()
```

These duplicate lines are the concrete anti-pattern this phase should remove.

## Test Surfaces To Extend

- `test/rendro/document_test.exs`
  - add direct registry/default-font struct behavior proof.
- `test/rendro/text_test.exs`
  - add logical-font selection and compatibility assertions.
- `test/rendro_builders_test.exs`
  - add top-level registration/default builder coverage.
- `test/rendro/pipeline/measure_test.exs`
  - prove measurement consumes resolved font choice.
- `test/rendro/pdf/font_test.exs`
  - prove registry lookup / built-in definition behavior.
- `test/rendro/pdf/writer_test.exs`
  - prove writer consumes resolved font selection without exposing PDF internals publicly.

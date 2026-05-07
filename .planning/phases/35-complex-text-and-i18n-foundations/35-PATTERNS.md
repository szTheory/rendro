# Phase 35: Complex Text & i18n Foundations - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/pdf/font_subsetter.ex` | component | transform | `lib/rendro/pdf/font_parser.ex` | exact |
| `lib/rendro/text/shaper.ex` | service | transform | `lib/rendro/i18n/analyzer.ex` | exact |
| `lib/rendro/pipeline/build.ex` | pipeline | transform | `lib/rendro/pipeline/build.ex` | exact |
| `lib/rendro/pipeline/compose.ex` | pipeline | transform | `lib/rendro/pipeline/compose.ex` | exact |
| `lib/rendro/pipeline/measure.ex` | pipeline | transform | `lib/rendro/pipeline/measure.ex` | exact |

## Pattern Assignments

### `lib/rendro/pdf/font_subsetter.ex` (component, transform)

**Analog:** `lib/rendro/pdf/font_parser.ex`

**Binary Processing Pattern** (lines 17-38):
```elixir
  def parse(bytes) when is_binary(bytes) do
    with {:ok, version, num_tables, directory} <- parse_offset_table(bytes),
         :ok <- validate_version(version),
         {:ok, tables} <- parse_table_directory(directory, num_tables, bytes),
         # ...
         {:ok, base_font} <- parse_base_font_name(tables) do
      {:ok,
       %{
         base_font: base_font,
         units_per_em: units_per_em,
         widths: widths
       }}
    else
      {:error, _} = error -> error
      false -> {:error, :non_embeddable_font}
    end
  end
```

### `lib/rendro/text/shaper.ex` (service, transform)

**Analog:** `lib/rendro/i18n/analyzer.ex`

**Binary Traversal Pattern** (lines 11-25):
```elixir
  def analyze(text) when is_binary(text) do
    do_analyze(text, %{rtl: false, complex: false})
  end

  defp do_analyze(<<>>, state), do: to_diagnostics(state)

  # Optimization: if both found, short-circuit
  defp do_analyze(_, %{rtl: true, complex: true} = state), do: to_diagnostics(state)

  defp do_analyze(<<cp::utf8, rest::binary>>, state) do
    state
    |> check_rtl(cp)
    |> check_complex(cp)
    |> then(&do_analyze(rest, &1))
  end
```

### Pipeline Modifications (`build.ex`, `compose.ex`, `measure.ex`)

**Analog:** Current pipeline structure (`lib/rendro/pipeline/measure.ex`)

**Pipeline Mapping Pattern** (lines 9-16):
```elixir
  @spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
  def run(%Rendro.Document{} = doc) do
    with {:ok, pages} <- measure_pages(doc, doc.pages),
         {:ok, content} <- measure_content(doc, doc.content),
         {:ok, measured_doc} <- measure_layout(doc, doc.options[:layout]) do
      {:ok, %{measured_doc | pages: pages, content: content}}
    end
  end
```

**Collection Processing Pattern** (lines 352-358):
```elixir
  defp map_ok(enum, fun) do
    Enum.reduce_while(enum, {:ok, []}, fn item, {:ok, acc} ->
      case fun.(item) do
        {:ok, value} -> {:cont, {:ok, acc ++ [value]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end
```

## Shared Patterns

### Missing Glyphs & Telemetry Errors
**Source:** `lib/rendro/telemetry.ex`
**Apply to:** All pipeline stages (via error tuples)
```elixir
  # Exceptions/Warnings are passed up to be tracked by telemetry in the pipeline runner
  # Ensure specific error tuples are returned
  {:error, {:unsupported_glyph, grapheme}}
  {:error, {:unsupported_script, reason}}
```

## Metadata

**Analog search scope:** `lib/rendro/pdf`, `lib/rendro/text`, `lib/rendro/i18n`, `lib/rendro/pipeline`
**Files scanned:** 8
**Pattern extraction date:** 2024-05-24

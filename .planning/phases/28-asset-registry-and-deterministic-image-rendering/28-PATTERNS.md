# Phase 28: Asset Registry and Deterministic Image Rendering - Pattern Map

**Mapped:** 2024-05-01
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/asset_registry.ex` | registry | state container | `lib/rendro/font_registry.ex` | exact |
| `lib/rendro/image.ex` | model | AST node | `lib/rendro/text.ex` | exact |
| `lib/rendro/image_parser.ex` | utility | transform | `lib/rendro/pdf/font_parser.ex` | role-match |
| `lib/rendro/component.ex` | component | builder | (None) | N/A |
| `lib/rendro/document.ex` | model | state container | `lib/rendro/document.ex` (font_registry) | exact |
| `lib/rendro/pipeline/measure.ex` | service | transform | `lib/rendro/pipeline/measure.ex` (Text measure) | exact |

## Pattern Assignments

### `lib/rendro/asset_registry.ex` (registry, state container)

**Analog:** `lib/rendro/font_registry.ex`

**Struct and Type pattern** (lines 14-38):
```elixir
  @enforce_keys [:fonts, :default_font]
  defstruct fonts: %{@default_font => @helvetica_descriptor}, default_font: @default_font

  @type logical_name :: atom()
  @type t :: %__MODULE__{
          fonts: %{optional(logical_name()) => descriptor()},
          default_font: logical_name()
        }
```

**Registration pattern** (lines 66-80):
```elixir
  @doc """
  Registers a logical font name against an explicit embedded font source.
  """
  @spec register_embedded(t(), logical_name(), {:path, Path.t()} | {:binary, binary()}, keyword()) :: t()
  def register_embedded(%__MODULE__{} = registry, logical_name, source, opts \\ [])
      when is_atom(logical_name) and is_list(opts) do
    descriptor = embedded_descriptor(source, :regular)
    
    # ...

    %__MODULE__{registry | fonts: Map.put(registry.fonts, logical_name, descriptor)}
  end
```

**Resolution/Fetch pattern** (lines 114-118):
```elixir
  @doc """
  Fetches a registered logical font descriptor.
  """
  @spec fetch(t(), logical_name()) :: {:ok, descriptor()} | :error
  def fetch(%__MODULE__{} = registry, logical_name) when is_atom(logical_name) do
    Map.fetch(registry.fonts, logical_name)
  end
```

---

### `lib/rendro/image.ex` (model, AST node)

**Analog:** `lib/rendro/text.ex`

**Struct pattern** (lines 13-28):
```elixir
  @enforce_keys [:content]
  defstruct [
    :content,
    font: "Helvetica",
    size: 12,
    color: {0, 0, 0},
    line_height: 1.2
  ]

  @type t :: %__MODULE__{
          content: String.t(),
          font: font_ref(),
          size: number(),
          color: {non_neg_integer(), non_neg_integer(), non_neg_integer()},
          line_height: float()
        }
```
*Note for planner: Apply this to `Rendro.Image` requiring `logical_name`, `width`, `height`, and `fit`.*

---

### `lib/rendro/image_parser.ex` (utility, transform)

**Analog:** `lib/rendro/pdf/font_parser.ex`

**Binary Parsing / Transform Pattern** (lines 17-43):
```elixir
  @spec parse(binary()) ::
          {:ok,
           %{
             base_font: String.t(),
             # ...
           }}
          | {:error, term()}
  def parse(bytes) when is_binary(bytes) do
    with {:ok, version, num_tables, directory} <- parse_offset_table(bytes),
         :ok <- validate_version(version),
         {:ok, tables} <- parse_table_directory(directory, num_tables, bytes) do
      {:ok, %{ ... }}
    else
      {:error, _} = error -> error
    end
  end

  def parse(_bytes), do: {:error, :unsupported_font_source}
```

---

### `lib/rendro/document.ex` (model, state container)

**Analog:** `lib/rendro/document.ex` (existing font registry patterns)

**Struct Integration** (lines 43-48):
```elixir
  defstruct pages: [],
            # ...
            font_registry: Rendro.FontRegistry.new(),
            default_font: Rendro.FontRegistry.default_font(),
            # ...
```

**Document registration pipeline helper** (lines 115-126):
```elixir
  @doc """
  Registers a logical name against an explicit embedded font source.
  """
  @spec register_embedded_font(
          t(),
          Rendro.FontRegistry.logical_name(),
          {:path, Path.t()} | {:binary, binary()}
        ) :: t()
  def register_embedded_font(%__MODULE__{} = doc, logical_name, source)
      when is_atom(logical_name) do
    %__MODULE__{
      doc
      | font_registry: Rendro.FontRegistry.register_embedded(doc.font_registry, logical_name, source)
    }
  end
```

---

### `lib/rendro/pipeline/measure.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/measure.ex` (Text Measure)

**Measure Pattern** (lines 62-83):
```elixir
  defp measure_block(doc, %Rendro.Block{content: %Rendro.Text{} = text} = block, _container_width) do
    with [] <- Rendro.I18n.Analyzer.analyze(text.content),
         {:ok, font_chain} <- resolve_font_chain(doc, text),
         {:ok, lines} <- wrap_text(text.content, block.width, font_chain, text.size) do
      measured_width = measured_text_width(lines)
      width = block.width || measured_width
      measured_height = text.size * text.line_height * length(lines)
      height = block.height || measured_height

      measured_text = %MeasuredText{
        # ...
      }

      {:ok, %{block | content: measured_text, width: width, height: height}}
    else
      {:error, _} = err -> err
    end
  end
```
*Note for planner: Pattern should look up the `AssetRegistry` to pull intrinsic bounds, evaluate explicit bounds/fit, and calculate the resulting `width` and `height` of the block.*

## Shared Patterns

### Error Handling
**Source:** `lib/rendro/font_registry.ex`
**Apply to:** `lib/rendro/asset_registry.ex`
```elixir
defmodule Rendro.AssetRegistry.InvalidAssetError do
  defexception [:message, :logical_name, :reason]
  # exception structure mirrors Rendro.FontRegistry.EmbeddedFontFamilyError
end
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/rendro/component.ex` | component | builder | `Rendro.Component` only exposes `render_component`. We need to define `Rendro.image(logical_name, opts)` building a block directly from research doc suggestions. |

## Metadata

**Analog search scope:** `lib/rendro/**/*.ex`
**Files scanned:** 6
**Pattern extraction date:** 2024-05-01

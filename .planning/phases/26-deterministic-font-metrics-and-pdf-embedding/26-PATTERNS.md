# Phase 26: Deterministic Font Metrics and PDF Embedding - Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 15
**Analogs found:** 13 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/font_registry.ex` | model | request-response | `lib/rendro/font_registry.ex` | exact |
| `lib/rendro/document.ex` | model | request-response | `lib/rendro/document.ex` | exact |
| `lib/rendro.ex` | utility | request-response | `lib/rendro.ex` | exact |
| `lib/rendro/pipeline/build.ex` | utility | request-response | `lib/rendro/pipeline/build.ex` | exact |
| `lib/rendro/pipeline/measure.ex` | service | transform | `lib/rendro/pipeline/measure.ex` | exact |
| `lib/rendro/pipeline/measured_text.ex` | model | transform | `lib/rendro/pipeline/measured_text.ex` | exact |
| `lib/rendro/pipeline/paginate.ex` | service | transform | `lib/rendro/pipeline/paginate.ex` | exact |
| `lib/rendro/pdf/font.ex` | model | transform | `lib/rendro/pdf/font.ex` | exact |
| `lib/rendro/pdf/writer.ex` | service | request-response | `lib/rendro/pdf/writer.ex` | exact |
| `lib/rendro/pdf/object.ex` | utility | transform | `lib/rendro/pdf/object.ex` | exact |
| `lib/rendro/error.ex` | utility | request-response | `lib/rendro/error.ex` | exact |
| `lib/rendro/pdf/font_parser.ex` | utility | file-I/O | `lib/rendro/pdf/object.ex` + `lib/rendro/pdf/font.ex` | partial |
| `lib/rendro/pdf/embedded_font.ex` | model | transform | `lib/rendro/pdf/font.ex` | role-match |
| `test/rendro/pdf/font_test.exs` | test | transform | `test/rendro/pdf/font_test.exs` | exact |
| `test/rendro/pdf/writer_test.exs` | test | request-response | `test/rendro/pdf/writer_test.exs` | exact |

## Existing Analogs

### `lib/rendro/font_registry.ex` (registry seam to extend)

**Keep this as the single document-owned font store.** Phase 26 should extend descriptor shape here rather than inventing a parallel embedded-font registry.

**Registry/default pattern** (`lib/rendro/font_registry.ex:10-14`):
```elixir
  @default_font :default
  @helvetica_descriptor %{source: :built_in, family: :helvetica}

  @enforce_keys [:fonts, :default_font]
  defstruct fonts: %{@default_font => @helvetica_descriptor}, default_font: @default_font
```

**Shared resolver seam** (`lib/rendro/font_registry.ex:96-114`):
```elixir
  def resolve(%__MODULE__{} = registry, text_font_ref, document_default_font) do
    with {:ok, logical_name} <- normalize_reference(text_font_ref, document_default_font),
         {:ok, descriptor} <- fetch_descriptor(registry, logical_name) do
      {:ok, descriptor}
    end
  end

  def resolve_pdf_font(%__MODULE__{} = registry, text_font_ref, document_default_font) do
    with {:ok, logical_name} <- normalize_reference(text_font_ref, document_default_font),
         {:ok, descriptor} <- fetch_descriptor(registry, logical_name) do
      {:ok, built_in(descriptor, logical_name)}
    end
  end
```

**Stable resource naming seam** (`lib/rendro/font_registry.ex:124-156`):
```elixir
  def built_in(%{source: :built_in, family: :helvetica}, logical_name) do
    %Rendro.PDF.Font{Rendro.PDF.Font.helvetica() | name: resource_name(logical_name)}
  end

  defp resource_name(logical_name) do
    logical_name
    |> Atom.to_string()
    |> String.upcase()
    |> String.replace(~r/[^A-Z0-9]/u, "_")
    |> then(&"F_#{&1}")
  end
```

**Phase 26 recommendation:** preserve `resolve/3` and `resolve_pdf_font/3` as the only public resolution seams, but widen their return payload to a preflighted descriptor that can drive both metrics and embedding.

---

### `lib/rendro/document.ex` and `lib/rendro.ex` (public authoring boundary)

**Document-owned pure state** (`lib/rendro/document.ex:36-47`):
```elixir
  defstruct pages: [],
            content: [],
            page_templates: [],
            page_template: nil,
            sections: [],
            diagnostics: [],
            font_registry: Rendro.FontRegistry.new(),
            default_font: Rendro.FontRegistry.default_font(),
```

**Pure builder update style** (`lib/rendro/document.ex:136-154`):
```elixir
  def register_font(%__MODULE__{} = doc, logical_name, opts)
      when is_atom(logical_name) and is_list(opts) do
    %__MODULE__{
      doc
      | font_registry: Rendro.FontRegistry.register(doc.font_registry, logical_name, opts)
    }
  end

  def put_default_font(%__MODULE__{} = doc, logical_name) when is_atom(logical_name) do
    registry = Rendro.FontRegistry.put_default_font(doc.font_registry, logical_name)
    %__MODULE__{doc | font_registry: registry, default_font: registry.default_font}
  end
```

**Top-level wrapper pattern** (`lib/rendro.ex:79-90`):
```elixir
  def register_font(%Document{} = doc, logical_name, opts)
      when is_atom(logical_name) and is_list(opts) do
    Document.register_font(doc, logical_name, opts)
  end

  def put_default_font(%Document{} = doc, logical_name) when is_atom(logical_name) do
    Document.put_default_font(doc, logical_name)
  end
```

**Boundary normalization precedent** (`lib/rendro.ex:119-163`):
```elixir
  def text(content, attrs \\ []) do
    attrs
    |> normalize_text_attrs()
    |> Keyword.put(:content, content)
    |> then(&struct!(Text, &1))
  end
```

**Phase 26 recommendation:** add explicit embedded registration wrappers here, not an option overload on `register_font/3`. Match the existing pure-document update style.

---

### `lib/rendro/pipeline/build.ex` (earliest hard-failure seam)

**Stage gate pattern** (`lib/rendro/pipeline/build.ex:9-14`):
```elixir
  def run(%Rendro.Document{pages: pages} = doc) when is_list(pages) do
    case validate(doc) do
      :ok -> {:ok, normalize(doc)}
      {:error, _} = err -> err
    end
  end
```

**Current font validation seam** (`lib/rendro/pipeline/build.ex:101-115`):
```elixir
  defp validate_block_fonts(
         %Rendro.Document{font_registry: registry, default_font: default_font},
         %Rendro.Block{content: %Rendro.Text{font: font}}
       ) do
    case FontRegistry.resolve(registry, font, default_font) do
      {:ok, _descriptor} ->
        :ok

      {:error, {:unknown_logical_font, logical_name}} ->
        {:error, {:unknown_text_font, logical_name}}

      {:error, {:unsupported_font_reference, font_ref}} ->
        {:error, {:invalid_text_font, font_ref}}
    end
  end
```

**Recursive table validation seam** (`lib/rendro/pipeline/build.ex:117-146`):
```elixir
  defp validate_block_fonts(doc, %Rendro.Block{content: %Rendro.Table{} = table}) do
    with :ok <- validate_table_row_fonts(doc, table.header),
         :ok <- validate_table_rows_fonts(doc, table.rows) do
      :ok
    end
  end
```

**Phase 26 recommendation:** embedded-font parsing/readability/embeddability checks belong here or in a helper called from here. Preserve the “validate once, later stages consume resolved data” pattern from Phase 25.

---

### `lib/rendro/pipeline/measure.ex` and `lib/rendro/pipeline/measured_text.ex` (layout truth seam)

**Measure resolves once and stores resolved font** (`lib/rendro/pipeline/measure.ex:69-85`):
```elixir
  defp measure_block(doc, %Rendro.Block{content: %Rendro.Text{} = text} = block, _container_width) do
    with {:ok, font} <- resolve_font(doc, text) do
      lines = wrap_text(text.content, block.width, font, text.size)
      measured_width = measured_text_width(lines, font, text.size)
      width = block.width || measured_width
      measured_height = text.size * text.line_height * length(lines)
      height = block.height || measured_height

      measured_text = %MeasuredText{
        source: text,
        lines: lines,
        line_height: text.line_height,
        width: measured_width,
        height: measured_height,
        resolved_font: font
      }
```

**Resolver delegation seam** (`lib/rendro/pipeline/measure.ex:262-267`):
```elixir
  defp resolve_font(
         %Rendro.Document{font_registry: registry, default_font: default_font},
         %Rendro.Text{font: font}
       ) do
    FontRegistry.resolve_pdf_font(registry, font, default_font)
  end
```

**Measured text contract** (`lib/rendro/pipeline/measured_text.ex:4-13`):
```elixir
  @enforce_keys [:source, :lines, :line_height, :width, :height, :resolved_font]
  defstruct [:source, :lines, :line_height, :width, :height, :resolved_font]
```

**Wrapping algorithm seam to preserve** (`lib/rendro/pipeline/measure.ex:217-304`):
- `wrap_text/4`
- `wrap_segment/4`
- `split_chunk/4`
- `split_graphemes/4`
- `measured_text_width/3`

**Phase 26 recommendation:** do not split built-in and embedded measurement into separate codepaths. Preserve the exact wrapping pipeline and swap only the metrics source behind `Font.text_width/3` or its equivalent.

---

### `lib/rendro/pipeline/paginate.ex` (proof that measured lines affect pagination)

**MeasuredText survives pagination mutations** (`lib/rendro/pipeline/paginate.ex:373-397`):
```elixir
        %Rendro.Pipeline.MeasuredText{source: %Rendro.Text{content: text} = source} = measured ->
          replaced = String.replace(text, "{{page_number}}", Integer.to_string(page_num))

          %{
            block
            | content: %{
                measured
                | source: %{source | content: replaced},
                  lines:
                    Enum.map(measured.lines, fn line ->
                      String.replace(line, "{{page_number}}", Integer.to_string(page_num))
                    end)
              }
          }
```

**Height-driven pagination seam** (`lib/rendro/pipeline/paginate.ex:131-132`, `636-638`):
```elixir
    block_h = block.height || 0
    current_h = Enum.sum(Enum.map(current_page.blocks, &(&1.height || 0)))
```
```elixir
    header_h = table.header_height || 0
    rows_h = if table.row_heights, do: Enum.sum(table.row_heights), else: 0
```

**Phase 26 recommendation:** any change to metrics payload must preserve `MeasuredText.height`, `MeasuredText.lines`, and table row height semantics, because paginate consumes those values as layout truth.

---

### `lib/rendro/pdf/font.ex` (font metrics container analog)

**Current shape** (`lib/rendro/pdf/font.ex:10-16`):
```elixir
  @type t :: %__MODULE__{
          name: String.t(),
          base_font: String.t(),
          widths: %{non_neg_integer() => non_neg_integer()}
        }

  defstruct [:name, :base_font, widths: %{}]
```

**Metrics consumer API** (`lib/rendro/pdf/font.ex:117-132`):
```elixir
  def helvetica do
    %__MODULE__{
      name: "F1",
      base_font: "Helvetica",
      widths: @helvetica_widths
    }
  end

  def text_width(%__MODULE__{widths: widths}, text, font_size) do
```

**Phase 26 recommendation:** this is the best analog for a generalized resolved-font metrics struct. If embedding metadata is added, keep measurement-facing metrics data adjacent to writer-facing font identity in one resolved payload.

---

### `lib/rendro/pdf/writer.ex` (embedding seam)

**Writer resolves/collects fonts before object allocation** (`lib/rendro/pdf/writer.ex:22-24`, `228-239`):
```elixir
  def render(%Rendro.Document{} = doc, opts) when is_list(opts) do
    with {:ok, fonts} <- collect_fonts(doc),
         {numbered_objects, catalog_num, info_num, total_objects} <- build_objects(doc, fonts, opts) do
```
```elixir
  defp collect_fonts(%Rendro.Document{pages: pages} = doc) do
    pages
    |> Enum.reduce_while({:ok, %{}}, fn page, {:ok, acc} ->
      case collect_page_fonts(doc, page, acc) do
```

**Current built-in font object seam** (`lib/rendro/pdf/writer.ex:102-114`):
```elixir
  defp build_font_objects(font_object_refs, opts) do
    Enum.map(font_object_refs, fn {font, obj_num} ->
      font_dict =
        {:dict,
         [
           {"Type", {:name, "Font"}},
           {"Subtype", {:name, "Type1"}},
           {"BaseFont", {:name, font.base_font}}
         ]}
```

**MeasuredText parity seam** (`lib/rendro/pdf/writer.ex:196-205`):
```elixir
  defp render_block(_doc, %Rendro.Block{content: %MeasuredText{} = text} = block, page, font_map, ox, oy) do
    render_text_block(block, page, ox, oy, text.source, text.lines, text.line_height, text.resolved_font, font_map)
  end
```

**Text emission seam** (`lib/rendro/pdf/writer.ex:199-219`):
```elixir
  defp render_text_block(block, page, ox, oy, text, lines, line_height, font, font_map) do
    x = block.x + ox + page.margin_left
    y = page.height - (block.y + oy) - page.margin_top - text.size
    {r, g, b} = text.color
    color_op = "#{format_num(r / 255)} #{format_num(g / 255)} #{format_num(b / 255)} rg"
    line_offset = text.size * line_height
    font_name = resolved_font_name(font, font_map)
```

**Resource-name fallback to remove for explicit embedded fonts** (`lib/rendro/pdf/writer.ex:306-311`):
```elixir
  defp resolved_font_name(font, font_map) do
    case Map.fetch(font_map, font.name) do
      {:ok, _font_ref} -> font.name
      :error -> Font.helvetica().name
    end
  end
```

**Phase 26 recommendation:** preserve the collect-allocate-render order, but replace the Type1-only object builder with descriptor-driven font object emission. For explicit embedded fonts, `resolved_font_name/2` should never silently fall back.

---

### `lib/rendro/pdf/object.ex` (new parser/embedding helper style analog)

**Pure PDF serialization helper style** (`lib/rendro/pdf/object.ex:1-88`):
```elixir
defmodule Rendro.PDF.Object do
  @moduledoc """
  PDF value type serialization per PDF 1.4 spec.
  """
```
```elixir
  def serialize({:stream, dict_entries, data}, opts)
      when is_list(dict_entries) and is_binary(data) do
    entries_with_length = dict_entries ++ [{"Length", byte_size(data)}]
```

**Phase 26 recommendation:** any new PDF embedding helper should look like this module: pure functions, explicit binary input/output, no ambient IO, and narrow PDF-domain responsibility.

---

### `lib/rendro/error.ex` (typed-error vocabulary seam)

**Stage-specific error contract** (`lib/rendro/error.ex:23-38`):
```elixir
  def from_stage(stage, reason, context \\ %{}) when is_atom(stage) do
    %__MODULE__{
      what: what(stage, reason),
      where: "Rendro.Pipeline.#{stage_module_suffix(stage)}",
      why: why(reason),
      next: next_step(stage, reason),
```

**Current build/measure/render messaging pattern** (`lib/rendro/error.ex:48-99`):
- `what/2` branches by stage
- `next_step/2` branches by stage + reason

**Phase 26 recommendation:** if embedded-font preflight adds new error atoms, extend this module so operators get logical font name, source kind, and fix guidance without PDF internals.

## Recommended File Roles

| File | Recommended Role In Phase 26 | Why It Fits |
|---|---|---|
| `lib/rendro/font_registry.ex` | descriptor registry + resolver | Existing single source of truth for logical font resolution. |
| `lib/rendro/document.ex` | document-owned registration storage | Public authored state already lives here. |
| `lib/rendro.ex` | explicit embedded-font wrappers | Current public builder entrypoint. |
| `lib/rendro/pipeline/build.ex` | embedded-font preflight gate | Current earliest deterministic failure boundary. |
| `lib/rendro/pipeline/measure.ex` | metrics consumer | Already turns resolved fonts into widths, lines, heights. |
| `lib/rendro/pipeline/measured_text.ex` | parity carrier | Already moves resolved font from measure to writer. |
| `lib/rendro/pdf/font.ex` | resolved metrics/identity payload | Best existing analog for font-domain data. |
| `lib/rendro/pdf/writer.ex` | PDF embedding/object assembly | Owns font collection, resource maps, and object allocation. |
| `lib/rendro/pdf/font_parser.ex` | new pure parser helper | Best fit for TTF/OTF byte parsing and metrics extraction from normalized bytes. |
| `lib/rendro/pdf/embedded_font.ex` | new embedded descriptor/helper | Best fit for encapsulating parsed metrics + embeddable binary + PDF subtype info. |

## New Helper Recommendations

### `lib/rendro/pdf/font_parser.ex`

**Recommended role:** utility, `file-I/O` at the boundary and `transform` after bytes are loaded.

**Preserve these repo patterns:**
- Keep filesystem reads out of the parser itself. `Build` or `Document` should normalize `{:path, path}` into bytes first.
- Return pure data or typed errors, not writer objects.
- Match `Rendro.PDF.Object` in style: small explicit functions over binaries.

**Closest seams to copy:**
- `lib/rendro/pipeline/build.ex:101-146` for early validation structure.
- `lib/rendro/pdf/object.ex:1-88` for pure binary transform style.
- `lib/rendro/pdf/font.ex:10-132` for font-domain data shaping.

### `lib/rendro/pdf/embedded_font.ex`

**Recommended role:** model/helper for the resolved embedded-font payload consumed by both `Measure` and `Writer`.

**Suggested payload responsibilities:**
- logical font resource name
- PDF base/subtype data needed by writer
- widths / ascent / descent / units-per-em or equivalent normalized metrics
- original owned bytes ready for embedding
- embeddability/preflight flags already decided

**Closest seam to copy:**
- `lib/rendro/pdf/font.ex:10-132` for a compact struct + narrow API surface.

## Test Surfaces To Extend

| Test File | Existing Proof Surface | Phase 26 Extension |
|---|---|---|
| `test/rendro/document_test.exs` | registry/default-font purity and immutability | Add embedded registration helpers, path-vs-binary normalization behavior, and document-owned pure-data storage assertions. |
| `test/rendro/pdf/font_test.exs` | shared resolver and unknown-font validation | Add parser/preflight tests for unsupported format, missing metrics, non-embeddable font, and resolved embedded descriptor shape. |
| `test/rendro/pipeline/measure_test.exs` | resolved font reaches measurement and wrapping is deterministic | Add custom embedded-font width/line-break tests to prove metrics change layout deterministically. |
| `test/rendro/pdf/writer_test.exs` | logical font resource naming and rendered PDF structure | Add embedded font object/resource assertions, font stream presence, and no-fallback behavior for explicit embedded fonts. |
| `test/rendro/deterministic_test.exs` | deterministic writer binary checks | Keep only narrow regression checks here; add layout-parity assertions rather than making full-byte identity the main proof. |
| `test/rendro/pipeline/paginate_test.exs` | page-height and row-height driven pagination | Add page-break parity tests using embedded fonts with different metrics to prove paginate follows measured output. |

## Shared Patterns To Preserve

### One Resolver, All Stages
**Source:** `lib/rendro/font_registry.ex:96-114`

`Build`, `Measure`, and `Writer` should continue to resolve through one shared contract. Phase 26 should widen the resolved payload, not duplicate resolution logic per stage.

### Fail Early At Build
**Source:** `lib/rendro/pipeline/build.ex:18-146`

Explicit font failures should surface before measure/paginate/render. Preserve the current `{:error, reason}` stage style and extend it for unreadable, unsupported, or non-embeddable custom fonts.

### MeasuredText Carries Render Truth
**Source:** `lib/rendro/pipeline/measured_text.ex:4-13`, `lib/rendro/pdf/writer.ex:196-205`

Writer should continue preferring `MeasuredText.resolved_font` over re-resolving text ad hoc. This is the key seam that preserves layout/render parity.

### Pure Data, No Ambient Environment
**Source:** `lib/rendro/document.ex:36-47`, `lib/rendro/pdf/object.ex:1-88`

Do not let writer/parser depend on temp files, OS font lookup, or runtime-global font caches. Normalize external state into document-owned bytes before later stages.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/rendro/pdf/font_parser.ex` | utility | file-I/O | No existing binary parser module for external asset formats exists yet; closest analog is pure serializer style in `lib/rendro/pdf/object.ex`. |
| `lib/rendro/pdf/embedded_font.ex` | model | transform | No existing embedded-font payload exists; closest analog is the built-in metrics carrier in `lib/rendro/pdf/font.ex`. |

## Metadata

**Analog search scope:** `lib/rendro/**/*.ex`, `test/rendro/**/*.exs`, `.planning/phases/25-*`, `.planning/phases/26-*`
**Key seams preserved:** document-owned registry, `Build` preflight, `MeasuredText` parity, writer-side font collection/object allocation, paginate height consumption
**Pattern extraction date:** 2026-04-30

# Phase 19: Deterministic Text Flow and Break Semantics - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/block.ex` | model | request-response | `lib/rendro/block.ex` | exact |
| `lib/rendro/text.ex` | model | request-response | `lib/rendro/text.ex` | exact |
| `lib/rendro.ex` | utility | request-response | `lib/rendro.ex` | exact |
| `lib/rendro/pipeline/measure.ex` | service | transform | `lib/rendro/pipeline/measure.ex` | exact |
| `lib/rendro/pipeline/paginate.ex` | service | transform | `lib/rendro/pipeline/paginate.ex` | exact |
| `lib/rendro/pdf/writer.ex` | service | transform | `lib/rendro/pdf/writer.ex` | exact |
| `lib/rendro/error.ex` | utility | transform | `lib/rendro/error.ex` | exact |
| `test/rendro/flow_test.exs` | test | request-response | `test/rendro/flow_test.exs` | exact |
| `test/rendro/pipeline/measure_test.exs` | test | transform | `test/rendro/pipeline/measure_test.exs` | exact |
| `test/rendro/pipeline/paginate_test.exs` | test | transform | `test/rendro/pipeline/paginate_test.exs` | exact |
| `test/rendro/pdf/writer_test.exs` | test | transform | `test/rendro/pdf/writer_test.exs` | exact |
| `README.md` | utility | transform | `README.md` | exact |
| `guides/integrations.md` | utility | transform | `guides/integrations.md` | exact |

## Pattern Assignments

### `lib/rendro/block.ex` (model, request-response)

**Analog:** `lib/rendro/block.ex`

**Struct/type pattern** (lines 6-21):
```elixir
@enforce_keys [:content]
defstruct [
  :content,
  x: 0,
  y: 0,
  width: nil,
  height: nil
]

@type t :: %__MODULE__{
        content: Rendro.Text.t() | Rendro.Table.t() | term(),
        x: number(),
        y: number(),
        width: number() | nil,
        height: number() | nil
      }
```
Copy this shape when adding block-level break directives: extend `defstruct` and `@type` in-place, keep geometry and page-intent on `Block`.

### `lib/rendro/text.ex` (model, request-response)

**Analog:** `lib/rendro/text.ex`

**Leaf style pattern** (lines 6-19):
```elixir
@enforce_keys [:content]
defstruct [
  :content,
  font: "Helvetica",
  size: 12,
  color: {0, 0, 0}
]
```
Add any wrapped-text styling here, not on `Block`. Follow the existing leaf-content style: one small struct, defaults in `defstruct`, mirrored in `@type`.

### `lib/rendro.ex` (utility, request-response)

**Analog:** `lib/rendro.ex`

**Builder pattern** (lines 80-87):
```elixir
@spec block(Text.t() | term(), keyword()) :: Block.t()
def block(content, attrs \\ []) do
  struct!(Block, Keyword.put(attrs, :content, content))
end

@spec text(String.t(), keyword()) :: Text.t()
def text(content, attrs \\ []) do
  struct!(Text, Keyword.put(attrs, :content, content))
end
```
If Phase 19 exposes new public fields or helper docs, keep the builder surface as `struct!` wrappers with narrow specs and no pipeline leakage.

### `lib/rendro/pipeline/measure.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/measure.ex`

**Stage entry + alias pattern** (lines 12-23):
```elixir
alias Rendro.PDF.Font
alias Rendro.Region

@spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
def run(%Rendro.Document{} = doc) do
  font = Font.helvetica()

  doc
  |> measure_pages(font)
  |> measure_content(font)
  |> measure_layout(font)
end
```

**Text measurement hook** (lines 57-60):
```elixir
defp measure_block(%Rendro.Block{content: %Rendro.Text{} = text} = block, font) do
  width = block.width || Font.text_width(font, text.content, text.size)
  height = block.height || text.size * 1.2
  %{block | width: width, height: height}
end
```

**Layout propagation pattern** (lines 69-93):
```elixir
measured_region_blocks =
  Enum.into(layout.region_blocks, %{}, fn {name, blocks} ->
    {name, Enum.map(blocks, &measure_block(&1, font))}
  end)
```
Implement wrapping here by extending `measure_block/2` for `%Rendro.Text{}` and preserving the existing measured-layout propagation into `doc.content`, `doc.header`, and `doc.footer`.

### `lib/rendro/pipeline/paginate.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/paginate.ex`

**Stage routing pattern** (lines 14-20):
```elixir
@spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
def run(%Document{pages: pages, content: content} = doc) do
  cond do
    pages != [] -> validate_fixed_pages(doc)
    content != [] or has_flow_layout?(doc) -> paginate_flow(doc)
    true -> {:error, :no_content}
  end
end
```

**Typed overflow catch pattern** (lines 30-49):
```elixir
try do
  pages =
    body_blocks
    |> Enum.reduce([%{page_template | blocks: []}], fn block, pages ->
      paginate_block(block, pages, page_template, max_h, %{overflow_source: :bounded_region, region: :body})
    end)

  {:ok, %{doc | pages: pages, content: []}}
catch
  {:error, :content_overflow, details} ->
    {:error, Rendro.Error.from_stage(:paginate, :content_overflow, %{details: details})}
end
```

**Fit/fail pattern** (lines 107-137, 176-189):
```elixir
if current_h + block_h <= max_h do
  [%{current_page | blocks: current_page.blocks ++ [block]} | rest]
else
  check_overflow!(block, block_h, max_h, failure_details)
  [%{template | blocks: [block]}, current_page | rest]
end
```
```elixir
defp check_overflow!(block, block_h, max_h, overflow_details) do
  if block_h > max_h do
    throw(
      {:error, :content_overflow,
       Map.merge(
         %{block_height: block_h, max_height: max_h, block: block_rect(block)},
         overflow_details
       )}
    )
  end
end
```
Keep break/keep evaluation inside this stage, after heights are final, and continue using typed throw/catch details instead of raw raises.

### `lib/rendro/pdf/writer.ex` (service, transform)

**Analog:** `lib/rendro/pdf/writer.ex`

**Page stream assembly pattern** (lines 137-139):
```elixir
defp build_content_stream(%Rendro.Page{} = page, font) do
  Enum.map_join(page.blocks, "\n", fn block -> render_block(block, page, font) end)
end
```

**Text serialization pattern** (lines 163-179):
```elixir
defp render_block(%Rendro.Block{content: %Rendro.Text{} = text} = block, page, _font, ox, oy) do
  x = block.x + ox + page.margin_left
  y = page.height - (block.y + oy) - page.margin_top - text.size

  [
    "BT",
    color_op,
    "/F1 #{format_num(text.size)} Tf",
    "#{format_num(x)} #{format_num(y)} Td",
    "(#{escape_pdf_string(text.content)}) Tj",
    "ET"
  ]
  |> Enum.join("\n")
end
```
Preserve the current writer contract: page-local deterministic coordinates, explicit PDF operators, and no re-measurement at render time. Wrapped text should render from measured lines, not from ad hoc string splitting here.

### `lib/rendro/error.ex` (utility, transform)

**Analog:** `lib/rendro/error.ex`

**Structured error pattern** (lines 9-10, 23-41):
```elixir
@enforce_keys [:what, :where, :why, :next, :stage]
defstruct [:what, :where, :why, :next, :stage, :reason, :render_id, details: %{}]
```
```elixir
def from_stage(stage, reason, context \\ %{}) when is_atom(stage) do
  %__MODULE__{
    what: what(stage, reason),
    where: "Rendro.Pipeline.#{stage_module_suffix(stage)}",
    why: why(reason),
    next: next_step(stage, reason),
    stage: stage,
    reason: reason,
    render_id: Map.get(context, :render_id),
    details:
      Map.merge(
        %{document_type: Map.get(context, :document_type), deterministic: Map.get(context, :deterministic)},
        Map.get(context, :details, %{})
      )
  }
end
```

**Paginate guidance text** (lines 74-76):
```elixir
defp next_step(:paginate, :content_overflow) do
  "Reduce content size or expand the declared page/region bounds; Rendro does not auto-fit overflowing content."
end
```
Enrich keep-rule failures by adding fields under `details`; do not create a separate top-level error family.

### `test/rendro/flow_test.exs` (test, request-response)

**Analog:** `test/rendro/flow_test.exs`

**End-to-end render proof pattern** (lines 6-25):
```elixir
content =
  for i <- 1..50 do
    Rendro.block(Rendro.text("Line #{i}"))
  end

doc = Rendro.flow(content)
{:ok, pdf} = Rendro.render(doc)

assert pdf =~ "Line 1"
assert pdf =~ "Line 50"
assert length(Regex.scan(~r"/Type\s*/Page\b", pdf)) == 2
```

**Truthful error proof pattern** (lines 221-258):
```elixir
assert {:error, %Rendro.Error{} = error} = Rendro.render(doc)
assert error.stage == :paginate
assert error.reason == :content_overflow
assert error.details.overflow_source == :bounded_region
assert error.details.region == :body
```
Add public-contract tests here for wrapped flow text and block-level keep/break semantics through `Rendro.render/1`.

### `test/rendro/pipeline/measure_test.exs` (test, transform)

**Analog:** `test/rendro/pipeline/measure_test.exs`

**Direct stage proof pattern** (lines 9-36):
```elixir
text = %Rendro.Text{content: "Hello", font: "Helvetica", size: 12, color: {0, 0, 0}}
block = %Rendro.Block{content: text, x: 0, y: 0, width: nil, height: nil}
page = %Rendro.Page{blocks: [block]}
doc = %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{}}

assert {:ok, result} = Measure.run(doc)
```
Use this file for deterministic line-break and final-height proofs: explicit newlines, width-constrained wrapping, long-token fallback, and preservation of authored width.

### `test/rendro/pipeline/paginate_test.exs` (test, transform)

**Analog:** `test/rendro/pipeline/paginate_test.exs`

**Pipeline-stage setup pattern** (lines 116-120, 147-150):
```elixir
{:ok, doc} = Build.run(doc)
{:ok, doc} = Compose.run(doc)
{:ok, doc} = Measure.run(doc)
assert {:ok, paginated} = Paginate.run(doc)
```

**Overflow details assertion pattern** (lines 58-66):
```elixir
assert {:error, %Rendro.Error{} = error} = Paginate.run(doc)
assert error.stage == :paginate
assert error.reason == :content_overflow
assert error.details.overflow_source == :fixed_page
assert error.details.page_index == 1
assert error.details.block_index == 0
```
Add keep-group movement and impossible-layout failures here. This file already proves page geometry and stage-local pagination behavior.

### `test/rendro/pdf/writer_test.exs` (test, transform)

**Analog:** `test/rendro/pdf/writer_test.exs`

**Writer surface proof pattern** (lines 71-77, 133-152):
```elixir
{:ok, pdf} = Writer.render(sample_document())
assert pdf =~ "/F1"
assert pdf =~ "Tf"
assert pdf =~ "Td"
assert pdf =~ "(Hello, Rendro!) Tj"
```
```elixir
expected_x = 10 + 72
expected_y = 792 - 20 - 72 - 14

assert pdf =~ "#{expected_x} #{expected_y} Td"
```
Extend this file to prove multi-line content stream emission and stable coordinates for measured wrapped lines.

### `README.md` (utility, transform)

**Analog:** `README.md`

**Executable docs-contract pattern** (lines 14-28, 98-109):
```elixir
# docs-contract: readme-flow-compile
data = %{...}

doc = Rendro.Recipes.invoice(data)
{:ok, _pdf} = Rendro.render(doc)
```
```elixir
# docs-contract: readme-policies-compile
_doc = Rendro.flow([], options: %{policies: [max_pages: 50, max_bytes: 1_000_000, timeout: 5_000]})
```
Keep Phase 19 README examples executable, builder-first, and truthful about scope boundaries.

### `guides/integrations.md` (utility, transform)

**Analog:** `guides/integrations.md`

**Truthful docs posture pattern** (lines 12-13, 138-140, 273-279):
```markdown
This guide walks through enabling each adapter, verifying it works end-to-end, and
interpreting the failure modes your code may encounter.
```
```markdown
The failure-path example below is intentionally schematic. Its public contract is
pinned by direct ExUnit semantic tests instead of by a compile-only docs lane.
```
```markdown
`attach_pdf/3` never raises. All failure paths return `{:error, _}`:
```
If this guide changes, follow its existing contract style: explicit scope, schematic-vs-executable honesty, and direct failure-mode tables.

## Shared Patterns

### Public Builder Surface
**Source:** `lib/rendro.ex` lines 39-97  
**Apply to:** `lib/rendro.ex`, README examples
```elixir
@doc """
Creates a flow document from a list of content blocks.
"""
@spec flow([Block.t()], keyword()) :: Document.t()
def flow(content, opts \\ []) do
  document(Keyword.put(opts, :content, content))
end
```

### Small Struct Modules
**Source:** `lib/rendro/block.ex` lines 6-21, `lib/rendro/text.ex` lines 6-19  
**Apply to:** `lib/rendro/block.ex`, `lib/rendro/text.ex`
```elixir
@enforce_keys [:content]
defstruct [...]
@type t :: %__MODULE__{...}
```

### Stage Return Convention
**Source:** `lib/rendro/pipeline/measure.ex` lines 15-23, `lib/rendro/pipeline/paginate.ex` lines 14-20  
**Apply to:** `Measure`, `Paginate`
```elixir
@spec run(Rendro.Document.t()) :: {:ok, Rendro.Document.t()} | {:error, term()}
```

### Typed Overflow/Error Plumbing
**Source:** `lib/rendro/pipeline/paginate.ex` lines 46-49, 176-189; `lib/rendro/error.ex` lines 23-41  
**Apply to:** `Paginate`, `Error`, end-to-end tests
```elixir
{:error, :content_overflow, details}
{:error, Rendro.Error.from_stage(:paginate, :content_overflow, %{details: details})}
```

### Full-Pipeline Test Setup
**Source:** `test/rendro/pipeline/paginate_test.exs` lines 116-120  
**Apply to:** pagination and writer proofs that depend on measured flow behavior
```elixir
{:ok, doc} = Build.run(doc)
{:ok, doc} = Compose.run(doc)
{:ok, doc} = Measure.run(doc)
assert {:ok, paginated} = Paginate.run(doc)
```

### Docs Contract Honesty
**Source:** `README.md` lines 16-17; `guides/integrations.md` lines 138-140  
**Apply to:** README and guide updates
```markdown
Verified by the README compile/eval lane in `mix docs.contract`.
```
```markdown
The failure-path example below is intentionally schematic.
```

## No Analog Found

None. Phase 19 extends existing flow-engine, writer, diagnostics, and docs surfaces rather than introducing a new subsystem.

## Metadata

**Analog search scope:** `lib/rendro`, `lib/rendro/pipeline`, `lib/rendro/pdf`, `test/rendro`, repo-root docs  
**Files scanned:** 13 primary analog files, plus phase `19-CONTEXT.md` and `19-RESEARCH.md`  
**Pattern extraction date:** 2026-04-29

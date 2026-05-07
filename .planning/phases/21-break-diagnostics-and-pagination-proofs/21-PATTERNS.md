# Phase 21: Break Diagnostics and Pagination Proofs - Pattern Map

**Mapped:** 2024-04-29 (or current date)
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/document.ex` | model | transform | `lib/rendro/document.ex` | exact |
| `lib/rendro/inspector.ex` | utility | transform | `lib/rendro/error.ex` | role-match |
| `lib/rendro/pipeline/measure.ex` | service | transform | `lib/rendro/pipeline/measure.ex` | exact |
| `lib/rendro/pipeline/paginate.ex` | service | transform | `lib/rendro/pipeline/paginate.ex` | exact |
| `test/rendro/inspector_test.exs` | test | request-response | `test/rendro/error_test.exs` | role-match |

## Pattern Assignments

### `lib/rendro/document.ex` (model, transform)

**Analog:** `lib/rendro/document.ex`

**Struct definition pattern** (lines 7-18):
```elixir
  @enforce_keys []
  defstruct pages: [],
            content: [],
            page_templates: [],
            page_template: nil,
            sections: [],
            header: [],
            footer: [],
            metadata: %Rendro.Metadata{},
            options: %{}
```
*Note: Planner should append `diagnostics: []` to `defstruct` and `@type t` to support structured diagnostics (OBS-05).*

---

### `lib/rendro/inspector.ex` (utility, transform)

**Analog:** `lib/rendro/error.ex`

**String formatting pattern** (lines 80-92):
```elixir
defimpl String.Chars, for: Rendro.Error do
  def to_string(error) do
    """
    Rendro Error in #{error.stage} stage:

    What:  #{error.what}
    Where: #{error.where}
    Why:   #{error.why}

    Next:  #{error.next}
    """
  end
end
```
*Note: Implement an equivalent ASCII text tree serializer for `%Rendro.Document{}` that includes `diagnostics`, bounding boxes, and structural types (QUAL-06).*

---

### `lib/rendro/pipeline/paginate.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/paginate.ex`

**Pipeline data modification pattern** (lines 23-44):
```elixir
  defp paginate_flow(%Document{} = doc) do
    layout = flow_layout(doc)
    # ...
    try do
      pages =
        paginate_blocks(...)
        # ...
      {:ok, %{doc | pages: pages, content: []}}
    catch
      {:error, :content_overflow, details} ->
        {:error, Rendro.Error.from_stage(:paginate, :content_overflow, %{details: details})}
    end
  end
```
*Note: Ensure non-fatal overflow/split diagnostics are appended to `doc.diagnostics` within this flow.*

---

### `test/rendro/inspector_test.exs` (test, request-response)

**Analog:** `test/rendro/error_test.exs`

**Test structure pattern** (lines 1-19):
```elixir
defmodule Rendro.ErrorTest do
  use ExUnit.Case, async: true

  test "from_stage/3 builds actionable diagnostics" do
    error =
      Rendro.Error.from_stage(:build, :no_pages, %{
        render_id: "render-123",
        deterministic: true,
        document_type: :pdf
      })

    assert error.stage == :build
    assert error.reason == :no_pages
    assert error.render_id == "render-123"
    assert error.where == "Rendro.Pipeline.Build"
    assert error.what =~ "validation"
    assert error.why == "no pages"
    assert error.next =~ "Add at least one page"
    assert error.details == %{document_type: :pdf, deterministic: true}
  end
```
*Note: Adapt this to construct a `%Rendro.Document{}` with diagnostics and assert its exact string representation using an ExUnit snapshot via `Rendro.Inspector`.*

## Shared Patterns

### Structured Diagnostics Map
**Apply to:** `lib/rendro/pipeline/measure.ex`, `lib/rendro/pipeline/paginate.ex`
- Instead of purely throwing errors on breaks, structural changes (like table splits) should emit a map (e.g. `%{level: :info, type: :table_split, page: 2, block_id: "tbl-1", reason: :insufficient_height}`) to `doc.diagnostics`. 

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `ExUnit Snapshot Library` | test | - | Standard ExUnit lacks native snapshot testing similar to Jest. The planner will need to implement a simple fixture serialization comparison or use an external snapshot library (like `Mneme` if researched) for the `Rendro.Inspector` output. |

## Metadata

**Analog search scope:** `lib/rendro/**/*.ex`, `test/rendro/**/*.exs`
**Files scanned:** 5
**Pattern extraction date:** 2024-04-29
# Phase 22: Authoring Ergonomics and Canonical Recipes - Pattern Map

**Mapped:** 2024-04-29 (approx based on context)
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/recipes/invoice.ex` | component/recipe | transform/compose | `lib/rendro/recipes.ex` | role-match |
| `lib/rendro/document.ex` | model/builder | transform/compose | `lib/rendro.ex` (top-level functions) | partial |
| `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` | controller | request-response | `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` | exact |
| `test/rendro/recipes/invoice_test.exs` | test | transform/compose | `test/rendro/document_test.exs` | role-match |

## Pattern Assignments

### `lib/rendro/recipes/invoice.ex` (component/recipe, transform/compose)

**Analog:** `lib/rendro/recipes.ex`

**Imports and Core Pattern** (lines 10-41):
Currently, recipes are just standalone functions. Phase 22 mandates "Tiered Composition":
- `document(data, opts)`
- `page_template(opts)`
- `sections(data, opts)`

The closest existing pattern is the simple flow creation:
```elixir
  def invoice(data) do
    header = [
      Rendro.block(Rendro.text("INVOICE ##{data.id}", size: 18))
    ]
    # ...
    Rendro.flow(
      [
        Rendro.block(Rendro.text("Date: #{data.date}")),
        Rendro.block(table)
      ],
      header: header,
      footer: footer
    )
  end
```
*Note: The new invoice recipe will expand this into discrete, composable functions rather than returning a monolithic `Rendro.flow`.*

---

### `lib/rendro/document.ex` (model/builder, transform/compose)

**Analog:** `lib/rendro.ex` (for document construction helpers)

**Core Builder Pattern** (lines 44-53 of `lib/rendro.ex`):
Currently, documents are created via static struct assignment. We need to introduce a pipeline builder API.
```elixir
  @doc """
  Creates a flow document from a list of content blocks.
  """
  @spec flow([Block.t()], keyword()) :: Document.t()
  def flow(content, opts \\ []) do
    document(Keyword.put(opts, :content, content))
  end

  @spec document(keyword()) :: Document.t()
  def document(attrs \\ []) do
    struct!(Document, attrs)
  end
```
*Note: In `Rendro.Document`, this will become a pipeable API: `new() |> put_metadata(...) |> add_template(...) |> add_section(...)`.*

---

### `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` (controller, request-response)

**Analog:** `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex`

**Phoenix Controller Ergonomics** (lines 4-11):
We want to keep this seamless integration but use the new Recipe and Builder APIs.
```elixir
  def download(conn, _params) do
    doc = Rendro.flow([
      Rendro.block(Rendro.text("Hello from Phoenix Example!"))
    ])

    RendroPhoenix.render_pdf(conn, doc, "example.pdf")
  end
```

---

### `test/rendro/recipes/invoice_test.exs` (test, transform/compose)

**Analog:** `test/rendro/document_test.exs`

**AST-Based Testing Ergonomics** (lines 17-36 of `test/rendro/document_test.exs`):
Rather than asserting on binary PDFs (as seen in `flow_test.exs`), test the document AST structure.
```elixir
    test "creates with all fields" do
      page = %Page{}
      meta = %Metadata{title: "Test"}
      template = %PageTemplate{name: :invoice}
      section = %Section{name: :summary, region: :body}

      doc = %Document{
        # ... struct fields
      }

      assert doc.sections == [section]
      assert doc.metadata.title == "Test"
      assert doc.options.deterministic == true
    end
```

## Shared Patterns

### React-PDF Mental Model
**Source:** N/A (New Paradigm)
**Apply to:** All new `Rendro.Recipes`
Users are encouraged to write small functions that return `[%Rendro.Block{}]` or `%Rendro.Section{}`, allowing deep composability without managing stateful layout cursors.

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `guides/authoring.md` | guide | documentation | We are introducing a fundamentally new "batteries-included" DX and React-PDF mental model not captured in current guides. |

## Metadata

**Analog search scope:** `lib/rendro/`, `examples/phoenix_example/`, `test/rendro/`
**Files scanned:** ~30
**Pattern extraction date:** 2024-04-29

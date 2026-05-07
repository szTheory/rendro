# Phase 18: Layout Contract and Page Template Model - Pattern Map

**Mapped:** 2026-04-28
**Scope analyzed:** public document/page builders, flow pagination, layout validation, existing ExUnit proofs

## File Classification

| File | Role | Data Flow | Why it matters |
|---|---|---|---|
| `lib/rendro/document.ex` | domain struct | authoring -> pipeline | Current document contract; will absorb explicit template/section fields. |
| `lib/rendro/page.ex` | domain struct | authoring -> pipeline | Current page geometry defaults; best analog for a `PageTemplate` struct. |
| `lib/rendro/block.ex` | domain struct | authoring -> pipeline | Region/section work must preserve the existing block payload shape. |
| `lib/rendro.ex` | public API | authoring -> pipeline | Builder functions and `flow/2`/`fixed/2` entry points live here. |
| `lib/rendro/pipeline/compose.ex` | normalization | authoring -> internal doc | Best insertion point for region/section normalization before measurement. |
| `lib/rendro/pipeline/paginate.ex` | pagination | normalized doc -> pages | Current implicit-template and overflow behavior lives here. |
| `lib/rendro/pipeline/measure.ex` | sizing | normalized doc -> measured doc | Region-aware space reservation must stay consistent with measurement. |
| `test/rendro/document_test.exs` | unit test | authoring contract | Best proof for new `Document` fields and defaults. |
| `test/rendro/page_test.exs` | unit test | authoring contract | Best proof for geometry defaults and template compatibility. |
| `test/rendro_builders_test.exs` | unit test | public API | Best proof that builders stay pure and reject unknown keys. |
| `test/rendro/pipeline/compose_test.exs` | unit test | normalization | Best analog for section/region normalization assertions. |
| `test/rendro/pipeline/paginate_test.exs` | unit test | pagination | Best proof for template expansion, page assignment, and overflow behavior. |
| `test/rendro/flow_test.exs` | integration-style unit test | public flow API | Best proof for user-facing template, header/footer region, and overflow behavior. |

## Reusable Patterns

### 1. Pure struct builders with `struct!`

**Source:** `lib/rendro.ex`, `lib/rendro/document.ex`, `lib/rendro/page.ex`

```elixir
def document(attrs \\ []) do
  struct!(Document, attrs)
end
```

```elixir
def page(attrs \\ []) do
  struct!(Page, attrs)
end
```

**Pattern to preserve**
- New layout primitives should be plain structs with deterministic defaults.
- Builder functions should keep rejecting unknown keys automatically through `struct!`.

### 2. Pipeline stage ownership stays narrow

**Source:** `lib/rendro/pipeline/compose.ex`, `lib/rendro/pipeline/paginate.ex`

```elixir
# Compose: normalize tree shape
composed_pages = Enum.map(pages, &compose_page/1)
```

```elixir
# Paginate: assign pages and validate fit
content
|> Enum.reduce([%{template | blocks: []}], fn block, pages ->
```

**Pattern to preserve**
- `Compose` normalizes authored structures.
- `Measure` computes sizes.
- `Paginate` assigns pages and enforces bounds.
- Region/template work should fit those boundaries rather than introducing a side pipeline.

### 3. Deterministic overflow returns typed errors

**Source:** `lib/rendro/pipeline/paginate.ex`, `test/rendro/flow_test.exs`

```elixir
throw({:error, :content_overflow, %{block_height: block_h, max_height: max_h}})
```

```elixir
assert {:error, %Rendro.Error{} = error} = Rendro.render(doc)
assert error.stage == :paginate
assert error.reason == :content_overflow
```

**Pattern to preserve**
- Impossible layouts should fail with stable structured errors.
- New fixed-position and region-fit checks should reuse the same posture.

## Recommended New Files

| File | Why this name/layout fits the repo |
|---|---|
| `lib/rendro/page_template.ex` | Flat top-level naming matches `page.ex`, `document.ex`, `table.ex`, `text.ex`. |
| `lib/rendro/region.ex` | Region is a first-class domain primitive, not a pipeline-only helper. |
| `lib/rendro/section.ex` | Sections represent authored layout groupings and belong with other domain structs. |

## Code Excerpts To Mirror

### Document/page defaults and type style

**Source:** `lib/rendro/document.ex`, `lib/rendro/page.ex`

```elixir
defstruct pages: [],
          content: [],
          header: [],
          footer: [],
          metadata: %Rendro.Metadata{},
          options: %{}
```

```elixir
defstruct blocks: [],
          width: 595.28,
          height: 841.89,
          margin_top: 72,
          margin_right: 72,
          margin_bottom: 72,
          margin_left: 72
```

**Pattern to preserve**
- Keep defaults explicit in the struct definition.
- Keep type specs aligned with struct fields.

### Builder and nested-document test posture

**Source:** `test/rendro_builders_test.exs`

```elixir
assert_raise KeyError, fn ->
  Rendro.page(bogus: true)
end
```

**Pattern to preserve**
- Public API tests assert both success paths and contract rejection paths.

## Landmines

- `Document.header/footer` currently reserve space by summed heights, not by declared rectangles. Any migration needs compatibility planning.
- `Paginate.run/1` short-circuits fixed pages today. Plan 03 must close that gap or LAY-11 will remain open.
- Flow behavior tests currently assert PDF content and page counts rather than internal template metadata; add internal pipeline tests where needed so public PDF tests stay stable.

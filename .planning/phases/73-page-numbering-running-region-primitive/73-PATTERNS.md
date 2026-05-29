# Phase 73: Page-Numbering / Running-Region Primitive - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 9 (5 source + 4 test)
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/rendro/pipeline/paginate.ex` | pipeline stage | transform | itself — `replace_page_numbers/2` (lines 414–455), `apply_page_template/3` (397–412), `Enum.with_index(1)` map (33–41), `flow_layout/1` (478–501) | self-analog (extend) |
| `lib/rendro/pipeline/measure.ex` | pipeline stage | transform | itself — `body_capacity/1` (lines 442–443) | self-analog (extend) |
| `lib/rendro.ex` | public API builder | request-response | `region/1` and `section/1` at lines 199–207 | exact (same file, same idiom) |
| `lib/rendro/section.ex` | model/struct | — | `lib/rendro/region.ex` (struct with `@enforce_keys []` + typespec) | role-match |
| `lib/rendro/block.ex` (typespec only, no struct change) | model/struct | — | `lib/rendro/region.ex` — `content: term()` already in typespec | role-match |
| `test/rendro/pipeline/paginate_test.exs` | test | unit | itself — existing `describe "run/1"` block; explicit pipeline chain pattern (lines 69–144) | self-analog (extend) |
| `test/rendro/pipeline/measure_test.exs` | test | unit | itself — existing `body_capacity` test (lines 70–124) | self-analog (extend) |
| `test/rendro/flow_test.exs` | test | integration | itself — `"headers, footers and page numbers"` test (lines 102–122); explicit template test (124–237) | self-analog (extend) |
| `test/rendro/deterministic_test.exs` | test | property/unit | itself — `describe "property: deterministic byte-identity"` (lines 12–39); `describe "embedded font parity"` pipeline chain (lines 122–188) | self-analog (extend) |

---

## Pattern Assignments

### `lib/rendro/pipeline/paginate.ex` — extend `replace_page_numbers/2`

**Analog:** `lib/rendro/pipeline/paginate.ex` lines 414–455

**Current implementation** (lines 414–455 — copy verbatim as baseline, extend the two `String.replace` calls):

```elixir
defp replace_page_numbers(blocks, page_num) do
  Enum.map(blocks, fn block ->
    case block.content do
      %Rendro.Text{content: text} = t ->
        %{
          block
          | content: %{
              t
              | content: String.replace(text, "{{page_number}}", Integer.to_string(page_num))
            }
        }

      %Rendro.Pipeline.MeasuredText{source: %Rendro.Text{content: text} = source} = measured ->
        replaced = String.replace(text, "{{page_number}}", Integer.to_string(page_num))

        %{
          block
          | content: %{
              measured
              | source: %{source | content: replaced},
                lines:
                  Enum.map(measured.lines, fn line ->
                    Enum.map(line, fn run ->
                      %{
                        run
                        | text:
                            String.replace(
                              run.text,
                              "{{page_number}}",
                              Integer.to_string(page_num)
                            )
                      }
                    end)
                  end)
            }
        }

      _ ->
        block
    end
  end)
end
```

**Extension rule (D-10):** Add `total` as second integer param. Chain a second `String.replace("{{total_pages}}", Integer.to_string(total))` immediately after each existing `page_number` replace. Touch only `.text` strings — never `run.width`, `block.height`, or any geometry field.

**Caller — `apply_page_template/3`** (lines 397–412 — add `total` as 4th param):

```elixir
defp apply_page_template(%Page{} = page, idx, layout) do
  anchored_blocks =
    layout.template.regions
    |> Enum.reject(&(&1.name == :body))
    |> Enum.flat_map(fn region ->
      anchored_region_blocks =
        layout.region_blocks
        |> Map.get(region.name, [])
        |> replace_page_numbers(idx)          # <-- becomes replace_page_numbers(idx, total)
        |> anchor_region_blocks(region, page)

      maybe_validate_region_fit(anchored_region_blocks, region, page, idx, region.name)
    end)

  %{page | blocks: anchored_blocks ++ page.blocks}
end
```

**`Enum.with_index(1)` map site** (lines 32–41 — bind `total` before map, thread through):

```elixir
pages =
  pages
  |> Enum.reverse()
  |> Enum.with_index(1)
  |> Enum.map(fn {page, idx} ->
    page
    |> stack_body_blocks(layout.body_region)
    |> validate_body_region_fit!(layout.body_region, idx)
    |> apply_page_template(idx, layout)   # <-- becomes apply_page_template(idx, layout, total)
  end)
```

`total = length(pages)` MUST be bound once from the reversed list before this `Enum.with_index` call — not inside the lambda.

**Suppression insertion point** — inside `apply_page_template/3`, between `Map.get(region.name, [])` and `replace_page_numbers`: this is where function block evaluation and declarative selector suppression (D-07/D-08) resolve per-region per-page.

---

### `lib/rendro/pipeline/paginate.ex` — fix `flow_layout/1` `body_capacity` (second fix site)

**Analog:** `lib/rendro/pipeline/paginate.ex` lines 478–501

**Current implementation** (lines 478–501):

```elixir
defp flow_layout(%Document{options: %{layout: layout}}), do: layout

defp flow_layout(%Document{} = doc) do
  template = %PageTemplate{}

  body_region = %Region{
    name: :body,
    role: :body,
    anchor: :flow,
    x: template.margin_left,
    y: template.margin_top,
    width: template.width - template.margin_left - template.margin_right,
    height: template.height - template.margin_top - template.margin_bottom
  }

  %{
    template: template,
    body_region: body_region,
    body_capacity: body_region.height,   # <-- BUG: ignores header/footer
    region_blocks: %{
      body: doc.content,
      header: doc.header,
      footer: doc.footer
    }
  }
end
```

**Fix pattern:** Derive header/footer heights from `template.regions` (not from a `layout.header_region` key — that key does not exist on this fallback path). Use `Enum.find(template.regions, &(&1.name == :header))` and `Enum.find(template.regions, &(&1.name == :footer))` then read `.height || 0`. Subtract both from `body_region.height` to compute `body_capacity`. Default `%PageTemplate{}` has `header.height: 0` and `footer.height: 0`, so the fix is a no-op for default usage.

**Existing guard pattern to reuse** (`bounded_region?/1` at line 679):

```elixir
defp bounded_region?(%Region{width: width, height: height}) do
  is_number(width) and width > 0 and is_number(height) and height > 0
end
```

Use the same `is_number(h) and h > 0` guard when extracting header/footer heights from regions.

---

### `lib/rendro/pipeline/measure.ex` — fix `body_capacity/1`

**Analog:** `lib/rendro/pipeline/measure.ex` lines 442–443

**Current implementation:**

```elixir
defp body_capacity(%{body_region: %Region{height: height}}) when is_number(height), do: height
defp body_capacity(_layout), do: 0
```

**Context — `measure_layout/2`** (lines 396–418, shows how `body_capacity` is used):

```elixir
defp measure_layout(%Rendro.Document{} = doc, layout) do
  with {:ok, measured_region_blocks} <- measure_region_blocks(doc, layout) do
    measured_layout =
      layout
      |> Map.put(:region_blocks, measured_region_blocks)
      |> Map.put(:body_capacity, body_capacity(layout))

    if measured_layout.body_capacity <= 0 do
      {:error, :no_body_capacity}
    else
      ...
    end
  end
end
```

**Available layout keys (verified, compose.ex:90–100):**

```elixir
layout = %{
  template: template,
  region_map: region_map,
  body_region: Map.get(region_map, :body, default_body_region(template)),
  header_region: Map.get(region_map, :header),    # Rendro.Region.t() | nil
  footer_region: Map.get(region_map, :footer),    # Rendro.Region.t() | nil
  region_blocks: region_blocks,
  entries: entries
}
```

**Fix pattern (D-04):** Replace the two-clause function with a three-key destructure. Use `if region, do: region.height || 0, else: 0` for nil guard — this is idiomatic Elixir and consistent with the `||` pattern used in `measure_region_blocks` (line 429: `if region, do: region.width, else: nil`).

---

### `lib/rendro.ex` — add `page_number/1` helper

**Analog:** `lib/rendro.ex` lines 199–207 — the `region/1` and `section/1` builder functions

**Exact pattern to copy:**

```elixir
@spec region(keyword()) :: Region.t()
def region(attrs \\ []) do
  struct!(Region, attrs)
end

@spec section(keyword()) :: Section.t()
def section(attrs \\ []) do
  struct!(Section, attrs)
end
```

**Adjacent block/text builder pattern** (lines 209–220) — `page_number/1` produces a `Block` containing a `Text`, matching this idiom exactly:

```elixir
@spec block(Text.t() | term(), keyword()) :: Block.t()
def block(content, attrs \\ []) do
  struct!(Block, Keyword.put(attrs, :content, content))
end

@spec text(String.t(), keyword()) :: Text.t()
def text(content, attrs \\ []) do
  attrs
  |> normalize_text_attrs()
  |> Keyword.put(:content, content)
  |> then(&struct!(Text, &1))
end
```

**Placement:** Insert after `section/1` at approximately line 207, before `block/2`. Module alias `Text` is already in scope (line 21). No new aliases needed.

**`@spec` format to match:** `@spec page_number(keyword()) :: Block.t()` — aligns with `block/2` return type.

---

### `lib/rendro/section.ex` — add `suppress_on` field + widen `content:` typespec

**Analog:** `lib/rendro/region.ex` (lines 1–27) — struct with `@enforce_keys []` and full `@type t`

**Current `Rendro.Section` struct** (lines 1–20 — full file, copy as baseline):

```elixir
defmodule Rendro.Section do
  @moduledoc """
  Reusable flow section that targets a named template region.
  """

  @enforce_keys []
  defstruct name: nil,
            region: :body,
            content: [],
            page_template: nil,
            options: %{}

  @type t :: %__MODULE__{
          name: atom() | String.t() | nil,
          region: atom() | String.t(),
          content: [Rendro.Block.t()],
          page_template: atom() | String.t() | nil,
          options: %{optional(atom()) => term()}
        }
end
```

**`Rendro.Region` typespec pattern** (region.ex lines 15–26) — how the project defines enum types inline:

```elixir
@type role :: :header | :body | :footer | :sidebar | :custom
@type anchor :: :top | :flow | :bottom | :fixed

@type t :: %__MODULE__{
        name: atom() | String.t() | nil,
        role: role(),
        anchor: anchor(),
        ...
      }
```

**Extension rule (D-07, Claude's Discretion):** Add `suppress_on: nil` field to defstruct. Define `@type suppress_on :: nil | :first | {:pages, [pos_integer()]}` above `@type t`. Widen `content:` in `@type t` to `[Rendro.Block.t()] | (({pos_integer(), pos_integer()} -> [Rendro.Block.t()]) | Rendro.Block.t())` — or keep `content: [Rendro.Block.t()]` at the section level and carry the function variant inside `Rendro.Block.content` (see Block note below). Top-level `suppress_on:` field preferred over `options` map per research OQ-2 recommendation.

---

### `lib/rendro/block.ex` — typespec note (no struct change required)

**Analog:** `lib/rendro/block.ex` lines 19–30 — the existing `content: term()` fallback

**Current typespec** (lines 19–30):

```elixir
@type t :: %__MODULE__{
        content:
          Rendro.Text.t() | Rendro.Table.t() | Rendro.FormField.t() | Rendro.Link.t() | term(),
        ...
      }
```

The `| term()` catch-all already accommodates a function value without struct change. If a dedicated `%Rendro.RunningContent{fun: fn}` wrapper is chosen (research OQ-1), its struct pattern follows `lib/rendro/region.ex` exactly: `@enforce_keys []`, `defstruct`, `@type t`. The `@enforce_keys [:fun]` variant would be appropriate since a function is always required. No other struct field changes are needed.

---

### `test/rendro/pipeline/paginate_test.exs` — new tests for fn evaluation, suppression, `flow_layout` fallback

**Analog:** `test/rendro/pipeline/paginate_test.exs` lines 69–144 — explicit pipeline chain test pattern

**Pattern to copy — full pipeline chain setup:**

```elixir
test "uses authored page-template geometry for flow pagination" do
  template =
    %PageTemplate{
      name: :compact,
      ...
      regions: [
        %Region{name: :header, role: :header, anchor: :top, x: 24, y: 24, width: 372, height: 20},
        %Region{name: :body,   role: :body,   anchor: :flow, x: 24, y: 52, width: 372, height: 28.8},
        %Region{name: :footer, role: :footer, anchor: :bottom, x: 24, y: 188, width: 372, height: 16}
      ]
    }

  doc = Rendro.flow(..., page_template: :compact, page_templates: [template])

  {:ok, doc} = Build.run(doc)
  {:ok, doc} = Compose.run(doc)
  {:ok, doc} = Measure.run(doc)
  assert {:ok, paginated} = Paginate.run(doc)

  assert length(paginated.pages) == 3
  ...
end
```

**Alias block to copy** (lines 1–8 — already present, no change needed):

```elixir
alias Rendro.{PageTemplate, Region}
alias Rendro.Pipeline.{Build, Compose, Measure, MeasuredText, Paginate}
```

**New tests use same `Build → Compose → Measure → Paginate` chain.** For `flow_layout/1` fallback tests, skip `Build/Compose/Measure` and call `Paginate.run(doc)` directly on a `%Rendro.Document{content: [...], footer: [...]}` struct with no `options.layout` key — this forces the `flow_layout/1` branch.

---

### `test/rendro/pipeline/measure_test.exs` — extend body_capacity test

**Analog:** `test/rendro/pipeline/measure_test.exs` lines 70–124 — the existing `body_capacity` test

**Full pattern to extend** (lines 70–124):

```elixir
test "measures body capacity from the explicit body region instead of header/footer block heights" do
  template =
    %PageTemplate{
      name: :statement,
      regions: [
        %Region{name: :header, role: :header, anchor: :top,    x: 72, y: 72,  width: 451.28, height: 48},
        %Region{name: :body,   role: :body,   anchor: :flow,   x: 72, y: 120, width: 451.28, height: 540},
        %Region{name: :footer, role: :footer, anchor: :bottom, x: 72, y: 732, width: 451.28, height: 36}
      ]
    }

  doc =
    %Rendro.Document{
      page_template: :statement,
      page_templates: [template],
      content: [Rendro.block(Rendro.text("Line item"))],
      header: [Rendro.block(Rendro.text("Tall header"), height: 120)],
      footer: [Rendro.block(Rendro.text("Tall footer"), height: 80)],
      metadata: %Rendro.Metadata{}
    }

  assert {:ok, composed} = Compose.run(doc)
  assert {:ok, result} = Measure.run(composed)

  layout = result.options.layout

  assert layout.body_capacity == 540
  assert hd(result.header).height == 120
  assert hd(result.footer).height == 80
  assert_in_delta hd(result.content).height, 14.4, 1.0e-9
end
```

**D-04 fix test:** Add a companion test in the same `describe` block where `footer.height: 36` and `header.height: 0` → `body_capacity == 540 - 0 - 36 == 504`. Use `assert_in_delta` for float comparisons (see line 123 pattern).

---

### `test/rendro/flow_test.exs` — extend existing page-number test + new suppression/overlap tests

**Analog:** `test/rendro/flow_test.exs` lines 102–122 — `"headers, footers and page numbers"` test

**Pattern to extend** (lines 102–122):

```elixir
test "headers, footers and page numbers" do
  header = [Rendro.block(Rendro.text("My Report"))]
  footer = [Rendro.block(Rendro.text("Page {{page_number}}"))]

  content =
    for i <- 1..50 do
      Rendro.block(Rendro.text("Line #{i}"))
    end

  doc = Rendro.flow(content, header: header, footer: footer)
  {:ok, pdf} = Rendro.render(doc)

  assert length(Regex.scan(~r"/Type\s*/Page\b", pdf)) == 2
  assert length(Regex.scan(~r/\(My Report\) Tj/, pdf)) == 2
  assert pdf =~ "(Page 1) Tj"
  assert pdf =~ "(Page 2) Tj"
end
```

**Explicit template test for assertions on block y-coordinates** (lines 124–237) — use this pattern when testing that body blocks do not overlap the footer region (assert `block.y + block.height <= footer_region.y`).

---

### `test/rendro/deterministic_test.exs` — new `describe "running-region determinism (D-11)"`

**Analog:** `test/rendro/deterministic_test.exs` lines 12–39 — `describe "property: deterministic byte-identity"` and lines 122–188 — embedded font parity (pipeline chain + assertions on `paginated.pages`).

**Property test idiom** (lines 13–18):

```elixir
property "two deterministic renders of the same document produce identical binaries" do
  check all(doc <- renderable_document_gen(), max_runs: 100) do
    {:ok, pdf1} = Rendro.render(doc, deterministic: true)
    {:ok, pdf2} = Rendro.render(doc, deterministic: true)
    assert pdf1 == pdf2
  end
end
```

**Unit test with full pipeline chain** (lines 139–188):

```elixir
{:ok, built} = Build.run(doc)
{:ok, composed} = Compose.run(built)
{:ok, measured} = Measure.run(composed)
{:ok, paginated} = Paginate.run(measured)
```

**Existing import** (line 7): `alias Rendro.Pipeline.{Build, Compose, Measure, Paginate}` — already present, no change needed.

**Helper function idiom** (lines 190–195):

```elixir
defp simple_doc do
  text = %Rendro.Text{content: "Hello World", font: "Helvetica", size: 12, color: {0, 0, 0}}
  block = %Rendro.Block{content: text, x: 0, y: 0}
  page = %Rendro.Page{blocks: [block]}
  %Rendro.Document{pages: [page], metadata: %Rendro.Metadata{title: "Test"}}
end
```

**D-11(d) geometry guard:** After running through `Build → Compose → Measure → Paginate`, capture `MeasuredText.lines` (run `text`, `width`, `height`) from a footer block pre-substitution. Substitute. Assert widths and block heights unchanged. Pattern for reading lines from a block: `block.content.lines` and `Enum.map(line, & &1.text)` (line 150 pattern).

---

### `test/rendro_builders_test.exs` — new `page_number/1` builder test

**Analog:** `test/rendro_builders_test.exs` lines 22–44 — existing builder function tests

**Pattern to copy:**

```elixir
test "text/2 builds a Text struct" do
  text = Rendro.text("hello")
  assert %Text{content: "hello", font: "Helvetica"} = text
end
```

**New test shape:**

```elixir
test "page_number/1 builds a Block containing a Text with page-number tokens" do
  block = Rendro.page_number()
  assert %Block{content: %Text{content: content}} = block
  assert content =~ "{{page_number}}"
  assert content =~ "{{total_pages}}"
end
```

Alias block (lines 1–16) already imports `Block` and `Text` — no changes needed.

---

## Shared Patterns

### `struct!(Module, attrs)` builder idiom
**Source:** `lib/rendro.ex` lines 199–207
**Apply to:** `page_number/1` implementation in `lib/rendro.ex`

```elixir
@spec region(keyword()) :: Region.t()
def region(attrs \\ []) do
  struct!(Region, attrs)
end
```

### `@enforce_keys []` + `defstruct` + `@type t` struct pattern
**Source:** `lib/rendro/region.ex` lines 1–27; `lib/rendro/section.ex` lines 1–20
**Apply to:** any new `%Rendro.RunningContent{}` wrapper struct if the planner chooses option (b) from research OQ-1; the `suppress_on` field addition to `lib/rendro/section.ex`

### `if region, do: region.height || 0, else: 0` nil-region guard
**Source:** measure.ex line 429 pattern — `if region, do: region.width, else: nil`
**Apply to:** `body_capacity/1` fix in `lib/rendro/pipeline/measure.ex`; `flow_layout/1` fix in `lib/rendro/pipeline/paginate.ex`

### `Build → Compose → Measure → Paginate` pipeline chain (test setup)
**Source:** `test/rendro/flow_test.exs` lines 178–181; `test/rendro/pipeline/paginate_test.exs` lines 117–120; `test/rendro/deterministic_test.exs` lines 139–143
**Apply to:** All new integration tests in `flow_test.exs`, `paginate_test.exs`, and `deterministic_test.exs`

```elixir
{:ok, built} = Build.run(doc)
{:ok, composed} = Compose.run(built)
{:ok, measured} = Measure.run(composed)
assert {:ok, paginated} = Paginate.run(measured)
```

### `Enum.find(page.blocks, &match?(%Rendro.Block{content: %MeasuredText{source: %Rendro.Text{content: "..."}}}, &1))` block finder
**Source:** `test/rendro/flow_test.exs` lines 187–215
**Apply to:** Any test that asserts page-number token substitution on specific pages (flow_test.exs, deterministic_test.exs)

### `maybe_validate_region_fit/5` reuse
**Source:** `lib/rendro/pipeline/paginate.ex` lines 590–601
**Apply to:** Suppression path — a suppressed region passes an empty block list to `anchor_region_blocks` and still calls `maybe_validate_region_fit`; the geometry check uses the authored `height` (D-08), not the zero-length rendered block list

```elixir
defp maybe_validate_region_fit(blocks, %Region{} = region, %Page{} = page, page_index, region_name) do
  if bounded_region?(region) do
    validate_region_fit!(blocks, region, page, page_index, region_name)
  else
    blocks
  end
end
```

---

## No Analog Found

All files have close analogs. No entries.

---

## Metadata

**Analog search scope:** `lib/rendro/`, `lib/rendro/pipeline/`, `lib/rendro/recipes/`, `test/rendro/`, `test/rendro/pipeline/`
**Files read:** 12 source + test files (live, verified line numbers)
**Pattern extraction date:** 2026-05-29

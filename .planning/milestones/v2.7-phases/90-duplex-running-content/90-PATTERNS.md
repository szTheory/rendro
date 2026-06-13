# Phase 90: Duplex Running Content - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 10 new/modified files
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/section.ex` | model | request-response | `lib/rendro/section.ex` page_numbering field/type | exact |
| `lib/rendro.ex` | public facade | transform | `Rendro.section/1` and `Rendro.page_number/1` builders | exact |
| `lib/rendro/section_options.ex` | utility | validation/transform | `lib/rendro/pipeline/compose.ex` suppress_on validation | role-match |
| `lib/rendro/pipeline/compose.ex` | pipeline stage | transform | existing `normalize_section/2` + `region_suppress_on` layout metadata | exact |
| `lib/rendro/pipeline/paginate.ex` | pipeline stage | batch/transform | existing running-region suppression, callback evaluation, and PAGE-token replacement path | exact |
| `test/rendro_builders_test.exs` | test | request-response | existing `section/1 builds a Section struct` test | exact |
| `test/rendro/pipeline/compose_test.exs` | test | transform/validation | existing section metadata and conflicting `suppress_on` tests | exact |
| `test/rendro/pipeline/paginate_test.exs` | test | batch/transform | existing section context, running content, suppression tests | exact |
| `test/rendro/flow_test.exs` | test | request-response | existing render-level header/footer/suppress_on tests | role-match |
| `priv/public_api.json` | config/manifest | batch/transform | `mix rendro.api.gen` + manifest equality tests | exact |

## Pattern Assignments

### `lib/rendro/section.ex` (model, request-response)

**Analog:** `lib/rendro/section.ex`

**Struct and type pattern** (lines 7-27):
```elixir
@enforce_keys []
defstruct name: nil,
          region: :body,
          content: [],
          suppress_on: nil,
          page_numbering: [],
          page_template: nil,
          options: %{}

@type suppress_on :: nil | :first | {:pages, [pos_integer()]}
@type page_numbering :: [] | [restart: true]

@type t :: %__MODULE__{
        name: atom() | String.t() | nil,
        region: atom() | String.t(),
        content: [Rendro.Block.t() | Rendro.RunningContent.t()],
        suppress_on: suppress_on(),
        page_numbering: page_numbering(),
        page_template: atom() | String.t() | nil,
        options: %{optional(atom()) => term()}
      }
```

**Guidance:** Add `only_on: nil` next to `suppress_on`, define `@type only_on :: nil | :odd | :even`, and include it in `t/0`. This is a public stable type change, so regenerate `priv/public_api.json`.

### `lib/rendro.ex` (public facade, transform)

**Analog:** `lib/rendro.ex`

**Import/alias pattern** (lines 7-23):
```elixir
alias Rendro.{
  Artifact,
  Block,
  Document,
  FormField,
  Link,
  Metadata,
  Page,
  PageTemplate,
  Protect,
  Pipeline,
  Region,
  Section,
  Sign,
  Table,
  Text
}
```

**Builder pattern** (lines 217-220):
```elixir
@spec section(keyword()) :: Section.t()
def section(attrs \\ []) do
  struct!(Section, attrs)
end
```

**Guidance:** `Rendro.section/1` should remain a thin `struct!` builder. Do not add builder-only validation here because manually built `%Rendro.Section{}` values must be validated by the pipeline too.

### `lib/rendro/section_options.ex` (utility, validation/transform)

**Analog:** `lib/rendro/pipeline/compose.ex`

**Existing validation style** (lines 96-111):
```elixir
region_suppress_on =
  doc.sections
  |> Enum.filter(&(&1.suppress_on != nil))
  |> Enum.reduce(%{}, fn section, acc ->
    region = section.region || :body

    case Map.fetch(acc, region) do
      {:ok, existing} when existing != section.suppress_on ->
        raise ArgumentError,
              "Conflicting suppress_on for region #{inspect(region)}: " <>
                "#{inspect(existing)} vs #{inspect(section.suppress_on)}"

      _ ->
        Map.put(acc, region, section.suppress_on)
    end
  end)
```

**Guidance:** If a helper is added, keep it pure core Elixir and raise `ArgumentError` with precise messages. Validate `only_on in [nil, :odd, :even]` and `page_numbering in [[], [restart: true]]`. Call it from Compose before section metadata is trusted; avoid a public module unless necessary.

### `lib/rendro/pipeline/compose.ex` (pipeline stage, transform)

**Analog:** `lib/rendro/pipeline/compose.ex`

**Imports pattern** (lines 1-5):
```elixir
defmodule Rendro.Pipeline.Compose do
  @moduledoc false

  alias Rendro.{Document, PageTemplate, Region, Section}
```

**Layout metadata pattern** (lines 70-82, 113-122):
```elixir
entries =
  [
    %{
      name: :content,
      region: :body,
      blocks: doc.content,
      page_numbering: [],
      page_template: doc.page_template
    },
    Enum.with_index(doc.sections, 1)
    |> Enum.map(fn {section, index} -> normalize_section(section, index) end)
  ]
  |> List.flatten()

layout = %{
  template: template,
  region_map: region_map,
  body_region: Map.get(region_map, :body, default_body_region(template)),
  header_region: Map.get(region_map, :header),
  footer_region: Map.get(region_map, :footer),
  region_blocks: region_blocks,
  region_suppress_on: region_suppress_on,
  entries: entries
}
```

**Section normalization pattern** (lines 130-138):
```elixir
defp normalize_section(%Section{} = section, index) do
  %{
    name: section.name || :"section_#{index}",
    region: section.region || :body,
    blocks: Enum.map(section.content, &compose_block/1),
    page_numbering: section.page_numbering,
    page_template: section.page_template
  }
end
```

**Guidance:** Extend normalized entries with `suppress_on` and `only_on`. Preserve a list of running-region entries rather than relying on `region_suppress_on` by region, because odd and even footer sections must coexist for the same region.

### `lib/rendro/pipeline/paginate.ex` (pipeline stage, batch/transform)

**Analog:** `lib/rendro/pipeline/paginate.ex`

**Pipeline order pattern** (lines 32-44):
```elixir
pages = Enum.reverse(pages)
total = length(pages)
page_contexts = page_contexts(total, section_starts)

pages =
  pages
  |> Enum.with_index(1)
  |> Enum.map(fn {page, idx} ->
    page
    |> stack_body_blocks(layout.body_region)
    |> validate_body_region_fit!(layout.body_region, idx)
    |> apply_page_template(idx, layout, total, Map.fetch!(page_contexts, idx))
  end)
```

**Measured-entry re-pairing pattern** (lines 159-175):
```elixir
defp measured_body_entries(entries, measured_body_blocks) do
  {measured_entries, remaining_blocks} =
    Enum.map_reduce(entries, measured_body_blocks, fn entry, remaining ->
      {entry_blocks, rest} = Enum.split(remaining, length(Map.get(entry, :blocks, [])))
      {%{entry | blocks: entry_blocks}, rest}
    end)

  case {measured_entries, remaining_blocks} do
    {[], _} -> fallback_body_entries(measured_body_blocks)
    {entries, []} -> entries
    {entries, rest} -> List.update_at(entries, -1, fn entry -> %{entry | blocks: entry.blocks ++ rest} end)
  end
end
```

**Running-region application pattern** (lines 558-579):
```elixir
defp apply_page_template(%Page{} = page, idx, layout, total, page_context) do
  region_suppress_on = Map.get(layout, :region_suppress_on, %{})

  anchored_blocks =
    layout.template.regions
    |> Enum.reject(&(&1.name == :body))
    |> Enum.flat_map(fn region ->
      suppress_on = Map.get(region_suppress_on, region.name)

      anchored_region_blocks =
        layout.region_blocks
        |> Map.get(region.name, [])
        |> apply_suppression(suppress_on, idx)
        |> evaluate_fn_blocks(idx, total)
        |> replace_page_numbers(page_context)
        |> anchor_region_blocks(region, page)

      maybe_validate_region_fit(anchored_region_blocks, region, page, idx, region.name)
    end)

  %{page | blocks: anchored_blocks ++ page.blocks}
end
```

**Token replacement stability pattern** (lines 589-608):
```elixir
%Rendro.Pipeline.MeasuredText{source: %Rendro.Text{content: text} = source} = measured ->
  new_source_text = replace_page_number_tokens(text, page_context)

  new_lines =
    Enum.map(measured.lines, fn line ->
      Enum.map(line, fn run ->
        new_run_text = replace_page_number_tokens(run.text, page_context)

        # NOTE: run.width intentionally NOT updated (D-10)
        %{run | text: new_run_text}
      end)
    end)
```

**Suppression and callback pattern** (lines 631-673):
```elixir
defp evaluate_fn_blocks(blocks, page_num, total) do
  Enum.flat_map(blocks, fn block ->
    case block.content do
      %Rendro.RunningContent{fun: fun} ->
        try do
          result = fun.({page_num, total})
          case result do
            nil -> []
            [] -> []
            list when is_list(list) -> list
            single -> [single]
          end
        rescue
          reason ->
            throw({:error, :running_content_error, %{page_num: page_num, reason: inspect(reason)}})
        end

      _ -> [block]
    end
  end)
end

defp apply_suppression(blocks, suppress_on, page_idx) do
  case suppress_on do
    nil -> blocks
    :first when page_idx == 1 -> []
    :first -> blocks
    {:pages, page_list} when is_list(page_list) -> if page_idx in page_list, do: [], else: blocks
    _ -> blocks
  end
end
```

**Guidance:** Add physical-page `only_on` filtering before `evaluate_fn_blocks/3` and `replace_page_numbers/2`. Use `idx` from `Enum.with_index(1)`, not `page_context.section_page_number`. Keep measured text geometry frozen.

## Test Pattern Assignments

### `test/rendro_builders_test.exs` (test, request-response)

**Analog:** `test/rendro_builders_test.exs`

**Builder assertion pattern** (lines 212-230):
```elixir
section =
  Rendro.section(
    name: :summary,
    region: :body,
    content: [block],
    page_numbering: [restart: true],
    page_template: :invoice
  )

assert %Section{
         name: :summary,
         region: :body,
         content: [^block],
         page_numbering: [restart: true],
         page_template: :invoice
       } = section
```

**Guidance:** Add `only_on: :odd` or `:even` to this test and assert the field. Do not assert validation here beyond `struct!` unknown-key behavior.

### `test/rendro/pipeline/compose_test.exs` (test, transform/validation)

**Analog:** `test/rendro/pipeline/compose_test.exs`

**ArgumentError pattern** (lines 52-107):
```elixir
test "CR-03 regression: two sections targeting the same region with conflicting suppress_on raises ArgumentError" do
  section1 = %Section{region: :footer, content: [Rendro.block(Rendro.text("Footer A"))], suppress_on: :first}
  section2 = %Section{region: :footer, content: [Rendro.block(Rendro.text("Footer B"))], suppress_on: {:pages, [3]}}

  doc = %Rendro.Document{content: [Rendro.block(Rendro.text("Body"))], sections: [section1, section2], metadata: %Rendro.Metadata{}}

  assert_raise ArgumentError, ~r/Conflicting suppress_on for region :footer/, fn ->
    Compose.run(doc)
  end
end
```

**Metadata assertion pattern** (lines 238-260):
```elixir
assert {:ok, result} = Compose.run(doc)
layout = result.options.layout

assert Enum.map(layout.entries, & &1.name) == [
         :content,
         :report_header,
         :totals,
         :body_copy
       ]

body_entry = Enum.find(layout.entries, &(&1.name == :body_copy))
assert body_entry.page_numbering == [restart: true]
```

**Guidance:** Add tests that invalid `only_on` values (`:left`, `"odd"`) and invalid `page_numbering` values (`[restart: false]`, unknown keys) raise clear `ArgumentError`s through `Compose.run/1`. Add a positive assertion that running-region entries retain both `suppress_on` and `only_on`.

### `test/rendro/pipeline/paginate_test.exs` (test, batch/transform)

**Analog:** `test/rendro/pipeline/paginate_test.exs`

**Section-local token pattern** (lines 685-722):
```elixir
footer_section =
  Rendro.section(
    region: :footer,
    content: [
      Rendro.page_number(
        format:
          "P{{page_number}}/{{total_pages}} S{{section_page_number}}/{{section_total_pages}}"
      )
    ]
  )

restarting_section =
  Rendro.section(
    name: :appendix,
    region: :body,
    page_numbering: [restart: true],
    content: for(i <- 1..3, do: Rendro.block(Rendro.text("Appendix #{i}")))
  )

assert page_texts(page1) == ["P1/3 S1/1", "Intro"]
assert page_texts(page2) == ["P2/3 S1/2", "Appendix 1", "Appendix 2"]
assert page_texts(page3) == ["P3/3 S2/2", "Appendix 3"]
```

**RunningContent callback pattern** (lines 792-838):
```elixir
fn_block =
  %Rendro.Block{
    content: %Rendro.RunningContent{
      fun: fn {pn, tp} ->
        Agent.update(agent, fn calls -> [{pn, tp} | calls] end)
        [Rendro.block(Rendro.text("#{pn}/#{tp}"))]
      end
    },
    height: 14.4
  }

calls
|> Enum.with_index(1)
|> Enum.each(fn {{pn, tp}, expected_idx} ->
  assert pn == expected_idx
  assert tp == total_pages
end)
```

**Helper pattern** (lines 1019-1030):
```elixir
defp paginate_flow(doc) do
  {:ok, doc} = Build.run(doc)
  {:ok, doc} = Compose.run(doc)
  {:ok, doc} = Measure.run(doc)
  Paginate.run(doc)
end

defp page_texts(page) do
  Enum.map(page.blocks, fn
    %Rendro.Block{content: %MeasuredText{source: %Rendro.Text{content: content}}} -> content
    %Rendro.Block{content: %Rendro.Text{content: content}} -> content
  end)
end
```

**Guidance:** Add odd/even header/footer tests using `page_texts/1`, including two footer sections targeting `:footer` at once. Add a regression where a `page_numbering: [restart: true]` body section begins on physical page 2 and `only_on: :even` renders there while `only_on: :odd` does not.

### `test/rendro/flow_test.exs` (test, request-response)

**Analog:** `test/rendro/flow_test.exs`

**Render-level running region pattern** (lines 137-156):
```elixir
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
```

**Suppress-on integration pattern** (lines 215-265):
```elixir
footer_section =
  Rendro.section(
    region: :footer,
    content: [Rendro.block(Rendro.text("Page {{page_number}}"))],
    suppress_on: :first
  )

assert footer_blocks_p1 == [],
       "expected no footer on page 1 (suppressed), got #{inspect(footer_blocks_p1)}"

assert footer_block_p2 != nil,
       "expected footer 'Page 2' on page 2 but not found"
```

**Guidance:** Add one render-level compatibility test if planner wants end-to-end coverage. Keep it focused: PDF contains odd footer text only on odd pages and even footer text only on even pages, with no docs overclaim.

### `priv/public_api.json` (config/manifest, batch/transform)

**Analog:** `lib/mix/tasks/rendro/api.gen.ex` and manifest tests

**Generator source of truth** (lines 37-45, 69-71, 117-122):
```elixir
@manifest_path "priv/public_api.json"

@public_modules [
  # Stable tier — core document model and facades
  Rendro,
  ...
  Rendro.RunningContent,
  Rendro.Section,
  Rendro.Sign,
  ...
]

manifest = Rendro.PublicApi.build_manifest(loaded_modules)
json = encode_manifest(manifest)
File.write!(@manifest_path, json <> "\n")
```

**Manifest equality pattern** (`test/rendro/public_api/manifest_test.exs` lines 83-103):
```elixir
loaded_modules =
  Mix.Tasks.Rendro.Api.Gen.public_modules()
  |> Enum.filter(fn mod ->
    Code.ensure_loaded?(mod) and
      match?({:docs_v1, _, _, _, _, _, _}, Code.fetch_docs(mod))
  end)

fresh_manifest = PublicApi.build_manifest(loaded_modules)
fresh_json = Mix.Tasks.Rendro.Api.Gen.encode_manifest(fresh_manifest) <> "\n"
checked_in = File.read!("priv/public_api.json")

assert fresh_json == checked_in,
       """
       The freshly-generated manifest does not byte-match priv/public_api.json.
       This means the manifest is out of date. Run: mix rendro.api.gen
       and commit the result (D-15 drift treadmill guard).
       """
```

**Current Section manifest shape** (`priv/public_api.json` lines 396-403):
```json
"Elixir.Rendro.Section": {
  "functions": [],
  "tier": "stable",
  "types": [
    "page_numbering/0",
    "suppress_on/0",
    "t/0"
  ]
}
```

**Guidance:** After adding `@type only_on`, run `mix rendro.api.gen`. The expected manifest drift is an added `"only_on/0"` type for `Elixir.Rendro.Section`.

## Shared Patterns

### Pipeline Validation
**Source:** `lib/rendro/pipeline/compose.ex` lines 96-111  
**Apply to:** `lib/rendro/section_options.ex`, `lib/rendro/pipeline/compose.ex`, compose tests

Raise `ArgumentError` for malformed section options before measurement/pagination. Use Compose as the central validation point so builder-created and manually built structs share the same path.

### Running-Region Filtering Order
**Source:** `lib/rendro/pipeline/paginate.ex` lines 558-573  
**Apply to:** `lib/rendro/pipeline/paginate.ex`, paginate tests

Filter first, then evaluate `RunningContent`, then replace PAGE tokens, then anchor. `only_on` must use physical `idx`; PAGE token replacement continues to use `page_context`.

### Measurement Stability
**Source:** `lib/rendro/pipeline/paginate.ex` lines 589-608 and `test/rendro/deterministic_test.exs` lines 230-239  
**Apply to:** paginate implementation and tests

Do not remeasure token-expanded footer/header text. Replace text content and measured runs only; leave run widths and block heights intact.

### Public API Drift
**Source:** `test/docs_contract/public_api_contract_test.exs` lines 30-78  
**Apply to:** `priv/public_api.json`, manifest tests

Any public type change must be regenerated through `mix rendro.api.gen`; the docs-contract lane byte-compares the fresh manifest to the checked-in file.

## No Analog Found

None. Every planned Phase 90 file has a close existing analog. The only new-file candidate is `lib/rendro/section_options.ex`; use the existing Compose `ArgumentError` style and keep it private/internal.

## Metadata

**Analog search scope:** `lib/rendro`, `lib/mix/tasks`, `test/rendro`, `test/docs_contract`, `priv/public_api.json`, Phase 89/90 planning artifacts  
**Files scanned:** 80+ via `rg --files` and targeted `rg` searches  
**Project-local skills:** none found under `.codex/skills/` or `.agents/skills/`  
**Pattern extraction date:** 2026-06-13

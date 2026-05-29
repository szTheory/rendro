# Architecture Research

**Domain:** Pure-Elixir PDF generation library — v2.4 feature integration
**Researched:** 2026-05-29
**Confidence:** HIGH (all findings based on direct source inspection of the live codebase)

## Standard Architecture

### Existing Pipeline (Non-Negotiable)

```
Rendro.render/2
    │
    ▼
Rendro.Pipeline.run_with_diagnostics/1
    │
    ├─ Build    — font preflight, document normalization
    ├─ Compose  — section/region normalization, flow layout assembly
    │             (builds layout.region_blocks: %{header: [...], body: [...], footer: [...]})
    ├─ Measure  — text measurement, column sizing, block height calculation
    │             (token strings like "{{page_number}}" survive measurement intact)
    ├─ Paginate — flow pagination, apply_page_template per page
    │             (already resolves {{page_number}} placeholder — seam extends here)
    ├─ Validate — structural validation (Poppler adapter, policy checks)
    └─ Render   — Writer.render/2 → PDF binary
```

The single seam for all new v2.4 work is `Paginate` and the `region_blocks` map assembled
during `Compose`. No second render path is introduced. The pipeline sequencing
in `lib/rendro/pipeline.ex` is unchanged.

### Paginate Stage Detail (lib/rendro/pipeline/paginate.ex)

The paginate stage does the following, in order:

1. `paginate_flow/1` — iterates `body_blocks`, distributes them across pages via
   `paginate_blocks/4` recursion. All pages are collected in reverse order first.
2. `Enum.reverse()` on the collected pages — produces the final ordered page list.
3. `Enum.with_index(1)` — assigns 1-based page index to each page.
4. For each `{page, idx}` pair: `apply_page_template/3` — anchors non-body region blocks,
   calls `replace_page_numbers/2` which substitutes `{{page_number}}` with the current index.

The key point: `replace_page_numbers/2` already runs inside the final `Enum.map` after all
pages are collected. `total_pages = length(pages_reversed)` is therefore computable at the
same point — same pass, same function, zero additional infrastructure.

```elixir
# Current code in paginate_flow/1 (lib/rendro/pipeline/paginate.ex):
pages =
  pages
  |> Enum.reverse()
  |> Enum.with_index(1)
  |> Enum.map(fn {page, idx} ->
    page
    |> stack_body_blocks(layout.body_region)
    |> validate_body_region_fit!(layout.body_region, idx)
    |> apply_page_template(idx, layout)   # replace_page_numbers runs here
  end)
```

`{{total_pages}}` resolves in the same pass as `{{page_number}}` — total is
`length(pages)` computed once before the map. No second pipeline pass is needed.

## The Running-Region Seam: Exact Proposal

### Where It Lives

**`Rendro.Pipeline.Paginate` — modified, not replaced.**

The seam is a targeted extension inside the existing `replace_page_numbers/2` private function
(renamed to `replace_running_tokens/3`), called with both `page_num` and `total_pages`. No new
pipeline stage is introduced. No second render path is introduced.

### Why a Two-Pass Render Is Unnecessary

A two-pass render (measure → paginate once to count pages, then render again with the count
injected) would be required only if total page count were needed BEFORE pagination completes.
But in this pipeline:

- `paginate_blocks/4` recursion collects ALL pages first (reversed accumulator)
- `Enum.reverse()` produces the ordered page list — at this point `length` is exact
- `apply_page_template` is called inside the subsequent `Enum.with_index` map

Total page count is available in the same pass, at the same callsite where per-page tokens are
already being substituted. A second render path is not needed and must not be introduced.

### Token Resolution Expansion

Extend `replace_page_numbers/2` to `replace_running_tokens/3`:

```elixir
# Signature change: add total_pages
defp replace_running_tokens(blocks, page_num, total_pages) do
  Enum.map(blocks, fn block ->
    case block.content do
      %Rendro.Text{content: text} = t ->
        replaced =
          text
          |> String.replace("{{page_number}}", Integer.to_string(page_num))
          |> String.replace("{{total_pages}}", Integer.to_string(total_pages))
        %{block | content: %{t | content: replaced}}

      %Rendro.Pipeline.MeasuredText{source: %Rendro.Text{content: text} = source} = measured ->
        # Replace in both source text and rendered lines (same pattern as existing impl)
        replaced_text =
          text
          |> String.replace("{{page_number}}", Integer.to_string(page_num))
          |> String.replace("{{total_pages}}", Integer.to_string(total_pages))
        %{block | content: %{measured |
            source: %{source | content: replaced_text},
            lines: replace_in_measured_lines(measured.lines, page_num, total_pages)
          }}

      _ ->
        block
    end
  end)
end
```

Updated `apply_page_template/4` signature (add `total_pages`):

```elixir
defp apply_page_template(%Page{} = page, idx, layout, total_pages) do
  anchored_blocks =
    layout.template.regions
    |> Enum.reject(&(&1.name == :body))
    |> Enum.flat_map(fn region ->
      layout.region_blocks
      |> Map.get(region.name, [])
      |> replace_running_tokens(idx, total_pages)   # was: replace_page_numbers(_, idx)
      |> anchor_region_blocks(region, page)
      |> then(&maybe_validate_region_fit(&1, region, page, idx, region.name))
    end)

  %{page | blocks: anchored_blocks ++ page.blocks}
end
```

Updated callsite in `paginate_flow/1`:

```elixir
pages_reversed = ...  # result of paginate_blocks recursion + Enum.reverse
total_pages = length(pages_reversed)

pages =
  pages_reversed
  |> Enum.with_index(1)
  |> Enum.map(fn {page, idx} ->
    page
    |> stack_body_blocks(layout.body_region)
    |> validate_body_region_fit!(layout.body_region, idx)
    |> apply_page_template(idx, layout, total_pages)   # pass total_pages
  end)
```

### Carried-Forward Running Totals

Running totals (e.g., "Balance carried forward: $X") are a data-level concern, not a
layout-level concern. The correct seam is in the recipe, not the pipeline:

- Recipe's `sections/2` receives the full `data` map
- `sections/2` computes `balance_forward` (or similar) from item sums before constructing blocks
- The footer section block receives a pre-computed string: `"Balance forward: $#{balance}"`
- No pipeline state changes. No new struct fields on `%Rendro.Document{}`

This keeps the pipeline deterministic and the recipe layer responsible for business logic.

### Repeated Header/Footer Region Content

Already works. `apply_page_template/3` stamps `layout.region_blocks[:header]` and
`layout.region_blocks[:footer]` onto every page. No changes needed for the "same header/footer
on every page" use case. The `{{total_pages}}` token just makes repeated footers more useful.

## Component Classification: New vs Modified

| Component | Status | Risk | Notes |
|-----------|--------|------|-------|
| `lib/rendro/pipeline/paginate.ex` | **MODIFIED** | Medium | Rename `replace_page_numbers/2` to `replace_running_tokens/3`; add `total_pages` param to `apply_page_template`. Additive change to private functions. Existing `{{page_number}}` behavior is preserved exactly; backward-compatible at the authoring API level. |
| `lib/rendro/recipes/base.ex` | **NEW** | Low | `@moduledoc false` private helper module. Extracts the `assemble_document/3` loop shared by all recipes. Not public API. |
| `lib/rendro/recipes/statement.ex` | **NEW** | Low | Three-rung pattern. Uses `{{page_number}}` / `{{total_pages}}` in footer. Depends on Paginate modification landing first. |
| `lib/rendro/recipes/receipt.ex` | **NEW** | Low | Three-rung pattern. Multi-page report variant. Uses running tokens in footer. |
| `lib/rendro/recipes/certificate.ex` | **NEW** | Low | Three-rung pattern. Single-page variant. Running tokens optional. |
| `lib/rendro/recipes.ex` | **MODIFIED** | Low | Add `statement/1`, `receipt/1`, `certificate/1` delegate functions alongside existing `invoice/1`, `branded_invoice/1`. |
| `examples/phoenix_example` (controllers) | **MODIFIED** | Low | Add Statement/Receipt/Certificate controllers. |
| `examples/phoenix_example/test/` | **NEW** | Low | Smoke-test suite (render-level, no HTTP layer). Renders each recipe and asserts `{:ok, <<_::binary>>}`. |
| `examples/phoenix_example/README.md` | **NEW** | Low | How to run, endpoints, `mix test` instruction. |
| `.github/workflows/ci.yml` — `test` job | **MODIFIED** | Low | Upgrade "Verify Phoenix Example" step from `mix compile` to `mix test`. |

**Risk summary:** The only medium-risk change is `Paginate`. It modifies a private function that
is currently tested end-to-end. The change is strictly additive (new parameter, new token), the
existing `{{page_number}}` substitution is preserved, and no public API changes. Everything else
is new files or low-risk extensions to facades.

## Shared Recipe Scaffolding

### What Exists

`Invoice` and `BrandedInvoice` share an identical `document/2` assembly pattern:

```elixir
base_doc =
  Rendro.Document.new()
  |> Rendro.Document.add_template(template)
  |> Rendro.Document.set_template(template.name)

Enum.reduce(secs, base_doc, fn section, doc ->
  Rendro.Document.add_section(doc, section)
end)
```

`BrandedInvoice` adds font/image registration before this loop. Three new recipes will
reproduce this loop verbatim without extraction.

### What to Extract

Extract the assembly loop into `Rendro.Recipes.Base` (new `@moduledoc false` module):

```elixir
defmodule Rendro.Recipes.Base do
  @moduledoc false

  def assemble_document(template, sections, extra_setup \\ & &1) do
    Rendro.Document.new()
    |> extra_setup.()
    |> Rendro.Document.add_template(template)
    |> Rendro.Document.set_template(template.name)
    |> then(fn doc ->
      Enum.reduce(sections, doc, &Rendro.Document.add_section(&2, &1))
    end)
  end
end
```

The `extra_setup` callback handles the branded case (font + image registration).
This is a safe internal extraction — it does not change public API and is not externally
visible. All five recipes (`Invoice`, `BrandedInvoice`, `Statement`, `Receipt`, `Certificate`)
use it.

### What Not to Extract

Do not extract `page_template/1` or `sections/2` into a shared behaviour or callback module.
Each recipe's template geometry and section content is unique; a shared behaviour would force
an artificial common shape onto them and complicate the three-rung escape-hatch pattern.

### Recipe-Specific Running Region Usage

| Recipe | `{{page_number}}` | `{{total_pages}}` | Running totals |
|--------|------------------|--------------------|----------------|
| Statement | footer | footer | balance_forward computed in `sections/2` from data |
| Receipt/Report | footer | footer | subtotals in table rows, computed at authoring time |
| Certificate | optional header | optional header | n/a (single page typical) |

## Reference Phoenix App Integration

### Current State

`examples/phoenix_example/mix.exs` uses `{:rendro, path: "../.."}` — already correct.
`PDFController` has `download/2`, `preview/2`, `branded_download/2`, `branded_preview/2`.

The CI `test` job currently runs:

```yaml
- name: Verify Phoenix Example
  run: |
    cd examples/phoenix_example
    mix deps.get
    mix compile
```

It compiles but does not run tests. No `test/` directory exists in the example.

### Integration Boundary (Preserved)

`Rendro.Adapters.Phoenix` guards itself with `Code.ensure_loaded?(Plug.Conn) and
Code.ensure_loaded?(Phoenix)` — Phoenix is never pulled into core. The core test suite
never requires Phoenix. This boundary must be preserved exactly.

### Target State

1. Add controllers for the three new recipes in `examples/phoenix_example/lib/`
2. Add `examples/phoenix_example/test/` with render-smoke tests (no HTTP layer):
   ```elixir
   # examples/phoenix_example/test/pdf_render_test.exs
   defmodule PhoenixExample.PDFRenderTest do
     use ExUnit.Case
     test "Statement renders without error" do
       data = %{...}
       assert {:ok, <<_::binary>>} = Rendro.Recipes.Statement.document(data) |> Rendro.render()
     end
     # ... one test per recipe
   end
   ```
3. Add `examples/phoenix_example/README.md` — `mix deps.get && mix phx.server`, endpoint list,
   `mix test` instruction
4. Upgrade CI step to `mix test` (no new required status check — runs inside existing `test` job)

## System Overview Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      Authoring Layer (unchanged API)                     │
│   Rendro.flow/2  Rendro.fixed/2  Rendro.Document.*  Rendro.Recipes.*    │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────────────┐
│                  Pipeline (build→compose→measure→paginate→validate→render) │
│                                                                           │
│   Compose: region_blocks assembled                                        │
│     %{header: [blocks with "{{page_number}}" tokens],                    │
│       body:   [content blocks],                                           │
│       footer: [blocks with "{{total_pages}}" tokens]}                    │
│                                                                           │
│   Paginate: ALL pages collected first, then final pass                    │
│     total_pages = length(pages)   ← computed HERE, single pass           │
│     apply_page_template(page, idx, layout, total_pages)                  │
│       → replace_running_tokens(footer_blocks, idx, total_pages)          │
│         "Page {{page_number}} of {{total_pages}}"                        │
│         → "Page 3 of 7"                               ← resolved here    │
│                                                                           │
│   Render: resolved strings → PDF content streams                         │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────────────┐
│                      Recipe Layer (three-rung pattern)                   │
│                                                                           │
│   Rendro.Recipes.Base         (NEW, @moduledoc false)                    │
│     assemble_document/3       (shared Document assembly loop)            │
│                                                                           │
│   Rendro.Recipes.Invoice      (unchanged)                                │
│   Rendro.Recipes.BrandedInvoice (unchanged)                              │
│   Rendro.Recipes.Statement    (NEW)                                      │
│   Rendro.Recipes.Receipt      (NEW)                                      │
│   Rendro.Recipes.Certificate  (NEW)                                      │
│                                                                           │
│   Each recipe: document/2 → page_template/1 + sections/2                 │
│   sections/2 computes running totals from data BEFORE building blocks    │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────────────┐
│              Reference App (examples/phoenix_example — isolated)         │
│   {:rendro, path: "../.."}   ← path dep, Phoenix never in core          │
│   Rendro.Adapters.Phoenix    ← Code.ensure_loaded? guard preserved      │
│   Smoke tests: render each recipe, assert {:ok, binary}                 │
│   CI: mix test inside existing test job step                             │
└─────────────────────────────────────────────────────────────────────────┘
```

## Recommended Project Structure

```
lib/rendro/
├── pipeline/
│   └── paginate.ex            MODIFIED: replace_running_tokens/3
├── recipes/
│   ├── base.ex                NEW (@moduledoc false)
│   ├── invoice.ex             unchanged
│   ├── branded_invoice.ex     unchanged
│   ├── statement.ex           NEW
│   ├── receipt.ex             NEW
│   └── certificate.ex         NEW
└── recipes.ex                 MODIFIED: add 3 delegate functions

examples/phoenix_example/
├── README.md                  NEW
├── mix.exs                    unchanged
├── lib/
│   └── phoenix_example_web/
│       └── controllers/
│           ├── pdf_controller.ex         unchanged
│           ├── statement_controller.ex   NEW
│           ├── receipt_controller.ex     NEW
│           └── certificate_controller.ex NEW
└── test/
    └── pdf_render_test.exs               NEW

.github/workflows/ci.yml       MODIFIED (mix test upgrade in test job)
```

## Data Flow for Running Token Resolution

```
Author time:
  Rendro.text("Page {{page_number}} of {{total_pages}}", size: 9)
       ↓ Rendro.block(text) → placed in footer section content

Compose stage:
  footer blocks → layout.region_blocks[:footer]
  (token strings survive compose unchanged)

Measure stage:
  MeasuredText wraps raw text; token strings survive measurement intact
  (measurement uses string width — tokens are just strings at this point)

Paginate stage:
  paginate_blocks/4 → collects all pages (reversed accumulator)
  pages_reversed = Enum.reverse(accumulator)
  total_pages = length(pages_reversed)        ← SINGLE PASS, computed here
  Enum.with_index(1) → (page, idx) pairs
  apply_page_template(page, idx, layout, total_pages)
    → replace_running_tokens(footer_blocks, idx, total_pages)
      → String.replace("{{page_number}}", "3")
      → String.replace("{{total_pages}}", "7")
      → applied to both %Rendro.Text{content:} and %MeasuredText{lines:, source:}

Render stage:
  resolved strings → PDF content streams
  (no awareness of tokens — they are already plain strings)
```

## Suggested Build Order

The dependency constraint is firm: recipes use `{{total_pages}}`; the Paginate modification
must land and be proven before any recipe can use it.

| Phase | Work | Status | Why This Order |
|-------|------|--------|----------------|
| Phase 73 | Extend `Paginate`: rename `replace_page_numbers/2` → `replace_running_tokens/3`, add `total_pages` parameter, add `{{total_pages}}` token; unit-test both tokens across 1-page and multi-page documents with header/footer regions | MODIFIED (medium risk) | Foundation all recipes depend on; must be green before recipe work begins |
| Phase 74 | `Rendro.Recipes.Base` extraction: create `base.ex`, refactor `Invoice` + `BrandedInvoice` to use `assemble_document/3`; all existing docs-contract tests pass unchanged | NEW + MODIFIED (low risk) | De-risks the extraction before three new consumers are built; pure refactor with no behavior change |
| Phase 75 | `Rendro.Recipes.Statement`: three-rung pattern, `{{page_number}}/{{total_pages}}` in footer, running balance from data in `sections/2`, docs-contract test, guide entry | NEW (low risk) | Highest-value recipe (multi-page financial); first exercise of the new tokens in a full recipe |
| Phase 76 | `Rendro.Recipes.Receipt` + `Rendro.Recipes.Certificate`: three-rung pattern each, docs-contract tests, guide entries | NEW (low risk) | Lower complexity; Certificate is typically single-page; batch together to reduce ceremony |
| Phase 77 | Reference Phoenix app upgrade: new controllers for all three recipes, `mix test` smoke tests, README, CI step from `mix compile` → `mix test` | MODIFIED (low risk) | Depends on all recipes existing; isolated to `examples/`; no core changes |

## Anti-Patterns to Avoid

### Anti-Pattern 1: Two-Pass Render for Total Page Count

**What people do:** Paginate once to count pages, store the count, then invoke the full
pipeline again with the count injected into authored content blocks.

**Why it's wrong:** Doubles render latency, complicates determinism reasoning, requires a
second pipeline invocation, and is completely unnecessary — total page count is available in a
single pass in this architecture. `length(pages)` is known after `Enum.reverse()` and before
`apply_page_template` is called.

**Do this instead:** Compute `total_pages = length(pages_reversed)` inside `paginate_flow/1`,
pass it to `apply_page_template/4`, substitute in `replace_running_tokens/3`.

### Anti-Pattern 2: New Pipeline Stage for Running Regions

**What people do:** Add a `RunningRegion` stage between `Paginate` and `Render` that walks
the fully-paginated document and substitutes tokens.

**Why it's wrong:** Increases pipeline surface area, requires updating all pipeline stage
tests, and the substitution already happens inside `apply_page_template` at exactly the right
moment. Adding a stage adds complexity with no benefit.

**Do this instead:** Extend `replace_page_numbers/2` in place (rename + add parameter).
The token substitution is already in the right location.

### Anti-Pattern 3: Running Totals in Pipeline State

**What people do:** Add `running_totals: map()` to `%Rendro.Document{}`, populate it during
`Measure`, read it during `Paginate` to inject footer values dynamically.

**Why it's wrong:** Running totals are data-level (business logic), not layout-level (geometry).
Adding them to `%Document{}` widens the core struct and couples business semantics to the
rendering contract. It also makes recipes harder to test independently.

**Do this instead:** Compute running totals in the recipe's `sections/2` from `data` before
constructing blocks. The footer block receives a pre-computed string. The pipeline never knows.

### Anti-Pattern 4: Adding Phoenix Dep to Core

**What people do:** Move reference app tests into the main test suite and add
`{:phoenix, ...}` to the core `mix.exs` under `:test` or `:dev`.

**Why it's wrong:** Forces every consumer of `:rendro` to resolve Phoenix in their dependency
graph. Corrupts the pure-Elixir core contract. Contradicts `PROJECT.md` constraints.

**Do this instead:** Keep all Phoenix integration tests in `examples/phoenix_example/test/`.
The CI `test` job step already enters the example directory as a separate shell step.

### Anti-Pattern 5: New Required CI Branch Protection Check for the Example

**What people do:** Add a new required `phoenix-example` job to `.github/workflows/ci.yml`
and wire it into branch protection.

**Why it's wrong:** The example check already runs inside the existing `test` job. Adding a
separate required job duplicates compilation time and implies a different category of proof.
The existing `test` job is already required on `main`.

**Do this instead:** Upgrade the shell step inside the existing `test` job from `mix compile`
to `mix test`. No new branch protection entry needed.

## Integration Points Summary

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `Paginate` → `replace_running_tokens/3` | Private function call | `{{page_number}}` + `{{total_pages}}` substituted in same pass; `{{page_number}}` backward-compatible |
| `Recipes.Base` → new recipes | Internal module call (`@moduledoc false`) | Not public API; used only within `Rendro.Recipes.*` |
| `Rendro.Recipes` facade → new recipes | Public function delegation | `statement/1`, `receipt/1`, `certificate/1` added alongside existing delegates |
| Core lib ↔ `examples/phoenix_example` | `{:rendro, path: "../.."}` in example `mix.exs` | Phoenix never in core `mix.exs`; `Code.ensure_loaded?` guard preserved in adapter |
| CI `test` job ↔ example | Shell step in `.github/workflows/ci.yml` | Upgrade from `mix compile` to `mix test`; no new required status check |
| `sections/2` ↔ running totals | Data passed through `data` map at authoring time | Pipeline-transparent; recipe computes totals before constructing blocks |

## Sources

- Direct inspection: `lib/rendro/pipeline/paginate.ex` — `replace_page_numbers/2`, `apply_page_template/3`, `paginate_flow/1`, the `Enum.reverse |> Enum.with_index` pattern
- Direct inspection: `lib/rendro/pipeline/pipeline.ex` — stage sequencing in `run_stages/5`
- Direct inspection: `lib/rendro/pipeline/compose.ex` — `region_blocks` assembly from sections + document header/footer fields
- Direct inspection: `lib/rendro/pipeline/measure.ex` — confirms token strings survive measurement (MeasuredText wraps source text)
- Direct inspection: `lib/rendro/recipes/invoice.ex` — three-rung pattern canonical implementation
- Direct inspection: `lib/rendro/recipes/branded_invoice.ex` — three-rung pattern with `extra_setup` (font/image registration)
- Direct inspection: `lib/rendro/recipes.ex` — delegate facade
- Direct inspection: `lib/rendro/document.ex` — `%Document{}` struct fields, builder API
- Direct inspection: `lib/rendro/adapters/phoenix.ex` — `Code.ensure_loaded?` guard pattern
- Direct inspection: `examples/phoenix_example/mix.exs` — path dep, no Phoenix in core
- Direct inspection: `examples/phoenix_example/lib/phoenix_example_web/controllers/pdf_controller.ex` — current endpoint shape
- Direct inspection: `.github/workflows/ci.yml` — existing `test` job structure, current "Verify Phoenix Example" step
- Direct inspection: `.planning/PROJECT.md` — v2.4 constraints, pipeline non-negotiables
- Direct inspection: `.planning/threads/v24-adoption-scoping.md` — v2.4 scope findings and adoption gap analysis

---
*Architecture research for: Rendro v2.4 — page-numbering/running-region primitive, Statement/Receipt/Certificate recipes, reference Phoenix app*
*Researched: 2026-05-29*

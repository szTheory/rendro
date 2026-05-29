# Phase 73: Page-Numbering / Running-Region Primitive - Research

**Researched:** 2026-05-29
**Domain:** Elixir PDF pipeline — paginate/measure stages, running-region API, determinism contract
**Confidence:** HIGH — all findings verified against live source files in this session

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Per-page function `fn {page_number, total_pages} -> content end` is the primitive. Named helper and token strings lower to it.
- **D-02:** Evaluation at `replace_page_numbers/2` (paginate.ex:414), called from `Enum.with_index(1)` map where `total = length(pages)` is already available — single-pass.
- **D-03:** Function signature is `fn {page_number, total_pages} -> content end`; public surface inherited by recipes 74–76.
- **D-04:** `body_capacity` = `body_region.height − header_region.height − footer_region.height`. Reads heights already on `Rendro.Region`. Default 0 → no-op for today's default template.
- **D-05:** No engine auto-measure of region content in this phase.
- **D-06:** Deferred — `height: :auto` is out of scope.
- **D-07:** Declarative selector `skip_first: true` / `pages: :except_first` as sugar; function returning `nil`/`[]` is always-available escape hatch.
- **D-08:** Suppression hides rendering but NEVER reclaims reserved height. `body_capacity` stays uniform across all pages.
- **D-09:** Reserved region height is a pure function of declared layout geometry only — independent of per-page content, page index, and digit-width of tokens.
- **D-10:** `{{total_pages}}` follows the existing `{{page_number}}` path in `replace_page_numbers/2` — rewrite `MeasuredText.source.content` and per-run `.text` only; never re-run measurement.
- **D-11:** Determinism test MUST assert all four properties: (a) byte-identical; (b) `body_capacity` identical for 9-page vs 100+-page; (c) page count and body-block assignment identical regardless of `{{total_pages}}` vs static wide placeholder; (d) `replace_page_numbers/2` leaves `MeasuredText.lines` geometry and block `height` unchanged before vs. after substitution.

### Claude's Discretion

- Exact module/typespec placement for `page_number/1` helper (`lib/rendro.ex` ~lines 199–207).
- Internal representation of a "lowered" function vs token string; field name/shape for suppression selector (`suppress_on:` vs `pages:`).
- Error/validation behavior for under-sized region or malformed function arity (reuse `maybe_validate_region_fit`).

### Deferred Ideas (OUT OF SCOPE)

- `height: :auto` (auto-measured region height, measure-once-then-freeze).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAGE-01 | Single-pass "Page X of Y" — Y resolves to real total with no second render | D-02/D-10: `total = length(pages)` already available at `Enum.with_index(1)` map; `replace_page_numbers/2` is the correct post-pagination substitution site |
| PAGE-02 | Running region content authorable as `fn {page_number, total_pages} -> content end`; named helper; suppressible on first page | D-01/D-03/D-07: function primitive, sugar lowering, declarative selector in `Rendro.Section` content typespec |
| PAGE-03 | `body_capacity` subtracts header/footer heights — body content never overlaps running footer | D-04: two fix sites confirmed — `measure.ex:442` and `paginate.ex:494`; `compose.ex` already populates `layout.header_region` and `layout.footer_region` |
| PAGE-04 | Deterministic, test-covered; byte-identical output; no convergence loop | D-09/D-10/D-11: fixed-geometry invariant, text-only substitution, four-property test |
</phase_requirements>

---

## Summary

Phase 73 is a surgical extension of two existing pipeline stages — `Measure` and `Paginate` — plus a narrow new API surface on `Rendro.Section` and `Rendro.` (top-level). Every design decision is locked in CONTEXT.md and all cited code seams have been verified against live source in this session. The line numbers in CONTEXT.md have drifted slightly from the actual file (see verification table below), but the logic descriptions are accurate.

The single most important finding: `body_capacity` is computed in **two places** that are architecturally distinct. `measure.ex:442` is called for documents with explicit `layout` from `Compose` (the typical recipe flow). `paginate.ex:494` inside `flow_layout/1` is the fallback for documents passed directly to `paginate_flow` without going through `Build`/`Compose`. Both must be fixed simultaneously for PAGE-03, but they have different fix patterns.

`Compose.run/1` already populates `layout.header_region` and `layout.footer_region` on the layout map (compose.ex:94–95). The `body_capacity` fix in `measure.ex` can read `layout.header_region.height` and `layout.footer_region.height` directly — no new struct fields needed. The `paginate.ex` fallback must also inspect the template's header/footer regions.

The `replace_page_numbers/2` function at paginate.ex:414 handles both `Rendro.Text` content (pre-measure, for fixed documents) and `Rendro.Pipeline.MeasuredText` (post-measure). The `{{total_pages}}` extension is a two-character addition to two `String.replace` calls and two run-text loops in the same function — it does not require touching geometry fields.

**Primary recommendation:** Implement changes wave-by-wave: (1) body_capacity fix in both sites, (2) extend replace_page_numbers/2 for {{total_pages}}, (3) add fn/suppression API surface, (4) write the four D-11 determinism assertions.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `{{page_number}}` substitution | Pipeline / Paginate stage | — | Post-pagination; page index is only known here |
| `{{total_pages}}` substitution | Pipeline / Paginate stage | — | `total = length(pages)` computed here; no second pass |
| `body_capacity` computation | Pipeline / Measure stage | Paginate fallback | Measure owns layout; Paginate has a no-compose fallback that must match |
| Per-page function evaluation | Pipeline / Paginate stage | — | Called from same `Enum.with_index(1)` map as token substitution |
| Suppression selector resolution | Pipeline / Paginate stage | — | Evaluated at `apply_page_template/3` per page |
| `page_number/1` named helper | Public API (`Rendro` module) | — | Near `region/1`/`section/1` at lib/rendro.ex:199–207 |
| Content typespec widening | `Rendro.Section` struct | `Rendro.Region` struct | `content:` field holds new function shape |
| Region height reservation | `Rendro.Region` struct | `Rendro.PageTemplate` | `height:` field already exists; just needs to be non-zero for header/footer |

---

## Verified Code Seams

All seams from CONTEXT.md verified against live code. Line numbers updated to actuals.

### `replace_page_numbers/2` — paginate.ex (ACTUAL: lines 414–455)

```elixir
# VERIFIED against live source: paginate.ex:414-455
defp replace_page_numbers(blocks, page_num) do
  Enum.map(blocks, fn block ->
    case block.content do
      %Rendro.Text{content: text} = t ->
        # Handles pre-measure Rendro.Text (fixed documents)
        %{block | content: %{t | content: String.replace(text, "{{page_number}}", Integer.to_string(page_num))}}

      %Rendro.Pipeline.MeasuredText{source: %Rendro.Text{content: text} = source} = measured ->
        # Handles post-measure MeasuredText (flow documents)
        replaced = String.replace(text, "{{page_number}}", Integer.to_string(page_num))
        %{block | content: %{measured |
            source: %{source | content: replaced},
            lines: Enum.map(measured.lines, fn line ->
              Enum.map(line, fn run ->
                %{run | text: String.replace(run.text, "{{page_number}}", Integer.to_string(page_num))}
              end)
            end)
          }
        }

      _ -> block
    end
  end)
end
```

**Extension pattern for `{{total_pages}}`:** Add a second `String.replace/3` call chained after each existing `page_number` replace — or pass both `page_num` and `total` and do both in one map pass. The run `width` fields in the lines must NOT be touched — only the `.text` string. This is D-10's invariant.

**Caller site** — paginate.ex:397–412 `apply_page_template/3`:
```elixir
# VERIFIED: paginate.ex:397-412
defp apply_page_template(%Page{} = page, idx, layout) do
  anchored_blocks =
    layout.template.regions
    |> Enum.reject(&(&1.name == :body))
    |> Enum.flat_map(fn region ->
      anchored_region_blocks =
        layout.region_blocks
        |> Map.get(region.name, [])
        |> replace_page_numbers(idx)          # <-- extend to replace_page_numbers(idx, total) after
        |> anchor_region_blocks(region, page)

      maybe_validate_region_fit(anchored_region_blocks, region, page, idx, region.name)
    end)

  %{page | blocks: anchored_blocks ++ page.blocks}
end
```

The `total` value needed for the extension must be threaded into `apply_page_template/3` from the `Enum.with_index(1)` map at paginate.ex:35–41. Currently the map signature is `fn {page, idx} ->`. After the fix it becomes `fn {page, idx} -> ... apply_page_template(page, idx, layout, total)`.

**`Enum.with_index(1)` map** — paginate.ex:33–41 (ACTUAL lines):
```elixir
pages =
  pages
  |> Enum.reverse()
  |> Enum.with_index(1)
  |> Enum.map(fn {page, idx} ->
    page
    |> stack_body_blocks(layout.body_region)
    |> validate_body_region_fit!(layout.body_region, idx)
    |> apply_page_template(idx, layout)   # <-- add total as 4th arg
  end)
```

`total = length(pages)` is derivable here before the `Enum.map` (from the reversed, finalized list).

### `body_capacity/1` — measure.ex (ACTUAL: lines 442–443)

```elixir
# VERIFIED: measure.ex:442-443
defp body_capacity(%{body_region: %Region{height: height}}) when is_number(height), do: height
defp body_capacity(_layout), do: 0
```

**Current behavior:** Returns `body_region.height` verbatim. Ignores `header_region` and `footer_region` heights entirely.

**D-04 target:** `body_region.height - (header_region?.height || 0) - (footer_region?.height || 0)`

**Available inputs:** The layout map passed to `body_capacity/1` comes from `measure_layout/2` at measure.ex:396–418. The layout at this point has the `Compose`-populated keys. Checking compose.ex:90–100:

```elixir
# VERIFIED: compose.ex:90-100 — layout map shape after Compose
layout = %{
  template: template,
  region_map: region_map,
  body_region: Map.get(region_map, :body, default_body_region(template)),
  header_region: Map.get(region_map, :header),    # may be nil if no :header region
  footer_region: Map.get(region_map, :footer),    # may be nil if no :footer region
  region_blocks: region_blocks,
  entries: entries
}
```

`header_region` and `footer_region` are `Rendro.Region.t()` or `nil`. `Rendro.Region.height` defaults to `nil` (struct defstruct). Pattern match must guard both nil and 0.

**Fix:**
```elixir
defp body_capacity(%{
  body_region: %Region{height: body_h},
  header_region: header_region,
  footer_region: footer_region
}) when is_number(body_h) do
  header_h = (header_region && header_region.height) || 0
  footer_h = (footer_region && footer_region.height) || 0
  body_h - header_h - footer_h
end
defp body_capacity(_layout), do: 0
```

### `flow_layout/1` fallback — paginate.ex (ACTUAL: lines 478–501)

```elixir
# VERIFIED: paginate.ex:478-501
defp flow_layout(%Document{} = doc) do
  template = %PageTemplate{}
  body_region = %Region{...height: template.height - template.margin_top - template.margin_bottom}
  %{
    template: template,
    body_region: body_region,
    body_capacity: body_region.height,   # <-- BUG: second body_capacity site
    region_blocks: %{body: doc.content, header: doc.header, footer: doc.footer}
  }
end
```

This fallback runs only when a document reaches `Paginate.run/1` without going through `Build`/`Compose`/`Measure` (e.g. in older-style tests or direct pipeline invocations). It does NOT have `header_region`/`footer_region` keys because `Compose` was never run.

**Fix approach:** Derive header/footer heights from the default `%PageTemplate{}` regions list — the default template (page_template.ex:18–46) has `header.height: 0` and `footer.height: 0`, so the fix is a no-op for default usage. But it must subtract properly when a caller provides custom regions. The fallback must mirror the measure.ex fix by finding `:header`/`:footer` from `template.regions`.

### `Rendro.Region` struct — region.ex (ACTUAL: lines 1–27)

Fields: `name`, `role`, `anchor`, `x`, `y`, `width`, `height`. All default to `nil` except `role: :body`, `anchor: :flow`, `x: 0`, `y: 0`. `height: nil` means zero for subtraction purposes.

**Default PageTemplate regions** (page_template.ex:18–46):
- `:header` — `height: 0`
- `:body` — `height: 697.89` (= 841.89 - 72 - 72)
- `:footer` — `height: 0`

With the D-04 fix, default template `body_capacity` = 697.89 - 0 - 0 = 697.89 (no regression). A recipe that sets footer height to 30 will have `body_capacity` = 667.89.

### `Rendro.Section` struct — section.ex (ACTUAL: lines 1–20)

```elixir
defstruct name: nil,
          region: :body,
          content: [],       # <-- current: [Rendro.Block.t()]
          page_template: nil,
          options: %{}

@type t :: %__MODULE__{
  content: [Rendro.Block.t()],   # <-- needs widening for fn and suppression
  options: %{optional(atom()) => term()}
}
```

**Extension needed for PAGE-02:** Add suppression selector field (`:suppress_on` or place in `:options`), and widen `content:` typespec to accept a per-page function. The function lives at the **block** level (a block's content may be a function), not the section level — sections are region containers.

### `Rendro.Block` struct

Blocks are the atomic content unit. A "running region block" carrying a per-page function would be a new content variant. Current content types: `Rendro.Text`, `Rendro.Table`, `Rendro.Image`, `Rendro.FormField`, `Rendro.Link`, `Rendro.Pipeline.MeasuredText`. The function `fn {pn, tp} -> [Block.t()] end` is a new content variant that must be evaluated before rendering, not stored as-is in the final page.

### `maybe_validate_region_fit/5` — paginate.ex (ACTUAL: lines 590–602)

```elixir
defp maybe_validate_region_fit(blocks, %Region{} = region, %Page{} = page, page_index, region_name) do
  if bounded_region?(region) do
    validate_region_fit!(blocks, region, page, page_index, region_name)
  else
    blocks
  end
end
```

`bounded_region?/1` (line 679) requires both `width > 0` and `height > 0`. A footer with `height: 0` skips validation. This means the existing fit-check reuse path for under-sized-region errors is already available when non-zero heights are used.

---

## Standard Stack

No new Hex dependencies. [VERIFIED: REQUIREMENTS.md scope note: "All features implementable with zero new runtime Hex dependencies."]

### Core (unchanged)
| Module | Path | Purpose in Phase 73 |
|--------|------|----------------------|
| `Rendro.Pipeline.Paginate` | `lib/rendro/pipeline/paginate.ex` | Extend `replace_page_numbers/2`, thread `total`, evaluate per-page fn, apply suppression |
| `Rendro.Pipeline.Measure` | `lib/rendro/pipeline/measure.ex` | Fix `body_capacity/1` (PAGE-03 primary site) |
| `Rendro.Region` | `lib/rendro/region.ex` | Existing `height:` field is sufficient; no struct changes |
| `Rendro.Section` | `lib/rendro/section.ex` | Widen `content:` typespec; add suppression field |
| `Rendro` (top-level) | `lib/rendro.ex` | Add `page_number/1` helper near `region/1`/`section/1` (lines 199–207) |

---

## Package Legitimacy Audit

No external packages are installed in this phase. Zero new runtime Hex dependencies.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Document authored with running footer section
  (region: :footer, content: [block with fn or token])
        |
        v
  Build.run/1
  (sections → content/header/footer block lists)
        |
        v
  Compose.run/1
  (layout map built: body_region, header_region, footer_region, region_blocks)
        |
        v
  Measure.run/1
  (measures all region blocks including footer; body_capacity FIXED = body_h - header_h - footer_h)
        |
        v
  Paginate.run/1
  (paginate_flow: body blocks distributed across pages using body_capacity)
        |
        v
  pages reversed → Enum.with_index(1) map
  total = length(pages) computed once
        |
        for each {page, idx}:
          v
        apply_page_template(page, idx, layout, total)
          |
          for each non-body region:
            v
          blocks = layout.region_blocks[region.name]
               |
               v
          [NEW] evaluate fn blocks with {idx, total}   (PAGE-02)
               |
               v
          [NEW] apply suppression selector              (PAGE-02)
               |
               v
          replace_page_numbers(blocks, idx, total)      (PAGE-01 extended)
          (token strings → final text, fn already evaluated)
               |
               v
          anchor_region_blocks(region, page)
               |
               v
          maybe_validate_region_fit(...)
        |
        v
  Final pages with substituted, anchored region blocks
```

### Recommended Project Structure (additions)

```
lib/
├── rendro.ex                         # add page_number/1 helper (~line 207)
├── rendro/
│   ├── section.ex                    # widen content typespec, add suppress_on field
│   ├── pipeline/
│   │   ├── measure.ex                # fix body_capacity/1
│   │   └── paginate.ex               # extend replace_page_numbers/2, thread total
test/
├── rendro/
│   ├── flow_test.exs                 # extend existing {{page_number}} tests for {{total_pages}}
│   ├── pipeline/
│   │   ├── measure_test.exs          # body_capacity fix regression tests
│   │   └── paginate_test.exs         # fn evaluation, suppression, total_pages substitution
│   └── deterministic_test.exs        # D-11 four-property assertions (new describe block)
```

### Pattern 1: Extending `replace_page_numbers/2` for total_pages and fn evaluation

The function takes `blocks` (region blocks for one page) and currently accepts only `page_num`. The extension adds `total` as a second integer parameter and evaluates any "function blocks" before doing token substitution.

**Evaluation order (D-01/D-02):** Evaluate the function first (producing concrete content blocks), then run token substitution on the result. Token strings are sugar that lowers to the same path — at authoring time the `Rendro.page_number/1` helper produces a block whose content is `{{page_number}}` / `{{total_pages}}` strings, so evaluation produces a `Rendro.Text` with those tokens, then substitution fires on the text.

```elixir
# Extended signature (illustrative, not prescriptive)
defp replace_page_numbers(blocks, page_num, total) do
  blocks
  |> Enum.map(&evaluate_fn_block(&1, page_num, total))
  |> Enum.map(&substitute_page_tokens(&1, page_num, total))
end

defp evaluate_fn_block(%Rendro.Block{content: fun} = block, page_num, total)
     when is_function(fun, 1) do
  case fun.({page_num, total}) do
    nil -> nil           # suppressed via fn returning nil
    [] -> nil
    content_blocks when is_list(content_blocks) ->
      # replace block content with evaluated blocks (or a wrapper)
      %{block | content: content_blocks}
    single_block -> %{block | content: single_block}
  end
end
defp evaluate_fn_block(block, _page_num, _total), do: block
```

The suppression selector (D-07/D-08) fires before function evaluation: if the selector says suppress, the block renders empty (returns `nil`/`[]`) but the region's geometry is preserved.

### Pattern 2: `body_capacity` fix in `measure.ex`

```elixir
# BEFORE (measure.ex:442-443) — ignores header/footer
defp body_capacity(%{body_region: %Region{height: height}}) when is_number(height), do: height
defp body_capacity(_layout), do: 0

# AFTER (D-04)
defp body_capacity(%{
  body_region: %Region{height: body_h},
  header_region: header_region,
  footer_region: footer_region
}) when is_number(body_h) do
  header_h = (is_nil(header_region) or is_nil(header_region.height)) && 0 || header_region.height
  footer_h = (is_nil(footer_region) or is_nil(footer_region.height)) && 0 || footer_region.height
  body_h - header_h - footer_h
end
defp body_capacity(_layout), do: 0
```

The planner should also specify idiomatic nil/0 guard — the cleanest Elixir pattern is:
```elixir
header_h = if header_region, do: header_region.height || 0, else: 0
footer_h = if footer_region, do: footer_region.height || 0, else: 0
```

### Pattern 3: `page_number/1` helper in `lib/rendro.ex`

Placed after `section/1` at approximately line 207. Returns a `Rendro.Block` containing a `Rendro.Text` with `{{page_number}}` and `{{total_pages}}` tokens in the appropriate format, or alternatively returns a content-function block directly.

The simplest implementation consistent with D-01 (function is the primitive, tokens are sugar):
```elixir
@spec page_number(keyword()) :: Rendro.Block.t()
def page_number(opts \\ []) do
  format = Keyword.get(opts, :format, "Page {{page_number}} of {{total_pages}}")
  text_opts = Keyword.drop(opts, [:format])
  block(text(format, text_opts))
end
```

This produces a `Rendro.Text` with the token strings. At render time `replace_page_numbers/2` substitutes. The function-based lowering path (D-01) means the planner may also implement this as producing a function block directly.

### Pattern 4: Suppression selector in `Rendro.Section`

The CONTEXT leaves the field name/shape to Claude's Discretion. Idiomatic pattern:

```elixir
# Option A: add :suppress_on field to Section (matches LaTeX \thispagestyle model)
defstruct name: nil,
          region: :body,
          content: [],
          suppress_on: nil,   # nil | :first | {:pages, [integer()]}
          page_template: nil,
          options: %{}

# Usage:
Rendro.section(region: :footer, content: [...], suppress_on: :first)
```

The declarative selector resolves at `apply_page_template/3` before content functions are evaluated. A suppressed page still has the region's geometry reserved (D-08).

### Anti-Patterns to Avoid

- **Re-measuring after substitution:** `replace_page_numbers/2` must ONLY rewrite `.text` strings in existing run structs. Never call `Measure.run/1` on substituted blocks. The run `.width` fields are stale after substitution but that is acceptable — the geometry was already used for layout (D-10).
- **Modifying `body_capacity` per page:** `body_capacity` is a scalar computed once during `Measure.run/1`. It must not vary by page index or by what content is in the running region (D-09).
- **Computing total_pages lazily inside `replace_page_numbers`:** `total = length(pages)` must be computed BEFORE the `Enum.map` over pages, not re-derived inside each iteration.
- **New `measure_region_blocks` call in paginate.ex:** The extension to evaluate fn blocks must not trigger re-measurement. Functions return already-measured blocks or tokens that substitute into pre-measured geometry.
- **Suppression reclaiming height:** D-08 is an iron rule. Even if a footer block is suppressed, `body_capacity` stays the same across all pages.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token substitution across text runs | Custom string walker | Extend existing `replace_page_numbers/2` — two `String.replace` calls per run | Already handles both `Rendro.Text` and `MeasuredText`; regression-tested |
| Region overflow validation | New fit-check logic | `maybe_validate_region_fit/5` (paginate.ex:590) | Already handles bounded vs. unbounded regions correctly |
| Per-page content evaluation | New pipeline stage | Integrate into `replace_page_numbers/2` call site in `apply_page_template/3` | Keeps it single-pass; no new stage ordering issues |
| Determinism in timestamps/IDs | Custom seeding | Existing `deterministic: true` path in `Rendro.render/2` | Already implemented; new tests extend the existing `DeterministicTest` |

**Key insight:** The "second body_capacity call site" in `paginate.ex:flow_layout/1` exists only as a no-Compose fallback. After the fix it must derive header/footer heights from `template.regions` (not from `layout.header_region`, which isn't populated in this path) — this is the one asymmetry between the two sites.

---

## Runtime State Inventory

Not applicable — this is a greenfield addition to the engine. No rename/refactor/migration involved.

---

## Common Pitfalls

### Pitfall 1: Two `body_capacity` sites with different input shapes

**What goes wrong:** Fix `measure.ex:442` but forget `paginate.ex:494` inside `flow_layout/1`. Tests that skip `Compose`/`Measure` (using direct paginate pipeline calls) still use the old value, masking the PAGE-03 bug in a subset of test scenarios.

**Why it happens:** The two sites receive different map shapes. `measure.ex` receives the `Compose`-populated layout (has `header_region`/`footer_region`). `paginate.ex flow_layout/1` builds its own minimal layout map without those keys.

**How to avoid:** Fix both sites in the same commit. The `paginate.ex` fallback must find regions by name from `template.regions` list (not a `region_map` key).

**Warning signs:** Tests that call `Paginate.run(doc)` directly without preceding `Compose.run` pass with wrong `body_capacity`.

### Pitfall 2: Substituting run widths

**What goes wrong:** `replace_page_numbers/2` is extended to update not just `run.text` but also `run.width` (to match the new digit string width). This triggers geometry changes post-layout, breaking determinism and potentially causing overflow or clipping.

**Why it happens:** Width updating feels "correct" — the substituted text is longer/shorter than the token. But D-10 explicitly forbids this: the geometry is frozen at measure time. Token widths are pre-measured using the same font metrics regardless of the final digit string.

**How to avoid:** Only touch `run.text`. Never touch `run.width`, `block.height`, `block.width`, `measured.width`, or `measured.height` inside `replace_page_numbers/2` or any helper it calls.

**Warning signs:** D-11(d) regression test fails — geometry differs before vs. after substitution.

### Pitfall 3: `total = length(pages)` computed inside the map

**What goes wrong:** `total` is computed as `length(pages)` inside the `Enum.map` lambda instead of before it. On a list this is O(N) per page, making pagination O(N²), and may produce wrong values if the list is being consumed lazily.

**Why it happens:** The `total` calculation looks like a local variable.

**How to avoid:** Bind `total = length(pages)` once before the `Enum.with_index(1)` map and close over it.

### Pitfall 4: Suppression reclaims height

**What goes wrong:** When suppression is applied, the region blocks list is empty, so the body_capacity for that page is larger. Body blocks overflow onto the "extra" space, and page 2's first body block overwrites the footer region on page 1 visually.

**Why it happens:** The temptation to give suppressed pages "more room."

**How to avoid:** D-08 is non-negotiable. Suppression is purely visual (empty block list passed to `anchor_region_blocks`). The reserved `body_capacity` scalar is computed once in `Measure.run` and never varies per page.

### Pitfall 5: `no_body_capacity` error when footer height > body_region.height

**What goes wrong:** After the D-04 fix, if a recipe sets footer height larger than the declared body region height, `body_capacity` goes negative, and `measure.ex:403-404` returns `{:error, :no_body_capacity}`. This is correct behavior, but recipes must be designed with correct geometry.

**How to avoid:** Document the invariant. The `Rendro.Error` from `:no_body_capacity` already has a `next_step` hint in error.ex:230 — verify it mentions geometry fix options.

---

## Code Examples

### Extending `replace_page_numbers/2` for `{{total_pages}}`

```elixir
# Source: VERIFIED against paginate.ex:414-455 — extend this function
# Pattern: add total parameter, chain a second String.replace

defp replace_page_numbers(blocks, page_num, total) do
  Enum.map(blocks, fn block ->
    case block.content do
      %Rendro.Text{content: text} = t ->
        new_text =
          text
          |> String.replace("{{page_number}}", Integer.to_string(page_num))
          |> String.replace("{{total_pages}}", Integer.to_string(total))
        %{block | content: %{t | content: new_text}}

      %Rendro.Pipeline.MeasuredText{source: %Rendro.Text{content: text} = source} = measured ->
        new_text =
          text
          |> String.replace("{{page_number}}", Integer.to_string(page_num))
          |> String.replace("{{total_pages}}", Integer.to_string(total))

        new_lines =
          Enum.map(measured.lines, fn line ->
            Enum.map(line, fn run ->
              new_run_text =
                run.text
                |> String.replace("{{page_number}}", Integer.to_string(page_num))
                |> String.replace("{{total_pages}}", Integer.to_string(total))
              %{run | text: new_run_text}
              # NOTE: run.width intentionally NOT updated (D-10)
            end)
          end)

        %{block | content: %{measured | source: %{source | content: new_text}, lines: new_lines}}

      _ ->
        block
    end
  end)
end
```

### Wiring `total` through `paginate_flow/1`

```elixir
# Source: VERIFIED against paginate.ex:33-41
# Pattern: bind total before map, pass to apply_page_template

pages =
  pages
  |> Enum.reverse()

total = length(pages)   # bind once

pages =
  pages
  |> Enum.with_index(1)
  |> Enum.map(fn {page, idx} ->
    page
    |> stack_body_blocks(layout.body_region)
    |> validate_body_region_fit!(layout.body_region, idx)
    |> apply_page_template(idx, layout, total)   # thread total
  end)
```

### D-11 Determinism Test Skeleton

```elixir
# Source: VERIFIED pattern from test/rendro/deterministic_test.exs
# Pattern: extend DeterministicTest with a new describe block for PAGE properties

describe "running-region determinism (D-11)" do
  test "(a) two deterministic renders with {{total_pages}} footer are byte-identical" do
    doc = running_footer_doc("Page {{page_number}} of {{total_pages}}")
    {:ok, pdf1} = Rendro.render(doc, deterministic: true)
    {:ok, pdf2} = Rendro.render(doc, deterministic: true)
    assert pdf1 == pdf2
  end

  test "(b) body_capacity is identical for 9-page vs 100+-page document" do
    # Use a template with non-zero footer height; verify capacity is geometry-only
    {cap9, _} = measure_body_capacity(make_doc(lines: 9 * 48, footer_height: 30))
    {cap100, _} = measure_body_capacity(make_doc(lines: 100 * 48, footer_height: 30))
    assert cap9 == cap100
  end

  test "(c) page count and body-block assignment are identical with {{total_pages}} vs static placeholder" do
    doc_with_token = running_footer_doc("Page {{page_number}} of {{total_pages}}")
    doc_with_static = running_footer_doc("Page {{page_number}} of 999")
    {:ok, paginated_token} = paginate_flow(doc_with_token)
    {:ok, paginated_static} = paginate_flow(doc_with_static)
    assert length(paginated_token.pages) == length(paginated_static.pages)
    # block assignments per page are identical
    body_assignment = fn doc ->
      Enum.map(doc.pages, fn page ->
        Enum.count(page.blocks, &body_block?/1)
      end)
    end
    assert body_assignment.(paginated_token) == body_assignment.(paginated_static)
  end

  test "(d) replace_page_numbers does not change MeasuredText geometry" do
    # Build, Compose, Measure, Paginate, then inspect that block heights
    # and line widths match before and after substitution
    # ... see existing MeasuredText pattern in deterministic_test.exs
  end
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `{{page_number}}` token only | Extend to `{{total_pages}}` + fn primitive | Phase 73 | Closes the single-pass total-pages gap; no architecture change |
| `body_capacity = body_region.height` (ignores header/footer) | `body_capacity = body_h - header_h - footer_h` | Phase 73 | Closes PAGE-03 overlap bug; zero-height default is a no-op |
| No running-region API on Section | `suppress_on:` selector + fn content variant | Phase 73 | Enables recipes 74–76 to suppress headers on cover pages |

**Deprecated/outdated:**
- The two-clause `body_capacity/1` at measure.ex:442–443 is replaced by a three-key destructure.
- The `flow_layout/1` fallback at paginate.ex:494 needs a companion fix that reads from `template.regions`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `Rendro.Block` struct can carry a function as its `content` field without struct enforcement issues | Code Examples / Pattern 1 | Block struct may have type enforcement; planner must verify if `@enforce_keys` or typespec guards reject non-struct content. Resolution: introduce a dedicated `Rendro.RunningRegionContent` struct or use `options` map to carry the fn. | [ASSUMED] |
| A2 | `gsd-sdk query commit` is available and will auto-commit RESEARCH.md | Output section | Not verified; commit step is best-effort per execution_flow |

---

## Open Questions

1. **Where does the per-page function live in the block struct?**
   - What we know: `Rendro.Block` content is currently `Rendro.Text | Rendro.Table | Rendro.Image | Rendro.FormField | Rendro.Link | Rendro.Pipeline.MeasuredText`. The struct has no `@enforce_keys` guard on `content`.
   - What's unclear: Whether storing a raw `fn` as `content` is idiomatic or whether a dedicated wrapper struct (`%Rendro.RunningContent{fun: fn}`) is needed for pattern-match clarity in `replace_page_numbers/2`.
   - Recommendation: The planner should decide between (a) bare `fn` in `content` (simplest, one pattern-match clause) vs (b) a `%Rendro.RunningContent{}` wrapper (more explicit, matches project's pattern of named structs for each content type). Claude's Discretion permits either. Option (b) is more consistent with the existing codebase style.

2. **Suppression selector field placement**
   - What we know: `Rendro.Section` has an `options: %{}` catch-all. `suppress_on:` could go there or as a top-level field.
   - What's unclear: Whether adding top-level `suppress_on:` to `Rendro.Section` is a public API commitment that constrains recipes 74–76.
   - Recommendation: Make it a top-level `Rendro.Section` field for discoverability; it IS public API since recipes 74–76 use `Rendro.section/1`.

---

## Environment Availability

Step 2.6: SKIPPED — this phase is purely code changes within the existing Elixir library. No new runtimes, CLIs, or external services are introduced. The existing `mix test` pipeline is sufficient.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + StreamData (ExUnitProperties for property tests) |
| Config file | `mix.exs` — `preferred_envs: [ci: :test]`; no separate test config |
| Quick run command | `mix test test/rendro/pipeline/paginate_test.exs test/rendro/pipeline/measure_test.exs test/rendro/flow_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PAGE-01 | `{{total_pages}}` renders real total on every page in single pass | integration | `mix test test/rendro/flow_test.exs` | ✅ (extend existing `"headers, footers and page numbers"` test) |
| PAGE-01 | `replace_page_numbers/2` with total param substitutes `{{total_pages}}` in both Text and MeasuredText variants | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ (new test in existing file) |
| PAGE-02 | `fn {pn, tp} -> content end` block evaluates per-page with correct args | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ❌ Wave 0 |
| PAGE-02 | `Rendro.page_number/1` produces correct token block | unit | `mix test test/rendro_builders_test.exs` | ❌ Wave 0 |
| PAGE-02 | `suppress_on: :first` suppresses footer on page 1 but not page 2 | integration | `mix test test/rendro/flow_test.exs` | ❌ Wave 0 |
| PAGE-02 | Suppressed page has same body_capacity as non-suppressed page | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ❌ Wave 0 |
| PAGE-03 | `body_capacity` = `body_h - header_h - footer_h` for non-zero footer | unit | `mix test test/rendro/pipeline/measure_test.exs` | ✅ (extend existing body_capacity test at line 70) |
| PAGE-03 | `flow_layout/1` fallback subtracts header/footer from body_capacity | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ❌ Wave 0 |
| PAGE-03 | Body blocks do not overlap footer region visually (y + height <= footer.y) | integration | `mix test test/rendro/flow_test.exs` | ❌ Wave 0 |
| PAGE-04 | D-11(a): byte-identical two renders with running footer | unit | `mix test test/rendro/deterministic_test.exs` | ❌ Wave 0 (new describe block) |
| PAGE-04 | D-11(b): body_capacity identical for 9-page vs 100+-page | unit | `mix test test/rendro/deterministic_test.exs` | ❌ Wave 0 |
| PAGE-04 | D-11(c): page count identical with `{{total_pages}}` vs static placeholder | unit | `mix test test/rendro/deterministic_test.exs` | ❌ Wave 0 |
| PAGE-04 | D-11(d): `replace_page_numbers` leaves MeasuredText geometry unchanged | unit | `mix test test/rendro/deterministic_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/pipeline/measure_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs test/rendro/deterministic_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] New `describe "running-region determinism (D-11)"` block in `test/rendro/deterministic_test.exs`
- [ ] New `page_number/1` helper tests in `test/rendro_builders_test.exs`
- [ ] New per-page function evaluation tests in `test/rendro/pipeline/paginate_test.exs`
- [ ] New suppression selector tests in `test/rendro/flow_test.exs` and `test/rendro/pipeline/paginate_test.exs`
- [ ] New `flow_layout/1` fallback body_capacity test in `test/rendro/pipeline/paginate_test.exs`
- [ ] New body-does-not-overlap-footer integration test in `test/rendro/flow_test.exs`

*(Existing infrastructure covers all other requirements — no new framework install needed.)*

---

## Security Domain

No new security attack surface introduced. This phase:
- Does not add any input processing of external data (token substitution operates on author-controlled strings)
- Does not add network I/O, filesystem access, or authentication paths
- Does not introduce new serialization or deserialization

ASVS categories not applicable to this phase.

---

## Sources

### Primary (HIGH confidence)
- `lib/rendro/pipeline/paginate.ex` — verified `replace_page_numbers/2` (lines 414–455), `apply_page_template/3` (397–412), `flow_layout/1` (478–501), `Enum.with_index(1)` map (33–41)
- `lib/rendro/pipeline/measure.ex` — verified `body_capacity/1` (442–443), `measure_layout/2` (396–418)
- `lib/rendro/pipeline/compose.ex` — verified layout map shape (90–100), `header_region`/`footer_region` keys (94–95)
- `lib/rendro/region.ex` — verified struct fields and defaults (1–27)
- `lib/rendro/page_template.ex` — verified default region heights (18–46)
- `lib/rendro.ex` — verified `region/1`/`section/1` location (199–207), no `page_number/1` exists yet
- `lib/rendro/section.ex` — verified struct fields (1–20)
- `lib/rendro/pipeline/measured_text.ex` — verified `lines`, `source`, `height`, `width` fields
- `test/rendro/deterministic_test.exs` — verified property test patterns and existing determinism assertions
- `test/rendro/flow_test.exs` — verified existing `{{page_number}}` test at lines 102–122, explicit template test at 124–237
- `test/rendro/pipeline/measure_test.exs` — verified existing `body_capacity == 540` test at lines 70–124
- `.planning/phases/73-page-numbering-running-region-primitive/73-CONTEXT.md` — all D-01..D-11 decisions

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new deps, all code verified from live source
- Architecture: HIGH — all seams verified; actual line numbers confirmed
- Pitfalls: HIGH — derived from reading both fix sites in full context
- Content API shape: MEDIUM — Claude's Discretion areas; function-block struct shape is an open question answered by the planner

**Research date:** 2026-05-29
**Valid until:** Stable (no external dependencies; only stales if source files are modified)

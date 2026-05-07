# Phase 41: Widow/Orphan Layout Controls - Research

**Researched:** 2024-05-30
**Domain:** Elixir Document Layout & Pagination Pipeline
**Confidence:** HIGH

## Summary

This phase implements predictive line splitting for multi-line text blocks across page boundaries to prevent isolated single lines (widows and orphans). We rely on the typography properties `widows` and `orphans` on the `Rendro.Text` struct. When the Measure phase processes text into `Rendro.Pipeline.MeasuredText`, it passes these values down. The Pagination phase (`Rendro.Pipeline.Paginate`) uses these values during block overflow to determine how many lines can physically fit on the current page. By mathematically reducing the fitting lines to satisfy widows, and validating the remainder against the orphans constraint, the algorithm ensures strict typographic rules.

**Primary recommendation:** Implement text constraints in `paginate.ex` via strict mathematical calculation using pre-computed `MeasuredText` line arrays and heights. Do not introduce these properties on a generic `Rendro.Block`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Typographic Schema | Core Schema | — | `widows` and `orphans` are content properties of `Rendro.Text`, avoiding application to incompatible types like images. |
| Metrics Transport | Pipeline Measure | — | `Measure` translates the generic text schema into physical runs and explicitly copies typographic rules into `MeasuredText` for layout consumption. |
| Layout Enforcement | Pipeline Paginate | — | Only the `Paginate` phase knows the available `max_h`, making it the exclusive authority for triggering overflow checks and splits. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir (core) | >= 1.14 | Logic implementation | Standard language of the project; sufficient for pure functional mathematical layout logic. |

## Architecture Patterns

### System Architecture Diagram

`Rendro.Text (widows/orphans schema)` 
  ➔ `Rendro.Pipeline.Measure` (Converts to `MeasuredText`, maps constraints) 
  ➔ `Rendro.Pipeline.Paginate` (Applies split algorithm on available capacity) 
  ➔ Splits into two valid Blocks OR Overflows entire Block to next page.

### Pattern 1: Explicit Function Matching for Fragmentation
**What:** Implementing structural split functionality using explicit matching (e.g., `handle_text_split`) in `paginate.ex` rather than a protocol for now.
**When to use:** To isolate complex splitting math (lines fitting, widows, orphans) on specific schema types (`MeasuredText`) and align with existing logic like `handle_table_split/10`. This preps for a future S02 protocol migration.
**Example:**
```elixir
defp handle_text_split(block, %MeasuredText{} = text, current_page, rest, template, max_h, current_h, block_h, overflow_details, diagnostics) do
  # Math here
end
```

### Pattern 2: Schema Locality for Typographic Constraints
**What:** Fields like `widows` and `orphans` are defined on `Rendro.Text`, not `Rendro.Block`.
**When to use:** To enforce that constraints that only apply to one domain (text) cannot be misused by others (images/tables).

### Anti-Patterns to Avoid
- **Heuristic Layout Iteration:** Trying to layout lines one by one and checking heights iteratively. Instead, calculate total lines and use simple division on pre-computed total heights.
- **Modifying Line Heights:** Stretching or squishing line-heights to force a fit is an anti-pattern. If constraints fail, the *entire block* moves to the next page.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Line Metrics | Custom line wrapping iteration | `MeasuredText` output | The Measure phase already accurately chunks text into physical lines. Use `text.lines` and `line_height_pt`. |

## Elixir Logic Outlines

### Splitting Algorithm Data Structures Modified
1.  **`lib/rendro/text.ex`:** Must contain `widows: 2`, `orphans: 2` in `defstruct`.
2.  **`lib/rendro/pipeline/measured_text.ex`:** Must define `:widows` and `:orphans` in `@enforce_keys` and `defstruct`.
3.  **`lib/rendro/pipeline/measure.ex`:** Must map `text.widows` and `text.orphans` from the source `Rendro.Text` into the newly created `%MeasuredText{}` struct.

### Pagination Split Logic (`handle_text_split` in `paginate.ex`)
The algorithm inside `paginate.ex` should operate exactly as follows:
1.  **Calculate Initial Fit:**
    ```elixir
    available_h = max_h - current_h
    total_lines = length(text.lines)
    line_height_pt = text.height / total_lines
    lines_fitting = floor(available_h / line_height_pt)
    ```
2.  **Adjust for Widows (Push Lines Down):**
    ```elixir
    # Check if lines left for next page are less than widows required
    lines_fitting =
      if total_lines - lines_fitting < text.widows do
        max(0, total_lines - text.widows)
      else
        lines_fitting
      end
    ```
3.  **Validate Against Orphans (Minimum Lines Up Top):**
    ```elixir
    # Re-verify if adjusted fit leaves enough lines on current page
    can_split? = lines_fitting >= max(1, text.orphans)
    ```
4.  **Execute or Overflow:**
    If `can_split?` is true and `lines_fitting < total_lines`: perform `Enum.split(text.lines, lines_fitting)` to emit two distinct blocks. Otherwise, trigger `check_overflow!` to push the block entirely to the next page.

*Note: This identical algorithm applies to `split_block/2` inside `paginate.ex` as well, where crossing rows are sliced horizontally.*

## Testing Scenarios

Required testing scenarios in `test/rendro/pipeline/paginate_test.exs`:

1.  **Valid Split (No Conflict):** A block with 5 lines fits exactly 3 lines. `widows: 2, orphans: 2`. 3 lines fit (>= 2 orphans). 2 lines pushed (>= 2 widows). Block is split at line 3.
2.  **Widow Enforcement (Adjustment):** A block with 4 lines fits 3 lines. `widows: 2, orphans: 2`. 3 lines fit leaves 1 line pushed (violates widows). Algorithm reduces fit to 2 lines. 2 lines pushed (satisfies widows). 2 lines fit (satisfies orphans). Block splits at line 2.
3.  **Orphan Rejection (Entire Block Moved):** A block with 3 lines fits 2 lines. `widows: 2, orphans: 2`. 2 lines fit leaves 1 line pushed (violates widows). Algorithm reduces fit to 1 line to push 2 lines. But 1 line fit violates orphans (1 < 2). Split is rejected. Block moves to next page.
4.  **Short Overflow:** A block with 5 lines fits 1 line. `widows: 2, orphans: 2`. 1 line fit violates orphans (1 < 2). Split is rejected.

## Common Pitfalls

### Pitfall 1: Incorrect Orphan Validation
**What goes wrong:** Developers check `lines_fitting >= orphans` *before* adjusting for widows.
**Why it happens:** Order of operations mistake.
**How to avoid:** Always perform the widow adjustment subtraction first, then run the orphan validation against the mutated `lines_fitting` variable.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs`, `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/pipeline/paginate_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WO-01 | Widows adjustment shifts split | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ Wave 0 |
| WO-02 | Orphans violation rejects split | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ Wave 0 |
| WO-03 | Measure passes text fields | unit | `mix test test/rendro/pipeline/measure_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/pipeline/paginate_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
None — existing test infrastructure covers all phase requirements.
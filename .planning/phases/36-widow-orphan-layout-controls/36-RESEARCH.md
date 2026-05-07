# Phase 36: S01: Widow/Orphan Layout Controls - Research

**Researched:** 2024-05-18
**Domain:** Elixir / Backend PDF Generation Pipeline
**Confidence:** HIGH

## Summary

This phase implements predictive line splitting for text blocks across page boundaries in Rendro. We will add `widows` and `orphans` configuration to `Rendro.Text`, propagate these constraints down to `Rendro.Pipeline.MeasuredText`, and enforce them dynamically during pagination in `Rendro.Pipeline.Paginate`.

**Primary recommendation:** Implement text splitting via explicit function matching for `%Rendro.Pipeline.MeasuredText{}` in `paginate_block/5` to cleanly isolate the logic for S01 before introducing a generic protocol in S02.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- `widows` and `orphans` are typographic properties of the content, not the layout container.
- We add `widows: 2` and `orphans: 2` defaults directly to the `Rendro.Text` struct.
- This prevents applying text-specific logic to incompatible block types (like images) and aligns with the Ecto-style pattern of validating/constraining the specific payload field rather than a generic wrapper.
- S01 implements text fragmentation via explicit function matching in `paginate.ex` (analogous to the existing `handle_table_split/10`). This isolates the text-splitting math and ensures it's ready to be slotted behind a protocol boundary in the next slice without user-facing schema changes.

### the agent's Discretion
- (No discretion explicitly called out in CONTEXT.md, follow exact constraints)

### Deferred Ideas (OUT OF SCOPE)
- S02 will introduce `Rendro.Fragmentable` for recursive splitting. Do NOT implement a protocol in S01.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REQ-01 | Schema Updates | `Rendro.Text` requires `:widows` and `:orphans` added to `defstruct` and `@type`. |
| REQ-02 | Pipeline State | `Rendro.Pipeline.MeasuredText` requires the fields, and `Measure.measure_block` must map them from source `Text`. |
| REQ-03 | Predictive Split Math | `Rendro.Pipeline.Paginate` needs a new `handle_text_split/10` handling text flow across pages respecting limits. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Schema Definition | API / Backend | — | `Rendro.Text` manages the public interface for user configuration of typography. |
| Measurement | API / Backend | — | `Rendro.Pipeline.Measure` bridges user schema to layout objects, copying necessary state (`widows`, `orphans`). |
| Pagination Engine | API / Backend | — | `Rendro.Pipeline.Paginate` performs math to determine block overflows and enforces widow/orphan rules, slicing `MeasuredText` runs list. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.15+ | Core Logic | Existing codebase foundation |
| ExUnit | — | Testing | Core testing framework |

## Architecture Patterns

### System Architecture Diagram
Data flows linearly through the rendering pipeline:

`Rendro.Text` (Authoring, contains widows/orphans defaults)
   ↓ (Rendro.Pipeline.Measure)
`Rendro.Pipeline.MeasuredText` (Internal, inherits constraints, computes exact line metrics)
   ↓ (Rendro.Pipeline.Paginate detects overflow)
`handle_text_split/10` (Calculates line capacity minus widow/orphan adjustments)
   ↓ (Valid Split mathematically verified)
Splits into two distinct `Rendro.Block{content: %MeasuredText{}}` on consecutive pages.

### Pattern 1: Explicit Function Matching for S01
**What:** Handle `MeasuredText` splits via an explicit pattern match in `paginate_block/5` before delegating to a specialized text split function.
**When to use:** In S01 before `Rendro.Fragmentable` is introduced.
**Example:**
```elixir
case block.content do
  %Rendro.Table{} = table ->
    # existing table logic
  %Rendro.Pipeline.MeasuredText{} = text ->
    if current_h + block_h > max_h do
      handle_text_split(block, text, current_page, rest, template, max_h, current_h, block_h, overflow_details, diagnostics)
    else
      # block fits completely
    end
  _ ->
    # fallback generic overflow
end
```

### Anti-Patterns to Avoid
- **Generic Block Splitting:** Do not try to split the `Rendro.Block` wrapper directly in a generic way. Split the inner `content` (`MeasuredText`) and wrap the two halves in new `Rendro.Block` structs.
- **Protocol Definition:** Do not introduce `Rendro.Fragmentable` yet. S01 strictly uses function overloading in `Paginate`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fragmentation Abstraction | Polymorphic `defprotocol` | Explicit `%MeasuredText{}` matching | S01 scope limitation strictly forbids protocol introduction. |

## Common Pitfalls

### Pitfall 1: Line Height Calculation
**What goes wrong:** Incorrectly determining how many lines fit on a page.
**Why it happens:** `MeasuredText` stores total `height` and a `line_height` ratio (e.g. `1.2`), but not the raw point value of a single line's height.
**How to avoid:** Calculate line height in points as `line_height_pt = text_block.height / length(text_block.lines)`. Then `lines_fitting = floor(available_h / line_height_pt)`.

### Pitfall 2: Invalid Splits (Infinite Loops)
**What goes wrong:** A block that cannot be split legally (e.g., a 3-line paragraph needing 2 orphans and 2 widows).
**Why it happens:** The split math returns impossible line counts.
**How to avoid:** The mathematical algorithm must be strict:
1. `lines_fitting < orphans` -> invalid split. Push entire block to next page.
2. `remaining_lines < widows` -> subtract from `lines_fitting` to satisfy widows.
3. If new `lines_fitting < orphans` -> invalid split. Push entire block to next page.

## Code Examples

### The Math Algorithm
```elixir
# Proposed logic for handle_text_split
total_lines = length(text.lines)
line_height_pt = text.height / total_lines
lines_fitting = floor(available_h / line_height_pt)

# Widow/Orphan validation
{this_page_count, rest_count} =
  cond do
    lines_fitting < text.orphans ->
      # Cannot even satisfy orphans on current page
      {0, total_lines}
    
    total_lines - lines_fitting < text.widows ->
      # Violates widows, try shifting lines to next page
      adjusted_fitting = total_lines - text.widows
      if adjusted_fitting < text.orphans do
        # Shifting violates orphans, invalid split
        {0, total_lines}
      else
        {adjusted_fitting, total_lines - adjusted_fitting}
      end
      
    true ->
      {lines_fitting, total_lines - lines_fitting}
  end
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Rendro.Pipeline.MeasuredText` lines are uniformly spaced for simple height division. | Common Pitfalls | Math fails if lines have variable heights in the same paragraph. (Low risk based on current font shaping). |

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/rendro/pipeline/paginate_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | Text Schema | unit | `mix test test/rendro/text_test.exs` | ✅ Wave 0 |
| REQ-02 | MeasuredText Mapping | unit | `mix test test/rendro/pipeline/measure_test.exs` | ✅ Wave 0 |
| REQ-03 | Paginate Splits | unit | `mix test test/rendro/pipeline/paginate_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/rendro/pipeline/paginate_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements. The planner just needs to add test cases specifically for widow/orphan edge conditions.

## Sources

### Primary (HIGH confidence)
- `36-CONTEXT.md` - Phase constraints and decisions
- `lib/rendro/text.ex` - Schema target
- `lib/rendro/pipeline/measured_text.ex` - Pipeline state target
- `lib/rendro/pipeline/paginate.ex` - Algorithm target

## Metadata

**Confidence breakdown:**
- Architecture: HIGH - Fully detailed in CONTEXT.md
- Pitfalls: HIGH - Common typographic layout calculations are mathematically deterministic.

**Research date:** 2024-05-18
**Valid until:** Indefinite (internal architecture limits)

---
phase: "41"
plan: "01"
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/rendro/text.ex
  - lib/rendro/pipeline/measured_text.ex
  - lib/rendro/pipeline/measure.ex
  - lib/rendro/pipeline/paginate.ex
  - test/rendro/pipeline/paginate_test.exs
  - test/rendro/pipeline/measure_test.exs
autonomous: true
requirements:
  - WO-01
  - WO-02
  - WO-03
must_haves:
  truths:
    - "Schema defaults text to 2 widows and 2 orphans"
    - "Typographic constraints pass through Measure phase"
    - "Pagination mathematically shifts lines to satisfy widows"
    - "Pagination rejects split entirely if orphans constraint fails"
  artifacts:
    - path: "lib/rendro/text.ex"
      provides: "Schema properties"
      contains: "widows: 2"
    - path: "lib/rendro/pipeline/measured_text.ex"
      provides: "Measured constraints transport"
    - path: "lib/rendro/pipeline/paginate.ex"
      provides: "Layout constraints enforcement"
      contains: "handle_text_split"
  key_links:
    - from: "lib/rendro/pipeline/measure.ex"
      to: "lib/rendro/pipeline/measured_text.ex"
      via: "Struct mapping"
      pattern: "widows: text.widows"
    - from: "lib/rendro/pipeline/paginate.ex"
      to: "lib/rendro/pipeline/measured_text.ex"
      via: "Pattern matching on widows/orphans fields during overflow"
      pattern: "text.widows"
---

<objective>
Implement predictive line splitting for text blocks across page boundaries to ensure clean breaks that do not leave solitary lines (widows/orphans), fully respecting typographic constraints.

Purpose: Allows text paragraphs to flow across pages intelligently without manual tweaking, enforcing correct typographical reading rules.
Output: Modifications to typographic schema, pipeline measurement structures, and mathematical pagination constraints.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/41-widow-orphan-layout-controls/GOAL.md
@.planning/phases/41-widow-orphan-layout-controls/RESEARCH.md
@.planning/phases/41-widow-orphan-layout-controls/41-PATTERNS.md

<interfaces>
From lib/rendro/text.ex:
```elixir
  @enforce_keys [:content]
  defstruct [
    :content,
    font: "Helvetica",
    size: 12,
    color: {0, 0, 0},
    line_height: 1.2,
    widows: 2,
    orphans: 2
  ]
```

From lib/rendro/pipeline/measured_text.ex:
```elixir
  @enforce_keys [
    :source,
    :lines,
    :line_height,
    :width,
    :height,
    :resolved_font,
    :widows,
    :orphans
  ]
  defstruct [:source, :lines, :line_height, :width, :height, :resolved_font, :widows, :orphans]
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Typographic Schema & Measure Phase Transport</name>
  <files>lib/rendro/text.ex, lib/rendro/pipeline/measured_text.ex, lib/rendro/pipeline/measure.ex, test/rendro/pipeline/measure_test.exs</files>
  <behavior>
    - Test 1: `Rendro.Text` initializes with `widows: 2` and `orphans: 2`
    - Test 2: `Rendro.Pipeline.Measure` maps these exact fields to `%MeasuredText{}` struct when chunking text
  </behavior>
  <action>
    Add `widows: 2` and `orphans: 2` to `Rendro.Text` defaults and types. Add `:widows` and `:orphans` to `@enforce_keys` and `defstruct` in `Rendro.Pipeline.MeasuredText`. In `Rendro.Pipeline.Measure`, update the `measure_block` function mapping for text to pass `text.widows` and `text.orphans` to `%MeasuredText{}`. This leverages the struct schema constraint patterns identified in 41-PATTERNS.md.
  </action>
  <verify>
    <automated>mix test test/rendro/pipeline/measure_test.exs</automated>
  </verify>
  <done>Models support typographic constraints and successfully map them across the measurement boundary.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Pagination Layout Enforcement</name>
  <files>lib/rendro/pipeline/paginate.ex, test/rendro/pipeline/paginate_test.exs</files>
  <behavior>
    - Test 1: A 5-line paragraph fitting 3 lines splits at line 3.
    - Test 2: A 4-line paragraph fitting 3 lines reduces to 2 lines to satisfy widows: 2.
    - Test 3: A 3-line paragraph fitting 2 lines reduces to 1 for widows, fails orphans constraint (1 < 2), rejects split, and moves entirely to next page.
  </behavior>
  <action>
    Update `handle_text_split` and `split_block` inside `lib/rendro/pipeline/paginate.ex` (analogous to the `handle_table_split/10` block transformation pattern identified in 41-PATTERNS.md). Use mathematical constraint validation:
    1. Calculate `lines_fitting = floor(available_h / line_height_pt)`
    2. Adjust for widows: `if total_lines - lines_fitting < text.widows do max(0, total_lines - text.widows) else lines_fitting end`
    3. Validate orphans: `can_split? = lines_fitting >= max(1, text.orphans)`
    4. Reject the split if `!can_split?` and push block down, otherwise execute `Enum.split`.
  </action>
  <verify>
    <automated>mix test test/rendro/pipeline/paginate_test.exs</automated>
  </verify>
  <done>Text splits accurately respect widow/orphan constraints or overflow the entire block.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Input -> Pipeline | Text layout parameters (widows, orphans) passed in text structs |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-41-01 | Tampering | `paginate.ex` | mitigate | Ensure negative or 0 orphan values gracefully clamp using `max(1, text.orphans)` to avoid division by zero or infinite loop equivalent. |
| T-41-02 | Denial of Service | `paginate.ex` | accept | Extremely large widow requirements on massive blocks may force unresolvable pagination overflows; handled by existing layout error catchers. |
</threat_model>

<verification>
mix test
</verification>

<success_criteria>
- Paragraphs appropriately shift lines to honor 2-widow constraints
- Layouts reject splitting text that yields 1-line orphans
- Full test suite is green
</success_criteria>

<output>
After completion, create `.planning/phases/41-widow-orphan-layout-controls/41-01-SUMMARY.md`
</output>
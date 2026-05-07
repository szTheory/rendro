# Phase 27: Fallback Chains and Honest I18n Diagnostics - Pattern Map

**Mapped:** 2024-05
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/rendro/typography/fallback.ex` | service | transform | `lib/rendro/font_registry.ex` | role-match |
| `lib/rendro/error.ex` | utility | event-driven | `lib/rendro/error.ex` | exact |
| `lib/rendro/pipeline/measure.ex` | service | transform | `lib/rendro/pipeline/measure.ex` | exact |
| `test/rendro/typography/fallback_test.exs` | test | validation | `test/rendro/pdf/font_test.exs` | role-match |

## Pattern Assignments

### `lib/rendro/error.ex` (utility, event-driven)

**Analog:** `lib/rendro/error.ex`

**Structured Error Pattern** (lines 14-29):
```elixir
  def from_stage(stage, reason, context \\ %{}) when is_atom(stage) do
    %__MODULE__{
      what: what(stage, reason),
      where: "Rendro.Pipeline.#{stage_module_suffix(stage)}",
      why: why(reason),
      next: next_step(stage, reason),
      stage: stage,
      reason: reason,
      render_id: Map.get(context, :render_id),
      details:
        Map.merge(
          %{
            document_type: Map.get(context, :document_type),
            deterministic: Map.get(context, :deterministic)
          },
          Map.get(context, :details, %{})
        )
    }
  end
```

**Actionable Diagnostics** (lines 49-65):
```elixir
  defp next_step(:measure, :no_body_capacity) do
    "Increase the body region height or reduce reserved header/footer regions so flow content has usable space."
  end
```
*(Apply this to add `:unsupported_glyph` or `:missing_fallback` to provide honest feedback instead of rendering squares/spaces.)*

---

### `lib/rendro/typography/fallback.ex` (service, transform)

**Analog:** `lib/rendro/font_registry.ex`

**Explicit Exception Pattern** (lines 280-305):
```elixir
defmodule Rendro.FontRegistry.EmbeddedFontFamilyError do
  defexception [:message, :family_name, :missing_variants, :extra_variants, :provided_kinds, :reason]

  @impl true
  def exception(opts) do
    # ...
    message =
      "embedded font family #{inspect(family_name)} is invalid: " <>
        "missing=#{inspect(missing_variants)} extra=#{inspect(extra_variants)} " <>
        "provided_kinds=#{inspect(provided_kinds)} reason=#{inspect(reason)}"

    %__MODULE__{
      family_name: family_name,
      missing_variants: missing_variants,
      extra_variants: extra_variants,
      provided_kinds: provided_kinds,
      reason: reason,
      message: message
    }
  end
end
```

---

### `lib/rendro/pipeline/measure.ex` (service, transform)

**Analog:** `lib/rendro/pipeline/measure.ex`

**Core Pattern for Text Measurement** (lines 191-213):
```elixir
  defp split_graphemes(text, max_width, font, font_size) do
    {lines, current_line} =
      Enum.reduce(String.graphemes(text), {[], ""}, fn grapheme, {lines, current_line} ->
        candidate = current_line <> grapheme

        cond do
          current_line == "" and Font.text_width(font, candidate, font_size) <= max_width ->
            {lines, candidate}
          # ...
        end
      end)
    
    # ...
  end
```
*(Apply this by hooking fallback chain resolution directly into text measurement, preventing blind `Font.text_width` default resolution for unmapped characters.)*

## Shared Patterns

### Error Handling
**Source:** `lib/rendro/error.ex`
**Apply to:** `lib/rendro/pipeline/measure.ex` and `lib/rendro/pipeline/validate.ex`
Instead of silently falling back or using default font widths for unknown glyphs, the pipeline must trap and halt, propagating an explicit error tuple (e.g. `{:error, {:unsupported_glyph, char}}`) up to `Rendro.Error.from_stage/3`.

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/rendro/typography/shaping.ex` | service | transform | No existing module handles complex text layout or true shaping; current state assumes simple 1:1 glyph mapping via string chunking. |

## Metadata

**Analog search scope:** `lib/rendro/**/*.ex`
**Files scanned:** 3 explicitly read
**Pattern extraction date:** 2024-05

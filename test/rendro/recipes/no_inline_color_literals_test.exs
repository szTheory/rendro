defmodule Rendro.Recipes.NoInlineColorLiteralsTest do
  @moduledoc """
  Phase 120 PLUMB-02 completeness proof — a pure static source-scan (no
  rendering).

  Every recipe section builder MUST source its colors from that recipe's
  `palette/1` seam (which is the single point `Rendro.Theme` slots into),
  never inline a literal `{r, g, b}` color tuple. This test reads each
  `lib/rendro/recipes/*.ex` file, isolates the section-builder region
  (everything EXCEPT the `defp palette(opts)` body, where the literal role
  defaults legitimately live), and fails — with file + line — if any inline
  color literal is assigned to a `color:` / `fill:` / `stroke:` context.

  It also enforces the Phase-120 colors-only boundary (D-04): no recipe file
  performs a `.typography` read. Phase 120 reads `theme.colors` ONLY; type-scale
  application is Phase 122 scope.

  Non-color numerics (a stroke `width: 0.75`, geometry/coordinate constants)
  and comment lines are excluded by construction so they are never
  false-positives.
  """
  use ExUnit.Case, async: true

  @recipes_dir Path.join([File.cwd!(), "lib", "rendro", "recipes"])

  # Matches an inline literal color triple assigned to a color context key.
  # Keyed on `color:`/`fill:`/`stroke:` so a role-default map (`ink: {0,0,0}`),
  # a variable read (`color: colors.rule`), and non-color numerics
  # (`width: 0.75`) are all excluded automatically.
  @color_literal ~r/(?:color|fill|stroke):\s*\{\s*\d{1,3}\s*,\s*\d{1,3}\s*,\s*\d{1,3}\s*\}/

  defp recipe_files do
    @recipes_dir
    |> Path.join("*.ex")
    |> Path.wildcard()
    |> Enum.sort()
  end

  # Line indices (0-based) spanned by the `defp palette(opts) do ... end` body,
  # so its literal role-default map is excluded from the section-builder scan.
  defp palette_body_indices(lines) do
    case Enum.find_index(lines, &(&1 =~ ~r/^\s*defp palette\(/)) do
      nil ->
        MapSet.new()

      start_idx ->
        rest = Enum.drop(lines, start_idx + 1)
        # The palette function is at 2-space indent; its closing `end` is `  end`.
        end_offset = Enum.find_index(rest, &(&1 =~ ~r/^  end\s*$/))
        end_idx = start_idx + 1 + end_offset
        MapSet.new(start_idx..end_idx)
    end
  end

  defp comment_line?(line), do: String.starts_with?(String.trim_leading(line), "#")

  test "no recipe section builder inlines a literal {r,g,b} color tuple (PLUMB-02)" do
    violations =
      Enum.flat_map(recipe_files(), fn path ->
        lines = path |> File.read!() |> String.split("\n")
        palette_idx = palette_body_indices(lines)

        lines
        |> Enum.with_index()
        |> Enum.filter(fn {line, idx} ->
          not MapSet.member?(palette_idx, idx) and
            not comment_line?(line) and
            line =~ @color_literal
        end)
        |> Enum.map(fn {line, idx} ->
          "#{Path.relative_to_cwd(path)}:#{idx + 1}: #{String.trim(line)}"
        end)
      end)

    assert violations == [],
           "Inline color literal(s) found in recipe section builder(s). " <>
             "Route every color through the recipe's palette/1 seam instead:\n" <>
             Enum.join(violations, "\n")
  end

  test "no recipe file performs a .typography read (colors-only boundary, D-04)" do
    violations =
      Enum.flat_map(recipe_files(), fn path ->
        lines = path |> File.read!() |> String.split("\n")

        lines
        |> Enum.with_index()
        |> Enum.filter(fn {line, _idx} ->
          not comment_line?(line) and line =~ ~r/\.typography\b/
        end)
        |> Enum.map(fn {line, idx} ->
          "#{Path.relative_to_cwd(path)}:#{idx + 1}: #{String.trim(line)}"
        end)
      end)

    assert violations == [],
           "Phase 120 reads theme.colors ONLY — a .typography read is Phase 122 scope (D-04):\n" <>
             Enum.join(violations, "\n")
  end
end

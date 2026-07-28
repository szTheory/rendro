defmodule Rendro.Recipes.NoInlineSizeLiteralsTest do
  @moduledoc """
  Phase 122 TYPE-01 completeness proof — a pure static source-scan (no
  rendering), the size-axis twin of `no_inline_color_literals_test.exs`.

  Every recipe section builder MUST source its text sizes from that recipe's
  `typography/1` seam (which is the single point `Rendro.Theme` slots into),
  reading them as `size: type.scale.<role>` — never inlining a numeric
  `size:` literal on a seamed call site. This test reads each
  `lib/rendro/recipes/*.ex` file, isolates the section-builder region
  (everything EXCEPT the `defp typography(opts)` body, where the literal
  role-default scale legitimately lives), and fails — with file + line — if
  any inline NUMERIC `size:` literal survives in a section builder.

  Deliberate exclusions (so they are never false-positives):

    * The `defp typography(opts)` body — its `scale: %{display: 20, ...}`
      literal defaults are the legitimate home for the numbers.
    * `@*_size` module-attr DEFINITION lines — Ticket's `@caption_size 7` /
      `@present_code_size 6` are the two exempt mono micro-sizes; they are
      read at call sites as `size: @attr` (a VARIABLE read, not an inline
      literal), so the regex — keyed on a numeric literal after `size:` —
      never matches them anyway, but the definition lines are excluded for
      robustness.
    * Certificate's `Rendro.text("", size: 1)` layout spacer — a pure
      vertical-centering hack, never a typographic size, allowlisted by an
      explicit spacer guard.

  Variable reads (`size: type.scale.body`, `size: @caption_size`,
  `size: size`) and comment lines are excluded by construction.
  """
  use ExUnit.Case, async: true

  @recipes_dir Path.join([File.cwd!(), "lib", "rendro", "recipes"])

  # Matches an inline NUMERIC `size:` literal (integer or float). Keyed on a
  # digit immediately after `size:` so a variable read (`size: type.scale.body`,
  # `size: @caption_size`, `size: size`) is excluded automatically — only a
  # re-introduced hardcoded number in a section builder trips it.
  @size_literal ~r/\bsize:\s*\d+(?:\.\d+)?\b/

  # The single legitimate remaining inline `size:` literal across all 7
  # recipes: Certificate's empty layout spacer (vertical-centering hack).
  @spacer_line ~r/Rendro\.text\(\s*""\s*,\s*size:\s*1\s*\)/

  # A `@*_size` module-attr DEFINITION line (e.g. `@caption_size 7`). Excluded
  # for robustness — these are the legit literal home for exempt micro-sizes.
  @size_attr_def ~r/^\s*@\w*size\b/

  defp recipe_files do
    @recipes_dir
    |> Path.join("*.ex")
    |> Path.wildcard()
    |> Enum.sort()
  end

  # Line indices (0-based) spanned by the `defp typography(opts) do ... end`
  # body, so its literal role-default scale is excluded from the
  # section-builder scan. Mirrors `palette_body_indices/1` in the color twin.
  defp typography_body_indices(lines) do
    case Enum.find_index(lines, &(&1 =~ ~r/^\s*defp typography\(/)) do
      nil ->
        MapSet.new()

      start_idx ->
        rest = Enum.drop(lines, start_idx + 1)
        # The typography function is at 2-space indent; its closing `end` is `  end`.
        end_offset = Enum.find_index(rest, &(&1 =~ ~r/^  end\s*$/))
        end_idx = start_idx + 1 + end_offset
        MapSet.new(start_idx..end_idx)
    end
  end

  defp comment_line?(line), do: String.starts_with?(String.trim_leading(line), "#")

  defp allowlisted?(line), do: line =~ @spacer_line or line =~ @size_attr_def

  test "no recipe section builder inlines a numeric size: literal (TYPE-01)" do
    violations =
      Enum.flat_map(recipe_files(), fn path ->
        lines = path |> File.read!() |> String.split("\n")
        typography_idx = typography_body_indices(lines)

        lines
        |> Enum.with_index()
        |> Enum.filter(fn {line, idx} ->
          not MapSet.member?(typography_idx, idx) and
            not comment_line?(line) and
            not allowlisted?(line) and
            line =~ @size_literal
        end)
        |> Enum.map(fn {line, idx} ->
          "#{Path.relative_to_cwd(path)}:#{idx + 1}: #{String.trim(line)}"
        end)
      end)

    assert violations == [],
           "Inline numeric size: literal(s) found in recipe section builder(s). " <>
             "Route every size through the recipe's typography/1 seam " <>
             "(size: type.scale.<role>) instead:\n" <>
             Enum.join(violations, "\n")
  end
end

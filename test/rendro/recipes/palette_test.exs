defmodule Rendro.Recipes.PaletteTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.Palette

  # QL-006 — Wave 0 characterization: these maps are copied directly from the
  # seven recipe `palette/1` nil branches. They are compatibility contracts,
  # not shared theme defaults.
  @standard_defaults %{
    ink: {0, 0, 0},
    muted: {0, 0, 0},
    accent: {0, 0, 0},
    on_accent: {0, 0, 0},
    background: {255, 255, 255},
    surface: {255, 255, 255},
    rule: {0, 0, 0}
  }

  @statement_defaults %{
    ink: {0, 0, 0},
    muted: {0, 0, 0},
    background: {255, 255, 255},
    surface: {245, 245, 245},
    rule: {0, 0, 0}
  }

  @certificate_defaults %{
    ink: {0, 0, 0},
    muted: {0, 0, 0},
    background: {255, 255, 255},
    rule: {34, 34, 34}
  }

  describe "resolve/2 (QL-006 Wave 0)" do
    test "returns each exact legacy no-theme map used by the seven recipes" do
      assert Palette.resolve([], @standard_defaults) == @standard_defaults
      assert Palette.resolve([], @statement_defaults) == @statement_defaults
      assert Palette.resolve([], @certificate_defaults) == @certificate_defaults
    end

    test "treats an explicit nil theme like no theme, including boundary default maps" do
      assert Palette.resolve([theme: nil], %{}) == %{}
      assert Palette.resolve([theme: nil], %{rule: {34, 34, 34}}) == %{rule: {34, 34, 34}}
    end

    test "resolves a supplied theme before palette overrides" do
      theme = %{colors: %{ink: {1, 2, 3}, rule: {4, 5, 6}}}

      assert Palette.resolve([theme: theme], @certificate_defaults) ==
               Rendro.Theme.resolve(theme).colors
    end

    test "lets palette overrides win key-by-key over legacy and themed bases" do
      assert Palette.resolve([palette: %{ink: {0, 0, 0}}], @standard_defaults).ink == {0, 0, 0}

      theme = %{colors: %{ink: {1, 2, 3}, rule: {4, 5, 6}}}

      assert Palette.resolve([theme: theme, palette: %{ink: {7, 8, 9}}], @statement_defaults).ink ==
               {7, 8, 9}
    end

    test "retains Map.merge/2's invalid non-map palette failure" do
      assert_raise BadMapError, fn ->
        Palette.resolve([palette: [ink: {1, 2, 3}]], @standard_defaults)
      end
    end
  end
end

defmodule Rendro.Recipes.TableCellTest do
  use ExUnit.Case, async: true

  alias Rendro.Recipes.TableCell

  @colors %{ink: {12, 34, 56}, muted: {78, 90, 12}}
  @type_config %{
    scale: %{body: 10},
    fonts: %{body: :default},
    leading: 1.2,
    widows: 2,
    orphans: 2
  }

  test "returns the literal input string for a nil theme" do
    value = "Invoice item"

    assert TableCell.content(value, nil, @colors, @type_config, :ink) === value
  end

  test "materializes the requested semantic color role for a supplied theme" do
    ink = @colors.ink
    muted = @colors.muted

    assert %Rendro.Block{content: %Rendro.Text{content: "Invoice item", color: ^ink}} =
             TableCell.content("Invoice item", :supplied_theme, @colors, @type_config, :ink)

    assert %Rendro.Block{content: %Rendro.Text{color: ^muted}} =
             TableCell.content("Secondary", :supplied_theme, @colors, @type_config, :muted)
  end
end

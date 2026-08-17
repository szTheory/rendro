defmodule Rendro.Recipes.TableCell do
  @moduledoc false

  @spec content(String.t(), term(), map(), map(), atom()) :: String.t() | Rendro.Block.t()
  def content(value, nil, _colors, _type, _role) when is_binary(value), do: value

  def content(value, _theme, colors, type, role) when is_binary(value) do
    Rendro.block(
      Rendro.text(value,
        size: type.scale.body,
        font: type.fonts.body,
        line_height: type.leading,
        widows: type.widows,
        orphans: type.orphans,
        color: Map.fetch!(colors, role)
      )
    )
  end
end

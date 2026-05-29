defmodule Rendro.PageSize do
  @moduledoc false

  # A4 portrait — matches PageTemplate @default_width / @default_height exactly.
  @a4_portrait {595.28, 841.89}
  # US Letter portrait — standard PostScript dimensions (612 × 792 pt).
  @us_letter_portrait {612.0, 792.0}

  @spec resolve(atom() | {number(), number()}, :portrait | :landscape) ::
          {number(), number()}
  def resolve(size, orientation \\ :portrait)
  def resolve(:a4, :portrait), do: @a4_portrait
  def resolve(:a4, :landscape), do: swap(@a4_portrait)
  def resolve(:us_letter, :portrait), do: @us_letter_portrait
  def resolve(:us_letter, :landscape), do: swap(@us_letter_portrait)
  def resolve({w, h}, :portrait), do: {w, h}
  def resolve({w, h}, :landscape), do: swap({w, h})

  defp swap({w, h}), do: {h, w}
end

defmodule Rendro.PageSize do
  @moduledoc false

  # A4 portrait — matches PageTemplate @default_width / @default_height exactly.
  @a4_portrait {595.28, 841.89}
  # US Letter portrait — standard PostScript dimensions (612 × 792 pt).
  @us_letter_portrait {612.0, 792.0}
  # A6 portrait — 105mm × 148mm (standard postcard/ticket-stock size), added
  # in 118-08 (SHOW-01) so Rendro.Recipes.Ticket can render at its native
  # physical size instead of a much larger A4/US-Letter canvas.
  @a6_portrait {297.64, 419.53}

  @spec resolve(atom() | {number(), number()}, :portrait | :landscape) ::
          {number(), number()}
  def resolve(size, orientation \\ :portrait)
  def resolve(:a4, :portrait), do: @a4_portrait
  def resolve(:a4, :landscape), do: swap(@a4_portrait)
  def resolve(:us_letter, :portrait), do: @us_letter_portrait
  def resolve(:us_letter, :landscape), do: swap(@us_letter_portrait)
  def resolve(:a6, :portrait), do: @a6_portrait
  def resolve(:a6, :landscape), do: swap(@a6_portrait)
  def resolve({w, h}, :portrait), do: {w, h}
  def resolve({w, h}, :landscape), do: swap({w, h})

  defp swap({w, h}), do: {h, w}
end

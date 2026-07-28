defmodule Rendro.Recipes.Background do
  @moduledoc false

  # Sentinel for "no theme applied" — the light default's `background` role
  # (theme.ex:53). `emit?/1` compares against this EXACT integer tuple (D-06):
  # no tolerance / no near-white rounding. Any resolved palette whose
  # `background` differs from paper-white (a dark theme, or a caller-supplied
  # tinted background) emits the full-page fill; the untouched default does not.
  @paper_white {255, 255, 255}

  @doc """
  Returns `true` when the resolved `colors.background` differs from the
  paper-white no-theme default, i.e. a full-page background fill must be
  painted. Exact integer-tuple equality — no tolerance (D-06).

  ## Examples

      iex> Rendro.Recipes.Background.emit?(%{background: {255, 255, 255}})
      false

      iex> Rendro.Recipes.Background.emit?(%{background: {27, 23, 19}})
      true

  """
  @spec emit?(%{background: {non_neg_integer(), non_neg_integer(), non_neg_integer()}}) ::
          boolean()
  def emit?(%{background: bg}), do: bg != @paper_white

  @doc """
  Returns the `:background` `%Rendro.Region{}` — a fixed, full-page region
  sized to `page_w × page_h`. Dimensions are always caller-supplied (never
  hardcoded) so landscape/portrait and A4/Letter recipes all pass their own
  resolved page size.

  ## Examples

      iex> region = Rendro.Recipes.Background.region(595.28, 841.89)
      iex> {region.name, region.role, region.anchor}
      {:background, :custom, :fixed}

  """
  @spec region(number(), number()) :: Rendro.Region.t()
  def region(page_w, page_h) do
    Rendro.region(
      name: :background,
      role: :custom,
      anchor: :fixed,
      x: 0,
      y: 0,
      width: page_w,
      height: page_h
    )
  end

  @doc """
  Returns the `:background` `%Rendro.Section{}` — a single full-page filled
  rect block, painted with `colors.background`, mapped to the `:background`
  region.

  ## Examples

      iex> colors = %{background: {27, 23, 19}}
      iex> section = Rendro.Recipes.Background.section(colors, 595.28, 841.89)
      iex> section.region
      :background

  """
  @spec section(map(), number(), number()) :: Rendro.Section.t()
  def section(colors, page_w, page_h) do
    fill_block =
      Rendro.path([{:rect, 0, 0, page_w, page_h}],
        fill: colors.background,
        x: 0,
        y: 0,
        width: page_w,
        height: page_h
      )

    Rendro.section(name: :background, region: :background, content: [fill_block])
  end
end

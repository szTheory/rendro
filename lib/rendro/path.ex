defmodule Rendro.Path do
  @moduledoc """
  Declarative vector-graphics block element for Rendro documents.

  A `%Rendro.Path{}` is an inert authored value — a list of drawing operations
  (`ops`) with optional `fill` and `stroke` styling. It is placed in a document
  as a block element (via `Rendro.path/2`) and rendered through the standard
  `build → compose → measure → paginate → render` pipeline.

  ## Coordinate model

  All coordinates are **block-relative, author top-left, Y-down** — the same
  convention used by `Rendro.Text`, `Rendro.Image`, and `Rendro.Table`. The
  writer performs the single PDF Y-flip internally. Do not pre-flip coordinates.

  ## Op vocabulary

  The `ops` list accepts the following tagged tuple operations:

  - `{:move, x, y}` — Move to `(x, y)` without drawing (`m` PDF operator).
  - `{:line, x, y}` — Draw a straight line to `(x, y)` (`l`).
  - `{:curve, x1, y1, x2, y2, x3, y3}` — Draw a cubic Bézier curve with two
    control points `(x1,y1)`, `(x2,y2)` and endpoint `(x3,y3)` (`c`).
  - `{:rect, x, y, w, h}` — Draw a rectangle at `(x, y)` with dimensions
    `w × h` (`re`).
  - `{:rounded_rect, x, y, w, h, radius}` — Draw a rectangle with rounded
    corners of the given `radius`. Decomposed deterministically into
    `move`/`line`/`curve` ops using the `0.5522847498` kappa approximation.
  - `:close` — Close the current subpath (`h`).

  ## Stroke and fill

  `stroke` and `fill` each accept:

  - `nil` (default) — no stroke / no fill.
  - `{r, g, b}` tuple (integers, 0–255) — bare color, using PDF default line
    width `1.0`, butt caps, miter join, solid dash.
  - A map with any of: `color: {r,g,b}`, `width: float()`, `dash: nil | [on, off]`,
    `cap: :butt | :round | :square`, `join: :miter | :round | :bevel`.

  Paint-op selection is deterministic: `{nil, nil} → n`; `{nil, fill} → f`;
  `{stroke, nil} → S`; `{stroke, fill} → B`.

  ## Example

      Rendro.path([
        {:rect, 10, 10, 100, 50}
      ], stroke: {0, 0, 0}, width: 200, height: 70)

  """
  @moduledoc tags: [:stable]

  @enforce_keys [:ops]
  defstruct [:ops, fill: nil, stroke: nil]

  @type op ::
          {:move, number(), number()}
          | {:line, number(), number()}
          | {:curve, number(), number(), number(), number(), number(), number()}
          | {:rect, number(), number(), number(), number()}
          | {:rounded_rect, number(), number(), number(), number(), number()}
          | :close

  @type color :: {non_neg_integer(), non_neg_integer(), non_neg_integer()}

  @type stroke_style ::
          nil
          | color()
          | %{
              optional(:color) => color(),
              optional(:width) => number(),
              optional(:dash) => nil | [number()],
              optional(:cap) => :butt | :round | :square,
              optional(:join) => :miter | :round | :bevel
            }

  @type fill_style ::
          nil
          | color()
          | %{optional(:color) => color()}

  @type t :: %__MODULE__{
          ops: [op()],
          fill: fill_style(),
          stroke: stroke_style()
        }
end

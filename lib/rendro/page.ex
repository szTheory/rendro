defmodule Rendro.Page do
  @moduledoc """
  A page with blocks, dimensions, and margins.
  """

  @default_width 595.28
  @default_height 841.89
  @default_margin 72

  @enforce_keys []
  defstruct blocks: [],
            width: @default_width,
            height: @default_height,
            margin_top: @default_margin,
            margin_right: @default_margin,
            margin_bottom: @default_margin,
            margin_left: @default_margin

  @type t :: %__MODULE__{
          blocks: [Rendro.Block.t()],
          width: number(),
          height: number(),
          margin_top: number(),
          margin_right: number(),
          margin_bottom: number(),
          margin_left: number()
        }
end

defmodule Rendro.Page do
  @moduledoc """
  A page with blocks, dimensions, and margins.
  """

  @enforce_keys []
  defstruct blocks: [],
            width: 595.28,
            height: 841.89,
            margin_top: 72,
            margin_right: 72,
            margin_bottom: 72,
            margin_left: 72

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

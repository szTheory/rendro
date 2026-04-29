defmodule Rendro.PageTemplate do
  @moduledoc """
  Explicit flow-page layout template with page geometry and named regions.
  """

  @default_width 595.28
  @default_height 841.89
  @default_margin 72

  @enforce_keys []
  defstruct name: :default,
            width: @default_width,
            height: @default_height,
            margin_top: @default_margin,
            margin_right: @default_margin,
            margin_bottom: @default_margin,
            margin_left: @default_margin,
            regions: [
              %Rendro.Region{name: :header, role: :header, anchor: :top, x: 72, y: 72, width: 451.28, height: 0},
              %Rendro.Region{
                name: :body,
                role: :body,
                anchor: :flow,
                x: 72,
                y: 72,
                width: 451.28,
                height: 697.89
              },
              %Rendro.Region{
                name: :footer,
                role: :footer,
                anchor: :bottom,
                x: 72,
                y: 769.89,
                width: 451.28,
                height: 0
              }
            ]

  @type t :: %__MODULE__{
          name: atom() | String.t(),
          width: number(),
          height: number(),
          margin_top: number(),
          margin_right: number(),
          margin_bottom: number(),
          margin_left: number(),
          regions: [Rendro.Region.t()]
        }
end

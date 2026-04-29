defmodule Rendro.Pipeline.MeasuredText do
  @moduledoc false

  @enforce_keys [:source, :lines, :line_height, :width, :height]
  defstruct [:source, :lines, :line_height, :width, :height]

  @type t :: %__MODULE__{
          source: Rendro.Text.t(),
          lines: [String.t()],
          line_height: number(),
          width: number(),
          height: number()
        }
end

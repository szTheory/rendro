defmodule Rendro.Pipeline.MeasuredText do
  @moduledoc false

  @enforce_keys [:source, :lines, :line_height, :width, :height, :resolved_font]
  defstruct [:source, :lines, :line_height, :width, :height, :resolved_font]

  @type run :: %{font: Rendro.PDF.Font.t(), text: String.t(), width: float()}

  @type t :: %__MODULE__{
          source: Rendro.Text.t(),
          lines: [[run()]],
          line_height: number(),
          width: number(),
          height: number(),
          resolved_font: Rendro.PDF.Font.t()
        }
end

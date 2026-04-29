defmodule Rendro.Block do
  @moduledoc """
  Content container with position and size.
  """

  @enforce_keys [:content]
  defstruct [
    :content,
    x: 0,
    y: 0,
    width: nil,
    height: nil,
    keep_together: false,
    keep_with_next: false,
    break_before: false,
    break_after: false
  ]

  @type t :: %__MODULE__{
          content: Rendro.Text.t() | Rendro.Table.t() | term(),
          x: number(),
          y: number(),
          width: number() | nil,
          height: number() | nil,
          keep_together: boolean(),
          keep_with_next: boolean(),
          break_before: boolean(),
          break_after: boolean()
        }
end

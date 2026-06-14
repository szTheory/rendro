defmodule Rendro.Block do
  @moduledoc """
  Content container with position and size.
  """
  @moduledoc tags: [:stable]

  @enforce_keys [:content]
  defstruct [
    :id,
    :content,
    x: 0,
    y: 0,
    width: nil,
    height: nil,
    keep_together: false,
    keep_with_next: false,
    break_before: false,
    break_after: false,
    outline: false,
    outline_level: 1
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          content:
            Rendro.Text.t() | Rendro.Table.t() | Rendro.FormField.t() | Rendro.Link.t() | term(),
          x: number(),
          y: number(),
          width: number() | nil,
          height: number() | nil,
          keep_together: boolean(),
          keep_with_next: boolean(),
          break_before: boolean(),
          break_after: boolean(),
          outline: boolean() | String.t(),
          outline_level: non_neg_integer()
        }
end

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
    height: nil
  ]

  @type t :: %__MODULE__{
          content: Rendro.Text.t() | Rendro.Table.t() | term(),
          x: number(),
          y: number(),
          width: number() | nil,
          height: number() | nil
        }
end

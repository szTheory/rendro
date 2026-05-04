defmodule Rendro.Row do
  @moduledoc """
  Row primitive for explicit table fragmentation configuration.
  """

  @enforce_keys [:cells]
  defstruct [
    :cells,
    split_policy: :row_atomic,
    x: 0,
    y: 0,
    width: nil,
    height: nil,
    keep_together: false,
    keep_with_next: false,
    break_before: false,
    break_after: false
  ]

  @type split_policy :: :row_atomic | :atomic | :fragment
  @type t :: %__MODULE__{
          cells: [Rendro.Cell.t() | Rendro.Block.t() | String.t()],
          split_policy: split_policy(),
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

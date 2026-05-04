defmodule Rendro.Cell do
  @moduledoc """
  Cell primitive for explicit table fragmentation configuration.
  """

  @enforce_keys [:content]
  defstruct [
    :content,
    split_policy: :atomic,
    colspan: 1,
    rowspan: 1,
    x: 0,
    y: 0,
    width: nil,
    height: nil,
    keep_together: false,
    keep_with_next: false,
    break_before: false,
    break_after: false
  ]

  @type split_policy :: :atomic | :fragment
  @type t :: %__MODULE__{
          content: Rendro.Block.t() | String.t(),
          split_policy: split_policy(),
          colspan: pos_integer(),
          rowspan: pos_integer(),
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

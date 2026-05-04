defmodule Rendro.Table do
  @moduledoc """
  Table primitive for structured data.
  """

  @enforce_keys [:rows]
  defstruct [
    :rows,
    header: nil,
    columns: nil,
    split_policy: :row_atomic,
    repeat_header: true,
    decoration_break: :slice,
    # Pipeline geometry fields populated by Measure
    column_widths: nil,
    row_heights: nil,
    header_height: nil,
    _grid_layout: nil
  ]

  @type row :: [Rendro.Block.t() | String.t()] | Rendro.Row.t()
  @type column_rule :: {:fixed, number()} | {:share, number()}
  @type split_policy :: :row_atomic | :atomic | :fragment
  @type decoration_break :: :slice | :clone
  @type t :: %__MODULE__{
          rows: [row()],
          header: row() | nil,
          columns: [column_rule()] | nil,
          split_policy: split_policy(),
          repeat_header: boolean(),
          decoration_break: decoration_break(),
          column_widths: [number()] | nil,
          row_heights: [number()] | nil,
          header_height: number() | nil,
          _grid_layout: list(list(map())) | nil
        }
end

defmodule Rendro.Table do
  @moduledoc """
  Table primitive for structured data.
  """
  @moduledoc tags: [:stable]

  @enforce_keys [:rows]
  defstruct [
    :rows,
    header: nil,
    columns: nil,
    split_policy: :row_atomic,
    repeat_header: true,
    decoration_break: :slice,
    # Opt-in borders / shading fields (all inert by default)
    borders: :none,
    border_style: nil,
    header_fill: nil,
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
  @type borders ::
          :none
          | :outer
          | :rows
          | :columns
          | :grid
          | :all
          | [atom()]
  @type t :: %__MODULE__{
          rows: [row()],
          header: row() | nil,
          columns: [column_rule()] | nil,
          split_policy: split_policy(),
          repeat_header: boolean(),
          decoration_break: decoration_break(),
          borders: borders(),
          border_style: nil | map(),
          header_fill: nil | {non_neg_integer(), non_neg_integer(), non_neg_integer()},
          column_widths: [number()] | nil,
          row_heights: [number()] | nil,
          header_height: number() | nil,
          _grid_layout: list(list(map())) | nil
        }
end

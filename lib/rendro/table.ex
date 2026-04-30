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
    # Pipeline geometry fields populated by Measure
    column_widths: nil,
    row_heights: nil,
    header_height: nil
  ]

  @type row :: [Rendro.Block.t() | String.t()]
  @type column_rule :: {:fixed, number()} | {:share, number()}
  @type split_policy :: :row_atomic | :atomic
  @type t :: %__MODULE__{
          rows: [row()],
          header: row() | nil,
          columns: [column_rule()] | nil,
          split_policy: split_policy(),
          column_widths: [number()] | nil,
          row_heights: [number()] | nil,
          header_height: number() | nil
        }
end

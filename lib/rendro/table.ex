defmodule Rendro.Table do
  @moduledoc """
  Table primitive for structured data.
  """

  @enforce_keys [:rows]
  defstruct [
    :rows,
    header: nil,
    columns: nil,
    split_policy: :atomic,
    # Pipeline geometry fields populated by Measure
    column_widths: nil,
    row_heights: nil,
    header_height: nil
  ]

  @type row :: [Rendro.Block.t() | String.t()]
  @type column_rule :: {:fixed, number()} | {:share, number()}
  @type t :: %__MODULE__{
          rows: [row()],
          header: row() | nil,
          columns: [column_rule()] | nil,
          split_policy: :atomic,
          column_widths: [number()] | nil,
          row_heights: [number()] | nil,
          header_height: number() | nil
        }
end

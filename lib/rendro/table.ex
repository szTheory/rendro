defmodule Rendro.Table do
  @moduledoc """
  Table primitive for structured data.
  """

  @enforce_keys [:rows]
  defstruct [
    :rows,
    header: nil,
    width: :fill,
    border: true
  ]

  @type row :: [Rendro.Block.t() | String.t()]
  @type t :: %__MODULE__{
          rows: [row()],
          header: row() | nil,
          width: number() | :fill,
          border: boolean()
        }
end

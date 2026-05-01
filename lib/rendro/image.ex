defmodule Rendro.Image do
  @moduledoc """
  AST representation of a registered image asset to be rendered.
  """

  @enforce_keys [:logical_name]
  defstruct [
    :logical_name,
    :fit
  ]

  @type t :: %__MODULE__{
          logical_name: atom(),
          fit: {number(), number()} | nil
        }
end

defmodule Rendro.FormField do
  @moduledoc """
  Interactive text form field content with deterministic authoring defaults.
  """

  @enforce_keys [:name]
  defstruct [
    :name,
    value: "",
    font: "Helvetica",
    size: 12
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          value: String.t(),
          font: String.t() | atom(),
          size: number()
        }
end

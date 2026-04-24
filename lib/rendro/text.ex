defmodule Rendro.Text do
  @moduledoc """
  Text content with font, size, and color attributes.
  """

  @enforce_keys [:content]
  defstruct [
    :content,
    font: "Helvetica",
    size: 12,
    color: {0, 0, 0}
  ]

  @type t :: %__MODULE__{
          content: String.t(),
          font: String.t(),
          size: number(),
          color: {non_neg_integer(), non_neg_integer(), non_neg_integer()}
        }
end

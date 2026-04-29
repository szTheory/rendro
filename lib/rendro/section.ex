defmodule Rendro.Section do
  @moduledoc """
  Reusable flow section that targets a named template region.
  """

  @enforce_keys []
  defstruct name: nil,
            region: :body,
            content: [],
            page_template: nil,
            options: %{}

  @type t :: %__MODULE__{
          name: atom() | String.t() | nil,
          region: atom() | String.t(),
          content: [Rendro.Block.t()],
          page_template: atom() | String.t() | nil,
          options: %{optional(atom()) => term()}
        }
end

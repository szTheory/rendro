defmodule Rendro.Section do
  @moduledoc """
  Reusable flow section that targets a named template region.
  """
  @moduledoc tags: [:stable]

  @enforce_keys []
  defstruct name: nil,
            region: :body,
            content: [],
            suppress_on: nil,
            only_on: nil,
            page_numbering: [],
            page_template: nil,
            options: %{}

  @type suppress_on :: nil | :first | {:pages, [pos_integer()]}
  @type only_on :: nil | :odd | :even
  @type page_numbering :: [] | [restart: true]

  @type t :: %__MODULE__{
          name: atom() | String.t() | nil,
          region: atom() | String.t(),
          content: [Rendro.Block.t() | Rendro.RunningContent.t()],
          suppress_on: suppress_on(),
          only_on: only_on(),
          page_numbering: page_numbering(),
          page_template: atom() | String.t() | nil,
          options: %{optional(atom()) => term()}
        }
end

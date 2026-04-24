defmodule Rendro.Metadata do
  @moduledoc """
  Document metadata: title, author, creator, dates, and custom fields.
  """

  @enforce_keys []
  defstruct [
    :title,
    :author,
    :creator,
    :creation_date,
    :modification_date,
    custom: %{}
  ]

  @type t :: %__MODULE__{
          title: String.t() | nil,
          author: String.t() | nil,
          creator: String.t() | nil,
          creation_date: DateTime.t() | nil,
          modification_date: DateTime.t() | nil,
          custom: %{optional(atom()) => term()}
        }
end

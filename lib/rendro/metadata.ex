defmodule Rendro.Metadata do
  @moduledoc """
  Input metadata for a rendered PDF document.

  Passed to `Rendro.metadata/1` to set title, author, creator, and custom
  key-value pairs in the PDF document info dictionary. All fields are optional.

  The `custom` field accepts an open map of `atom() => term()` pairs (additive
  contract — new keys may be added by the caller without version friction).
  """,
  tags: [:stable]

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

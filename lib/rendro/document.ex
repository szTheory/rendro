defmodule Rendro.Document do
  @moduledoc """
  Top-level document: pages, metadata, and rendering options.
  """

  @enforce_keys []
  defstruct pages: [],
            metadata: %Rendro.Metadata{},
            options: %{}

  @type t :: %__MODULE__{
          pages: [Rendro.Page.t()],
          metadata: Rendro.Metadata.t(),
          options: %{optional(atom()) => term()}
        }
end

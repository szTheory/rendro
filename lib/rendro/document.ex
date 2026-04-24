defmodule Rendro.Document do
  @moduledoc """
  Top-level document: pages, content (flow), metadata, and rendering options.
  """

  @enforce_keys []
  defstruct pages: [],
            content: [],
            metadata: %Rendro.Metadata{},
            options: %{}

  @type t :: %__MODULE__{
          pages: [Rendro.Page.t()],
          content: [Rendro.Block.t()],
          metadata: Rendro.Metadata.t(),
          options: %{optional(atom()) => term()}
        }
end

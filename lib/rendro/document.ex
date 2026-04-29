defmodule Rendro.Document do
  @moduledoc """
  Top-level document: pages, content (flow), metadata, and rendering options.
  """

  @enforce_keys []
  defstruct pages: [],
            content: [],
            page_templates: [],
            page_template: nil,
            sections: [],
            header: [],
            footer: [],
            metadata: %Rendro.Metadata{},
            options: %{}

  @type t :: %__MODULE__{
          pages: [Rendro.Page.t()],
          content: [Rendro.Block.t()],
          page_templates: [Rendro.PageTemplate.t()],
          page_template: atom() | String.t() | nil,
          sections: [Rendro.Section.t()],
          header: [Rendro.Block.t()],
          footer: [Rendro.Block.t()],
          metadata: Rendro.Metadata.t(),
          options: %{optional(atom()) => term()}
        }
end
